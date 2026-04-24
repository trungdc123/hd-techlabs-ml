# Marlin HFI Agent Skills

Hệ thống Agent Skills dạng module cho Marlin HFI (Human Feedback Integration). So sánh output Model A vs Model B qua nhiều turns.

## Vấn đề

Có 3 solutions cũ, mỗi cái thiếu một phần:

| Solution | Ưu điểm | Nhược điểm |
|----------|---------|------------|
| prj-merlin-agent (FastAPI app) | Đầy đủ tính năng, có UI | Flow cứng, không linh hoạt, khó maintain |
| APT_Marlin_step1_pipeline (shell) | Nhanh, đơn giản | Chỉ forward 1 lần, không multi-agent |
| rewrite-human (Claude Code skill) | Nhẹ, portable | Chỉ xử lý text rewriting |

## Giải pháp

**10 Agent Skills độc lập**, mỗi skill là 1 file SKILL.md (tất cả tự chạy validate + rewrite trước khi output):
- Chạy được trên **bất kỳ runtime nào**: Claude Code, Antigravity, Codex, custom agent
- **File system = checkpoint store** - không cần DB
- **Self-review gates** trong mỗi skill để chống reject
- **Context accumulation** - mỗi skill đọc tất cả output trước đó

## Danh sách Skills

| # | Skill | Chức năng | Chống Reject |
|---|-------|-----------|-------------|
| 1 | [task-select](.claude/skills/task-select) | Đánh giá PR phù hợp không (TAKE/SKIP/CAUTION) | Low Quality Task (5.2%) |
| 2 | [task-submit](.claude/skills/task-submit) | Tạo Step 1 spec (6 fields) | Redundant Prompts (21.9%), Scope Creep (7.6%) |
| 3 | [checkpoint-review](.claude/skills/checkpoint-review) | Phân tích A/B, 21 sections, 12 trục đánh giá | Inaccurate Eval (14.2%), Rating Inconsistency (9.4%) |
| 4 | [checkpoint-prompt](.claude/skills/checkpoint-prompt) | Tạo prompt cho turn tiếp theo | Redundant Prompts (21.9%), Scope Creep (7.6%) |
| 5 | [eval-finalize](.claude/skills/eval-finalize) | Bước 3 finalization (10 sections) | Incomplete Work (9.7%) |
| 6 | [rewrite-human](.claude/skills/rewrite-human) | Viết lại text chống AI detection | AI/LLM Detected (10.1%) |
| 7 | [validate-output](.claude/skills/validate-output) | 38 bước kiểm tra (P0/P1/P2) | Tất cả categories |
| 8 | [checkpoint-qa](.claude/skills/checkpoint-qa) | Brainstorm câu hỏi, gợi ý đáp án, đánh giá đáp án CTV | Inaccurate Eval (14.2%), Fabricated (6.9%) |
| 9 | [get-logs](.claude/skills/get-logs) | Lấy logs từ tmux session, phân tích running state | Process Violation (4.2%) |
| 10 | [gen-claude-md](.claude/skills/gen-claude-md) | Tự tạo CLAUDE.md cho repo (V3 bắt buộc) | Process Violation (4.2%) |

## Bắt đầu nhanh

### Với Claude Code

Skills đã được cài đặt sẵn trong `.claude/skills/`. Chỉ cần gọi trực tiếp trong Claude Code session:

> **Không dùng Claude Code?** Đọc trực tiếp file skill tại `.claude/skills/<tên-skill>` (ví dụ: `.claude/skills/checkpoint-review`). Mỗi file là self-contained prompt, inject vào LLM của bạn làm system prompt.
```
/task-select https://github.com/owner/repo/pull/123
/task-submit workspace/329_owner_repo_123
/checkpoint-review workspace/329_owner_repo_123 1
/checkpoint-prompt workspace/329_owner_repo_123 1
/get-logs model_a
/eval-finalize workspace/329_owner_repo_123
/rewrite-human [text]
/validate-output [file_or_text]
```

### Với Shell Scripts

```bash
# 1. Khởi tạo workspace
bash scripts/init_task.sh 329 https://github.com/PrefectHQ/prefect/pull/13620

# 2. Fetch PR diff
bash scripts/fetch_pr_diff.sh 329 https://github.com/PrefectHQ/prefect/pull/13620

# 3. Thu thập diffs từ worktrees
bash scripts/collect_diffs.sh workspace/329_PrefectHQ_prefect_13620 1 /path/worktree_a /path/worktree_b
```

### Với Antigravity / Codex / Custom Agent

Mỗi SKILL.md là self-contained. Đọc nội dung và inject làm system prompt:

```python
with open(".claude/skills/checkpoint-review") as f:
    skill_content = f.read()

# Inject vào LLM call
response = llm.chat(
    system=skill_content,
    user=f"Review turn 1 in workspace/329_PrefectHQ_prefect_13620"
)
```

## Cấu trúc dự án

