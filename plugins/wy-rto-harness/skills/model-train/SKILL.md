---
name: model-train
description: 예측 모델 재학습 워크플로우. 모델 유형에 구애받지 않고 최적 접근법을 탐색. 피처 확인 → 데이터 준비 → 모델 선택 → 학습 → 검증
user-invocable: true
---

# 모델 재학습 워크플로우

## 1. PRE-CHECK
- 현재 모델 구조와 피처 목록 확인
- 기존 모델 파일 백업 (bak/ 디렉토리)
- 학습 환경 확인: venv 활성화, 패키지 버전
- baseline 성능 기록 (비교 기준)

## 2. DATA
- 데이터 추출 및 탐색적 분석 (분포, 이상치, 결측)
- 피처 엔지니어링: 기존 피처 검증 + 새로운 피처 후보 탐색
- train/valid/test 분할: 시계열이면 시간순, 아니면 stratified
- 데이터 품질 이슈 발견 시 사용자에게 보고

## 3. MODEL SELECTION
현재 모델에 고정하지 마라. 과제 목표에 맞는 최적 접근법을 탐색:
- **트리 기반**: LightGBM, XGBoost, CatBoost
- **선형/통계**: 분위수 회귀, LASSO, Ridge, ARIMA
- **확률 모델**: FPT, 베이지안, Gaussian Process
- **딥러닝**: LSTM, Transformer (데이터 충분 시)
- **앙상블**: 단일 모델 한계 시 조합 시도

모델 선택 근거를 progress.md에 기록.
"왜 이 모델인가"를 설명할 수 없으면 선택하지 마라.

## 4. TRAIN
- 하이퍼파라미터 탐색: 소규모 grid/random search 먼저
- 학습 로그 모니터링: overfitting 징후 시 조기 중단
- 분위수 예측 필요 시: 모델별 지원 방식 확인
- 메모리/시간 제약 준수: Pool(4) 피처, Pool(6) 학습

## 5. VALIDATE
- 예측값 sanity: NaN, Inf, 비현실적 값 없는지
- baseline 대비 성능 비교 (같은 메트릭 기준)
- 분위수 모델: crossing 검증 (q10 <= q50 <= q90)
- 시나리오별 테스트: 극단 케이스에서 성능 확인
- 새 모델이 기존보다 악화된 시나리오가 있으면 trade-off 명시

## 6. SAVE
- 검증 통과 시 모델 파일 저장
- 피처 목록/모델 설정 변경 시 함께 업데이트
- goals.md 지표 갱신, progress.md에 결과 기록
- 모델 선택 근거 + 성능 비교표를 progress.md에 남겨라
