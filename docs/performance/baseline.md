# Iceraven OP7 — Performance Baseline Methodology (Phase 2)

Goal: a repeatable, comparable measurement protocol run on a **physical OnePlus 7**
(Snapdragon 855/SM8150, Adreno 640, Android 10). Benchmarks are only meaningful on the
real device; emulator/managed-device numbers are never used as release evidence.

## Device conditions (record every time)

- OnePlus 7, OxygenOS 10, same build number; GPS/Wi-Fi/Bluetooth fixed per test plan.
- Screen fixed brightness; airplane mode for CPU/startup tests where network is not the subject.
- Same Iceraven profile state: fresh profile for cold tests; identical seeded state for long-session tests.
- Phone idle for ≥ 2 minutes before each run; 3–5 repeats; report median + min/max.
- No benchmark-mode cheat flags; app must be the production `forkRelease` build (or the exact variant under test).

## Metrics and methods

| Metric | Method |
|---|---|
| Cold start (process → first page interactive) | `adb shell am start -W`; Perfetto trace; logcat markers |
| Warm start | `adb shell am start -W` after backgrounding (not killing) |
| First browser UI | Activity `onCreate` → `onResume` via Perfetto slices |
| First page load | Perfetto + `performance.timing`/WebDriver where available |
| Heavy page load (e.g. image-heavy, JS-heavy fixed URLs) | Perfetto; network waterfall |
| Scrolling | Macrobenchmark `ScrollBenchmark` (benchmark module); Perfetto frame timings |
| Tab switching | UI automation timing of switch + restore |
| Video playback (H.264/HEVC/VP9 fixtures) | playback stall counters + `MediaCodec` session logs |
| Memory (5/10 tabs, heavy pages, long session) | `adb shell dumpsys meminfo`, `ActivityManager.MemoryInfo`, Gecko memory reports (`about:memory` equivalents) |
| CPU / GPU behavior | Perfetto; `adb shell top`; GPU process counters |
| Background / battery | `adb shell dumpsys batterystats`, wakeup counters over fixed idle window |
| Downloads | timed download of fixed-size fixture over fixed network |

## Automated capture

`automation/op7/baseline_capture.sh` automates install, cold/warm start (`am start -W`),
memory, gfx, and battery capture into `docs/performance/data/<timestamp>/` when adb is
reachable. Run `baseline_capture.sh devices` first, then `all <apk>`.

## Capture artifacts

- Perfetto traces + `trace_processor` SQL summaries where practical.
- `dumpsys` outputs, benchmark JSON, screenshots/video for scrolling and startup.
- All raw data stored under `docs/performance/data/<date>-<op7rev>/` with a README describing conditions.
- A result table is appended to this file for every optimization: baseline value, optimized value, delta %, decision (keep/revert), and regression risk.

## Decision rule

- Improvement must be on the primary metric and not regress memory, battery, stability, or
  web compatibility beyond tolerance (±5% where measurable).
- Any optimization that improves one benchmark while damaging another is rejected until
  reworked. No exceptions.

## Results so far (Phase 2, 2026-08-13 — contended conditions)

| Metric | Baseline (r2, contended) | Method | Notes |
|---|---|---|---|
| Cold start (median) | 595 ms (575–617) | `am start -W`, COLD ×5, Shizuku | device in active use; re-capture when idle |
| Warm start | pending | HOME not available in proot env | needs adb or HOME-capable session |
| Memory (1 tab) | pending | `dumpsys meminfo` | blocked by transport flakiness during active use |
| gfxinfo / battery | pending | `dumpsys gfxinfo` / `batterystats` | idle window required |

Decision rule unchanged: no optimization without a clean baseline comparison.
