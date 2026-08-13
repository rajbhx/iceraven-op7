#!/usr/bin/env python3
"""Append session-digest lessons to docs/field-notes/log.yml (auto-synced to the playbook).

Usage: session_to_notes.py <session-digest.md>
Reads `## Problems solved` blocks:
  - **P** <problem>
    cause: <root cause>
    solution: <fix>
    section: <A-F>   (optional, default: last section in log)
Dedupes by problem text; auto-assigns the next id in the section.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
LOG = ROOT / "docs" / "field-notes" / "log.yml"

def load_sections(text):
    sections = {}
    cur = None
    for line in text.splitlines():
        m = re.match(r"^  - id: ([A-Z])\n?$", line) or re.match(r"^  - id: ([A-Z])$", line)
        if m:
            cur = m.group(1)
            sections.setdefault(cur, {"start": None, "end": None, "ids": set()})
        elif cur is not None:
            s = sections[cur]
            if s["start"] is None:
                s["start"] = None
            m2 = re.match(r"^      - id: (\S+)$", line)
            if m2:
                sections[cur]["ids"].add(m2.group(1))
    return sections

def main():
    if len(sys.argv) != 2:
        sys.exit("usage: session_to_notes.py <session-digest.md>")
    digest = Path(sys.argv[1])
    if not digest.is_file():
        sys.exit(f"no such digest: {digest}")
    dtext = digest.read_text()

    log = LOG.read_text()
    # section spans: find '  - id: X' block starts and the tail marker
    lines = log.splitlines(keepends=True)
    section_starts = {}
    for i, line in enumerate(lines):
        m = re.match(r"^  - id: ([A-Z])$", line.rstrip("\n"))
        if m:
            section_starts[m.group(1)] = i
    tail = None
    for i, line in enumerate(lines):
        if line.startswith("recurring_signature:"):
            tail = i
            break

    problems = []
    current = None
    for raw in dtext.splitlines():
        line = raw.strip()
        if ("**P" in line) and ("**" in line[line.find("**P") + 3:]):
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
            m = re.match(r"^section:\s*([A-F])$", line)
            if m:
                current["section"] = m.group(1)
    if current:
        problems.append(current)

    if not problems:
        print("no problem blocks found; nothing to do")
        return

    existing_sections = sorted(section_starts)
    added = 0
    for p in problems:
        if not p["problem"]:
            continue
        if p["problem"] in log:
            print(f"skip (already logged): {p['problem'][:60]}")
            continue
        section = p["section"] or existing_sections[-1]
        ids = set(re.findall(rf"^      - id: ({re.escape(section)}\d+)$", log, re.M))
        n = 1
        while f"{section}{n}" in ids:
            n += 1
        entry = (
            f"      - id: {section}{n}\n"
            f"        problem: \"{p['problem']}\"\n"
            f"        cause: \"{p['cause']}\"\n"
            f"        solution: \"{p['solution']}\"\n"
        )
        if section in section_starts:
            # insert after the last entry line of this section
            idx = section_starts[section]
            end = section_starts.get(existing_sections[existing_sections.index(section) + 1], tail) if existing_sections.index(section) + 1 < len(existing_sections) else tail
            block = "".join(lines[idx:end])
            last_entry = max(block.rfind("      - id:"), 0)
            insert_at = idx + block[:last_entry].count("\n") + 1 if False else None
            # simpler: find last '      - id:' line within the section block
            pos = -1
            search_start = idx
            for j in range(idx, end):
                if re.match(r"^      - id: ", lines[j]):
                    pos = j
            if pos >= 0:
                lines.insert(pos + 1, entry)
            else:
                # no entries yet: insert right after 'entries:' line
                for j in range(idx, end):
                    if lines[j].strip() == "entries:":
                        lines.insert(j + 1, entry)
                        break
        else:
            # new section: insert before tail (or append)
            new_block = (
                f"  - id: {section}\n"
                f"    title: {('UI / perceived performance' if section == 'F' else 'Additional')}\n"
                f"    entries:\n"
            ) + entry
            if tail is not None:
                lines.insert(tail, new_block)
            else:
                lines.append(new_block)
        added += 1
        LOG.write_text("".join(lines))
        log = LOG.read_text()
        lines = log.splitlines(keepends=True)
        section_starts = {}
        for i, line in enumerate(lines):
            m = re.match(r"^  - id: ([A-Z])$", line.rstrip("\n"))
            if m:
                section_starts[m.group(1)] = i
        existing_sections = sorted(section_starts)
        print(f"added {section}{n}: {p['problem'][:60]}")

    import yaml
    with open(LOG) as f:
        data = yaml.safe_load(f)
    print("total entries now:", sum(len(s["entries"]) for s in data["sections"]))

if __name__ == "__main__":
    main()
