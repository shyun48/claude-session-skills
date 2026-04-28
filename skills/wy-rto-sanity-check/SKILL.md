---
name: wy-rto-sanity-check
description: 코드 변경 후 빠른 무결성 검증. import 테스트, 예측값 범위, 피처 정합성을 5분 이내 확인
user-invocable: true
---

# Sanity Check

코드 수정 후 반드시 실행. 5분 이내 완료.

## 1. IMPORT TEST
변경된 모듈의 import가 성공하는지 확인:
```bash
python -c "from {module} import {class}; print('OK')"
```

## 2. FEATURE INTEGRITY
피처 목록 파일과 모델 코드의 피처 수/이름 일치 확인

## 3. PREDICTION RANGE
더미 입력으로 예측 → 출력값 범위 확인:
- NaN/Inf 없음
- 확률: 0~1 범위
- 분위수 순서 정상

## 4. RESULT
- 통과: "Sanity check PASSED"
- 실패: 구체적 오류와 수정 방향 제시
