---
name: infra-config
description: Quy ước cho package.json, .env, Dockerfile, docker-compose và CI.
globs:
  - "package.json"
  - ".env"
  - ".env.*"
  - "Dockerfile"
  - "docker-compose*.yml"
  - ".gitlab-ci.yml"
---
# Build, cấu hình và hạ tầng

## package.json
- Không thêm/nâng dependency khi chưa được người dùng đồng ý. Nêu lý do và tác động trước.
- Version pin chính xác hoặc dùng lockfile (`package-lock.json`/`yarn.lock`/`pnpm-lock.yaml`) — không để version range quá rộng cho dependency runtime quan trọng.
- Không tắt script `test`, `lint`, `build` để CI xanh giả.

## Cấu hình
- Không commit secret. Giá trị nhạy cảm đọc từ biến môi trường qua `ConfigService`, không hardcode default là mật khẩu thật.
- `.env.example` chứa mặc định an toàn (không phải giá trị thật); `.env` thật không commit.
- Mọi biến môi trường mới phải khai báo trong schema validate của `ConfigModule` (`validate: ...`) với comment ngắn về ý nghĩa.

## Docker
- `docker-compose.yml` chỉ phục vụ local: DB, cache, message broker. Cố định tag image, không dùng `latest`.
- Dockerfile app dùng multi-stage (build stage riêng `node_modules`/`dist`), image runtime slim, chạy user non-root.

## CI
- Pipeline tối thiểu: `install` → `lint` → `test` → `build`. Không thêm stage deploy tự động nếu chưa được yêu cầu.
- Không in biến bí mật ra log CI.
