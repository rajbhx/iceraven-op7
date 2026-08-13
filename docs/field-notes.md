# Field Notes — reusable OP7 build knowledge

Everything learned while building this project (problems, root causes, fixes)
is maintained in a standalone, app-agnostic playbook:

**https://github.com/rajbhx/op7-special-build-playbook**

Highlights you can reuse for other apps / special builds:

- `docs/09-field-notes-journey.md` — chronological problems→solutions log
  (testOnly APK, Shizuku stdout races, transfer tricks, cache outages, etc.)
- `docs/02-device-access-and-transfer.md` — adb-less device access via Shizuku,
  staging installs, loopback transfers, proot quirks
- `docs/04-build-pipeline-blueprint.md` — GitHub Actions build/sign/gate pattern
- `docs/05-github-free-tier-operations.md` — staying inside free limits forever
- `docs/10-porting-playbook.md` — step-by-step to apply this to another app

In this repo, the same knowledge is captured operationally in:
`docs/op7-project-audit.md`, `docs/roadmap.md` (error matrix), `docs/baseline.md`,
`docs/performance/baseline.md`, and the error matrix inside `docs/roadmap.md`.
