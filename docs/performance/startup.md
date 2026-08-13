# Iceraven OP7 — Startup Stage Map (Phase 6 input)

Breaks startup into stages so profiling targets the right layer. Extends upstream
`docs/startup-performance.md` with OP7-specific capture points.

```
Android process start
   → Zygote fork / Application attach (system)
   → FenixApplication.onCreate
       • crash reporter
       • Nimbus (megazord/Rust)
       • GeckoEngine warmUp()
       • BrowserStore
       • Glean
       • web extension support
       • BrowsersCache / app services providers
       • push setup
   → IntentReceiverActivity / HomeActivity
       • BrowserFragment.onCreateView
       • tab preview, toolbar view init
       • first UI frame
   → GeckoRuntime init (from AAR; prefs applied here)
       • profile init (I/O)
       • Gecko thread start, GPU process, content process
   → first page (navigation commit → first paint)
```

## Capture points on the OnePlus 7

- `adb shell am start -W` cold/warm totals (first 3 runs discarded as warmup).
- Perfetto `tracing` for slices across `FenixApplication`, `HomeActivity`, `BrowserFragment`, `GeckoRuntime`.
- Logcat markers already emitted by Fenix (`STARTUP_*`-style tags) plus `Gecko` process logs.
- `dumpsys activity` for process start overhead on OxygenOS 10.

## Optimization rule for startup

- Only touch stages shown by profiles to be expensive on the OP7.
- Never move security-relevant or privacy-relevant init (e.g. certificate/data protection) later for a startup win.
- Record every change with before/after numbers in `docs/performance/baseline.md`.

## Results — 2026-08-13 (r4, re-measurement; device in active use = contended)

Verdict: **no change justified by this data.** Cold start median moved
~595 ms (r2) → ~697 ms (r4), but the run was contended and the delta is
within noise; a clean idle-window re-run is the honest gate before any
startup change.

| Run | r2 baseline (2026-08-13) | r4 re-measure (2026-08-13) |
|---|---|---|
| cold start TotalTime | 575–617 ms (median 595) | 679, 695, 699, 731 ms (median ~697) |

Method: `am force-stop` + 3 s settle + `am start -W -n .../.App`, `LaunchState:
COLD` verified each run. Note: rapid force-stop→start sequences hit Binder
`Failed transaction (2147483646)` under contention; the 3 s settle avoids it
(field note D26).

### Stage timeline (one cold run, logcat)

```
GeckoRuntime: Lifecycle: onCreate
  → OP7Capabilities (Phase 5 probe, one-shot)        ~+0.22 s
  → GeckoViewStartup: app-startup
  → profile-after-change (profile I/O)
  → SetLocale / ResetUserPrefs / SetDefaultPrefs
  → Lifecycle: onStart / onResume
  → StartupTypeTelemetry: cold_unknown
  → content-process-ready-for-script
  → GeckoSession: chrome startup finished            ~+1.0 s
  → MozAfterPaint (first content paint, session restore) ~+1.3 s
```

- The Phase 5 `DeviceCapabilities` probe runs once during init and logs its
  result; it is a few ms of Java reflection, not a startup bottleneck.
- First *content* paint trails the activity frame by ~1 s because the session
  restore path (tabs from the previous run) must init first — this is the
  visible "feel" gap on cold start.

### Interpretation

- 595 → 697 ms is +17 % on a contended daily driver with small samples; not
  treated as a regression yet (r2 was also labeled "device active").
- No startup optimization ships without a clean-window baseline. If the user
  grants an idle window, re-run 5× with nothing else running; only then
  compare to the 450 ms stretch target in the catalog.
