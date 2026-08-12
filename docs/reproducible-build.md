# Iceraven OP7 — Reproducible Builds & Release Traceability

Every release must be traceable to its inputs. This document defines how.

## Release identity

- Keep Iceraven's versioning scheme; extend only with the OP7 revision.
- Tag format: `op7-<iceraven-version>-r<op7-revision>` (e.g. `op7-2.46.0-r1`).
- Version name embedded in the APK: `<iceraven-version>-op7r<revision>`
  (passed via `-PversionName`, consistent with upstream's tag-derived version names).

## Build inputs recorded per release

| Input | Source |
|---|---|
| Repository commit | this repo's git SHA (OP7 layer) |
| Upstream commit | `upstream/commit.txt` (pinned by sync) |
| Upstream branch/ref | `iceraven` |
| Iceraven version | `version.txt` (`153.0`) |
| GeckoView artifact | `geckoview-omni:<version>.<buildid>` (from `buildid.h`) |
| A-C submodule commit | recorded from the upstream checkout |
| OP7 patch revision | `op7-revision.txt` + `git log patches/` |
| Workflow revision | `.github/workflows/op7-build.yml` SHA at run time |
| Build config | toolchain versions + `GRADLE_OPTS` + cache keys from the run |

## Reproducing a release

1. Check out the recorded repo commit.
2. Run `automation/op7/sync_upstream.sh --commit <recorded-upstream-commit>` (no-op if already pinned).
3. Run `automation/op7/apply_patches.sh` against a fresh upstream checkout at that commit.
4. Build with the recorded command and toolchain; compare SHA-256 of the unsigned APK
   against the recorded checksum (signatures differ per key; unsigned artifact hash is
   the reproducibility anchor).

## Release package (attached to every GitHub Release)

- `app-arm64-v8a-forkRelease.apk`
- `SHA256SUMS.txt` (checksum of the APK)
- `build-metadata.json` (all inputs above + `github.run_id`/`github.run_attempt`)
- Job summary with the full build report (see `op7-build.yml`).

## Rules

- Never publish an artifact that failed any quality gate.
- Never replace a working release with an unvalidated build.
- Never commit signing keys; signing materials live in GitHub secrets only.
