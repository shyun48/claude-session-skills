---
name: wy-new-task
description: 신규 과제 폴더 + Jira 티켓을 한 번에 생성. 기존 폴더에 Jira 발급(역방향), 기존 Jira에서 폴더 스캐폴드(정방향), 둘 다 있는 매핑만 등록(복구) 모드 지원. /wy-new-task 호출 시 사용.
user-invocable: true
argument-hint: "[<폴더경로>|<JIRA-KEY>|--no-jira] [<제목>]"
---

# wy-new-task

신규 과제와 Jira 티켓을 동시에 만들거나, 한쪽이 이미 있는 경우 매핑·보강을 처리.

## 트리거
- 사용자가 `/wy-new-task` 입력
- "새 과제 만들자", "Jira 티켓 발급해줘", "이 폴더에 지라 연결해줘" 같은 표현

## 사전 조건
- `<local_root>/registry.md` 존재 (CLAUDE.md 의 워크스페이스 컨벤션)
- (옵션) Atlassian Cloud MCP 셋업 — 없으면 Jira 단계 자동 스킵
- `01_projects/<project>/` 디렉토리는 프로젝트 단위로 사전 생성되어 있을 것

## 4가지 모드

| 모드 | 트리거 | 동작 |
|------|--------|------|
| **A. 신규** | 인자 없음 | 인터뷰 → 폴더 생성 → Jira 발급 → 매핑 |
| **B. 역방향** | 폴더 경로 인자 (`/`로 끝남 또는 `02_analyses/` `03_tasks/` 시작) | 기존 폴더 읽어 Jira 발급 → 매핑 |
| **C. 정방향** | `--from-jira <KEY>` 또는 인자가 `[A-Z]+-\d+` 패턴 | Jira 읽어와 폴더 스캐폴드 → 매핑 |
| **D. 복구** | 폴더 경로 + Jira 키 동시 지정 | 매핑만 등록 |

## 절차

### Step 0. 모드 결정

사용자 입력에서 mode 추출:

```bash
# 인자 분석 의사코드
arg1=$1; arg2=$2
if [[ "$arg1" =~ ^([A-Z]+-[0-9]+)$ ]] || [[ "$1" == --from-jira ]]; then
  MODE=C
elif [[ -d "$arg1" ]] || [[ "$arg1" == */ ]] || [[ "$arg1" =~ ^0[23]_(analyses|tasks)/ ]]; then
  if [[ "$arg2" =~ ^([A-Z]+-[0-9]+)$ ]]; then MODE=D; else MODE=B; fi
elif [[ -z "$arg1" ]] && [[ -f brief.md || -f 01_ask.md ]]; then
  MODE=B  # 현재 디렉토리가 과제 폴더면 B 자동
else
  MODE=A
fi
```

`--no-jira` 플래그가 있으면 모드 무관 Jira 단계 스킵.

### Step 1. Atlassian MCP 가용성 점검

```bash
# Atlassian Cloud MCP 도구가 노출되어 있는지 확인
# 일반적으로 mcp__atlassian__* 또는 비슷한 prefix
```

`ToolSearch` 로 atlassian/jira 키워드 검색해 사용 가능한 MCP 도구 확인. 없으면 `JIRA_AVAILABLE=false` 로 표시 후 사용자에게 "Atlassian MCP 미셋업, 로컬만 생성합니다" 안내.

### Step 2-A. 모드 A — 신규 과제 인터뷰

순서대로 묻고 답 수집:

1. **타입**: `F` (분석/메이저) / `S` (분석/단발) / `T` (구현)
2. **제목** (한글 자유 형식): 예 — "라이더 Gap KPI 대시보드"
3. **slug** (영문): 한 줄 자동 제안 후 확인. 예 — `rider-gap-kpi-dashboard`
4. **프로젝트** (선택):
   - `01_projects/` 의 디렉토리 목록 출력 + "없음/신규" 옵션
   - 선택 시: 해당 프로젝트로 매핑
   - 없음/신규 선택 시: 프로젝트 무관 과제로 처리 (Jira 안 만듦)
   - 새 프로젝트 입력 시: `01_projects/<name>/` 생성
