---
name: session-done
description: 세션 종료 시 진행 상황을 정리하고 클라우드 동기화 폴더(Google Drive Desktop, Dropbox, iCloud Drive 등 로컬 마운트되는 모든 클라우드 폴더)에 MD 문서만 미러링. 페이즈 종료 / 단순 세션 종료 두 가지 모드. /session-done 호출 시 사용. 최초 1회 셋업 (사용자명 + Drive 폴더 경로) 필요.
---

# session-done

세션을 마무리하면서:
1. 활성 과제의 페이즈 MD / progress.md / 핸드오프 MD 갱신
2. 로컬에 마운트된 클라우드 동기화 폴더로 MD 문서만 미러링

## 트리거
- 사용자가 `/session-done` 입력
- 사용자가 "세션 종료", "오늘 작업 마무리", "Drive에 정리해줘" 같은 표현

## 사전 조건
스킬 디렉토리: `~/.claude/skills/session-done/`
- `scripts/setup.sh` — 최초 셋업
- `scripts/sync.sh` — 미러링 (rsync)
- `scripts/secret_scan.sh` — 민감정보 스캔
- `templates/*.tpl` — phase / handoff / progress / readme
- `config.json` — 셋업 결과 (없으면 미셋업 상태)

가정하는 워크스페이스 구조:
```
<local_root>/
├── registry.md          ← 활성/완료 과제 보드
├── 01_projects/         ← (옵션) 프로젝트별 운영 문서
├── 02_analyses/         ← (옵션) 분석과제. active/ done/
├── 03_tasks/            ← (옵션) 구현과제. active/ done/
└── 04_docs/             ← (옵션) 운영팀 공통 문서
```
존재하는 폴더만 동기화됨. 없는 폴더는 자동 생성하지 않음.

## 절차

### Step 0. config.json 존재 확인

```bash
test -f ~/.claude/skills/session-done/config.json && echo OK || echo SETUP_NEEDED
```

`SETUP_NEEDED` → **Step 1 (셋업 인터뷰)**.
`OK` → **Step 2 (활성 과제 감지)**.

### Step 1. 최초 셋업 인터뷰 (1회만)

#### 1-A. 사용자명 입력

```
Drive(또는 클라우드 동기화 폴더)에서 본인 폴더로 표시될 이름:
(자유 형식 — 영문ID/실명/조합 등, 동료가 식별 가능한 형태)
```

#### 1-B. Drive 동기화 폴더 위치 안내

사용자에게 본인이 사용할 클라우드 동기화 폴더의 절대경로를 묻기. 자동 감지 도움을 주려면 macOS의 경우:

```bash
ls ~/Library/CloudStorage/ 2>/dev/null
```
→ `GoogleDrive-<email>`, `Dropbox`, `OneDrive-*` 등 후보 출력. 사용자가 그 안에서 본인 동기화 위치를 선택/입력.

권장 구조 예시 (필요에 맞게 조정):
```
<클라우드 마운트>/공유 드라이브/<팀>/<공유 카테고리>/<사용자명>/
```

#### 1-C. 로컬 루트 (옵션)

기본값: 현재 작업 디렉토리. 다른 경로를 쓰고 싶으면 사용자가 지정.

#### 1-D. 셋업 스크립트 실행

```bash
~/.claude/skills/session-done/scripts/setup.sh \
  --drive-root '<DRIVE_FULL_PATH>' \
  --user-name '<USER_NAME>' \
  --local-root '<LOCAL_ROOT>'
```

`--local-root` 생략하면 현재 디렉토리 사용. 결과(config 위치, Drive 폴더 경로) 사용자에게 출력 → Step 2 로 진행.

### Step 2. 활성 과제 감지

#### 2-A. 사용자 입력에서 과제 지정 추출 (우선)

사용자 메시지에 다음 형태가 있으면 **그걸 우선** 사용:

- **절대/상대 폴더 경로** — 예: `03_tasks/active/T-...-...slug/`
- **과제 ID** — 예: `T-YYYY-MMDD-NNN`, `F-YYYY-MMDD-NNN` → registry.md 매칭
- **슬러그/이름 일부** → registry.md fuzzy 매칭

지정 식별되면 2-B 건너뛰고 Step 3 으로 직행. 후보 여러 개면 사용자에게 명확화 요청.

#### 2-B. 자동 감지 (명시 지정 없을 때)

`<local_root>/registry.md` 를 Read 하여 active 행 추출.

- **0개**: "활성 과제 없음. registry.md 확인하세요." → 종료
- **1개**: 자동 선택
- **여러 개**: 최근 mtime 순으로 보여주고 선택. 폴더 mtime 기준:
  ```bash
  ls -dt <local_root>/02_analyses/active/*/ <local_root>/03_tasks/active/*/ 2>/dev/null | head -10
  ```

표시 시 **registry.md 의 한글 이름과 영문 경로를 함께** 출력 (식별성).
선택된 과제 폴더를 `$TASK_DIR` 로 저장.

### Step 3. 종료 유형 선택

```
[session-done] 어떤 종료인가요?
  [1] 페이즈 종료 — 현재 페이즈 마무리 + 다음 페이즈 MD 신규 생성
  [2] 단순 세션 종료 — 현재 페이즈 MD 에 진행분만 append
```

