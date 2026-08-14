# Session digest — 2026-08-14 — Playbook sync log-schema fixes

Fixed three related playbook-sync bugs while registering the DeepDenoiser and
Rain projects. All fixed at the root (scripts + parser), verified end-to-end
via a dispatched Playbook Sync run.

## Problems solved
- **P** playbook sync crashed when a project log used the flat-list shape (no sections: key)
  cause: new repos wrote log.yml as a bare YAML list of entries; generate_project_docs.py expected a dict with sections
  solution: scripts normalize both shapes (flat list wrapped into one section); canonical shape documented in skill reference field-notes-sync.md; both repos canonicalized
  section: G
  tags: [playbook, yaml, schema, sync, field-notes]
- **P** session_to_notes dedupe missed long problems, appending duplicate entries
  cause: dedupe checked problem text against RAW file text; line-wrapped long scalars never matched
  solution: dedupe against PARSED problem texts; entries stay unique; re-ran clean on both repos
  section: G
  tags: [tooling, yaml, dedupe, session-notes]
- **P** tags rendered as [[a, b]] (nested list) in logs
  cause: digest parser kept the square brackets from 'tags: [a, b]' lines; join re-added them
  solution: parse_digest strips surrounding brackets; build_notes flattens nested tags defensively
  section: G
  tags: [tags, tooling, yaml, parser]
- **P** human journey doc shrank when a young project registered first
  cause: build_notes picked the first alphabetically-sorted log for docs/09
  solution: journey now selects the project with the most entries; docs/09 stays the richest history
  section: G
  tags: [playbook, journey, docs, sync]
