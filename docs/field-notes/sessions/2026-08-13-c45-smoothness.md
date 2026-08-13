# Session digest — 2026-08-13 — C4/C5: smoothness baseline

## Problems solved
- **P** gfxinfo framestats showed 0 frames while the page was clearly scrolling
  cause: gfxinfo only measures the main process; WebRender content renders in :tab_* / :gpu processes
  solution: use `dumpsys SurfaceFlinger --latency "<pkg>/<activity>#0"`; judge deltas only during continuous motion
  section: D
  tags: smoothness, surfaceflinger, measurement
- **P** alias URL http://127.0.0.1:8790/s rendered blank (200 fetch, no JS, no content)
  cause: extensionless file served as application/octet-stream; Gecko won't render it as HTML
  solution: give fixtures .html extensions; verify Content-Type before testing (D22)
  section: D
  tags: mime, fixtures, http, debugging
- **P** intent-opened URL tab never ran JS (background tab suspends rAF/timers)
  cause: cold start with VIEW intent restores the old session in front; the URL tab sits in the background
  solution: user paste in the address bar (foreground load) or chooser route; treat background tabs as frozen (D24)
  section: D
  tags: tabs, intent, background, foreground
- **P** self-driven swipes hit the wrong app when the user switched to chat mid-test
  cause: input swipe injects globally; foreground was the chat app during the swipe window
  solution: atomic bring-to-front + swipe + capture chains; auto-scrolling fixture pages (rAF + beacons) remove gesture timing entirely
  section: D
  tags: automation, input, swipe, contention

## Outcome
- C4/C5 baseline captured: typical frame interval 1 vsync (16.7 ms); periodic ~200 ms stalls on the heavy synthetic page (real under continuous JS scroll); chrome UI smooth (p50 5 ms, 0 % jank).
- No code change shipped. Real-page gesture baseline pending.
- Fixture tooling: test-scroll.html (+ s.html auto-scroll), test-scroll2.html (+ s2.html static), sc-/sc2- beacons.

## Addendum — real-page gesture baseline (correct layer)
- Problem: earlier smoothness numbers used the wrong SF layer (HomeActivity#0 = chrome), giving fake 43%/25% jank; the web content renders in the SurfaceView child layer.
- Fix: capture `SurfaceFlinger --latency "SurfaceView - <pkg>/<activity>#0"` (D25).
- Result (github.com/rajbhx/iceraven-op7, 10 real swipes, foreground): 126 frames, p50 16.65 ms, p95 17.17 ms, 4.8% >1 vsync, max 283 ms → smooth 60 Hz baseline; chrome gfxinfo 24% jank (chrome-only, not content).
- Verdict: C4/C5 = no code change; retracted the wrong-layer numbers in docs/performance/smoothness.md.
