#!/usr/bin/env python3
"""Append session-digest lessons to docs/field-notes/log.yml (auto-synced to the playbook).

Usage: session_to_notes.py <session-digest.md>
Reads `## Problems solved` blocks:
  - **P** <problem>
    cause: <root cause>
    solution: <fix>
    section: <A-F>   (optional, default: last section in log)
Model-based: loads the log with yaml, appends entries, re-renders canonically
(dedupe by problem text, auto-ids). Safe to run repeatedly.
"""
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent.parent
LOG = ROOT / "docs" / "field-notes" / "log.yml"


def esc(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def render(log_text: str, data: dict) -> str:
    head, _, rest = log_text.partition("sections:")
    sig_marker = "recurring_signature: |"
    sig = ""
    if sig_marker in rest:
        sig = rest.split(sig_marker, 1)[1].lstrip("\n")
        sig = "\n".join(line[2:] if line.startswith("  ") else line for line in sig.splitlines())
    out = head + "sections:\n"
    for section in data["sections"]:
        out += f"  - id: {section['id']}\n"
        out += f"    title: {section['title']}\n"
        out += "    entries:\n"
        for entry in section["entries"]:
            out += f"      - id: {entry['id']}\n"
            out += f"        problem: \"{esc(entry['problem'])}\"\n"
            out += f"        cause: \"{esc(entry['cause'])}\"\n"
            out += f"        solution: \"{esc(entry['solution'])}\"\n"
    out += "recurring_signature: |\n"
    out += "\n".join("  " + line if line else "" for line in sig.splitlines()) + "\n"
    return out


def parse_digest(text: str):
    problems = []
    current = None
    for raw in text.splitlines():
        line = raw.strip()
        idx = line.find("**P")
        if idx >= 0 and "**" in line[idx + 3:]:
            if current:
                problems.append(current)
            current = {"problem": line.split("**")[2].strip(), "cause": "", "solution": "", "section": None}
        elif current is not None:
            m = re.match(r"^cause:\s*(.+)$", line)
            if m:
                current["cause"] = m.group(1).strip()
            m = re.match(r"^solution:\s*(.+)$", line)
            if m:
                current["solution"] = m.group(1).strip()
            m = re.match(r"^section:\s*([A-Z])$", line)
            if m:
                current["section"] = m.group(1)
    if current:
        problems.append(current)
    return [p for p in problems if p["problem"]]


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: session_to_notes.py <session-digest.md>")
    digest = Path(sys.argv[1])
    if not digest.is_file():
        sys.exit(f"no such digest: {digest}")
    problems = parse_digest(digest.read_text())
    if not problems:
        print("no problem blocks found; nothing to do")
        return

    log_text = LOG.read_text()
    data = yaml.safe_load(log_text)
    sections = {s["id"]: s for s in data["sections"]}
    added = 0
    for p in problems:
        if p["problem"] in log_text:
            print(f"skip (already logged): {p['problem'][:60]}")
            continue
        section_id = p["section"] or data["sections"][-1]["id"]
        if section_id not in sections:
            sections[section_id] = {"id": section_id, "title": "Additional", "entries": []}
            data["sections"].append(sections[section_id])
        entries = sections[section_id]["entries"]
        n = 1
        while any(e["id"] == f"{section_id}{n}" for e in entries):
            n += 1
        entries.append({"id": f"{section_id}{n}", "problem": p["problem"],
                        "cause": p["cause"], "solution": p["solution"]})
        added += 1
        print(f"added {section_id}{n}: {p['problem'][:60]}")

    LOG.write_text(render(log_text, data))
    # validate
    with open(LOG) as f:
        d2 = yaml.safe_load(f)
    print("total entries now:", sum(len(s["entries"]) for s in d2["sections"]),
          "| sections:", [s["id"] for s in d2["sections"]])


if __name__ == "__main__":
    main()
