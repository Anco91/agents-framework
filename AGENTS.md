# agents-framework — repository instructions

Source repository of the portable, spec-first agent framework. The framework itself is delivered
from `framework/`; this file only covers working on the repository.

## Commands

```bash
bash tests/run.sh                                            # behaviour tests (macOS + Linux)
shellcheck init.sh framework/scripts/*.sh tests/*.sh          # shell lint
bash framework/scripts/lint-docs.sh                           # docs budgets, rule IDs, links
```

`initialize` installs `shellcheck` (Debian/Ubuntu). CI runs both commands.

## Ground rules

- Scripts stay POSIX/bash 3.2 compatible: no `jq`, no associative arrays, no interactive prompts.
- `sha256sum` with `shasum -a 256` fallback. No network access at runtime.
- Delivered files in `framework/` and `adapters/` are English; README and design docs are French.
- Line budgets are enforced by `lint-docs.sh`: `core.md` ≤ 120, rules/standards ≤ 200,
  procedures ≤ 80. Do not raise them.
- One milestone = one branch = one PR. Conventional Commits with trailer
  `Spec: docs/design/spec-v4.md`.
- Do not store model slugs, prices or API keys in `framework/` or `adapters/`.
- Tests are behavioural: run scripts against a temporary project and assert the produced state.
- `.devin/blueprint.yaml` defines the Devin environment; keep its commands identical to CI.

## Layout

| Path | Purpose |
|---|---|
| `framework/core.md` | Managed block injected into a project's `AGENTS.md` |
| `framework/rules/` | WF, ROLE, SES, TEST, CTX, GIT rules |
| `framework/standards/` | ARCH, BE, FE, LIB, TypeScript, Python + reference code |
| `framework/procedures/`, `framework/templates/` | Step-by-step guides and templates |
| `framework/scripts/` | `test-lock.sh`, `arch-check.sh`, `new-handoff.sh`, `lint-docs.sh` |
| `adapters/` | Per-host files (`claude`, `kilo`, `aider`, `skills`) |
| `docs/design/` | Validated spec v4.1, plan, v3 audit |