### Step 4. 과제 폴더 구조 점검 / 마이그레이션

`$TASK_DIR/` 내부 점검:
- `progress.md` 없으면 `templates/progress.md.tpl` 기반 생성
- `phases/` 없으면 mkdir. 비어있으면 `phases/01_initial.md` 생성 (`templates/phase.md.tpl` 기반)
- `handoffs/` 없으면 mkdir

기존 `progress.md` 가 free-form이면 유지. 단 `**활성 페이즈**` 헤더가 없으면 추가.

`phases/` 안 가장 큰 번호 파일이 **현재 페이즈**.

### Step 5-A. 페이즈 종료 처리

1. **현재 페이즈 MD 의 `## 페이즈 종료 요약` 섹션 채움**.
   사용자에게 다음을 묻고 채움:
   - 결과
   - 한계
   - 다음 페이즈로 넘기는 컨텍스트
   상단 `**상태**: in_progress` → `completed` 로 변경.

2. **다음 페이즈 정보 작성** (Claude가 초안 → 사용자 확인).
   `goals.md`, `progress.md`, 직전 페이즈 MD 를 읽고 다음 페이즈 후보 제안:
   - 페이즈 이름 (slug, 영소문자/하이픈)
   - 한 줄 목표
   - 체크리스트 항목 2~3개
   사용자 수정/확인.

3. **`phases/0(N+1)_<slug>.md` 생성** (`templates/phase.md.tpl` 기반).

4. **progress.md 갱신**:
   - `**활성 페이즈**: 0(N+1) (phases/0(N+1)_<slug>.md)`
   - `## 페이즈 진행도` 에 이전 페이즈 체크 + 새 페이즈 추가
   - `**최종 갱신**` = 현재 시각 (KST)
   - `## 다음 할 일` = 새 페이즈 체크리스트로 교체

5. **handoffs/`<YYYY-MMDD-HHMM>`.md 생성** (`templates/handoff.md.tpl` 기반):
   - `{{END_TYPE}}` = `phase-done`

### Step 5-B. 단순 세션 종료 처리

1. **현재 페이즈 MD `## 세션 로그` 에 오늘 항목 append**.
   사용자에게 묻거나 컨텍스트에서 추출:
   - 한 일 / 발견한 이슈 / 다음 할 일
   - 형식: `### YYYY-MM-DD\n- 한 일: ...\n- 발견한 이슈: ...\n- 다음 할 일: ...`

2. **progress.md 갱신**:
   - `**최종 갱신**` 시각
   - `## 다음 할 일` 갱신
   - `## 최근 핸드오프` 에 이번 핸드오프 파일명

3. **handoffs/`<YYYY-MMDD-HHMM>`.md 생성**:
   - `{{END_TYPE}}` = `session-done`

### Step 6. registry.md 갱신 (옵션)

`registry.md` 의 해당 과제 행 `최종 갱신` / `상태` 컬럼 업데이트.

### Step 7. 동기화

1. **변경된 MD + 기본 동기화 대상** 수집.

2. **민감정보 스캔**:
   ```bash
   FILE_LIST=$(mktemp)
   # 스캔 대상 MD 절대경로 줄단위 기록
   ~/.claude/skills/session-done/scripts/secret_scan.sh "$FILE_LIST"
   ```
   exit code != 0 → 결과를 사용자에게 보여주고 **동기화 중단**. 정리 후 재실행 안내.

3. **Dry-run 미리보기**:
   ```bash
   ~/.claude/skills/session-done/scripts/sync.sh --dry-run
   ```
   결과 사용자에게 보여주고 확인.

4. **실제 동기화**:
   ```bash
   ~/.claude/skills/session-done/scripts/sync.sh
   ```

5. **결과 리포트**:
   ```
   [session-done] 완료
     종료 유형:     <phase-done | session-done>
     과제:         <T-... | F-... slug>  (registry.md 의 한글 이름)
     페이즈:        <NN name>
     로컬 갱신:     phases/NN_*.md, progress.md, handoffs/<ts>.md
     Drive 업로드:  <N>개 파일
     충돌 백업:     <N>개
     Drive 위치:    <DRIVE_ROOT>
   ```

## 주의사항

- **폴더/경로는 영문 slug 만 사용**. 한글 이름은 `registry.md` "이름" 컬럼에만. macOS 한글 NFD 이슈, 셸/Drive 호환성.
- **단방향 동기화**. Drive 쪽 직접 편집은 다음 sync 때 덮어씌워질 수 있으나, mtime 더 최신이면 `.drive-conflict-<ts>.md` 백업.
- **민감정보 자동 redaction 금지**. 사용자가 직접 정리.
- **rsync whitelist에 없는 파일은 절대 업로드 안 됨** (`*.md` 만).
- **out/, bak/, credentials/, .omc/, venv/, __pycache__/, .pytest_cache/ 강제 제외**.
- **시간 표기는 KST** (또는 사용자 로케일).

## 실패 시

- Drive 베이스 경로 없음 → 클라우드 동기화 클라이언트 상태 확인
- secret_scan 차단 → 차단된 파일/라인 보여주고 정리 후 재시도
- rsync 실패 → 에러 그대로 노출, 추측 금지
