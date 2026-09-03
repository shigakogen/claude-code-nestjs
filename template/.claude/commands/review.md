---
description: Tự review thay đổi hiện tại trước khi mở merge request.
---
Chạy quy trình review nội bộ:

1. `git status` và `git diff` để nắm phạm vi.
2. Gọi subagent `nest-reviewer`.
3. Nếu diff chạm `src/migrations/`, gọi thêm subagent `db-migration-auditor`.
4. Tổng hợp kết quả thành một danh sách hành động ngắn, đánh dấu rõ `[blocker]` và `[nên sửa]`.
5. Hỏi tôi có muốn bạn sửa các mục blocker ngay không. Đừng tự sửa trước khi tôi đồng ý.
