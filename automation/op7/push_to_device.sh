#!/usr/bin/env bash
# Streamlined proot->device APK transfer + install via Shizuku.
# Why: proot storage is app-private; the real device (shizuku shell) cannot
# see it. Proot shares the device network, so we serve over loopback HTTP and
# pull with curl on the real shell. APKs are stored on the REAL /sdcard so
# they survive proot wipes and can be reinstalled anytime.
#
# Usage:
#   push_to_device.sh <apk>            # copy to /sdcard/Download/op7/ + install
#   push_to_device.sh <apk> --no-install   # copy to /sdcard only
set -u

APK="${1:?usage: push_to_device.sh <apk> [--no-install]}"
NO_INSTALL=0
[ "${2:-}" = "--no-install" ] && NO_INSTALL=1
[ -f "$APK" ] || { echo "no such file: $APK"; exit 1; }

SRC_DIR="$(cd "$(dirname "$APK")" && pwd)"
BASE="$(basename "$APK")"
PORT="${OP7_PUSH_PORT:-8766}"

echo "== [1/5] start loopback server (port $PORT) =="
# persistent across sessions; pick free port if busy
while ! python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',$PORT)); s.close()" 2>/dev/null; do
  PORT=$((PORT+1))
done
setsid nohup python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SRC_DIR" >/tmp/op7-httpd.log 2>&1 < /dev/null &
sleep 1
python3 - "$PORT" "$BASE" <<'PY' || { echo "server not reachable"; exit 1; }
import sys, urllib.request
port, name = sys.argv[1], sys.argv[2]
r = urllib.request.urlopen(f"http://127.0.0.1:{port}/{name}", timeout=5)
print(f"   serving OK ({r.headers.get('Content-Length')} bytes)")
PY

DEV_APK_DIR="/sdcard/Download/op7"
DEV_APK="$DEV_APK_DIR/$BASE"
echo "== [2/5] pull to real /sdcard ($DEV_APK) =="
shizuku sh -c "mkdir -p '$DEV_APK_DIR' && curl -s -o '$DEV_APK' 'http://127.0.0.1:$PORT/$BASE' && ls -la '$DEV_APK'" || {
  echo "curl failed (rc=$?)"; exit 1; }

echo "== [3/5] verify size =="
LOCAL_SIZE=$(stat -c %s "$APK")
DEV_SIZE=""
for i in 1 2 3; do
  DEV_SIZE=$(shizuku sh -c "stat -c %s '$DEV_APK'" 2>/dev/null | tr -d '[:space:]')
  [ -n "$DEV_SIZE" ] && break
  sleep 1
done
echo "   local=$LOCAL_SIZE dev=$DEV_SIZE"
[ "$LOCAL_SIZE" = "$DEV_SIZE" ] || { echo "SIZE MISMATCH"; exit 1; }

if [ "$NO_INSTALL" = "1" ]; then
  echo "== stored at $DEV_APK (no install) =="
  exit 0
fi

echo "== [4/5] copy to /data/local/tmp (FUSE-path installs fail, see log C2) =="
shizuku sh -c "cp '$DEV_APK' /data/local/tmp/op7.apk && ls -la /data/local/tmp/op7.apk" || exit 1

echo "== [5/5] pm install -r =="
shizuku sh -c "pm install -r /data/local/tmp/op7.apk" 2>&1 | tail -3
echo "   installed: $DEV_APK (also kept in /data/local/tmp/op7.apk)"
