# claude-code-nestjs

Bộ cấu hình `.claude/` dùng lại được cho các repo NestJS/TypeScript — file memory, rules theo đường dẫn, subagent, skill, hook và một danh sách MCP server cố tình giữ ngắn.

Toàn bộ thiết kế xoay quanh một ràng buộc: **ngân sách context mặc định phải nhỏ.** Mọi thứ khác chỉ nạp khi cần.

🇬🇧 [English](README.md)

---

## Cài đặt

```bash
git clone https://github.com/OWNER/claude-code-nestjs.git ~/tools/claude-code-nestjs
cd ~/work/my-nest-service
~/tools/claude-code-nestjs/install.sh .
```

Xem trước mà chưa ghi gì:

```bash
~/tools/claude-code-nestjs/install.sh . --dry-run
```

Installer an toàn với repo đang có: **không ghi đè** file nào đã tồn tại (dùng `--force` nếu muốn). Nếu repo đã có `CLAUDE.md`, nó giữ nguyên file của bạn và chỉ thêm dòng import `@.claude/CLAUDE.md`.

Sau đó:

```bash
cp .env.mcp.example .env.mcp     # điền GITLAB_API_URL, GITLAB_TOKEN, LOCAL_DB_DSN
set -a; source .env.mcp; set +a
claude
```

Trong phiên, gõ `/onboard`. Nó đọc codebase và đề xuất chính xác những dòng cần sửa trong `CLAUDE.md` — tên module thật, npm script thật, module thật. **Làm việc này trước tiên**; file sinh ra chỉ là điểm khởi đầu.

Kiểm tra bằng `/memory`, `/agents`, `/mcp`, `/context`. Rồi commit `.claude/` và `.mcp.json` để cả team dùng chung.

Gỡ ra: `~/tools/claude-code-nestjs/uninstall.sh .`

### Yêu cầu

| | |
|---|---|
| Claude Code | bản gần đây bất kỳ |
| `jq` | bắt buộc — các hook parse payload JSON bằng nó |
| Dự án | NestJS + TypeORM, npm/yarn/pnpm (tự động phát hiện); Prisma vẫn dùng được nhưng phải sửa rule persistence và lệnh migration |
| Tuỳ chọn | Docker Compose cho hạ tầng local |

---

## Bạn nhận được gì

```
CLAUDE.md              sinh ở gốc repo — dưới 60 dòng, nạp MỌI lượt
.claude/
├── rules/             nạp theo glob, 0 token khi không chạm file khớp
├── agents/            context riêng, model rẻ hơn, danh sách tool hẹp
├── skills/             quy trình đóng gói; chỉ metadata nạp cho tới khi được kích hoạt
├── hooks/              guardrail tất định
├── commands/           /onboard  /review  /fix-test
└── settings.json       permissions + đấu nối hook (nên commit)
.mcp.json               ba server, không phải mười lăm
```

### Rules — sáu file, nạp theo đường dẫn

| File | Glob | Phạm vi |
|---|---|---|
| `api-layer.md` | `**/*.controller.ts`, `src/controller/**`, `**/*.dto.ts`, `**/*.guard.ts` | controller, validate DTO, hợp đồng lỗi, guard |
| `service-layer.md` | `**/*.service.ts`, `src/service/**` | ranh giới transaction, DI, invariant nghiệp vụ |
| `persistence.md` | `**/*.entity.ts`, `**/*.repository.ts`, `src/entity/**` | eager/lazy relation, N+1, phân trang, kiểu dữ liệu MySQL/Postgres |
| `tests.md` | `**/*.spec.ts`, `test/**` | unit / e2e, không gọi mạng thật, không `.skip()`/`.only()` để build xanh |
| `migrations.md` | `src/migrations/**` | CLI TypeORM, bất biến, expand–migrate–contract, khoá bảng lớn |
| `infra-config.md` | `package.json`, `.env*`, `Dockerfile`, `docker-compose*.yml`, `.gitlab-ci.yml` | dependency, secret, CI |

Glob theo hậu tố filename (`*.controller.ts`) là chính ở đây, không phải glob theo thư mục — quy ước đặt tên của NestJS nhất quán bất kể repo dùng layout colocate-theo-feature hay layered-theo-loại, nên rule nạp đúng dù layout nào.

### Subagent — bốn

| Agent | Dùng khi | Vì sao tách riêng |
|---|---|---|
| `nest-reviewer` | sau khi implement, trước khi mở MR | review phải đọc nhiều file — đừng làm bẩn context chính |
| `test-runner` | chạy và tóm tắt test | output Jest có thể rất dài; đọc ở nơi khác, trả về năm dòng |
| `db-migration-auditor` | diff chạm `src/migrations/` | tiêu chí chuyên biệt, rủi ro lan rộng |
| `log-triage` | bạn dán một exception | ánh xạ các họ lỗi NestJS/TypeORM quen thuộc về nguyên nhân gốc |

Cả bốn chạy `sonnet` với `tools` hẹp. Vòng lặp chính giữ model mạnh cho phần suy luận khó.

