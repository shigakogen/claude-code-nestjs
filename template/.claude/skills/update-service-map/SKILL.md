---
name: update-service-map
description: Quét code để tìm lời gọi/lắng nghe tới service khác (REST, Kafka, RabbitMQ, Redis pub/sub, WebSocket) và đề xuất cập nhật SERVICE_MAP.md. Dùng khi vừa thêm/sửa client gọi service khác, thêm producer/consumer message, hoặc trước khi mở MR nếu diff chạm những thứ đó.
allowed-tools: Read, Grep, Glob, Edit, Bash(git diff:*), Bash(git status:*)
---
# Cập nhật SERVICE_MAP.md

`SERVICE_MAP.md` mô tả bề mặt giao tiếp của service này với các service khác. Hệ thống
chưa có contract hình thức (không OpenAPI registry, không schema registry) — mọi mục dưới
đây được SUY LUẬN từ code, không phải đọc từ một nguồn sự thật nào cả. Luôn xác nhận với
người dùng trước khi ghi.

## Trước khi quét
Nếu chưa rõ service này dùng những kênh giao tiếp nào, hỏi người dùng xác nhận trong số:
REST, Kafka, RabbitMQ, Redis pub/sub, WebSocket/socket.io. Đừng quét mù toàn bộ nếu người
dùng đã biết rõ chỉ dùng 1-2 kênh — quét đúng phạm vi tiết kiệm thời gian và tránh nhiễu.

## Các bước
1. Đọc `SERVICE_MAP.md` hiện có (nếu có) làm baseline — không viết lại từ đầu.
2. Nếu đang trong một phiên vừa sửa code, ưu tiên `git diff`/`git status` để khoanh vùng
   file cần xem, thay vì quét lại toàn repo mỗi lần.
3. Tìm lời gọi RA:
   - REST đồng bộ: `HttpService`/`HttpModule` của `@nestjs/axios`, hoặc `axios`/`fetch` gọi trực tiếp.
   - Kafka/RabbitMQ qua `@nestjs/microservices`: `ClientProxy.emit()`/`.send()`.
   - Redis pub/sub: `.publish(` (ioredis) hoặc `RedisClient` tương đương.
   - WebSocket/socket.io: `@WebSocketGateway().server.emit(`, hoặc `io.emit(`/`socket.emit(`.
4. Tìm điểm nhận VÀO (ngoài REST controller — đã có ở `api-layer.md`):
   - Kafka/RabbitMQ: `@MessagePattern`/`@EventPattern`.
   - Redis pub/sub: subscriber đăng ký `.on('message', ...)` hoặc tương đương.
   - WebSocket: `@SubscribeMessage`, hoặc `io.on(`/`socket.on(`.
5. Với mỗi phát hiện, xác định: service/topic/queue/channel đích hoặc nguồn, mục đích một
   câu. Không tự suy đoán *ai gọi mình từ bên ngoài* — một service đơn lẻ không thể biết
   điều đó; để nguyên mục "Được gọi bởi" là "chưa xác định".
6. Trình bày danh sách đề xuất THÊM/SỬA/XÓA cho người dùng, nói rõ cái nào là suy luận
   mới, cái nào giữ nguyên từ baseline. Chờ xác nhận trước khi ghi.
7. Sau khi được xác nhận, `Edit` `SERVICE_MAP.md` — chỉ những mục đã xác nhận.

## Không làm
- Không tự đoán "Được gọi bởi" khi không thấy bằng chứng trong code của repo này.
- Không sửa code nghiệp vụ trong skill này — chỉ cập nhật `SERVICE_MAP.md`.
- Không xóa một mục đã có mà không hỏi, kể cả khi không còn tìm thấy trong code (có thể do quét thiếu phạm vi, không phải do mục đó sai).
