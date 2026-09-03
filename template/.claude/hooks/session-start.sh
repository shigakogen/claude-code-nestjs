#!/usr/bin/env bash
# SessionStart: nạp ngữ cảnh động, rẻ, chỉ vài dòng. Không dump cả repo.
set -uo pipefail
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"
changed="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
node_v="$(node -v 2>&1 || echo 'node: n/a')"
compose="down"
if command -v docker >/dev/null 2>&1 && [ -n "$(docker compose ps -q 2>/dev/null)" ]; then compose="up"; fi

printf 'Ngữ cảnh phiên: branch=%s | file thay đổi=%s | node=%s | docker compose=%s\n' \
  "$branch" "$changed" "$node_v" "$compose"
exit 0
