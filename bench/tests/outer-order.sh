#!/usr/bin/env bash
# Check grade.sh's outer-loop checks on hand-written transcripts: the disciplined order passes, and
# each way of breaking it fails.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/ad-bench-outer.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

cat > "$tmp/expect" <<'EOF'
outer-red cucumber|accept\.sh "本にタグを付ける" (tests|src)/
outer-close cucumber|accept\.sh "本にタグを付ける" features/.*\.feature$
no-write-before-green cucumber|accept\.sh "本にタグを付ける" tests/
EOF

# Steps: "write <path>", "edit <path>|<new text, ⏎ for newlines>", "unwip <path>" (an edit that drops @wip), "run <command>|<output>".
stream() {
  python3 - "$@" <<'EOF'
import json, sys
print(json.dumps({"type": "system", "subtype": "init", "plugins": []}))
for n, step in enumerate(sys.argv[1:]):
    kind, arg = step.split(" ", 1)
    use = {"type": "tool_use", "id": f"t{n}"}
    if kind == "write":
        use |= {"name": "Write", "input": {"file_path": arg, "content": "x"}}; out = "ok"
    elif kind == "edit":
        path, text = arg.split("|", 1)
        use |= {"name": "Edit", "input": {"file_path": path, "old_string": "x", "new_string": text.replace("⏎", "\n")}}; out = "ok"
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

# Runners other than cucumber-js: a tag filter or an include-everything flag is not the default run, and
# "No scenarios" (godog) selects nothing.
stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run scripts/accept.sh -t @wip|$all_green" > "$tmp/tag-filter.jsonl"
expect_fail "a tag-filtered run is not the default run" "$tmp/tag-filter.jsonl"
stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run scripts/accept.sh --all|$all_green" > "$tmp/all-flag.jsonl"
expect_fail "an include-everything run is not the default run" "$tmp/all-flag.jsonl"
stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run scripts/accept.sh|No scenarios" > "$tmp/godog-zero.jsonl"
expect_fail "godog's No scenarios is not green" "$tmp/godog-zero.jsonl"
stream "write /r/features/books.feature" "run $one|$red" "write /r/src/app.ts" "run $one|$green" \
       "unwip /r/features/books.feature" "run scripts/accept.sh -f books.feature|$all_green" > "$tmp/godog-ok.jsonl"
expect_pass "a file-scoped run with the default tags" "$tmp/godog-ok.jsonl"

# Reading a test file with stderr folded into a pipe is not a write.
stream "write /r/features/books.feature" "run $one|$red" "run go vet ./... 2>&1 && grep -n x tests/a.test.ts|ok" \
       "write /r/src/app.ts" "run $one|$green" "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/fd-dup.jsonl"
expect_pass "2>&1 is not a write" "$tmp/fd-dup.jsonl"

# With a content pattern, only writes that add a test count: a stub added to an existing mock so the
# test package still compiles is part of the skeleton, a new test function is not.
cp "$tmp/expect" "$tmp/expect.plain"
cat > "$tmp/expect" <<'EOF2'
outer-red cucumber|accept\.sh "本にタグを付ける" (tests|src)/
outer-close cucumber|accept\.sh "本にタグを付ける" features/.*\.feature$
no-write-before-green cucumber|accept\.sh "本にタグを付ける" _test\.go$ ^func Test
EOF2
stream "write /r/features/books.feature" "run $one|$red" "edit /r/src/mock_test.go|func (m *Mock) Stock() int {⏎	return 0⏎}" \
       "write /r/src/app.go" "run $one|$green" "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/stub.jsonl"
expect_pass "a mock stub during the skeleton" "$tmp/stub.jsonl"
stream "write /r/features/books.feature" "run $one|$red" "edit /r/src/stock_test.go|func TestStock(t *testing.T) {⏎}" \
       "write /r/src/app.go" "run $one|$green" "unwip /r/features/books.feature" "run $dflt|$all_green" > "$tmp/newtest.jsonl"
expect_fail "a new test function during the skeleton" "$tmp/newtest.jsonl"
cp "$tmp/expect.plain" "$tmp/expect"

echo "outer-order: all checks passed"
