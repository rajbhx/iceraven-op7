#!/usr/bin/env bash
# Apply the OP7 patch set to a fresh upstream checkout (Phase 3+).
# Run from the upstream checkout root, with this repo checked out somewhere reachable:
#   OP7_LAYER_DIR=/path/to/iceraven-op7 automation/op7/apply_patches.sh
# Never auto-resolves conflicts: on failure it exits non-zero with a conflict report
# and the pipeline stops before any build or publish step.
set -euo pipefail

OP7_LAYER_DIR="${OP7_LAYER_DIR:?set OP7_LAYER_DIR to the iceraven-op7 checkout}"
PATCH_DIR="$OP7_LAYER_DIR/patches/op7"

if [[ ! -d "$PATCH_DIR" ]]; then
  echo "no patch directory: $PATCH_DIR (nothing to apply)"
  exit 0
fi

FAILED=0
for patch in "$PATCH_DIR"/*.patch; do
  [[ -e "$patch" ]] || continue
  echo "==> applying $patch"
  if ! git apply --check "$patch" 2> /tmp/op7-check.err; then
    echo "!! CONFLICT with $patch" >&2
    cat /tmp/op7-check.err >&2
    FAILED=1
    continue
  fi
  git apply "$patch"
  echo "    ok"
done

if [[ "$FAILED" -ne 0 ]]; then
  cat << REPORT >&2
======================== OP7 PATCH CONFLICT ========================
upstream commit : $(git rev-parse HEAD 2>/dev/null || echo unknown)
failing patch   : see messages above
conflict files  : git apply --check output above
last known-good : see GitHub Releases (op7-* tags) / upstream tag
maintenance     : rebase the failing patch onto the new upstream HEAD,
                  verify the root cause, and re-run validation.
Policy          : automatic publishing is STOPPED. No build, no release.
=====================================================================
REPORT
  exit 1
fi

echo "all OP7 patches applied cleanly"
