---
name: migrations
description: Quy ước migration TypeORM cho MySQL và PostgreSQL. Load khi chạm src/migrations.
globs:
  - "src/migrations/**"
---
# Database migration

## Tạo migration
- Lệnh: `npm run typeorm -- migration:generate src/migrations/<Name> -d src/config/data-source.ts` (script `typeorm` trong `package.json` phải trỏ `typeorm-ts-node-commonjs`, không phải `typeorm` CLI cũ).
- KHÔNG tự đặt tên file — để CLI sinh ra `<timestamp>-<Name>.ts` (timestamp là số, không phải chuỗi tự gõ).
- Chạy: `npm run typeorm -- migration:run -d src/config/data-source.ts`.

## Bất biến
- File migration đã merge vào nhánh chính là BẤT BIẾN. Sửa lỗi bằng migration mới, không sửa file cũ.
- Một migration = một thay đổi có nghĩa. Cả `up()` và `down()` đều phải viết, `down()` không được để trống nếu `up()` có thể hoàn tác được.
- Kèm comment đầu file: mục đích + ticket id.

## Nội dung
- Thêm cột NOT NULL trên bảng có dữ liệu phải làm 3 bước qua nhiều lần release:
  1) thêm cột nullable + default, 2) backfill, 3) set NOT NULL.
- Không xóa cột/bảng trong cùng release với code còn đọc nó. Expand → migrate → contract.
- Đồng bộ với entity TypeORM tương ứng (`@Column` type/length/nullable phải khớp cột thật) trong cùng diff.

## Bảng lớn
- PostgreSQL: `CREATE INDEX CONCURRENTLY` (đặt trong migration riêng, ngoài transaction — TypeORM query runner mặc định bọc transaction, cần `queryRunner.query('CREATE INDEX CONCURRENTLY ...')` với transaction tắt cho migration đó).
- MySQL: nêu rõ thuật toán online DDL (`ALGORITHM=INPLACE, LOCK=NONE`) khi có thể; nếu không, cảnh báo downtime trong mô tả MR.

## Cấm
- Không viết `UPDATE`/`DELETE` không có `WHERE`.
- Không nhúng dữ liệu môi trường (host, credential, id cụ thể của prod) vào migration.
- Không chạy migration lên DB thật từ phiên Claude. Chỉ chạy trên container local.
