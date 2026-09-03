---
description: Chạy test và sửa test đỏ theo quy trình chuẩn.
argument-hint: [đường dẫn file test hoặc tên test, để trống = chạy toàn bộ]
---
Dùng skill `debug-failing-test`.

Phạm vi: $ARGUMENTS (nếu trống thì chạy `npm run test` cho toàn bộ).

Bắt buộc: xác định nguyên nhân gốc trước khi sửa, không nới lỏng assertion, không thêm `.skip()`.
