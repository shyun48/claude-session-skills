---
name: wy-session-resume
description: 새 세션 시작 시 활성 과제의 컨텍스트 빠르게 회복. progress.md → 현재 페이즈 MD → 최근 핸드오프 순서로 읽고 요약 출력. /wy-session-resume 호출 또는 "이어서 하자", "어디까지 했지", "재개" 같은 표현에서 사용.
---

# session-resume

세션 진입 즉시 활성 과제의 컨텍스트를 회복하고 다음 할 일 확인.

## 트리거
- 사용자가 `/wy-session-resume` 입력
- 사용자가 "이어서 하자", "어디까지 했지", "재개", "오늘 어디부터?" 같은 표현
- 새 세션 시작 시 명시적 과제 지정 없이 작업 의도를 보일 때

## 사전 조건
- `~/.claude/skills/wy-session-done/config.json` 가 존재 (셋업 완료)
- `<local_root>/registry.md` 에 활성 과제 등록되어 있어야 함

## 절차

### Step 0. config.json 확인

```bash
test -f ~/.claude/skills/wy-session-done/config.json
```

없으면: "session-done 스킬 셋업 먼저 필요. /wy-session-done 호출하세요." 안내 후 종료.

### Step 1. 활성 과제 식별

#### 1-A. 사용자 입력에서 과제 지정 추출 (우선)

사용자 메시지(현재 프롬프트 + 직전 히스토리)에 다음 형태가 있으면 **그걸 우선** 사용:

- **절대/상대 폴더 경로** — 예: `03_tasks/active/T-2026-0427-001_ops-bot-bootstrap/`
  → 그대로 `$TASK_DIR` 로 사용 (절대경로면 그대로, 상대면 `local_root` 기준)
- **과제 ID** — 예: `T-2026-0427-001`, `F-2026-0311-001`
  → `registry.md` 에서 매칭 후 "경로" 컬럼 사용
- **슬러그/이름 일부** — 예: `ops-bot-bootstrap`
  → `registry.md` 의 이름/경로 컬럼에서 fuzzy 매칭
  → 매칭 후보가 여러 개면 사용자에게 명확화 요청

지정이 식별되면 1-B 건너뛰고 Step 2 로 직행.

#### 1-B. 자동 감지 (명시 지정이 없을 때만)

config.json 의 `local_root` 사용. 그 아래 `registry.md` 를 Read.

- 표 형식이면 "active" / "in_progress" 상태 행만 추출
- 0개 → "활성 과제 없음" 안내
- 1개 → 자동 선택
- 여러 개:
  ```bash
  ls -dt <local_root>/02_analyses/active/*/ <local_root>/03_tasks/active/*/ 2>/dev/null | head -5
  ```
  최근 mtime 순으로 보여주고 사용자가 선택. 가장 최근 폴더는 `(추천)` 표시.

선택된 폴더를 `$TASK_DIR` 로 저장.

### Step 2. 표준 3종 파일 Read

순서대로 (병렬 호출 가능):

1. **`$TASK_DIR/progress.md`**
   - 활성 페이즈 번호 / 다음 할 일 / 페이즈 진행도 / 최근 핸드오프 추출
   - 없으면: "progress.md 없음 — session-done 스킬로 생성 필요" 경고

2. **`$TASK_DIR/phases/0N_*.md`** (N = progress.md 가 알려준 활성 페이즈 번호)
   - progress.md 가 알려준 정확한 파일 우선
   - 없으면 `phases/` 의 가장 큰 번호 파일 fallback
   - 페이즈 목표 / 체크리스트 / 마지막 세션 로그 추출

3. **`$TASK_DIR/handoffs/<latest>.md`**
   - 가장 최근 mtime 파일
   - 없으면 skip
   - 직전 종료 유형 / 세션 요약 / 다음 세션 진입 시 할 일 추출

### Step 3. 컨텍스트 요약 출력

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
재개 과제: <ID 한글이름>
경로:      <영문 폴더 경로>
현재 페이즈: <NN name>
페이즈 상태: <in_progress | blocked | completed>
직전 종료: <YYYY-MM-DD HH:MM> (<phase-done | session-done>)

다음 할 일 (progress.md):
  1. <항목 1>
  2. <항목 2>

직전 핸드오프 요약:
  - <세션 요약 한 줄>
  - <미해결 이슈 한 줄>

페이즈 체크리스트:
  [x] <완료 항목>
  [ ] <남은 항목>

세부 파일:
  - 페이즈: phases/<NN_slug>.md
  - 핸드오프: handoffs/<latest>.md
  - 진행도: progress.md
  - 추가 컨텍스트: brief.md (또는 01_ask.md), goals.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4. 추가 로드 판단

기본은 위 3종이면 충분. 단:

- 사용자가 "이 과제 처음 본다" / "전체 그림" / "목표가 뭐였지?" → `goals.md` + `brief.md` 추가 Read
- 페이즈 종료 직후 첫 세션 (`{{END_TYPE}}` = `phase-done`) → 직전 페이즈 MD 도 같이 Read
- 블로커 상태 → `## 블로커` 섹션 강조

### Step 5. 사용자 의도 확인

```
이 컨텍스트로 진행할까요? 다른 과제로 전환하려면 알려주세요.
```

## 주의사항

- **활성 과제 식별 시 registry.md 의 "이름" 컬럼(한글)을 영문 경로와 함께 표시** — 영문 경로만 보여주면 식별 어려움.
- **3종 파일을 항상 같은 순서로 읽어 일관된 회복 경험**.
- **추측 금지**: progress.md / 페이즈 MD 모순되면 둘 다 보여주고 사용자 확인.
- **실제 코드/데이터는 읽지 않음**. 컨텍스트 회복은 MD 문서 기반.

## 실패 시

- registry.md 없음 → 등록 절차 안내
- progress.md 없음 → "session-done 으로 초기 구조 생성" 안내
- phases/ 비어있음 → "첫 세션이거나 마이그레이션 필요" 안내
