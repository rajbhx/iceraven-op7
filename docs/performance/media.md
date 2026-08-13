# Iceraven OP7 — r5 (C1): hardware media codec verification

**Verdict: GeckoView already uses hardware video decoding on this device.
No preference change needed (C1 = verified).**

## Method (2026-08-13, r4 installed, Shizuku transport)

`automation/op7/media_probe.sh <label> <url>` — force-stop app, clear logcat,
open a direct 1080p30 10 MB clip in Iceraven, sample `top` every 4 s during
playback, then dump logcat + `dumpsys media.player` / `dumpsys media.codec`.
Evidence = GeckoView's own `HardwareCodecCapability` decoder selection +
decode CPU. Data: `docs/performance/data/20260813-media-probe-r4/`.

| Codec | Clip | Decoder selected by GeckoView | Peak decode CPU |
|---|---|---|---|
| H.264 | test-videos.co.uk mp4/h264/1080 30s | `OMX.qcom.video.decoder.avc` (Color 0x13) | ~10 % |
| HEVC | test-videos.co.uk mp4/h265/1080 30s | `OMX.qcom.video.decoder.hevc` (Color 0x13) | ~10 % |
| VP9 | test-videos.co.uk webm/vp9/1080 30s | `OMX.qcom.video.decoder.vp9` + `MIME support: HW video/x-vnd.on2.vp9` | ~10 % |

## Interpretation

- GeckoView's `HardwareCodecCapability` layer probes `MediaCodecList` and
  deliberately targets the Qualcomm decoders (`OMX.qcom.video.decoder.*`) with
  its preferred color format — for all three web codecs.
- ~10 % peak decode CPU across app + media processes is the hardware-decode
  signature (software decode of 1080p would spike one or more cores 60–150 %).
- The candidate knob `media.hardware-video-decoding.enabled` does not need to
  be forced: hardware decoding is already the active path on the OnePlus 7.

## Consequence for the optimization plan

- C1 → **no code change, keep measured result as the baseline answer**.
- r5 (this revision) = measurement-only revision: hardware decode verified,
  nothing shipped.
- Next candidates, in order: C2 (background discipline — needs an idle-window
  drain/wakeups baseline first), C6 (startup — re-measure cold start cleanly),
  C3 (content-process count), C4/C5 (smoothness — idle framestats).
