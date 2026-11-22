# Decisions log

Extracted from the design conversation (`context-projet.md`, kept out of the repo).
One entry per decision: what, why, evidence. Newest last.

## 2026-11-22 — Cost diagnosis

- **What**: ~6 $ burnt in ~2 h on OpenRouter with Kilo Code + Qwen3.7 Plus.
- **Wrong first diagnosis**: autocompletion (FIM) requests. Kilo does not stream completions to the
  chat model by default.
- **Retained cause**: the agentic loop. Every tool call (read, write, run test) re-sends the whole
  conversation. A growing context with lint/test iterations makes the bill grow with each turn.
- **Consequence**: the main lever is context discipline (sliced specs, fresh sessions, targeted reads),
  more than model choice. This is the reason the framework exists.

## 2026-11-22 — Roles by capability, never by slug

- Planner/Advisor: strong reasoning model, short bursts, text only.
- Executor: cheap "Flash" model with reliable tool calling and structured output; 80-95 % of tokens.
- Reviewer: another model family than the Executor.
- Completion: local model (Ollama / LM Studio) or Copilot completions; never a paid chat model.
- Model names produced by LLMs were repeatedly obsolete or hallucinated. Every slug, price and
  provider is checked on openrouter.ai before use. No slug is stored in `framework/`.

## 2026-11-22 — Chosen / rejected tools

| Tool | Verdict | Why |
|---|---|---|
| Kilo Code + OpenRouter | core | One model per agent, sub-agents, VS Code fork + CLI, no BYOK commission |
| Kilo Orchestrator mode | rejected | Deprecated; ~3x tokens of a plain session |
| Copilot Chat + OpenRouter BYOK as main tool | rejected | No BYOK inline completion, no per-phase routing |
| Copilot BYOK to try a model | optional | Fine for one-off comparisons |
| Antigravity / Gemini Orchestrator | rejected as main | Gemini-only, subscription, no OpenRouter; good concept |
| T3 Code | optional | Free control surface for existing harnesses; makes parallel token burn easy |
| OpenCode | optional | Accepts any OpenAI-compatible endpoint, so OpenRouter |
| Claude Code / Codex subscriptions | optional | Redundant with a Flash executor unless already paid |
| `openrouter/free` auto router | rejected | Random model, may lack tool calling |
| Session compaction | rejected | Summaries lose fresh details; handoff + new session instead |

## 2026-11-22 — MCP servers

- Required: Context7 (up-to-date, version-pinned library docs; 2 tools, small context weight).
- Recommended: GitHub MCP; Serena (symbol-level navigation, avoids dumping large files).
- Conditional: Playwright, Supabase, Sentry, Linear — only when the project uses them.
- Rule: few MCP servers; each tool schema costs context on every turn.

## 2026-11-22 — Financial guards

- One OpenRouter key per tool, each with a hard credit limit (e.g. 3 $), raised by hand.
- Watch the `Activity` dashboard, not only the balance.
- Pin the provider when reproducible bills matter; check it supports tool calling and structured output.
- OpenRouter BYOK (+5 % fee) only to bypass a provider rate limit.

## 2026-11-22 — Framework design v4 (validated by Anco)

- Spec: `docs/design/spec-v4.md`. Plan: `docs/design/plan-v4.md`. Audit of v3: `docs/design/audit-spec-v3.md`.
- Install under `.agents-fw/` + managed block in `AGENTS.md` (existing projects already own `AGENTS.md`,
  and `SKILLS/` collides with `skills/` on case-insensitive disks).
- Advisor leads (framing + locked tests); Executor writes production code only; git-checked test lock.
- One handoff file per session, explicit resume block naming handoff and sub-spec.
- Git trailers instead of a YAML change journal.
- Targets new and existing projects; procedures also exposed as `.agents/skills/` (opt-in host).
- Handoff after every delivered sub-spec and after ~30 conversation exchanges (thresholds tuned in pilot).
