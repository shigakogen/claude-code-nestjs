# Xử lý sự cố

🇬🇧 [English](troubleshooting.md)

## Rule không bao giờ nạp

**Triệu chứng.** Agent vi phạm một rule rõ ràng đã viết trong `.claude/rules/`. `/context` không liệt kê file rule đó.

Kiểm tra theo thứ tự sau:

1. **Glob không khớp layout của bạn.** Glob mặc định ưu tiên hậu tố filename (`*.controller.ts`) cộng với fallback thư mục kiểu layered-by-type (`src/controller/`). Nếu repo của bạn dùng quy ước đặt tên rất khác (hiếm trong NestJS, nhưng có thể xảy ra ở một bản port legacy), sửa glob. Xem [customization.md](customization.vi.md#1-sửa-glob-trước-tiên).
2. **Sai key frontmatter.** Key được tài liệu hoá là `paths:`, nhưng vài bản build chỉ tuân theo `globs:`. Kit này dùng `globs:`. Nếu bản của bạn cần key kia, đổi lại:
   ```yaml
   paths: ["**/*.controller.ts"]
   ```
   Dạng CSV trên một dòng cũng hoạt động ổn định hơn dạng list YAML trên vài bản build.
3. **Frontmatter sai định dạng.** Phải bắt đầu ở dòng 1 bằng `---`, và cả hai dấu phân cách phải nằm riêng một dòng. Một dòng trống ở đầu sẽ làm hỏng việc parse một cách âm thầm.
4. **Bản của bạn không hỗ trợ rule.** Chạy `claude --version`. Nếu rule theo đường dẫn chưa khả dụng, tạm thời gộp hai ba dòng quan trọng nhất vào `CLAUDE.md` và giữ sẵn các file rule.

Kiểm tra nhanh: hỏi thẳng agent — *"những file rule nào đang được nạp?"*

## `CLAUDE.md` không được nạp

Claude Code nạp `./CLAUDE.md` từ gốc repo. Installer đặt nó ở đó. Nếu repo của bạn đã có sẵn một file, bản copy của kit chuyển sang `.claude/CLAUDE.md` và một dòng import được thêm vào:

```markdown
@.claude/CLAUDE.md
```

Nếu bản của bạn không tuân theo import đó, gộp hai file bằng tay rồi xoá `.claude/CLAUDE.md`. Hai file memory chồng lấn tốn token mỗi lượt và cho model chỉ dẫn mâu thuẫn nhau.

Xác nhận bằng `/memory`.

## Hook không kích hoạt

1. **Thiếu `jq`.** Mọi hook đều parse payload bằng nó. `jq --version`; cài bằng `apt install jq` hoặc `brew install jq`.
2. **Không có quyền thực thi.** `chmod +x .claude/hooks/*.sh`. Clone trên Windows hoặc copy qua vài công cụ sẽ làm mất bit này.
3. **`$CLAUDE_PROJECT_DIR` chưa được set.** Hook resolve đường dẫn thông qua biến này. Nếu bản của bạn không set nó, hardcode một đường dẫn tuyệt đối trong `settings.json` như một cách sửa tạm.
4. **Line ending CRLF.** `#!/usr/bin/env bash\r` gây lỗi "no such file" khó hiểu. Sửa: `sed -i 's/\r$//' .claude/hooks/*.sh`, và thêm `*.sh text eol=lf` vào `.gitattributes`.

Test một hook trực tiếp, bên ngoài Claude Code:

```bash
export CLAUDE_PROJECT_DIR=$PWD
echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/gate-dangerous.sh
# kỳ vọng: {"hookSpecificOutput":{...,"permissionDecision":"deny",...}}
```

Sau đó kiểm tra `.claude/logs/denied.jsonl` — nếu denial được ghi lại, nghĩa là đấu nối hoạt động.

## `protect-migrations.sh` chặn một migration *mới*

Nó chỉ chặn file đã được git track (`git ls-files --error-unmatch`). Nếu một file thực sự mới bị chặn, tức là nó đã được stage bằng `git add`. Unstage nó (`git restore --staged <file>`) hoặc, nếu đã commit, tạo một migration mới — đó chính là rule mà hook này tồn tại để cưỡng chế.

## `format-source.sh` làm chậm mọi lần ghi file

Nó chạy ESLint và/hoặc Prettier cho từng file qua `npx`.

- Nếu không có cả `.eslintrc*`/`eslint.config.*` lẫn `.prettierrc*`/`prettier.config.*`, hook thoát ngay — nó kiểm tra cả hai trước khi chạy bất cứ gì.
- `npx` phải resolve một package chưa cache thường là chỗ chậm nhất. Chạy formatter một lần bằng tay (`npx eslint .`) để làm nóng cache local của npm.
- Vẫn quá chậm? Tăng `timeout` trong `settings.json`, hoặc bỏ hook và chạy lint/format trong pre-commit hook của bạn thay vào đó.

## MCP server không kết nối được

Chạy `/mcp` trong phiên để xem trạng thái từng server.

- **Biến môi trường chưa được expand.** `.mcp.json` dùng `${GITLAB_TOKEN}`. Các biến này phải có trong môi trường *trước khi* `claude` khởi động: `set -a; source .env.mcp; set +a; claude`.
- **Server chưa được bật.** `.claude/settings.json` set `enableAllProjectMcpServers: false` và bật server tường minh trong `enabledMcpjsonServers`. `db-local` mặc định tắt — bật nó trong `.claude/settings.local.json`.
- **GitLab self-hosted đứng sau private CA.** Set `NODE_EXTRA_CA_CERTS=/path/to/ca.pem` trong khối `env` của server.
- **`npx` bị chặn bởi proxy công ty.** Cài package global trước rồi trỏ `command` thẳng vào binary.

## MCP database có thể ghi được

Nó không nên như vậy. Xác nhận `--readonly` có mặt trong args của `db-local` và `LOCAL_DB_DSN` trỏ về localhost. Nếu cái nào sai, sửa ngay — ý định chỉ-đọc chỉ được diễn đạt trong một file rule không phải là một biện pháp kiểm soát thật.

## Token dùng nhiều hơn dự kiến

Chạy `/context`. Đọc theo thứ tự:

- **`CLAUDE.md` vượt ~1.5k token** — chuyển chi tiết xuống `rules/`.
- **Tool schema của MCP chiếm phần lớn** — bạn có quá nhiều server. Ba là mục tiêu; mỗi server thêm bị tính phí mỗi lượt.
- **Nhiều file rule cùng nạp một lúc** — glob quá rộng. `**/*.ts` khớp mọi thứ và phá vỡ mục đích của rule.
- **Kết quả tool cũ chiếm hết context window** — bắt đầu phiên mới. Cuộc hội thoại dài tích luỹ quan sát cũ, và không cấu hình nào sửa được điều đó.

## Agent không được đề xuất

Kiểm tra `/agents`. Nếu danh sách trống, frontmatter của `.claude/agents/*.md` sai định dạng — `name:` và `description:` đều bắt buộc, và `name` phải khớp tên file (bỏ phần mở rộng).

Nếu agent tồn tại nhưng không bao giờ tự được chọn, `description` của nó quá mơ hồ. Description là thứ vòng lặp chính dùng để đối chiếu; hãy nói rõ *khi nào* dùng nó, không chỉ nó là gì.

## Mọi thứ đã chạy tốt, rồi ngừng sau khi nâng cấp Claude Code

Schema của frontmatter và tên sự kiện hook có thể thay đổi giữa các phiên bản. Chạy `./tests/run.sh` từ repo kit — nó kiểm tra JSON, frontmatter và định dạng output hook, thường sẽ chỉ ra thứ gì đã đổi. Sau đó kiểm tra [changelog của Claude Code](https://docs.claude.com/en/docs/claude-code) cho các sự kiện và key bạn đang phụ thuộc.
