---
name: new-endpoint
description: Tạo một REST endpoint mới đầy đủ tầng (controller, DTO, service, test) theo kiến trúc và quy ước của repo. Dùng khi người dùng nói "thêm API", "tạo endpoint", "làm API cho ...".
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(npm run:*), Bash(git status:*), Bash(git diff:*)
---
# Thêm endpoint mới

## Thông tin cần có trước khi viết code
Nếu thiếu, HỎI người dùng, đừng đoán:
1. HTTP method + path + version (`POST /api/v1/orders`).
2. Request body / query param và ràng buộc validation.
3. Response và mã trạng thái thành công.
4. Quyền truy cập (guard nào, hay public).
5. Có chạm DB không: đọc bảng nào, có ghi không.

## Các bước
1. Đọc `.claude/rules/api-layer.md` và `.claude/rules/service-layer.md`.
2. Tìm một endpoint tương tự đã có trong repo và bám theo đúng phong cách của nó (đặt tên, DTO, guard, test).
3. Viết theo thứ tự: DTO (class + class-validator) → method ở `service/` → controller → khai báo guard.
4. Test (dùng framework test hiện có của repo — Jest mặc định):
   - Unit test cho service: một case thành công, một case lỗi nghiệp vụ.
   - Test cho controller (unit qua `Test.createTestingModule` hoặc e2e qua `supertest`): happy path, 400 validation, 401/403 phân quyền.
5. Nếu cần cột/bảng mới → dừng lại, dùng skill `new-migration` trước.
6. Chạy `npm run lint` rồi `npm run test -- <pattern>`.
7. Gọi subagent `nest-reviewer` để soát lại.

## Không làm
- Không tạo endpoint trả entity TypeORM.
- Không thêm dependency mới.
- Không tự commit hay push.