5. **한 줄 골**: 측정 가능한 형태 권장. 예 — "시간단위 Gap-KPI 비교 차트 + 운영 alert 1개 자동 발화"
6. **Jira 동시 생성?** (Y/n): MCP 가용 + 프로젝트 지정 시 기본 Y, 그 외 N

확인 후 Step 3으로.

### Step 2-B. 모드 B — 폴더 → Jira

1. 인자 폴더 절대경로 정규화
2. 폴더 내 `brief.md`/`01_ask.md`, `goals.md` 읽기
3. 메타 추출: 타입(폴더 prefix), slug(폴더명), 제목(brief 첫 헤더), 한 줄 골(goals.md 핵심)
4. **이미 Jira 매핑 존재 여부 확인** — `brief.md`/`01_ask.md` 헤더에 `Jira:` 라인이나 `[A-Z]+-\d+` 키 검색
   - 있으면 "이미 매핑됨: <키>" 출력 후 종료 (사용자가 `--force` 명시 시만 재발급)
5. 프로젝트 결정:
   - 폴더 경로 또는 `registry.md` 의 해당 행에서 프로젝트 추론
   - 추론 실패 시 사용자에게 묻기

→ Step 3 으로.

### Step 2-C. 모드 C — Jira → 폴더

1. Atlassian MCP 로 Jira issue 조회 (summary, description, labels, parent epic, project key)
2. 메타 매핑:
   - **타입**: 라벨에서 `analysis` → F or S, `task` → T 추출 (없으면 사용자에게 묻기)
   - **slug**: summary 한글 → 영문 자동 변환 시도, 실패 시 사용자 입력
   - **제목**: summary 그대로
   - **한 줄 골**: description 첫 문장 또는 사용자 입력
3. 프로젝트: parent epic 의 `.jira.json` 매칭 검색 → 매칭 없으면 사용자에게 묻기

→ Step 3 으로.

### Step 2-D. 모드 D — 매핑만 등록

폴더와 Jira 키 모두 입력받음:
1. 폴더 존재 확인, Jira issue 존재 확인
2. brief.md 헤더에 Jira 라인 추가/갱신
3. registry.md Jira 컬럼 갱신
4. 프로젝트 `.jira.json` 일관성 확인 (Epic 키와 issue 의 parent 일치)

→ Step 6 (마무리) 로 직행.

### Step 3. ID + 폴더 생성 (모드 A/C)

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/..}/skills/wy-new-task/scripts/create_task.py \
  --type "<F|S|T>" \
  --title "<제목>" \
  --slug "<slug>" \
  --project "<project|''>" \
  --goal "<한 줄 골>" \
  --local-root "<local_root>" \
  --mode "<A|C>" \
  ${JIRA_KEY:+--from-jira "$JIRA_KEY"} \
  ${JIRA_DESC:+--jira-description "$JIRA_DESC"}
```

스크립트가:
1. 다음 ID 생성 (`{F|S|T}-YYYY-MMDD-NNN`, NNN = 같은 날짜의 최대치+1)
2. 폴더 스캐폴드: `02_analyses/active/F-...` 또는 `03_tasks/active/T-...`
3. `brief.md`/`01_ask.md`, `goals.md`, `progress.md`, `phases/01_initial.md`, `handoffs/` 템플릿 채워 생성
4. registry.md 에 행 삽입 (활성 테이블)
5. 프로젝트 지정 시 `01_projects/<project>/registry.md` 에도 행 추가
6. JSON 메타데이터 stdout

JSON 결과 파싱해서 `$TASK_ID`, `$TASK_DIR` 변수 보관.

### Step 4. Jira 발급 (모드 A/B/C, JIRA_AVAILABLE && 프로젝트 지정)

#### 4-A. 프로젝트 Epic 확인 / 생성

`01_projects/<project>/.jira.json` 읽기:
- 존재 + `epic_key` 채워짐 → 그대로 사용
- 부재 또는 빈 값 → 새 Epic 생성

새 Epic 생성:
```
Atlassian MCP create_issue:
  project_key: REALTIMEOP
  issue_type: Epic
  summary: <project 이름 (한글)>
  description: "01_projects/<project>/ 에 대응하는 Epic"
  labels: ["wy-task-mgmt", "auto-generated"]
