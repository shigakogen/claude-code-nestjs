---
name: persistence
description: Quy ước TypeORM entity/repository/query và hiệu năng truy vấn. Load khi sửa entity/ hoặc repository.
globs:
  - "**/*.entity.ts"
  - "**/*.repository.ts"
  - "src/entity/**"
---
# Tầng Persistence

## Entity
- KHÔNG set `eager: true` trên `@ManyToOne`/`@OneToMany`/`@ManyToMany` — mặc định TypeORM đã là `eager: false`, cứ để mặc định và nạp tường minh khi cần.
- KHÔNG dùng lazy relation kiểu property `Promise<T>` (`@ManyToOne(() => X, x => x.ys) ys: Promise<Y[]>`) — TypeORM tự nhận là cơ chế không chuẩn, dễ gây bug khó debug. Dùng `relations: [...]` hoặc `leftJoinAndSelect` tường minh trong query.
- Tên bảng/cột snake_case, khai báo tường minh bằng `@Entity({ name: '...' })`/`@Column({ name: '...' })`, không dựa vào naming strategy ngầm định.
- Cột nhạy cảm (tiền, thời gian) khai báo `type` tường minh trong `@Column()`, không để TypeORM tự suy luận từ kiểu TS.

## Query
- Danh sách luôn phân trang (`take`/`skip`, hoặc keyset cho offset lớn). Không có repository method trả `find()` không giới hạn cho bảng có thể lớn.
- Truy vấn cần quan hệ: dùng `relations: [...]` trong `find()` hoặc `leftJoinAndSelect` trong `QueryBuilder` để tránh N+1 — không loop gọi `findOne` bên trong vòng lặp.
- Query builder chỉ khi `find()`/`findOne()` không diễn đạt được; kèm comment nêu lý do.
- Không nối chuỗi vào câu query (`query(\`... ${x}\`)`). Luôn tham số hóa (`query('...', [x])` hoặc QueryBuilder `.where('x = :x', { x })`).

## MySQL / PostgreSQL
- Kiểu tiền: `decimal(19,4)` hoặc lưu cent bằng `bigint`. Kiểu thời gian: `timestamp` lưu UTC (Postgres: `timestamptz`).
- Cột dùng trong `WHERE`/`ORDER BY` của truy vấn nóng phải có index (`@Index()`) — thêm trong cùng migration.
- Postgres: không `SELECT ... FOR UPDATE` trên truy vấn quét rộng. MySQL: chú ý gap lock ở isolation REPEATABLE READ.

## Cấm
- Không `synchronize: true` ở bất kỳ profile nào ngoài test/local — dùng migration.
- Không dùng MCP database để chạy `INSERT`/`UPDATE`/`DELETE`/`DROP`. MCP DB chỉ để đọc schema và `SELECT` phục vụ chẩn đoán.
