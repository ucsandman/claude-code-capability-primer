---
name: claude-code-subagents
description: Use when you have research, exploration, a large review, or 2+ independent tasks to run — spawn subagents (the Agent/Task tool), in parallel when possible, to do focused work and keep the main context clean.
user-invocable: true
---

# Claude Code Subagents

The **Agent tool** (the `Task` tool is a backward-compatible alias for it) spawns a subagent that runs with its **own separate context** and returns **only its final message** to you. Everything it read and reasoned about is discarded. That is the point: offload work whose intermediate tokens you don't want clogging the main thread.

## When to reach for one

- **Research / exploration** across many files or docs where you only need the conclusion, not the file dumps.
- **A large review or audit** — hand it the diff and a focused brief.
- **2+ independent tasks** that share no state and no ordering — dispatch them in parallel.
- **Keeping the main context clean** — anything that would otherwise pull lots of bytes into the conversation (broad greps, whole-tree reads, log triage).

For a single fact in a file you already know, just read it. Subagents pay off when the work is broad or parallel.

## How to invoke

Call the Agent tool with a `subagent_type` and a self-contained `prompt`. The agent's final message comes back as the tool result (the user does not see it — relay what matters).

- **Run several concurrently:** put multiple Agent calls in ONE message. They execute in parallel. This is the main lever for independent work.
- **`run_in_background: true`** detaches a long-running agent; you're notified on completion (see `claude-code-background-agents`).
- **`isolation: "worktree"`** gives the agent its own git worktree — use ONLY when multiple agents mutate files in parallel and would otherwise collide (it costs setup time + disk).
- **Continue an agent** with its context intact via `SendMessage` to its id/name; a fresh Agent call starts cold.
- **`/agents`** manages reusable subagent definitions; **`/fork <directive>`** spawns a subagent that inherits your *current* conversation (the cheapest hand-off when the side task needs context you already have).

## Agent types

- `general-purpose` — multi-step research, search, and execution when you're not sure you'll hit the answer fast.
- `Explore` — read-only, breadth-first search across many files; returns the conclusion, not a review. Good for "where is X / what calls Y".
- `Plan` — design an implementation plan (read-only).
- `claude-code-guide` — questions about Claude Code / Agent SDK / Claude API features.
- Plus any **custom or plugin agents** (defined in `.claude/agents/` or a plugin), selectable by `subagent_type`.

## Model routing (per subagent)

Route to fit the job, and remember your CLAUDE.md preference: **Opus** subagents for code review, architecture, debugging, and documentation; **Haiku/Sonnet** for file searches, simple refactors, and formatting. A subagent inherits the session model unless you override it — override down for cheap mechanical work, up for hard reasoning.

## How subagents differ from the neighbors

- **Subagent (Agent tool)** — synchronous-ish, returns a result to you; *you* decide what to do next. One level only: **subagents cannot spawn subagents.**
- **Dynamic workflow (`Workflow` tool)** — deterministic *orchestration* of many subagents with loops/pipelines/verification; reach for it when the fan-out is large or structured. See `claude-code-dynamic-workflows`.
- **Background agent / task** — long-running async work that keeps going across turns. See `claude-code-background-agents`.

## Anti-patterns

- **Single-threading parallelizable work** — context-switching through 10 independent files yourself instead of dispatching agents. If the subtasks don't depend on each other, fan out.
- **Dumping huge reads into the main context** — if you only need the conclusion of a broad search, send it to an `Explore`/`general-purpose` agent and keep the bytes out of the thread.
- **Re-running a search you already delegated** — wait for the agent's result instead of also doing it yourself.
- **Over-delegating trivia** — a one-line lookup in a known file is faster done directly.

Write the agent's brief like a contract: what to do, what to return, and that its final message *is* the deliverable (not a chat reply).
