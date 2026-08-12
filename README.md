# Iceraven OP7

OnePlus 7 (Snapdragon 855 / SM8150, Adreno 640, Android 10) optimized distribution of
[Iceraven Browser](https://github.com/fork-maintainers/iceraven-browser).

This is **not a new browser**. It is an engineering layer that:

1. mirrors a pinned, audited upstream Iceraven commit,
2. applies Iceraven's own build-time patch layer (search engines, toolbar, branding — exactly
   as upstream CI does),
3. applies a small, documented OP7 patch set on top,
4. builds `app:assembleForkRelease` for `arm64-v8a` on free GitHub-hosted runners,
5. validates structure, ABI, and checksums, then releases only when every gate passes,
6. detects upstream changes automatically and stops-and-reports instead of force-resetting
   or silently resolving conflicts.

Gecko, GeckoView, Android Components, extensions, privacy and security architecture are all
preserved unchanged unless a measured, documented problem on the OnePlus 7 requires
otherwise.

## Repository layout

```
docs/op7-project-audit.md       Phase 0 audit (start here)
docs/architecture.md            layer ownership map
docs/baseline.md                golden-rule baseline record
docs/performance/               measurement methodology + startup map
docs/oneplus7/                  DeviceCapabilities design
docs/reproducible-build.md      traceability + release identity
automation/op7/                 check/sync/patch/metadata scripts
patches/op7/                    OP7 patch set (empty until Phase 7)
upstream/commit.txt             pinned upstream commit
.github/workflows/              ci | upstream-check | op7-build
```

## Pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `CI` | push / PR | static validation (actionlint, shellcheck, pin/revision format) |
| `Upstream Check` | schedule / manual / repository_dispatch | compares upstream HEAD to pin; opens sync issue; dispatches build |
| `OP7 Build` | workflow_dispatch | mirror → patch → build → validate → (release) |

Run a validation build manually:

```
gh workflow run op7-build.yml -f upstream_commit=<sha> -f abi=arm64-v8a -f release=false
```

Publish a release (after validation passes; requires release secrets):

```
gh workflow run op7-build.yml -f release=true -f release_tag=op7-2.46.0-r1
```

## Required secrets

- Validation signing (same pattern as upstream CI): `DEBUG_SIGNING_KEY`,
  `DEBUG_ALIAS`, `DEBUG_KEY_STORE_PASSWORD`, `DEBUG_KEY_PASSWORD`.
- Release signing (protected `release` environment): `OP7_RELEASE_KEYSTORE_BASE64`,
  `OP7_RELEASE_KEYSTORE_PASSWORD`, `OP7_RELEASE_KEY_ALIAS`, `OP7_RELEASE_KEY_PASSWORD`.

Never commit keys. Never give PR-triggered jobs access to release secrets.

## Status

- Phase 0 (audit): **done** — `docs/op7-project-audit.md`
- Phases 1–2 (baseline + measurement on a physical OnePlus 7): next
- Phases 3–5 (CI reliability, upstream sync, capability detection): skeleton implemented
- Phases 6–10 (profiling, optimizations, regression system, release, maintenance): pending,
  gated on baseline
