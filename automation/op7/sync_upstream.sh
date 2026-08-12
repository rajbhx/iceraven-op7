#!/usr/bin/env bash
# Pin a new upstream commit and record upstream status (Phase 4).
# Usage:
#   automation/op7/sync_upstream.sh                 # pin current upstream HEAD
#   automation/op7/sync_upstream.sh --commit <sha>  # pin a specific upstream commit
# This NEVER force-resets the repository; it only records the upstream commit to sync to.
set -euo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-fork-maintainers/iceraven-browser}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-iceraven}"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PIN_FILE="$ROOT_DIR/upstream/commit.txt"
STATUS_FILE="$ROOT_DIR/upstream/status.json"

COMMIT=""
if [[ "${1:-}" == "--commit" ]]; then
  COMMIT="${2:?usage: sync_upstream.sh [--commit <sha>]}"
fi

if [[ -z "$COMMIT" ]]; then
  COMMIT="$(curl -fsSL "https://api.github.com/repos/${UPSTREAM_REPO}/commits/${UPSTREAM_BRANCH}" | jq -r '.sha')"
fi

COMMIT_INFO="$(curl -fsSL "https://api.github.com/repos/${UPSTREAM_REPO}/commits/${COMMIT}")"

COMMIT_DATE="$(jq -r '.commit.committer.date' <<< "$COMMIT_INFO")"
MESSAGE="$(jq -r '.commit.message' <<< "$COMMIT_INFO" | head -n 1)"
VERSION_TXT="$(curl -fsSL "https://raw.githubusercontent.com/${UPSTREAM_REPO}/${COMMIT}/version.txt" | tr -d '[:space:]')"
BUILDID_H="$(curl -fsSL "https://raw.githubusercontent.com/${UPSTREAM_REPO}/${COMMIT}/buildid.h" | grep -oP 'MOZ_BUILDID\s+\K[0-9]+' || echo "unknown")"

printf '%s\n' "$COMMIT" > "$PIN_FILE"

cat > "$STATUS_FILE" << JSON
{
  "upstream_repo": "$UPSTREAM_REPO",
  "upstream_branch": "$UPSTREAM_BRANCH",
  "commit": "$COMMIT",
  "commit_date": "$COMMIT_DATE",
  "commit_message": "$MESSAGE",
  "iceraven_version": "$VERSION_TXT",
  "geckoview_buildid": "$BUILDID_H",
  "synced_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

echo "pinned upstream commit: $COMMIT"
echo "iceraven version: $VERSION_TXT"
echo "geckoview artifact: org.mozilla.geckoview:geckoview-omni:${VERSION_TXT}.${BUILDID_H}"
jq . "$STATUS_FILE"
