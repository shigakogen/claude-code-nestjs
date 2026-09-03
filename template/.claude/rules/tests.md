---
name: tests
description: Quy ước viết và chạy test. Load khi Claude tạo hoặc sửa file test.
globs:
  - "**/*.spec.ts"
  - "test/**"
---
# Test

## Phân tầng
- Unit test: Jest, `Test.createTestingModule` + mock provider, không kết nối DB/HTTP thật. Nhanh, chiếm đa số.
- Integration/e2e: đặt trong `test/`, đặt tên `*.e2e-spec.ts`, chạy bằng `npm run test:e2e`, dùng `supertest` gọi qua app thật (Testcontainers hoặc docker-compose cho DB).

## Luật
- Không gọi mạng thật trong unit test. Mock provider qua `useValue`/`useFactory`, hoặc `nock`/`msw` cho HTTP ngoài.
- Không `setTimeout`/sleep để chờ async. Dùng `await`/fake timers của Jest (`jest.useFakeTimers()`).
- Không phụ thuộc thứ tự chạy test và không chia sẻ state tĩnh giữa các test (`beforeEach` reset mock).
- Tên test: `should <kết quả> when <điều kiện>`. Cấu trúc given/when/then (arrange/act/assert) rõ ràng.
- Assert bằng Jest matcher (`expect(...).toEqual(...)`). Một hành vi một test; tránh assert 10 thứ trong một `it`.
- Dữ liệu test tạo qua factory/builder trong `test/fixture/` hoặc file cạnh test, không copy-paste khối khởi tạo dài.

## Khi test đỏ
- Chạy đúng test đó trước: `npm run test -- <pattern>` hoặc `npx jest <file>`.
- Đọc stack trace trước khi sửa. KHÔNG bao giờ sửa test cho khớp code sai — xác định phía nào sai rồi mới sửa.
- Không thêm `.skip()`/`.only()` để làm xanh build rồi để quên. Nếu buộc phải bỏ qua, hỏi người dùng.

## Coverage
- Mọi nhánh `if`/`switch` nghiệp vụ mới phải có test. Không cần chạy theo con số coverage tổng.
