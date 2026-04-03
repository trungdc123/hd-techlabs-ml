#!/usr/bin/env bash
set -euo pipefail

# Demo test script - kiểm tra toàn bộ pipeline với task 329
# Chạy: bash scripts/demo_test.sh
#
# Script này KHÔNG chạy skills (cần Claude Code / LLM).
# Nó kiểm tra:
# 1. Workspace structure đúng
# 2. Tất cả files cần thiết tồn tại
# 3. Content validation cơ bản
# 4. Simulate luồng từ đầu đến cuối

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_WORKSPACE="${PROJECT_DIR}/workspace/329_PrefectHQ_prefect_13620"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() {
  echo -e "  ${GREEN}PASS${NC} $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo -e "  ${RED}FAIL${NC} $1"
  FAIL=$((FAIL + 1))
}

check_warn() {
  echo -e "  ${YELLOW}WARN${NC} $1"
  WARN=$((WARN + 1))
}

section() {
  echo ""
  echo -e "${BLUE}=== $1 ===${NC}"
}

# ============================================================
section "1. Kiểm tra cấu trúc project"
# ============================================================

for f in CLAUDE.md README.md TUTORIAL.md; do
  if [[ -f "${PROJECT_DIR}/$f" ]]; then
    check_pass "$f tồn tại"
  else
    check_fail "$f THIẾU"
  fi
done

for d in skills scripts templates workspace reference; do
  if [[ -d "${PROJECT_DIR}/$d" ]]; then
    check_pass "Thư mục $d/ tồn tại"
  else
    check_fail "Thư mục $d/ THIẾU"
  fi
done

# ============================================================
section "2. Kiểm tra skills"
# ============================================================

SKILLS=(task-select task-submit checkpoint-review checkpoint-qa checkpoint-prompt eval-finalize rewrite-human validate-output get-logs gen-claude-md)
for skill in "${SKILLS[@]}"; do
  if [[ -f "${PROJECT_DIR}/skills/${skill}/SKILL.md" ]]; then
    # Kiểm tra frontmatter
    if head -1 "${PROJECT_DIR}/skills/${skill}/SKILL.md" | grep -q "^---"; then
      check_pass "skills/${skill}/SKILL.md (frontmatter OK)"
    else
      check_warn "skills/${skill}/SKILL.md (thiếu frontmatter ---)"
    fi
  else
    check_fail "skills/${skill}/SKILL.md THIẾU"
  fi
done

# Shared resources
for f in blocked_words.md rating_scale.md rejection_rules.md style_guide.md; do
  if [[ -f "${PROJECT_DIR}/skills/_shared/$f" ]]; then
    check_pass "skills/_shared/$f"
  else
    check_fail "skills/_shared/$f THIẾU"
  fi
done

# ============================================================
section "3. Kiểm tra scripts"
# ============================================================

for f in init_task.sh fetch_pr_diff.sh collect_diffs.sh; do
  if [[ -f "${PROJECT_DIR}/scripts/$f" ]]; then
    if [[ -x "${PROJECT_DIR}/scripts/$f" ]]; then
      check_pass "scripts/$f (executable)"
    else
      check_warn "scripts/$f (không executable - chạy chmod +x)"
    fi
  else
    check_fail "scripts/$f THIẾU"
  fi
done

# ============================================================
section "4. Kiểm tra templates"
# ============================================================

for f in step1_spec.md turn_evaluation.md step3_finalization.md; do
  if [[ -f "${PROJECT_DIR}/templates/$f" ]]; then
    check_pass "templates/$f"
  else
    check_fail "templates/$f THIẾU"
  fi
done

# ============================================================
section "5. Kiểm tra demo workspace (329)"
# ============================================================

if [[ ! -d "$DEMO_WORKSPACE" ]]; then
  check_fail "Demo workspace không tồn tại: $DEMO_WORKSPACE"
  echo -e "${RED}Không thể tiếp tục test workspace. Dừng lại.${NC}"
  echo ""
  echo "Kết quả: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
  exit 1
fi

# meta.json
if [[ -f "${DEMO_WORKSPACE}/meta.json" ]]; then
  if python3 -c "import json; json.load(open('${DEMO_WORKSPACE}/meta.json'))" 2>/dev/null; then
    check_pass "meta.json (JSON hợp lệ)"
  else
    check_fail "meta.json (JSON KHÔNG hợp lệ)"
  fi
else
  check_fail "meta.json THIẾU"
fi

