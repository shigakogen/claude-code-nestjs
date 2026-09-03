# Ghi chú thiết kế

Vì sao mỗi lớp tồn tại, tốn gì, và khi nào nên dùng. Đọc file này trước khi thêm bất cứ thứ gì vào kit.

🇬🇧 [English](design.md)

## Ràng buộc

`CLAUDE.md` nạp ở **mọi lượt**. Tool schema của mọi MCP server cũng vậy. Mọi thứ khác trong kit này được thiết kế để chỉ nạp theo nhu cầu.

Điều đó tạo ra một thang chi phí. Khi muốn agent hành xử khác đi, chọn lớp rẻ nhất mà vẫn hiệu quả:

| Lớp | Chi phí thường trực | Độ tin cậy | Dùng khi nào |
|---|---|---|---|
| Hook | 0 | tất định | luật máy móc và việc vi phạm là không chấp nhận được |
| Rule theo đường dẫn | 0 khi glob không khớp | mạnh | luật chỉ áp dụng cho một số thư mục |
| Skill | chỉ metadata cho tới khi kích hoạt | mạnh | quy trình lặp lại có các bước rõ ràng |
| Subagent | 0 tới khi được gọi | mạnh | việc cần context riêng hoặc giới hạn tool riêng |
| Dòng `CLAUDE.md` | **mọi lượt, mãi mãi** | vừa phải | thực sự toàn cục và không tránh được |

Đa số team làm ngược lại: mọi thứ đổ vào `CLAUDE.md`, không gì được cưỡng chế, và file phình to tới mức không còn ai đọc kỹ nữa.

## Lớp 1 — file memory

Dưới 60 dòng ở đây; trần cứng trong CI là 200.

Ba phép thử cho một dòng ứng viên:

1. **Có thay đổi hành vi không?** "Viết code sạch" thì không. "Ranh giới transaction chỉ ở `service/`" thì có.
2. **Có kiểm chứng được không?** Nhìn vào diff phải nói được là có tuân theo hay không.
3. **Có toàn cục không?** Nếu chỉ quan trọng ở một thư mục, nó thuộc về `rules/`.

Viết mệnh lệnh, không viết gợi ý. "Không bao giờ trả entity TypeORM từ controller" — không phải "nên trả DTO khi phù hợp". Ngôn ngữ mập mờ cho model chỗ để tự thương lượng với chính nó.

## `SERVICE_MAP.md` — file ở root, không phải file memory

`CLAUDE.md` và `SERVICE_MAP.md` nằm cạnh nhau ở root repo, nhưng nạp khác nhau. `CLAUDE.md`
được import tự động, mọi lượt. `SERVICE_MAP.md` thì không — không có gì trong kit này
`@`-import nó. Nó không tốn gì cho tới khi agent (hoặc bạn) đọc nó — đó chính là mục đích:
đa số lượt không chạm tới service khác, và những lượt có chạm thì đã có `Read` miễn phí sẵn.

Con trỏ giúp nó được phát hiện nằm ở lớp rẻ nhất có thể mang nó — một dòng trong `CLAUDE.md`
và một dòng trong `service-layer.md`, cả hai chỉ nêu tên file, không nhúng nội dung. Skill
`update-service-map` mới là thứ giữ nó trung thực: hệ thống này chưa có contract registry,
nên mọi mục đều suy luận từ code và cần người xác nhận — cùng chuẩn "kiểm chứng được, không
mô tả chung chung" như mọi thứ khác trong kit.

Một repo đơn lẻ chỉ có thể mô tả nó gọi gì và expose gì — không bao giờ biết ai gọi nó. Với
bức tranh xuyên service (tác động của một thay đổi contract, truy vết một sự cố xuyên nhiều
service), xem kit anh em `claude-code-workspace`, cài một lần ở thư mục chứa repo này như
một thư mục con anh em, không phải cài bên trong repo này.

## Lớp 2 — rule theo đường dẫn

Frontmatter khai báo glob; file chỉ nạp khi agent chạm đường dẫn khớp. Sửa controller không phải trả phí cho quy ước migration.

Hai hệ quả đáng lưu ý:

- **Tách theo thư mục, không theo chủ đề.** Một rule áp dụng ở mọi nơi là một dòng `CLAUDE.md`, không phải file rule.
- **Ưu tiên glob theo hậu tố filename hơn glob theo thư mục khi quy ước của framework đủ mạnh.** Hậu tố `*.controller.ts`/`*.service.ts`/`*.entity.ts` của NestJS gần như phổ quát bất kể layout, nên rule trong kit này chủ yếu dựa vào đó — một rule chỉ khớp `src/controller/**` sẽ im lặng ngừng nạp ngay khi repo chuyển sang module colocate-theo-feature. Xem [customization.md](customization.md) để đổi layout mặc định.

Một điểm tài liệu cần lưu ý: schema ghi khóa là `paths:`, nhưng nhiều bản Claude Code chỉ nhận `globs:`. Kit này dùng `globs:`. Nếu một rule bị bỏ qua im lặng, đây là chỗ kiểm tra đầu tiên.

## Lớp 3 — Plan Mode

Không phải file — là một thói quen, và là thói quen có lợi ích cao nhất.

Plan Mode tách việc khảo sát ra khỏi việc thực thi. Subagent khảo sát đọc codebase trong context riêng của nó, còn planner sinh ra một tài liệu bạn có thể sửa trước khi bất cứ thứ gì được ghi. Dùng nó cho việc chạm nhiều hơn một service, mọi refactor, và mọi thay đổi schema.

