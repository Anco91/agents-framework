---
id: 05-style-review
status: done
branch: feat/m-g-style-review
tier: small
---

# 05 — Style and direction review

Master: `specs/SPEC_MASTER.md` · Rules: ROLE-5, ROLE-10

## Goal

The Reviewer can tell whether new code matches the project's own style and direction, because the style is written down and exemplars are named.

## Acceptance criteria

1. `ARCHITECTURE.md` template has a "House style" section (exemplars + conventions); `SUB_SPEC.md` Frame has "Style exemplars".
2. ROLE-10 exists; `review.md` has a House style step; `execute.md` reads the exemplar. `lint-docs.sh` passes.

## Frame

### Modify

| Path | Change |
|---|---|
| `framework/templates/ARCHITECTURE.md`, `framework/templates/SUB_SPEC.md` | new sections |
| `framework/rules/roles.md` | add ROLE-10 |
| `framework/procedures/review.md`, `framework/procedures/execute.md` | style step |
| `CHANGELOG.md`, `specs/SPEC_MASTER.md` | entry, status |

## Out of scope

- Automatic style linting. Exemplars are registry paths, so `arch-check.sh` already catches a deleted exemplar.

## Handoffs
- `docs/handoffs/20261124-1436-05-style-review.md`
