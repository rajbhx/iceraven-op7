# Iceraven OP7 — Project Audit

> Repository audit performed on 2026-08-12 against
> `https://github.com/fork-maintainers/iceraven-browser` (default branch: `iceraven`).
>
> This audit is the **Phase 0 deliverable**. Nothing in this repository modifies the
> upstream source until the baseline (Phase 1) is recorded and the measurement
> methodology (Phase 2) is in place.

---

## 0. Scope and method

The audit inspects the authoritative upstream structure and build system without
modifying it:

| Component | Inspected artifact | Finding |
|---|---|---|
| Repository | `fork-maintainers/iceraven-browser` | Fork of Mozilla Fenix; default branch `iceraven`; ~6.3k stars; not archived; last push 2026-07-27 |
| Version | `version.txt` | `153.0` |
| Build ID | `buildid.h` | `MOZ_BUILDID 20260715202819` |
| Latest release | GitHub Releases | `iceraven-2.46.0` (2026-07-27); cadence ≈ monthly (`2.45.0` 2026-06-20, `2.44.0` 2026-05-22) |
| Submodules | `.gitmodules` | `android-components` → `akliuxingyuan/android-components` (Iceraven-maintained A-C) |
| Workflows | `.github/workflows/` | `ci.yml`, `release.yml` (+ `ISSUE_TEMPLATE/`) |
| Build wrapper | `gradle/wrapper/gradle-wrapper.properties` | Gradle `9.5.1` (sha256 pinned) |
| Toolchain (CI) | `.github/workflows/*.yml`, `automation/iceraven/install-sdk.sh` | JDK 17 (Temurin), Android SDK via script, NDK `29.0.14206865` |
| Mozconfig | `mozconfig.json` + `gradle/mozconfig.gradle` | Maven mirrors; `MOZ_UPDATE_CHANNEL=release`; `MOZ_ANDROID_FAT_AAR_ARCHITECTURES=true`; `ANDROID_BUILD_TOOLS_VERSION=36.0.0` |
| SDK levels | `android-components/.config.yml` (submodule) | `minSdk 26`, `targetSdk 36`, `compileSdk 37.0`, `jvmTarget 17` |
| Version catalog | `gradle/libs.versions.toml` | AGP `8.13.2`, Kotlin `2.3.21`, KSP `2.3.9`, detekt `1.23.8`, ktlint `1.8.0`, Glean `67.3.2` |
| GeckoView | A-C `engine-gecko` + Mozilla Maven | `org.mozilla.geckoview:geckoview-omni:153.0.20260715202819` (verified present on `maven.mozilla.org`, 240 MB fat AAR) |
| APK ABIs | `app/build.gradle` `splits.abi` | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Versioning scheme | tags | `iceraven-x.y.z` (e.g. `iceraven-2.46.0`) |

Verified build facts that the OP7 project must not silently change:

- Application ID: `io.github.forkmaintainers`; `forkRelease` appends `.iceraven` upstream, and the OP7 patch layer appends `.iceraven.op7` (final `io.github.forkmaintainers.iceraven.op7`); OP7 shared user ID `io.github.forkmaintainers.iceraven.op7.sharedID` (`app/build.gradle` + `patches/op7/001-op7-application-id.patch`).
- The releasable variant is `app:assembleForkRelease`; output layout `gradle/build/app/outputs/apk/forkRelease/` (build dir relocated by `settings.gradle`).
- No Gradle product flavors exist in the current source set layout (`app/src/forkRelease/`, `app/src/forkDebug/` are source sets of the `forkRelease`/`forkDebug` build types). The README's `assemblefenixForkRelease` spelling is stale; the CI uses `app:assembleForkRelease`.
- Iceraven's own branding delta is applied **at CI time** (`automation/iceraven/patch_android_components.sh` + `sed` of string resources), not committed into the tree. This is the pattern the OP7 patch layer must follow.

---

## 1. Existing architecture

`app` (Fenix-derived UI) builds against a composite build of the `android-components`
submodule (`settings.gradle` includes `android-components/plugins/*` builds). The
browser engine is GeckoView consumed from Mozilla Maven as a fat `-omni` AAR
(`MOZ_ANDROID_FAT_AAR_ARCHITECTURES=true`), so **no Gecko/GeckoView source is built in
this pipeline** — only the Fenix-style app plus A-C components.

Documented reference for the full stack (UI → A-C → GeckoView → Gecko) already exists
upstream: `docs/architecture-overview.md`. The OP7 `docs/architecture.md` extends it
with the layer ownership rules (see below).

Relevant existing subsystems for OP7 work:

- `app/src/main/java/org/mozilla/fenix/` — UI, sessions, browser state, engine wiring.
- `benchmark/` — AndroidX Macrobenchmark module (`com.android.test`) with a managed Pixel 6 device.
- `app/benchmark.gradle` — Jetpack Microbenchmark wiring behind the `-Pbenchmark` property.
- `tools/run_benchmark.py`, `tools/setup-startup-profiling.py` — benchmark helpers.
- `automation/iceraven/` — Iceraven-specific CI patching (search engines, toolbar, crash-reporter toolkit, TLD list).
- `docs/startup-performance.md` — existing startup timeline (FenixApplication → HomeActivity → Gecko) that the OP7 startup baseline extends.

---

## 2. Existing workflows

`.github/workflows/ci.yml` (push to `iceraven`):

- Checkout with `submodules: true`, `fetch-depth: 0`.
- JDK 17 Temurin; SDK via `automation/iceraven/install-sdk.sh`; memory inspection.
- `VERSION_NAME=$(git describe --tags HEAD)`.
- Runs `automation/iceraven/patch_android_components.sh` and string `sed` replacements (the on-the-fly Iceraven patch layer).
- Builds `app:assembleForkRelease` via `gradle/gradle-build-action@v2` with `GRADLE_OPTS` memory tuning, `--no-daemon`, `/usr/bin/time`.
- Signs all ABIs with `abhijitvalluri/sign-apks@v0.8` using `DEBUG_*` secrets.
- Uploads `arm64-v8a`, `armeabi-v7a`, `x86_64` APKs as artifacts.

`.github/workflows/release.yml` (trigger `create`):

- Same build; when the created ref is a tag matching `iceraven*`, signs, creates a GitHub Release (`actions/create-release@v1`), and uploads the three APKs.
- Changelog generation compares previous `iceraven-*` tag and embeds the Fenix version from `version.txt`.

Gaps relevant to OP7 automation:

- No scheduled upstream-change detection; no conflict handling; no quality gates beyond "build succeeds".
- No checksums, no structured build metadata, no ABI validation, no job summaries.
- Builds every ABI on every run (slow and storage-heavy on free runners).
- Uses deprecated action versions (`actions/create-release@v1`, `upload-release-asset@v1`, `gradle-build-action@v2`, checkout@v3).

The OP7 pipeline **reuses** the build/sign pattern but fixes the gaps; it does not replace upstream's own CI for upstream development.

---

## 3. Existing build system

- Gradle 9.5.1 wrapper with pinned checksum; `settings.gradle` applies `shared-settings.gradle` (YAML-backed `Config` from `android-components/.config.yml`) and includes composite builds for A-C plugins and Iceraven's own `plugins/`.
- `gradle/mozconfig.gradle` loads `mozconfig.json`, derives `MOZ_APP_VERSION` from `version.txt`, sets `MOZ_UPDATE_CHANNEL=release`, fat AAR flag, build-tools `36.0.0`, and Maven repository mirrors (Mozilla, Gradle Plugin Portal, Google, Maven Central).
- GeckoView resolution (in A-C `components/browser/engine-gecko/build.gradle`): channel `release` → artifact `geckoview-omni`; version = `MOZ_APP_VERSION` + `.` + build ID from `buildid.h` → `153.0.20260715202819` (verified on Maven).
- Android Components version = `version.txt` content (`153.0`) plus the A-C submodule commit pin.
- Variant: `forkRelease` (minified, resource-shrunk, `USE_RELEASE_VERSIONING=true`, custom AMO collection). Debug/dev variant `forkDebug` is the default build type.
- APK version codes follow the legacy Fennec scheme (`Config.generateFennecVersionCode(abi)` in the A-C `ConfigPlugin`), so each ABI split gets a distinct monotonic code.

---

## 4. Existing release system

- Tag-driven: maintainers push `iceraven-x.y.z`; `release.yml` builds, signs with the shared `DEBUG_*` signing secrets, creates a GitHub Release, and attaches the three ABI APKs.
- "Last known-good" for OP7 purposes: `iceraven-2.46.0` (2026-07-27).
- No checksums, no metadata manifests, no reproducible-build record, no validation beyond successful compilation.

---

## 5. Existing upstream relationship

- Iceraven is a fork of Mozilla Fenix. Version branches exist (`fenix/<version>`, e.g. `fenix/130.0` … `fenix/153.0` era), and the `iceraven` branch is the shipping line.
- Recent `iceraven` commits (2026-07-25) show the sync workflow: bump `version.txt`, apply "update patch", fix build, tag. The A-C submodule is pinned to the Iceraven-maintained `akliuxingyuan/android-components` repo.
- There is **no automated upstream detection** today; sync is manual, commit-based, and not conflict-safe.

OP7 relationship: this repository does **not** fork the full Iceraven tree. It mirrors the upstream commit, applies a small OP7 patch set on top at build time (same philosophy as `automation/iceraven/patch_android_components.sh`), and records the pinned upstream commit for traceability.

