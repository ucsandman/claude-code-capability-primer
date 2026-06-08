---
name: claude-code-agent-sdk
description: "Use when building custom AI agents headlessly, embedding Claude Code tools in an app, or running scripted/cron agents—need SDK package names, setup, core API entry points, supported languages, and relation to Claude Code CLI and Messages..."
user-invocable: true
---

# Claude Code Agent SDK

**What it is:** Library for building production AI agents in TypeScript or Python with the same tools, agentic loop, and context management that power Claude Code. Same capabilities as the CLI, but programmable for headless automation, CI/CD, custom applications, and production deployments.

**Packages:**
- **TypeScript:** `@anthropic-ai/claude-agent-sdk` (includes native Claude Code binary)
- **Python:** `claude-agent-sdk` (requires Python 3.10+)

Installation:
```bash
npm install @anthropic-ai/claude-agent-sdk
pip install claude-agent-sdk
```

## When to Use

**Use Agent SDK when:** productizing/automating agents headlessly, embedding tools into apps, running agents on schedule, building custom agents with full control, or agents need autonomous operation without interactive CLI.

**Don't use when:** interactive development (use CLI), one-off tasks (use CLI), or needing managed REST API without running infrastructure (use Managed Agents).

## Core Entry Point: `query()`

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Fix the bug in auth.ts",
  options: { allowedTools: ["Read", "Edit", "Bash"] }
})) {
  console.log(message);
}
```

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Fix the bug in auth.py",
        options=ClaudeAgentOptions(allowed_tools=["Read", "Edit", "Bash"]),
    ):
        print(message)

asyncio.run(main())
```

Python also supports context manager: `async with ClaudeSDKClient(options=...) as client: await client.query(...)`

## Key Options (Python snake_case / TypeScript camelCase)

| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `allowed_tools` / `allowedTools` | string[] | — | Pre-approve tools |
| `disallowed_tools` / `disallowedTools` | string[] | — | Block tools or patterns |
| `permission_mode` / `permissionMode` | string | `"default"` | Control approval: `default`, `dontAsk`, `acceptEdits`, `bypassPermissions`, `plan`, `auto` (TS only) |
| `cwd` | string | cwd | Working directory |
| `model` | string | latest Claude | Model ID |
| `resume` | string | — | Session ID to resume |
| `max_turns` / `maxTurns` | number | — | Max iterations |
| `hooks` | object | — | Lifecycle callbacks |
| `agents` | object | — | Subagent definitions |
| `mcp_servers` / `mcpServers` | object | — | MCP server config |
| `setting_sources` / `settingSources` | string[] | `["project"]` | Config sources to load |

## Built-in Tools

Read, Write, Edit, Bash, PowerShell, Monitor, Glob, Grep, WebSearch, WebFetch, AskUserQuestion.

## Hooks: Lifecycle Callbacks

**Available events** (17+ total; 6 TypeScript-only):

| Event | Python | TypeScript | Purpose |
|-------|--------|-----------|---------|
| PreToolUse | ✓ | ✓ | Block/modify before execution |
| PostToolUse | ✓ | ✓ | Audit/log after completion |
| PostToolUseFailure | ✓ | ✓ | Handle errors |
| PostToolBatch | — | ✓ | React to batch completion |
| UserPromptSubmit | ✓ | ✓ | Inject context |
| MessageDisplay | — | ✓ | Transform display text |
| Stop | ✓ | ✓ | Save state on exit |
| SubagentStart | ✓ | ✓ | Track spawn |
| SubagentStop | ✓ | ✓ | Aggregate results |
| PreCompact | ✓ | ✓ | Archive before compaction |
| PermissionRequest | ✓ | ✓ | Custom permissions |
| SessionStart | — | ✓ | Initialize (TS only) |
| SessionEnd | — | ✓ | Cleanup (TS only) |
| Notification | ✓ | ✓ | Forward status |
| Setup | — | ✓ | Init tasks (TS only) |
| TeammateIdle | — | ✓ | Reassign (TS only) |
| TaskCompleted | — | ✓ | React to task (TS only) |
| ConfigChange | — | ✓ | Reload settings (TS only) |
| WorktreeCreate | — | ✓ | Track worktree (TS only) |
| WorktreeRemove | — | ✓ | Cleanup worktree (TS only) |

Hooks use `matcher` patterns (e.g. `"Write|Edit"`) and return `hookSpecificOutput` with `permissionDecision`, `updatedInput`, `additionalContext`, or `updatedToolOutput`. **Note:** `SessionStart`/`SessionEnd` are TypeScript-only for SDK callbacks; Python supports them only as shell command hooks in `.claude/settings.json`.

## Subagents

Spawn specialized agents via the `Agent` tool. **Warning:** when parent uses `bypassPermissions`, `acceptEdits`, or `auto` mode, subagents inherit it without override—grants full system access in controlled environments only.

## Sessions: Context Persistence

Capture `session_id` from init message, resume with `resume=session_id`. Sessions persist as `.jsonl` files locally. Use `resumeSessionAt` to resume at specific transcript point.

## MCP Integration

Register via `mcp_servers` / `mcpServers` option or load from `.claude/mcp.json` / `~/.claude/mcp.json`.

## Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | No auto-approvals; unmatched tools trigger callback |
| `dontAsk` | Deny instead of prompting |
| `acceptEdits` | Auto-approve file edits + filesystem ops |
| `bypassPermissions` | All tools run without prompts (use cautiously) |
| `plan` | Read-only tools; Claude analyzes without editing |
| `auto` | Model-classified approvals (TS only) |

Evaluation order: Hooks → Deny rules → Permission mode → Allow rules → Callback.

## Configuration Sources

Loaded from `.claude/` and `~/.claude/` when `settingSources` includes those paths:
- **Skills:** `.claude/skills/*/SKILL.md`
- **Commands:** `.claude/commands/*.md` (legacy)
- **Memory:** `CLAUDE.md` or `.claude/CLAUDE.md`
- **Settings/Hooks:** `.claude/settings.json`
- **Plugins:** Programmatic via `plugins` option only

## Authentication

Priority: `api_key` in options → `ANTHROPIC_API_KEY` env var → Third-party providers (Bedrock, AWS, Vertex AI, Azure).

## Billing

**Starting June 15, 2026:** Agent SDK usage draws from separate monthly credit pool (distinct from interactive Claude). Credits do not roll over.

## TypeScript vs Python

| Concept | TypeScript | Python |
|---------|-----------|--------|
| Options | Passed as object | `ClaudeAgentOptions` |
| camelCase | `allowedTools`, `mcpServers` | `allowed_tools`, `mcp_servers` |
| Iteration | `for await (const msg of query(...))` | `async for message in query(...)` |
| SessionStart/End | Callback hooks | Shell command hooks only |

## Key Resources

- Docs: https://code.claude.com/docs/en/agent-sdk/overview
- TypeScript: https://code.claude.com/docs/en/agent-sdk/typescript
- Python: https://code.claude.com/docs/en/agent-sdk/python
- Hooks: https://code.claude.com/docs/en/agent-sdk/hooks
- Permissions: https://code.claude.com/docs/en/agent-sdk/permissions
- Subagents: https://code.claude.com/docs/en/agent-sdk/subagents
- Sessions: https://code.claude.com/docs/en/agent-sdk/sessions
- MCP: https://code.claude.com/docs/en/agent-sdk/mcp
- Plugins: https://code.claude.com/docs/en/agent-sdk/plugins
- Examples: https://github.com/anthropics/claude-agent-sdk-demos
