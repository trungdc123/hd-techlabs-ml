# Hướng dẫn sử dụng: Marlin HFI Agent Skills

Hướng dẫn đầy đủ cho CTV và developers.

---

## Mục lục

1. [Cài đặt](#1-cài-đặt)
2. [Tổng quan luồng làm việc](#2-tổng-quan-luồng-làm-việc)
3. [Giai đoạn 1: Chọn và Submit Task](#3-giai-đoạn-1-chọn-và-submit-task)
4. [Giai đoạn 2: Review Checkpoints](#4-giai-đoạn-2-review-checkpoints)
5. [Giai đoạn 3: Hoàn tất](#5-giai-đoạn-3-hoàn-tất)
6. [Sử dụng riêng từng skill](#6-sử-dụng-riêng-từng-skill)
7. [Mẹo chống reject](#7-mẹo-chống-reject)
8. [Xử lý sự cố](#8-xử-lý-sự-cố)

---

## 1. Cài đặt

### 1.1 Yêu cầu

- Git, curl, bash
- Claude Code (hoặc bất kỳ agentic runtime nào)
- GitHub token (không bắt buộc, giúp fetch PR diffs nhanh hơn)
- tmux (để theo dõi logs khi model chạy)

### 1.2 Cài đặt cho Claude Code

Skills đã được tích hợp sẵn trong `.claude/skills/`. Không cần copy hay symlink.

> **Không dùng Claude Code?** Đọc trực tiếp file skill:
> ```
> .claude/skills/task-select
> .claude/skills/task-submit
> .claude/skills/checkpoint-review
> .claude/skills/checkpoint-prompt
> .claude/skills/checkpoint-qa
> .claude/skills/eval-finalize
> .claude/skills/validate-output
> .claude/skills/rewrite-human
> .claude/skills/get-logs
> .claude/skills/gen-claude-md
> ```
> Mỗi file là self-contained prompt. Inject vào LLM của bạn làm system prompt.

Kiểm tra skills đã load:
```
# Trong Claude Code session, gọi:
/task-select
# Nếu hiện help text của skill là OK
```

### 1.3 Cài đặt cho Cursor

Tạo file `.cursorrules` ở root project, reference skills từ `.claude/skills/`:

```markdown
# Trong .cursorrules, reference qua @file

@.claude/skills/checkpoint-review
@.claude/skills/validate-output
```

Cách dùng trong Cursor chat:
- Mở Composer (Cmd+I), gõ lệnh tương tự Claude Code
- Có thể tag file context: `@workspace/329_.../turn_1/staged_diff_a.patch`
- Cursor đọc được skill file nếu bạn @ reference nó

### 1.4 Cài đặt cho Antigravity / Codex

Đọc nội dung skill và dùng làm system prompt. Xem README.md phần "Tương thích đa nền tảng".

**Antigravity:**
```bash
# Inject skill làm system prompt khi chạy task
antigravity run --system-prompt .claude/skills/checkpoint-review \
  --user "Review turn 1 in workspace/329_PrefectHQ_prefect_13620"
```

**Codex (OpenAI):**
```bash
# Tạo file instructions chứa nội dung skill
cat .claude/skills/checkpoint-review > .codex-instructions.md
codex --instructions .codex-instructions.md
```

### 1.5 Thiết lập GitHub token (không bắt buộc)

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

Token giúp fetch PR diffs nhanh hơn và không bị rate limit.

### 1.6 Thiết lập tmux

Model A và B chạy trong tmux sessions. Skill `get-logs` cần tmux để lấy logs:

```bash
# Tạo session cho Model A
tmux new-session -d -s model_a

# Tạo session cho Model B
tmux new-session -d -s model_b

# Kiểm tra sessions
tmux list-sessions
```

---

## 2. Tổng quan luồng làm việc

```
 +-------------------+     +---------------------+     +-------------------+
 | GĐ 1: Thiết lập   | --> | GĐ 2: Vòng lặp Turn | --> | GĐ 3: Hoàn tất    |
 |                   |     |   (3+ turns)         |     |                   |
 |  task-select      |     |  get-logs            |     |  eval-finalize    |
 |  init_task.sh     |     |  checkpoint-review   |     |  validate-output  |
 |  fetch_pr_diff    |     |  checkpoint-prompt   |     |                   |
 |  task-submit      |     |  validate-output     |     |                   |
 +-------------------+     +---------------------+     +-------------------+
```

Mỗi giai đoạn có thể hỏi đáp với agent bất kỳ lúc nào. Context lưu trong workspace files.

**Quan trọng**: Tất cả skills tự động chạy validate + rewrite trước khi output. Bạn KHÔNG cần gọi `/validate-output` riêng sau mỗi bước - output đã được kiểm tra sẵn. Chỉ gọi `/validate-output` khi muốn kiểm tra text bạn tự viết.

---

## 3. Giai đoạn 1: Chọn và Submit Task

### Bước 1: Chọn PR

```
/task-select https://github.com/PrefectHQ/prefect/pull/13620
```

Skill sẽ trả về:
- **TAKE**: PR phù hợp, tiến hành submit
- **SKIP**: PR không phù hợp (quá đơn giản, chỉ docs, không test được)
- **CAUTION**: Có rủi ro, cần cân nhắc

**Đánh giá nhiều PR cùng lúc:**
```
/task-select https://github.com/org/repo/pull/1 https://github.com/org/repo/pull/2 https://github.com/org/repo/pull/3
```

### Bước 2: Khởi tạo workspace

```bash
bash scripts/init_task.sh 329 https://github.com/PrefectHQ/prefect/pull/13620
```

Tạo ra:
```
workspace/329_PrefectHQ_prefect_13620/
  meta.json    # Metadata
```

### Bước 3: Fetch PR diff

```bash
bash scripts/fetch_pr_diff.sh 329 https://github.com/PrefectHQ/prefect/pull/13620
```

Tạo ra: `workspace/329_.../pr.diff`

### Bước 4: Tạo Step 1 spec

```
/task-submit workspace/329_PrefectHQ_prefect_13620
```

Skill sẽ:
1. Đọc pr.diff
2. Phân tích changed files, functions, patterns
3. Soạn 6 fields: Prompt Category, Repo Def, PR Def, Edge Cases, Acceptance Criteria, Initial Prompt
4. Tự review: self-contained check, no-deferred-requirements, chống AI, validate
5. Xuất ra `step1_spec.md`

**Kiểm tra output:**
```
/validate-output workspace/329_PrefectHQ_prefect_13620/step1_spec.md
```

### Bước 5: Submit lên platform

Copy nội dung `step1_spec.md` vào các fields trên platform.

---

## 4. Giai đoạn 2: Review Checkpoints

Lặp lại cho mỗi turn (tối thiểu 3 turns).

### Bước 1: Theo dõi model đang chạy

Sau khi platform chạy Model A và B, theo dõi tiến trình:

```
/get-logs model_a
```

Skill sẽ:
- Lấy output gần nhất từ tmux session
- Phân tích trạng thái: đang chạy, hoàn thành, hay bị lỗi
- Trích xuất thông tin: test results, errors, warnings
- Tóm tắt tiến trình hiện tại

```
/get-logs model_b
```

Làm tương tự cho Model B. Bạn có thể kiểm tra lặp đi lặp lại cho đến khi cả 2 models hoàn thành.

### Bước 2: Thu thập diffs

Khi cả 2 models đã chạy xong:

```bash
bash scripts/collect_diffs.sh \
  workspace/329_PrefectHQ_prefect_13620 \
  1 \
  /path/to/worktree_a \
  /path/to/worktree_b
```

Tạo ra:
```
turn_1/
  staged_diff_a.patch
  staged_diff_b.patch
  execution_evidence_a.md   # Template - cần điền test output vào
  execution_evidence_b.md   # Template - cần điền test output vào
```

### Bước 3: Lưu logs vào workspace

```
/get-logs model_a --save workspace/329_PrefectHQ_prefect_13620/turn_1/logs_a.txt
/get-logs model_b --save workspace/329_PrefectHQ_prefect_13620/turn_1/logs_b.txt
```

### Bước 4: Điền execution evidence

Mở `execution_evidence_a.md` và `execution_evidence_b.md`, điền:
- Kết quả test (paste output)
- Output build
- Thời gian chạy (bao lâu model chạy)

Hoặc dùng logs đã lưu bước 3 để trích xuất tự động.

### Bước 5: Tạo đánh giá

```
/checkpoint-review workspace/329_PrefectHQ_prefect_13620 1
```

Skill sẽ:
1. Đọc step1_spec + tất cả đánh giá trước + diffs + evidence
2. Trích xuất code references từ diffs
3. Soạn 21 sections (preferred answer, senior expectations, A/B strengths/weaknesses, 12 trục, ratings, justification)
4. Tự review 5 gates:
   - GATE 1: Code refs >= 3 mỗi section
   - GATE 2: Rating nhất quán với winner
   - GATE 3: Quét blocked words
   - GATE 4: Kiểm tra tính cụ thể
   - GATE 5: Cả 2 models đều có cons
5. Chạy reflection loop (tự phê bình, sửa, tối đa 2 vòng)
6. Xuất ra `turn_1_evaluation.md`

### Bước 6: Brainstorm câu hỏi (checkpoint-qa)

Sau khi có evaluation, đào sâu bằng Q&A. Có 3 cách:

```
# Cách 1: Tự động sinh 3-8 câu hỏi từ evaluation
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1

# Cách 2: Dùng 7 câu hỏi chuẩn Marlin (preset)
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 --preset
```

7 preset questions:
1. Which code has better logic and correctness?
2. Which code has better naming and clarity?
3. Which code has better organization and modularity?
4. Which code has better interface design?
5. Which code has better error handling and robustness?
6. Which code has better comments and documentation?
7. Which code is more ready for review/merge?

```
# Cách 3: Hỏi câu cụ thể (1 hoặc nhiều)
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 "How does Model B handle async def vs A?"
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 --questions "Q1?" "Q2?" "Q3?"
```

Skill tự động: sinh câu hỏi -> gợi ý đáp án -> auto-validate + auto-rewrite -> xuất ra `turn_1/qa/`

### Bước 7: CTV viết đáp án + đánh giá

CTV đọc gợi ý trong `q_1_suggestion.md`, viết đáp án riêng trong `q_1_answer.md`, rồi:

```
# Đánh giá 1 đáp án
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 --evaluate q_1

# Hoặc đánh giá tất cả cùng lúc
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 --evaluate all
```

Verdict: STRONG / ADEQUATE / NEEDS WORK. Nếu NEEDS WORK, skill gợi ý cách viết lại.

### Bước 7b: Overall Preference Justification

Sau khi Q&A hoàn tất, tạo justification tổng hợp cho submission:

```
/checkpoint-qa workspace/329_PrefectHQ_prefect_13620 1 --overall
```

Tạo ra `turn_1/qa/overall_justification.md` gồm:
- Preferred Model + Rating (A1-B1)
- Key-axis (dimension chính)
- Justification 4-6 câu với code refs
- Evidence Summary (Logic, Code Quality, Robustness, Production Readiness)

### Bước 8: Tạo prompt turn tiếp theo

```
/checkpoint-prompt workspace/329_PrefectHQ_prefect_13620 1
```

Skill sẽ:
1. Đọc đánh giá vừa tạo
2. Xác định gaps của winner
3. Soạn prompt chỉ address khía cạnh mới
4. Tự review: novelty check, scope check, winner-only check
5. Xuất ra `turn_1_next_prompt.md`

### Bước 9: Cập nhật accepted baseline

Tạo/update `accepted_baseline.json`:
```json
{
  "turn": 1,
  "side": "B",
  "reason": "AsyncFunctionDef handling, better module resolution"
}
```

### Bước 10: Lặp lại cho turn 2, 3...

```bash
# Turn 2
/get-logs model_a    # Kiểm tra model đang chạy
/get-logs model_b
bash scripts/collect_diffs.sh workspace/329_... 2 /path/a /path/b
# Điền evidence
/checkpoint-review workspace/329_... 2
/checkpoint-prompt workspace/329_... 2

# Turn 3
/get-logs model_a
/get-logs model_b
bash scripts/collect_diffs.sh workspace/329_... 3 /path/a /path/b
/checkpoint-review workspace/329_... 3
# Không cần checkpoint-prompt nếu đây là turn cuối
```

---

## 5. Giai đoạn 3: Hoàn tất

### Bước 1: Tạo finalization

```
/eval-finalize workspace/329_PrefectHQ_prefect_13620
```

Skill sẽ:
1. Đọc tất cả turn evaluations + prompts
2. Tính trajectory (ai thắng mỗi turn)
3. Tính final ratings (format nhãn A1-B1)
4. Soạn 10 sections
5. Tự review: trajectory consistency, code refs, completeness, chống AI, format nhãn
6. Xuất ra `step3_finalization.md`

### Bước 2: Validate

```
/validate-output workspace/329_PrefectHQ_prefect_13620/step3_finalization.md
```

### Bước 3: Submit

Copy nội dung step3_finalization.md lên platform.

---

## 6. Sử dụng riêng từng skill

Mỗi skill độc lập, có thể gọi bất kỳ lúc nào:

### get-logs - Theo dõi model chạy

```
# Xem logs gần nhất
/get-logs model_a

# Xem 200 dòng cuối
/get-logs model_a --lines 200

# Lưu vào file
/get-logs model_a --save workspace/329_.../turn_1/logs_a.txt

# Tìm kiếm trong logs
/get-logs model_a --grep "error\|fail\|PASS"

# So sánh 2 sessions
/get-logs model_a model_b --compare
```

### checkpoint-qa - Brainstorm Q&A + Overall Justification

```
# Mode 1: Auto-generate 3-8 questions
/checkpoint-qa workspace/329_... 1

# Mode 2: Use 7 preset Marlin questions
/checkpoint-qa workspace/329_... 1 --preset

# Mode 3: Custom question
/checkpoint-qa workspace/329_... 1 "Why does B use find_spec instead of path splitting?"

# Mode 4: Multiple questions at once
/checkpoint-qa workspace/329_... 1 --questions "Q1?" "Q2?" "Q3?"

# Mode 5: Evaluate CTV answers
/checkpoint-qa workspace/329_... 1 --evaluate q_1
/checkpoint-qa workspace/329_... 1 --evaluate all

# Mode 6: Overall Preference Justification
/checkpoint-qa workspace/329_... 1 --overall
```

Output:
- `turn_1/qa/questions.json` - question list
- `turn_1/qa/q_1_suggestion.md` - suggested answer (auto-validated + rewritten)
- `turn_1/qa/q_1_answer.md` - CTV writes their own
- `turn_1/qa/q_1_review.md` - CTV answer review (STRONG/ADEQUATE/NEEDS WORK)
- `turn_1/qa/overall_justification.md` - Overall Preference Justification for submission

### gen-claude-md - Auto-generate CLAUDE.md

```
# Generate CLAUDE.md for a repo that doesn't have one (V3 required)
/gen-claude-md /path/to/repo
```

Analyzes repo structure, detects language/framework, test commands, conventions, and generates CLAUDE.md.

### rewrite-human - Viết lại text

```
/rewrite-human Model B provides a more robust and comprehensive implementation that leverages urllib3's built-in retry mechanisms
```

Output:
```
### LLM signals detected:
- "robust" (từ bị cấm)
- "comprehensive" (từ bị cấm)
- "leverages" (từ bị cấm)

### Rewritten text:
Model B's implementation uses urllib3's built-in retry with configurable backoff. Solid choice for production traffic.
```

### validate-output - Kiểm tra chất lượng

```
/validate-output path/to/any/text/file.md
```

Hoặc paste text trực tiếp:
```
/validate-output
[paste text]
```

### Hỏi đáp bất kỳ lúc nào

Vì context lưu trong workspace files, CTV có thể hỏi bất kỳ câu hỏi nào giữa các bước:

```
# Trong Claude Code session:
"Đọc lại turn_1_evaluation.md và giải thích tại sao B thắng"
"So sánh staged_diff_a.patch và staged_diff_b.patch, file nào khác nhau nhiều nhất?"
"Check xem turn_2 prompt có bị trùng với turn_1 không"
"Phân tích logs Model A xem có error gì không"
```

---

## 7. Mẹo chống reject

### Top 5 lỗi thường gặp

**1. Prompt trùng lặp (21.9%)**
- SAI: Turn 2 lặp lại "implement AST extraction" (đã làm ở Turn 1)
- ĐÚNG: Turn 2 chỉ fix gaps mới: "keyword-only args missing in _signature_from_ast"
- Dùng checkpoint-prompt skill, nó tự kiểm tra tính mới

**2. Đánh giá không chính xác (14.2%)**
- SAI: "Model B handles errors better" (không có code ref)
- ĐÚNG: "Model B's _retry_handler() in api_client.py catches ConnectionError with exponential backoff"
- checkpoint-review GATE 1 bắt buộc >= 3 refs mỗi section

**3. Phát hiện AI/LLM (10.1%)**
- SAI: Dùng "robust", "comprehensive", "leverage", em dashes
- ĐÚNG: "solid", "thorough", "use", hyphens
- Chạy /validate-output trước khi submit

**4. Rating không nhất quán (9.4%)**
- SAI: Nói A thắng nhưng 8/12 trục favor B
- ĐÚNG: Winner khớp với đa số trục đánh giá
- checkpoint-review GATE 2 tự kiểm

**5. Lan rộng phạm vi (7.6%)**
- SAI: Turn 3 thêm "also add HTTP caching" (ngoài scope PR)
- ĐÚNG: Chỉ giải quyết vấn đề trong scope issue gốc
- checkpoint-prompt GATE 2 tự kiểm scope

### Checklist trước khi Submit

- [ ] Mỗi pro/con có file:function reference
- [ ] Hướng rating khớp với winner
- [ ] Không có blocked words (chạy /validate-output)
- [ ] Không có em dashes (dấu gạch dài)
- [ ] Cả 2 models đều có cons (điểm yếu)
- [ ] Tối thiểu 3 turns
- [ ] Mỗi turn có khía cạnh MỚI
- [ ] Không mention PR/pull request trong output
- [ ] Justification 3-5 câu với code refs
- [ ] Đã kiểm tra logs model (không bị lỗi giữa chừng)

---

## 8. Xử lý sự cố

### Skill không load trong Claude Code

Kiểm tra:
1. Files nằm đúng vị trí: `.claude/skills/task-select`
2. Frontmatter đúng format (bắt đầu bằng `---`)
3. Restart Claude Code session

### fetch_pr_diff.sh bị 403

Thiết lập GITHUB_TOKEN:
```bash
export GITHUB_TOKEN=ghp_xxx
```

### Workspace không tìm thấy

Kiểm tra tên thư mục khớp với format: `{task_id}_{owner}_{repo}_{pr}`
```bash
ls workspace/
```

### Model chạy trong tmux nhưng get-logs không thấy

```bash
# Liệt kê tất cả sessions
tmux list-sessions

# Kiểm tra tên session đúng
tmux list-windows -t model_a

# Nếu session dùng tên khác, chỉ định trực tiếp
/get-logs my_custom_session_name
```

### Đánh giá bị FAIL validation

Đọc "Fix Suggestions" trong validation report. Các lỗi P0 phải fix, P1 nên fix, P2 tùy chọn.

Lỗi thường gặp nhất:
- Blocked words: thay thế theo bảng trong `skills/_shared/blocked_words.md`
- Em dashes: Find & Replace `—` thành `-`
- Thiếu code refs: đọc lại diffs và thêm specific file:function

### Context quá lớn cho 1 turn

Nếu turn 3+ có quá nhiều đánh giá trước đó:
- Đọc diff stats trước, chỉ đọc chi tiết phần liên quan
- Execution evidence nên là bản tóm tắt, không paste raw output
- Focus vào delta (thay đổi từ turn trước), không lặp lại full analysis
- Dùng /get-logs với --grep để lọc chỉ phần quan trọng
