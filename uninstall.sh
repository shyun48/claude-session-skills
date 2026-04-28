#!/usr/bin/env bash
# claude-session-skills 제거.
# ~/.claude/skills/session-{done,resume} 만 삭제. 다른 ~/.claude/ 항목은 건드리지 않음.
# config.json (셋업 결과)도 함께 삭제됨.

set -euo pipefail

CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

for name in session-done session-resume; do
  target="$CLAUDE_SKILLS_DIR/$name"
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf "$target"
    echo "[uninstall] removed: $target"
  else
    echo "[uninstall] skip (없음): $target"
  fi
done

echo "제거 완료. Drive 미러 폴더는 그대로 유지됩니다 (수동 삭제 필요)."
