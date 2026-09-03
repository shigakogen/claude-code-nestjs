---
name: perf-triage
description: Chẩn đoán endpoint hoặc truy vấn chậm trong ứng dụng NestJS (N+1, thiếu index, connection pool, transaction dài). Dùng khi người dùng nói "API chậm", "query lâu", "timeout".
allowed-tools: Read, Grep, Glob, Bash(npm run:*), Bash(docker compose:*)
---
# Chẩn đoán hiệu năng

## Thứ tự kiểm tra (từ rẻ đến đắt)
1. **N+1**: đọc code đường đi của request; tìm vòng lặp gọi `findOne`/`find` bên trong loop, hoặc thiếu `relations`/`leftJoinAndSelect` khi cần dữ liệu quan hệ.
   Kiểm chứng: bật TypeORM `logging: true` (hoặc `logging: ["query"]`) ở config local, gọi endpoint, đếm số câu SQL.
2. **Thiếu index**: lấy câu SQL nóng, chạy `EXPLAIN` (Postgres: `EXPLAIN ANALYZE`) qua MCP database ở chế độ chỉ đọc.
   Tìm seq scan / full table scan trên bảng lớn.
3. **Phân trang**: query có dùng `find()` không giới hạn không? Offset (`skip`) lớn trên bảng lớn → đề xuất keyset pagination.
4. **Transaction dài**: có gọi HTTP/Kafka/tính toán nặng bên trong `dataSource.transaction()` không.
5. **Connection pool**: `extra.max` (hoặc pool size của driver) trong `data-source.ts` so với số worker; log timeout xin connection.
6. **Serialization**: response trả về quá nhiều trường/quan hệ lồng nhau → dùng `class-transformer` (`@Exclude()`) hoặc DTO projection thay vì trả cả entity.

## Đầu ra
- Nguyên nhân xếp theo mức độ tin cậy, mỗi cái kèm bằng chứng cụ thể (file:dòng, số câu SQL, kế hoạch EXPLAIN).
- Đề xuất sửa theo thứ tự chi phí thấp → cao, kèm ước lượng tác động.
- Không tự tối ưu hàng loạt; đề xuất trước, người dùng chọn.

## Không làm
- Không chạy lệnh ghi lên database.
- Không thêm cache làm giải pháp đầu tiên khi chưa xác định nguyên nhân.
