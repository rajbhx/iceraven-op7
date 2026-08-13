# Iceraven OP7 — C2 runbook: background discipline (battery, screen-off)

Goal: prove the browser is (or make it) near-silent in the background — the
biggest "system app" battery win. Needs one ~30 min idle window on the device
(no touches, screen off). All commands are Shizuku-ready.

## Protocol (run in order, one idle window)

### Phase A — baseline (current r4, no changes)
1. Make sure Iceraven is the last thing used, with a few tabs open, then
   background it (Home) and lock the screen.
2. Reset stats: `baseline_capture.sh battery-start`
3. Wait 30 min untouched (screen off, no notifications interactions).
4. Wake: `baseline_capture.sh battery-stop drain-base`
5. `baseline_capture.sh wakeups drain-base.txt` — extract discharge + wakeup lines.

Success criteria for baseline sanity: discharge during screen-off < ~1%/h and
Iceraven wakeups near zero. If baseline already good → C2 = verify-only
(no change), like C1/C3.

### Phase B — fix only if baseline shows a problem
Measured problem → pick the smallest knob, one revision:
- Tab timers waking the device → verify tab discard / throttling prefs are on
  (Gecko runtime prefs; never touch privacy/security knobs).
- Push/websocket wakeups → user-facing setting documentation, not a code hack.
- Process churn in background → re-check C3 data (process count is capped at 3).

### Phase C — verify the fix
Repeat Phase A with the new build (r6). Keep only if discharge/wakeups improve
and cold start + memory stay within ±5%.

## What counts as success
- Screen-off drain delta between baseline and fix, per `dumpsys batterystats`
  (`Discharge: ...` and `Screen off/doze discharge`), plus per-package wakeup
  lines for `io.github.forkmaintainers.iceraven.op7`.
- Honest label: single-window, user device, real-world noise — treat ±20% as
  noise; only large deltas (≥2x wakeup reduction) count.

## Anti-goals (never)
- Killing Gecko security (site isolation, HTTPS, sandboxing).
- Forcing aggressive doze behavior that breaks tabs, push, or downloads.
- Optimizing for synthetic benchmarks over real overnight behavior.
