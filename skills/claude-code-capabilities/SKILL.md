---
name: claude-code-capabilities
description: Use when unsure which Claude Code capability fits a task, when about to single-thread large/cross-cutting/repetitive work, or when you or the user ask what Claude Code can do — loads the full capability map (signal → capability) and points to the deep-dive skills.
user-invocable: true
argument-hint: "(optional) a task or capability you want mapped, e.g. 'migrate 40 files' or 'hooks'"
---

# Claude Code Capabilities

This skill is your **capability index**. Its job: before you plan, single-thread something big, or decide a thing is impossible, make sure you have considered the right built-in Claude Code capability.

## Do this now

1. **Read the full map:** open `references/capability-map.md` (in this skill's directory). It maps concrete task signals → the capability to reach for → how to invoke it → which deep-dive skill to read. It also lists the anti-patterns that this primer exists to prevent.
2. **Match the task** to a row. If a capability fits, invoke its deep-dive skill (below) for the exact mechanics before implementing.
3. **If nothing fits,** proceed normally — not every task needs special machinery. The point is to *consider* these first, not to force them.

## Condensed trigger list (full detail in `references/capability-map.md`)

| Signal | Capability | Deep-dive skill |
|---|---|---|
| Repeatable workflow / knowledge you keep re-deriving | Skills & slash commands | `claude-code-skills` |
| Research, exploration, big review, 2+ independent tasks | Subagents (`Agent`/`Task`) | `claude-code-subagents` |
| Broad audit, migration, fan-out > one context | Dynamic workflows (`Workflow`, ultracode) | `claude-code-dynamic-workflows` |
| "Each time X, do Y" the harness must enforce | Hooks | `claude-code-hooks` |
| Long build/test/watch, polling external state | Background agents & tasks | `claude-code-background-agents` |
| Undo a bad edit path / restore state | Checkpointing & `/rewind` | `claude-code-checkpointing` |
| Live external tool / API / data source | MCP servers | `claude-code-mcp` |
| Reuse skills/hooks/agents/MCP as a bundle | Plugins | `claude-code-plugins` |
| Server-side PR / issue automation | GitHub Actions (`@claude`) | `claude-code-github-actions` |
| Build a custom/headless agent | Agent SDK | `claude-code-agent-sdk` |
| Task too hard/trivial for current setting | Effort, models & fast mode | `claude-code-effort-models` |

Each row's deep-dive skill is a separate skill in this plugin — invoke it with the `Skill` tool when you are actually doing that kind of work (they auto-surface on the matching signal too).

## Staying current (automatic)

This primer keeps itself current:
- An async SessionStart hook (`hooks/auto-update.sh`) does a throttled `git pull --ff-only` so your install tracks the latest merged `main`, and flags this card when your installed Claude Code is newer than the version the content was generated for (`references/.generated-for`).
- A scheduled refresh agent fetches the latest official docs/changelog, adds or updates the card, map, and `claude-code-*` skills for any new capabilities, **verifies every claim against the live docs**, and opens a PR — auto-merging only when verification passes (`AUTO_MERGE_POLICY = verified`; see `references/refresh-runbook.md`).

To refresh manually: run `bash scripts/update-docs.sh`, then follow `references/refresh-runbook.md` in a Claude session.
