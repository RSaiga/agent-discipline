#!/usr/bin/env bash
# End-to-end check of bench/run.sh without calling the real CLI or touching any real repository.
# Everything lives in one mktemp directory: a throwaway source repo, a fake `claude` on a PATH
# that only this script uses, the bench root, and the results. The directory is removed on exit.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/codence-bench-flow.XXXXXX")" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

git init -q "$tmp/src"
echo a > "$tmp/src/f"
git -C "$tmp/src" add f
git -C "$tmp/src" -c user.name=bench -c user.email=bench@example.invalid commit -qm init
commit="$(git -C "$tmp/src" rev-parse --short HEAD)"

mkdir -p "$tmp/bin" "$tmp/task" "$tmp/va" "$tmp/vb"
cat > "$tmp/bin/claude" <<'EOF'
#!/usr/bin/env bash
# Records the arguments it received (NUL-separated) and the directory it ran in, then
# emits a minimal stream-json transcript.
printf '%s\0' "$@" >> "$FLOW_LOG.args"
printf '%s\n' "$PWD" >> "$FLOW_LOG.cwd"
echo '{"type":"system","subtype":"init","claude_code_version":"fake","model":"m","plugins":[],"skills":["s"]}'
echo '{"type":"result","subtype":"success","is_error":false,"result":"no findings","total_cost_usd":0.01,"num_turns":1,"modelUsage":{"m":{"inputTokens":1,"outputTokens":2,"cacheReadInputTokens":3,"cacheCreationInputTokens":4,"costUSD":0.01}}}'
EOF
chmod +x "$tmp/bin/claude"

echo "{review} now" > "$tmp/task/prompt.txt"
echo "/kit-a:review" > "$tmp/va/review.txt"
echo "/kit-b:review" > "$tmp/vb/review.txt"
echo "max-findings 0" > "$tmp/task/expect"
printf '["--allowedTools","Bash(git diff:*)","arg with spaces","*"]\n' > "$tmp/task/claude.args.json"
cat > "$tmp/task/setup.sh" <<'EOF'
#!/usr/bin/env bash
echo changed > "$1/f"
EOF
cat > "$tmp/task/check.sh" <<'EOF'
#!/usr/bin/env bash
# Passes only when it is handed the clone with the setup change in it.
[ "$(cat "$1/f")" = changed ] && echo '{"pass": true, "seen": "clone"}' || echo '{"pass": false}'
EOF
chmod +x "$tmp/task/setup.sh" "$tmp/task/check.sh"

cat > "$tmp/base.env" <<EOF
SOURCE_REPO=$tmp/src
COMMIT=$commit
BENCH_ROOT=$tmp/root
WORKDIR=$tmp/root/work
RESULTS=$tmp/results
MODEL=m
EOF

FLOW_LOG="$tmp/log" PATH="$tmp/bin:$PATH" \
  bash "$here/run.sh" --base "$tmp/base.env" --task "$tmp/task" --variants "$tmp/va,$tmp/vb" --repeat 2 >/dev/null

results="$tmp/results/results.jsonl"
[ "$(wc -l < "$results" | tr -d ' ')" = 4 ] || fail "expected 4 records"

python3 - "$results" "$tmp/log.args" <<'EOF' || exit 1
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
order = [(r["variant"], r["rep"]) for r in rows]
assert order == [("va", 1), ("vb", 1), ("vb", 2), ("va", 2)], f"order {order}"
for r in rows:
    assert r["status"] == "ok" and r["pass"] is True, r
    assert r["check"] == {"pass": True, "seen": "clone"}, r["check"]
    assert r["cost_usd"] == 0.01 and r["input"] == 1 and r["cache_read"] == 3, r
    assert r["cli"] == "fake" and r["model"] == "m", r
    assert "arg with spaces" in r["args"] and "*" in r["args"], r["args"]
calls = open(sys.argv[2]).read().split("\0")[:-1]
assert calls.count("arg with spaces") == 4 and calls.count("*") == 4, "args were split or globbed"
assert calls.count("/kit-a:review now") == 2 and calls.count("/kit-b:review now") == 2, "review command not substituted per variant"
EOF

[ -f "$tmp/root/work/.codence-bench-workdir" ] || fail "marker missing"
[ "$(cat "$tmp/root/work/repo/f")" = changed ] || fail "setup did not run in the clone"
[ "$(cat "$tmp/src/f")" = a ] || fail "source repo was modified"
[ -z "$(git -C "$tmp/src" status --porcelain)" ] || fail "source repo is dirty"
sort -u "$tmp/log.cwd" | grep -qx "$tmp/root/work/repo" || fail "claude did not run in the clone"
[ "$(sort -u "$tmp/log.cwd" | wc -l | tr -d ' ')" = 1 ] || fail "runs used different paths"

echo "PASS: 4 runs, AB/BA order, args verbatim, clone-only changes, same path every run, check.sh on the clone, {review} per variant"
