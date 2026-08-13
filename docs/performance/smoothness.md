# Iceraven OP7 — C4/C5: smoothness baseline (frame timing)

**Verdict: baseline captured with the correct tool (SurfaceFlinger latency);
no code change yet. Synthetic stress page shows real periodic ~200 ms
main-thread stalls; typical frame interval is 1 vsync (16.7 ms) when not
stalling. Real-page gesture baseline still pending (needs a foreground
window on a real site).**

## Tooling (important correction)

- `dumpsys gfxinfo <pkg> framestats` measures **only the main process** — the
  browser chrome. WebRender page content renders in the `:tab_*` (content) and
  `:gpu` processes, so page-scroll frames never appear in gfxinfo for the
  package (observed: 0 frames while the page was actively scrolling).
- The correct compositor-level measure is
  `dumpsys SurfaceFlinger --latency "<package>/<activity>#0"`:
  line 1 = refresh period (16 666 666 ns = 60 Hz), then one row per presented
  frame `desired actual ready` (ns). Inter-frame deltas of `actual` ≈ refresh
  = smooth; larger deltas during *active animation* = stalls.
- Caveat: idle gaps (no animation) legitimately produce large deltas — those
  are not jank. Only judge deltas while continuous motion is happening.

## Method (2026-08-13, r4 installed, Shizuku transport)

1. Fixture `media-fixtures/test-scroll.html` (+ alias `s.html`) — 220 sections
   with gradient boxes (heavy DOM), served from `127.0.0.1:8790` (must be
   `text/html`; extensionless aliases render blank — see field note D22).
2. Run A (stress): the page auto-scrolls via `requestAnimationFrame`
   (`scrollBy(0,40)` per frame) and beacons `scrollY` every 2 s to the local
   server (proves continuous motion). SurfaceFlinger latency captured while
   scrolling.
3. Run B (gesture): 10 `input swipe` gestures while the page is foreground,
   then the same SurfaceFlinger capture.

## Results

| Run | Presented frames | p50 interval | max interval | >1 vsync (18.3 ms) | Notes |
|---|---|---|---|---|---|
| A auto-scroll (stress) | 7 | 16.7 ms | 199.8 ms | 3 (43 %) | continuous motion → stalls are real |
| B gestures | 12 | 16.7 ms | 199.8 ms | 3 (25 %) | gaps overlap swipe-idle periods → not all jank |
| B main-process gfxinfo | 7 | 5 ms | 10 ms | 0 | chrome UI is smooth |

- Typical frame interval when frames are flowing: **1 vsync (16.7 ms)** — the
  compositor is hitting 60 Hz.
- Periodic **~200 ms stalls** (≈12 vsyncs) appear in continuous JS-driven
  scroll on the heavy page: main-thread stalls (layout/paint of the 220
  gradient layers). This is the stress signal to watch.

## Interpretation

- The heavy synthetic page is a worst case (JS scroll forces main-thread
  layout per frame; real gesture scroll uses compositor-only scrolling). It is
  a useful **upper bound** reference, not the user's everyday experience.
- Chrome UI rendering is smooth (0 % jank, p50 5 ms).
- No change shipped. C4/C5 verdict = baseline measured; the stall pattern on
  heavy content is the candidate target for a future measured optimization
  (e.g., if C4 memory/GC work reduces it).

## Pending / next runs
- Real-page gesture baseline: open a real site in the foreground (user paste)
  and repeat Run B — network variance aside, this is the user's actual feel.
- Longer capture for more frames (SF latency ring is ~127 rows; capture during
  a continuous scroll pass, not between gestures).

## Raw data
- `docs/performance/data/20260813-c45-smoothness/sf-latency-auto.txt` (Run A)
- `docs/performance/data/20260813-c45-smoothness/sf-latency-gesture.txt` (Run B)
- `docs/performance/data/20260813-c45-smoothness/beacons-scroll.log` (Run A motion proof)
