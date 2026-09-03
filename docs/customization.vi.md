# Tuỳ chỉnh

Installer cho bạn một baseline chạy được. Đây là những chỉnh sửa để nó khớp với *repo của bạn*. Dự trù mười phút.

🇬🇧 [English](customization.md)

## 1. Sửa glob trước tiên

Các file rule mặc định dùng layout **layered-by-type**, khớp với repo NestJS nội bộ thật dùng làm tham chiếu khi xây kit này:

```
src/controller/  service/  entity/  dto/  guard/
```

Glob theo hậu tố filename (`**/*.controller.ts`, `**/*.service.ts`, ...) là match chính trong mọi rule, nên chúng vẫn nạp đúng kể cả khi repo của bạn **không** dùng layout thư mục này — quy ước đặt tên của NestJS đủ mạnh để chỉ riêng hậu tố thường là đủ.

Nếu repo của bạn dùng style **feature-colocated** mặc định của Nest CLI (`src/orders/orders.controller.ts`, `orders.service.ts`, `orders.module.ts` đều nằm chung một thư mục), thì glob theo thư mục (`src/controller/**` v.v.) đơn giản là không bao giờ khớp — vô hại, vì glob theo hậu tố đã bao phủ rồi, nhưng bạn có thể bỏ các pattern thư mục chết đi để frontmatter gọn hơn:

```yaml
# .claude/rules/api-layer.md
globs:
  - "**/*.controller.ts"
  - "**/*.controller.spec.ts"
  - "**/*.dto.ts"
  - "**/*.guard.ts"
```

Kiểm tra: mở `claude`, bảo nó đọc một controller, rồi xem `/context` — rule phải xuất hiện là đã nạp.

## 2. Sửa lệnh build

Mục *Build & test* trong `CLAUDE.md` là thứ agent copy mỗi khi nó chạy bất cứ gì. Lệnh sai ở đó tốn một lượt vô ích mỗi lần.

Xoá dòng cho tooling bạn không có. Không có config ESLint hay Prettier? `format-source.sh` đã tự kiểm tra trước khi chạy và thoát êm nếu không có cái nào, nên không gãy gì — nhưng đừng bảo agent chạy `npm run lint` nếu script đó không tồn tại.

Nếu không có source set e2e riêng, bỏ dòng `test:e2e` thay vì để lại tên script không tồn tại.

## 3. Dùng yarn hoặc pnpm thay vì npm

Kit vẫn chạy; chỉ có lệnh là sai. `install.sh` đã tự phát hiện package manager từ lockfile và in ra ở dòng header, nhưng mục *Build & test* trong `CLAUDE.md` luôn hiển thị `npm run ...` — thay nó:

```markdown
## Build & test
- Build:           `pnpm build`
- Unit test:        `pnpm test`
- One test:         `pnpm test -- <pattern>`
- E2E:              `pnpm test:e2e`
- Lint + format:    `pnpm lint`
- Run local:        `docker compose up -d && pnpm start:dev`
```

(đổi `pnpm` thành `yarn` nếu cần). Sau đó cập nhật `tools:` allowlist trong mỗi agent (`Bash(pnpm:*)` thay vì `Bash(npm run:*)`), `allowed-tools` trong mỗi skill, và `permissions.allow` trong `.claude/settings.json`.

## 4. Dùng Prisma thay vì TypeORM

`persistence.md` và `migrations.md` giả định entity dạng decorator của TypeORM và CLI `migration:generate`/`migration:run` của nó. Với Prisma:

- Thay quy ước entity bằng quy ước model `schema.prisma` (đặt tên, relation mode, khai báo index).
- Thay mục CLI migration bằng `npx prisma migrate dev --name <name>` (local) / `npx prisma migrate deploy` (CI), và rule bất biến bằng quy ước lịch sử migration riêng của Prisma (`prisma/migrations/`, không bao giờ sửa một folder đã apply ở đâu đó).
- `protect-migrations.sh` khớp `*src/migrations/*` — đổi thành `*prisma/migrations/*`.
- Pattern transaction trong `service-layer.md` (`dataSource.transaction()`) trở thành `prisma.$transaction(async (tx) => {...})`; cập nhật rule đó và checklist của agent `nest-reviewer` tương ứng.
- Cách trình bày N+1/eager-loading trong `persistence.md` là đặc thù của TypeORM (`eager: true`, `relations: [...]`); tương đương bên Prisma là `include`/`select` — lời khuyên gốc (fetch relation tường minh, tránh query từng dòng trong vòng lặp) vẫn giữ nguyên, chỉ tên API đổi.

## 5. Dùng GitHub, Bitbucket hoặc Gitea thay vì GitLab

Thay khối `gitlab` trong `.mcp.json`:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
}
```

Cập nhật `enabledMcpjsonServers` trong `.claude/settings.json` cho khớp, và đổi tên "merge request" thành "pull request" trong `mr-checklist/SKILL.md` và `CLAUDE.md`.

## 6. Monorepo (Nx, nhiều app/lib)

Với workspace Nx hoặc layout `apps/*`/`libs/*`, ưu tiên **một file rule cho mỗi app hoặc lib** thay vì một bộ rule khổng lồ:

```yaml
# .claude/rules/app-payment.md
globs:
  - "apps/payment/**"
```

Rule của mỗi app khi đó có thể mang lệnh build riêng (`nx test payment`) và quy ước riêng. Giữ các rule dùng chung — `tests.md`, `migrations.md` — ở mức toàn workspace.

Nếu các app do các team khác nhau sở hữu, `.claude/rules/` cũng là nơi ghi chú về quyền sở hữu, không phải `CLAUDE.md`.

## 7. Siết chặt hoặc nới lỏng permission

`.claude/settings.json` cố tình cấu hình thận trọng. Hai hướng để điều chỉnh:

**Siết chặt hơn** — với repo động đến tiền hoặc dữ liệu cá nhân, chuyển `Edit(src/**)` từ `allow` sang `ask`, và thêm `Bash(docker compose:*)` vào `ask`.

**Nới lỏng hơn** — với repo sandbox cá nhân, chuyển `Bash(git commit:*)` sang `allow`. Giữ `git push` trong `ask`; ranh giới đó đáng giữ ở mọi nơi.

Kiểm tra `.claude/logs/denied.jsonl` sau vài tuần. Nó cho biết bằng dữ liệu thực tế nên chỉnh theo hướng nào.

## 8. Ngôn ngữ

File rule và skill mặc định dùng tiếng Việt, dành tiếng Anh cho code, identifier, commit message và log output — cách chia mà hầu hết team Việt Nam đã dùng sẵn.

Để chuyển sang tiếng Anh, dịch các file `.md` dưới `.claude/`, và đổi mục cuối của `CLAUDE.md`:

```markdown
## Language
Respond in English. Code, identifiers, commit messages and log messages in English.
```

Các key frontmatter (`name`, `description`, `globs`, `tools`, `model`, `allowed-tools`) phải luôn giữ tiếng Anh bất kể trường hợp nào.

## 9. Triển khai cho cả team

Commit `.claude/` và `.mcp.json`. Không commit `.env.mcp` hay `.claude/settings.local.json` — installer đã thêm cả hai vào `.gitignore`.

Mỗi dev chạy:

```bash
cp .env.mcp.example .env.mcp   # token GitLab riêng của họ
set -a; source .env.mcp; set +a
```

Sở thích cá nhân đặt trong `.claude/settings.local.json` (đã gitignore). Cái gì cả team cần dùng chung thì đặt trong `settings.json` và đi qua code review như mọi thay đổi khác.
