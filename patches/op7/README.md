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
