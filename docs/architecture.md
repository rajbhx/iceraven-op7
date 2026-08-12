# Iceraven OP7 — Architecture Map

Ownership map for the Iceraven build this project produces. Every optimization must
target the correct layer; fixing a Gecko problem in the UI, or an Android lifecycle
problem in Gecko, is a defect.

```
Iceraven (app module, Fenix-derived UI)
   ├── Android UI / lifecycle ............ app/src/main/java/org/mozilla/fenix/
   ├── Android Components (A-C) .......... android-components/ submodule (composite build)
   │     ├── browser-engine-gecko ........ engine wrapper (session, settings, webext)
   │     ├── feature-* / support-* ....... browser features, storage, services
   │     └── plugins/* ................... gradle plugins (config, dependencies, ...)
   ├── GeckoView ......................... org.mozilla.geckoview:geckoview-omni:<ver> (Maven AAR)
   │     └── Android embedding API, runtime prefs, GeckoRuntime/GeckoSession
   └── Gecko (in-process Rust/C++ core inside the AAR)
         ├── Rust ......................... Servo/WebRender components, App Services (megazord)
         ├── C++ .......................... layout, style, compositor, networking, media
         ├── graphics ..................... WebRender, GPU process, OpenGL ES / Vulkan
         ├── networking ................... Necko (DNS, HTTP/2/3, TLS, cache)
         ├── media ........................ MediaCodec hardware acceleration
         └── Java/JNI ..................... GeckoView ⇄ Gecko bridge (org.mozilla.gecko.*)
```

## Layer ownership rules

| Concern | Owner layer | Where changes go |
|---|---|---|
| Cold/warm startup sequencing, service init | app UI + application object | `app/src/main/java/org/mozilla/fenix/` |
| Tab lifecycle, tab suspension, memory pressure policy | app + A-C feature-session | app code or runtime prefs |
| Browser UI latency, toolbar, compose screens | app UI | app code |
| Engine behavior: process model, sandboxing, rendering | GeckoView runtime | GV prefs via `GeckoRuntimeSettings`, or upstream Gecko patches |
| Graphics/compositing quality and driver behavior | Gecko (WebRender) | GV prefs; only if measured |
| Networking, DNS, TLS, HTTP versions | Gecko (Necko) | GV prefs; never hard-code a DNS provider |
| Media codec selection | Gecko media stack + Android `MediaCodec` | GV prefs/`DeviceCapabilities` data |
| Native library packaging, ABI splits | build system | `app/build.gradle` splits / `DeviceCapabilities` |
| CPU/ARM64 execution path | prebuilt Gecko AAR | none locally; report upstream |

## Hard constraints

- GeckoView is consumed prebuilt from Mozilla Maven (`geckoview-omni`, release channel,
  fat AAR). This pipeline does not build Gecko source and must not pretend to.
- All Gecko-level tuning must go through documented GeckoView runtime preferences or
  upstream patches; device-specific Gecko hacks are forbidden unless a reproducible,
  measured problem demands one — and then it should be proposed upstream first.
- A-C changes are possible (submodule patch at build time, same mechanism as Iceraven's
  `automation/iceraven/patch_android_components.sh`) but must stay minimal and
  patch-based so upstream syncs remain cheap.
