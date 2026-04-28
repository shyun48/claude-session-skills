---
name: wy-rto-goal-loop
description: 과제 폴더의 goals.md를 읽고 목표 달성까지 자동 반복. 정체 시 전문가 5인 자문 자동 발동. autopilot/ralph와 조합 가능
user-invocable: true
argument-hint: "<과제 폴더 경로>"
---

# Goal-Driven 고도화 루프

## 실행 방법
```
/wy-rto-goal-loop 03_tasks/active/T-xxx/       # 과제 폴더 지정
/wy-rto-goal-loop                              # 현재 디렉토리에서 goals.md 탐색
autopilot: /wy-rto-goal-loop으로 goals.md TODO 모두 달성해줘
ralph로 /wy-rto-goal-loop 돌려줘
```

## STEP 0: LOCATE
goals.md 탐색 순서:
1. 인자로 전달된 과제 폴더
2. 현재 디렉토리
3. 현재 디렉토리/docs/

goals.md가 없으면 사용자에게 목표 수립을 먼저 요청하고 중단.

과제 폴더의 brief.md에서 **target** (작업 대상 프로젝트 경로)를 확인.
- 예: `target: deploy/` → 코드 수정은 deploy/에서 수행
- target이 없으면 사용자에게 확인

## STEP 1: READ & PRIORITIZE
goals.md에서 TODO/WIP 상태인 항목 추출.
우선순위:
1. baseline 미측정 (현재값 "-") → 최우선
2. 목표 미달 항목
3. WIP 항목

완료할 항목이 없으면 "모든 목표 달성" 출력 후 종료.

## STEP 2: PLAN (Plan Mode)
**EnterPlanMode를 호출하여 계획 모드로 진입한다.** 쓰기 권한 없이 읽기/검색만으로 계획을 수립.

계획 모드에서 수행:
- target 프로젝트의 관련 코드/데이터 탐색 (Read, Grep, Glob만 사용)
- 수정 대상 파일/함수 특정
- 필요한 데이터/리소스 확인
- 실패 시 rollback 방법 설계
- 관련 스킬 선택 (/wy-rto-model-train, /wy-rto-model-evaluate, /wy-rto-sanity-check 등)
- 예상 변경 사항을 plan 문서로 정리

**계획 완성 자가 점검 (3가지 모두 YES여야 통과):**
1. 수정 대상 파일과 함수가 구체적으로 특정되었는가?
2. 변경 전후 예상 동작을 설명할 수 있는가?
3. 실패 시 되돌릴 방법이 있는가?

첫 루프: 계획을 사용자에게 보여주고 승인 후 진행.
이후 루프: 3가지 점검 통과 시 자동으로 실행 단계로 전환.

## STEP 3: EXECUTE (자동 전환)
**ExitPlanMode를 호출하여 실행 모드로 전환한다.** 쓰기 권한 개방.

승인된 계획에 따라 target 프로젝트에서 실행:
- 해당 프로젝트의 CLAUDE.md, .claude/rules/ 규칙 준수
- 한 루프에 한 항목만. 동시에 여러 지표 건드리지 마라
- 계획에 없는 파일은 건드리지 마라

## STEP 4: MEASURE
실행 결과를 정량적으로 측정:
- goals.md의 해당 지표에 현재값 기입
- 달성: 상태를 "달성"으로 변경
- 미달: 원인 1줄 기록 후 다음 루프

## STEP 4.5: EXPERT CONSULT (2회 연속 정체 시 자동 발동)

2회 연속 같은 항목에서 개선 없으면 전문가 5인을 서브에이전트로 병렬 소환.

**전문가 팀 (전원 20년+ 경력/교수급):**

| # | 전문가 | 자문 영역 |
|---|-------|--------|
| 1 | 통계학자 | 분포 가정, 검정 설계, 캘리브레이션, 시계열 정상성 |
| 2 | 수학자 | 수치 안정성, 최적화 수렴, 확률 모델링, 수식 검증 |
| 3 | 데이터 사이언티스트 | 피처 엔지니어링, 모델 선택, 앙상블, 하이퍼파라미터 |
| 4 | 개발자 | 성능 병목, 메모리, 병렬화, 코드 구조 |
| 5 | 운영 리더 | 운영 현장 관점, KPI 우선순위, 실무 적합성 |

**호출 프로토콜:**
```
각 에이전트에게 전달:
  - 정체된 지표명과 현재값/목표값
  - 지금까지 시도한 접근법과 결과 요약
  - 관련 코드/데이터 구조 요약 (target 프로젝트 기준)

각 전문가는 독립적으로 분석 → 구체적 다음 시도 1~2개 제안
5명의 제안을 종합 → 가장 유망한 접근법 1개 선택
선택 근거를 과제 폴더의 progress.md에 기록
선택된 접근법으로 STEP 2(PLAN)부터 재개
```

## STEP 5: UPDATE
- goals.md 갱신 (측정값, 상태)
- 과제 폴더 내 progress.md에 이력 추가 (없으면 생성)
- 다음 루프 → STEP 1 복귀

## 종료 조건
- 모든 TODO/WIP → 달성
- 전문가 자문 후에도 2회 추가 정체 (총 4회) → 사용자 보고 후 중단
- 사용자가 중단 요청

## 안전장치
- 매 루프 시작 시 goals.md 재읽기 (목표 변경 반영)
- 루프 진행 상황을 progress.md에 기록 (세션 끊어져도 이어갈 수 있도록)
- target 프로젝트의 .claude/rules/ 자동 적용
