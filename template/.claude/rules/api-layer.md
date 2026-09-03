---
name: api-layer
description: Quy ước cho tầng controller/DTO/exception filter. Load khi Claude đọc hoặc sửa controller, DTO, guard.
globs:
  - "**/*.controller.ts"
  - "**/*.controller.spec.ts"
  - "src/controller/**"
  - "**/*.dto.ts"
  - "src/dto/**"
  - "**/*.guard.ts"
  - "src/guard/**"
---
# Tầng API

## Controller
- Một controller = một resource. Đặt tên `<Resource>Controller`, decorator `@Controller('api/v{n}/<resource-số-nhiều>')`.
- Method chỉ làm 3 việc: nhận DTO đã validate (`@Body()`), gọi đúng 1 method ở `service/`, map sang response DTO.
- Không mở transaction, không inject repository trực tiếp, không dùng `EntityManager` ở đây.
- POST tạo mới trả 201 kèm header `Location` (`@HttpCode(201)` + set header thủ công nếu cần). DELETE trả 204. Không trả 200 cho mọi thứ.

## DTO
- Request/response là **class** (KHÔNG dùng `type`/`interface`), đặt trong `dto/`. Hậu tố `...Request` / `...Response`.
- Validate bằng decorator `class-validator` (`@IsString()`, `@IsNotEmpty()`...) trên property của class — decorator dựa trên `reflect-metadata`, dùng `type` alias thì validate im lặng không chạy.
- `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` phải đăng ký global trong `main.ts`, nếu không toàn bộ decorator vô nghĩa.
- KHÔNG bao giờ trả entity TypeORM trực tiếp ra ngoài. Map qua DTO bằng `class-transformer` (`plainToInstance`) hoặc mapper thủ công.
- Thông điệp lỗi validation lấy từ message của decorator, không hardcode rải rác.

## Lỗi
- Ném `BusinessException` con; `ExceptionFilter` (đăng ký qua token `APP_FILTER`, không dùng `app.useGlobalFilters()`) là nơi DUY NHẤT dịch exception sang HTTP response.
- Body lỗi luôn theo schema `{ "code", "message", "traceId", "details" }`. Không thêm trường ad-hoc.
- Không nuốt exception bằng `catch (e) { return null; }`.

## Bảo mật
- Mỗi endpoint mới phải có `@UseGuards(...)` rõ ràng hoặc được đánh dấu public tường minh (decorator riêng, không im lặng bỏ qua).
- Không nhận entity trực tiếp làm `@Body()` (tránh mass assignment).

## Test
- Mỗi endpoint mới cần test: happy path, lỗi validation (400), lỗi phân quyền (401/403) — unit test qua `Test.createTestingModule` hoặc e2e qua `supertest`.