### Skill — năm

`new-endpoint` · `debug-failing-test` · `new-migration` · `mr-checklist` · `perf-triage`

Mỗi skill cùng một khuôn: *hỏi gì trước khi viết code* → *các bước có thứ tự với lệnh thật* → *không được làm gì*. `allowed-tools` cưỡng chế ranh giới thay vì trông chờ model tự nhớ — `mr-checklist` không thể `git push`.

### Hook — năm

| Hook | Sự kiện | Làm gì |
|---|---|---|
| `session-start.sh` | SessionStart | một dòng ngữ cảnh sống: branch, số file đổi, version Node, compose up/down |
| `gate-dangerous.sh` | PreToolUse `Bash` | **chặn** force push, `reset --hard`, `git clean`, `publish`; **hỏi** với `git push`, `commit --amend`, `compose down -v`, và mọi lệnh nhắc `prod`/`staging`/`uat` |
| `protect-migrations.sh` | PreToolUse `Edit\|Write` | **chặn** sửa file migration đã commit vào git |
| `format-source.sh` | PostToolUse | chạy ESLint `--fix` rồi Prettier sau mỗi lần ghi `.ts`/`.js`, nếu repo có cấu hình |
| `log-denied.sh` | PermissionDenied | ghi vào `.claude/logs/denied.jsonl` để rà soát sau |

`protect-migrations.sh` là cái đáng giá nhất. Một câu nhắc "đừng sửa migration cũ" rồi sẽ bị bỏ qua; một hook thì không.

### MCP — ba server

`gitlab` (instance nội bộ) · `context7` (doc thư viện đúng version) · `db-local` (**chỉ đọc**, DSN chỉ trỏ database trong Docker Compose).

Tool schema của mọi server được nạp ở **mọi lượt**. Năm mươi tool có thể tốn 10–20k token mỗi lượt. Vì vậy ở đây không có filesystem server — `Read`/`Grep`/`Glob` đã đủ, và miễn phí.

> **Tuyệt đối không** trỏ `db-local` vào staging hay production. Cờ `--readonly` là dây an toàn, không phải giấy phép.

---

## Tài liệu

| | |
|---|---|
| [docs/design.vi.md](docs/design.vi.md) | vì sao mỗi lớp tồn tại và tốn gì — đọc trước khi thêm bất cứ thứ gì |
| [docs/customization.md](docs/customization.md) | điều chỉnh theo module layout, Prisma, yarn/pnpm, Git host khác |
| [docs/troubleshooting.md](docs/troubleshooting.md) | rule không nạp, hook không chạy, MCP không kết nối |

## Lộ trình áp dụng

Đừng bật hết ngày đầu.

| Tuần | Thêm gì |
|---|---|
| 1 | `CLAUDE.md` + hai rule (`api-layer`, `tests`) + hook format + ba MCP. Dùng Plan Mode cho việc rủi ro. |
| 2 | `gate-dangerous` và `protect-migrations`, sau khi đã tận mắt thấy agent làm điều bạn không muốn. Thêm `nest-reviewer`. |
| 3 | Đóng gói những quy trình đã ổn định thành skill. |
| 4+ | Worktree song song; chạy headless trong CI (`claude -p --allowedTools ...`). |

## Bảo trì

- Chỉ thêm rule sau khi đã thấy agent mắc **cùng một lỗi hai lần**. Không thêm theo suy đoán.
- Rà `.claude/logs/denied.jsonl` mỗi quý. Guardrail chưa bao giờ kích hoạt là gánh nặng thừa; guardrail chặn việc hợp lệ mỗi ngày là quá chặt.
- `CLAUDE.md` vượt 200 dòng thì chuyển chi tiết xuống `rules/` — đừng nới trần. CI cưỡng chế điều này.

## Anti-pattern

- Dán cả wiki kỹ thuật vào `CLAUDE.md`.
- Cài mười lăm MCP server "cho chắc".
- Để agent tự `git push`.
- Cho MCP database quyền ghi, hoặc trỏ vào môi trường dùng chung.
- Viết rule mô tả (*"nên viết code dễ đọc"*) thay vì luật kiểm chứng được (*"controller không được trả entity TypeORM"*).
- Review ngay trong phiên chính.

## Đóng góp

Xem [CONTRIBUTING.md](CONTRIBUTING.md). Chạy `./tests/run.sh` trước khi mở PR.

## Nguồn tham khảo

Cách tiếp cận phân lớp — memory file nhỏ, rule theo đường dẫn, subagent, skill, hook, danh sách server ngắn — theo bài viết [*I Spent 6 Months Tuning Claude Code*](https://medium.com/data-science-collective/i-spent-6-months-tuning-claude-code-heres-the-exact-setup-that-finally-worked-b41c67628478) của Anubhav. Repo này áp dụng vào NestJS, song song với kit anh em cho Spring Boot ([claude-code-springboot](https://github.com/OWNER/claude-code-springboot)).

## Giấy phép

MIT — xem [LICENSE](LICENSE).
