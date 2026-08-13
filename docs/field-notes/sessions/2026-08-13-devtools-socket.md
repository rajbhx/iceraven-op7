# Session digest — 2026-08-13 — devtools socket exploration (dead end, documented)

## Problems solved
- **P** "Remote debugging via USB" enabled but port 6000 not listening
  cause: GeckoView's remote debugger listens on a Unix abstract socket (io.github.forkmaintainers.iceraven.op7/firefox-debugger-socket), not TCP; adb forward is the normal bridge
  solution: verified via logcat `GeckoViewRemoteDebugger: listening on .../firefox-debugger-socket`
  section: D
  tags: devtools, debugging, socket, geckoview
- **P** cannot reach the abstract socket without adb
  cause: SELinux denies the proot app domain (EACCES on connect); shell toybox nc has no -U; user declined adb authorization
  solution: accept the constraint — devtools measurement channel is unavailable on this setup; keep Shizuku dumpsys/top/logcat as the measurement stack
  section: D
  tags: devtools, selinux, adb, constraint
