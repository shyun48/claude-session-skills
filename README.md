# claude-session-skills

Claude Code용 세션 시작/종료 보조 스킬 두 개 묶음.

- **session-done** — 세션 종료 시 진행 상황을 페이즈 MD / progress.md / 핸드오프 MD에 정리하고, 로컬에 마운트된 클라우드 동기화 폴더(Google Drive Desktop, Dropbox, iCloud Drive 등)로 **MD 문서만** 미러링.
- **session-resume** — 세션 시작 시 활성 과제의 컨텍스트(progress.md → 현재 페이즈 → 최근 핸드오프)를 자동 회복.

팀 단위로 과제 진행 상황을 공유하면서, **코드/모델/데이터/자격증명은 로컬에 그대로** 두고 싶을 때 유용합니다.

## 동작 개요

```
[ 로컬 워크스페이스 ]                                [ 클라우드 동기화 폴더 ]
<local_root>/                       /session-done   <drive_root>/
├── registry.md                   ─────────────▶    ├── README.md (자동)
├── 01_projects/                                     ├── registry.md
├── 02_analyses/                                     ├── 01_projects/
├── 03_tasks/active/T-.../                           ├── 02_analyses/
│   ├── brief.md, goals.md, progress.md              ├── 03_tasks/...
│   ├── phases/0N_*.md                               └── 04_docs/
│   └── handoffs/<ts>.md
└── 04_docs/

[ 새 세션 ]
/session-resume → progress.md + 현재 페이즈 + 최근 핸드오프 자동 로드 → 컨텍스트 회복
```

화이트리스트는 `*.md` 만. `out/`, `bak/`, `credentials/`, `.omc/`, `venv/`, `.git/`, `__pycache__/`, `node_modules/`, `.pytest_cache/`, `.DS_Store` 강제 제외.

## 사전 요구

- Claude Code (CLI / 데스크톱 / IDE 확장 어느 환경이든 OK)
- macOS · Linux (rsync, bash 4+, python3)
- 로컬에 마운트된 클라우드 동기화 폴더 (Google Drive Desktop, Dropbox, iCloud, OneDrive 등 — 선택 자유)

## 설치

```bash
git clone https://github.com/<your-org-or-user>/claude-session-skills.git
cd claude-session-skills
./install.sh           # ~/.claude/skills/session-done, session-resume 로 복사
# 개발자 모드(리포 변경 즉시 반영) ./install.sh --link
```

이후 Claude Code 에서:

```
/session-done
```

→ 처음 호출되면 셋업 인터뷰가 진행됩니다 (사용자명 + 클라우드 동기화 폴더 경로).

## 워크스페이스 구조 컨벤션

이 스킬들은 다음 구조를 가정합니다 (모두 옵션 — 존재하는 폴더만 동기화):

```
<local_root>/
├── registry.md          ← 활성/완료 과제 보드 (필수)
├── 01_projects/<proj>/  ← 프로젝트별 운영 문서. <proj>/registry.md, <proj>/docs/
├── 02_analyses/active/<F|S>-YYYY-MMDD-NNN_<slug>/
│   ├── 01_ask.md, goals.md, progress.md
│   ├── phases/0N_<slug>.md
│   └── handoffs/<ts>.md
├── 03_tasks/active/T-YYYY-MMDD-NNN_<slug>/
│   ├── brief.md, goals.md, progress.md
│   ├── phases/0N_<slug>.md
│   └── handoffs/<ts>.md
└── 04_docs/             ← 운영팀 공통 문서
```

핵심 규칙: **폴더/경로는 영문 slug 만**. 한글 이름은 `registry.md` 의 "이름" 컬럼에만. (macOS 한글 NFD 이슈 / Drive 동기화 안정성 / 셸 스크립트 호환성)

## /session-done 흐름

1. **활성 과제 자동 감지** (`registry.md` + 폴더 mtime 기반)
2. **종료 유형 선택**:
   - `[1] 페이즈 종료` — 현재 페이즈 MD 마무리 + 다음 페이즈 MD 신규 생성
   - `[2] 단순 세션 종료` — 현재 페이즈 MD에 진행분 append
3. **MD 갱신** (페이즈 MD / progress.md / handoff)
4. **민감정보 스캔** (SSH/TLS 키, GCP/AWS/Slack/GitHub 토큰, JWT, 환경변수 형태 시크릿)
5. **Dry-run 미리보기** → 사용자 승인
6. **rsync 미러링**

민감정보 발견 시 동기화 차단 + 라인 위치 표시. 자동 redaction 하지 않음 (가짜 안전감 방지).

## /session-resume 흐름

1. `registry.md` 에서 활성 과제 식별 (여러 개면 사용자 선택)
2. **표준 3종 파일** 자동 Read:
   - `progress.md` (현재 페이즈 / 다음 할 일)
   - `phases/0N_*.md` (현재 페이즈 내용)
   - `handoffs/<latest>.md` (직전 종료 상태)
3. 컨텍스트 요약 출력
4. 필요 시 `goals.md`, `brief.md` 추가 로드

## 충돌 처리

단방향 동기화 (로컬 → Drive). Drive 쪽에서 직접 편집한 파일이 있다면:

- 로컬 파일과 비교해 Drive 쪽 mtime이 더 최신이면 **`<filename>.drive-conflict-<ts>.md` 로 백업**한 뒤 로컬 버전으로 덮어씀
- 사용자가 백업 파일을 보고 수동 병합

## 민감정보 패턴

`scripts/secret_scan.sh` 가 다음을 탐지합니다 (실제 토큰 길이 기준 — 일반 placeholder 는 통과):

- SSH/TLS 개인키 헤더 (`BEGIN PRIVATE KEY` 등)
- GCP API 키 (`AIza...`), JWT, AWS Access Key (`AKIA...`)
- Slack 토큰 (`xoxb-`, `xoxp-`, `xapp-`)
- GitHub 토큰 (`ghp_`, `gho_`, `github_pat_`)
- OpenAI 키 (`sk-...`)
- 환경변수 형태: `<NAME>_TOKEN=`, `<NAME>_PASS=`, `<NAME>_KEY=`, `<NAME>_SECRET=` (값이 충분히 길고 토큰 형태일 때만)

자세한 패턴은 `session-done/scripts/secret_scan.sh` 참고.

## 동기화 대상 확장

기본 화이트리스트 외 추가 디렉토리/패턴을 섞고 싶으면 환경변수:

```bash
SYNC_INCLUDES=$'05_design/**/*.md\n06_meeting/**/*.md' \
  ~/.claude/skills/session-done/scripts/sync.sh --dry-run
```

## 제거

```bash
./uninstall.sh
```

`~/.claude/skills/session-{done,resume}` 와 `config.json` 만 제거. Drive 미러 폴더는 손대지 않음 (수동 삭제 필요).

## 라이선스

MIT — `LICENSE` 참고.

## 알려진 한계 / 향후

- Drive 충돌 해결은 백업만, 자동 병합 없음
- 자동 셋업 검증(Drive 마운트 상태) 미구현 — 사용자가 경로 직접 확인 필요
- Windows 미지원 (rsync 환경 가정)
- Claude Code 외 환경(Cursor, Copilot CLI 등)에서의 트리거 방식 미검증

피드백/PR 환영합니다.
