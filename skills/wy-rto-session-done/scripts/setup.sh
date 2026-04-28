#!/usr/bin/env bash
# session-done setup — 최초 1회 실행. config.json 생성 + 미러 폴더 준비.
#
# 사용법:
#   setup.sh --drive-root <PATH> --user-name <NAME> [--local-root <PATH>]
#
# 인자:
#   --drive-root  : 클라우드 동기화 폴더의 절대경로. 보통 macOS Google Drive Desktop이
#                   마운트한 ~/Library/CloudStorage/GoogleDrive-<email>/공유\ 드라이브/.../
#                   하위의 본인 미러 폴더. 없으면 자동 생성됨.
#   --user-name   : Drive에서 본인 폴더로 표시될 이름 (자유 형식, README에 사용).
#   --local-root  : 동기화 소스가 되는 로컬 작업 루트. 기본값: 현재 디렉토리(CWD).
#
# 예시:
#   setup.sh \
#     --drive-root '/Users/me/Library/CloudStorage/GoogleDrive-x@y.com/공유 드라이브/MyTeam/2. 과제/me' \
#     --user-name 'me' \
#     --local-root "$HOME/Documents/work"

set -euo pipefail

DRIVE_ROOT=""
USER_NAME=""
LOCAL_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --drive-root) DRIVE_ROOT="$2"; shift 2 ;;
    --user-name)  USER_NAME="$2"; shift 2 ;;
    --local-root) LOCAL_ROOT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *)
      echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$DRIVE_ROOT" || -z "$USER_NAME" ]]; then
  echo "ERROR: --drive-root 와 --user-name 은 필수입니다." >&2
  echo "사용법: setup.sh --drive-root <PATH> --user-name <NAME> [--local-root <PATH>]" >&2
  exit 2
fi

if [[ -z "$LOCAL_ROOT" ]]; then
  LOCAL_ROOT="$(pwd)"
fi

if [[ ! -d "$LOCAL_ROOT" ]]; then
  echo "ERROR: 로컬 루트가 존재하지 않음: $LOCAL_ROOT" >&2
  exit 1
fi

# DRIVE_ROOT의 부모 디렉토리는 반드시 존재해야 함 (사용자가 클라우드 동기화 폴더를 알려줘야 의미가 있음).
DRIVE_PARENT="$(dirname "$DRIVE_ROOT")"
if [[ ! -d "$DRIVE_PARENT" ]]; then
  echo "ERROR: Drive 부모 폴더가 존재하지 않음: $DRIVE_PARENT" >&2
  echo "  - macOS Google Drive Desktop이 동기화되어 있는지 확인" >&2
  echo "  - 또는 부모 폴더를 직접 생성한 뒤 다시 시도" >&2
  exit 1
fi

mkdir -p "$DRIVE_ROOT"

CONFIG_DIR="$HOME/.claude/skills/wy-rto-session-done"
CONFIG_PATH="$CONFIG_DIR/config.json"
mkdir -p "$CONFIG_DIR"

README_PATH="$DRIVE_ROOT/README.md"
if [[ ! -f "$README_PATH" ]]; then
  cat > "$README_PATH" <<EOF
# $USER_NAME — Claude 워크스페이스 미러

이 폴더는 \`$USER_NAME\` 의 Claude 로컬 작업 공간에서 자동으로 동기화되는 **MD 문서 미러**입니다.

## 무엇이 올라오나
- 과제 정의 (\`brief.md\`, \`01_ask.md\`)
- 페이즈별 진행 (\`phases/0N_*.md\`)
- 진행 상태 (\`progress.md\`)
- 핸드오프 (\`handoffs/<ts>.md\`)
- 운영 공통 문서 (\`04_docs/\`)
- 과제 보드 (\`registry.md\`)

## 무엇은 올라오지 않나
- 코드 (\`*.py\`, \`*.sh\`)
- 데이터/모델 (\`*.json\`, \`*.txt\`, \`*.parquet\` 등)
- 자격증명 / 환경변수
- 실행 결과물 (\`out/\`)

## 동기화 시점
- 로컬에서 \`/wy-rto-session-done\` 실행 시
- 단방향 (로컬 → Drive)

생성일: $(date '+%Y-%m-%d %H:%M:%S %Z')
EOF
fi

cat > "$CONFIG_PATH" <<EOF
{
  "user_name": "$USER_NAME",
  "drive_root": "$DRIVE_ROOT",
  "local_root": "$LOCAL_ROOT",
  "configured_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF

echo "[setup] 완료"
echo "  사용자:    $USER_NAME"
echo "  로컬 루트:  $LOCAL_ROOT"
echo "  Drive 루트: $DRIVE_ROOT"
echo "  config:    $CONFIG_PATH"
