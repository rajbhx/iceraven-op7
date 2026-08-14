# Session digest — 2026-08-14 — self-updating skill

## Problems solved
- **P** the op7-special-build skill that agents actually load (/root/.shared-skills/op7-special-build) was a static copy of the playbook repo's skills/op7-special-build — it could silently drift from the playbook source, so agents would re-derive stale knowledge
  cause: no updater, no version marker; the playbook repo auto-syncs its notes layer but nothing pushed the skill directory to installs
  solution: bundled scripts/update_skill.sh into the skill itself — cheap git ls-remote check against the playbook HEAD vs a .skill-installed-commit marker; only on change does it sparse-fetch, validate SKILL.md, and atomically swap with a timestamped backup (restores on failure); offline/rate-limited keeps the current copy and warns; resolves ~/.codex/skills symlink to update the real root; PLAYBOOK_REPO/SKILL_ROOT/EXTRA_SKILL_ROOTS overrides for other machines; SKILL.md/quickstart/README/AGENTS.md now tell agents to run it at session start
  section: G
  tags: skill, self-update, automation, playbook, bootstrap
- **P** local shellcheck/actionlint can't run under this sandbox (shellcheck binary gets killed), so workflow fixes had to round-trip through CI
  cause: exec sandbox terminates the shellcheck subprocess; actionlint calls it per script
  solution: rely on the CI actionlint step as the authoritative check (it runs in a container); keep local python yaml.safe_load as a fast pre-check
  section: E
  tags: actionlint, sandbox, ci
