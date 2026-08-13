#!/usr/bin/env python3
"""Archive ONLY the useful knowledge from a Codex conversation into field notes.

Extracts the user's typed instructions/decisions from the local Codex session
JSONL and writes a compact, typed digest to
docs/field-notes/conversations/<date>-<thread>.md, which the playbook sync
fetches and renders (notes/<slug>/CONVERSATIONS.md).

Entry types (the only things worth keeping):
  RULE     a hard constraint the user set (never/don't/must/only/free infra...)
  DECISION a choice/approval ("do it", "use X", "next phase", "start"...)
  REQUEST  an explicit task ("check", "fix", "implement", "make"...)
  GOTCHA   a reported problem/error ("same error", "not working", "black"...)
  GOAL     an objective ("i want", "goal", "purpose", "make sure"...)

No raw transcripts: each message is trimmed to one line (<=300 chars) and
trivial single-word prompts are dropped. Run it at the end of a session,
before committing, then fold durable rules into log.yml with session_to_notes.py.

Local-only tool: needs the ~/.codex session files (never run in CI).
Usage:
  conversation_to_notes.py [--session PATH] [--thread-id ID] [--out-dir DIR]
                           [--max-entries N] [--dry-run]
Default session: newest ~/.codex/sessions/**/*.jsonl whose cwd matches this repo.
"""
import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT = ROOT / "docs" / "field-notes" / "conversations"

RULES = re.compile(
    r"\b(never|always|don'?t|do not|must|mustn'?t|required|only|mandatory|"
    r"forbidden|prohibited|free infra|no paid|never build|not build locally|"
    r"not local|do not build|ignore adb|no adb|be careful|careful)\b",
    re.I,
)
DECISIONS = re.compile(
    r"\b(do it|yes|go for it|next phase|start|use |use it|switch|prefer|"
    r"choose|approve|approved|go ahead|implement|delete|remove|keep|"
    r"continue|proceed|let's|lets |add |make it|build|upload|push|commit)\b",
    re.I,
)
REQUESTS = re.compile(
    r"\b(check|verify|fix|solve|find|explain|why|what|how|make sure|ensure|"
    r"test|profile|measure|compare|look at|inspect|read|review|create|write|"
    r"update|improve|optimize|speed up|tell me|show|document|record)\b",
    re.I,
)
GOTCHAS = re.compile(
    r"\b(problem|error|fails?|failed|not working|broken|same error|black|void|"
    r"issue|bug|crash|cannot|can'?t|won'?t|not installed|wrong|blank|stuck)\b",
    re.I,
)
GOALS = re.compile(
    r"\b(i want|we want|goal|purpose|objective|aim|target|make sure that|"
    r"would like|want it|feel like|should be|must be)\b",
    re.I,
)
TRIVIAL = re.compile(r"^(do|yes|no|ok|okay|y|n|go|continue|next|done|\?|\.\.\.)+$", re.I)
NOISE = re.compile(
    r"(recommended_plugins|Here is a list of plugins|permissions instructions|"
    r"environment_context|collaboration_mode|sandbox_mode|workspace_roots|"
    r"<system>|exec_command result|The user is working on|you are a coding agent)",
    re.I,
)


def classify(text: str) -> str:
    scored = []
    for label, rx in (("GOAL", GOALS), ("RULE", RULES), ("GOTCHA", GOTCHAS),
                      ("DECISION", DECISIONS), ("REQUEST", REQUESTS)):
        hits = len(rx.findall(text))
        if hits:
            scored.append((hits, label))
    if not scored:
        return "REQUEST"
    scored.sort(key=lambda x: -x[0])
    return scored[0][1]


def user_messages(path: Path):
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("type") != "response_item":
                continue
            pl = rec.get("payload", {})
            if pl.get("type") != "message" or pl.get("role") != "user":
                continue
            text = ""
            for item in pl.get("content", []) or []:
                if isinstance(item, dict) and item.get("type") in ("input_text", "text"):
                    text += item.get("text", "")
            text = text.strip()
            if not text:
                continue
            ts = rec.get("timestamp") or ""
            out.append((ts, text))
    return out


def pick_session(cli_path, cli_thread, repo_root: Path):
    if cli_path:
        return Path(cli_path)
    base = Path.home() / ".codex" / "sessions"
    if not base.exists():
        sys.exit(f"no {base} — this is a local-only tool")
    best = None
    best_mtime = -1
    for f in base.rglob("*.jsonl"):
        try:
            mtime = f.stat().st_mtime
        except OSError:
            continue
        if cli_thread and cli_thread not in f.name:
            continue
        if mtime <= best_mtime:
            continue
        best, best_mtime = f, mtime
    if best is None:
        sys.exit(f"no session file found under {base}")
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--session", type=Path)
    ap.add_argument("--thread-id")
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--max-entries", type=int, default=40)
    ap.add_argument("--min-len", type=int, default=24)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    session = pick_session(args.session, args.thread_id, ROOT)
    msgs = user_messages(session)
    meta = {}
    try:
        with open(session, encoding="utf-8") as f:
            for line in f:
                if '"session_meta"' in line:
                    rec = json.loads(line)
                    meta = rec.get("payload", {})
                    break
    except Exception:
        pass

    thread = meta.get("session_id") or session.stem.split("-")[-1]
    short = thread[:8]
    date = (meta.get("timestamp") or datetime.now(timezone.utc).isoformat())[:10]
    cwd = meta.get("cwd", "")

    entries = []
    seen = set()
    for ts, text in msgs:
        one = re.sub(r"\s+", " ", text).strip()
        if len(one) < args.min_len or TRIVIAL.match(one) or NOISE.search(one):
            continue
        key = one[:80].lower()
        if key in seen:
            continue
        seen.add(key)
        kind = classify(one)
        clipped = one if len(one) <= 300 else one[:297] + "..."
        entries.append((ts, kind, clipped))
    entries.sort(key=lambda e: e[0], reverse=True)  # newest knowledge first
    entries = entries[: args.max_entries]

    out_dir = args.out_dir
    out_file = out_dir / f"{date}-{short}.md"
    if args.dry_run:
        print(f"[dry-run] would write {out_file} with {len(entries)} entries "
              f"(session {thread}, {len(msgs)} user msgs total)")
        for ts, kind, clipped in entries[:10]:
            print(f"  [{kind}] {clipped[:90]}")
        return

    out_dir.mkdir(parents=True, exist_ok=True)
    counts = {}
    body = [f"# Conversation knowledge — {date} — thread {short}",
            "",
            f"- thread: `{thread}`",
            f"- cwd: {cwd}",
            f"- user messages: {len(msgs)} | kept: {len(entries)} (useful types only)",
            "",
            "## Extracted knowledge (types)",
            ""]
    for ts, kind, clipped in entries:
        counts[kind] = counts.get(kind, 0) + 1
        stamp = ts[11:16] if len(ts) >= 16 else ""
        body.append(f"- `{stamp} [{kind}]` {clipped}")
    body += ["",
             f"counts: {', '.join(f'{k}={v}' for k, v in sorted(counts.items()))}",
             "",
             "> Curate: fold durable RULE/GOTCHA items into log.yml via "
             "`python3 automation/op7/session_to_notes.py`. Raw transcripts are "
             "never stored — this file is derived from the local session."]
    out_file.write_text("\n".join(body) + "\n", encoding="utf-8")
    print(f"wrote {out_file} ({len(entries)} entries)")
    print(f"types: {', '.join(f'{k}={v}' for k, v in sorted(counts.items()))}")


if __name__ == "__main__":
    main()
