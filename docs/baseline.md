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
