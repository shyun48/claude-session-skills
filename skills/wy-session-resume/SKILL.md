---
name: wy-session-resume
description: 새 세션 시작 시 활성 과제의 컨텍스트 빠르게 회복. progress.md → 현재 페이즈 MD → 최근 핸드오프 순서로 읽고 요약 출력. /wy-session-resume 호출 또는 "이어서 하자", "어디까지 했지", "재개" 같은 표현에서 사용.
---

# wy-session-resume

활성 과제 컨텍스트 회복.

**트리거**: `/wy-session-resume`, "이어서 하자", "어디까지 했지", "재개", "오늘 어디부터?"

**사전 조건**: `~/.claude/skills/wy-session-done/config.json` 존재 + `<local_root>/registry.md` 활성 행.

## 절차

### 0. 셋업 확인
```bash
test -f ~/.claude/skills/wy-session-done/config.json
```
없으면: "/wy-session-done 셋업 먼저 필요" 안내 후 종료.

### 1. 과제 식별
**우선** — 사용자 입력에서 추출:
- 폴더 경로(절대/상대) → 그대로 `$TASK_DIR`
- 과제 ID(예: `T-2026-...`) → registry.md 매칭 후 경로 컬럼
- slug/이름 일부 → registry.md fuzzy 매칭 (다중이면 명확화 요청)

**자동** (명시 없을 때) — config.json 의 `local_root/registry.md` 의 active 행:
- 0개: "활성 과제 없음"
- 1개: 자동 선택
- 다중: `ls -dt 02_analyses/active/*/ 03_tasks/active/*/ | head -5` mtime 순 표시(최신=추천)

### 2. 3종 파일 Read (병렬)
1. `$TASK_DIR/progress.md` — 활성 페이즈/다음 할 일/페이즈 진행도/최근 핸드오프
2. `$TASK_DIR/phases/0N_*.md` (progress가 알려준 N, 없으면 최대 번호) — 목표/체크리스트/세션 로그
3. `$TASK_DIR/handoffs/<latest>.md` (mtime 최신) — 직전 종료 유형/요약/다음 할 일

### 3. 요약 출력
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
재개 과제: <ID 한글이름>
경로:     <영문 경로>
현재 페이즈: <NN name>  (<in_progress|blocked|completed>)
직전 종료: <ts> (<phase-done|session-done>)

다음 할 일 (progress.md):
  1. ...
  2. ...

직전 핸드오프 요약:
  - <세션 요약>
  - <미해결>

페이즈 체크리스트:
  [x] <완료>
  [ ] <남음>

세부: phases/<NN_slug>.md, handoffs/<latest>.md, progress.md, brief.md|01_ask.md, goals.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
이 컨텍스트로 진행할까요? 다른 과제로 전환하려면 알려주세요.
```

### 4. 추가 로드 (조건부)
- "처음 본다"/"전체 그림"/"목표 뭐였지?" → `goals.md` + `brief.md`/`01_ask.md`
- 직전이 `phase-done` → 직전 페이즈 MD 도 함께 Read
- 블로커 상태 → `## 블로커` 섹션 강조

## 주의
- registry "이름"(한글) + 영문 경로 함께 표시 (식별성)
- 3종 파일 항상 같은 순서 읽기 (일관성)
- progress.md vs 페이즈 MD 모순 시 둘 다 보여주고 사용자 확인
- 코드/데이터 안 읽음. MD 만.

## 실패 시
- registry.md 없음 → 등록 절차 안내
- progress.md 없음 → `/wy-session-done` 으로 초기 구조 생성 안내
- phases/ 비어있음 → 첫 세션 또는 마이그레이션 필요 안내