```
hd-techlabs-ml/
  CLAUDE.md                    # Quy tắc project cho Claude Code
  README.md                    # Bạn đang đọc file này
  TUTORIAL.md                  # Hướng dẫn sử dụng chi tiết
  .claude/
    skills/                    # Agent skills (đã tích hợp sẵn)
      eval/                    # Shared resources
        reference/             # Tài liệu tham khảo (axis, rating, rules)
        templates/             # Output templates
        hooks/                 # Hook scripts
      task-select              # Đánh giá PR
      task-submit              # Tạo Step 1 spec
      checkpoint-review        # Phân tích A/B
      checkpoint-qa            # Brainstorm Q&A sau checkpoint
      checkpoint-prompt        # Tạo prompt turn tiếp
      eval-finalize            # Finalization
      rewrite-human            # Viết lại text
      validate-output          # Kiểm tra chất lượng
      get-logs                 # Lấy logs từ tmux
      gen-claude-md/           # Tự tạo CLAUDE.md (cho agents không có /init)
  scripts/
    init_task.sh               # Tạo workspace + meta.json
    fetch_pr_diff.sh           # Fetch PR diff từ GitHub API
    collect_diffs.sh           # Thu thập A/B diffs vào turn dir
  templates/
    step1_spec.md              # Template Step 1 output
    turn_evaluation.md         # Template đánh giá mỗi turn
    step3_finalization.md      # Template Step 3 finalization
  workspace/                   # Các task workspace (tự sinh)
  reference/                   # Dữ liệu tham khảo + ví dụ
```

## Quy ước Workspace

Mỗi task tạo 1 thư mục:

```
workspace/{task_id}_{owner}_{repo}_{pr}/
  meta.json                    # Metadata + trạng thái task
  pr.diff                      # Diff gốc của PR
  step1_spec.md                # Output Step 1
  accepted_baseline.json       # Theo dõi bên thắng
  turn_1/
    prompt.md                  # Prompt gửi cho cả 2 models
    staged_diff_a.patch        # Thay đổi của Model A
    staged_diff_b.patch        # Thay đổi của Model B
    execution_evidence_a.md    # K���t qu�� test/build Model A
    execution_evidence_b.md    # Kết quả test/build Model B
    logs_a.txt                 # Logs từ tmux session Model A
    logs_b.txt                 # Logs từ tmux session Model B
    turn_1_evaluation.md       # Đánh giá được tạo
    turn_1_next_prompt.md      # Prompt turn tiếp theo
  turn_2/                      # Cùng cấu trúc
  turn_3/                      # Cùng cấu trúc
  step3_finalization.md        # Output cuối cùng
```

## Luồng làm việc đầy đủ

```
Giai đoạn 1: Thiết lập Task
  /task-select pr_url              --> TAKE/SKIP/CAUTION
  bash scripts/init_task.sh        --> workspace/
  bash scripts/fetch_pr_diff.sh    --> pr.diff
  /task-submit workspace/          --> step1_spec.md

Giai đoạn 2: Vòng lặp mỗi Turn (3+ turns)
  [Platform chạy Model A + B]
  /get-logs model_a model_b       --> kiểm tra running state
  bash scripts/collect_diffs.sh    --> turn_N/ artifacts
  /checkpoint-review workspace/ N  --> turn_N_evaluation.md (auto-validated)
  /checkpoint-qa workspace/ N      --> câu hỏi + gợi ý đáp án (auto-validated)
  CTV viết đáp án riêng
  /checkpoint-qa workspace/ N --evaluate --> đánh giá đáp án CTV
  /checkpoint-prompt workspace/ N  --> turn_N_next_prompt.md (auto-validated)
  Lặp lại cho turn 2, 3...

Giai đoạn 3: Hoàn tất
  /eval-finalize workspace/        --> step3_finalization.md
  /validate-output finalization    --> pass/fail
```

## Chống Reject

Skills được thiết kế để chống reject (phân tích từ 288 bản ghi):

| Lý do Reject | % | Skill chống | Gate |
|--------------|---|-------------|------|
| Prompt trùng lặp | 21.9% | checkpoint-prompt | Kiểm tra tính mới vs prompt trước |
| Đánh giá không chính xác | 14.2% | checkpoint-review | Code refs >= 3 mỗi section |
| Phát hiện AI/LLM | 10.1% | validate-output + rewrite-human | 38 bước scan + 10 quy tắc viết lại |
| Thiếu sót | 9.7% | checkpoint-review + eval-finalize | Cả 2 model phải có cons, tối thiểu 3 turns |
| Rating không nhất quán | 9.4% | checkpoint-review | Hướng rating khớp với winner |
| Lan rộng phạm vi | 7.6% | checkpoint-prompt | Kiểm tra scope vs issue gốc |
| Đánh giá bịa đặt | 6.9% | checkpoint-review | Bắt buộc cụ thể |
| Task chất lượng thấp | 5.2% | task-select | Lọc difficulty >= 3 |
| Vi phạm quy trình | 4.2% | validate-output + get-logs | Không tham chiếu PR, kiểm tra format |

## Tương thích đa nền tảng

> **Tất cả skills nằm tại:** `.claude/skills/<tên-skill>`
> 
> Ví dụ: `.claude/skills/checkpoint-review`, `.claude/skills/validate-output`

| Nền tảng | Cách dùng |
|----------|----------|
| Claude Code | Gọi `/skill-name` trực tiếp |
| Cursor | `@.claude/skills/checkpoint-review` trong Composer |
| Antigravity | `--system-prompt .claude/skills/checkpoint-review` |
| Codex (OpenAI) | `--instructions .claude/skills/checkpoint-review` |
| Custom Python | `open(".claude/skills/checkpoint-review").read()` → inject vào LLM |
| LangChain/LangGraph | Đọc file skill, dùng làm system message |

## Dữ liệu tham khảo

`reference/` chứa các ví dụ chuẩn:
- `329_prefecthq_prefect_13620/` - Ví dụ đánh giá 3 turns đầy đủ
- `APT_Marlin_step1_pipeline/` - Template pipeline Step 1
- `rewrite-human/` - Skill viết lại gốc

## License

Chỉ dùng nội bộ - Dự án TBrain Marlin.
