---
name: new-migration
description: Tạo migration TypeORM mới an toàn cho MySQL/PostgreSQL kèm cập nhật entity và test. Dùng khi cần thêm bảng, thêm cột, thêm index, hoặc đổi schema.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(npm run:*), Bash(ls:*), Bash(docker compose:*)
---
# Tạo migration mới

## Thông tin cần có
1. Thay đổi schema cụ thể là gì (bảng, cột, kiểu, nullable, default, index).
2. Bảng hiện có bao nhiêu dữ liệu (ước lượng) — quyết định có cần chia nhiều bước không.
3. DB đích: MySQL hay PostgreSQL (hoặc cả hai).

## Các bước
1. Đọc `.claude/rules/migrations.md` và `.claude/rules/persistence.md`.
2. Cập nhật entity TypeORM tương ứng trước (`@Column`, nullable, length, index).
3. Sinh migration bằng CLI, không tự viết file/tự đặt tên:
   `npm run typeorm -- migration:generate src/migrations/<Name> -d src/config/data-source.ts`
4. Đọc lại SQL do CLI sinh ra, chỉnh nếu cần:
   - Cột NOT NULL trên bảng có dữ liệu → tách 3 bước (nullable+default → backfill → set NOT NULL) thay vì để CLI sinh 1 bước.
   - Postgres bảng lớn → tách `CREATE INDEX CONCURRENTLY` ra migration riêng.
   - Đảm bảo `down()` hoàn tác đúng những gì `up()` làm.
5. Chạy migration trên container local: `docker compose up -d && npm run typeorm -- migration:run -d src/config/data-source.ts`.
6. Chạy `npm run test`.
7. Gọi subagent `db-migration-auditor`.

## Không làm
- Không sửa file migration đã tồn tại.
- Không chạy migration lên bất kỳ DB nào ngoài container local.
- Không dùng MCP database để thực thi DDL/DML.
