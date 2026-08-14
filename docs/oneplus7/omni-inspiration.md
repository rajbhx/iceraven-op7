# omni-browser — inspiration review (2026-08-14)

Source: `https://github.com/REBEL-ROOT/omni-browser` — reviewed via the GitHub API
only (tree, README, `OmniApplication.kt`, `force_dark` extension, `release.yml`).
**Not cloned.** Purpose: extract reusable ideas for the Iceraven OP7 special build.
This document is research, not a change request.

## What omni-browser is
- A from-scratch Android browser (Jetpack Compose + Material 3, Kotlin 1.9). **Not a Fenix
  fork** — so its architecture is not a template for our patch layer; only ideas/patterns transfer.
- Engine: Mozilla **GeckoView** (v145 per its README badge). Same engine family as Iceraven,
  so engine-level concepts are relevant.
- License: **GPL-3.0** (see the license note at the bottom — this matters for us).

## UI / theme patterns (verified from source)
- `OmniApplication.onCreate()` applies hardcoded theme defaults (`darkThemeEnabled = true`)
  synchronously before the first Compose frame → no white flash. Our `004-op7-seamless-launch`
  already delivers an instant-black AMOLED splash (`fx_mobile_splashscreen_background →
  fx_mobile_surface` = `#000`). Equivalent outcome; **no new work required.**
- `ThemeScreen` separates `darkThemeEnabled` from an `amoledMode` toggle, plus `accentTheme`
  and `dynamicColor`. Iceraven/Fenix already has an accent-colour setting and
  `006-op7-onephone-red-accent` provides the OP7 theme. A standalone "AMOLED toggle" is a
  possible future refinement but is feature creep right now.
- OLED-black discipline matches `005-op7-amoled-dark` (r7): every non-content UI pixel is
  `#000`. omni confirms "true-black chrome" is a valid premium target.

## Bundled WebExtensions — the single most useful idea
omni ships MV2 extensions under `app/src/main/assets/web_extensions/`:
- `force_dark` — content script at `document_start`; **smart detection** (only forces dark when
  the site lacks a native dark theme); CSS scoped under `.omni-force-dark-active`; protects
  media/player elements; uses near-black `#121214` (not pure `#000`).
- `universal_copy`, `media_grabber` (HLS/DASH sniffing), `omni_translate`, `ai_blocker`,
  `proxy_router`.

### Transfer decision for OP7
- Web-content AMOLED darkening is **not** covered by our UI patch — pages still render light.
  This is the highest-value gap.
- **Option A (now, zero repo risk):** install a force-dark add-on (e.g. Dark Reader) from
  Iceraven's add-ons manager. Works today, no maintenance, no patch risk.
- **Option B (future, measured):** bundle a `force_dark` extension. **Constraint:** recent
  Fenix/Android-Components has no default `installBuiltInExtension` path, so it needs new code
  in the components/startup layer — an exact-source patch (we have no local mirror here). Make it
  an r8 candidate, gated on a Phase-2/6 measurement, with before/after black-pixel + drain data.
  Keep omni's smart-detection approach (don't blind-invert media/player surfaces).

## Release / CI pattern (verified from `release.yml`)
- Triggered on `v*` tags; runs under `environment: release` holding signing secrets
  (`RELEASE_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, alias).
- Guards: versionCode regression check; `jarsigner -verify` post-build; rename APKs per ABI
  (`<app>-<ver>-arm/aarch64/universal.apk`); **wipe keystore from the runner in an `if: always()`
  step**.
- Our `op7-build.yml` already mirrors most of this (release env, metadata gates, artifacts).
  Add the keystore-wipe-in-`always()` guard if not present, and consider a `jarsigner -verify`
  gate (our validate step already checks the signing config). Low priority.

## What we deliberately do NOT copy
These violate the thin-patch / measure-first rules and bloat the OP7 build:
- On-device AI: ASR (Vosk), live captions, offline/online translation, model catalog + downloader.
- Media rewrite: ExoPlayer "Omni Player" + stream sniffer. We keep GeckoView media and instead
  measure HW codec usage (roadmap §9, rank 1).
- Safe Locker (AES-256 vault), bookmarks import/export, PDF export, QR tools, Discover feed,
  animated wallpaper, UI-scale/wallpaper theming.
- Multi-ABI packaging (arm + aarch64 + universal). We are **arm64-v8a-only by design** (OP7 =
  SD855 AArch64).

## License note (important)
omni-browser is **GPL-3.0**; Iceraven and our patches are **MPL-2.0**. GPL-3.0 code cannot be
incorporated into an MPL-2.0 project. Take inspiration and patterns only — never paste omni
source into this repo.

## Carried-forward action items
- r8 candidate (Tier 1): web-content AMOLED darkening — start with Option A during daily use;
  measure; only then decide Option B as a patch.
- Roadmap §9 unchanged. Note that **r7 (pure-black) is built and ready to release**.
- Cleanup: `maintenance.yml` already prunes artifacts/caches/runs older than 14 days monthly.
