# Field Notes — reusable OP7 build knowledge

Everything learned while building this project (problems, root causes, fixes)
is maintained in a standalone, app-agnostic playbook:

**https://github.com/rajbhx/op7-special-build-playbook**

Highlights you can reuse for other apps / special builds:

- `projects/iceraven-op7/README.md` — auto-generated problems→solutions log
  (testOnly APK, Shizuku stdout races, transfer tricks, cache outages, etc.)
- `projects/` — register any new app in `projects/<slug>/manifest.yml`; the
  playbook syncs its field-notes log automatically (see `AGENTS.md` for agents)
- `docs/02-device-access-and-transfer.md` — adb-less device access via Shizuku,
  staging installs, loopback transfers, proot quirks
- `docs/04-build-pipeline-blueprint.md` — GitHub Actions build/sign/gate pattern
- `docs/05-github-free-tier-operations.md` — staying inside free limits forever
- `docs/10-porting-playbook.md` — step-by-step to apply this to another app

In this repo, the same knowledge is captured operationally in:
`docs/op7-project-audit.md`, `docs/roadmap.md` (error matrix), `docs/baseline.md`,
`docs/performance/baseline.md`, and the error matrix inside `docs/roadmap.md`.

## Auto-update

This repo is the **source of truth** for field notes: `docs/field-notes/log.yml`
(structured, machine-readable). The playbook repo
(`rajbhx/op7-special-build-playbook`) regenerates its journey doc from it on a
schedule and on demand — add an entry to `log.yml` whenever a problem is solved
and the playbook updates itself on the next sync.

## Conversation → playbook pipeline (how sessions feed the playbook)

1. At the end of a working session, write `docs/field-notes/sessions/<date>-<topic>.md`
   using `_template.md` (one `- **P**` block per problem with cause/solution/section).
2. Run `python3 automation/op7/session_to_notes.py <that file>` — auto-appends to
   `log.yml` (dedupe + auto-ids), no manual YAML editing.
3. Push — the playbook repo's `Playbook Sync` workflow fetches `log.yml` and
   regenerates the journey docs automatically (weekly + manual + dispatch).

This makes the chat→playbook path a 2-command discipline instead of manual
editing; the repo→playbook half is fully automatic.
