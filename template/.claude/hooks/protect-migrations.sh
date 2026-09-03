#!/usr/bin/env bash
# PreToolUse(Edit|Write): cấm sửa file migration đã được commit vào lịch sử git.
set -uo pipefail

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
[ -z "$file" ] && { jq -nc '{}'; exit 0; }

case "$file" in
  *src/migrations/*) ;;
  *) jq -nc '{}'; exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || { jq -nc '{}'; exit 0; }
rel="${file#"$CLAUDE_PROJECT_DIR"/}"

if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
  jq -nc --arg r "Migration '$rel' đã được commit nên là bất biến. Hãy tạo file migration MỚI thay vì sửa file này (xem .claude/rules/migrations.md)." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

jq -nc '{}'
exit 0
