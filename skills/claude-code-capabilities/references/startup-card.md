# Claude Code — Capability Self-Awareness Card

You are running inside **Claude Code**. Before you plan, single-thread a large task, or say something is "not possible," check whether one of your built-in capabilities fits. Each line below has a deep-dive skill — invoke it (via the `Skill` tool) when the signal matches.

**Signal → capability → deep-dive skill:**

1. Repeatable workflow or knowledge you keep re-deriving → **Skills / slash commands** (`Skill` tool) · `claude-code-skills`
2. Research, exploration, a large review, or 2+ independent tasks → **Subagents** (`Agent`/`Task`, run several in one message) · `claude-code-subagents`
3. Broad audit, migration, or fan-out bigger than one context holds → **Dynamic workflows** (`Workflow` tool; requires ultracode / explicit opt-in) · `claude-code-dynamic-workflows`
4. "From now on, each time X, do Y" — automation the *harness* must enforce → **Hooks** (settings.json / plugin `hooks.json`) · `claude-code-hooks`
5. Long build/test/watch, or polling external state (CI, deploy) → **Background agents & tasks** (`run_in_background`, `/loop`, `ScheduleWakeup`) · `claude-code-background-agents`
6. Undo a bad edit path / restore a previous state → **Checkpointing & `/rewind`** · `claude-code-checkpointing`
7. A live external tool, API, or data source → **MCP servers** (`mcp__*` tools; `ToolSearch` to load deferred ones) · `claude-code-mcp`
8. Package skills/hooks/agents/MCP to reuse across sessions → **Plugins** · `claude-code-plugins`
9. Server-side PR / issue automation → **GitHub Actions** (`@claude`) · `claude-code-github-actions`
10. Build a custom or headless agent on this harness → **Agent SDK** · `claude-code-agent-sdk`
11. Task too hard or too trivial for the current setting → **Effort, models & fast mode** (`/effort`, `/model`, `/fast`) · `claude-code-effort-models`

For the full opinionated map (every signal → capability, plus anti-patterns) invoke **`claude-code-capabilities`**.

When a task is broad, risky, repetitive, cross-repo, or tool-heavy, reach for one of these **before** defaulting to a single-agent inline implementation.
