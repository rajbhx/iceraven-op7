# Session digest — 2026-08-13 — Playbook helper layer: searchable low-token notes

## Problems solved
- **P** full journey tables (docs/09, projects/*/README.md) cost agents too many tokens
  cause: every entry rendered in one big markdown table; an agent must read all of it to find one answer
  solution: notes/ layer — INDEX.md keyword->ids map (grep-able, ~150 lines), one entries/<id>.md per problem, lookup.py ranked search; agents read only the matching entry
  section: G
  tags: playbook, tokens, search
- **P** keyword auto-extraction produced a noisy index (478 lines of '1.5', '2-core', 'add')
  cause: naive tokenization of problem+cause+solution text
  solution: curated INDEX from problem text + explicit tags only; full text kept in index.json for ranked lookup.py matching; stopwords + prefix-collapse
  section: G
  tags: keywords, search, index
- **P** conversation digests lived only in the build repo, not the playbook
  cause: playbook sync fetched only log.yml
  solution: sync also lists docs/field-notes/sessions and fetches each *.md (skip _template) into _logs/sessions/<slug>/; SESSIONS.md generated with summaries
  section: G
  tags: sessions, conversations, sync
- **P** optional tags would be stripped by session_to_notes re-render
  cause: canonical renderer wrote only id/problem/cause/solution
  solution: renderer + digest parser now carry tags: [...] through
  section: G
  tags: tags, tooling, yaml
