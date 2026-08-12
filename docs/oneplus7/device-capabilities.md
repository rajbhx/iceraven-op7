# Iceraven OP7 — DeviceCapabilities Design (Phase 5)

Replace scattered `Build.MODEL == "GM1901"` checks with a single capability model.
Generic Android capability checks are preferred over device-specific ones; a
OnePlus-specific check is allowed only when the problem is reproducible, the root cause
is understood, the workaround is necessary, benefit is measurable, and no generic check
solves it.

## Data model (initial)

```kotlin
data class DeviceCapabilities(
    val abiList: List<String>,              // Build.SUPPORTED_ABIS — expect listOf("arm64-v8a")
    val is64Bit: Boolean,                   // Build.SUPPORTED_64_BIT_ABIS.isNotEmpty()
    val apiLevel: Int,                      // Build.VERSION.SDK_INT
    val manufacturer: String,               // Build.MANUFACTURER (informational only)
    val model: String,                      // Build.MODEL (informational only, never the gate)
    val totalRamBytes: Long,                // ActivityManager.MemoryInfo.totalMem
    val memoryClassMb: Int,                 // ActivityManager.getMemoryClass() + largeHeap
    val glesVersion: String,                // PackageManager FEATURE_GLES_VERSION
    val vulkanSupported: Boolean,           // FEATURE_VULKAN_HARDWARE_VERSION
    val openGlEsSupported: Boolean,         // FEATURE_OPENGLES (3.1/3.2 check)
    val mediaCodecCapabilities: List<MediaCodecInfo>, // MediaCodecList — H.264/HEVC/VP9 decoders
    val displayWidthPx / displayHeightPx / densityDpi: Int,
    val lowRam: Boolean,                    // ActivityManager.isLowRamDevice()
)
```

## Where it lives and how it is used

- Lives in the app module as a small, dependency-free helper (e.g.
  `org.mozilla.fenix.op7.DeviceCapabilities`), initialized once at startup, memoized.
- Consumers ask *capabilities*, never the model string:
  - "hardware video decode for HEVC available?" → `mediaCodecCapabilities`
  - "device is 64-bit arm64?" → `abiList`
  - "8 GB RAM class?" → `totalRamBytes`/`memoryClassMb`
- Capabilities feed **runtime preference decisions** for GeckoView (e.g. media codec
  policy, content-process count, WebRender feature toggles) so behavior stays generic
  and portable.

## Verification on the real device

Before Phase 5 is considered done, dump the OP7's actual reported values and record them
in `docs/oneplus7/device-report-op7.md` (Build fields, RAM, GLES/Vulkan features,
`MediaCodecList`, display, storage class). Every assumption in the project brief
(SD855/SM8150, Adreno 640, Android 10, OxygenOS 10) must be confirmed or corrected by
this report — including the actual Android version if the device was updated.

## Anti-patterns

- `if (Build.MODEL == "GM1901") ...` anywhere in app code.
- Hard-coding CPU instructions or `-march=native`.
- Using capabilities to disable security features (sandboxing, HTTPS, site isolation).
- Guessing codec support instead of reading `MediaCodecList`.
