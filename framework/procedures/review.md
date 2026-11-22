# Review a sub-spec delivery

Use when: a sub-spec PR is open (status `review`). Role: Reviewer, or Advisor in a fresh session.
Rules: ROLE-5, GIT-2, every rule cited in the sub-spec.

1. Read `AGENTS.md`, `ARCHITECTURE.md`, the sub-spec, then the PR diff. Not the whole repo.
2. Mechanical checks (run them):
   - `.agents-fw/scripts/test-lock.sh <sub-spec>` → pass;
   - `.agents-fw/scripts/arch-check.sh` → pass;
   - project tests, lint, typecheck → pass.
3. Frame conformity: every changed file is in Create/Modify (or a proposed test); names, paths and
   signatures match; nothing forbidden was done.
4. Acceptance criteria: each one is covered by a test or a stated manual check.
5. Standards, by priority:
   - security: server-side validation and authorisation, no trusted client values (BE-4);
   - duplication: anything that exists in the registry or a library (CTX-4, LIB-2);
   - backend thinness (BE-1), filter translator use (BE-2);
   - frontend: no fetch/derive effects (FE-3), state placement (FE-4), no repeated inline JSX (FE-9),
     form kit and structures used (FE-6, FE-7);
   - functions first, size, naming (ARCH-4, ARCH-5, ARCH-7).
6. Executor-proposed tests: accept or reject each (`write-tests.md`).
7. Write findings as a list `RULE-ID — file:line — problem — fix`. Blocking = MUST rules.
8. Verdict: approve, or request changes with the list. Hand off to the Executor with the list as
   "Left" if changes are needed.
