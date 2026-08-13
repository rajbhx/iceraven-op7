# Session digest — 2026-08-13 — r6b: playbook sync gap + conversation knowledge

## Problems solved
- **P** playbook was stale after a push — it only synced weekly + manual, and nothing triggered it on build-repo pushes
  cause: playbook-sync.yml scheduled `0 3 * * 1` (Monday only); no repository_dispatch/PAT wiring from the build repo
  solution: playbook-sync now polls every 6h (`0 */6 * * *`) — self-contained, no cross-repo secrets, also resets GitHub's 60-day scheduled-workflow window; manual dispatch used immediately
  section: G
  tags: playbook, sync, schedule, automation
- **P** the original user engineering specification (ROLE, 35 requirements, success criteria) and day-to-day operating rules were not preserved verbatim anywhere
  cause: playbook carried only distilled golden rules (AGENTS.md, skill); the master prompt lived only in the conversation
  solution: added docs/00-master-spec.md to the playbook (canonical contract: engineering spec + Part B user operating rules: no local builds, Shizuku not adb, free infra only, 30-min windows, daily-driver care, playbook auto-update) and wired it into the skill references
  section: G
  tags: playbook, spec, rules, agents
- **P** conversations were only summarized by hand-written digests; raw chat knowledge was not systematically captured
  cause: session digests depend on the agent writing them; nothing read the actual Codex session files
  solution: new local tool automation/op7/conversation_to_notes.py extracts ONLY useful typed knowledge (RULE/DECISION/REQUEST/GOTCHA/GOAL, trimmed ≤300 chars, newest-first, noise-filtered) from ~/.codex/sessions JSONL into docs/field-notes/conversations/; playbook sync fetches them and renders notes/<slug>/CONVERSATIONS.md; raw transcripts are never stored
  section: G
  tags: conversations, extraction, tooling, low-token
- **P** conversation extraction initially included system-injected noise (recommended_plugins block) and dropped the newest messages under the entry cap
  cause: injected preamble arrives as a user-role message; chronological collection hit the 40-entry cap first
  solution: NOISE regex filter (recommended_plugins/permissions/environment tags) + newest-first sort so today's knowledge always survives trimming
  section: G
  tags: extraction, noise, ordering

## Notes
- r6 settings-black fix (patch 005 v2, commit 2c70dc0) was pushed and the fast validation build (31732263093) dispatched; still compiling at last check.
- playbook-sync cadence change + master-spec + conversation layer are in the playbook repo (rajbhx/op7-special-build-playbook).
