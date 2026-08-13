#!/usr/bin/env bash
# Phase 7 r5 (C1): verify GeckoView uses HARDWARE media codecs during playback.
# Usage: media_probe.sh <label> <url> [outdir]
#   label: avc | hevc | vp9 | ...
# Samples CPU of app + media processes during playback, captures codec logcat
# lines (RISH transport spam filtered out) and NuPlayer state.
set -euo pipefail

PKG="io.github.forkmaintainers.iceraven.op7"
LABEL="${1:?usage: media_probe.sh <label> <url>}"
URL="${2:?usage: media_probe.sh <label> <url>}"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${3:-$ROOT_DIR/docs/performance/data/$(date -u +%Y%m%d-%H%M%S)-media-$LABEL}"
mkdir -p "$OUT_DIR"

log() { echo "[media-probe] $*"; }

log "== $LABEL: $URL =="
shizuku sh -c "am force-stop $PKG" >/dev/null 2>&1 || true
sleep 2
shizuku sh -c "logcat -c" >/dev/null 2>&1 || true
shizuku sh -c "am start -a android.intent.action.VIEW -d '$URL' -n $PKG/.App" >/dev/null 2>&1 || true

# CPU samples every 4s during playback (decode is bursty; one sample misses it)
for i in 1 2 3 4 5 6; do
  sleep 4
  shizuku sh -c "top -b -n 1 -o %CPU,%MEM,RES,NAME 2>/dev/null | grep -iE 'PID|forkmaintainers|mediaserver|media.codec|audioserver|mediadrmserver' | head -10" > "$OUT_DIR/cpu-$i.txt" 2>/dev/null || true
  echo "--- sample $i ---" >> "$OUT_DIR/cpu-all.txt"
  cat "$OUT_DIR/cpu-$i.txt" >> "$OUT_DIR/cpu-all.txt"
done

# Codec evidence: which decoder was used? (hardware = c2.qti*/OMX.qcom*, software = c2.android*/OMX.google*)
shizuku sh -c "logcat -d" > "$OUT_DIR/logcat.txt" 2>/dev/null || true
grep -aiE "ccodec|acodec|mediacodec|omx| c2\.|codec2|configureCodec|MediaCodecProxy" "$OUT_DIR/logcat.txt" | grep -av "RISH" | tail -25 > "$OUT_DIR/codec-lines.txt" || true
shizuku sh -c "dumpsys media.player" > "$OUT_DIR/media-player.txt" 2>/dev/null || true
shizuku sh -c "dumpsys media.codec" > "$OUT_DIR/media-codec.txt" 2>/dev/null || true

# Summary
echo "=== $LABEL summary ==="
echo "-- peak CPU (app + media procs) --"
grep -hoE "^[ 0-9]+" "$OUT_DIR"/cpu-*.txt | tr -d ' ' | sort -rn | head -3 | while read -r c; do echo "  ${c}%"; done
echo "-- codec log lines (hw=OMX.qcom/c2.qti, sw=OMX.google/c2.android) --"
grep -aoE "c2\.[a-z]+\.[a-z0-9_.-]*|OMX\.[a-z]+\.[a-z0-9_.-]*|MediaCodec[A-Za-z]*|CCodec|ACodec" "$OUT_DIR/codec-lines.txt" | sort | uniq -c | sort -rn | head -12 || echo "  (no codec lines captured)"
echo "-- NuPlayer last state --"
grep -E "state|atEOS|mime|looping" "$OUT_DIR/media-player.txt" | head -6 || true
log "results: $OUT_DIR"
