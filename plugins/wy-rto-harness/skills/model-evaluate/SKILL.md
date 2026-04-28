---
name: model-evaluate
description: 예측 모델 성능 평가 및 비교. MAE/RMSE, 분위수 캘리브레이션, 시나리오별 성능을 측정하여 goals.md 지표 갱신
user-invocable: true
---

# 모델 평가 워크플로우

## 1. LOAD
- 평가 대상 모델 로드
- 평가용 데이터 준비 (학습 미사용 기간)

## 2. METRICS
- MAE, RMSE, MAPE (타겟별)
- Coverage Rate: q10-q90 구간 포함 비율 (목표 80%)
- 캘리브레이션: 각 분위수 아래 실제값 비율 검증

## 3. SCENARIO
| 구분 | 조건 |
|------|------|
| 시간대 | 새벽/오전/점심/오후/저녁/심야 |
| 요일 | 평일 vs 주말 |
| 기상 | 맑음 vs 우천 (max_dbz > 35) |
| 수급 | 정상 vs 부족 (supply_ratio < 0.8) |

## 4. REPORT
마크다운 테이블로 정리 → goals.md에 현재값 반영

## 5. DECISION
- 기존 대비 개선/악화 판단
- 악화 시나리오 원인 분석
- 배포 여부는 사용자가 결정
