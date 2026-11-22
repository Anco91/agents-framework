# Host integrations

This table records project-level instruction and skill discovery in each host's official
documentation. The generated `skills` option writes portable skills to `.agents/skills/`.

| host | reads AGENTS.md | extra file we generate | skills location | evidence URL | verified yes/no |
|---|---|---|---|---|---|
| Kilo Code | Yes, loaded by default | `.kilo/agents/agents-fw-advisor.md`; `.kilo/agents/agents-fw-executor.md`; `.agents-fw/adapters/kilo/kilo.jsonc.example` | `.kilo/skills/`; `.agents/skills/` compatibility | [AGENTS.md](https://kilo.ai/docs/customize/agents-md), [agents](https://kilo.ai/docs/customize/custom-modes), [permissions](https://kilo.ai/docs/customize/agent-permissions), [skills](https://kilo.ai/docs/customize/skills) | Yes; `**` glob behavior unverified |
| Claude Code | Yes from v2.1.277; `@AGENTS.md` import is the compatibility path | `CLAUDE.md` | `.claude/skills/` | [memory](https://code.claude.com/docs/en/memory), [skills](https://code.claude.com/docs/en/skills) | Yes |
| Aider | Yes, via the generated config's read-only `read:` list; native discovery is unverified | `.aider.conf.yml` | Unverified | [YAML config](https://aider.chat/docs/config/aider_conf.html) | Yes for `read:`; project skill location unverified |
| Codex CLI | Yes, project instructions are discovered from the repository root to the current directory | None; uses `AGENTS.md` | `.agents/skills/` | [AGENTS.md](https://developers.openai.com/codex/guides/agents-md), [skills](https://developers.openai.com/codex/skills) | Yes |
| OpenCode | Yes, loads project `AGENTS.md` files | None; uses `AGENTS.md` | `.opencode/skills/`; `.agents/skills/` compatibility | [instructions](https://opencode.ai/docs/instructions/), [skills](https://opencode.ai/docs/skills/) | Yes |
| Mistral Vibe | Yes, for trusted project folders | None; uses `AGENTS.md` | `.vibe/skills/`; `.agents/skills/` | [agents](https://docs.mistral.ai/vibe/code/cli/agents), [skills](https://docs.mistral.ai/vibe/code/cli/skills) | Yes; project content requires trust |
| Antigravity | Yes, as a workspace rule | None; uses `AGENTS.md` | `.agents/skills/` (default); `.agent/skills/` (legacy) | [rules](https://antigravity.google/docs/rules/), [skills](https://antigravity.google/docs/skills/) | Yes |

Kilo Markdown agents support YAML front matter for `description`, `mode`, `model`, and `permission`.
Per-path edit permissions use a `permission.edit` pattern map with `allow` and `deny`; the last
matching rule wins. The official documentation confirms glob matching and demonstrates patterns,
but does not specify the exact recursive `**` behavior used by the adapter examples.

Claude Code documents `@path/to/import` syntax for `CLAUDE.md`; this adapter imports `@AGENTS.md`
directly. Aider documents `read:` as a list of read-only files in `.aider.conf.yml`. No official
project-skill location was found in the cited Aider documentation, so it remains unverified.