Subagent lập plan chỉ đọc theo thiết kế. Nó không thể sửa codebase trong lúc lập bản đồ dependency.

## Lớp 4 — subagent

Viết một subagent khi việc lặp lại, cần giới hạn tool riêng, hoặc cần system prompt xung đột với cấu hình chính.

Hai tính chất khiến bốn agent ở đây đáng có:

- **`tools:` là allowlist.** `nest-reviewer` chỉ có `Read, Grep, Glob` cộng `Bash(git diff:*)`. Nó không thể ghi. Đó là bảo đảm cấu trúc, không phải lời hứa.
- **`model: sonnet`** giữ chi phí thấp. Vòng lặp chính giữ model mạnh cho phần suy luận thực sự cần nó; review và log triage chạy nền với chi phí chỉ bằng một phần nhỏ.

Review ngay trong phiên chính là sai lầm mà lớp này tồn tại để ngăn. Review kéo rất nhiều nội dung file vào context rồi nội dung đó nằm lại đó cho hết cuộc hội thoại.

## Lớp 5 — skill

Progressive disclosure: metadata lúc bắt đầu phiên, hướng dẫn khi được kích hoạt, tài nguyên đóng gói chỉ khi được tham chiếu. Năm mươi skill cài sẵn vẫn gần như không tốn gì thường trực.

Mọi skill trong kit này cùng ba mục, và mục thứ ba là mục hay bị bỏ qua:

1. **Thông tin cần thu thập trước** — buộc agent phải hỏi thay vì tự bịa yêu cầu.
2. **Các bước** — thứ tự rõ ràng, lệnh thật.
3. **Không được làm** — ranh giới cứng. `mr-checklist` không được `git push`; `new-migration` không được đụng file migration đã có.

`allowed-tools` cưỡng chế ranh giới ở tầng tool, nên nó vẫn giữ vững kể cả khi model không muốn.

## Lớp 6 — hook

Hook thêm guardrail tất định vào một hệ thống xác suất. Đây là lớp duy nhất không thể bị thuyết phục để bỏ vị trí của nó.

Hai dạng đáng biết:

**Format (PostToolUse).** Nhàm chán nhưng ROI cao nhất trong kit. Agent ghi một file thụt lề lộn xộn, hook format lại, và lượt sau đọc code sạch. Không có nó, agent bối rối vì chính output của mình.

**Chặn (PreToolUse).** Trả `deny` cho việc không bao giờ được xảy ra, `ask` cho việc cần người xác nhận. `gate-dangerous.sh` chặn force push và `reset --hard`; nó hỏi khi lệnh nhắc tới `prod`, `staging` hay `uat`, vì một lệnh nhắc tên môi trường dùng chung xứng đáng được người liếc qua kể cả khi trông vô hại.

`protect-migrations.sh` là ví dụ rõ nhất cho lớp này. "Không bao giờ sửa migration đã commit" đúng là kiểu luật giữ vững ba mươi lượt rồi lặng lẽ không còn giữ vững nữa. Hook kiểm tra `git ls-files` và trả `deny`. Nó không chịu ảnh hưởng của sự sao nhãng.

`log-denied.sh` khép vòng lặp: mọi lần từ chối được ghi vào `.claude/logs/denied.jsonl`, để sau này biết guardrail nào đang đáng giá hay chỉ đang cản trở.

## Lớp 7 — dàn server

Mỗi MCP server đóng góp tool schema vào **mọi lượt**. Năm mươi tool có thể tốn 10–20k token mỗi lượt. Lazy tool-loading giảm đáng kể, nhưng ít server hơn vẫn là chiến lược tốt hơn.

Ba server ở đây:

- **`gitlab`** — merge request, branch, issue trên instance tự lưu trữ.
- **`context7`** — tài liệu thư viện đúng version. Bề mặt API của NestJS/TypeORM đổi qua các major, và đây là thứ ngăn model tự tin viết code kiểu TypeORM 0.2 (hay decorator Nest cũ) vào một dự án hiện tại.
- **`db-local`** — đọc schema và `EXPLAIN`, chỉ đọc, chỉ container local.

Không có filesystem server: `Read`, `Grep`, `Glob` đã làm việc đó miễn phí schema. Chỉ thêm server thứ tư khi gọi tên được việc lặp lại mà nó loại bỏ.

## Lớp 8 — worktree và headless

**Worktree** cho chạy nhiều phiên song song, mỗi phiên context riêng. Việc chồng lấn tạo ra sửa đổi chồng lấn, nên chia pane theo domain riêng biệt — test ở một pane, logic lõi ở pane khác — để xung đột hiếm xảy ra.

**Headless** (`claude -p --allowedTools ...`) chạy agent không tương tác trong CI. Kết hợp với `gate-dangerous.sh`, một job đêm có thể chuẩn bị bản fix và dừng lại ở bước push, chờ người thay vì fail hoặc được cấp quyền vô hạn.

## Điều những lớp này không giải quyết được

Phiên chạy lâu vẫn suy giảm khi context đầy dần những quan sát cũ. Không lớp nào ở trên sửa được điều đó; chúng chỉ trì hoãn. Bắt đầu phiên mới khi việc đổi hình dạng, và dùng `/context` để xem ngân sách đang đi đâu.
