# Session digest — 2026-08-14 — omni-browser inspiration review

## Problems solved
- **P** need OP7 "new things" without cloning a second browser repo
  cause: omni-browser (REBEL-ROOT) is a GeckoView-based browser; it is GPL-3.0 and a greenfield Compose app, not a Fenix fork
  solution: reviewed via GitHub API only (tree + README + OmniApplication.kt + force_dark ext + release.yml); extracted transferable patterns into docs/oneplus7/omni-inspiration.md; recorded do-not-copy list + GPL-3.0 boundary
  section: G
  tags: [research, inspiration, amoled, addons, gpl-3.0, release]
- **P** web content stays light even after app UI is pure-black
  cause: 005-amoled-dark patches only the app UI resources, not page rendering
  solution: omni's force_dark MV2 extension (smart detection, scoped CSS, media-protected) is the transferable model; ship via add-on now (Option A), bundle as a measured r8 patch later (Option B)
  section: F
  tags: [amoled, webcontent, addons]

## Notes
- GPL-3.0 (omni) vs MPL-2.0 (Iceraven/OP7): patterns only, never copy source.
- omni startup no-flash pattern == our 004 + 005 outcome; no new work needed.
- maintenance.yml already auto-cleans artifacts/caches/runs older than 14 days monthly.
