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
