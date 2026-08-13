# C5 layer verification — real WebRender content layer

Captured 2026-08-13 on the OnePlus 7 (GM1901), r4 build foreground with 9 tabs.

- `sf-layers.txt` — `dumpsys SurfaceFlinger --list` for the Iceraven task + gfxinfo
  snapshot. Confirms the real WebRender content layer is
  `SurfaceView - io.github.forkmaintainers.iceraven.op7/HomeActivity#0`
  (the SurfaceView under the activity's `#0` window layer).
- COLD launch via `am start -W`: TotalTime 728 ms (contended; matches C6).
- Lesson (field note D25): gfxinfo reports the **main process** (UI thread only);
  for content-layer frame timing use SurfaceFlinger latency on the SurfaceView
  layer. The earlier "wrong-layer" C4/C5 numbers were retracted in
  `docs/performance/smoothness.md`.
