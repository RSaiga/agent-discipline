#!/usr/bin/env bash
# Grade one run. Prints {"status", "pass", "findings", "detail"}.
#
#   bench/grade.sh <expect> <stream.jsonl> <exit-code>
#
# status is "ok" only when the CLI exited 0 and emitted a successful, non-error result
# with a non-empty answer. Any other run is "run_error" with pass=null, so a failed run
# is never counted as a quality result.
#
# expect lines:
#   finding-heading <regex>          a heading line for one finding; named groups
#                                    (?P<name>...) and (?P<loc>...) identify it
#   expect-finding <name-re> <loc-re>  some finding must have a matching name and location
#   max-findings <n>                   at most n findings (false positives)
#   must <regex>                       the answer must match (prefer expect-finding)
#   plugin-loaded <regex>              some plugin in the init event matches (guards the no-* checks)
#   no-skill <regex>                   no Skill tool call names a matching skill
#   no-read <regex>                    no Read tool call opens a matching path
#   subagent-must <regex>              what some started subagent returned must match (not the final answer)
#   tdd-order <src-re> <test-cmd-re>   red before green, read from the stream: a test command
#                                      (a Bash call matching test-cmd-re) fails before the first
#                                      edit of a matching source file, and one passes after the last
#                                      such edit. Failure is read from the output (exit codes are
#                                      often hidden by pipes); permission denials are not runs.
#   outer-red <cmd-re> <name> <paths-re> the acceptance scenario <name> fails on behaviour (a run of
#                                      cmd-re whose command or output names it, with a failed
#                                      scenario that is not merely undefined) before the first write
#                                      to paths-re (inner tests or code)
#   outer-close <cmd-re> <name> <feature-re>  @wip leaves the scenario's feature file only after a
#                                      run naming <name> passed, and a later default run (no
#                                      profile, tag or include-all override) selected and passed
#                                      scenarios
#   no-write-before-green <cmd-re> <name> <paths-re> [<content-re>]  nothing matching paths-re is
#                                      written before the first passing run naming <name> (the
#                                      skeleton has no inner tests); with content-re, only edits whose
#                                      new text matches it count (a stub added to an existing mock
#                                      is not a test)
#   Writes are file-edit tool calls plus shell commands that redirect, tee, or edit in place.
set -euo pipefail
python3 - "$1" "$2" "$3" <<'EOF'
import json, re, sys
expect, raw, code = sys.argv[1], sys.argv[2], int(sys.argv[3])

def out(**kw):
    kw["pass"] = kw.pop("pass_")
    print(json.dumps(kw, ensure_ascii=False)); sys.exit(0)

result, init, calls, results = None, {}, [], {}
try:
    for line in open(raw):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d.get("type") == "result":
            result = d
        elif d.get("type") == "system" and d.get("subtype") == "init":
            init = d
        elif d.get("type") == "assistant":
            calls += [c for c in d["message"]["content"] if c.get("type") == "tool_use"]
        elif d.get("type") == "user" and isinstance(d["message"].get("content"), list):
            for c in d["message"]["content"]:
                if c.get("type") == "tool_result":
                    body = c.get("content")
                    results[c.get("tool_use_id")] = body if isinstance(body, str) else json.dumps(body, ensure_ascii=False)
except OSError:
    pass
answer = (result or {}).get("result") or ""
if code != 0 or result is None or result.get("is_error") or result.get("subtype") != "success" or not answer.strip():
    reason = f"exit={code}" if code != 0 else "no result" if result is None else \
             "is_error" if result.get("is_error") else f"subtype={result.get('subtype')}" \
             if result.get("subtype") != "success" else "empty answer"
    out(status="run_error", pass_=None, findings=None, detail=reason)

heading, expected, must, max_findings = None, [], [], None
plugin_loaded, no_skill, no_read, tdd_order = [], [], [], []
outer_red, outer_close, no_write_before = [], [], []
subagent_must = []
for line in open(expect):
    key, _, value = line.strip().partition(" ")
    if key == "finding-heading":
        heading = re.compile(value, re.M)
    elif key == "expect-finding":
        name, loc = value.split(" ", 1)
        expected.append((name, loc))
    elif key == "must":
        must.append(value)
    elif key == "max-findings":
        max_findings = int(value)
    elif key == "plugin-loaded":
        plugin_loaded.append(value)
    elif key == "no-skill":
        no_skill.append(value)
    elif key == "subagent-must":
        subagent_must.append(value)
    elif key == "no-read":
        no_read.append(value)
    elif key == "tdd-order":
        tdd_order.append(value.split(" ", 1))
    elif key in ("outer-red", "outer-close", "no-write-before-green"):
        # <cmd-re> "<scenario name>" <path-re> [<content-re>]: the name is quoted because it contains spaces.
        m = re.match(r'(\S+) "([^"]+)" (\S+)(?: (.+))?$', value)
        if key == "no-write-before-green":
            no_write_before.append(m.groups())
        else:
            {"outer-red": outer_red, "outer-close": outer_close}[key].append(m.groups()[:3])

found = [m.groupdict() for m in heading.finditer(answer)] if heading else []
missed = [f"{n} @ {l}" for n, l in expected
          if not any(re.search(n, f.get("name") or "", re.I) and re.search(l, f.get("loc") or "")
                     for f in found)]
missed += [m for m in must if not re.search(m, answer, re.I)]
plugins = [json.dumps(p) for p in init.get("plugins", [])]
missed += [f"plugin {p} not loaded" for p in plugin_loaded if not any(re.search(p, x) for x in plugins)]
skills_called = [str((c.get("input") or {}).get("skill") or (c.get("input") or {}).get("command") or "")
                 for c in calls if c.get("name") in ("Skill", "SlashCommand")]
