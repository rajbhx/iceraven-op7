# Iceraven OP7 — Roadmap & Engineering Plan

> Live planning document. Updated 2026-08-12.
> Companion docs: `docs/op7-project-audit.md` (Phase 0), `docs/baseline.md`,
> `docs/architecture.md`, `docs/performance/`, `docs/reproducible-build.md`.

---

## 1. What the "special build" is

Iceraven OP7 = **stock Iceraven, engineered for this OnePlus 7**:

- Browser source is always the exact upstream Iceraven commit (`upstream/commit.txt`), never a fork of browser code.
- OP7 layer = build/distribution choices + capability-driven runtime settings + *measured* optimizations, nothing else.
- Distribution is **arm64-v8a only** — the only ABI this device runs.
- Every revision is traceable: upstream commit + Iceraven version + OP7 patch revision + workflow run (see `docs/reproducible-build.md`).

**What it must never change:** Gecko/GeckoView architecture, security (sandboxing, HTTPS, site isolation), privacy defaults, extension support, web compatibility. Optimization only where the baseline shows a real, measured bottleneck.

## 2. Build revisions

| Revision | Content | Status |
|---|---|---|
| `r0` | Unmodified Iceraven (arm64-only distribution, signed, metadata) — **the baseline** | build in progress |
| `r1` | First measured optimization (top baseline bottleneck) | gated on Phase 2 data |
| `r2+` | One optimization per revision, each with before/after benchmark | gated |
| release | `op7-<iceraven-version>-r<rev>` tag + signed APK + SHA-256 + metadata | after gates pass |

Revisions do NOT skip phases: r1 exists only after baseline measurements exist.

## 3. Phase status (from the Phase-0 audit)

| Phase | Work | Status |
|---|---|---|
| 0 | Repository audit | ✅ `docs/op7-project-audit.md` |
| 1 | Unmodified build, reproducible, recorded | 🔄 first validated build running |
| 2 | Baseline measurements on this device | ⏳ needs APK installed + adb/shell |
| 3 | GitHub Actions reliability (cache, arm64-only, parallel) | 🔄 implemented, needs green run |
| 4 | Automatic upstream sync + conflict stop | ✅ implemented, unproven on real upstream move |
| 5 | `DeviceCapabilities` (design + device report) | ✅ design + report; Kotlin impl after baseline |
| 6 | On-device profiling | ⏳ |
| 7 | First measured optimization | ⏳ gated |
| 8 | Benchmark/regression loop | ⏳ |
| 9 | Automated release (gates, signing, checksums, Release) | ✅ skeleton, unproven end-to-end |
| 10 | Long-term upstream maintenance | ⏳ |

## 4. Error matrix — problems, fixes, prevention

Legend: 🔴 seen in our runs · 🟡 anticipated

### Build pipeline

| # | Error | Root cause | Fix applied / solution | Prevention |
|---|---|---|---|---|
| E1 🔴 | `destination path 'upstream' already exists` | workflow cloned into `upstream/` which is a tracked dir of this repo | clone into `mirror/` | keep clone dirs out of tracked paths; CI validates layout |
| E2 🔴 | `removeUnusedEntriesOlderThan` write-only property crash | gradle-build-action v3 cleanup incompatible with Gradle 9.5.1 | use gradle-build-action **v2** (upstream-proven) | pin action version to upstream's |
| E3 🔴 | `APK not found` (first time) | hardcoded output path; ABI selection changes AGP output layout | `find`-based discovery, name-agnostic | never assume AGP output paths/names |
| E4 🔴 | `APK not found` (second time) | unsigned APKs are named `*-forkRelease-unsigned.apk` (no signing config in forkRelease) | discovery + `-unsigned` handling; sign action renames to `.apk` | validation of actual file listing |
| E5 🟢 | `unexpected package id` (fixed) | OP7 patch appends `.iceraven.op7` to app id | expect `io.github.forkmaintainers.iceraven.op7` | derived at runtime from OP7 patches + `app/build.gradle` defaultConfig |
| E6 🔴 | sign action "build-tools not found" risk | action reads `ANDROID_HOME` (runner SDK), we pointed at `ANDROID_SDK_ROOT` (custom SDK) | compute `BUILD_TOOLS_VERSION` from `ANDROID_HOME` like upstream | read third-party action source before use |
| E7 🔴 | GitHub cache service outage (`400` / "services aren't available") | GitHub-side transient | non-fatal warnings; next run restores | cache keys stable; don't churn build inputs |
| E8 🟡 | R8 OOM with `--parallel` on 2-core/7 GB runner | heap vs workers | tune `GRADLE_OPTS`, reduce `--max-workers`, drop `--parallel` if needed | watch `free -h` step; keep release builds serial if flaky |
| E9 🟡 | `native-code` badging line absent (universal APK) | ABI selection ignored by some AGP versions | validation fails loudly; adjust `-Pandroid.injected.build.abi` or patch `splits.abi` | validation gates exist by design |
| E10 🟡 | PKCS12 alias mismatch at signing | openssl `-name` vs apksigner alias | verify with `apksigner --list-keys`; both are `iceravenop7debug`/`iceravenop7release` | document keystore contents in `/root/op7-keystores/` |
| E11 🟡 | APK artifact too large for retention | 131 MB APK + 3 ABIs | arm64-only now; retention-days 30 | releases live on GitHub Releases, not artifacts |

