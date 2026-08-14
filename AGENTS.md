# AGENTS.md — Iceraven OP7 build repo

This repo produces an OnePlus 7–optimized Iceraven (Fenix + GeckoView) APK,
arm64-v8a only, via GitHub Actions. Iceraven upstream is
`fork-maintainers/iceraven-browser`; OP7 changes are a thin patch layer only
(`patches/op7/NNN-*.patch`, apply in order 001→002→003→004). Never fork the
app source, never replace GeckoView with WebView.

## Before doing anything

- If your environment supports skills, load the `op7-special-build` skill and
  refresh it first (self-updating):
  `bash /root/.shared-skills/op7-special-build/scripts/update_skill.sh`
  (one `git ls-remote` when up to date; sparse fetch + atomic backup on change;
  offline keeps the current copy).
- Otherwise use the playbook: `gh repo clone rajbhx/op7-special-build-playbook`,
  then `python3 scripts/lookup.py <problem words>` (or grep `notes/*/INDEX.md`)
  before re-deriving anything. Every solved problem is recorded there.

## Hard rules (from the field)

- Baseline before optimization; measure on the real device; label data "contended"
  if the device was in use. Never optimize on assumptions.
- One measured optimization per revision (`op7r<N>` in `op7-revision.txt`);
  benchmark before/after; revert on regression.
- Patch iteration: dispatch CI with `-f fast=true` (no R8, ~13 min). Full
  release builds (~40 min) only when ready.
- Regenerating a patch after `git reset` loses hunks: re-`git add` ALL touched
  files before `git diff --cached`, then grep the patch for expected
  `diff --git` lines and imports.
- Never publish an unvalidated build; upstream conflicts stop the pipeline.
- Never commit signing keys, APKs, or large binaries (`op7apk/` is ignored for
  a reason). Free infra only: GitHub Actions/Releases/caches.

## Recording lessons (keeps everything self-maintaining)

1. Write `docs/field-notes/sessions/<date>-<topic>.md` (see `_template.md`):
   `**P** problem` / `cause:` / `solution:` / `section:` / optional `tags:`.
2. `python3 automation/op7/session_to_notes.py <digest>` → appends to
   `docs/field-notes/log.yml` (dedupe, auto-id, preserves tags).
3. `python3 automation/op7/conversation_to_notes.py` → archives the useful
   typed knowledge (RULE/DECISION/REQUEST/GOTCHA/GOAL) from the local Codex
   session into `docs/field-notes/conversations/` (local-only, trimmed, never
   raw transcripts).
4. Commit + push. The playbook sync workflow (every 6h + manual +
   repository_dispatch) regenerates its searchable notes layer automatically —
   no other action needed.
