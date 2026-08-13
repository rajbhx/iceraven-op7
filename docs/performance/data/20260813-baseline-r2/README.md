# Baseline capture — 2026-08-13 (OP7 revision 2)

- Device: OnePlus 7 (GM1901), Snapdragon 855/SM8150, arm64-v8a, Android 10 (OxygenOS 10)
- Build under test: `iceraven-2.46.0-op7r2` (versionCode 2016178394),
  installed via Shizuku `pm install -r` from `/data/local/tmp/op7r2.apk`
- Transport: Shizuku (`OP7_TRANSPORT=shizuku`), no adb
- Conditions: **device in active user use during capture** — these are
  contended numbers, NOT a clean idle baseline. A clean re-capture during an
  idle window is required before Phase 7 optimization decisions.
- Profile: existing r2 profile (not fresh)
- Metrics: cold start via `am start -W` (LaunchState COLD only)
