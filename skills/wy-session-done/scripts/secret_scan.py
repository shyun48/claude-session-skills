#!/usr/bin/env python3
"""
업로드 대상 MD 파일들에 민감정보 패턴 스캔. 발견 시 exit 1, 없으면 exit 0.

사용법: secret_scan.py <file_list_path>
  file_list_path : 한 줄에 한 파일씩 절대경로
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


PATTERNS = [
    r"BEGIN PRIVATE KEY",
    r"BEGIN RSA PRIVATE KEY",
    r"BEGIN OPENSSH PRIVATE KEY",
    r"BEGIN EC PRIVATE KEY",
    r'private_key"\s*:',
    r'client_secret"\s*:',
    r"xoxb-[A-Za-z0-9-]{20,}",
    r"xoxp-[A-Za-z0-9-]{20,}",
    r"xapp-[A-Za-z0-9-]{20,}",
    r"ghp_[A-Za-z0-9]{20,}",
    r"gho_[A-Za-z0-9]{20,}",
    r"github_pat_[A-Za-z0-9_]{20,}",
    r"AKIA[0-9A-Z]{16}",
    r"sk-[A-Za-z0-9]{30,}",
    r"AIza[0-9A-Za-z_-]{30,}",
    r"eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}",
    r"[A-Z][A-Z0-9_]{3,}_TOKEN\s*=\s*[A-Za-z0-9+/_=-]{20,}",
    r"[A-Z][A-Z0-9_]{3,}_PASS\s*=\s*[A-Za-z0-9+/_=!@#$%^&*-]{12,}",
    r"[A-Z][A-Z0-9_]{3,}_KEY\s*=\s*[A-Za-z0-9+/_=-]{20,}",
    r"[A-Z][A-Z0-9_]{3,}_SECRET\s*=\s*[A-Za-z0-9+/_=-]{20,}",
]
PATTERN_REGEX = re.compile("|".join(PATTERNS))


def main() -> int:
    if len(sys.argv) != 2:
        print("ERROR: 사용법: secret_scan.py <file_list_path>", file=sys.stderr)
        return 2

    file_list = Path(sys.argv[1])
    if not file_list.is_file():
        print(f"ERROR: 파일 목록 없음: {file_list}", file=sys.stderr)
        return 2

    found = False
    for line in file_list.read_text(encoding="utf-8").splitlines():
        target = line.strip()
        if not target:
            continue
        p = Path(target)
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for ln, content in enumerate(text.splitlines(), start=1):
            if PATTERN_REGEX.search(content):
                print(f"{p}:{ln}:{content}")
                found = True

    if found:
        print("", file=sys.stderr)
        print("[secret_scan] 민감정보 패턴 발견 — 위 파일 정리 후 재시도", file=sys.stderr)
        return 1

    print("[secret_scan] 통과 — 민감정보 패턴 없음")
    return 0


if __name__ == "__main__":
    sys.exit(main())
