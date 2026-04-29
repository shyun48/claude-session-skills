---
name: wy-session-done
description: 세션 종료 시 활성 과제의 progress/phase/handoff MD 갱신 + 클라우드 동기화 폴더로 MD 미러링. 페이즈 종료/단순 세션 종료 모드. 최초 1회 셋업(사용자명+Drive 경로) 필요. /wy-session-done 호출 시 사용.
---

# wy-session-done

세션 마무리 → progress.md / 현재 페이즈 MD / handoffs/<ts>.md 갱신 → Drive 미러링.

**트리거**: `/wy-session-done`, "세션 종료", "오늘 작업 마무리", "Drive에 정리해줘"

## 절차

### 0. 셋업 확인
```bash
test -f ~/.claude/skills/wy-session-done/config.json
```
없으면 → **Step 1**. 있으면 → **Step 2**.

### 1. 셋업 인터뷰 (1회)
사용자에게 다음을 묻고 setup.sh 실행:
- `user_name`: Drive에 표시될 본인 이름 (자유 형식)
- `drive_root`: 클라우드 동기화 폴더 절대경로. 후보 자동 감지: `ls ~/Library/CloudStorage/`
- `local_root`: 워크스페이스 루트 (기본 = 현재 디렉토리)

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/..}/skills/wy-session-done/scripts/setup.sh \
  --drive-root '<...>' --user-name '<...>' --local-root '<...>'
```

### 2. 활성 과제 감지
**우선**: 사용자 입력에서 폴더경로/과제ID/슬러그 추출 → registry.md 매칭.
**자동**: registry.md 의 활성 행 추출. 0개=종료 / 1개=자동 / 다중=mtime 순으로 사용자 선택. 한글 이름 + 영문 경로 함께 표시.

선택된 폴더를 `$TASK_DIR`.

### 3. 종료 유형
```
[1] 페이즈 종료 — 현재 페이즈 마무리 + 다음 페이즈 신규
[2] 단순 세션 종료 — 현재 페이즈에 진행분만 append
```

### 4. 폴더 구조 점검
없으면 templates 기반 생성: `progress.md`, `phases/01_initial.md`, `handoffs/`. `phases/` 의 가장 큰 번호 = 현재 페이즈.

### 5-A. 페이즈 종료 처리
1. 현재 페이즈 MD 의 `## 페이즈 종료 요약` 채움(결과/한계/다음 컨텍스트), 상단 상태 → `completed`
2. 다음 페이즈 초안 제시(이름·목표·체크리스트 2~3개) → 사용자 확인 → `phases/0(N+1)_<slug>.md` 생성
3. progress.md 갱신: 활성 페이즈 / 페이즈 진행도 / 최종 갱신 / 다음 할 일
4. `handoffs/<YYYY-MMDD-HHMM>.md` 생성 (`{{END_TYPE}}=phase-done`)

### 5-B. 단순 세션 종료
1. 현재 페이즈 `## 세션 로그`에 오늘 항목 append (한 일/이슈/다음)
2. progress.md 갱신 (최종 갱신 / 다음 할 일 / 최근 핸드오프)
3. `handoffs/<YYYY-MMDD-HHMM>.md` 생성 (`{{END_TYPE}}=session-done`)

### 6. registry.md 갱신
해당 행 `최종 갱신`/`상태` 컬럼 업데이트.

### 7. 동기화
```bash
SD=${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/..}/skills/wy-session-done/scripts
FILE_LIST=$(mktemp)  # 변경 MD 절대경로 줄단위 기록
"$SD/secret_scan.sh" "$FILE_LIST"   # exit≠0 → 중단, 정리 후 재시도
"$SD/sync.sh" --dry-run             # 미리보기 후 사용자 확인
"$SD/sync.sh"                       # 실제 동기화
```

결과 리포트: 종료유형 / 과제(한글이름) / 페이즈 / 로컬 갱신 / Drive 업로드·충돌 / Drive 위치.

## 주의
- 폴더/slug 영문만(한글 이름은 registry "이름" 컬럼). macOS NFD/Drive 호환.
- 단방향(로컬→Drive). Drive쪽 mtime 최신이면 `.drive-conflict-<ts>.md` 백업.
- whitelist `*.md` 만 업로드. `out/ bak/ credentials/ .omc/ venv/ __pycache__/ .pytest_cache/` 강제 제외.
- 민감정보 자동 redaction 안 함. secret_scan 차단 시 사용자가 정리.
- 시간은 KST.
