#!/usr/bin/env bash
# 로컬 → Drive(또는 임의 클라우드 동기화 폴더) MD 미러링.
# whitelist: *.md 만. 기본 동기화 대상 디렉토리는 아래 INCLUDE 패턴 참고.
#
# 사용법: sync.sh [--dry-run]

set -euo pipefail

CONFIG_PATH="$HOME/.claude/skills/wy-session-done/config.json"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "ERROR: config.json 없음. setup.sh 를 먼저 실행하세요." >&2
  exit 1
fi

PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
LOCAL_ROOT=$("$PYTHON_BIN" -c "import json,sys;print(json.load(open('$CONFIG_PATH'))['local_root'])")
DRIVE_ROOT=$("$PYTHON_BIN" -c "import json,sys;print(json.load(open('$CONFIG_PATH'))['drive_root'])")

if [[ ! -d "$LOCAL_ROOT" ]]; then
  echo "ERROR: 로컬 루트 없음: $LOCAL_ROOT" >&2
  exit 1
fi
if [[ ! -d "$DRIVE_ROOT" ]]; then
  echo "ERROR: Drive 루트 없음: $DRIVE_ROOT" >&2
  exit 1
fi

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="--dry-run"
fi

cd "$LOCAL_ROOT"

# 충돌 백업: Drive 쪽 mtime이 더 최신인 MD가 있으면 .drive-conflict-<ts>.md 로 백업
TS=$(date '+%Y%m%d-%H%M%S')
CONFLICT_LOG=$(mktemp)

while IFS= read -r drive_file; do
  rel="${drive_file#$DRIVE_ROOT/}"
  local_file="$LOCAL_ROOT/$rel"
  [[ ! -f "$local_file" ]] && continue
  if [[ "$drive_file" -nt "$local_file" ]]; then
    backup="${drive_file%.md}.drive-conflict-${TS}.md"
    if [[ -z "$DRY_RUN" ]]; then
      cp -p "$drive_file" "$backup"
    fi
    echo "$rel" >> "$CONFLICT_LOG"
  fi
done < <(find "$DRIVE_ROOT" -type f -name "*.md" ! -name "*.drive-conflict-*.md" 2>/dev/null)

CONFLICT_COUNT=$(wc -l < "$CONFLICT_LOG" | tr -d ' ')

# rsync 본 동작
# 화이트리스트:
#   - 루트 registry.md
#   - 01_projects/**/*.md, 02_analyses/**/*.md, 03_tasks/**/*.md, 04_docs/**/*.md
# 추가/수정이 필요하면 SYNC_INCLUDES 환경변수에 rsync --include 패턴을 줄단위로 넣어 확장 가능.
RSYNC_LOG=$(mktemp)

INCLUDE_ARGS=()
if [[ -n "${SYNC_INCLUDES:-}" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    INCLUDE_ARGS+=(--include="$line")
  done <<< "$SYNC_INCLUDES"
fi

rsync -av $DRY_RUN --prune-empty-dirs \
  --exclude='venv/' \
  --exclude='.venv/' \
  --exclude='.git/' \
  --exclude='.omc/' \
  --exclude='__pycache__/' \
  --exclude='node_modules/' \
  --exclude='out/' \
  --exclude='bak/' \
  --exclude='credentials/' \
  --exclude='.pytest_cache/' \
  --exclude='.cache/' \
  --exclude='.DS_Store' \
  --exclude='CLAUDE.md' \
  --exclude='*.drive-conflict-*.md' \
  ${INCLUDE_ARGS[@]+"${INCLUDE_ARGS[@]}"} \
  --include='*/' \
  --include='registry.md' \
  --include='01_projects/**/*.md' \
  --include='02_analyses/**/*.md' \
  --include='03_tasks/**/*.md' \
  --include='04_docs/**/*.md' \
  --exclude='*' \
  "$LOCAL_ROOT/" "$DRIVE_ROOT/" 2>&1 | tee "$RSYNC_LOG" | grep -E '\.md$|^sent|^total' || true

UPLOADED=$(grep -E '\.md$' "$RSYNC_LOG" | grep -v '^d' | wc -l | tr -d ' ')

echo ""
echo "[sync] 결과"
echo "  업로드:      $UPLOADED 파일"
echo "  충돌 백업:   $CONFLICT_COUNT 파일"
if [[ $CONFLICT_COUNT -gt 0 ]]; then
  echo "  충돌 목록:"
  sed 's/^/    - /' "$CONFLICT_LOG"
fi
echo "  Drive 위치:  $DRIVE_ROOT"
[[ -n "$DRY_RUN" ]] && echo "  ※ DRY-RUN (실제 업로드 안 함)"

rm -f "$CONFLICT_LOG" "$RSYNC_LOG"
