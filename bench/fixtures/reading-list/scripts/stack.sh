#!/usr/bin/env bash
# The acceptance stack: one server process on $PORT with its own database file.
#   scripts/stack.sh up      start it in the background and wait until /health answers (10s at most)
#   scripts/stack.sh down    stop the server this script started (its pid file), and nothing else
#   scripts/stack.sh reset   delete the database file (run while the stack is down)
#   scripts/stack.sh status  say whether our server is running, and whether the port is taken
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${PORT:-4310}"; DB_PATH="${DB_PATH:-.data/reading-list.db}"; pid_file=.data/server.pid
mkdir -p .data
ours() { [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; }
port_taken() { lsof -tnP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; }
case "${1:-}" in
  up)
    if ours; then echo "already running (pid $(cat "$pid_file")) on $PORT"; exit 0; fi
    if port_taken; then echo "port $PORT is used by another process; not starting" >&2; exit 3; fi
    PORT="$PORT" DB_PATH="$DB_PATH" ALLOW_RESET=1 nohup bun run src/server.ts > .data/server.log 2>&1 &
    echo $! > "$pid_file"
    for _ in $(seq 1 50); do curl -sf "http://localhost:$PORT/health" >/dev/null && { echo "up on $PORT (pid $(cat "$pid_file"))"; exit 0; }; sleep 0.2; done
    echo "not ready after 10s; see .data/server.log" >&2; exit 4 ;;
  down)
    if ours; then kill "$(cat "$pid_file")"; echo "stopped pid $(cat "$pid_file")"; else echo "not running"; fi
    rm -f "$pid_file" ;;
  reset)
    if ours; then echo "stop the stack before resetting" >&2; exit 5; fi
    rm -f "$DB_PATH"; echo "database removed" ;;
  status)
    if ours; then echo "running (pid $(cat "$pid_file")) on $PORT"; elif port_taken; then echo "port $PORT taken by another process"; else echo "stopped"; fi ;;
  *) echo "usage: $0 up|down|reset|status" >&2; exit 2 ;;
esac
