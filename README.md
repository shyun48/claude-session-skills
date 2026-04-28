# claude-session-skills

Claude Code 플러그인 마켓플레이스 — 운영효율화파트 공용 스킬 모음.

## 수록 플러그인

| 플러그인 | 스킬 | 용도 |
|---------|------|------|
| **session-skills** | `session-resume`, `session-done` | 세션 재개/종료 자동화. 진행상태(`progress.md`/`handoffs/`) 자동 갱신 + 클라우드 폴더 미러링 |
| **wy-rto-harness** | `goal-loop`, `model-train`, `model-evaluate`, `sanity-check` | 분석·모델 고도화 하네스. 목표 달성 반복, 전문가 5인 자문, 모델 재학습/평가/검증 워크플로우 |

## 설치 (Claude Code 안에서)

```
/plugin marketplace add shyun48/claude-session-skills
```

이후 원하는 플러그인을 골라 설치:

```
/plugin install session-skills@claude-session-skills
/plugin install wy-rto-harness@claude-session-skills
```

둘 다 설치하려면 위 두 줄을 모두 실행. **Public 레포라 사전 인증 불필요.**

## 첫 셋업

### session-skills
`/session-done` 1회 호출 → 인터뷰로 `user_name` / `drive_root` / `local_root` 입력 → `~/.claude/skills/session-done/config.json` 자동 생성 (플러그인 업데이트 무관하게 유지).

### wy-rto-harness
별도 셋업 불필요. 과제 폴더에 `goals.md` 가 있으면 `/goal-loop <task-folder>` 로 즉시 실행. `goals-template.md` 는 새 과제 시작 시 참조.

## 사용

```
# 세션 재개
/session-resume                       # 또는 "이어서 하자"

# 세션 종료
/session-done                         # 또는 "오늘 작업 마무리"

# 분석/모델 하네스
/goal-loop 03_tasks/active/T-...-slug/
```

## 업데이트 / 제거

```
/plugin marketplace update claude-session-skills
/plugin uninstall session-skills@claude-session-skills
/plugin uninstall wy-rto-harness@claude-session-skills
```

## 폴더 컨벤션 (session-skills 가정)

```
<local_root>/
├── registry.md
├── 02_analyses/active/<F|S>-...-NNN_slug/
└── 03_tasks/active/T-...-NNN_slug/
    ├── brief.md / 01_ask.md
    ├── goals.md
    ├── progress.md
    ├── phases/0N_*.md
    └── handoffs/YYYY-MMDD-HHMM.md
```

## 문의

suhyun.kim@woowayouths.com
