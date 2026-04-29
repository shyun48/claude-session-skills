#!/usr/bin/env python3
"""
로컬 → Drive(또는 임의 클라우드 마운트 폴더) MD 미러링.

화이트리스트:
  - 루트 registry.md
  - 01_projects/**/*.md
  - 02_analyses/**/*.md
  - 03_tasks/**/*.md
  - 04_docs/**/*.md

제외: venv/ .venv/ .git/ .omc/ __pycache__/ node_modules/ out/ bak/ credentials/
      .pytest_cache/ .cache/ .DS_Store CLAUDE.md *.drive-conflict-*.md

사용법: sync.py [--dry-run]

cross-platform — rsync 비의존. 기존 sync.sh 의 Python 포팅.
"""

from __future__ import annotations

import argparse
import filecmp
import json
import shutil
import sys
import re
from datetime import datetime
from pathlib import Path

CONFIG_PATH = Path.home() / ".claude" / "skills" / "wy-session-done" / "config.json"

EXCLUDE_DIR_NAMES = {
    "venv", ".venv", ".git", ".omc", "__pycache__", "node_modules",
    "out", "bak", "credentials", ".pytest_cache", ".cache",
}
EXCLUDE_FILE_NAMES = {".DS_Store", "CLAUDE.md"}
CONFLICT_RE = re.compile(r"\.drive-conflict-\d{8}-\d{6}\.md$")

INCLUDE_TOP_DIRS = ("01_projects", "02_analyses", "03_tasks", "04_docs")
ROOT_FILES = ("registry.md",)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args()


def load_config() -> dict:
    if not CONFIG_PATH.is_file():
        print(f"ERROR: config.json 없음 ({CONFIG_PATH}). setup.py 먼저 실행.", file=sys.stderr)
        sys.exit(1)
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def is_excluded_dir(path: Path) -> bool:
    return any(part in EXCLUDE_DIR_NAMES for part in path.parts)


def iter_local_md(local_root: Path):
    """화이트리스트 적용된 .md 파일 절대경로 yield."""
    for fname in ROOT_FILES:
        p = local_root / fname
        if p.is_file():
            yield p
    for top in INCLUDE_TOP_DIRS:
        top_dir = local_root / top
        if not top_dir.is_dir():
            continue
        for p in top_dir.rglob("*.md"):
            if not p.is_file():
                continue
            rel = p.relative_to(local_root)
            if is_excluded_dir(rel):
                continue
            if p.name in EXCLUDE_FILE_NAMES:
                continue
            if CONFLICT_RE.search(p.name):
                continue
            yield p


def iter_drive_md(drive_root: Path):
    for p in drive_root.rglob("*.md"):
        if not p.is_file():
            continue
        if CONFLICT_RE.search(p.name):
            continue
        yield p


def needs_copy(src: Path, dst: Path) -> bool:
    if not dst.exists():
        return True
    try:
        return not filecmp.cmp(src, dst, shallow=False)
    except OSError:
        return True


def main() -> int:
    args = parse_args()
    cfg = load_config()
    local_root = Path(cfg["local_root"]).expanduser()
    drive_root = Path(cfg["drive_root"]).expanduser()

    if not local_root.is_dir():
        print(f"ERROR: 로컬 루트 없음: {local_root}", file=sys.stderr)
        return 1
    if not drive_root.is_dir():
        print(f"ERROR: Drive 루트 없음: {drive_root}", file=sys.stderr)
        return 1

    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    conflict_count = 0
    conflict_log: list[str] = []

    # 1. 충돌 백업: Drive 쪽 mtime 더 최신이면 백업
    for drive_file in iter_drive_md(drive_root):
        rel = drive_file.relative_to(drive_root)
        local_file = local_root / rel
        if not local_file.is_file():
            continue
        if drive_file.stat().st_mtime > local_file.stat().st_mtime:
            backup = drive_file.with_name(f"{drive_file.stem}.drive-conflict-{ts}.md")
            if not args.dry_run:
                shutil.copy2(drive_file, backup)
            conflict_count += 1
            conflict_log.append(str(rel))

    # 2. 로컬 → Drive 복사 (필요한 것만)
    uploaded = 0
    for local_file in iter_local_md(local_root):
        rel = local_file.relative_to(local_root)
        dst = drive_root / rel
        if not needs_copy(local_file, dst):
            continue
        if args.dry_run:
            print(str(rel))
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(local_file, dst)
        uploaded += 1

    print()
    print("[sync] 결과")
    print(f"  업로드:      {uploaded} 파일")
    print(f"  충돌 백업:   {conflict_count} 파일")
    if conflict_log:
        print("  충돌 목록:")
        for r in conflict_log:
            print(f"    - {r}")
    print(f"  Drive 위치:  {drive_root}")
    if args.dry_run:
        print("  ※ DRY-RUN (실제 업로드 안 함)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
