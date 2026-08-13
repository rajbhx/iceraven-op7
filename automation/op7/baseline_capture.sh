#!/usr/bin/env bash
# OnePlus 7 baseline capture (Phase 2).
# Transport: adb (default) or Shizuku (OP7_TRANSPORT=shizuku) when adb is unavailable.
# Usage:
#   automation/op7/baseline_capture.sh devices
#   automation/op7/baseline_capture.sh install <path.apk>
#   automation/op7/baseline_capture.sh cold-start [runs]
#   automation/op7/baseline_capture.sh warm-start [runs]
#   automation/op7/baseline_capture.sh mem [tabs]
#   automation/op7/baseline_capture.sh gfx
#   automation/op7/baseline_capture.sh battery-start
#   automation/op7/baseline_capture.sh battery-stop <label>
#   automation/op7/baseline_capture.sh all <path.apk> [runs]
#
# Shizuku mode: APK paths must be visible to the device (e.g. /sdcard/Download/...);
# install copies to /data/local/tmp first (direct /sdcard pm install can return 255).
set -euo pipefail

PKG="io.github.forkmaintainers.iceraven.op7"
COMPONENT="io.github.forkmaintainers.iceraven.op7/org.mozilla.fenix.HomeActivity"
ADB="${ADB:-adb}"
ADB_ARGS=()
if [[ -n "${ADB_SERIAL:-}" ]]; then ADB_ARGS=(-s "$ADB_SERIAL"); fi
TRANSPORT="${OP7_TRANSPORT:-adb}"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${OP7_BASELINE_DIR:-$ROOT_DIR/docs/performance/data/$(date -u +%Y%m%d-%H%M%S)}"

log() { echo "[baseline] $*"; }

run_sh() {
  if [[ "$TRANSPORT" == "shizuku" ]]; then
    shizuku sh -c "$*"
  else
    "$ADB" "${ADB_ARGS[@]}" shell "$*"
  fi
}

require_transport() {
  if [[ "$TRANSPORT" == "shizuku" ]]; then
    command -v shizuku >/dev/null || { echo "error: shizuku not found on PATH"; exit 2; }
    if [[ "$(shizuku whoami 2>&1 | head -n1)" != *shell* ]]; then
      echo "error: Shizuku server not reachable (open Shizuku and start the server)"
      exit 2
    fi
  else
    command -v "$ADB" >/dev/null || { echo "error: adb not found on PATH"; exit 2; }
    if ! "$ADB" "${ADB_ARGS[@]}" get-state >/dev/null 2>&1; then
      echo "error: no adb device reachable (try: $ADB devices, then enable adb over TCP: $ADB tcpip 5555)"
      exit 2
    fi
  fi
}

cmd_devices() {
  if [[ "$TRANSPORT" == "shizuku" ]]; then
    shizuku whoami 2>&1 | head -n1
  else
    "$ADB" "${ADB_ARGS[@]}" devices -l
  fi
}

cmd_install() {
  local apk="$1"
  [[ -f "$apk" ]] || { echo "error: APK not found: $apk"; exit 1; }
  log "installing $apk ($TRANSPORT)"
  if [[ "$TRANSPORT" == "shizuku" ]]; then
    run_sh "cp '$apk' /data/local/tmp/op7-baseline.apk && pm install -r /data/local/tmp/op7-baseline.apk"
  else
    "$ADB" "${ADB_ARGS[@]}" install -r "$apk"
  fi
}

start_measure() {
  local label="$1" runs="${2:-5}"
  mkdir -p "$OUT_DIR"
  local logfile="$OUT_DIR/${label}.txt"
  : > "$logfile"
  for i in $(seq 1 "$runs"); do
    run_sh "am force-stop $PKG" >/dev/null 2>&1 || true
    sleep 2
    log "$label run $i/$runs"
    {
      echo "=== $label run $i ==="
      run_sh "am start -W -n $COMPONENT"
    } >> "$logfile"
    sleep 3
    run_sh "am force-stop $PKG" >/dev/null 2>&1 || true
    sleep 5
  done
  log "results: $logfile (parse ThisTime/TotalTime)"
}

cmd_cold() { start_measure "cold-start" "${1:-5}"; }
cmd_warm() {
  local runs="${1:-5}" logfile
  mkdir -p "$OUT_DIR"
  logfile="$OUT_DIR/warm-start.txt"
  : > "$logfile"
  run_sh "am start -n $COMPONENT" >/dev/null 2>&1 || true
  sleep 8
  for i in $(seq 1 "$runs"); do
    {
      echo "=== warm run $i ==="
      run_sh "am start -W -n $COMPONENT"
    } >> "$logfile"
    sleep 5
  done
  log "results: $logfile"
}

cmd_mem() {
  local tabs="${1:-5}" memfile
  mkdir -p "$OUT_DIR"
  memfile="$OUT_DIR/meminfo-${tabs}tabs.txt"
  run_sh "am start -n $COMPONENT" >/dev/null 2>&1 || true
  sleep 10
  log "opening $tabs tabs (manual seed required if auto-nav is not yet scripted)"
  sleep 5
  run_sh "dumpsys meminfo $PKG" > "$memfile"
  log "results: $memfile"
}

cmd_gfx() {
  mkdir -p "$OUT_DIR"
  run_sh "dumpsys gfxinfo $PKG" > "$OUT_DIR/gfxinfo.txt"
  log "results: $OUT_DIR/gfxinfo.txt"
}

cmd_battery_start() {
  run_sh "dumpsys batterystats --reset" >/dev/null
  log "batterystats reset"
}

cmd_battery_stop() {
  local label="${1:-battery}"
  mkdir -p "$OUT_DIR"
  run_sh "dumpsys batterystats" > "$OUT_DIR/${label}.txt"
  log "results: $OUT_DIR/${label}.txt"
}

cmd_all() {
  local apk="$1" runs="${2:-5}"
  cmd_install "$apk"
  cmd_cold "$runs"
  cmd_warm "$runs"
  cmd_mem 5
  log "baseline capture complete -> $OUT_DIR"
}

require_transport
case "${1:-}" in
  devices)        cmd_devices ;;
  install)        cmd_install "$2" ;;
  cold-start)     cmd_cold "${2:-5}" ;;
  warm-start)     cmd_warm "${2:-5}" ;;
  mem)            cmd_mem "${2:-5}" ;;
  gfx)            cmd_gfx ;;
  battery-start)  cmd_battery_start ;;
  battery-stop)   cmd_battery_stop "$2" ;;
  all)            cmd_all "$2" "${3:-5}" ;;
  *) sed -n '2,20p' "$0" >&2; exit 1 ;;
esac
