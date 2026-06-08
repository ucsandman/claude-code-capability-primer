---
name: claude-code-background-agents
description: "Use when needing to understand or manage background agents, long-running tasks, polling, scheduling, or async work in Claude Code without blocking the session."
user-invocable: true
---

# Claude Code Background Agents and Tasks

When to use: Background Bash via `Ctrl+B` or `run_in_background=true`, `/loop` with fixed or self-paced intervals, Monitor tool for streaming output, Agent view (`claude agents`) for parallel sessions, subagents for side tasks, workflows for multi-agent orchestration, `/schedule` (cloud routines), and `/goal` for turn-by-turn looping.

---

## Quick Summary

**Background Bash**: Run a shell command asynchronously. Press `Ctrl+B` during a Bash tool call, or Claude sets `run_in_background=true`. Command runs; output written to file in session directory. Claude reads output with Read tool. Returns task ID. List and stop with `/tasks`.

**`/loop`**: Recurring prompt on a session-scoped schedule. Fixed interval (`5m`, `30s`) or self-paced. Behind the scenes uses `CronCreate`/`CronList`/`CronDelete` tools. Expires 7 days or when you `Esc`.

**Monitor**: Built-in tool; streams background script output line-by-line as each line arrives. Claude reacts mid-conversation without polling. Not available on Bedrock/Vertex/Foundry. More token-efficient than `/loop` on fixed cron.

**Agent view** (`claude agents`): Dispatch and monitor independent background **sessions** in a dedicated terminal UI. Each session isolated, gets its own worktree. Survives terminal exit (supervisor process keeps them alive). You hand off work; Claude runs autonomously.

**Subagents**: Spawn a worker inside conversation with separate context. Foreground subagents show permission prompts as they run; background subagents don't and auto-deny unpermitted calls. Returns summary. Does not block main turn.

**Workflows**: JavaScript script runs in background, orchestrates many subagents. Script holds plan; intermediate results stay out of context. Resumable. Invoke via `/workflows` or `ultracode` effort level.

**`/schedule`** (cloud routines): Create a task on Anthropic infra. Cron or API trigger. Persists independently of any session.

**`/goal`**: Keep session looping turn-by-turn until a condition is met. Session stays active.

---

## Background Bash Commands

**When**: Long builds, test suites, dev servers, file watches.

**How to invoke**:
1. Press `Ctrl+B` during a Bash tool call to move it to background.
2. Or: Claude sets `run_in_background=true` on the Bash tool parameter.

