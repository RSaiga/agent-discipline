#!/usr/bin/env bash
# Check grade.sh's tdd-order on hand-written transcripts: red before the first source edit passes,
# an implementation written before any failing test does not, and a permission denial is not a run.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/codence-bench-order.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

echo 'tdd-order src/f\.ts$ vitest' > "$tmp/expect"

# Each step is "edit <path>" or "test <output>"; prints a stream with one tool call per step.
stream() {
  python3 - "$@" <<'EOF'
import json, sys
print(json.dumps({"type": "system", "subtype": "init", "plugins": []}))
for n, step in enumerate(sys.argv[1:]):
    kind, arg = step.split(" ", 1)
    use = {"type": "tool_use", "id": f"t{n}"}
    if kind == "edit":
        use |= {"name": "Edit", "input": {"file_path": arg}}
        out = "updated"
    else:
        use |= {"name": "Bash", "input": {"command": "bunx vitest run | tail -5"}}
        out = arg
    print(json.dumps({"type": "assistant", "message": {"content": [use]}}))
    print(json.dumps({"type": "user", "message": {"content": [
        {"type": "tool_result", "tool_use_id": f"t{n}", "content": out, "is_error": False}]}}))
print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "result": "done"}))
EOF
}
verdict() { "$here/grade.sh" "$tmp/expect" "$1" 0 | python3 -c 'import json,sys; print(json.load(sys.stdin)["pass"])'; }

red='Tests  1 failed | 3 passed (4)'
green='Tests  4 passed (4)'
denial='This command requires approval'

stream "edit /r/test/f.test.ts" "test $red" "edit /r/src/f.ts" "test $green" > "$tmp/ok.jsonl"
[ "$(verdict "$tmp/ok.jsonl")" = True ] || fail "red, then edit, then green should pass"

stream "edit /r/src/f.ts" "test $red" "edit /r/src/f.ts" "test $green" > "$tmp/impl-first.jsonl"
[ "$(verdict "$tmp/impl-first.jsonl")" = False ] || fail "an edit before any failing test should fail"

stream "test $denial" "edit /r/src/f.ts" "test $green" > "$tmp/denied.jsonl"
[ "$(verdict "$tmp/denied.jsonl")" = False ] || fail "a denied command must not count as the red"

stream "test $red" "edit /r/src/f.ts" "test $red" > "$tmp/never-green.jsonl"
[ "$(verdict "$tmp/never-green.jsonl")" = False ] || fail "no passing run after the last edit should fail"

stream "test src/f.ts(3,1): error TS2554: Expected 0 arguments" "edit /r/src/f.ts" "test $green" > "$tmp/tsc.jsonl"
[ "$(verdict "$tmp/tsc.jsonl")" = True ] || fail "a type error counts as a red"

echo "tdd-order: all checks passed"
