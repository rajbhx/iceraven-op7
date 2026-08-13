# Baseline capture — 2026-08-13 (OP7 revision 2, batch b)

- Build under test: `iceraven-2.46.0-op7r2` (versionCode 2016178394), arm64-v8a
- Transport: Shizuku (`OP7_TRANSPORT=shizuku`), no adb
- Conditions: **contended** — device in active user use, assistant app
  foreground, existing r2 profile. Not a clean idle baseline; re-capture
  during an idle window before Phase-7 optimization decisions.

## Results (raw files in this dir)

### Cold start (`am start -W`, LaunchState COLD ×5)
727, 623, 601, 615, 614 ms → **median 615**, min 601, max 727
(pool with first batch: n=10, median ~603, min 575, max 727)

### Memory (1 tab / home screen)
TOTAL PSS **156,076 KB (~152 MB)**; Java Heap 10,244 KB; Native Heap 21,888 KB;
Graphics 2,320 KB. (Lower than the earlier contended 228 MB reading; fresh
launch, single tab.)

### gfxinfo (first-render session, small sample)
8 frames, 3 janky (37.5%), p50 12 ms, p90/95/99 150 ms, 2 missed vsync,
3 slow UI thread. Preliminary only — a real scroll session is needed.

### Battery (session snapshot, ~15 min, screen-on activity)
Discharge 15.6 mAh (screen-on), 0 mAh screen-off. Estimated capacity 3700 mAh.
Capture truncated at 82% (327,677/401,406 B) by the Shizuku pull race — summary
section intact. Preliminary; a fixed idle window is required for Phase-2 battery.

## Known gaps (transport limitations, documented in docs/02... playbook)
- Warm start: HOME no-op in proot env; `am finish` and `am task
  move-task-to-back` unknown on this Android build → needs adb or a
  HOME-capable session.
- Large `dumpsys` outputs (>~40 KB) only partially pull through the Shizuku
  wrapper; use chunked/MediaStore paths or adb for full captures.
