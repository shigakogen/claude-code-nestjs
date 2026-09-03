#!/usr/bin/env bash
# PreToolUse(Bash): chặn/hoãn các lệnh không hồi phục được.
# deny  = từ chối hẳn, agent nhận lý do và đi tiếp.
# ask   = hỏi người dùng trước khi chạy.
#
# Nhánh main/master/prod: chặn hẳn (deny) push/merge/rebase/xóa nhánh cưỡng
# bức trực tiếp vào đó. Nhánh uat: không chặn hẳn, luôn hỏi (ask).
#
# Việc xác định "nhánh đích" chỉ là suy luận từ chuỗi lệnh (parse best-effort),
# không phải parser shell thật — command bất thường có thể qua mặt được.
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && { jq -nc '{}'; exit 0; }

deny() { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
ask()  { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'; exit 0; }

is_protected() { case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in main|master|prod) return 0 ;; *) return 1 ;; esac; }
is_uat()       { [ "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" = "uat" ]; }

current_branch() {
  (cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null) || printf ''
}

# Best-effort target branch của `git push ...`: token cuối không phải flag sau
# `push`, refspec local:remote lấy vế phải. Không có target rõ ràng (`git
# push` / `git push origin`) thì coi target là nhánh hiện tại.
push_target_branch() {
  local cmdline="$1" rest w last=""
  local -a words=()
  rest="${cmdline##*push}"
  rest="${rest%%[\&\|\;]*}"
  read -r -a words <<< "$rest"
  for w in "${words[@]}"; do
    case "$w" in -*) continue ;; esac
    last="$w"
  done
  case "$last" in *:*) last="${last##*:}" ;; esac
  case "$last" in ""|origin|upstream) last="$(current_branch)" ;; esac
  printf '%s' "$last"
}

# Best-effort tên nhánh của `git branch -D <name>`.
branch_delete_target() {
  local cmdline="$1" rest w last=""
  local -a words=()
  rest="${cmdline##*branch}"
  rest="${rest%%[\&\|\;]*}"
  read -r -a words <<< "$rest"
  for w in "${words[@]}"; do
    case "$w" in -*) continue ;; esac
    last="$w"
  done
  printf '%s' "$last"
}

case "$cmd" in
  *"git push"*--force*|*"git push"*" -f"*)
    deny "Force push bị chặn bởi hook của repo." ;;
esac

case "$cmd" in
  *"git push"*)
    tgt="$(push_target_branch "$cmd")"
    if is_protected "$tgt"; then
      deny "Push thẳng vào nhánh '$tgt' (main/master/prod) bị chặn. Tạo merge request để được review."
    elif is_uat "$tgt"; then
      ask "Push lên nhánh uat cần người xác nhận."
    else
      ask "Push lên remote cần người xác nhận."
    fi
    ;;
esac

case "$cmd" in
  *"git merge"*|*"git rebase"*)
    cur="$(current_branch)"
    if is_protected "$cur"; then
      deny "Đang ở nhánh '$cur' (main/master/prod) — merge/rebase trực tiếp vào đây bị chặn."
    elif is_uat "$cur"; then
      ask "Đang ở nhánh uat — xác nhận trước khi merge/rebase."
    fi
    ;;
esac

case "$cmd" in
  *"git branch"*"-D"*)
    tgt="$(branch_delete_target "$cmd")"
    if is_protected "$tgt"; then
      deny "Xóa cưỡng bức nhánh '$tgt' (main/master/prod) bị chặn."
    elif is_uat "$tgt"; then
      ask "Xóa cưỡng bức nhánh uat cần người xác nhận."
    fi
    ;;
esac

case "$cmd" in
  *"gh pr merge"*)
    ask "Merge PR có thể trỏ tới nhánh main/master/prod — xác nhận trước khi chạy." ;;
esac

case "$cmd" in
  *"git reset --hard"*)                      deny "git reset --hard có thể mất việc chưa commit. Hãy dùng git stash." ;;
  *"git clean -"*d*f*|*"git clean -f"*)      deny "git clean xóa file không hồi phục được." ;;
  *"git commit"*--amend*)                    ask  "Amend commit làm đổi lịch sử. Xác nhận?" ;;
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
