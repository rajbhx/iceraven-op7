# Iceraven OP7 — Phase 6 profiling (revision r4)

Captured 2026-08-13 on the OnePlus 7 (GM1901, Android 10) via **Shizuku-only**
transport (no adb). App: `iceraven-2.46.0-op7r4` (patches 001–004 applied;
004 is cosmetic splash-only). **All numbers are CONTENDED** — the phone was in
regular use during the sweep. Treat them as gross signal, not release gates.

Tooling added in Phase 6 (all Shizuku-capable):
- `baseline_capture.sh profile` — sweep: cold-start ×3, mem 1 tab, framestats,
  procstats (short; long drains need an idle window)
- `baseline_capture.sh framestats | procstats | cpu | page-load`
- `automation/op7/framestats_analyze.py` — frame-time stats from
  `dumpsys gfxinfo <pkg> framestats`

## Results (contended, n as noted)

### Cold start (`am start -W`, COLD-validated)
| Run | TotalTime (ms) |
|---|---|
| 1 | 714 |
| 2 | 828 |
| 3 | 707 |
Median **714 ms**, avg **750 ms**. r2b baseline (also contended) was ~603 ms —
n=3 is too small to call a regression; re-measure on an idle window (C6).

### Memory (`dumpsys meminfo`, 1 tab, foreground)
- TOTAL PSS **~198 MB** (202,853 KB). r2b 1-tab was ~152 MB — session state
  differed (foreground vs captured state); re-measure under identical conditions.
- Java heap 14 MB, native heap 21 MB (small; Gecko native dominates PSS).

### GPU / frames (`framestats`, launch + 3 swipes)
- 13 frames: avg **11.9 ms**, p50 8.5, p90 19.4, p95 28.5, max 28.5 ms
- Janky (>16.7 ms): **4/13 (30.8%)** — contended scroll, tiny sample.

### Processes (C3 data)
| Process | RES |
|---|---|
| main | 352 MB |
| gpu | 165 MB |
| crashhelper | 109 MB |
| tab ×3 | 171–312 MB each |

6 live processes while browsing = main + gpu + crashhelper + 3 content procs.
procstats (current): main avg PSS ~212 MB (197–225 range), crashhelper ~9.9 MB.
Note: process names carry the upstream `_disable_art_image_` suffix (Iceraven
patch-layer behavior, not an OP7 change).

## Not measured here (needs adb or an idle window)
- Warm start (HOME key no-op in proot; field note D7)
- Clean screen-off drain + wakeup audit (needs untouched idle window)
- Perfetto frame traces (needs adb)
- Precise page-load markers (logcat-only approximation; needs adb timing)
- Media playback drain fixtures (r5 plan: fixed H.264/HEVC/VP9 URLs)

## Measured signals → Phase 7 queue (one revision per candidate)
- **C1 hardware codecs (r5)**: Phase 5 confirmed hw H.264/HEVC/VP8/VP9 decoders;
  verify GeckoView actually uses them during playback (logcat MediaCodec
  markers) before any preference change.
- **C2 background discipline (r6)**: needs the idle-window drain/wakeups first.
- **C3 content-process count**: 3 tab procs ≈ 170–312 MB each is the biggest
  memory lever; tuning must be benchmarked (tab-switch + mem 5/10 tabs).
- **C4/C5 smoothness**: re-run framestats on an idle window; 30.8% jank here is
  contended, not a verdict.
- **C6 startup**: re-measure cold start cleanly before optimizing (r2b 603 vs
  r4 714 are both contended).

## Honest status
Phase 6 infra is complete and reusable; the numbers above are **contended
signal only**. A clean release-grade baseline requires an idle device window
(~15–30 min untouched) for cold-start n=10, drain/wakeups, and framestats.
