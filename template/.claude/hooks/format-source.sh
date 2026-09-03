#!/usr/bin/env bash
# PostToolUse: format file TS/JS vừa được ghi. Im lặng, không bao giờ làm hỏng phiên làm việc.
set -uo pipefail

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

[ -z "$file" ] && exit 0
case "$file" in
  *.ts|*.js) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
[ -e package.json ] || exit 0

# ESLint --fix rồi Prettier, mỗi cái chỉ chạy nếu dự án có cấu hình tương ứng.
if compgen -G ".eslintrc*" >/dev/null || compgen -G "eslint.config.*" >/dev/null; then
  timeout 90 npx --no-install eslint --fix "$file" >/dev/null 2>&1 || true
fi
if compgen -G ".prettierrc*" >/dev/null || compgen -G "prettier.config.*" >/dev/null; then
  timeout 60 npx --no-install prettier --write "$file" >/dev/null 2>&1 || true
fi
exit 0
