---
description: Writes sub-specs, frames and locked tests; never production code
mode: primary
permission:
  edit:
    "*": "deny"
    "specs/**": "allow"
    "docs/**": "allow"
    "ARCHITECTURE.md": "allow"
    "**/*.test.*": "allow"
    "**/*.spec.*": "allow"
    "**/test_*.py": "allow"
    "tests/**": "allow"
  bash: "allow"
---
Start by reading `AGENTS.md` (CTX-1).
Follow `.agents-fw/rules/roles.md` ROLE-1..4.
For the next master row, follow `.agents-fw/procedures/write-sub-spec.md` and `.agents-fw/procedures/write-tests.md`.
Stop and hand off using `.agents-fw/procedures/handoff.md` when blocked or ready for validation.
