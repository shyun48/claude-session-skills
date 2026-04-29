#!/usr/bin/env python3
"""
session-done 최초 셋업. config.json 생성 + Drive 미러 폴더 준비.

사용법:
  setup.py --drive-root <PATH> --user-name <NAME> [--local-root <PATH>]

cross-platform (mac/windows/linux). 기존 setup.sh 의 Python 포팅.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


CONFIG_DIR = Path.home() / ".claude" / "skills" / "wy-session-done"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--drive-root", required=True)
    p.add_argument("--user-name", required=True)
    p.add_argument("--local-root", default="")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    local_root = Path(args.local_root).expanduser().resolve() if args.local_root else Path.cwd()
    if not local_root.exists():
        print(f"ERROR: 로컬 루트 없음: {local_root}", file=sys.stderr)
        return 1

    drive_root = Path(args.drive_root).expanduser()
    drive_parent = drive_root.parent
    if not drive_parent.exists():
        print(f"ERROR: Drive 부모 폴더 없음: {drive_parent}", file=sys.stderr)
        print("  - macOS: Google Drive Desktop 동기화 상태 확인", file=sys.stderr)
        print("  - Windows: Drive Desktop 마운트 (G:\\My Drive 등) 확인", file=sys.stderr)
        return 1

    drive_root.mkdir(parents=True, exist_ok=True)
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    readme = drive_root / "README.md"
    if not readme.exists():
        now_local = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        readme.write_text(
            f"""# {args.user_name} — Claude 워크스페이스 미러

이 폴더는 `{args.user_name}` 의 Claude 로컬 작업 공간에서 자동으로 동기화되는 **MD 문서 미러**입니다.

## 무엇이 올라오나
- 과제 정의 (`brief.md`, `01_ask.md`)
- 페이즈별 진행 (`phases/0N_*.md`)
- 진행 상태 (`progress.md`)
- 핸드오프 (`handoffs/<ts>.md`)
- 운영 공통 문서 (`04_docs/`)
- 과제 보드 (`registry.md`)

## 무엇은 올라오지 않나
- 코드 (`*.py`, `*.sh`)
- 데이터/모델 (`*.json`, `*.txt`, `*.parquet` 등)
- 자격증명 / 환경변수
- 실행 결과물 (`out/`)

## 동기화 시점
- 로컬에서 `/wy-session-done` 실행 시
- 단방향 (로컬 → Drive)

생성일: {now_local}
""",
            encoding="utf-8",
        )

    config_path = CONFIG_DIR / "config.json"
    config = {
        "user_name": args.user_name,
        "drive_root": str(drive_root),
        "local_root": str(local_root),
        "configured_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")

    print("[setup] 완료")
    print(f"  사용자:    {args.user_name}")
    print(f"  로컬 루트:  {local_root}")
    print(f"  Drive 루트: {drive_root}")
    print(f"  config:    {config_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
