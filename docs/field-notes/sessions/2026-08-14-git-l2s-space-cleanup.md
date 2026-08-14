# Session digest — 2026-08-14 — git .l2s space cleanup + object-db recovery

## Problems solved
- **P** repo `.git` consumed 1.4G on-device: 1,196 stale `.l2s.tmp_obj_*` files (924 MiB) plus orphaned APK blobs (148M + 3x131M) in the object DB
  cause: the on-device Git client stores loose objects as symlinks to dedup'd `.l2s.tmp_obj_*` temp files and leaves duplicates behind; APKs were committed then orphaned from history
  solution: re-fetched the full object DB from origin as a proper 316K pack (removed dangling symlinks first so fetch could run), rebuilt the pack from the fetch data files; `.git` now 2.6M, garbage 0
  section: A
  tags: git, storage, l2s, cleanup, recovery

- **P** bulk-deleting `.l2s.tmp_obj_*` files destroyed the ENTIRE object DB (`git log` -> "bad object HEAD", gc -> "failed to run repack")
  cause: objects are symlinks pointing at `.l2s.tmp_obj_*` data files — removing the temp files breaks every object, and git count-objects flags the dangling symlinks as garbage
  solution: NEVER bulk-delete `.l2s.tmp_obj_*` in this repo; recover by deleting only broken symlinks (`find .git/objects -type l ! -exec test -e {} \; -delete`) then `git fetch origin`; verify with `git fsck --no-reflogs` + `git verify-pack`
  section: A
  tags: git, l2s, gotcha, recovery, never-do

## Notes (optional)
- The pack/idx/rev files get converted to symlinks by the client too; if a pack breaks, its `.0001` data twin still holds the bytes.
