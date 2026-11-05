#!/usr/bin/env bash
# Run bench tasks headlessly from an identical starting state and record cost and outcome.
#
#   bench/run.sh --base <base.env> --task <task-dir> --variants <dir>[,<dir>...] [--repeat N]
#
# base.env : SOURCE_REPO, COMMIT, BENCH_ROOT, WORKDIR (under BENCH_ROOT, reused every run),
#            RESULTS, MODEL, EFFORT, SETTING_SOURCES, [PRICES], [CLONE] (the clone's folder name, default
#            repo; parallel runs use a WORKDIR and CLONE each, since some kits key state on the name)
# task dir : prompt.txt, expect, [setup.sh <repo>], [check.sh <repo>], [claude.args.json],
#            [cwd] (run from this path relative to the clone, e.g. a subdirectory or ../wt)
#            check.sh grades the clone after the run and prints {"pass", ...}; both it and
#            expect must pass.
# variant  : [install.sh <repo>], [claude.args.json], [kit] (a checkout whose commit is recorded),
#            [<name>.txt] (the command that replaces {<name>} in a task's prompt, e.g. review.txt or
#            cycle.txt, since kits are invoked by different names; a prompt without placeholders runs
#            unchanged)
# *.args.json is a JSON array of CLI arguments, passed through verbatim.
# Order alternates per repetition (AB, BA, ...) so cache warmth does not favour one variant.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repeat=3
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --task) task="$(cd "$2" && pwd)"; shift 2 ;;
    --variants) variants="$2"; shift 2 ;;
    --repeat) repeat="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
: "${base:?--base is required}" "${task:?--task is required}" "${variants:?--variants is required}"

# shellcheck disable=SC1090
source "$base"
: "${SOURCE_REPO:?}" "${COMMIT:?}" "${BENCH_ROOT:?}" "${WORKDIR:?}" "${RESULTS:?}" "${MODEL:?}"
: "${EFFORT:=medium}" "${SETTING_SOURCES:=project,local}" "${PRICES:=$here/prices.json}" "${CLONE:=repo}"

