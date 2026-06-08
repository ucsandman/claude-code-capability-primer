---
name: claude-code-hooks
description: "Use when configuring automated lifecycle commands (hooks) in Claude Code settings.json — event types, matcher syntax, exit codes, JSON output, path placeholders."
user-invocable: true
---

# Claude Code Hooks

Hooks are shell commands, HTTP endpoints, or MCP tools that execute automatically at lifecycle points: before/after tool calls, on session start/end, when config changes, and on other events. The harness controls execution; Claude cannot suppress them.

## Event Types

Hooks fire at specific cadences:

**Once per session:**
- `SessionStart` — beginning, resume, or after compaction
- `SessionEnd` — on session close

**Once per turn:**
- `UserPromptSubmit` — before Claude reads prompt (can block)
- `UserPromptExpansion` — before user command expands to prompt (can block)
- `Stop` — after Claude responds
- `StopFailure` — if response failed

**Per tool call:**
- `PreToolUse` — before tool executes (can block)
- `PermissionRequest` — when permission dialog appears
- `PermissionDenied` — when tool denied; can return `{retry: true}`
- `PostToolUse` — after tool succeeds
- `PostToolUseFailure` — if tool failed
- `PostToolBatch` — after parallel batch resolves

**Async/file watching:**
- `FileChanged` — watched file modified on disk (matcher specifies files)
- `CwdChanged` — working directory changed
- `ConfigChange` — settings/skills file modified
- `InstructionsLoaded` — CLAUDE.md or rules/*.md loaded
- `Notification` — when Claude Code sends notification (matcher: notification type)
- `MessageDisplay` — while assistant message displays
- `SubagentStart` — subagent spawned (matcher: agent type)
- `SubagentStop` — subagent finished
- `TaskCreated`, `TaskCompleted` — task lifecycle
- `Setup` — on `--init-only` or CI setup mode
- `PreCompact`, `PostCompact` — context compaction boundary
- `Elicitation`, `ElicitationResult` — MCP server user input
- `WorktreeCreate`, `WorktreeRemove` — git worktree lifecycle
- `TeammateIdle` — agent team teammate idle

## Configuration Locations

1. `~/.claude/settings.json` — user-wide (all projects)
2. `.claude/settings.json` — project-wide (shareable, commitable)
3. `.claude/settings.local.json` — project-specific (gitignored)
4. Plugin `hooks/hooks.json` — loaded at plugin install
5. Skill/agent YAML frontmatter — active while component loaded

## Hook Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolName|OtherTool",
        "hooks": [
          {
            "type": "command|http|mcp_tool|prompt|agent",
            "command": "script.sh",
            "timeout": 30,
            "statusMessage": "Running validation...",
            "async": false,
            "if": "Bash(git *)"
          }
        ]
      }
    ]
  }
}
```

## Matcher Syntax

- **Empty or `"*"`** — matches all
- **Alphanumeric/`_`/`|`** — exact match or literal alternatives: `Bash`, `Edit|Write`, `mcp__github__create_issue`
- **Other chars (including regex syntax)** — regex: `^Notebook`, `.envrc|.env`, `mcp__.*__write.*`
- **SessionStart matchers** — special: `startup|resume|clear|compact`
- **Notification matchers** — `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_complete`, `elicitation_response`

## Command Hook Type

**Exec form (preferred; safe for paths with special chars):**
```json
{
  "type": "command",
  "command": "node",
  "args": ["${CLAUDE_PLUGIN_ROOT}/script.js", "--fix"]
}
```
Spawns directly without shell; `${}` placeholders safe.

**Shell form (full features like pipes, globs):**
```json
{
  "type": "command",
  "command": "grep 'error' log.txt | wc -l"
}
```
Runs in shell; supports `&&`, pipes, `*` globs. Avoid untrusted paths.

**Common fields:**
- `timeout` — seconds before kill (default: varies by event)
- `statusMessage` — user-visible spinner text
- `async` — run in background without blocking
- `asyncRewake` — background task, wake Claude on exit 2
- `if` — permission rule: `Bash(rm **)`, `Edit(*.ts)`, `Bash(git *)`
- `once` — run once per session, then remove (skills only)
- `shell` — `bash` (default) or `powershell`

## Path Placeholders

- `${CLAUDE_PROJECT_DIR}` — project root
- `${CLAUDE_PLUGIN_ROOT}` — plugin installation directory
- `${CLAUDE_PLUGIN_DATA}` — plugin persistent data dir

Always use exec form with `args` when using placeholders.

## Windows Polyglot Pattern

Claude Code on Windows auto-prepends `bash` to `.sh` commands. Override by using extensionless filenames with a wrapper:

```json
{
  "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start"
}
```

Wrapper (`run-hook.cmd`): batch block for cmd.exe, shell code for bash:
```batch
: << 'CMDBLOCK'
@echo off
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%~dp0%~1" %2 %3
    exit /b %ERRORLEVEL%
)
where bash >nul 2>nul && bash "%~dp0%~1" %2 %3 && exit /b %ERRORLEVEL%
exit /b 0
CMDBLOCK
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "${SCRIPT_DIR}/$1" "${@:2}"
```

The `: << 'CMDBLOCK'` trick: cmd.exe runs batch; bash sees `:` (no-op) and runs Unix shell code.

## Exit Code Protocol

| Code | Meaning |
|------|---------|
| **0** | Success. Harness parses stdout for JSON output. |
| **2** | Blocking error. Stderr shown to user. Hook can deny action or block turn. |
| **Other** | Non-blocking error. First line of stderr shown, execution continues. |

## Common Input (JSON stdin)

All hooks receive:
- `session_id` — unique identifier
- `cwd` — current working directory
- `permission_mode` — `default`, `plan`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`
- `hook_event_name` — event name
- `effort.level` — `low`, `medium`, `high`, `xhigh`, `max`
- `transcript_path` — path to session transcript (JSONL)
- `agent_id`, `agent_type` — when inside subagent
- **Event-specific fields** (e.g., `tool_name`, `tool_input` for `PreToolUse`)

## JSON Output (Exit 0 Only)

Exit 0 with valid JSON stdout to control harness. Output format depends on your platform:

**Claude Code (CLAUDE_PLUGIN_ROOT set):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Context for Claude",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by policy"
  }
}
```

**Cursor (CURSOR_PLUGIN_ROOT set):**
```json
{
  "additional_context": "Context for Claude"
}
```

**Copilot CLI (SDK standard):**
```json
{
  "additionalContext": "Context for Claude"
}
```

**Universal fields:**
- `continue: false` — stop entire turn
- `stopReason` — message when stopping
- `suppressOutput: true` — hide from transcript
- `systemMessage` — warning shown to user
- `terminalSequence` — OSC codes (desktop notification, window title)

## HTTP Hook Type

```json
{
  "type": "http",
  "url": "http://localhost:8080/hook",
  "headers": {"Authorization": "Bearer ${TOKEN}"},
  "allowedEnvVars": ["TOKEN"]
}
```

POST with stdin JSON. Whitelist env vars to pass. Return 2xx with JSON body for decisions.

## MCP Tool Hook Type

```json
{
  "type": "mcp_tool",
  "server": "my_mcp_server",
  "tool": "tool_name",
  "input": {"file_path": "${tool_input.file_path}"}
}
```

Call tool on connected MCP server. Fields can interpolate from stdin.

## Prompt/Agent Hook Types

```json
{
  "type": "prompt",
  "prompt": "Should this be allowed? $ARGUMENTS",
  "model": "fast-model"
}
```

Sends yes/no question to Claude. Rarely needed; prefer command hooks for determinism.

## Real Example: Block rm -rf

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "if": "Bash(rm -rf *)",
        "hooks": [{
          "type": "command",
          "command": "node",
          "args": ["${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.js"]
        }]
      }
    ]
  }
}
```

Exit code 2 to deny; stderr message shown.

## Disable All Hooks

```json
{
  "disableAllHooks": true
}
```

Top-level key to skip all hooks (useful for debugging).

## When to Use Hooks

- **Deterministic automation** ("each time X, always do Y")
- **Security gates** (block dangerous commands, validate secrets before commits)
- **Context injection** (SessionStart loads docs, specs, templates)
- **Auto-validation** (PostToolUse runs tests, blocks if fails)
- **Observability** (log commands, audit config changes)

**Don't use hooks for:**
- One-off tasks Claude should handle directly
- Business logic that belongs in code
- Anything requiring complex reasoning (use prompt/agent types sparingly)

## Debug Hooks

- `/hooks` command: browse configured hooks, view matchers/handlers
- Exit 2 blocks silently; non-0 shows error in transcript
- Test JSON with `jq` before deploying
- Check script permissions on Unix: `chmod +x script.sh`
- Use `timeout` to kill runaway scripts
- Hook stderr shown in transcript (unless `suppressOutput: true`)

## Security

Hooks execute with your user permissions. Always:
- Store hook scripts in `.claude/` or plugin dirs (not world-writable)
- Never call untrusted executables
- Whitelist env vars in HTTP hooks
- Review hook code before enabling
