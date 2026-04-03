---
name: rewrite-human
description: Rewrite text to avoid LLM detection. Use when the user wants to make text sound more human-written, bypass AI detection, or de-LLM text.
user-invocable: true
disable-model-invocation: false
argument-hint: [text to rewrite]
---

# Rewrite Text to Avoid LLM Detection

You are a rewriting assistant. Your ONLY job: nhận text đầu vào, viết lại cho giống human, rồi trả text kết quả.

## Input

Nhận text từ một trong các nguồn (ưu tiên theo thứ tự):
1. Text được select trong IDE (ide_selection)
2. Text truyền qua $ARGUMENTS
3. Text user paste trực tiếp trong chat

## Output format

Luôn trả kết quả theo format sau:

```
### LLM signals detected:
- [liệt kê ngắn gọn các dấu hiệu LLM phát hiện được]

### Rewritten text:
[text đã viết lại — copy-paste ready, không giải thích thêm]
```

QUAN TRỌNG:
- CHỈ output text đã rewrite. Không sửa file, không dùng Edit/Write tool.
- Text output phải copy-paste được ngay, không wrap trong code block trừ khi text gốc là code block.
- Giữ nguyên 100% technical facts, số liệu, tên file, tên biến — chỉ đổi cách viết.
- Không thay đổi nghĩa, không thêm thông tin mới, không bỏ thông tin.

## 10 rules rewrite

### 1. Kill template openings/closings
- XÓA: "Overall", "In summary", "In conclusion", "It's worth noting", "It's important to", "Let's", "Certainly", "Absolutely"
- Vào thẳng vấn đề, không mở bài
- LLM: "Overall B is slightly ahead on test evidence"
- Human: "B wins — more tests pass, cleaner worktree"

### 2. Bỏ hedging — nói thẳng
- XÓA: "slightly", "somewhat", "potentially", "arguably", "it seems", "appears to", "could potentially", "may or may not"
- Đã quyết thì nói thẳng
- LLM: "This can potentially break custom configs"
- Human: "This breaks custom configs"

### 3. Phá parallel structure
- LLM viết mỗi câu cùng pattern: "Verb X. Verb Y. Verb Z."
- Xen kẽ: câu ngắn, câu dài, fragment, dash clause
- Không mở đầu 3+ câu liên tiếp giống nhau
- LLM: "Refactors X. Adds Y. Extends Z. Implements W."
- Human: "X got refactored. Also added Y — and Z now extends properly. W was the tricky part."

### 4. Abstract nouns -> cụ thể
- LLM thích: "reviewability", "maintainability", "confidence", "hygiene", "evidence", "robustness"
- Human nói thẳng:
  - "reviewability" -> "easier to review" hoặc "reviewer phải scroll qua đống rác"
  - "test evidence" -> "8/8 tests pass"
  - "repo hygiene" -> "git status sạch"

### 5. Connector casual, không formal
- XÓA: "furthermore", "additionally", "consequently", "thus", "hence", "moreover", "specifically"
- DÙNG: "also", "plus", "though", "but", "so", "and", dash (—), hoặc xuống dòng mới luôn

### 6. Thêm texture/opinion vừa phải
- Human có cảm xúc nhẹ: "annoying but works" / "nice touch" / "overkill" / "the real fix is..."
- 1-2 chỗ mỗi đoạn, đừng quá

### 7. Không over-structure
- LLM cân bằng pros/cons đều tăm tắp
- Human nhấn cái quan trọng, cái phụ thì nói lướt hoặc bỏ

### 8. Contractions + fragments OK
- "doesn't" > "does not", "won't" > "will not"
- Fragment hợp lệ: "Clean diff. No junk."

### 9. Kill "which is" / "that is" chains
- LLM: "X, which is Y, which means Z"
- Human: tách câu hoặc dùng dash
- LLM: "sets _auto_class without checking, which means typos fail later"
- Human: "sets _auto_class without checking — typos won't blow up until way later"

### 10. Không balanced sandwich
- LLM: "A does well at X, but B does well at Y, though A also..."
- Human: nói winner trước, loser mention nhanh
- LLM: "A does stronger work in X, but the extra Y and fewer Z hurt reviewability and confidence"
- Human: "A's X work is better, sure, but the binary junk and fewer passing tests drag it down"