```

성공 시 Epic 키를 `01_projects/<project>/.jira.json` 에 저장:
```json
{
  "epic_key": "REALTIMEOP-1234",
  "project": "<project>",
  "created_at": "<KST timestamp>"
}
```

#### 4-B. Issue 생성 (Epic 하위)

```
Atlassian MCP create_issue:
  project_key: REALTIMEOP
  issue_type: Task
  parent: <epic_key>           # Epic 링크
  summary: <과제 제목 (한글)>
  description: <goals.md 한 줄 골 + brief.md 일부>
  labels:
    - wy-task-mgmt
    - <analysis | task>        # F/S 면 analysis, T 면 task
    - <project>                 # 프로젝트 슬러그도 라벨로
```

응답에서 issue_key, issue_url 확보.

#### 4-C. 매핑 정보 기록

`brief.md` (또는 `01_ask.md`) 최상단 메타 블록에:
```
> **Jira**: [{issue_key}]({issue_url})
> **Epic**: [{epic_key}](URL)
```

`registry.md` 의 해당 과제 행 Jira 컬럼에 `[키](URL)` 형식으로 기록.

### Step 5. 후속 안내 (모드 A/C)

```
✓ 과제 생성 완료
  ID:        <T-2026-...-NNN>
  경로:      <full path>
  프로젝트:   <project | (없음)>
  Jira:      <키 + URL | (생성 안 함)>

이어서 deep-interview 들어갈까요? (Y/n)
  → Y: deep-interview 스킬 호출 (브리핑 구체화)
  → n: 종료
```

deep-interview 가 채운 brief.md/goals.md 가 충실해지면 `/wy-goal-loop <폴더>` 로 진입 가능.

### Step 6. 마무리 (모든 모드 공통)

- 사용자에게 결과 요약
- 다음 단계 추천:
  - 모드 A/C → `/wy-goal-loop <폴더>` 로 즉시 진입 가능
  - 모드 B/D → registry.md / 폴더 brief 갱신 확인

## 주의사항

- **폴더/slug 는 영문만**. 한글 NFD/Drive 호환성 문제. 한글 제목은 brief.md/registry "이름" 컬럼에만.
- **Jira 키는 사용자 인스턴스에 의존**. 기본 프로젝트 키는 `REALTIMEOP`. 사용자가 다른 프로젝트 쓰면 인터뷰에서 변경 가능.
- **MCP 미가용 + 프로젝트 미지정**: 두 경우 모두 Jira 단계 스킵. 로컬만 생성.
- **자동 추측 금지**: slug 자동 변환·프로젝트 추론은 항상 사용자 확인을 거침.
- **registry 일관성**: 모든 모드 시작 시 폴더 ↔ registry ↔ Jira 매핑 검증. 끊긴 게 있으면 묻고 복구.

## 실패 시

- registry.md 부재 → 사용자에게 워크스페이스 셋업 안내 (CLAUDE.md 참조)
- Atlassian MCP 호출 실패 → 에러 그대로 노출, Jira 단계만 롤백 (로컬 폴더는 유지). 사용자가 추후 모드 B 로 재발급 가능
- 프로젝트 폴더 부재 → 사용자에게 묻고 자동 생성 (`01_projects/<name>/registry.md` + `.jira.json` placeholder)
- ID 충돌 (동일 NNN 존재) → NNN+1 로 자동 재시도 (3회까지)
