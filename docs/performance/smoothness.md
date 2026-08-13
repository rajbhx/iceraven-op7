# Iceraven OP7 — C4/C5: smoothness baseline (frame timing)

**Verdict: real-page gesture scrolling is smooth — 60 Hz with 4.8 % of frames
over one vsync. No code change needed. (Earlier wrong-layer numbers retracted.)**

## Tooling (corrected — read this first)

- `dumpsys gfxinfo <pkg> framestats` measures **only the main process**
  (browser chrome). WebRender content renders in `:tab_*` / `:gpu` processes.
- The web content is composited into the **SurfaceView child layer**, not the
  activity's `#0` layer. Correct measurement:
  `dumpsys SurfaceFlinger --latency "SurfaceView - <pkg>/<activity>#0"`.
  The `...HomeActivity#0` layer only reflects chrome updates (sparse frames,
  misleading jank numbers — field note D25).
- SF latency format: line 1 = refresh ns (16 666 666 = 60 Hz), then
  `desired actual ready` per presented frame. Judge deltas during continuous
  motion; idle gaps are not jank.

## Results (2026-08-13, r4 installed, Shizuku transport)

### Real page + real gestures (the representative number)
Page: `https://github.com/rajbhx/iceraven-op7`, 10 `input swipe` gestures
(540,1700→540,400, 120 ms), browser foreground throughout.

| Surface | Frames | p50 | p90 | p95 | max | >1 vsync |
|---|---|---|---|---|---|---|
| SurfaceView (web content) | 126 | 16.65 ms | 16.73 ms | 17.17 ms | 282.91 ms | 6 (4.8 %) |
| main-process gfxinfo (chrome) | 58 | 9 ms | 29 ms | 34 ms | 61 ms | 13 (24 %) |

- Web content: median frame interval = **one vsync (16.65 ms → 60 Hz)**; only
  4.8 % of presented frames exceeded one vsync. Single worst stall 283 ms.
- Chrome UI: 24 % of frames over one vsync during scroll feedback (toolbar /
  overscroll) — chrome-only, not content.

### Retracted (wrong layer)
Earlier captures used `...HomeActivity#0` (chrome surface): "7 frames / 43 %
janky (stress)" and "12 frames / 25 % (gesture)" are **invalid** — the web
content never appears there. Do not compare against them.

## Interpretation

- On a real page with real gestures, GeckoView WebRender presents at 60 Hz
  with ~5 % jank on this device — a healthy baseline. Nothing to fix at the
  renderer level (C5: no `gfx.webrender.*` changes justified by this data).
- C4 (memory/GC): the 283 ms worst stall and the 4.8 % >1-vsync share are the
  future comparison targets if a memory/GC optimization is ever proposed —
  but no change ships without a measured regression baseline.

## Pending
- Longer real-page session (2+ min continuous scrolling) for a larger sample.
- Overnight-type long-session jank check after heavy use (C4 long-session).

## Raw data
- `docs/performance/data/20260813-c45-smoothness/sf-latency-real-github-surfaceview.txt`
- `docs/performance/data/20260813-c45-smoothness/sf-latency-auto.txt` (stress — wrong layer, retained only as a retraction record)
- `docs/performance/data/20260813-c45-smoothness/beacons-scroll.log` (fixture motion proof)
