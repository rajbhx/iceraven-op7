# OP7 patch set

Each patch must be a self-contained `git format-patch`-style `.patch` file that applies
cleanly to a fresh upstream checkout **after** Iceraven's own patch layer
(`automation/iceraven/patch_android_components.sh`) has run.

## Naming

`NNN-short-description.patch` (zero-padded sequence, e.g. `001-startup-defer-glean.patch`).

## Required per-patch documentation

Every patch file starts with a header comment block:

```
Problem:
Root cause:
Affected layer:        (app UI | A-C | GeckoView runtime prefs | build)
Implementation:
Expected benefit:
Benchmark:             (before/after from docs/performance/)
Regression risk:
Upstream relationship: (does this belong upstream? bugzilla/issue link)
```

## Rules

- No patch ships without a Phase-2 baseline measurement and a positive Phase-8
  benchmark comparison.
- One concern per patch; a patch that mixes unrelated changes is rejected.
- Patches are applied with `git apply --check` then `git apply` by
  `automation/op7/apply_patches.sh`. Conflicts **stop** the pipeline; they are never
  auto-resolved.
- Removing a patch = revert, not `sed`-style whack-a-mole.
- `op7-revision.txt` is bumped (r1, r2, ...) whenever the patch set changes.


## 002-op7-arm64-only.patch

Problem: the arm64-only APK was marked `android:testOnly=true`, which Android
refuses to install from the UI (generic "App not installed").
Root cause: building with the Studio-injected property
`-Pandroid.injected.build.abi=arm64-v8a` makes AGP mark the APK test-only.
Affected layer: build (`app/build.gradle` `splits.abi` + `op7-build.yml`).
Implementation: restrict `splits.abi` to `arm64-v8a` only and stop passing
`-Pandroid.injected.build.abi`; CI validation now fails if the built manifest
contains `testOnly`.
Expected benefit: APK installs via the normal file-tap flow on the OnePlus 7.
Benchmark: none (distribution change, no runtime perf impact).
Regression risk: only arm64-v8a APKs are produced; other ABI inputs fail
validation (intended for the OP7 target).
Upstream relationship: N/A — distribution choice; upstream ships all ABIs.

## 003-op7-device-capabilities.patch

Problem: no capability-detection layer exists; future optimizations would risk
scattered `Build.MODEL == "GM1901"` checks and hard-coded device assumptions.

Root cause: new infrastructure (Phase 5) — the app has no single place to ask
"what can this device do?" (ABI, RAM class, GLES/Vulkan, hardware codecs).

Affected layer: app UI (observability hook in `HomeActivity.onCreate`); new
`org.mozilla.fenix.op7.DeviceCapabilities` data model.

Implementation: memoized `DeviceCapabilities.get(context)` reading Build fields,
ActivityManager memory, PackageManager GLES/Vulkan features, MediaCodecList
hardware video decoders, display metrics, and StatFs storage. Wired to a single
debug log `OP7Capabilities` at startup — observability only, no behavior change.

Expected benefit: Phase 5/6/7 foundation; on-device verification of the
capability fingerprint via logcat; consumers later ask capabilities, never
model strings.

Benchmark: none — no behavior change (verified: no codec/backend/process policy
is toggled by this class yet).

Regression risk: minimal — one debug log line; R8 retains the class because
HomeActivity references it.

Upstream relationship: not for upstream (device-build specific). A generic
capability model could be proposed upstream later after Phase-7 measurements.

## 004-op7-seamless-launch.patch

Problem: on launch there is a visible color jump between the splash screen and
the home screen (light: splash #FCF3EE vs surface #F7F6FB; dark: splash
#210340 vs surface #1D1B1F) — reads as a "cheap app" flash.

Root cause: the splash background color is a hard-coded brand color that does
not match the app's actual first screen surface.

Affected layer: app UI (resources only — `values/colors.xml`,
`values-night/colors.xml`).

Implementation: `fx_mobile_splashscreen_background` now references
`@color/fx_mobile_surface`, so the splash always matches the first screen in
both themes, automatically staying in sync if the palette changes.

Expected benefit: perceived-performance ("sugar"): seamless, iOS-style launch
transition. No performance claim — cosmetic continuity only.

Benchmark: visual continuity (before/after launch screenshots); no cold-start
time claim.

Regression risk: negligible (color reference change; icon still shown on
splash). If the home palette changes, splash follows by design.

Upstream relationship: not for upstream (cosmetic preference); could be
proposed as a general polish later.

## 005-op7-amoled-dark.patch

Problem: the dark theme uses dark-grey surfaces (#1d1b1f / #312f33 / #42414d etc.),
not true black. On the OnePlus 7's AMOLED panel every non-black pixel is lit, so the
browser UI draws current even when idle and the theme never looks 'all-black' premium.

Root cause: `values-night/colors.xml` maps the Material3 surface tokens to
`novaGray65-85` (dark greys) and layer tokens to `photonDarkGrey30/80`. None of them
are `#000000`, so AMOLED pixels stay on.

Affected layer: app UI resources only (`app/src/main/res/values-night/colors.xml`).
No Kotlin, no GeckoView, no build config.

Implementation: remap the dark-theme surface scale to a true-black AMOLED scale:
background/surface/dim/lowest -> `#000000` (`@color/novaBlack`); containers ->
`#070707` / `#0F0F0F` / `#1A1A1A` / `#1F1F1F` / `#242424` so elevation hierarchy is
preserved while every base pixel is off. Splash already follows the surface color
(004), so launch is seamless black in dark mode.

Expected benefit: AMOLED panel power saving proportional to lit-pixel reduction on UI
chrome (toolbar, menus, dialogs, home), plus the requested all-black premium look.
Measurable via screen-on drain deltas and black-pixel coverage screenshots.

Benchmark: TBD Phase 8 — capture black-pixel coverage + screen-on mA before/after on
the OnePlus 7 (method in `docs/performance/baseline.md`). No frame-time claim.

Regression risk: cosmetic only; on-surface text stays near-white (`#f2f0f8`, contrast
18.6:1 on black), light theme untouched, private-mode violet palette untouched.
Revert = drop the patch.

Upstream relationship: not for upstream (device-specific AMOLED preference); Fenix
deliberately uses Material dark greys. Could be proposed as an optional AMOLED toggle
later.
