#!/usr/bin/env bash
# claude-session-skills 설치 스크립트.
# 이 리포의 session-done / session-resume 폴더를 ~/.claude/skills/ 로 복사 (또는 symlink).
#
# 사용법:
#   ./install.sh           # 기본: 복사
#   ./install.sh --link    # symlink 모드 (개발자용 — 리포 변경이 즉시 반영됨)
#   ./install.sh --force   # 기존 ~/.claude/skills/session-{done,resume} 덮어쓰기

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

MODE="copy"
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --link)  MODE="link"; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help)
      sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$CLAUDE_SKILLS_DIR"

install_one() {
  local name="$1"
  local src="$REPO_DIR/$name"
  local dst="$CLAUDE_SKILLS_DIR/$name"

  if [[ ! -d "$src" ]]; then
    echo "ERROR: 소스 폴더 없음: $src" >&2; exit 1
  fi

  if [[ -e "$dst" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      rm -rf "$dst"
    else
      echo "이미 존재: $dst (덮어쓰려면 --force)"
      return
    fi
  fi

  if [[ "$MODE" == "link" ]]; then
    ln -s "$src" "$dst"
    echo "[install] symlink: $dst -> $src"
  else
    cp -R "$src" "$dst"
    echo "[install] copy:    $dst"
  fi

  chmod +x "$dst"/scripts/*.sh 2>/dev/null || true
}

install_one "session-done"
install_one "session-resume"

echo ""
echo "설치 완료. 다음 단계:"
echo "  1. Claude Code 에서 /session-done 호출 → 셋업 인터뷰 진행"
echo "  2. /session-resume 으로 다음 세션부터 컨텍스트 자동 회복"
