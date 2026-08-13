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
r6 fixed the invisible settings page with `#1A1A1A` card rows, but that left a
"mix of gray and pureblack"; r7 removes every gray fill.

Root cause: `values-night/colors.xml` maps the Material3 surface tokens to
`novaGray65-85` (dark greys) and layer tokens to `photonDarkGrey30/80`. None of them
are `#000000`, so AMOLED pixels stay on. androidx.preference rows are transparent
ripples and its dividers are `#1f000000`, so once the backdrop is black the settings
page loses all structure.

Affected layer: app UI resources only (`values-night/colors.xml`, `values/styles.xml`,
`drawable/`, `layout/`). No Kotlin, no GeckoView, no build config.

Implementation (r7 v3): collapse the ENTIRE dark-theme surface scale to `#000000` —
background/surface/dim, `surface_variant`, `surface_bright`, all
`surface_container_*`, `layer_color_2` (cards/menus/dialogs), `layer_color_3`
(search), and the splash background (004's seam becomes instant-black AMOLED).
Structure is carried by hairlines instead of lit fills: `outline` `#2A2A2A`,
`outline_variant` `#242424`, and the settings row card gets a 1dp `#242424` stroke
(`op7_preference_row_background`) around its pure-black fill via
`PreferenceTheme.preferenceStyle` + `SwitchCompatPreferenceMaterialStyle`
(`@layout/op7_preference_row`, a pinned copy of androidx.preference 1.2.1
`preference_material`). androidx list dividers stay neutralized.

Expected benefit: maximum AMOLED power saving — every non-content chrome pixel
(toolbar, menus, dialogs, home, settings, splash) is truly off, with card structure
preserved by hairlines that cost ~0 pixels. Measurable via screen-on drain deltas and
black-pixel coverage screenshots (before/after).

Benchmark: r5 baseline in `docs/performance/` (black-pixel coverage + screen-on mA
method). r7 target: ~100% pure-black coverage on UI chrome surfaces vs r5 ~10%,
settings rows visible via hairline (visual QA). No frame-time claim.

Regression risk: cosmetic only; on-surface text stays near-white (`#f2f0f8`, contrast
18.6:1 on black), light theme untouched, private-mode violet palette untouched.
Home cards now blend into the backdrop (structure by content, not fills) — the
intended pure-black look. Row layout is pinned to androidx.preference 1.2.1; an
upstream bump that changes it surfaces as a patch conflict and stops the pipeline.
Revert = drop the patch.

Upstream relationship: not for upstream (device-specific AMOLED preference); Fenix
deliberately uses Material dark greys. Could be proposed as an optional AMOLED toggle
later.

## 006-op7-onephone-red-accent.patch

Problem: the default Iceraven accent is Mozilla violet; a OnePlus 7 themed build
should carry the OnePlus brand red (`#EB0029`) so the browser feels native to the
device.

Root cause: `values-night/colors.xml` and `values/colors.xml` map
`fx_mobile_primary` / `primary_container` / `primary_inverse` and the dark-mode
accent family to the nova/photon violet palette.

Affected layer: app UI resources only (`values-night/colors.xml`,
`values/colors.xml`). No Kotlin, no GeckoView, no build config.

Implementation: remap the accent family to OnePlus red. Night: `primary`
`#FFEB0029`, `primary_container` `#FF4D000F`, `primary_inverse` `#FFFF3346`,
`accent_normal_theme` `#FFEB0029`, `accent_high_contrast_normal_theme` `#FFFF3346`,
fill-link-from-clipboard `#FFEB0029`, login cursor `#FFEB0029`, protections progress
bar `#FFEB0029`. Day: `primary` `#FFEB0029`, `primary_container` `#FFFFD9DE`,
`primary_inverse` `#FFFF4D5E`. Private-mode identity (violet) is intentionally kept
so private browsing stays visually distinct; day-theme text stays ink-dark
(`accent_normal_theme` day = `photonInk20` is text color, not brand accent).

Expected benefit: OnePlus brand identity in toolbar icons, links, toggles, buttons
and the dashboard, on top of the r7 pure-black AMOLED base. `#EB0029` on `#000000`
is ~4.6:1 contrast (AA for normal-size accent text).

Benchmark: visual QA (accent present across settings/toolbar/tabs) + r7 black-pixel
coverage unchanged (accent pixels are a tiny fraction of chrome). No perf claim.

Regression risk: cosmetic only; both themes keep dark and light accent variants for
contrast. No security/permission/process changes. Revert = drop the patch.

Upstream relationship: not for upstream (device-brand theming); Fenix keeps violet as
its brand color. Could be proposed as a configurable accent later.
