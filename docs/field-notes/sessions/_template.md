# Session digest — <date> — <what was worked on>

One file per working session. After the session, run:
  python3 automation/op7/session_to_notes.py docs/field-notes/sessions/<this-file>
to append the problems/solutions to docs/field-notes/log.yml (auto-dedupe,
auto-ids). The playbook repo then auto-syncs from log.yml.

## Problems solved
- **P** <one-line problem statement>
  cause: <root cause, one line>
  solution: <fix, one line>
  section: <A|B|C|D|E|F>   # optional; default = last section in log

## Notes (optional)
- <anything worth keeping, one bullet per line>
