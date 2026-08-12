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