reads = [str((c.get("input") or {}).get("file_path") or "") for c in calls if c.get("name") == "Read"]
missed += [f"skill {s_} called" for p in no_skill for s_ in skills_called if re.search(p, s_)]
missed += [f"read {r}" for p in no_read for r in reads if re.search(p, r)]
# A fresh context is a subagent call, or an external runner started from the shell (runner: command).
sub_text = "\n".join(results.get(c.get("id"), "") for c in calls if c.get("name") in ("Agent", "Task")
                     or (c.get("name") == "Bash" and re.search(r"\bcodex\s+exec\b", str((c.get("input") or {}).get("command") or ""))))
missed += [f"subagent-must {p}" for p in subagent_must if not re.search(p, sub_text)]
ansi = re.compile(r"\x1b\[[0-9;]*m")
failed = re.compile(r"error TS\d+|\b\d+ failed\b|^\s*FAIL\b", re.M)
denied = re.compile(r"requires approval|Approve only if you trust it|can't be checked before it runs|permission", re.I)
for src_re, cmd_re in tdd_order:
    steps = []  # ("edit", None) or ("test", passed)
    for c in calls:
        i = c.get("input") or {}
        if c.get("name") in ("Edit", "Write", "MultiEdit", "NotebookEdit") and re.search(src_re, str(i.get("file_path") or "")):
            steps.append(("edit", None))
        elif c.get("name") == "Bash" and re.search(cmd_re, str(i.get("command") or "")):
            body = ansi.sub("", results.get(c.get("id"), ""))
            if not denied.search(body[:400]):
                steps.append(("test", not failed.search(body)))
    edits = [k for k, (t, _) in enumerate(steps) if t == "edit"]
    if not edits:
        missed.append(f"tdd-order: no edit of {src_re}")
        continue
    if not any(t == "test" and ok is False for t, ok in steps[:edits[0]]):
        missed.append("tdd-order: no failing test before the first source edit")
    if not any(t == "test" and ok for t, ok in steps[edits[-1] + 1:]):
        missed.append("tdd-order: no passing test after the last source edit")
scen = re.compile(r"(\d+) scenarios? \(([^)]*)\)|(\b0 scenarios\b)")
def outer_runs(cmd_re):
    for k, c in enumerate(calls):
        if c.get("name") != "Bash" or not re.search(cmd_re, str((c.get("input") or {}).get("command") or "")):
            continue
        body = ansi.sub("", results.get(c.get("id"), ""))
        if denied.search(body[:400]):
            continue
        m = scen.search(body)
        if not m:
            continue
        counts = m.group(2) or ""
        n = 0 if m.group(3) else int(m.group(1))
        yield k, str(c["input"]["command"]), body, n, counts
def writes(paths_re, content_re=None):
    # content_re keeps only edits whose new text matches it; shell writes cannot be read that way and
    # always count.
    out = []
    for k, c in enumerate(calls):
        i = c.get("input") or {}
        if c.get("name") in ("Edit", "Write", "MultiEdit", "NotebookEdit") and re.search(paths_re, str(i.get("file_path") or "")):
            text = str(i.get("new_string") or i.get("content") or "") + "".join(str(e.get("new_string") or "") for e in i.get("edits") or [])
            if content_re is None or re.search(content_re, text, re.M):
                out.append((k, c))
        elif c.get("name") == "Bash" and re.search(paths_re, str(i.get("command") or "")) and \
                re.search(r"(>|\btee\b|sed -i|perl -pi|\bmv\b|\bcp\b)", re.sub(r"\d*>&\d", "", str(i.get("command") or ""))):
            out.append((k, c))
    return out
names = lambda name, cmd, body: name in cmd or name in body
failed_run = lambda n, counts: n > 0 and re.search(r"\d+ failed", counts)
passed_run = lambda n, counts: n > 0 and not re.search(r"failed|undefined|pending|ambiguous", counts)
for cmd_re, name, paths in outer_red:
    first = min([k for k, _ in writes(paths)], default=len(calls))
    if not any(k < first and names(name, c, b) and failed_run(n, ct) for k, c, b, n, ct in outer_runs(cmd_re)):
        missed.append(f"outer-red: {name} did not fail on behaviour before the first write to {paths}")
for cmd_re, name, feature in outer_close:
    removed = [k for k, c in writes(feature) if "@wip" in str((c.get("input") or {}).get("old_string") or "")
               and "@wip" not in str((c.get("input") or {}).get("new_string") or "")]
    if not removed:
        missed.append(f"outer-close: @wip never removed from {feature}")
        continue
    runs = list(outer_runs(cmd_re))
    if not any(k < removed[0] and names(name, c, b) and passed_run(n, ct) for k, c, b, n, ct in runs):
        missed.append(f"outer-close: @wip removed before {name} passed")
    if not any(k > removed[0] and not re.search(r"-p +all|--tags|--profile|\s-t\s|--all\b", c) and passed_run(n, ct) for k, c, b, n, ct in runs):
        missed.append("outer-close: no default run selected and passed after @wip was removed")
for cmd_re, name, paths, content_re in no_write_before:
    green = min([k for k, c, b, n, ct in outer_runs(cmd_re) if names(name, c, b) and passed_run(n, ct)], default=len(calls))
    early = [str((c.get("input") or {}).get("file_path") or "shell") for k, c in writes(paths, content_re) if k < green]
    if early:
        missed.append(f"no-write-before-green: {name} wrote {early[:3]} before it passed")
over = max_findings is not None and len(found) > max_findings
detail = f"findings={len(found)}" + (f" missed={missed}" if missed else "") + (" over-limit" if over else "")
out(status="ok", pass_=not missed and not over, findings=len(found), detail=detail)
EOF
