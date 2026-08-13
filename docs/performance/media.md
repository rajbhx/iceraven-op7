# Iceraven OP7 — C1: hardware media codec verification (corrected)

**Verdict: GeckoView uses Qualcomm hardware video decoders for AVC, HEVC, and
VP9 on this device. No preference change needed — but the original r5
"verification" was retracted and redone properly (see Correction below).**

## Correction (2026-08-13, honest re-test)

The earlier r5 report claimed C1 verified from `HardwareCodecCapability`
decoder selection logs + low decode CPU. That evidence only proved the
decoders *exist*, not that video actually *played* — the probe clip URLs were
404, so no decode session ever ran. The user's challenge ("I never see playing
video while texting") was correct. Retracted: `docs/performance/data/20260813-media-probe-r4/`
method does **not** prove playback.

## Verified method (2026-08-13, r4 installed, Shizuku transport)

1. Fixture pages in `media-fixtures/` (`test-suite.html`) play three 1080p30
   10 s looping clips **simultaneously and muted-autoplay**, served from a
   local `127.0.0.1:8790` HTTP server (proot shares loopback with the device).
   - AVC: `test-videos.co.uk .../mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4`
   - HEVC: `test-videos.co.uk .../mp4/h265/1080/Big_Buck_Bunny_1080_10s_1MB.mp4`
   - VP9:  `test-videos.co.uk .../webm/vp9/1080/Big_Buck_Bunny_1080_10s_1MB.webm`
   (The original 30 s/10 MB URLs were 404; the 10 s/1 MB variants return 200.)
2. Each page beacons `/s-<codec>-t=<tenths>/<readyState>/<p|r>` every 2 s to
   the local server; the server log is the **independent playback record**
   (`currentTime` must advance).
3. While playing, logcat is captured for live `MediaCodec` sessions.

## Evidence (raw)

- Beacons: `docs/performance/data/20260813-c1-suite/server-beacons.log`
  (21 advancing beacons per codec, `readyState=4`, `/r` running)
- Decoders: `docs/performance/data/20260813-c1-suite/decoders-logcat.txt`
- AVC single-codec first pass: `docs/performance/data/20260813-c1-avc/`

| Codec | Active session (logcat, 22:10:09–10) | Playback proof |
|---|---|---|
| AVC | `OMX.qcom.video.decoder.avc` — `component_init success fd=8`, surface gen 29707270 | t=19→39→59→79→99 looping |
| HEVC | `OMX.qcom.video.decoder.hevc` — `component_init success fd=89`, surface gen 29707272 | t=10→30→51→70→90 advancing |
| VP9 | `OMX.qcom.video.decoder.vp9` — `component_init success fd=15`, surface gen 29707271 | t=16→36→56→76→96 advancing |

All sessions in browser media process pid 29011 (`:media`), decoder instances
in Qualcomm media HAL pid 1106 (`android.hardwar`), `MediaCodec` async mode,
`useAndroidNativeBuffer` supported → frames go through gralloc to the
WebRender/GPU compositor.

## Interpretation

- GeckoView's MediaCodec pipeline selects the Qualcomm hardware decoders for
  all three web codecs; nothing to enable or override.
- Candidate knob `media.hardware-video-decoding.enabled` — no change needed.

## Consequence for the optimization plan

- C1 → **no code change; measured baseline answer confirmed with real
  playback evidence**.
- r5 verdict stands only in substance (hardware decode is active), now with
  proof; the r5 *method* is superseded by this fixture-beacon approach.
- Next candidates unchanged: C2 (background discipline), C6 (startup),
  C3 (content-process count), C4/C5 (smoothness).

## Field observations (from the re-test)

- Muted video in a **background tab is paused** by Gecko (decoder deinit on
  background, beacon gap) — correct energy behavior, relevant to C2.
- Audible video continues playing in the background (sound = active media),
  keeping the decoder alive.
- A VIEW intent on an already-running Fenix task logs "Activity not started"
  and does **not** deliver the URL (new tab was never fetched); cold-start
  (`am force-stop` + start) or chooser resolution delivers reliably.
- Background tabs don't fetch/play until foregrounded.