# pr.diff
if [[ -f "${DEMO_WORKSPACE}/pr.diff" ]]; then
  LINES=$(wc -l < "${DEMO_WORKSPACE}/pr.diff" | tr -d ' ')
  check_pass "pr.diff (${LINES} dòng)"
else
  check_fail "pr.diff THIẾU"
fi

# step1_spec.md
if [[ -f "${DEMO_WORKSPACE}/step1_spec.md" ]]; then
  # Kiểm tra 6 sections bắt buộc
  SECTIONS=0
  for section_name in "Prompt Category" "Repo Definition" "PR Definition" "Edge Cases" "Acceptance Criteria" "Initial Prompt"; do
    if grep -q "$section_name" "${DEMO_WORKSPACE}/step1_spec.md"; then
      SECTIONS=$((SECTIONS + 1))
    fi
  done
  if [[ $SECTIONS -eq 6 ]]; then
    check_pass "step1_spec.md (đủ 6/6 sections)"
  else
    check_warn "step1_spec.md (chỉ ${SECTIONS}/6 sections)"
  fi
else
  check_fail "step1_spec.md THIẾU"
fi

# accepted_baseline.json
if [[ -f "${DEMO_WORKSPACE}/accepted_baseline.json" ]]; then
  check_pass "accepted_baseline.json"
else
  check_warn "accepted_baseline.json thiếu (cần tạo sau Turn 1)"
fi

# ============================================================
section "6. Kiểm tra 3 turns"
# ============================================================

for turn in 1 2 3; do
  TURN_DIR="${DEMO_WORKSPACE}/turn_${turn}"
  echo -e "  ${BLUE}--- Turn ${turn} ---${NC}"

  if [[ ! -d "$TURN_DIR" ]]; then
    check_fail "turn_${turn}/ THIẾU"
    continue
  fi

  # Bắt buộc: diffs
  for f in staged_diff_a.patch staged_diff_b.patch; do
    if [[ -f "${TURN_DIR}/$f" ]]; then
      SIZE=$(wc -l < "${TURN_DIR}/$f" | tr -d ' ')
      if [[ $SIZE -gt 0 ]]; then
        check_pass "${f} (${SIZE} dòng)"
      else
        check_warn "${f} (rỗng)"
      fi
    else
      check_fail "${f} THIẾU"
    fi
  done

  # Bắt buộc: evidence
  for f in execution_evidence_a.md execution_evidence_b.md; do
    if [[ -f "${TURN_DIR}/$f" ]]; then
      check_pass "$f"
    else
      check_warn "$f thiếu"
    fi
  done

  # Bắt buộc: prompt
  if [[ -f "${TURN_DIR}/prompt.md" ]]; then
    check_pass "prompt.md"
  else
    check_fail "prompt.md THIẾU"
  fi

  # Bắt buộc: evaluation
  EVAL_FILE="${TURN_DIR}/turn_${turn}_evaluation.md"
  if [[ -f "$EVAL_FILE" ]]; then
    # Kiểm tra cơ bản: có Preferred Answer không
    if grep -q "Preferred Answer" "$EVAL_FILE"; then
      check_pass "turn_${turn}_evaluation.md (có Preferred Answer)"
    else
      check_warn "turn_${turn}_evaluation.md (thiếu Preferred Answer section)"
    fi

    # Kiểm tra blocked words
    BLOCKED_FOUND=""
    for word in robust comprehensive leverage streamline utilize facilitate enhance optimal seamless holistic paradigm innovative transformative pivotal delve; do
      if grep -qi "\b${word}\b" "$EVAL_FILE" 2>/dev/null; then
        BLOCKED_FOUND="${BLOCKED_FOUND} ${word}"
      fi
    done
    if [[ -n "$BLOCKED_FOUND" ]]; then
      check_warn "turn_${turn}_evaluation.md chứa blocked words:${BLOCKED_FOUND}"
    else
      check_pass "turn_${turn}_evaluation.md (không có blocked words)"
    fi

    # Kiểm tra em dashes
    if grep -q '—' "$EVAL_FILE" 2>/dev/null; then
      check_warn "turn_${turn}_evaluation.md chứa em dashes (—)"
    else
      check_pass "turn_${turn}_evaluation.md (không có em dashes)"
    fi
  else
    check_fail "turn_${turn}_evaluation.md THIẾU"
  fi

  # Tùy chọn: next prompt (không cần ở turn cuối)
  NEXT_PROMPT="${TURN_DIR}/turn_${turn}_next_prompt.md"
  if [[ -f "$NEXT_PROMPT" ]]; then
    check_pass "turn_${turn}_next_prompt.md"
  elif [[ $turn -lt 3 ]]; then
    check_warn "turn_${turn}_next_prompt.md thiếu (cần cho turn tiếp theo)"
  fi

  # Logs
  for side in a b; do
    if [[ -f "${TURN_DIR}/logs_${side}.txt" ]]; then
      check_pass "logs_${side}.txt"
    else
      check_warn "logs_${side}.txt thiếu (nên có cho evidence)"
    fi
  done
