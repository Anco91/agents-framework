---
id: 02-agent-tiers
status: done
branch: feat/m-a-agent-tiers
locked_at: 16d47e9
locked_tests:
  - tests/test_hosts.sh
tier: medium
---

# 02 — Claude agents with model tiers

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, ROLE-5, ROLE-6, ROLE-9

## Goal

A Claude project gets named Executor and Reviewer agents with a model tier alias, so sub-agents never
inherit the strong parent model. The Advisor picks `tier: small|medium` per sub-spec.

## Acceptance criteria

1. `init.sh install <p> --host claude` creates `.claude/agents/agents-fw-{executor,executor-small,reviewer}.md`, each with a `model:` alias.
2. `init.sh hosts` lists them.
3. `test-lock.sh` still reads a sub-spec that has a `tier:` key.

## Frame

### Modify

| Path | Change |
|---|---|
| `init.sh` | claude host also installs the three agent files; `print_hosts` lists them |
| `framework/rules/roles.md` | ROLE-6 allows tier aliases; add ROLE-9 |
| `framework/templates/SUB_SPEC.md` | add `tier: medium` to front-matter |
| `framework/core.md` | one line on tier and named agents |

## Out of scope

- Kilo model config (provider/model is a slug; stays a commented placeholder).

## Handoffs

- `docs/handoffs/20261124-1315-02-agent-tiers.md`
