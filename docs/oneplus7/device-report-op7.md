# OnePlus 7 — Verified Device Report

Captured **2026-08-12** directly on the physical device (BeanShell/Java bridge + sysfs).
This verifies the project-brief assumptions (§3) against real hardware.

## Identity

| Property | Value | Assumption check |
|---|---|---|
| Manufacturer / model | OnePlus / **GM1901** (OnePlus 7) | ✓ target device |
| Device / board / hardware | `OnePlus7` / `msmnile` / `qcom` | ✓ SM8150 (Snapdragon 855) |
| Android version / SDK | **10** / **29** (build `QKQ1.190716.003`) | ✓ Android 10 / OxygenOS 10 |
| Kernel | `4.14.117-perf`, aarch64, SMP PREEMPT | ✓ 64-bit |
| ABIs | `arm64-v8a`, `armeabi-v7a`, `armeabi` | ✓ arm64-v8a primary |

## CPU / Memory

- CPU cores: **8** (Snapdragon 855: 1× Kryo 485 Gold @2.84 GHz, 3× Gold @2.42 GHz, 4× Silver @1.78 GHz).
- Total RAM: **7,478 MB (~8 GB)**; current available ≈ 2.3 GB at capture time.
- Heap class: 256 MB standard, 512 MB large.

## GPU / Graphics

- GPU: **Adreno 640** (`ro.hardware.vulkan=adreno`; SM8150 standard).
- OpenGL ES: **3.2** (`ro.opengles.version=196610` = `0x30002`); AEP feature present.
- Vulkan: **supported** (version, level, and compute features all reported).

## Display

- 1080 × 2260 px @ 420 dpi (6.41" OnePlus 7 panel).

## Storage

- `/data`: 239.5 GB total, 138.8 GB available (256 GB UFS variant).

## Media (MediaCodecList — hardware decoders)

| Codec | Component | Hardware | Notes |
|---|---|---|---|
| H.264 / AVC | `OMX.qcom.video.decoder.avc` | ✓ | up to 8192×4320 |
| H.264 / AVC | `c2.qti.avc.decoder` | ✓ | Codec2 |
| HEVC / H.265 | `OMX.qcom.video.decoder.hevc` | ✓ | |
| VP8 | `OMX.qcom.video.decoder.vp8` | ✓ | |
| VP9 | `OMX.qcom.video.decoder.vp9` | ✓ | |
| MPEG-2 | `OMX.qcom.video.decoder.mpeg2` | ✓ | |
| Software video | DivX, H.263, MPEG-4, VC-1 | ✗ | sw fallback |
| Audio | AC-3, AC-4, E-AC-3, FLAC | ✓ | Dolby/Qualcomm |
| AV1 | — | ✗ | not present (expected on this SoC) |

## Conclusions for the OP7 layer

1. All brief assumptions (§3) are **confirmed**: GM1901, SD855/SM8150, Adreno 640, Android 10/OxygenOS 10, arm64-v8a.
2. H.264/HEVC/VP8/VP9 hardware decode is available; Gecko/GeckoView should prefer hardware paths and fall back to software only for AV1/DivX/H.263/MPEG-4/VC-1.
3. Vulkan + GLES 3.2 are both present; any WebRender backend decision must be benchmarked on-device (Phase 6), not assumed.
4. 8 GB RAM class justifies evaluating Gecko content-process and tab-suspension policy (Phase 7) — measure first.
5. Remaining runtime facts to capture once adb is available: exact GLES driver string and frame timing (`dumpsys SurfaceFlinger`), Vulkan driver version, and battery/wakeup baselines.