done

# ============================================================
section "7. Checkpoint Q&A (turn 1)"
# ============================================================

QA_DIR="${DEMO_WORKSPACE}/turn_1/qa"
if [[ -d "$QA_DIR" ]]; then
  check_pass "turn_1/qa/ directory exists"

  # questions.json
  if [[ -f "${QA_DIR}/questions.json" ]]; then
    if python3 -c "import json; qs=json.load(open('${QA_DIR}/questions.json')); assert len(qs)>=1" 2>/dev/null; then
      Q_COUNT=$(python3 -c "import json; print(len(json.load(open('${QA_DIR}/questions.json'))))")
      check_pass "questions.json (${Q_COUNT} questions)"
    else
      check_warn "questions.json (empty or invalid)"
    fi
  else
    check_warn "questions.json missing"
  fi

  # At least 1 suggestion
  if ls "${QA_DIR}"/q_*_suggestion.md 1>/dev/null 2>&1; then
    SUGG_COUNT=$(ls "${QA_DIR}"/q_*_suggestion.md 2>/dev/null | wc -l | tr -d ' ')
    check_pass "Q&A suggestions (${SUGG_COUNT} files)"
  else
    check_warn "No Q&A suggestion files"
  fi

  # Overall justification
  if [[ -f "${QA_DIR}/overall_justification.md" ]]; then
    if grep -q "Preferred Model" "${QA_DIR}/overall_justification.md"; then
      check_pass "overall_justification.md (has Preferred Model)"
    else
      check_warn "overall_justification.md (missing Preferred Model)"
    fi

    if grep -q "Key-axis" "${QA_DIR}/overall_justification.md"; then
      check_pass "overall_justification.md (has Key-axis)"
    else
      check_warn "overall_justification.md (missing Key-axis)"
    fi
  else
    check_warn "overall_justification.md missing"
  fi
else
  check_warn "turn_1/qa/ directory missing (run /checkpoint-qa to create)"
fi

# ============================================================
section "8. step3_finalization.md"
# ============================================================

FINAL="${DEMO_WORKSPACE}/step3_finalization.md"
if [[ -f "$FINAL" ]]; then
  FINAL_SECTIONS=0
  for section_name in "PR URL" "Categories" "Trajectory" "Multi-Axis" "Runtime" "Justification" "Submission Readiness" "Missing Evidence" "Turn Summary"; do
    if grep -qi "$section_name" "$FINAL"; then
      FINAL_SECTIONS=$((FINAL_SECTIONS + 1))
    fi
  done
  check_pass "step3_finalization.md (${FINAL_SECTIONS}/9 sections tìm thấy)"

  # Blocked words check
  BLOCKED_FOUND=""
  for word in robust comprehensive leverage streamline utilize facilitate enhance optimal seamless; do
    if grep -qi "\b${word}\b" "$FINAL" 2>/dev/null; then
      BLOCKED_FOUND="${BLOCKED_FOUND} ${word}"
    fi
  done
  if [[ -n "$BLOCKED_FOUND" ]]; then
    check_warn "step3_finalization.md chứa blocked words:${BLOCKED_FOUND}"
  else
    check_pass "step3_finalization.md (không có blocked words)"
  fi
else
  check_fail "step3_finalization.md THIẾU"
fi

# ============================================================
section "9. Summary"
# ============================================================

TOTAL=$((PASS + FAIL + WARN))
echo ""
echo -e "  Tổng: ${TOTAL} checks"
echo -e "  ${GREEN}PASS: ${PASS}${NC}"
echo -e "  ${RED}FAIL: ${FAIL}${NC}"
echo -e "  ${YELLOW}WARN: ${WARN}${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Demo workspace sẵn sàng để test skills!${NC}"
  echo ""
  echo "Tiếp theo, trong Claude Code session:"
  echo "  1. /checkpoint-review workspace/329_PrefectHQ_prefect_13620 1"
  echo "  2. /validate-output workspace/329_PrefectHQ_prefect_13620/turn_1/turn_1_evaluation.md"
  echo "  3. /eval-finalize workspace/329_PrefectHQ_prefect_13620"
else
  echo -e "${RED}Có ${FAIL} lỗi cần sửa trước khi test.${NC}"
fi
