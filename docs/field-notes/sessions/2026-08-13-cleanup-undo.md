# Session digest — 2026-08-13 — cleanup undo: restore disabled packages

## Problems solved
- **P** user asked to undo bulk per-user uninstalls on a daily-driver phone
  cause: cleanup removed 12 already-disabled packages via pm uninstall --user 0 without asking first
  solution: restore exactly via `pm install-existing --user 0 <pkg>` then `pm disable-user --user 0 <pkg>`; verify with `pm list packages -d` matches the original list. Rule: on a daily-driver, present a candidate list and get a go-ahead before uninstalling packages; files/app-data need explicit confirmation too
  section: C
  tags: uninstall, restore, safety, daily-driver
