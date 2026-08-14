# Session digest — 2026-08-14 — Phase 9 auto-release wiring

## Problems solved
- **P** releases were never created automatically even though the spec's success criteria require PASS -> release on every upstream sync
  cause: upstream-check.yml dispatched op7-build with release=false; op7-build.yml only ran the release job when manually invoked with release=true + release_tag; nothing generated a tag
  solution: new auto_release input on op7-build.yml — after ALL quality gates pass, the release job is gated on the build job's release output (not the raw dispatch input); tag auto-generated from version.txt + op7-revision.txt (op7-<version>-r<rev>, v-prefix stripped); refuses fast=true + release combos (fast skips R8, not release evidence); release tag+secrets guards fail closed; upstream-check.yml now dispatches auto_release=true so a new upstream commit -> sync -> build -> gates pass -> GitHub Release automatically, while any conflict/failed gate still stops publishing
  section: G
  tags: phase9, release, automation, gates, tag
- **P** shellcheck SC2295 on the auto-tag expression broke CI (actionlint)
  cause: nested expansion inside a parameter-expansion pattern: ${OP7_VERSION_NAME%-op7r${REV}} — the inner ${REV} matched as a pattern
  solution: quote the inner expansion: ${OP7_VERSION_NAME%-op7r"${REV}"}; CI (actionlint+shellcheck) now green
  section: E
  tags: shellcheck, workflow, quoting, actionlint

## Notes
- Release secrets were ALREADY configured (OP7_RELEASE_KEYSTORE_* in the protected `release` environment) since 2026-08-12 — the missing piece was wiring, not keys.
- Auto-release only fires on NEW upstream commits (sync path). Same-upstream revision bumps (r7 on unchanged upstream) still need a manual release=true dispatch.
- Local actionlint can't fully run here (sandbox kills shellcheck binary); CI actionlint is the authoritative check.
