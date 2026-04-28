# {{USER_NAME}} — Claude 워크스페이스 미러

이 폴더는 `{{USER_NAME}}` 의 Claude 로컬 작업 공간에서 자동으로 동기화되는 **MD 문서 미러**입니다.

## 무엇이 올라오나
- 과제 정의 (`brief.md`, `01_ask.md`)
- 페이즈별 진행 (`phases/0N_*.md`)
- 진행 상태 (`progress.md`)
- 핸드오프 (`handoffs/<ts>.md`)
- 운영팀 공통 문서 (`04_docs/`)
- 과제 보드 (`registry.md`)

## 무엇은 올라오지 않나
- 코드, 데이터, 모델
- 자격증명 / 환경변수
- 실행 결과물

## 동기화 시점
- 로컬에서 `/session-done` 실행 시 (페이즈 종료 또는 단순 세션 종료)
- 단방향 (로컬 → Drive)

생성일: {{CREATED_AT}}
