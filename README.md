<p align="center">
  <img src="https://img.shields.io/badge/OnePlus%207-GM1901-EB0028?style=for-the-badge&logo=oneplus&logoColor=white" alt="OnePlus 7"/>
  <img src="https://img.shields.io/badge/Snapdragon-855%20(SM8150)-EB0028?style=for-the-badge" alt="Snapdragon 855"/>
  <img src="https://img.shields.io/badge/Adreno-640-EB0028?style=for-the-badge" alt="Adreno 640"/>
  <img src="https://img.shields.io/badge/ABI-arm64--v8a-EB0028?style=for-the-badge" alt="arm64-v8a"/>
</p>

<h1 align="center">Iceraven · OnePlus 7 Edition</h1>

<p align="center">
  <b>AMOLED-black · Snapdragon 855 tuned · upstream-synced · auto-built on free GitHub Actions</b>
</p>

<p align="center">
  <a href="https://github.com/rajbhx/iceraven-op7/actions/workflows/op7-build.yml"><img src="https://github.com/rajbhx/iceraven-op7/actions/workflows/op7-build.yml/badge.svg" alt="OP7 Build"/></a>
  <a href="https://github.com/rajbhx/iceraven-op7/actions/workflows/ci.yml"><img src="https://github.com/rajbhx/iceraven-op7/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <a href="https://github.com/rajbhx/iceraven-op7/actions/workflows/upstream-check.yml"><img src="https://github.com/rajbhx/iceraven-op7/actions/workflows/upstream-check.yml/badge.svg" alt="Upstream Check"/></a>
  <img src="https://img.shields.io/badge/revision-r5-EB0028?style=flat-square" alt="OP7 revision r5"/>
  <img src="https://img.shields.io/badge/license-MPL--2.0-blue?style=flat-square" alt="License"/>
</p>

---

**Iceraven OP7** is the [Iceraven Browser](https://github.com/fork-maintainers/iceraven-browser) (Fenix + GeckoView + Android Components) engineered for the **OnePlus 7** — not a new browser, not a rewrite, not a WebView shell.

Everything Gecko does stays Gecko. The OP7 layer is thin, measurable, documented, and automatically maintained:

| Layer | What it does |
|---|---|
| Pinned upstream | exact Iceraven commit (`upstream/commit.txt`), never a moving branch |
| Upstream patch layer | Iceraven's own build-time patches, exactly like upstream CI |
| OP7 patch set | tiny, documented `patches/op7/` — arm64-only, capability log, seamless launch, AMOLED black |
| GitHub Actions | free runners: check upstream → sync → patch → build → validate → release |
| Fails closed | upstream conflict or failed gate = **no build, no publish**, issue-style report |

## Revision history

| Revision | Content | Status |
|---|---|---|
| r1–r2 | arm64-only distribution, installable APK (testOnly bug fixed) | ✅ shipped |
| r3 | `DeviceCapabilities` fingerprint (ABI, RAM, GLES/Vulkan, codecs) | ✅ shipped |
| r4 | Seamless launch — splash matches home surface | ✅ shipped |
| **r5** | **AMOLED true-black dark theme** — `#000000` surfaces, power-friendly | ✅ this revision |
| r6+ | One measured optimization per revision, gated on before/after benchmarks | 🔄 planned |

Verification-only (no code change, measured on device): hardware video decode (H.264/HEVC/VP9), content-process cap, background drain, real-page smoothness 60 Hz / ~5 % jank.

## What stays untouched

- Gecko / GeckoView / Android Components architecture
- Sandboxing, site isolation, HTTPS, certificate validation
- Privacy defaults, extensions, web compatibility
- No `-march=native`, no hard-coded CPU instructions, no security trade-offs

## Device fingerprint (verified on this OnePlus 7)

```
Model          GM1901            GPU            Adreno 640
SoC            Snapdragon 855    Vulkan         supported
ABI            arm64-v8a         OpenGL ES      3.2
Android        10 (OxygenOS)     Hardware video H.264 / HEVC / VP9
RAM            8 GB              Display        AMOLED (hence r5)
```

## Repository map

```
docs/op7-project-audit.md    Phase 0 audit (start here)
docs/architecture.md         layer ownership map
docs/baseline.md             golden-rule baseline record
docs/performance/            methodology + startup/smoothness/media/battery
docs/roadmap.md              live plan + error matrix
docs/reproducible-build.md   traceability + release identity
patches/op7/                 OP7 patch set (001–005)
automation/op7/              check / sync / patch / metadata scripts
upstream/commit.txt          pinned upstream commit
.github/workflows/           CI | Upstream Check | OP7 Build | Maintenance
```

## Pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `CI` | push / PR | actionlint + shellcheck + pin/revision format |
| `Upstream Check` | schedule / manual / dispatch | detects upstream moves, opens sync issue |
| `OP7 Build` | `workflow_dispatch` | mirror → patch → build → validate → (release) |
| `Maintenance` | schedule / manual | monthly cleanup + self-check |

Validation build (~13 min, no R8):

```
gh workflow run op7-build.yml -f abi=arm64-v8a -f release=false -f fast=true
```

Release build (~40 min, gated, requires release secrets):

```
gh workflow run op7-build.yml -f abi=arm64-v8a -f release=true -f release_tag=op7-<version>-r<rev>
```

## Secrets

- Validation: `DEBUG_SIGNING_KEY`, `DEBUG_ALIAS`, `DEBUG_KEY_STORE_PASSWORD`, `DEBUG_KEY_PASSWORD`
- Release (protected `release` environment): `OP7_RELEASE_KEYSTORE_BASE64`, `OP7_RELEASE_KEYSTORE_PASSWORD`, `OP7_RELEASE_KEY_ALIAS`, `OP7_RELEASE_KEY_PASSWORD`

Keys are never committed. PR-triggered jobs never see release secrets.

## Why this build on a OnePlus 7

The phone ships with the right hardware for this browser: 8 GB RAM for content processes, Adreno 640 for WebRender, and hardware codecs GeckoView already uses — so the engineering here is **tuning and measurement**, not replacement. r5 makes the AMOLED panel earn its black.
