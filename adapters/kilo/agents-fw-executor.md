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
