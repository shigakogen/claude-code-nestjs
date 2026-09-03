---
name: mr-checklist
description: Chuẩn bị merge request GitLab - chạy check, tự review, sinh mô tả MR theo template. Dùng khi người dùng nói "tạo MR", "chuẩn bị PR", "xong rồi, đẩy lên review".
allowed-tools: Read, Grep, Glob, Bash(npm run:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---
# Chuẩn bị Merge Request

## Các bước
1. `git status` và `git diff` — xác nhận phạm vi thay đổi đúng ý định, không có file rác, không có secret.
2. `npm run lint` rồi `npm run test`. Phải xanh mới đi tiếp.
3. Nếu diff chạm `src/migrations/` → gọi subagent `db-migration-auditor`.
4. Gọi subagent `nest-reviewer`. Sửa hết mục `[blocker]` rồi chạy lại bước 2.
5. Cập nhật `CHANGELOG.md` mục `## Unreleased` nếu có thay đổi ảnh hưởng người dùng.
6. Commit theo Conventional Commits: `feat(order): add cancel endpoint`. Message bằng tiếng Anh.
7. Sinh mô tả MR theo template dưới đây và đưa cho người dùng (hoặc tạo MR qua MCP GitLab nếu người dùng yêu cầu rõ).

## Template mô tả MR
```
## Mục đích
<1-3 câu: giải quyết vấn đề gì, ticket nào>

## Thay đổi
- <liệt kê theo tầng: controller / service / persistence / migration / test>

## Ảnh hưởng schema
<không có | mô tả migration, rủi ro khóa bảng, thứ tự deploy>

## Cách kiểm thử
- <lệnh npm đã chạy và kết quả>
- <cách kiểm thử thủ công nếu có>

## Rủi ro & rollback
<điểm cần chú ý khi deploy, cách quay lui>
```

## Không làm
- KHÔNG `git push`. Người dùng tự push, hoặc xác nhận rõ ràng từng lần.
- Không tạo MR khi test còn đỏ.
- Không gộp refactor không liên quan vào cùng MR.
