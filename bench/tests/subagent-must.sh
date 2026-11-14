#!/usr/bin/env bash
# Check grade.sh's subagent-must: it reads what a started subagent returned, not the final answer.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/codence-bench-sub.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
printf 'subagent-must db\\.ts:\\d+\n' > "$tmp/expect"
stream() {  # <subagent result> <final answer>
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"type": "system", "subtype": "init", "plugins": []}))
print(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "a1", "name": "Agent", "input": {"prompt": "x"}}]}}))
print(json.dumps({"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "a1", "content": [{"type": "text", "text": sys.argv[1]}]}]}}))
print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "result": sys.argv[2]}))
PY
}
verdict() { "$here/grade.sh" "$tmp/expect" "$1" 0 | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["pass"], d["detail"])'; }
stream "場所: src/db.ts:21 ## LENS CLEAN" "閉じました" > "$tmp/ok.jsonl"
[[ "$(verdict "$tmp/ok.jsonl")" == True* ]] || fail "a subagent citing the place should pass"
stream "## LENS CLEAN" "src/db.ts:21 を見ました" > "$tmp/answer-only.jsonl"
[[ "$(verdict "$tmp/answer-only.jsonl")" == False* ]] || fail "the final answer alone should not satisfy subagent-must"
# An external runner started from the shell (runner: command) counts as a fresh context too.
python3 - > "$tmp/codex.jsonl" <<'PY'
import json
print(json.dumps({"type": "system", "subtype": "init", "plugins": []}))
print(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "c1", "name": "Bash", "input": {"command": "codex exec --ephemeral --sandbox read-only -C . < /tmp/p"}}]}}))
print(json.dumps({"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "c1", "content": "場所: src/db.ts:21\n## LENS CLEAN"}]}}))
print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "result": "閉じました"}))
PY
[[ "$(verdict "$tmp/codex.jsonl")" == True* ]] || fail "an external runner's output should satisfy subagent-must"
echo "subagent-must: all checks passed"
