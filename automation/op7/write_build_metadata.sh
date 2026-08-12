#!/usr/bin/env bash
# Write build-metadata.json for a build/release (Phase 3+).
# Inputs are taken from environment variables set by the workflow.
set -euo pipefail

OUT="${1:-build-metadata.json}"

cat > "$OUT" << JSON
{
  "browser": "Iceraven OP7",
  "base": "${OP7_UPSTREAM_COMMIT:-unknown}",
  "base_branch": "${OP7_UPSTREAM_BRANCH:-iceraven}",
  "iceraven_version": "${OP7_ICERAVEN_VERSION:-unknown}",
  "geckoview_artifact": "${OP7_GECKOVIEW_ARTIFACT:-unknown}",
  "android_components_version": "${OP7_AC_VERSION:-unknown}",
  "version": "${OP7_VERSION_NAME:-unknown}",
  "op7_patch_revision": "${OP7_PATCH_REVISION:-unknown}",
  "target_abi": "${OP7_ABI:-arm64-v8a}",
  "android_target": "${OP7_ANDROID_TARGET:-unknown}",
  "build": "${GITHUB_RUN_ID:-local}",
  "workflow": "${GITHUB_WORKFLOW:-local}",
  "run_attempt": "${GITHUB_RUN_ATTEMPT:-1}",
  "repository": "${GITHUB_REPOSITORY:-unknown}",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

echo "metadata written to $OUT"
jq . "$OUT"
