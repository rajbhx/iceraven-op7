# Iceraven OP7 — Baseline (Phase 1)

The golden rule: **no optimization before the unmodified upstream build is recorded and
reproducible.**

## Baseline record

Populated on first successful unmodified build (Phase 1). Every field is required.

| Field | Value |
|---|---|
| Upstream repository | `https://github.com/fork-maintainers/iceraven-browser` |
| Upstream branch | `iceraven` |
| Upstream commit | _(set by sync: `upstream/commit.txt`)_ |
| Iceraven version | `153.0` (`version.txt`) |
| Iceraven release tag | `iceraven-2.46.0` (last known-good) |
| GeckoView artifact | `org.mozilla.geckoview:geckoview-omni:153.0.20260715202819` |
| Android Components version | `153.0` (A-C submodule commit pin) |
| Gradle | `9.5.1` (wrapper sha256 pinned) |
| JDK | 17 (Temurin, per CI) |
| Android SDK | sdkmanager-installed; build-tools `36.0.0`; NDK `29.0.14206865` |
| compileSdk / targetSdk / minSdk | 37.0 / 36 / 26 |
| Native architecture(s) built | arm64-v8a (OP7), upstream also armeabi-v7a + x86_64 |
| Build variant | `forkRelease` |
| Build command | `./gradlew app:assembleForkRelease -PversionName=<tag>` |
| APK output | `gradle/build/app/outputs/apk/forkRelease/app-arm64-v8a-forkRelease.apk` |
| APK SHA-256 | _(recorded by pipeline)_ |
| Baseline date + environment | _(recorded by pipeline)_ |

## Verification checklist

- [ ] Checkout of the pinned upstream commit reproduces the APK bit-for-bit-signature-wise (unsigned) from the documented command.
- [ ] `aapt dump badging` shows expected package, min/target SDK, and `native-code: 'arm64-v8a'`.
- [ ] No OP7 patches applied during baseline capture.
- [ ] Baseline artifacts archived with checksums (`docs/performance/baseline.md` keeps the measurement side).

## Change procedure

1. Update `upstream/commit.txt` only via `automation/op7/sync_upstream.sh`.
2. Re-capture the baseline measurements before evaluating any optimization.
3. Any optimization must reference this baseline in its benchmark result.

## Phase 2 — first on-device measurement (2026-08-13)

- APK installed via Shizuku `pm install -r`; verified `primaryCpuAbi=arm64-v8a`,
  `versionCode=2016178394`, `versionName=iceraven-2.46.0-op7r2`, not testOnly.
- Cold start (`am start -W`, LaunchState COLD, 5 runs): **median 595 ms**
  (min 575, max 617) — **contended** (device in active use, Shizuku transport,
  existing profile). Not a clean idle baseline.
- Raw data: `docs/performance/data/20260813-baseline-r2/` and
  `docs/performance/data/20260813-baseline-r2b/`.
- Second batch (r2b, still contended): cold-start median **615 ms** (601-727),
  memory TOTAL PSS **~152 MB** (1 tab), gfxinfo first-render 8 frames
  (37.5% janky, p50 12 ms), battery session discharge 15.6 mAh (partial capture).
- Gap: warm start needs a HOME-capable session (adb preferred); clean idle
  re-capture + full batterystats pending an idle window.
