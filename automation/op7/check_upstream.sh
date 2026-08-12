#!/usr/bin/env bash
# Lightweight upstream change detection (Phase 4).
# Compares the upstream `iceraven` branch HEAD to the pinned commit.
# Exit codes: 0 = unchanged, 1 = changed (new HEAD printed), 2 = upstream unreachable.
set -euo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-fork-maintainers/iceraven-browser}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-iceraven}"
PIN_FILE="${PIN_FILE:-$(cd "$(dirname "$0")/../.." && pwd)/upstream/commit.txt}"

if [[ ! -f "$PIN_FILE" ]]; then
  echo "error: pin file not found: $PIN_FILE" >&2
  exit 2
fi

NEW_HEAD="$(curl -fsSL "https://api.github.com/repos/${UPSTREAM_REPO}/commits/${UPSTREAM_BRANCH}" | jq -r '.sha' 2>/dev/null || true)"
if [[ -z "$NEW_HEAD" || "$NEW_HEAD" == "null" ]]; then
  echo "error: could not resolve upstream HEAD for ${UPSTREAM_REPO}@${UPSTREAM_BRANCH}" >&2
  exit 2
fi

PINNED="$(tr -d '[:space:]' < "$PIN_FILE")"
echo "pinned:  $PINNED"
echo "upstream: $NEW_HEAD"

if [[ "$NEW_HEAD" == "$PINNED" ]]; then
  echo "result: unchanged"
  exit 0
fi

echo "result: changed"
echo "new_head=$NEW_HEAD"
exit 1
