#!/usr/bin/env bash
# OnePlus 7 baseline capture (Phase 2). Requires adb reachability to the device.
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
set -euo pipefail

PKG="io.github.forkmaintainers.iceraven"
COMPONENT="io.github.forkmaintainers.iceraven/org.mozilla.fenix.HomeActivity"
ADB="${ADB:-adb}"
ADB_ARGS=()
if [[ -n "${ADB_SERIAL:-}" ]]; then ADB_ARGS=(-s "$ADB_SERIAL"); fi

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${OP7_BASELINE_DIR:-$ROOT_DIR/docs/performance/data/$(date -u +%Y%m%d-%H%M%S)}"

require_adb() {
  command -v "$ADB" >/dev/null || { echo "error: adb not found on PATH"; exit 2; }
  if ! "$ADB" "${ADB_ARGS[@]}" get-state >/dev/null 2>&1; then
    echo "error: no adb device reachable (try: $ADB devices, then enable adb over TCP: $ADB tcpip 5555)"
    exit 2
  fi
}

log() { echo "[baseline] $*"; }

cmd_devices() {
  "$ADB" "${ADB_ARGS[@]}" devices -l
}

cmd_install() {
  local apk="$1"
  [[ -f "$apk" ]] || { echo "error: APK not found: $apk"; exit 1; }
  log "installing $apk"
  "$ADB" "${ADB_ARGS[@]}" install -r "$apk"
}

start_measure() {
  local label="$1" runs="${2:-5}"
  mkdir -p "$OUT_DIR"
  local logfile="$OUT_DIR/${label}.txt"
  : > "$logfile"
  for i in $(seq 1 "$runs"); do
    "$ADB" "${ADB_ARGS[@]}" shell am force-stop "$PKG" >/dev/null 2>&1 || true
    sleep 2
    log "$label run $i/$runs"
    {
      echo "=== $label run $i ==="
      "$ADB" "${ADB_ARGS[@]}" shell am start -W -n "$COMPONENT"
    } >> "$logfile"
    sleep 3
    "$ADB" "${ADB_ARGS[@]}" shell am force-stop "$PKG" >/dev/null 2>&1 || true
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
  "$ADB" "${ADB_ARGS[@]}" shell am start -n "$COMPONENT" >/dev/null 2>&1 || true
  sleep 8
  for i in $(seq 1 "$runs"); do
    {
      echo "=== warm run $i ==="
      "$ADB" "${ADB_ARGS[@]}" shell am start -W -n "$COMPONENT"
    } >> "$logfile"
    sleep 5
  done
  log "results: $logfile"
}

cmd_mem() {
  local tabs="${1:-5}" memfile
  mkdir -p "$OUT_DIR"
  memfile="$OUT_DIR/meminfo-${tabs}tabs.txt"
  "$ADB" "${ADB_ARGS[@]}" shell am start -n "$COMPONENT" >/dev/null 2>&1 || true
  sleep 10
  log "opening $tabs tabs (manual seed required if auto-nav is not yet scripted)"
  sleep 5
  "$ADB" "${ADB_ARGS[@]}" shell dumpsys meminfo "$PKG" > "$memfile"
  log "results: $memfile"
}

cmd_gfx() {
  mkdir -p "$OUT_DIR"
  "$ADB" "${ADB_ARGS[@]}" shell dumpsys gfxinfo "$PKG" > "$OUT_DIR/gfxinfo.txt"
  log "results: $OUT_DIR/gfxinfo.txt"
}

cmd_battery_start() {
  "$ADB" "${ADB_ARGS[@]}" shell dumpsys batterystats --reset >/dev/null
  log "batterystats reset"
}

cmd_battery_stop() {
  local label="${1:-battery}"
  mkdir -p "$OUT_DIR"
  "$ADB" "${ADB_ARGS[@]}" shell dumpsys batterystats > "$OUT_DIR/${label}.txt"
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

require_adb
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
  *) sed -n '2,14p' "$0" >&2; exit 1 ;;
esac
