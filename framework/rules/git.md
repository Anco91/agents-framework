# Git rules (GIT)

Git is the audit log. No side journal. Cite rules by ID.

- **GIT-1 MUST** — One sub-spec = one branch `feat/<id>-<slug>` (or `fix/`, `chore/`) = one PR.
  Commits follow Conventional Commits and carry the trailer `Spec: specs/<id>-<slug>.md`.
  Why: `git log --grep "Spec: specs/03"` returns the whole history of a feature.
  ```
  feat(charges): filter charges by period

  Spec: specs/03-charges-period-filter.md
  ```

- **GIT-2 MUST** — A PR description follows `templates/PR.md`: sub-spec, changes, checks
  (`test-lock.sh`, `arch-check.sh`, tests), rule deviations.
  Why: the reviewer checks the frame, not only the diff.

- **GIT-3 SHOULD** — Small atomic commits: the locked tests commit first (Advisor), then code commits
  (Executor), then registry/docs. Audit with `git log --grep "Spec: "` or `--grep "Track: fast"`.
  Why: `locked_at` points to a clean commit; reverts stay surgical.

- **GIT-4 MUST** — Never push directly to the default branch, never merge with failing checks, never
  rewrite shared history.
  Why: the PR is where the human keeps control.

- **GIT-5 MUST** — Never commit secrets, `.env` files, API keys, or raw conversation dumps.
  Why: keys leak and get used; dumps are noise.

- **GIT-6 SHOULD** — Delete the branch after merge; one open branch per active sub-spec.
  Why: stale branches hide which work is live.
