"""Turn `codex exec --json` events into the stream shape grade.sh reads.

  python3 codex-stream.py <codex.jsonl> <exit-code> > stream.jsonl

Mapping: a completed command_execution becomes a Bash call (the shell wrapper `/bin/zsh -lc '...'` removed) whose result is
the output plus its exit code; a completed file_change becomes one Write call per path with no content (Codex does not
report the text, so checks that read edit contents cannot pass on a Codex run); agent messages are kept; the last one is the
answer. A run without turn.completed, or with an error event, is a failed result, so grade.sh records run_error.
"""
import json, re, shlex, sys

src, code = sys.argv[1], int(sys.argv[2])
out = lambda e: print(json.dumps(e, ensure_ascii=False))
out({"type": "system", "subtype": "init", "plugins": [{"name": "agent-discipline"}], "driver": "codex"})

def unwrap(cmd):
    m = re.match(r"^/bin/(?:zsh|bash|sh) -lc (.*)$", cmd, re.S)
    if not m:
        return cmd
    try:
        return shlex.split(m.group(1))[0]
    except ValueError:
        return m.group(1)

answer, usage, failed, n = "", {}, False, 0
for line in open(src):
    try:
        e = json.loads(line)
    except ValueError:
        continue
    t = e.get("type")
    if t in ("error", "turn.failed"):
        failed = True
    if t == "turn.completed":
        usage = e.get("usage") or {}
    if t != "item.completed":
        continue
    item = e.get("item") or {}
    kind = item.get("type")
    if kind == "agent_message":
        answer = item.get("text") or answer
        out({"type": "assistant", "message": {"content": [{"type": "text", "text": item.get("text", "")}]}})
    elif kind == "command_execution":
        n += 1; tid = f"c{n}"
        out({"type": "assistant", "message": {"content": [{"type": "tool_use", "id": tid, "name": "Bash",
                                                            "input": {"command": unwrap(item.get("command", ""))}}]}})
        body = (item.get("aggregated_output") or "") + f"\n[exit code {item.get('exit_code')}]"
        out({"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": tid, "content": body,
                                                      "is_error": item.get("exit_code") not in (0, None)}]}})
    elif kind == "file_change":
        for ch in item.get("changes") or []:
            n += 1; tid = f"f{n}"
            out({"type": "assistant", "message": {"content": [{"type": "tool_use", "id": tid, "name": "Write",
                                                                "input": {"file_path": ch.get("path", ""), "content": None}}]}})
            out({"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": tid, "content": ch.get("kind", ""),
                                                          "is_error": False}]}})
ok = code == 0 and not failed and bool(usage) and bool(answer.strip())
out({"type": "result", "subtype": "success" if ok else "error", "is_error": not ok, "result": answer,
     "total_cost_usd": 0, "num_turns": n, "codex_usage": usage})
