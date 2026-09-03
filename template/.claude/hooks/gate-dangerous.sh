#!/usr/bin/env bash
# PreToolUse(Bash): chặn/hoãn các lệnh không hồi phục được.
# deny  = từ chối hẳn, agent nhận lý do và đi tiếp.
# ask   = hỏi người dùng trước khi chạy.
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && { jq -nc '{}'; exit 0; }

deny() { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
ask()  { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'; exit 0; }

case "$cmd" in
  *"git push"*--force*|*"git push"*" -f"*)   deny "Force push bị chặn bởi hook của repo." ;;
  *"git reset --hard"*)                      deny "git reset --hard có thể mất việc chưa commit. Hãy dùng git stash." ;;
  *"git clean -"*d*f*|*"git clean -f"*)      deny "git clean xóa file không hồi phục được." ;;
  *"git commit"*--amend*)                    ask  "Amend commit làm đổi lịch sử. Xác nhận?" ;;
  *"git push"*)                              ask  "Push lên remote cần người xác nhận." ;;
  *"npm publish"*|*"yarn publish"*)          deny "Publish package chỉ chạy trên CI." ;;  # "npm publish" is a substring of "pnpm publish", already covered
  *"docker compose down -v"*|*"docker-compose down -v"*) ask "Lệnh này xóa volume DB local. Xác nhận?" ;;
  *"DROP DATABASE"*|*"drop database"*)        deny "DDL hủy dữ liệu bị chặn." ;;
  *"TRUNCATE"*|*"truncate table"*)            ask  "TRUNCATE xóa toàn bộ dữ liệu bảng. Xác nhận?" ;;
  *"rm -rf /"*)                               deny "Lệnh xóa nguy hiểm." ;;
  *) ;;
esac

# Chặn thao tác chạm môi trường không phải local.
case "$cmd" in
  *prod*|*staging*|*uat*)
    ask "Lệnh có nhắc tới môi trường không phải local. Xác nhận trước khi chạy." ;;
esac

jq -nc '{}'
exit 0
