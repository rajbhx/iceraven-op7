# Session digest — 2026-08-14 — project-intake skill for the playbook

## Problems solved
- **P** starting a new special-build project meant hand-writing projects/<slug>/manifest.yml + roadmap + workflow + onboarding from scratch, and classifying a candidate repo's engine was tribal knowledge
  cause: no tooling between "found a repo" and "projects/<slug> scaffolded"; engine mapping (geckoview vs webview vs native vs other) lived only in AGENTS.md/validators
  solution: new project-intake Codex skill in the playbook — skills/project-intake/ with scripts/intake.py that walks a repo for build-system signals (GeckoView/AC markers, android.webkit, Flutter pubspec, Cargo.toml, package.json+electron, CMake, Python), maps to the manifest engine enum, discovers ABI best-effort, and drafts manifest.yml (TODO for uninferrable fields, passes validate_manifests) + roadmap.md (phases 0-10 per engine type) + workflow.md (stack-specific commands) + PROMPT.md; unclassifiable repos are flagged for enum extension and never drafted; existing projects/<slug> is never overwritten (writes intake-drafts/<slug> + diff)
  section: G
  tags: playbook, skill, intake, classification, scaffolding, automation
- **P** the skill updater/installer were hard-wired to one skill name (op7-special-build)
  cause: update_skill.sh hardcoded SKILL_NAME; install_skill.sh installed a single skills/<name>
  solution: updater now derives SKILL_NAME from its own directory (generic for any skills/<name>); install_skill.sh installs ALL skills/ dirs from the playbook (SKILL_NAMES override for subsets); verified fresh install of both skills + markers on the device
  section: E
  tags: skill, updater, installer, generic, multi-skill
