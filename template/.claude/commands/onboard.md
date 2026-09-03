---
description: Khảo sát nhanh một repo NestJS lạ và tóm tắt kiến trúc, cách build, điểm rủi ro.
---
Khảo sát repo này và trả về bản tóm tắt ngắn (tiếng Việt):

1. Đọc `package.json`: script build/test/lint, NestJS version, TypeORM hay Prisma, package manager (npm/yarn/pnpm theo lockfile).
2. Đọc `.env`/`.env.example` và module config (`ConfigModule`): profile nào, DB gì, cổng, tích hợp ngoài.
3. Liệt kê thư mục top-level dưới `src/` và mô tả vai trò từng cái trong một câu.
4. Đếm và liệt kê 10 endpoint đầu tiên (grep `@Get\(|@Post\(|@Put\(|@Patch\(|@Delete\(`).
5. Đọc `src/migrations/` (hoặc đường dẫn migration thật của repo): bao nhiêu migration, timestamp mới nhất.
6. Đọc `.gitlab-ci.yml` (nếu có): pipeline gồm stage nào.
7. Nêu 3-5 điểm rủi ro/mùi code đáng chú ý nhất kèm file:dòng.

Cuối cùng, đề xuất những dòng cần chỉnh trong `.claude/CLAUDE.md` cho khớp repo này (chỉ đề xuất, chưa sửa).

Nếu service này giao tiếp với service khác (REST, Kafka, RabbitMQ, Redis pub/sub,
WebSocket/socket.io...), gợi ý người dùng chạy skill `update-service-map` sau khi khảo sát
xong để dựng bản nháp đầu tiên cho `SERVICE_MAP.md` — đừng lặp lại việc quét đó ở bước
khảo sát này.

Nếu service có luồng xử lý nội bộ đủ phức tạp để đáng vẽ (nhiều bước xử lý, nhiều tầng lưu
trữ, queue/pipeline...), gợi ý người dùng chạy `/service-flow` để dựng `FLOW.md` — sau khi
`SERVICE_MAP.md` đã ổn định.
