#!/usr/bin/env bash
# Check grade.sh's outer-loop checks on hand-written transcripts: the disciplined order passes, and
# each way of breaking it fails.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/ad-bench-outer.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

cat > "$tmp/expect" <<'EOF'
outer-red cucumber "本にタグを付ける" (tests|src)/
outer-close cucumber "本にタグを付ける" features/.*\.feature$
no-write-before-green cucumber "本にタグを付ける" tests/
EOF

# Steps: "write <path>", "unwip <path>" (an edit that drops @wip), "run <command>|<output>".
stream() {
  python3 - "$@" <<'EOF'
import json, sys
print(json.dumps({"type": "system", "subtype": "init", "plugins": []}))
for n, step in enumerate(sys.argv[1:]):
    kind, arg = step.split(" ", 1)
    use = {"type": "tool_use", "id": f"t{n}"}
    if kind == "write":
        use |= {"name": "Write", "input": {"file_path": arg, "content": "x"}}; out = "ok"
    elif kind == "unwip":
        use |= {"name": "Edit", "input": {"file_path": arg, "old_string": "@wip\n  Scenario: 本にタグを付ける",
                                           "new_string": "  Scenario: 本にタグを付ける"}}; out = "ok"
    else:
        cmd, out = arg.split("|", 1)
        use |= {"name": "Bash", "input": {"command": cmd}}
    print(json.dumps({"type": "assistant", "message": {"content": [use]}}))
    print(json.dumps({"type": "user", "message": {"content": [
        {"type": "tool_result", "tool_use_id": f"t{n}", "content": out, "is_error": False}]}}))
print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "result": "done"}))
EOF
}
verdict() { "$here/grade.sh" "$tmp/expect" "$1" 0 | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["pass"], d["detail"])'; }
expect_pass() { v="$(verdict "$2")"; [[ "$v" == True* ]] || fail "$1: $v"; }
expect_fail() { v="$(verdict "$2")"; [[ "$v" == False* ]] || fail "$1 should fail: $v"; }

one='bunx cucumber-js -p all --name "本にタグを付ける"'
dflt='bunx cucumber-js'
red='1 scenario (1 failed)'
undefined='1 scenario (1 undefined)'
green='1 scenario (1 passed)'
all_green='4 scenarios (4 passed)'
zero='0 scenarios'

stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/ok.jsonl"
expect_pass "disciplined skeleton" "$tmp/ok.jsonl"

stream "write /r/features/books.feature" "write /r/src/app.ts" "run $one|$red" "run $one|$green" \
       "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/code-first.jsonl"
expect_fail "code before the outer red" "$tmp/code-first.jsonl"

stream "write /r/features/books.feature" "run $one|$undefined" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/undefined.jsonl"
expect_fail "an undefined step is not a red" "$tmp/undefined.jsonl"

stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" \
       "unwip /r/features/books.feature" "run $one|$green" "run $dflt|$all_green" > "$tmp/early-unwip.jsonl"
expect_fail "@wip removed before green" "$tmp/early-unwip.jsonl"

stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" > "$tmp/no-default.jsonl"
expect_fail "no default run after removing @wip" "$tmp/no-default.jsonl"

stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$zero" \
       "unwip /r/features/books.feature" "run $dflt|$zero" > "$tmp/zero.jsonl"
expect_fail "zero selected scenarios are not green" "$tmp/zero.jsonl"

stream "write /r/features/books.feature" "run $one|$red" "write /r/tests/tags.test.ts" "write /r/src/app.ts" \
       "run $one|$green" "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/inner-in-skeleton.jsonl"
expect_fail "an inner test written during the skeleton" "$tmp/inner-in-skeleton.jsonl"

echo "outer-order: all checks passed"
