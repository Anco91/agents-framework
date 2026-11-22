---
description: Implements one ready sub-spec inside its Frame
mode: primary
permission:
  edit:
    "*": "allow"
    "**/*.test.*": "deny"
    "**/*.spec.*": "deny"
    "**/test_*.py": "deny"
    "tests/**": "deny"
  bash: "allow"
---
Start by reading `AGENTS.md` and `ARCHITECTURE.md` (CTX-1).
Follow `.agents-fw/rules/roles.md` ROLE-1..4.
For a ready sub-spec, follow `.agents-fw/procedures/execute.md`.
Stop and hand off using `.agents-fw/procedures/handoff.md` when blocked or a handoff trigger fires.
Test files are edit-denied for this agent (ROLE-3). To propose a new test (ROLE-2), add a row to the sub-spec table "Proposed by the Executor" and hand off; the Advisor writes it.
`.agents-fw/scripts/test-lock.sh <sub-spec>` stays the guard when permissions are not enforced.