---

## 6. Existing GeckoView integration

- Consumed purely as a Maven artifact (`geckoview-omni` fat AAR, release channel). No Gecko source, no `mach`, no Gecko build in this pipeline.
- A-C `engine-gecko` wraps GeckoView (session, settings, web extensions, profiler, login/address/card extensions).
- `app` wires the engine via Fenix `BrowserFragment`/`GeckoEngine` lifecycle; Nimbus, Glean, and megazord (App Services / Rust) are initialized in `FenixApplication`.
- Implication for OP7: **Gecko-level changes are out of reach of this build system**. OP7 changes must live in (a) app code, (b) A-C components, (c) build/runtime configuration (prefs, settings), or (d) documented GeckoView runtime preferences. Gecko source-level optimization would require a different pipeline (building Gecko/GV from source) and is explicitly out of scope unless a measured, reproducible problem requires it — and even then it should be pushed upstream rather than forked locally.

---

## 7. Existing ARM64 support

- `arm64-v8a` is a first-class split (`app/build.gradle`); upstream CI publishes it.
- `MOZ_ANDROID_FAT_AAR_ARCHITECTURES=true` means the fat AAR carries all ABIs; the app split keeps only the matched native libs.
- Iceraven's README documents ARM64 as appropriate for newer 64-bit devices.
- The OnePlus 7 (Snapdragon 855/SM8150, Adreno 640, Android 10) is a 64-bit-only device class; OP7 builds target `arm64-v8a` only.

---

## 8. Existing benchmark infrastructure

- Jetpack Microbenchmark (in-app, `-Pbenchmark` property; outputs to `app/build/outputs/connected_android_test_additional_output/...` and device `/storage/emulated/0/benchmark`).
- Macrobenchmark module `benchmark/` (startup, scrolling, etc.) with managed device `pixel6Api34`.
- `tools/run_benchmark.py` (run + collect), `tools/setup-startup-profiling.py`.
- `docs/startup-performance.md` documents a startup timeline synthesized from profiles.
- `docs/Addressing-a-performance-regression.md` documents regression methodology.
- No per-device (OP7) baseline exists yet; no automated benchmark job in CI; no regression tracking database. OP7 must add: device-specific baseline captures and a documented comparison protocol (the device is real hardware, so benchmarks must run on a physical OnePlus 7, not on emulators/managed devices).

---

## 9. Existing caching

- CI relies on `gradle/gradle-build-action@v2` with `gradle-home-cache-cleanup: true` (Gradle + dependency caches; keys include Gradle version and lockfiles).
- No explicit Rust/Cargo or NDK/sysroot caching (no Rust build happens — Gecko is a Maven artifact).
- No caching of the 240 MB GeckoView AAR beyond Gradle's dependency cache.
- No Maven-local or config-invalidation scheme beyond what Gradle provides.
- OP7 workflow must key caches on: OS, architecture, JDK, Gradle wrapper version, `version.txt`/buildid (they determine the GV artifact), and `gradle/libs.versions.toml` hash.

---

## 10. Existing automation

- `automation/iceraven/install-sdk.sh` — SDK + licenses + NDK `29.0.14206865` + `local.properties`.
- `automation/iceraven/patch_android_components.sh` — search-engine assets, `SearchEngineReader.kt` injection, A-C Gradle path rewrites, patch application (`patches/toolbar.patch`, `patches/top_sites_no_most_visted_sites.patch`), crash-reporter source generation, TLD list fetch from `mozilla-firefox/firefox` tags.
- Jenkinsfile — legacy sync-integration test only (not part of the release path).
- No scheduled tasks, no upstream watcher, no conflict handling, no maintenance bot.

---

## 11. Potential OP7 optimization points (hypotheses to be verified, not applied)

These are candidates only; **nothing ships without a measured baseline and a positive benchmark** (Phases 1–2, then 7+).

