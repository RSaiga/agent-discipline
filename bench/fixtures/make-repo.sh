#!/usr/bin/env bash
# Turn a fixture folder into a git repository the bench can clone, with a fixed author and date so
# the commit id stays the same across machines. Prints the commit id.
#   bench/fixtures/make-repo.sh <fixture-dir> <dest-dir>
set -euo pipefail
src="$(cd "$1" && pwd)"; dest="$2"
case "$dest" in "$src"|"$src"/*) echo "dest must be outside the fixture" >&2; exit 2 ;; esac
[ -e "$dest" ] && { [ -f "$dest/.bench-fixture" ] || { echo "refusing to replace $dest" >&2; exit 2; }; chmod -R u+w "$dest"; rm -rf "$dest"; }
mkdir -p "$dest"
rsync -a --exclude node_modules --exclude .data "$src/" "$dest/"
cd "$dest"
git init -q -b main
git add -A
GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" \
  git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "fixture"
touch .bench-fixture   # marks the folder as ours (untracked, so it is not in the commit)
git rev-parse --short HEAD