### Upstream sync

| # | Error | Root cause | Solution | Prevention |
|---|---|---|---|---|
| E12 🟡 | OP7 patch fails `git apply` on new upstream commit | upstream refactored a patched file | **STOP**, report (commit, patch, files, last known-good), no publish; rebase patch | patches small, one concern each |
| E13 🟡 | Upstream submodule (A-C) fetch failure | network/git flake | retry; build fails closed (never build without exact commit) | mirror clone with `--filter=blob:none` |
| E14 🟡 | Scheduled workflow disabled after ~60 days idle | GitHub policy | lightweight daily check + manual/repository_dispatch; upstream releases monthly keep repo active | documented in audit Risks |
| E15 🟡 | Upstream rewrites history / branch force-push | rare | pin by SHA (never branch name) — already the design | `upstream/commit.txt` is a SHA |

### Device / measurement

| # | Error | Root cause | Solution | Prevention |
|---|---|---|---|---|
| E16 🔴 | `adb` not reachable from container | no `adbd` on 5555 (port open but no adb listener); no adb binary | pure-Python `adb_shell` client; user enables `adb tcpip 5555`; fallback: manual install tap via `intent` bridge | document exact enable commands |
| E17 🔴 | shizuku bridge blocked | battery optimization between apps | user disables battery optimization; not pipeline-critical | adb path preferred |
| E18 🟡 | Noisy on-device benchmarks | phone state, brightness, background apps | fixed conditions, airplane mode, 3-5 runs, median; same build | runbook in `docs/performance/baseline.md` |
| E19 🟡 | Install blocked ("app not installed") | signature mismatch (debug vs release key) | use matching signed APK per purpose | separate debug-signed validation vs release-signed publish |

### Operations

| # | Error | Root cause | Solution | Prevention |
|---|---|---|---|---|
| E20 🟡 | Release secrets missing/expired | rotation | guard step fails before publish | README checklist; protect `release` environment |
| E21 🟡 | Keystore lost | device reset | **back up `/root/op7-keystores/` now** | offline copy |
| E22 🟡 | Version collision | re-releasing same tag | require explicit `release_tag` input; tags are immutable | documented in release flow |
| E23 🟡 | Free-runner minute limits | many builds | arm64-only + parallel + cache + `fast` mode; upstream-check is cheap | monitor Actions usage |

## 5. Requirements checklist

| Item | Needed for | Status |
|---|---|---|
| GitHub repo + `DEBUG_*` secrets | validation signing | ✅ set |
| GitHub `release` environment + `OP7_RELEASE_*` secrets | public release signing | ✅ set |
| Keystore backup (`/root/op7-keystores/`) | future releases | ⚠️ **do now** |
| Physical OnePlus 7 (GM1901) | baseline + all measurements | ✅ this device |
| adb reachability (or manual install tap) | install APK + shell measurements | ⏳ user action |
| Baseline APK (r0) | install + measure | 🔄 building |
| ~300 MB free on phone | APK + profile | ✅ 138 GB free |
| Measurement session (~1–2 h) | Phase 2 | ⏳ |
| Free GitHub Actions minutes | monthly builds | ✅ public repo |

## 6. Next build — definition (completes Phase 1 + 3)

Dispatch: `op7-build.yml` with `abi=arm64-v8a`, `release=false`, `fast=false`, upstream commit = pinned.

Expected: arm64-only build, `--parallel --build-cache`, validation (package/SDK/ABI/checksum), debug-signed APK, `build-metadata.json`, two artifacts (`op7-validation-*`, `op7-signed-*`), job summary.

Exit criteria (all must pass):
- [ ] source sync + patches apply
- [ ] `assembleForkRelease` succeeds (arm64 only)
- [ ] badging: package `io.github.forkmaintainers.iceraven.op7`, minSdk 26, targetSdk 36, `native-code: arm64-v8a`
- [ ] `lib/arm64-v8a/` present in APK
- [ ] debug-sign succeeds; SHA-256 written; metadata written
- [ ] artifacts uploaded; summary shows cache restore status

Then (Phase 2): install r0 on the phone → capture cold/warm start, memory, gfx, battery per runbook → write results into `docs/baseline.md` + `docs/performance/baseline.md`.

## 7. Release flow (Phase 9)

```
fast=false build passes validation (rN)
   → maintainer dispatches release=true + release_tag=op7-<ver>-rN
   → build job re-validates
   → release job (environment: release):
       guard secrets → download validation artifact → sign with release key
       → SHA256SUMS.txt → create GitHub Release (tag, body, assets)
```
No release without: sync ok, patches applied, compile ok, validation ok, signing ok, checksums ok.

## 8. Success criteria (spec §final) — status

| Criterion | Status |
|---|---|
| Automatically maintained (upstream detection + safe sync) | ✅ implemented; validate on first upstream move |
| Reproducible, traceable releases | ✅ design + metadata; first release pending |
| OnePlus 7 optimized (measured, not assumed) | ⏳ after baseline |
| Free public infrastructure only | ✅ GitHub Actions/Releases/cache |
| Conflict → stop, report, never overwrite | ✅ implemented |
| Benchmark/regression loop with keep/revert | ⏳ Phase 8 |
