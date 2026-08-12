# Upstream pin

`commit.txt` holds the exact upstream `fork-maintainers/iceraven-browser` commit
(`iceraven` branch) that the OP7 pipeline mirrors and builds.

- Updated only by `automation/op7/sync_upstream.sh` (never by hand).
- Every OP7 build records this commit in `build-metadata.json`.
- The pipeline stops and reports if a patch fails to apply against it — it never
  force-resets to upstream and never overwrites OP7 changes.
