---
name: debug-failing-test
description: Chẩn đoán và sửa test đỏ hoặc lỗi build trong repo NestJS. Dùng khi người dùng nói "test đỏ", "build fail", "fix test này", hoặc dán log lỗi Jest/TypeScript.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(npm run:*), Bash(npx jest:*), Bash(cat:*), Bash(git diff:*)
---
# Sửa test đỏ

## Nguyên tắc
Xác định phía nào SAI trước khi sửa. Nếu code sai → sửa code. Nếu test mô tả sai kỳ vọng → sửa test và nói rõ vì sao.
KHÔNG bao giờ nới lỏng assertion hay `.skip()` để build xanh.

## Các bước
1. Tái hiện ở phạm vi hẹp nhất: `npx jest <đường/dẫn/file.spec.ts>` hoặc `npm run test -- -t "<tên test>"`.
2. Lấy stack trace đầy đủ từ stdout/stderr của lệnh (Jest không sinh report file mặc định).
3. Phân loại lỗi:
   - Lỗi biên dịch TypeScript → sửa lỗi type trước, chạy lại.
   - Module/DI không khởi tạo được → dùng subagent `log-triage`.
   - Assertion sai → đọc code nghiệp vụ liên quan, đối chiếu với rule trong `.claude/rules/`.
   - Flaky (phụ thuộc thời gian/thứ tự/mock chưa reset) → chạy lại 3 lần để xác nhận, rồi sửa nguyên nhân bất định (thường là thiếu `jest.clearAllMocks()` trong `beforeEach`).
4. Sửa thay đổi nhỏ nhất có thể.
5. Chạy lại test đó, rồi chạy cả file, rồi `npm run test` cho toàn bộ.
6. Tóm tắt: nguyên nhân gốc một câu + những gì đã đổi.

## Không làm
- Không sửa nhiều test cùng lúc khi chưa hiểu nguyên nhân chung.
- Không đổi cấu hình Jest/CI để né lỗi.