MARKER=".agent-discipline-bench-workdir"
resolve() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
inside() { case "$1/" in "$2"/*) return 0 ;; *) return 1 ;; esac; }

mkdir -p "$BENCH_ROOT" "$RESULTS/out"
root="$(resolve "$BENCH_ROOT")"; work="$(resolve "$WORKDIR")"
src="$(resolve "$SOURCE_REPO")"; res="$(resolve "$RESULTS")"
[ "$work" != "$root" ] && inside "$work" "$root" || { echo "WORKDIR must be strictly inside BENCH_ROOT" >&2; exit 2; }
for p in "$src" "$res" "$here"; do
  if inside "$p" "$work" || inside "$work" "$p"; then
    echo "WORKDIR must not contain or sit inside $p" >&2; exit 2
  fi
done

prepare_workdir() {
  if [ -e "$work" ]; then
    [ -f "$work/$MARKER" ] || { echo "refusing to delete $work: no $MARKER" >&2; exit 2; }
    chmod -R u+w "$work"   # a stop task may leave read-only folders behind
    rm -rf "$work"
  fi
  mkdir -p "$work"; touch "$work/$MARKER"
  git clone -q --shared --no-checkout "$src" "$work/$CLONE"
  git -C "$work/$CLONE" checkout -q --detach "$COMMIT"
  # Diff-based skills compare against main; pin it so only the task's change is in the diff.
  git -C "$work/$CLONE" branch -q -f main "$COMMIT"
}

append_args() {
  [ -f "$1" ] || return 0
  while IFS= read -r -d '' a; do args+=("$a"); done < <(python3 - "$1" <<'EOF'
import json, sys
for a in json.load(open(sys.argv[1])):
    sys.stdout.write(str(a) + "\0")
EOF
)
}

kit_commit() {
  [ -f "$1/kit" ] || { echo null; return; }
  local k; k="$(cat "$1/kit")"
  local c; c="$(git -C "$k" rev-parse --verify -q HEAD 2>/dev/null || echo no-commit)"
  [ -n "$(git -C "$k" status --porcelain 2>/dev/null)" ] && c="$c-dirty"
  echo "\"$c\""
}

IFS=',' read -r -a variant_list <<< "$variants"

for rep in $(seq 1 "$repeat"); do
  order=("${variant_list[@]}")
  if [ $((rep % 2)) -eq 0 ]; then
    order=(); for ((i=${#variant_list[@]}-1; i>=0; i--)); do order+=("${variant_list[$i]}"); done
  fi
  for v in "${order[@]}"; do
    vdir="$(cd "$v" && pwd)"
    prepare_workdir
    [ -x "$vdir/install.sh" ] && "$vdir/install.sh" "$work/$CLONE"
    if [ -x "$task/setup.sh" ] && ! "$task/setup.sh" "$work/$CLONE"; then echo "setup failed: $task/setup.sh" >&2; exit 2; fi

    prompt="$(cat "$task/prompt.txt")"
    for name in $(grep -o '{[a-z][a-z-]*}' "$task/prompt.txt" | sort -u | tr -d '{}'); do
      [ -f "$vdir/$name.txt" ] || { echo "$vdir/$name.txt is required for a {$name} task" >&2; exit 2; }
      prompt="${prompt//\{$name\}/$(cat "$vdir/$name.txt")}"
    done
    args=(-p "$prompt" --output-format stream-json --verbose
          --no-session-persistence --strict-mcp-config
          --setting-sources "$SETTING_SOURCES" --model "$MODEL" --effort "$EFFORT")
    append_args "$task/claude.args.json"
    append_args "$vdir/claude.args.json"

    # The clone name keeps ids apart when parallel workdirs start in the same second.
    id="$(date +%Y%m%dT%H%M%S)-$(basename "$task")-$(basename "$vdir")-$rep"; [ "$CLONE" = repo ] || id="$id-$CLONE"
    raw="$RESULTS/out/$id.jsonl"
    set +e
    rundir="$work/$CLONE"; [ -f "$task/cwd" ] && rundir="$work/$CLONE/$(cat "$task/cwd")"
    (cd "$rundir" && claude "${args[@]}") < /dev/null > "$raw" 2> "$RESULTS/out/$id.stderr"
    code=$?
    set -e

    printf '%s\0' "${args[@]}" > "$RESULTS/out/$id.args"
    grade="$("$here/grade.sh" "$task/expect" "$raw" "$code")"
    check=null
    if [ -x "$task/check.sh" ] && [ "$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["status"])' "$grade")" = ok ]; then
      check="$("$task/check.sh" "$work/$CLONE" 2> "$RESULTS/out/$id.check.stderr" || echo '{"pass": false, "error": "check.sh failed"}')"
    fi
    python3 - "$raw" "$grade" "$id" "$(basename "$task")" "$(basename "$vdir")" "$rep" \
      "$COMMIT" "$(kit_commit "$vdir")" "$PRICES" "$RESULTS/out/$id.args" "$check" >> "$RESULTS/results.jsonl" <<'EOF'
import json, os, sys
raw, grade, id_, task, variant, rep, commit, kit, prices_path, args_path, check = sys.argv[1:]
grade, check = json.loads(grade), json.loads(check)
if check is not None:
    grade["pass"] = grade["pass"] is True and check.get("pass") is True
init, result = {}, {}
for line in open(raw):
    try:
        d = json.loads(line)
    except ValueError:
        continue
    if d.get("type") == "system" and d.get("subtype") == "init":
        init = d
    elif d.get("type") == "result":
        result = d
mu = result.get("modelUsage") or {}
tokens = {
    "input": sum(m.get("inputTokens", 0) for m in mu.values()),
    "cache_write": sum(m.get("cacheCreationInputTokens", 0) for m in mu.values()),
    "cache_read": sum(m.get("cacheReadInputTokens", 0) for m in mu.values()),
    "output": sum(m.get("outputTokens", 0) for m in mu.values()),
}
# Per-category cost needs a dated price table; without one, only the CLI's total is recorded.
prices = json.load(open(prices_path)) if os.path.exists(prices_path) else {}
breakdown = None
if mu and all(k in prices.get("models", {}) for k in mu):
    breakdown = {c: 0.0 for c in ("input", "cache_write_5m", "cache_write_1h", "cache_read", "output")}
    for k, m in mu.items():
        p = prices["models"][k]
        breakdown["input"] += m.get("inputTokens", 0) * p["input"] / 1e6
        breakdown["cache_write_5m"] += m.get("cacheCreationEphemeral5mInputTokens", 0) * p["cache_write_5m"] / 1e6
        breakdown["cache_write_1h"] += m.get("cacheCreationEphemeral1hInputTokens", 0) * p["cache_write_1h"] / 1e6
        breakdown["cache_read"] += m.get("cacheReadInputTokens", 0) * p["cache_read"] / 1e6
        breakdown["output"] += m.get("outputTokens", 0) * p["output"] / 1e6
    breakdown = {k: round(v, 6) for k, v in breakdown.items()} | {"price_table": prices.get("as_of")}
print(json.dumps({
    "id": id_, "task": task, "variant": variant, "rep": int(rep),
    "commit": commit, "kit": json.loads(kit),
    "cli": init.get("claude_code_version"), "model": init.get("model"),
    "plugins": [p.get("source") for p in init.get("plugins", [])],
    "skills": len(init.get("skills", [])), "agents": init.get("agents"),
    "args": open(args_path).read().split("\0")[:-1],
    "cost_usd": result.get("total_cost_usd"), "cost_breakdown": breakdown, **tokens,
    "models": {k: round(v.get("costUSD", 0), 6) for k, v in mu.items()},
    "subagent_stats": result.get("subagent_stats"),
    "permission_denials": len(result.get("permission_denials") or []),
    "turns": result.get("num_turns"), "duration_ms": result.get("duration_ms"),
    **grade, "check": check,
}, ensure_ascii=False))
EOF
    tail -1 "$RESULTS/results.jsonl"
  done
done