**Behavior**:
- Command runs asynchronously. Claude gets back task ID immediately.
- Output written to file in session directory.
- Claude reads output later with Read tool (no blocking).
- Max 30,000 chars per command before file save + preview. 5GB hard output cap before auto-termination.
- Auto-cleaned on session exit.
- List and stop: `/tasks` command.
- Disable: `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.

**Key constraint**: Background Bash does NOT re-invoke Claude on completion. You or a scheduled `/loop` must poll or read the output file.

---

## `/loop`: Local Recurring Prompts

**Scope**: Session-local. Expires 7 days or `Esc`. Restored on `--resume` if unexpired.

**Three modes**:

### Mode 1: Fixed Interval + Prompt
```
/loop 5m check if deployment finished
```
- Interval: `s`, `m`, `h`, `d`. Converts to cron; Claude confirms actual schedule.
- Fires between turns, never mid-response. If Claude busy, waits for turn end.
- Jitter: up to 30 minutes after scheduled time (deterministic per task ID to prevent API thundering).

### Mode 2: Prompt Only (Self-Paced)
```
/loop check whether CI passed and address review comments
```
- Claude chooses delay 1m–1h after each iteration based on observed work.
- May use Monitor tool instead to avoid re-polling.
- Respects 7-day expiry.
- Bedrock/Vertex/Foundry: unsupported; falls back to fixed 10m instead.

### Mode 3: Bare `/loop` (Fixed Built-in Maintenance)
```
/loop
/loop 15m
```
- Bare `/loop` = built-in maintenance prompt on fixed cron (NOT self-paced). Customizable via `.claude/loop.md` or `~/.claude/loop.md`.
- Bedrock/Vertex/Foundry: bare `/loop` prints usage instead.

**Stop**: Press `Esc` (works only during wait). Fixed-cron tasks keep running. Self-paced `/loop` may stop itself if work complete.

**Under the hood**: CronCreate, CronList, CronDelete tools. Max 50 tasks per session.

---

## Monitor Tool

**What**: Streams background script output line-by-line without polling.

**When**: More token-efficient alternative to `/loop` fixed intervals. Claude may choose Monitor for self-paced `/loop` instead of cron.

**How**: Claude runs script in background; yields each output line as it arrives. Claude reacts to each line immediately.

**Availability**: Not on Bedrock/Vertex/Foundry.

---

## Agent View: Background Sessions

**Command**: `claude agents` (opens dedicated terminal UI).

**What**: One screen for all dispatched background **sessions**. Each is a full Claude Code session, independent, with its own worktree.

**How to dispatch**:
- From agent view: type prompt, press Enter.
- From inside session: `/background [prompt]` or `/bg [prompt]`.
- From shell: `claude --bg "<prompt>"`.

**Behavior**:
- Each session isolated (edits go to separate worktree under `.claude/worktrees/`).
- You hand off; Claude runs autonomously.
- Status at a glance. Attach/peek/reply without leaving agent view.
- Supervisor process keeps sessions alive after terminal exit. Restart machine requires `claude respawn <id>` recovery.

---

## Subagents (In-Session Delegation)

**Scope**: Inside one conversation. Spawned by Claude or via `/agents` command.

**Permission behavior** (critical distinction):
- **Foreground subagents**: Show permission prompts as they run (same as main session).
- **Background subagents**: Don't show prompts; inherit permissions already granted; auto-deny unpermitted calls and keep going.

**Behavior**:
- Runs in own context.
- Returns summary to main conversation.
- Does not accept new user input mid-task.
- Can inherit full tool access or restricted set.

**When**: Side research, exploration, parallel investigation.

---

## Dynamic Workflows

**What**: JavaScript script orchestrates many subagents in background. Script holds plan; intermediate results stay out of context.

**When**: Large audits, 500-file migrations, cross-checked research, multi-angle planning.

**How**: Mention `ultracode` keyword or ask Claude to write workflow. Script executes in background. Monitor with `/workflows`. Final report to session when done.

**Resumable**: Pause/resume within same session. Exit Claude Code = fresh restart next session.

---

## `/schedule`: Cloud Routines

**Scope**: Persists on Anthropic infra, independent of any session. Survives machine restart.

**Triggers**: Cron schedule, API call, GitHub event.

**vs `/loop`**: `/loop` session-local, fires only while Claude running locally. `/schedule` runs in cloud.

---

## `/goal`: Turn-by-Turn Looping

**What**: Keep session actively looping until condition is met.

**How**: `/goal all tests pass and code is deployed`

**Behavior**: Claude evals condition after each turn. Session stays awake.

---

## Comparison Table: When to Use

| Use case | Tool | Scope | Blocking? | Survives exit? | Multi-agent? |
| --- | --- | --- | --- | --- | --- |
| Long build/test, check later | Background Bash | Session | No | No | No |
| Poll CI every 5m while working | `/loop 5m` | Session | No | 7d | No |
| Stream real-time output | Monitor | Session | No | No | No |
| Dispatch independent task | Agent view | Session | No | Yes (supervisor) | Many |
| Side research, return summary | Subagent | Conversation | No | No | Few |
| Codebase audit, 100s of agents | Workflow | Session | No | 7d | Many |
| Cron on cloud, no machine needed | `/schedule` | Cloud | No | Yes | No |
| Active loop until done | `/goal` | Session | Partially | No | No |

---

## Polling Without Re-Running Claude

**Pattern**: Bash loop + file writes → Claude reads file periodically.

```bash
while true; do
  curl https://api.example.com/status > /tmp/status.json
  sleep 30
done
```

Claude runs in background. Claude reads `/tmp/status.json` later. No re-invocation.

**Better**: Use Monitor or `/loop` if Claude should react, or `/goal` for tight feedback.

---

## Key Constraints

1. **Background Bash does not re-invoke Claude.** Poll with `/loop`, Monitor, or read file.
2. **Subagents: foreground shows prompts; background doesn't.** Critical for permission handling.
3. **Agent view sessions are discrete.** Separate worktrees; don't see main conversation.
4. **Scheduled tasks (cron) expire 7 days.** Extend by recreating, or use `/schedule` for durable cloud tasks.
5. **`/loop` fires between turns, never mid-response.** If Claude busy, waits for turn end.
6. **Jitter deterministic per task ID.** Prevents API thundering at wall-clock moments.
7. **Monitor not on Bedrock/Vertex/Foundry.** Use `/loop` instead.

---

## Common Patterns

**Watch a deploy**: `/loop 2m did deployment finish? if so, run smoke tests`

**Babysit a PR**: `/loop check CI status and new review comments; address them`

**Audit entire codebase**: `ultracode: audit every function in src/ for missing error handling`

**Parallel research**: Dispatch three independent investigations via agent view, review findings.

**Continuous improvement**: `/goal all tests pass and code is deployed`

---

## Monitoring Active Work

- **Background Bash**: `/tasks` command shows running tasks.
- **`/loop`**: `/tasks` shows scheduled tasks.
- **Agent view**: `claude agents` opens UI.
- **Subagents**: `/agents` shows Running tab.
- **Workflows**: `/workflows` shows phases, agent counts, token totals.

---

## Token Costs

- Background Bash: runs locally, no ongoing tokens.
- `/loop` fixed: one prompt per fire, cache reuse.
- `/loop` self-paced: one prompt per iteration, Claude chooses delay.
- Monitor: streaming; efficient vs polling.
- Agent view: each session fresh context, multiplies tokens.
- Subagents: separate context per agent.
- Workflows: many agents; estimate before large run.
- `/schedule` (cloud): billed separately, runs independently.
