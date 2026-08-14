# Session digest — 2026-08-14 — Port DeepDenoiser + Rain to OP7

Created two new build repos (rajbhx/deepdenoiser-op7, rajbhx/rain-op7) using
the iceraven-op7 pattern: pinned upstream, thin patch layer, GitHub Actions
only. Both r1 builds green; playbook projects registered.

## Problems solved
- **P** Expo/RN build repos cannot use upstream's EAS-based CI
  cause: eas build --local needs EAS project ownership + EXPO_TOKEN
  solution: expo prebuild --platform android --no-install + plain gradle assemble
  section: A
  tags: [expo, rn, eas, github-actions]
- **P** Expo SDK 55 lockfile drift broke compile (@siteed/audio-studio 3.2.1)
  cause: fresh bun.lock resolved siteed 3.2.1 whose Promise.reject(String?,...)
    no longer matches expo-modules-core reject(String,...); upstream patch-package
    patches target 3.0.3
  solution: pin @siteed/audio-studio=3.0.3 via overrides/bun.lock; verify compile
  section: A
  tags: [expo, bun, lockfile, compile-error]
- **P** ONNX InferenceSession leaked per denoise job (processing screen)
  cause: process.tsx creates DeepFilterNet and never calls release(); recording
    screen releases via ref
  solution: OP7 patch 001 — release() in finally (stability fix, not perf claim)
  section: A
  tags: [onnx, memory-leak, stability]
- **P** rainManager APK has no native-code badging entry (lspatch libs in assets)
  cause: lspatch .so injected into patched Discord APK at patch time, not used by
    the manager itself
  solution: validation gate for manager checks package/SDK/testOnly only
  section: A
  tags: [rain, lspatch, badging, abi]
- **P** playbook sync failed parsing project field-notes logs
  cause: unquoted YAML scalars containing ': ' broke generate_project_docs.py
  solution: quote all scalar values in docs/field-notes/log.yml
  section: F
  tags: [playbook, yaml, field-notes]

## Notes
- New repos: rajbhx/deepdenoiser-op7 (Expo 55/RN 0.83/ONNX), rajbhx/rain-op7 (rainManager + rain bundle)
- Both registered in playbook projects/ with manifests; canonical skill references added
- rainXposed runtime-fetched (reference pin only); RainTweak iOS-only excluded
