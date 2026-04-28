# claude-session-skills

Claude Code 세션 재개/종료 스킬 모음 (Claude Code 플러그인).

## 무엇을 하는가

| 스킬 | 트리거 | 역할 |
|------|--------|------|
| **session-resume** | `/session-resume`, "이어서 하자", "어디까지 했지" | 활성 과제의 `progress.md` → 페이즈 MD → 최근 핸드오프 순서로 읽고 컨텍스트 요약 출력 |
| **session-done** | `/session-done` | 진행 상황을 `progress.md`/`handoffs/` 자동 갱신 + 클라우드 폴더(Drive/Dropbox/iCloud)로 MD만 미러링 |

## 설치

### 1. 사전: GitHub private 레포 인증 (1회)

```bash
gh auth login
# 또는 SSH/PAT 사용 — 자동 업데이트까지 받으려면 GITHUB_TOKEN 환경변수 권장
```

> 권한이 없으면 collaborator 추가 요청: **suhyun.kim@woowayouths.com**

### 2. Claude Code 안에서 슬래시 명령

```
/plugin marketplace add shyun48/claude-session-skills
/plugin install session-skills@claude-session-skills
```

### 3. 첫 실행 셋업

`/session-done` 을 한 번 호출하면 셋업 인터뷰가 자동 실행됩니다:
- `user_name` (Drive 표시 이름)
- `drive_root` (클라우드 동기화 폴더 절대경로)
- `local_root` (로컬 작업 루트, 기본값 = 현재 디렉토리)

→ 결과가 `~/.claude/skills/session-done/config.json` 에 저장됩니다 (플러그인 업데이트 시에도 유지).

## 사용

```
/session-resume                                 # 가장 최근 과제 자동 감지
/session-resume T-2026-0428-001                 # ID 지정
/session-resume 03_tasks/active/T-...-slug/     # 경로 지정

/session-done                                   # 세션 종료 — progress 갱신 + Drive 미러링
```

## 의존하는 폴더 구조

```
<local_root>/
├── registry.md
├── 02_analyses/active/<F|S>-...-NNN_slug/
└── 03_tasks/active/T-...-NNN_slug/
    ├── brief.md (또는 01_ask.md)
    ├── goals.md
    ├── progress.md
    ├── phases/0N_*.md
    └── handoffs/YYYY-MMDD-HHMM.md
```

## 업데이트 / 제거

```
/plugin marketplace update claude-session-skills
/plugin uninstall session-skills@claude-session-skills
```

`config.json` 은 사용자 영역(`~/.claude/skills/session-done/`)에 있어 플러그인 업데이트와 무관하게 유지됩니다.

## 보안

- 레포는 private. `config.json` (개인 절대경로 + 이메일) 은 `.gitignore` 처리되어 푸시되지 않음
- 미러링 대상은 **MD 문서뿐**. 코드/데이터/자격증명 미동기화

## 문의

suhyun.kim@woowayouths.com
