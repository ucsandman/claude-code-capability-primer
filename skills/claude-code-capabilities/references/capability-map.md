# Claude Code Capability Map

**Decision-first cheat sheet for choosing the right Claude Code capability.** When stuck, when overwhelmed by scope, or when a task feels like it should automate, consult this map. Organized as: SIGNAL (what you're trying to do) -> CAPABILITY -> HOW TO INVOKE -> DETAIL SKILL REFERENCE.

> Verified against code.claude.com/docs (2026-06) and a real Claude Code settings.json. Where a claim could not be confirmed it is marked [unverified].
>
> **Detail skills:** names like `claude-code-hooks` are THIS plugin's deep-dive skills — invoke them (via the Skill tool) for full mechanics. Bare names like `skill-creator`, `update-config`, or `claude-mem:mem-search` are other installed helper plugins/skills.

---

## 1. SKILLS & SLASH COMMANDS

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Repeat a workflow / customize behavior for my team" | Custom skills (`/skillname`) | Write `.claude/skills/{name}/SKILL.md` + invoke by name. Frontmatter `disable-model-invocation` controls who triggers it; `allowed-tools` grants tools while active. | `skill-creator:skill-creator` (create/modify/benchmark) |
| "Run a pre-built workflow from a marketplace" | Installed skills | `/skillname [args]` from any project. Enable in plugin settings. | Consult each skill's frontmatter. |
| "List / hide / reload skills" | Skill management | `/skills` (list, sort by token cost, hide), `/reload-skills` (re-scan disk). | — |
| "I want to just try something quickly" | Direct prompt | Plain english request without `/skillname`. | `claude-code-skills` |

---

## 2. SUBAGENTS & AGENT ORCHESTRATION

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Run a side task in isolation, or 2-3 specialists in parallel, then merge" | **Subagents** (Agent tool) | The model calls the **Agent** tool (`Task` is a backward-compat alias, renamed to Agent in v2.1.63). Each runs in its own context and returns a summary. Subagents **cannot** spawn further subagents. Manage definitions with `/agents`. | `claude-code-subagents` |
| "Hand off a side task that needs my CURRENT conversation/context" | **Fork** (`/fork`) | `/fork <directive>` (v2.1.161+). Spawns a background subagent inheriting the full conversation; result returns when done. Can write to a worktree via `isolation: "worktree"`. | — |
| "Launch a named session that keeps running and I monitor it" | **Background agents** | `/background [prompt]` (alias `/bg`) detaches the session. Monitor with `/tasks` or `claude agents`. | `claude-code-background-agents` |
| "Run many sessions that talk to each other" | **Agent teams** | Spawn teammates that reference subagent definitions and message each other. See `/en/agent-teams`. | — |
| "Spawn 5-30 isolated workers on the same large change (migration, bulk edit)" | **Batch** (`/batch`) | `/batch <instruction>` (bundled skill). Decomposes into 5-30 units, one background subagent per unit in its own git worktree, opens a PR per unit. Requires a git repo. | — |
| "Lead agent + specialists, dynamic routing on a large project" | **Dynamic Workflows / Ultracode** | `/effort ultracode` (session-only): sends `xhigh` to the model AND has Claude orchestrate dynamic workflows for substantive tasks. | `claude-code-dynamic-workflows` |

---

## 3. EFFORT LEVELS & MODEL ROUTING

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "I want faster Opus output (interactive iteration / live debug)" | **Fast mode** (Opus only) | `/fast` to toggle (or `fastMode: true` in settings). Same Opus quality, **up to ~2.5x faster at HIGHER cost per token** (Opus 4.8 = $10/$50 per MTok in/out; 4.7/4.6 = $30/$150). Draws from usage credits. Opus 4.8/4.7/4.6 only; not Sonnet/Haiku. | — |
| "Depth-tune the reasoning for this task" | **Effort levels** | `/effort {level}` or `--effort` flag or `CLAUDE_CODE_EFFORT_LEVEL`. Opus 4.8 levels: `low`, `medium`, `high` (default), `xhigh`, `max`. `max` and `ultracode` are session-only; `low/medium/high/xhigh` persist (settings `effortLevel`). `ultracode` is a Claude Code setting (xhigh + workflow orchestration), not a true effort level. | `claude-code-effort-models` |
| "Use a specific or latest model" | **Model selection** | `/model {alias|id}` (saves as default; `s` = session-only) or settings key **`model`**. Aliases: `opus`/`sonnet`/`haiku`/`best`/`default`/`opusplan`/`opus[1m]`/`sonnet[1m]`. Latest full IDs: Opus = `claude-opus-4-8`, Sonnet = `claude-sonnet-4-6`, Haiku = `claude-haiku-4-5-20251001`. | — |

---

## 4. HOOKS & AUTOMATION

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Run a command before a tool runs (e.g., block/lint)" | **PreToolUse hooks** | `settings.json` `hooks.PreToolUse`. Matcher filters by tool name (`Edit\|Write\|Bash`, `mcp__.*`). Can block via exit code / `if` permission-rule filter. | `update-config` |
| "Run a command after an edit (e.g., format, typecheck)" | **PostToolUse hooks** | `settings.json` `hooks.PostToolUse`. Runs after tool succeeds (also `PostToolUseFailure`). | `update-config` |
| "Load durable context at session start" | **SessionStart hook** | `hooks.SessionStart`, matcher = `startup\|resume\|clear\|compact`. Used to auto-inject a codebase map, etc. | `update-config` |
| "Trigger behavior when Claude stops, a subagent finishes, or before compaction" | **Other lifecycle hooks** | `Stop`, `SubagentStart/Stop`, `UserPromptSubmit`, `Notification`, `PreCompact/PostCompact`, `InstructionsLoaded`, and ~20 more. See `/en/hooks`. | `hooks` skill |
| "Automatically execute on a schedule (nightly, weekly)" | **Scheduled routines** (`/schedule`) | `/schedule "description"` (alias `/routines`) -> Anthropic-managed cloud routine. Cron / API / GitHub triggers. | — |
| "Poll/repeat a prompt at intervals within a session" | **Loop** (`/loop`) | `/loop {interval} {prompt}` (bundled skill; alias `/proactive`). Omit interval to self-pace. | — |

---

## 5. PLAN MODE & CHECKPOINTING

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Write a plan before executing" | **Plan mode** | `/plan [description]`. Or alias `opusplan` (Opus plans, Sonnet executes). Cloud variant: `/ultraplan`. | — |
| "Keep working across turns until a condition is met" | **Goal** (`/goal`) | `/goal <condition>`; `/goal clear` to stop. | — |
| "Undo edits / explore an alternative / restore prior state" | **Checkpointing** | `/rewind` (aliases `/checkpoint`, `/undo`) rolls code and/or conversation back, or press Esc Esc. Resume with `claude --continue` / `/resume`. Fork the conversation with `/branch`. | `checkpointing` |
| "Inspect or free up context" | **Context mgmt** | `/context` shows window usage; `/compact [instructions]` summarizes; `/clear` starts fresh keeping project memory. | — |
| "Move a session between surfaces" | **Session portability** | `/teleport` pulls a web session into this terminal; `/desktop` continues it in the Desktop app; `/remote-control` (alias `/rc`) makes this terminal session controllable from claude.ai. | — |

---

## 6. MEMORY & CONTEXT MANAGEMENT

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Give Claude persistent project instructions" | **CLAUDE.md** | `./CLAUDE.md` or `./.claude/CLAUDE.md` (project root). Loaded in full every session. Per-path rules go in `.claude/rules/*.md`. | `/init` (scaffold); `/memory` (edit); `claude-md-management:revise-claude-md` |
| "Cross-project global instructions" | **User CLAUDE.md** | `~/.claude/CLAUDE.md`. Project CLAUDE.md loads after (more specific). Org-wide: managed-policy CLAUDE.md / `claudeMd` setting. | Same skills. |
| "Let Claude learn build commands, debug patterns across sessions" | **Auto memory** | Claude auto-writes to `~/.claude/projects/<project>/memory/` (keyed by git repo; shared across worktrees; machine-local). First 200 lines / 25KB of `MEMORY.md` load each session. Toggle via `/memory` or `autoMemoryEnabled`. | — |
| "Search what was solved in prior sessions" | **Claude-mem** | `claude-mem:mem-search` to query the persistent memory DB. | `claude-mem:mem-search` |

---

## 7. MCP SERVERS & EXTERNAL TOOLS

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Connect Claude to Jira, Google Drive, Slack, custom APIs" | **MCP servers** | Preferred: `claude mcp add --transport http\|sse\|stdio <name> <url-or-cmd>`. Or JSON in `.mcp.json` (project), `~/.claude.json` (user), or a `mcpServers` block in `settings.json`. Manage with `/mcp`. | `mcp` skill |
| "Use an MCP server from a package" | **Installed MCP** | `claude mcp add --transport stdio name -- npx -y <pkg>`. | — |
| "Why don't I see all MCP tools up front?" | **Tool Search (deferred tools)** | Enabled by default: only tool names + server instructions load at start; the model calls the **ToolSearch** tool to load a tool's schema on demand. Control via `ENABLE_TOOL_SEARCH` (unset/`true`/`auto`/`auto:N`). This is automatic, NOT done via `/mcp`. Built-in tools like WebSearch/WebFetch can also be deferred and surfaced the same way. | — |

---

## 8. PLUGINS & MARKETPLACES

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Install a plugin from a marketplace" | **Plugin marketplace** | `/plugin install` (or subcommands `list`/`enable`/`disable`). Add a source to `extraKnownMarketplaces` in `settings.json`. | `/plugin` |
| "Create a distributable plugin" | **Plugin authoring** | Package skills/agents/hooks/MCP; publish as a GitHub marketplace source; install via `/plugin`. | `plugins` skill; `skill-creator` |
| "Enable/disable a plugin" | **Plugin toggle** | `enabledPlugins` in `settings.json` (`{"plugin@source": true\|false}`), or `/plugin enable\|disable`. | — |

---

## 9. CI/CD & REMOTE EXECUTION

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Automate PR review, issue triage, or linting in GitHub Actions" | **GitHub Actions** | `/install-github-app` to set up, then `.github/workflows/claude.yml`; mention `@claude` in a PR. | `github-actions` |
| "Auto-fix a PR when CI fails or reviewers comment" | **Autofix PR** | `/autofix-pr [prompt]` spawns a Claude-Code-on-the-web session watching the branch's PR. Requires `gh`. | — |
| "Run Claude from Slack" | **Slack integration** | `/install-slack-app`, then `@claude <request>`. | `/install-slack-app` |
| "Kick off a task from a webhook or API call" | **Routines** | `/schedule` routine; supports GitHub webhook and API triggers. | — |
| "Build a custom or headless agent, or embed Claude Code in an app" | **Agent SDK** | The Claude Agent SDK (TypeScript / Python) runs the same harness + tools as Claude Code, headless. See `/en/sdk`. | `claude-code-agent-sdk` |

---

## 10. PERMISSIONS & SECURITY

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Restrict what Claude can read/execute" | **Permissions** | `permissions` in `settings.json` with **`allow` / `ask` / `deny`** arrays, per-tool (`Bash`, `Read`, `Write`, ...). Manage via `/permissions`. | `update-config` |
| "Auto-answer prompts for trusted commands" | **Allow rules** | `permissions.allow: ["Bash(npm install)"]`. `ask` prompts instead of auto-allowing. | `fewer-permission-prompts` |
| "Prevent Claude from reading a secret file" | **Deny rules** | `permissions.deny: ["Read(**/.secrets.env)"]`. | `update-config` |
| "Isolate execution" | **Sandbox** | `/sandbox` or `sandbox.enabled` in settings (supported platforms). | — |
| "Set environment variables for scripts" | **Env config** | `settings.json` `env: {VAR: value}`. | `update-config` |

---

## 11. BUILT-IN TOOLS (ALWAYS AVAILABLE)

| Tool | What It Does | When to Use |
|------|--------------|-------------|
| **Read** | Read a file (ranges, PDFs, images, notebooks) | Understand code/docs (targeted ranges) |
| **Write** | Create or overwrite a file | New files, complete rewrites |
| **Edit** | Exact string replacement in a file | Surgical changes |
| **Bash** / **PowerShell** | Run shell commands | Build, test, commit |
| **Glob** | Find files by pattern | Search before reading |
| **Grep** | Search file contents (ripgrep) | Find symbols, error patterns |
| **Agent** | Spawn a subagent (`Task` = legacy alias) | Isolated/parallel side tasks |
| **ToolSearch** | Load deferred tool schemas on demand | Before calling a deferred MCP/built-in tool |
| **WebSearch / WebFetch** | Search the web / fetch a URL | Research, fact-check (often deferred -> load via ToolSearch) |

---

## 12. CODE REVIEW & QUALITY GATES

| Signal | Capability | How | Detail |
|--------|-----------|-----|--------|
| "Review a diff locally for bugs + cleanups" | **Code review** (`/code-review`) | `/code-review [low\|medium\|high\|xhigh\|max\|ultra] [--fix] [--comment] [target]` (bundled skill). `--fix` applies findings; `--comment` posts inline PR comments; `ultra` = deep cloud review. | — |
| "Cleanup-only review (no bug hunting)" | **Simplify** (`/simplify`) | `/simplify [target]` (v2.1.154+). Four review agents run in parallel for reuse/simplification/efficiency/altitude. | — |
| "Review a PR" | **Review** (`/review`) | `/review [PR]` locally, or `/code-review ultra` (alias `/ultrareview`) for cloud multi-agent. | — |
| "Security review of pending changes" | **Security review** | `/security-review`. | — |

---

## 13. SETTINGS.JSON KEYS (CHEAT SHEET)

| Key | Type | Example | What It Does |
|-----|------|---------|--------------|
| `env` | object | `{VAR: value}` | Auto-load env vars for Bash/PowerShell |
| `permissions.allow/ask/deny` | array | `["Bash(npm install)"]` | Whitelist / prompt / block per tool |
| `hooks.<Event>` | array | PreToolUse/PostToolUse/SessionStart/Stop/... | Lifecycle command handlers |
| `statusLine.type` | string | `"command"` | Custom status line (terminal only) |
| `model` | string | `"claude-opus-4-8"` or `"opus"` | Default model (NOT `defaultModel`) |
| `effortLevel` | string | `"xhigh"` | Default effort (low/medium/high/xhigh only; max/ultracode are session-only) |
| `fastMode` | bool | `true` | Persist fast mode across sessions |
| `enabledPlugins` | object | `{"p@src": true}` | Enable/disable plugins (lives in settings.json) |
| `extraKnownMarketplaces` | object | `{name: {source}}` | Register plugin marketplaces |
| `mcpServers` | object | `{"name": {"command": ...}}` | MCP servers (also `.mcp.json` / `~/.claude.json` / `claude mcp add`) |
| `autoMemoryEnabled` | bool | `false` | Toggle auto memory |

---

## 14. ANTI-PATTERNS (FAILURE MODES)

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| "Context-switching between edits across 10+ files; this is slow" | Single-threading a distributed task. | `/batch` for parallel worktrees, or spawn Agent subagents / `/fork`. |
| "Hook isn't running" | Wrong matcher or wrong event name. | Check `settings.json`; matchers fire on tool name for tool events; verify event exists in `/en/hooks`. |
| "I set `effortLevel: max` in settings and it doesn't stick" | `max` and `ultracode` are session-only. | Use `/effort max` per session; persist only low/medium/high/xhigh. |
| "Set `defaultModel` in settings.json, ignored" | Key is `model`, not `defaultModel`. | Use the `model` key (alias or full ID). |
| "Expected fast mode to save money" | Fast mode is faster but COSTS MORE per token (usage credits). | Use `/fast` only for latency-sensitive interactive work; turn off for cost-sensitive/long autonomous runs. |
| "Permission prompt keeps appearing on a trusted command" | Not in allowlist / pattern mismatch. | Add exact pattern to `permissions.allow`; or run `/fewer-permission-prompts`. |

---

## 15. QUICK DECISION TREE (START HERE IF OVERWHELMED)

```
Is this a one-off task?
  YES -> Just prompt it (or use a slash command from a skill)
  NO  -> Does it repeat on a schedule?
       YES -> /schedule (cloud routine) or a hook (SessionStart/Pre/Post/Stop)
       NO  -> Does it need isolation from current work?
            YES -> /branch (fork convo) or git worktree, or /fork (keep my context)
            NO  -> Can it be parallelized?
                 YES -> /batch (5-30 workers) OR spawn Agent subagents
                 NO  -> Is it a review / multi-pass decision task?
                      YES -> /code-review (or /code-review ultra), or /effort ultracode
                      NO  -> Just run it. Adjust /effort {low|medium|high|xhigh|max} if stuck.

Need external data (Jira, Drive, Slack)?
  YES -> claude mcp add ... (or .mcp.json); tools load on demand via ToolSearch
  NO  -> Built-in tools only
```

---

## 16. MODEL IDs & ROUTING QUICK REFERENCE

| Model | ID / Alias | Use When | Speed | Cost |
|-------|-----------|----------|-------|------|
| **Opus 4.8** | `claude-opus-4-8` / `opus` | Hard reasoning, architecture, reviews, debugging | Slowest | Most ($$$$) |
| **Opus 4.8 Fast** | `/fast` (Opus) | Same tasks, interactive; up to ~2.5x faster | Fastest Opus | Higher per-token (usage credits) |
| **Sonnet 4.6** | `claude-sonnet-4-6` / `sonnet` | Coding, refactoring, boilerplate, simple debugging | Moderate | Medium ($$) |
| **Haiku 4.5** | `claude-haiku-4-5-20251001` / `haiku` | File ops, exploration, searches, fast summaries | Fastest | Least ($) |
| **opusplan** | `opusplan` | Opus reasoning in plan mode, Sonnet on execution | — | — |

---

## 17. KEY SLASH COMMANDS (SAMPLING)

| Command | Purpose |
|---------|---------|
| `/init` | Create / improve a starter CLAUDE.md |
| `/plan [desc]` | Enter plan mode (`/ultraplan` for cloud) |
| `/goal <cond>` | Keep working across turns until a condition is met |
| `/effort [level\|auto]` | Set reasoning depth (low/medium/high/xhigh/max; ultracode adds workflow orchestration) |
| `/fast` | Toggle fast Opus mode |
| `/model [id\|alias]` | Switch and default the model |
| `/batch <instruction>` | Parallelize a large change across worktrees |
| `/code-review [level] [--fix] [--comment]` | Review diff for bugs + cleanups |
| `/simplify [target]` | Cleanup-only review (no bug-hunting) |
| `/schedule [desc]` | Create a recurring cloud routine |
| `/loop [interval] [prompt]` | Run a prompt repeatedly in session |
| `/background [prompt]` | Detach session as a background agent (`/bg`) |
| `/fork <directive>` | Background subagent inheriting current conversation |
| `/teleport` / `/desktop` / `/remote-control` | Move a session web->terminal / to Desktop / control from claude.ai |
| `/memory` / `/context` / `/compact` | Edit memory / inspect context / summarize context |
| `/mcp` | Manage MCP server connections |
| `/permissions` | Manage allow/ask/deny rules |
| `/rewind` | Roll code/conversation back to a checkpoint |

---

**END CAPABILITY MAP**

This document is the canonical reference for Claude Code capabilities. Consult by SIGNAL. If a capability is not here, it may be in a detail skill or does not exist.
