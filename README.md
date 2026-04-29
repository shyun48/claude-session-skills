# wy-task-mgmt

운영효율화파트 공용 Claude Code 플러그인 — 과제 관리 자동화 + 세션 재개/종료 + 분석/모델 고도화 하네스.

## 수록 스킬

| 스킬 | 용도 |
|------|------|
| `/wy-new-task` | 신규 과제 폴더 + Jira 티켓 동시 생성 (4모드: 신규/역방향/정방향/매핑복구) |
| `/wy-session-resume` | 새 세션 시작 시 활성 과제 컨텍스트 자동 회복 |
| `/wy-session-done` | 세션 종료 시 진행 기록 + 클라우드 폴더 미러링 |
| `/wy-goal-loop` | 과제 폴더의 goals.md 를 목표 도달까지 자동 반복 |
| `/wy-model-train` | 예측 모델 재학습 워크플로우 |
| `/wy-model-evaluate` | 모델 성능 평가 및 비교 |
| `/wy-sanity-check` | 코드 변경 후 5분 무결성 검증 |

## 설치

Claude Code 안에서:

```
/plugin marketplace add shyun48/wy-task-mgmt
/plugin install wy-task-mgmt@wy-task-mgmt
```

**Public 레포 — 사전 인증 불필요.**

## 첫 셋업

`/wy-session-done` 1회 호출 → 인터뷰로 `user_name` / `drive_root` / `local_root` 입력 → `~/.claude/skills/wy-session-done/config.json` 자동 생성 (플러그인 업데이트 무관하게 유지).

다른 스킬은 별도 셋업 불필요.

## 사용

```
# 세션 재개 / 종료
/wy-session-resume                       # 또는 "이어서 하자"
/wy-session-done                         # 또는 "오늘 작업 마무리"

# 분석/모델 하네스
/wy-goal-loop 03_tasks/active/T-...-slug/
/wy-model-train
/wy-model-evaluate
/wy-sanity-check
```

## 업데이트 / 제거

```
/plugin marketplace update wy-task-mgmt
/plugin uninstall wy-task-mgmt@wy-task-mgmt
```

## 폴더 컨벤션 (세션 스킬이 가정)

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

## 이전 버전에서 마이그레이션

> 레포 이름이 `claude-session-skills` → `wy-task-mgmt` 로 변경됨. GitHub redirect 덕에 옛 URL 도 동작은 하지만, 마켓플레이스를 새로 등록해야 명령이 깔끔해집니다.

### v0.5.0 (`wy-task-mgmt` 플러그인 + 옛 마켓플레이스 이름) 에서

```
/plugin uninstall wy-task-mgmt@claude-session-skills
/plugin marketplace remove claude-session-skills
/plugin marketplace add shyun48/wy-task-mgmt
/plugin install wy-task-mgmt@wy-task-mgmt
```

### v0.4.0 (`wy-rto` 플러그인) 에서

```
/plugin uninstall wy-rto@claude-session-skills
/plugin marketplace remove claude-session-skills
/plugin marketplace add shyun48/wy-task-mgmt
/plugin install wy-task-mgmt@wy-task-mgmt
mv ~/.claude/skills/wy-rto-session-done ~/.claude/skills/wy-session-done
```

### v0.3.0 이하 (두 플러그인) 에서

```
/plugin uninstall session-skills@claude-session-skills
/plugin uninstall wy-rto-harness@claude-session-skills
/plugin marketplace remove claude-session-skills
/plugin marketplace add shyun48/wy-task-mgmt
/plugin install wy-task-mgmt@wy-task-mgmt
mv ~/.claude/skills/session-done ~/.claude/skills/wy-session-done
```

## 문의

suhyun.kim@woowayouths.com
