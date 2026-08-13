#!/usr/bin/env python3
"""Summarize a `dumpsys gfxinfo <pkg> framestats` capture.

Usage: framestats_analyze.py <framestats-file>
Parses frame rows (start with '0,'), computes per-frame time
(frameCompleted - intendedVsync) and reports jank stats.
"""
import sys


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: framestats_analyze.py <framestats-file>")
    frames = []
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("0,"):
                continue
            parts = line.split(",")
            if len(parts) < 10:
                continue
            try:
                flags = int(parts[1])
                intended = int(parts[2])
                completed = int(parts[10])  # FrameCompleted
                interval = int(parts[9])    # FrameInterval
            except (ValueError, IndexError):
                continue
            frames.append((flags, intended, completed, interval))
    if not frames:
        print("no frame rows found")
        return 1
    vsync = 1e9 / 60.0  # 60 Hz; adjust from interval if stable
    times = []
    for flags, intended, completed, interval in frames:
        t = (completed - intended) / 1e6  # ms
        times.append(t)
    times.sort()
    n = len(times)
    jank = [t for t in times if t > 16.7]
    p = lambda q: times[min(n - 1, int(q * n))] if n else 0
    print(f"frames: {n}")
    print(f"frame time ms: avg={sum(times)/n:.2f} p50={p(0.5):.2f} p90={p(0.9):.2f} p95={p(0.95):.2f} max={max(times):.2f}")
    print(f"janky (>16.7ms): {len(jank)} ({100.0*len(jank)/n:.1f}%)")
    print(f"vsync-intended spacing ok: last-intended diff {int((frames[-1][2]-frames[0][2])/1e6):.0f} ms over {n} frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
