# Optimization Catalog — Phase 7 candidates (battery + smoothness + speed)

Grounded in the actual pinned source. Every candidate becomes **one revision**
with a before/after measurement; keep only if the primary metric improves and
memory/battery/stability/web-compat stay within ±5%. Never touch security knobs.

Main wiring point in this source: `app/src/main/java/org/mozilla/fenix/gecko/GeckoProvider.kt`
(`createRuntimeSettings`) — where `GeckoRuntimeSettings` is built. Runtime prefs
would be added via `GeckoRuntimeSettings.Builder().setRuntimePrefs(mapOf(...))`.

## Ranked candidates

| # | Candidate | Knob / location | Expected | Measurement | Risk |
|---|---|---|---|---|---|
| C1 | Hardware media codecs (battery: video) | ~~runtime pref~~ **VERIFIED r5: no change needed** | lower playback drain | done: `docs/performance/media.md` — GeckoView already selects OMX.qcom hw decoders for H.264/HEVC/VP9; peak decode CPU ~10 % | — |
| C2 | Background discipline (battery: screen-off) | verify/keep tab discard + timers; wakeups audit | near-silent background | overnight `drain` test + `wakeups` | low-medium; keep privacy intact |
| C3 | Content-process count on 8 GB | `GeckoRuntimeSettings.setContentProcessHint(n)` / `dom.ipc.processCount` | faster tab switch; smoother under load | meminfo 5/10 tabs + tab-switch timing | medium; more processes = more RAM/power if over-tuned |
| C4 | Memory stability (smoothness) | image cache / GC pressure; discard policy | fewer GC stalls → less jank | scroll jank on image-heavy pages + meminfo over long session | low |
| C5 | Renderer backend/settings (smoothness) | runtime prefs `gfx.webrender.*` (benchmark, don't assume) | frame pacing | Perfetto frame timings / gfxinfo framestats | medium; needs adb |
| C6 | Startup: defer non-critical init | startup stage audit (pattern exists: `initializeEmojiCompat` on IO) | cold start 600→~450 ms | stage timings (`am start -W` + Perfetto) | low-medium; keep first-paint budget |

## Never-touch list (security/architecture — speed is not worth these)

- `fissionEnabled` (site isolation), `isolatedProcessEnabled`, `extensionsProcessEnabled`
- Tracking/content-blocking policy, safe browsing, certificate validation
- `-march=native` / hard-coded CPU instructions
- Disabling HTTPS, sandboxing, or permission model

## "Feels like a system app" — honest scope

Feasible without root:
- Fast cold start (C6), zero background drain (C2), smooth scrolling (C4/C5)
- Default-browser deep links (already present via patched scheme; user set-default prompt)
- No ANRs / stable long sessions (C3/C4)

Not feasible on this device without root/bootloader unlock:
- Privileged system-app install (`/system` or `/product` partition, signature-level grants)
- OTA-level integration

Decision: chase the *feel* (snappy, silent, integrated), not the install location.

## Measurement infra needed (Phase 6)

- `automation/op7/baseline_capture.sh drain <minutes>` — screen-off drain (done)
- `... wakeups <file>` — wakeup summary (done)
- `... gfx` — frame stats (done, small sample)
- Pending: Perfetto frame traces + `gfxinfo --framestats` (needs adb or a HOME-capable session)
- Pending: media playback drain fixtures (fixed H.264/HEVC/VP9 URLs)

## Revision plan (one candidate each)

- r4 = 004 seamless launch (perceived-performance sugar, cosmetic) — shipped
- r5 = C1 — **done (verification only): hardware decode already active, no change shipped** (`docs/performance/media.md`)
- r6 = C2 (background discipline)
- r7 = C6 or C4 (startup or memory/smoothness) — after profiling
- r8+ = remaining, each gated on the previous measurement

## "Premium / system-app feel" — definition and how we deliver it

Feel is a set of measurable behaviors, not a vibe. Each feel item maps to a
metric and a revision:

| Feel | Metric | Delivery (revision) |
|---|---|---|
| Opens instantly | cold-start TotalTime | C6 (startup deferral) |
| No white flash on launch | splash theme + first-frame time | already correct in source (`SplashScreenThemeBase`, splash bg color) — verify once, no patch needed |
| Scrolls buttery, no dropped frames | scroll jank %, 50/90th frame times | C4/C5 (memory + renderer) |
| Switch tabs without waiting | tab-switch + restore time | C3 (content-process policy) |
| Returning to the app never reloads | process-survival: background 10 min → resume vs reload | C4 (memory so LMK doesn't kill it) |
| No jank under load (5-10 tabs, heavy pages) | meminfo + jank on seeded session | C3/C4 |
| Feels integrated | default-browser deep links, dark mode, gesture nav, media notification | already present in Fenix; verify on-device |
| Stability = premium | crash/ANR rate per release | crash handler already present; report crashes in release notes |

Already-verified-good in this source (no patch needed): splash theme with themed
background, dark mode, gesture navigation, deep links, media session
notification, isolated content processes, extensions support.

Rule: a feel item ships only when its metric is measured before/after. Cosmetic
"feel" claims without a metric are rejected.
