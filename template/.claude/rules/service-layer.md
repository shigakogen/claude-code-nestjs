---
name: service-layer
description: Quy ước cho tầng service, transaction và business logic. Load khi sửa service/.
globs:
  - "**/*.service.ts"
  - "**/*.service.spec.ts"
  - "src/service/**"
---
# Tầng Service

## Transaction
- Transaction chỉ mở trong `service/`, qua `this.dataSource.transaction(async (manager) => {...})` (inject `DataSource`, không dùng package `typeorm-transactional`).
- Bên trong callback PHẢI dùng `manager` được truyền vào (`manager.getRepository(Entity)` hoặc `manager.save(...)`), không dùng repository đã inject sẵn — repository inject chạy trên connection mặc định, ngoài transaction.
- Không gọi HTTP/Kafka bên trong transaction. Publish event sau khi transaction commit thành công.
- Đọc thuần không cần transaction trừ khi cần consistency giữa nhiều truy vấn.

## Service
- Tên `<Domain>Service`. Một class không quá ~5 public method.
- Constructor injection, field `private readonly`. Không inject qua property (`@Inject()` trên field) trừ khi bắt buộc (circular dependency đã dùng `forwardRef()`).
- Không bắt `catch (e)` chung chung. Bắt đúng loại và bọc lại thành `BusinessException` có `code`.

## Business logic
- Entity giữ invariant của chính nó khi hợp lý; method có nghĩa (`order.cancel(reason)`) tốt hơn setter public tùy tiện.
- Logic nghiệp vụ đặt trong service hoặc entity, không rải vào controller.
- Tiền tệ dùng kiểu `decimal`/số nguyên (cent) + scale rõ ràng, không `number` cho tiền có phần thập phân nhạy cảm. Thời gian dùng `Date`/ISO string UTC, luôn UTC khi lưu.

## Concurrency
- Cập nhật có tranh chấp phải có cột version (optimistic lock qua `@VersionColumn()`) hoặc lock rõ ràng; nêu lựa chọn trong mô tả MR.

## Test
- Service test là unit test với `@nestjs/testing` (`Test.createTestingModule`) + mock provider, không kết nối DB thật.
- Mỗi nhánh nghiệp vụ mới cần ít nhất một test cho case thành công và một cho case lỗi.
