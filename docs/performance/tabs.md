# Iceraven OP7 — C3: content-process count vs tabs (verified)

**Verdict: no change needed.** GeckoView's content-process cap already prevents
memory from scaling with tab count; on this 8 GB device there is no memory
pressure to optimize.

## Method (2026-08-13, r4 installed, Shizuku transport)

Collaborative session: user opened 3 / 6 / 10 tabs by hand in Iceraven;
`baseline_capture.sh state <n>tabs` captured `dumpsys meminfo` + process list
at each settled state (no force-stop between captures). The app restarted once
mid-test (no crash logged) — only settled states are used. Data:
`docs/performance/data/20260813-tabs-r4/`.

| Tabs (settled) | TOTAL PSS | Content processes | tab proc RES range |
|---|---|---|---|
| 3 | 241 MB | 3 | 176–277 MB |
| 6 | 273 MB | 3 | 173–403 MB |
| 10 | 265 MB | 3 | 173–477 MB |

Steady-state: main ~270–320 MB, gpu ~170–190 MB, crashhelper ~102 MB, plus
3 content processes. 3→10 tabs changed total memory only 241→265 MB.

## Interpretation

- GeckoView keeps at most ~3 resident content processes; additional tabs are
  restored on demand (not resident), so **memory scales with process count,
  not tab count**.
- Total browser footprint at 10 tabs ≈ 1.3 GB in a 7.3 GB-RAM device — no
  pressure. Forcing a lower cap (e.g. `dom.ipc.processCount=2`) would trade
  tab isolation/restore speed for ~150–450 MB that this device doesn't need.
- Raising the cap would add RAM + wakeups for no measured benefit.

## Consequence for the optimization plan

- C3 → **verify-only, no code change shipped** (same outcome as C1).
- Remaining candidates: C2 (background discipline — needs idle window),
  C6 (startup), C4/C5 (smoothness — idle framestats), C3=done.
- Note: Fenix "Remote debugging via USB" (devtools) is enabled in settings —
  a possible future measurement channel (GeckoView devtools protocol) if we
  can reach the device-local port without adb.
