# claude-session-skills

운영효율화파트 공용 Claude Code 플러그인 — 세션 재개/종료 + 분석/모델 고도화 하네스.

## 수록 스킬

| 스킬 | 용도 |
|------|------|
| `/wy-rto-session-resume` | 새 세션 시작 시 활성 과제 컨텍스트 자동 회복 |
| `/wy-rto-session-done` | 세션 종료 시 진행 기록 + 클라우드 폴더 미러링 |
| `/wy-rto-goal-loop` | 과제 폴더의 goals.md 를 목표 도달까지 자동 반복 |
| `/wy-rto-model-train` | 예측 모델 재학습 워크플로우 |
| `/wy-rto-model-evaluate` | 모델 성능 평가 및 비교 |
| `/wy-rto-sanity-check` | 코드 변경 후 5분 무결성 검증 |

## 설치 (Claude Code 안에서)

```
/plugin marketplace add shyun48/claude-session-skills
/plugin install wy-rto@claude-session-skills
```

**Public 레포 — 사전 인증 불필요.**

## 첫 셋업

`/wy-rto-session-done` 1회 호출 → 인터뷰로 `user_name` / `drive_root` / `local_root` 입력 → `~/.claude/skills/wy-rto-session-done/config.json` 자동 생성 (플러그인 업데이트 무관하게 유지).

다른 스킬은 별도 셋업 불필요.

## 사용

```
# 세션 재개 / 종료
/wy-rto-session-resume                       # 또는 "이어서 하자"
/wy-rto-session-done                         # 또는 "오늘 작업 마무리"

# 분석/모델 하네스
/wy-rto-goal-loop 03_tasks/active/T-...-slug/
/wy-rto-model-train
/wy-rto-model-evaluate
/wy-rto-sanity-check
```

## 업데이트 / 제거

```
/plugin marketplace update claude-session-skills
/plugin uninstall wy-rto@claude-session-skills
```

## 폴더 컨벤션 (세션 스킬이 가정하는 구조)

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

## v0.3.0 이하에서 마이그레이션

```
/plugin uninstall session-skills@claude-session-skills
/plugin uninstall wy-rto-harness@claude-session-skills
/plugin marketplace update claude-session-skills
/plugin install wy-rto@claude-session-skills
```

config.json 은 위치 동일(`~/.claude/skills/wy-rto-session-done/config.json`)이라 추가 작업 없음.

## 문의

suhyun.kim@woowayouths.com
