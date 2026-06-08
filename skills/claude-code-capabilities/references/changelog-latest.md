# Claude Code — Recent Changes

> **Refresh with:** `curl -s https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | head -200`  
> **Today:** June 8, 2026. Current version: 2.1.168.

---

## Core Capability Changes (v2.1.154–v2.1.168)

### **Model & Effort**
- **Opus 4.8** now default for Max, Team Premium, Enterprise pay-as-you-go, Anthropic API; defaults to `high` effort
- **Fallback models** (`fallbackModel` setting): up to 3 backups tried in order on overload/unavailable. Applies in `-p` mode and background sessions only
- **Fast mode**: `/fast` on Opus 4.8/4.7/4.6. Higher per-token cost ($10/$50 on Opus 4.8), ~2.5x speed. Research preview
- **Thinking control**: `MAX_THINKING_TOKENS=0`, `--thinking disabled` disable thinking; per-model toggles [unverified exact API]

### **Hooks & Automation**
- **Hook context**: tool-use events receive `effort: { level: string }` and subprocess gets `$CLAUDE_EFFORT` env var
- **Hook output**: `Stop` and `SubagentStop` hooks can return `hookSpecificOutput.additionalContext` (no error label)
- **MessageDisplay hook**: new event lets hooks transform or hide assistant message text as displayed

### **Plugins & Extensibility**
- **Plugin loading**: `--plugin-dir` accepts `.zip` archives; `--plugin-url https://...` fetches plugin zip
- **Plugin listing**: `/plugin list --enabled` / `--disabled` filters
- **Auto-load from `.claude/skills`**: plugins in skill directories load without marketplace registration
- **defaultEnabled: false**: plugins can install dormant, require manual enable

### **Sessions & Worktrees**
- **Worktree base**: `worktree.baseRef` setting (`fresh` | `head`); `fresh` (default) excludes unpushed commits
- **Session ID env**: `$CLAUDE_CODE_SESSION_ID` in Bash subprocess
- **Background sessions**: improved stability, visible in `/resume`, pin to keep alive
- **Remote Control**: now works with console (API key) auth

### **Permissions & Security**
- **Deny glob patterns**: tool-name position accepts `*` to deny all tools (allow rules reject globs)
- **Auto mode hard deny**: `settings.autoMode.hard_deny` rules block unconditionally
- **Cross-session messaging**: `SendMessage` from other Claude sessions no longer carries user authority
- **MCP OAuth**: concurrent server refresh no longer loses refresh tokens [unverified edge-case details]

### **Managed Settings & Admin**
- **Version enforcement**: `requiredMinimumVersion`, `requiredMaximumVersion` (SDK managedSettings) — Claude Code refuses to start outside range
- **Managed settings merge**: `parentSettingsBehavior` admin key controls policy merge behavior

### **Terminal & Rendering**
- **JetBrains IDE**: fixed flickering (2026.1+) and Shift+non-ASCII in Kitty protocol
- **PowerShell**: fixed command validation hangs
- **Alternate screen**: `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` opts out fullscreen, preserves native scrollback
- **OTEL filtering**: Bash, hooks, MCP, LSP subprocesses no longer inherit `OTEL_*` env vars

### **MCP & Tools**
- **MCP status**: `/mcp` shows tool count per server
- **Tool search**: enabled via `ENABLE_TOOL_SEARCH=true`
- **Parallel tool calls**: independent processing; reduced permission checks on Edit

### **GitHub & CI/CD**
- **Code Review**: `/code-review` command reports correctness bugs at chosen effort level
- **Simplify**: `/simplify` is cleanup-only (no bug-hunting)
- **Security guidance plugin**: reviews code changes for vulnerabilities as work progresses

---

## Effort Level Tiers (Opus 4.8)

| Level     | Model      | Use Case                            |
|-----------|------------|-------------------------------------|
| `low`     | Haiku      | Fast tasks, exploration             |
| `medium`  | Sonnet     | Balanced, cost-conscious            |
| `high`    | Opus 4.8   | Default; balances speed + quality   |
| `xhigh`   | Opus 4.8   | Deeper reasoning, higher cost       |
| `max`     | Opus 4.8   | Session-only; costliest, risk overthinking |

**Note**: `ultracode` is NOT an effort level. It is a Claude Code setting that sends `xhigh` effort + orchestrates dynamic workflows. Session-only; set via `/effort ultracode` or `--ultracode`.

---

## CLI & Settings Quick Ref

```bash
# Model & effort
/model claude-opus-4-8
/effort high
/fast                          # Toggle fast mode (higher cost, ~2.5x speed)

# Plugins
claude --plugin-dir ./plugins.zip
claude --plugin-url https://example.com/plugin.zip

# Fallback model (print mode, background sessions)
claude -p --fallback-model sonnet "query"
```

**Key Settings**:
- `effortLevel`: `low|medium|high|xhigh` (persists)
- `fallbackModel`: `[model1, model2?, model3?]` (tried in order)
- `fastMode`: `true|false` (persists; use `/fast` to toggle)
- `autoMode.hard_deny`: `[deny rules]` (unconditional blocks)
- `worktree.baseRef`: `fresh|head` (branch source)
- `ENABLE_TOOL_SEARCH`: `"true"|"false"` (enable discovery)

---

## Hooks Reference

**Event names:** `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `MessageDisplay`, and 26 others.

**Tool-use event input** (PreToolUse, PostToolUse, PermissionRequest):
```json
{
  "session_id": "abc123",
  "tool_name": "Bash",
  "tool_input": { "command": "..." },
  "effort": { "level": "high" }
}
```

**Subprocess env vars**:
- `$CLAUDE_EFFORT` = current effort level
- `$CLAUDE_CODE_SESSION_ID` = session ID

**Output** (all hooks):
```json
{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "Text for Claude",
    "reloadSkills": true
  }
}
```

---

## Not Yet Verified

- Exact semantics of `hookSpecificOutput.additionalContext` continuation behavior
- Full scope of glob patterns in deny rules (confirm `*` semantics, depth limits)
- Specific worktree base-ref edge cases (dirty trees, remote divergence)
- Which MCP servers flag as 0-tool in `/mcp status`
- Detailed MCP OAuth concurrent refresh fix (changelog entry exists; mechanics unclear)

---

**Sources:**
- [Claude Code Changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Code.claude.com Docs](https://code.claude.com/docs/en/)
- [Week 22 Digest · May 25–29, 2026](https://code.claude.com/docs/en/whats-new/2026-w22)
- [Settings Reference](https://code.claude.com/docs/en/settings)
- [Hooks Documentation](https://code.claude.com/docs/en/hooks)
- [Model Configuration](https://code.claude.com/docs/en/model-config)
- [Fast Mode Guide](https://code.claude.com/docs/en/fast-mode)
