# Session digest — 2026-08-13 — C2: background discipline baseline

## Problems solved
- **P** prove the browser is (or make it) silent in the background — the "system app" battery win
  cause: no background-behavior baseline existed; optimization without a measured problem is banned
  solution: 30-min idle window (screen off, no touches), `baseline_capture.sh battery-start/battery-stop`, history + live summary via Shizuku; verdict = verify-only if already quiet
  section: D
  tags: battery, background, wakeups, c2
- **P** full batterystats (472 KB) truncates via Shizuku (~400 KB cap)
  cause: long dumpsys output cut mid-file; summary section lost, only history section stored
  solution: capture summary lines live with targeted greps (capacity/discharge/screen-off); store history section as raw evidence; label truncation in the doc (D9)
  section: D
  tags: measurement, batterystats, truncation, constraint

## Outcome
- Iceraven wakeups during idle window: 0 (u0a262 history marker only). Wakeups came from WhatsApp/chat/Instagram/Play/GMS.
- Screen-off discharge 17.3 mAh ≈ 0.43 %/h at 3700 mAh. Total 30.1 mAh over ~40 min.
- C2 verdict: verify-only, no code change. No r6 needed for background behavior. Runbook kept for post-sync regression checks.
