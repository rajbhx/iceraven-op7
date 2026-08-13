# Session digest — 2026-08-13 — r4 install via /sdcard path + Phase 5 fingerprint

## Problems solved
- **P** proot files invisible to the real device shell (shizuku)
  cause: proot runs inside the app (gptos.intelligence.assistant); its /storage/emulated/0 is an app-private bind, not the real /sdcard
  solution: proot shares the device network, so serve the APK with a persistent loopback HTTP server (setsid nohup python3 -m http.server) and pull with curl on the real shell to /sdcard/Download/op7/; verify size; copy to /data/local/tmp then pm install -r
  section: D
  tags: transfer, shizuku, sdcard, loopback
- **P** am start with HomeActivity failed (Error type 3: activity does not exist)
  cause: launcher activity is the Fenix delegate `.App`, and the package id is io.github.forkmaintainers.iceraven.op7 (not org.mozilla.fenix.iceraven.op7)
  solution: resolve the launcher with `cmd package resolve-activity --brief -c android.intent.category.LAUNCHER <pkg>` before launching
  section: C
  tags: install, activity, package-id