| # | Area | Hypothesis to test | Layer | Risk |
|---|---|---|---|---|
| 1 | Startup | Reduce pre-GV work in `FenixApplication` / `BrowserFragment`; lazy-init non-critical services; defer Nimbus/Glean where safe | app | Low-medium; telemetry loss if careless |
| 2 | Startup I/O | Profile profile dir init, SQLite (Room: recently-closed, downloads, crashes), cache warming on UFS | app + Gecko profile | Low |
| 3 | Memory | Long-session: tab suspension thresholds, image cache sizing, content-process count vs 8 GB RAM class | app settings / GV prefs | Medium; compatibility |
| 4 | GPU | WebRender settings, GPU process behavior on Adreno 640; verify GLES vs Vulkan defaults with Adreno 640 drivers on Android 10 | GV prefs (runtime) | Medium; driver bugs |
| 5 | Media | Verify HW codecs (H.264, HEVC, VP9) actually used via `MediaCodec` on OP7; force/fallback only if misdetected | GV prefs + `DeviceCapabilities` | Medium |
| 6 | Networking | DNS/HTTP3/TLS settings sanity on OxygenOS 10; no DNS-provider hard-coding | GV prefs | Low |
| 7 | Battery | Timer/wakeup audit on idle + background; avoid polling | app | Low |
| 8 | CPU/ARM64 | Confirm the fat AAR ships the right libs; no `-march=native`-style hacks (Gecko is prebuilt); Rust libs are prebuilt — only app-side JNI/D8/R8 settings can be tuned | build | Low |
| 9 | ABI | Ship arm64-v8a only → smaller APK, faster CI | build | Low |
| 10 | Cache/CI | Gradle + GV AAR caching to keep free-tier builds viable | CI | Low |

Layer rule: a problem in Gecko is fixed via runtime prefs or upstream patches, never by hacking the UI; a problem in Android lifecycle is fixed in app/A-C code, never by changing Gecko behavior to mask it.

---

## 12. Risks

1. **Free-runner limits** — a Fenix build takes a long time and GBs of storage; caching is mandatory and ABI scope should be arm64-only for OP7 builds. Risk of cache eviction or quota limits; pipeline must degrade gracefully (reports, not silent failure).
2. **Scheduled-workflow dormancy** — GitHub can disable scheduled workflows in public repos after ~60 days without activity. Mitigation: lightweight upstream check + build-on-push/manual dispatch + documented maintenance cadence (upstream releases monthly, which keeps the repo active).
3. **Upstream churn** — monthly Iceraven releases mean OP7 patches must be tiny and well-contained or every sync becomes a conflict. Mitigation: patch-per-concern, documented conflict protocol (stop, summarize, never overwrite).
4. **Device assumptions** — OP7 characteristics (SD855/SM8150, Adreno 640, Android 10/OxygenOS 10) are assumptions; `DeviceCapabilities` detection must be verified on the real device (`Build` fields, `ActivityManager.MemoryInfo`, `PackageManager` system features, `MediaCodecList`, `GLES`/`Vulkan` caps) before any device-aware behavior.
5. **Signing** — never commit keys; PR-triggered runs must never receive release secrets. Release signing only via protected environment secrets.
6. **Benchmark noise** — on-device measurements on a daily-driver phone are noisy; need fixed conditions (same build, screen brightness, airplane mode where relevant, multiple runs, medians) and a regression decision rule.
7. **Scope creep** — the temptation to "improve" upstream. Guard: every change must have a documented problem, root cause, expected benefit, and benchmark — otherwise it is rejected.
8. **Stale upstream references** — Iceraven's own README/`release.yml` contain stale bits (e.g. `assemblefenixForkRelease`); do not copy them blindly into OP7 automation.

---

## 13. Recommended implementation order

Maps to the mandated development phases; nothing is skipped or reordered.

| Phase | Work | Deliverable |
|---|---|---|
| 0 | Repository audit (this document) | `docs/op7-project-audit.md` |
| 1 | Record the unmodified upstream state: commit, versions, toolchain | `docs/baseline.md` + `upstream/commit.txt` |
| 2 | Define measurement methodology (cold/warm start, page load, scroll, memory, battery); first captures on a physical OnePlus 7 | `docs/performance/baseline.md`, `docs/performance/startup.md` |
| 3 | GitHub Actions reliability: caching, arm64-only build, APK/ABI validation, job summaries | `.github/workflows/op7-build.yml`, `ci.yml` |
| 4 | Automatic upstream detection + safe sync + conflict stop-and-report | `.github/workflows/upstream-check.yml`, `automation/op7/sync_upstream.sh` |
| 5 | `DeviceCapabilities` design (ABI, API, CPU, RAM, GPU/GLES/Vulkan, codecs, display) | `docs/oneplus7/device-capabilities.md`; later `DeviceCapabilities.kt` in app |
| 6 | Profiling on device; identify top bottlenecks; record in `docs/performance/` | profile captures + analysis |
| 7 | First measured optimization (smallest change that fixes the top measured bottleneck) | one patch in `patches/op7/` |
| 8 | Benchmark/regression loop: baseline → change → benchmark → compare → keep/revert | results in `docs/performance/` |
| 9 | Automated release pipeline: quality gates, signing, checksums, metadata, GitHub Release | `release` mode of `op7-build.yml` |
| 10 | Long-term upstream maintenance: monthly sync cadence, conflict playbook, issue automation | maintenance docs + bot behavior |

Phase gating rule (from the golden rule): **no optimization before Phase 1 baseline is recorded and Phase 2 methodology exists.**
