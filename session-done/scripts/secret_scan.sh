#!/usr/bin/env bash
# 업로드 대상 MD 파일들에 대해 민감정보 패턴 스캔.
# 발견 시 exit 1, 발견 없으면 exit 0.
#
# 사용법: secret_scan.sh <file_list_path>
#   file_list_path : 한 줄에 한 파일씩 절대경로가 적힌 파일

set -uo pipefail

FILE_LIST="${1:-}"
if [[ -z "$FILE_LIST" || ! -f "$FILE_LIST" ]]; then
  echo "ERROR: 파일 목록 경로가 필요합니다: secret_scan.sh <file_list_path>" >&2
  exit 2
fi

# 패턴은 명백히 자격증명/시크릿인 형태만. 너무 광범위하면 일반 문서가 다 막힘.
# - SSH/TLS 키 헤더
# - GCP/AWS 형식의 키 (실제 값 길이 기준)
# - JWT (3개 segment, 각 20자 이상)
# - 일반 환경변수 = 토큰 (값이 충분히 길고 영숫자/특수문자로만 구성될 때)
PATTERNS=(
  'BEGIN PRIVATE KEY'
  'BEGIN RSA PRIVATE KEY'
  'BEGIN OPENSSH PRIVATE KEY'
  'BEGIN EC PRIVATE KEY'
  'private_key"[[:space:]]*:'
  'client_secret"[[:space:]]*:'
  'xoxb-[A-Za-z0-9-]{20,}'
  'xoxp-[A-Za-z0-9-]{20,}'
  'xapp-[A-Za-z0-9-]{20,}'
  'ghp_[A-Za-z0-9]{20,}'
  'gho_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'AKIA[0-9A-Z]{16}'
  'sk-[A-Za-z0-9]{30,}'
  'AIza[0-9A-Za-z_-]{30,}'
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
  '[A-Z][A-Z0-9_]{3,}_TOKEN[[:space:]]*=[[:space:]]*[A-Za-z0-9+/_=-]{20,}'
  '[A-Z][A-Z0-9_]{3,}_PASS[[:space:]]*=[[:space:]]*[A-Za-z0-9+/_=!@#$%^&*-]{12,}'
  '[A-Z][A-Z0-9_]{3,}_KEY[[:space:]]*=[[:space:]]*[A-Za-z0-9+/_=-]{20,}'
  '[A-Z][A-Z0-9_]{3,}_SECRET[[:space:]]*=[[:space:]]*[A-Za-z0-9+/_=-]{20,}'
)

PATTERN_REGEX="$(IFS='|'; echo "${PATTERNS[*]}")"

FOUND=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ ! -f "$f" ]] && continue
  if HITS=$(grep -EnH --binary-files=without-match "$PATTERN_REGEX" "$f" 2>/dev/null); then
    if [[ -n "$HITS" ]]; then
      echo "$HITS"
      FOUND=1
    fi
  fi
done < "$FILE_LIST"

if [[ $FOUND -eq 1 ]]; then
  echo "" >&2
  echo "[secret_scan] 민감정보 패턴 발견 — 위 파일들을 정리한 뒤 다시 시도하세요." >&2
  exit 1
fi

echo "[secret_scan] 통과 — 민감정보 패턴 없음"
exit 0
