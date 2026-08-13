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
#   automation/op7/baseline_capture.sh drain <minutes> [label]
#   automation/op7/baseline_capture.sh wakeups <batterystats-file>
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

# Reliable capture: run the remote command, write its output to a device temp
# file, then cat it back. Shizuku's streaming stdout can truncate on large
# outputs; staging on-device avoids that. Retries once if the file is empty.
run_capture() {
  local remote="$1" localfile="$2" need="${3:-}"
  if [[ "$TRANSPORT" != "shizuku" ]]; then
    "$ADB" "${ADB_ARGS[@]}" shell "$remote" > "$localfile"
    return 0
  fi
  local tmp="/data/local/tmp/op7cap-$$.txt" size="" i cur
  shizuku sh -c "$remote > $tmp 2>&1" || true
  for i in 1 2 3 4 5; do
    size="$(shizuku sh -c "wc -c < $tmp" 2>/dev/null | tr -d '[:space:]')"
    [[ -n "$size" ]] && break
    sleep 1
  done
  if [[ -z "$size" ]]; then
    echo "error: cannot probe capture size: $remote" >&2
    return 1
  fi
  for i in $(seq 1 15); do
    shizuku sh -c "cat $tmp" > "$localfile" 2>/dev/null || true
    cur="$(wc -c < "$localfile")"
    [[ "$cur" == "$size" ]] && { shizuku sh -c "rm -f $tmp" >/dev/null 2>&1 || true; break; }
    sleep 1
  done
  shizuku sh -c "rm -f $tmp" >/dev/null 2>&1 || true
  if [[ "$(wc -c < "$localfile")" != "$size" ]]; then
    echo "error: capture incomplete ($(wc -c < "$localfile")/$size bytes): $remote" >&2
    return 1
  fi
  [[ -z "$need" ]] || grep -q "$need" "$localfile" || log "note: '$need' not found in capture (kept as-is)"
  return 0
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

# Health-check the transport between runs (Shizuku can drop under battery
# optimization); tells the user to reopen Shizuku instead of failing silently.
transport_ok() {
  if [[ "$TRANSPORT" == "shizuku" ]]; then
    [[ "$(shizuku whoami 2>&1 | head -n1)" == *shell* ]]
  else
    "$ADB" "${ADB_ARGS[@]}" get-state >/dev/null 2>&1
  fi
}

# Kill the app and verify it is gone (retry loop). Verifies by pid output
# content, not exit code: the Shizuku wrapper can mangle remote exit codes.
kill_ensure() {
  local pids=""
  for _ in 1 2 3; do
    run_sh "am force-stop $PKG" >/dev/null 2>&1 || true
    sleep 2
    pids="$(run_sh "pidof $PKG" 2>/dev/null || true)"
    [[ -n "$pids" ]] || return 0
    log "still alive ($pids), retrying force-stop"
  done
  log "warning: could not verify $PKG stopped; continuing"
}

start_measure() {
  local label="$1" runs="${2:-5}"
  mkdir -p "$OUT_DIR"
  local logfile="$OUT_DIR/${label}.txt"
  : > "$logfile"
  for i in $(seq 1 "$runs"); do
    transport_ok || { echo "error: transport lost (reopen Shizuku / re-enable adb)" >&2; return 1; }
    kill_ensure
    log "$label run $i/$runs"
    {
      echo "=== $label run $i ==="
      run_capture "am start -W -n $COMPONENT" "$OUT_DIR/.run-$i.txt" Complete
      cat "$OUT_DIR/.run-$i.txt"
    } >> "$logfile"
    if grep -q "LaunchState: COLD" "$OUT_DIR/.run-$i.txt"; then
      log "run $i: valid COLD launch"
    else
      log "run $i: NOT a cold launch (skipped in summary)"
    fi
    kill_ensure
    sleep 3
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
    # HOME first so the activity is backgrounded, not top-most.
    run_sh "input keyevent KEYCODE_HOME" >/dev/null 2>&1 || true
    sleep 3
    {
      echo "=== warm run $i ==="
      run_capture "am start -W -n $COMPONENT" "$OUT_DIR/.warm-$i.txt" Complete
      cat "$OUT_DIR/.warm-$i.txt"
    } >> "$logfile"
    if grep -q "TotalTime: 0" "$OUT_DIR/.warm-$i.txt"; then
      log "run $i: TotalTime 0 (activity stayed top-most; warm start needs adb/HOME-capable session)"
    fi
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
  run_capture "dumpsys meminfo $PKG" "$memfile"
  log "results: $memfile"
}

cmd_gfx() {
  mkdir -p "$OUT_DIR"
  run_capture "dumpsys gfxinfo $PKG" "$OUT_DIR/gfxinfo.txt"
  log "results: $OUT_DIR/gfxinfo.txt"
}

# ---- Phase 6: profiling primitives (Shizuku-capable subset) ----

# GPU frame timing: relaunch, scroll the page, dump gfxinfo framestats.
cmd_framestats() {
  mkdir -p "$OUT_DIR"
  log "framestats: launch + 3 swipes"
  kill_ensure
  run_sh "am start -n $COMPONENT" >/dev/null 2>&1 || true
  sleep 8
  for _ in 1 2 3; do
    run_sh "input swipe 540 1700 540 500 250" >/dev/null 2>&1 || true
    sleep 1
  done
  sleep 2
  run_capture "dumpsys gfxinfo $PKG framestats" "$OUT_DIR/framestats.txt"
  python3 "$ROOT_DIR/automation/op7/framestats_analyze.py" "$OUT_DIR/framestats.txt" | tee "$OUT_DIR/framestats-summary.txt"
  log "results: $OUT_DIR/framestats.txt"
}

# Background/process state: which of our processes stay alive after backgrounding.
cmd_procstats() {
  mkdir -p "$OUT_DIR"
  log "procstats: current snapshot (package filter)"
  run_sh "am start -n $COMPONENT" >/dev/null 2>&1 || true
  sleep 6
  run_sh "input keyevent KEYCODE_HOME" >/dev/null 2>&1 || true
  sleep 5
  run_capture "dumpsys procstats --current $PKG" "$OUT_DIR/procstats.txt"
  grep -A4 "io.github.forkmaintainers.iceraven.op7" "$OUT_DIR/procstats.txt" | head -40 > "$OUT_DIR/procstats-pkg.txt" || true
  log "results: $OUT_DIR/procstats.txt (+ procstats-pkg.txt)"
}

# CPU sample of our processes (top, 3 snapshots 2s apart).
cmd_cpu() {
  local secs="${1:-6}"
  mkdir -p "$OUT_DIR"
  local file="$OUT_DIR/cpu.txt"
  : > "$file"
  log "cpu: sampling top for ${secs}s"
  run_sh "am start -n $COMPONENT" >/dev/null 2>&1 || true
  sleep 4
  for i in 1 2 3; do
    {
      echo "=== sample $i ==="
      run_capture "top -b -n 1 -o %CPU,%MEM,RES,NAME | grep -E 'PID|forkmaintainers' | head -8" "$OUT_DIR/.cpu-$i.txt"
      cat "$OUT_DIR/.cpu-$i.txt"
    } >> "$file"
    sleep 2
  done
  log "results: $file"
}

# Page-load probe: launch a URL, sample CPU+mem during load, keep logcat markers.
cmd_page_load() {
  local url="${1:-https://example.com}"
  mkdir -p "$OUT_DIR"
  log "page-load: $url (contended unless idle)"
  kill_ensure
  run_sh "logcat -c" >/dev/null 2>&1 || true
  run_sh "am start -a android.intent.action.VIEW -d '$url' $PKG" >/dev/null 2>&1 || true
  for s in 2 4 8; do
    sleep 2
    run_capture "top -b -n 1 -o %CPU,%MEM,RES,NAME | grep -E 'forkmaintainers' | head -6" "$OUT_DIR/.pl-$s.txt"
  done
  cat "$OUT_DIR/.pl-2.txt" "$OUT_DIR/.pl-4.txt" "$OUT_DIR/.pl-8.txt" > "$OUT_DIR/page-load-cpu.txt"
  run_capture "dumpsys meminfo $PKG" "$OUT_DIR/page-load-meminfo.txt"
  run_capture "logcat -d" "$OUT_DIR/page-load-logcat.txt"
  grep -iE "Displayed|page|load|navigation|GeckoSession" "$OUT_DIR/page-load-logcat.txt" | head -20 > "$OUT_DIR/page-load-markers.txt" || true
  log "results: $OUT_DIR/page-load-*.txt"
}

# Phase 6 sweep: short, contended-friendly; long drains/wakeups need an idle window.
cmd_profile() {
  mkdir -p "$OUT_DIR"
  log "=== Phase 6 profile sweep (contended unless device idle) ==="
  cmd_cold 3
  cmd_mem 1
  cmd_framestats
  cmd_procstats
  log "note: warm-start, clean drain/wakeups, and Perfetto need adb or an idle window (field notes D7/D9)"
  log "profile complete -> $OUT_DIR"
}

cmd_battery_start() {
  run_sh "dumpsys batterystats --reset" >/dev/null
  log "batterystats reset"
}

cmd_battery_stop() {
  local label="${1:-battery}"
  mkdir -p "$OUT_DIR"
  run_capture "dumpsys batterystats" "$OUT_DIR/${label}.txt"
  log "results: $OUT_DIR/${label}.txt"
}

# Screen-off drain test: reset stats, try to sleep the display, wait, dump.
# The phone must be untouched for <minutes> (idle window) for trustworthy data.
cmd_drain() {
  local minutes="${1:-10}" label="${2:-drain}" file
  mkdir -p "$OUT_DIR"
  file="$OUT_DIR/${label}.txt"
  log "drain test: reset stats, screen off, ${minutes} min"
  run_sh "dumpsys batterystats --reset" >/dev/null
  run_sh "input keyevent KEYCODE_SLEEP" >/dev/null 2>&1 || true
  log "waiting ${minutes} min (do not touch the phone)..."
  sleep $((minutes * 60))
  run_sh "input keyevent KEYCODE_WAKEUP" >/dev/null 2>&1 || true
  run_capture "dumpsys batterystats" "$file" || log "warning: partial battery capture"
  log "results: $file"
}

# Extract wakeup/drain summary lines from a batterystats dump file.
cmd_wakeups() {
  local file="${1:?usage: wakeups <batterystats-file>}"
  [[ -f "$file" ]] || { echo "error: no such file: $file"; exit 1; }
  grep -E "Estimated battery capacity|Discharge:|Screen (off|doze|on) discharge|Total (deep|idle) wake:|Wake lock" "$file" | head -30
}

cmd_all() {
  local apk="$1" runs="${2:-5}"
  cmd_install "$apk"
  cmd_cold "$runs"
  cmd_warm "$runs"
  cmd_mem 5
  rm -f "$OUT_DIR"/.run-*.txt "$OUT_DIR"/.warm-*.txt
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
  framestats)     cmd_framestats ;;
  procstats)      cmd_procstats ;;
  cpu)            cmd_cpu "${2:-6}" ;;
  page-load)      cmd_page_load "${2:-https://example.com}" ;;
  profile)        cmd_profile ;;
  battery-start)  cmd_battery_start ;;
  battery-stop)   cmd_battery_stop "$2" ;;
  drain)          cmd_drain "${2:-10}" "${3:-drain}" ;;
  wakeups)        cmd_wakeups "$2" ;;
  all)            cmd_all "$2" "${3:-5}" ;;
  *) sed -n '2,20p' "$0" >&2; exit 1 ;;
esac
