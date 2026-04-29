---
name: wy-goal-loop
description: 과제 폴더의 goals.md를 읽고 목표 달성까지 자동 반복. 정체 시 전문가 5인 자문 자동 발동. autopilot/ralph와 조합 가능
user-invocable: true
argument-hint: "<과제 폴더 경로>"
---

# wy-goal-loop — Goal-Driven 고도화 루프

## 실행
```
/wy-goal-loop 03_tasks/active/T-xxx/    # 과제 폴더
/wy-goal-loop                            # 현재 dir에서 goals.md 탐색
autopilot: /wy-goal-loop으로 goals.md TODO 모두 달성해줘
```

## STEP 0: LOCATE
goals.md 탐색: 인자 폴더 → 현재 dir → `./docs/`. 없으면 사용자에 목표 수립 요청 후 중단.
brief.md 의 `target:` (작업 대상 프로젝트 경로)를 확인. 없으면 사용자 확인.

## STEP 1: READ & PRIORITIZE
goals.md 의 TODO/WIP 항목 추출. 우선순위:
1. baseline 미측정(현재값 "-") → 최우선
2. 목표 미달
3. WIP

완료할 항목 없으면 "모든 목표 달성" 출력 후 종료.

## STEP 2: PLAN (Plan Mode)
`EnterPlanMode` 호출 → 읽기/검색만으로 계획 수립:
- target 프로젝트 코드/데이터 탐색(Read/Grep/Glob)
- 수정 대상 파일·함수 특정 / 필요 리소스 / rollback / 관련 스킬 선택(`/wy-model-train`, `/wy-model-evaluate`, `/wy-sanity-check` 등)

**자가 점검 (3가지 YES 통과):**
1. 수정 대상 파일·함수 구체화?
2. 변경 전후 예상 동작 설명 가능?
3. 실패 시 되돌릴 방법?

첫 루프 = 사용자 승인. 이후 = 3점검 통과 시 자동 진행.

## STEP 3: EXECUTE
`ExitPlanMode` 호출 → 쓰기 권한 개방. 계획대로 target에서 실행.
- target의 CLAUDE.md / .claude/rules/ 준수
- 한 루프 = 한 항목, 계획 외 파일 금지

## STEP 4: MEASURE
goals.md 의 해당 지표 현재값 기입. 달성=상태 변경. 미달=원인 1줄 후 다음 루프.

## STEP 4.5: EXPERT CONSULT (2회 연속 정체 시 자동)
서브에이전트로 전문가 5인 병렬 소환:

| # | 전문가 | 영역 |
|---|--------|------|
| 1 | 통계학자 | 분포·검정·캘리브레이션·시계열 정상성 |
| 2 | 수학자 | 수치 안정성·최적화·확률 모델링·수식 검증 |
| 3 | 데이터 사이언티스트 | 피처/모델 선택/앙상블/하이퍼파라미터 |
| 4 | 개발자 | 성능 병목·메모리·병렬화·코드 구조 |
| 5 | 운영 리더 | 운영 현장·KPI 우선순위·실무 적합성 |

각 전문가에게 전달: 정체 지표·현재/목표값, 시도한 접근법 요약, 관련 코드/데이터 구조.
독립 분석 → 각 1~2개 제안. 5명 제안 종합 → 가장 유망한 1개 선택. 근거를 progress.md 에 기록 → STEP 2 재개.

## STEP 5: UPDATE
goals.md 갱신(값/상태) + progress.md 이력 append → STEP 1 복귀.

## 종료 조건
- 모든 TODO/WIP 달성
- 전문가 자문 후 2회 추가 정체(총 4회) → 사용자 보고 후 중단
- 사용자 중단 요청

## 안전장치
- 매 루프 시작 시 goals.md 재읽기(목표 변경 반영)
- 진행상황 progress.md 기록(세션 끊겨도 재개 가능)
- target 프로젝트 .claude/rules/ 자동 적용
