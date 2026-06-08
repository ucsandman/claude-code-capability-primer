---
name: claude-code-mcp
description: "Use when configuring MCP servers in Claude Code — connecting external tools (GitHub, Stripe, Sentry, databases), choosing transports (HTTP, stdio, WebSocket), managing scopes, handling authentication, scaling with tool search, and decidi..."
user-invocable: true
---

# Claude Code MCP Servers

## What is MCP?

Model Context Protocol (MCP) = **external tools/data/resources** exposed to Claude as callable tools. Live systems: issue trackers, databases, APIs, browsers, design tools. Not suitable for repo-local logic (use skills or scripts instead).

Tools are named `mcp__<server-name>__<tool-name>` in output. Example: `mcp__github__list_issues`.

---

## Configuration

**Three scopes, stored in two files:**

| Scope | Stored in | Shared with team | Loaded in |
|-------|-----------|------------------|-----------|
| Local (default) | `~/.claude.json` (project-specific path) | No | Current project only |
| Project | `.mcp.json` (repo root) | Yes, via git | Current project only |
| User | `~/.claude.json` (top-level `mcpServers` key) | No | All your projects |

**Add a server:**
```bash
# HTTP server (hosted)
claude mcp add --transport http <name> <url>
claude mcp add --transport http stripe https://mcp.stripe.com

# Stdio server (local process, needs --)
claude mcp add <name> -- <command> [args...]
claude mcp add playwright -- npx -y @playwright/mcp@latest

# Set scope
claude mcp add --scope user <name> <url>
claude mcp add --scope project <name> <url>
```

**Verify:**
```bash
claude mcp list
claude mcp get <name>
```

**Remove:**
```bash
claude mcp remove <name> [--scope local|project|user]
```

**Edit `.mcp.json` directly:**
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.github.com/...",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

---

## Transports

**HTTP** (hosted, recommended for remote servers):
- Stateless, runs at a URL.
- `claude mcp add --transport http <name> <url>`
- Also called `streamable-http` in JSON (MCP spec naming).

**Stdio** (local, for filesystem/browser/db access):
- Command runs on your machine, talks via stdin/stdout.
- `claude mcp add <name> -- <command> [args...]`
- **Critical:** Separate options from server command with `--`. Everything after `--` goes untouched to the server.
- Pass env vars via `--env KEY=value` or `env` in config.
- Startup timeout: 30s default; set `MCP_TIMEOUT=60000` (ms) if slow.

**SSE** (hosted, **DEPRECATED** — use HTTP instead):
- Server-Sent Events; older streaming transport.
- `"type": "sse"` in `.mcp.json`.

**WebSocket** (hosted, for persistent bidirectional connections):
- Configure in `.mcp.json` or `claude mcp add-json`.
- `"type": "ws"` with `url`, `headers`, `timeout`, `alwaysLoad`.
- Use HTTP instead when server only responds to requests (HTTP has OAuth support, WebSocket does not).

---

## Authentication

**Environment variables (stdio servers):**
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```
`${}` syntax (or `${VAR:-default}` for defaults) expands from shell env at runtime.

**HTTP headers (hosted servers):**
```json
{
  "mcpServers": {
    "api": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

**OAuth (interactive browser sign-in):**
1. `claude mcp add --transport http <name> <url>`
2. Server shows `! Needs authentication` in `/mcp`
3. Inside `claude` session: `/mcp` → select server → `Authenticate` → sign in → auto-connected

**Static token (at add time):**
```bash
claude mcp add --transport http <name> <url> --header "Authorization: Bearer <token>"
```

---

## Tool Search (Deferred Loading)

**What it does:** Instead of loading all tool definitions upfront (bloats context for 50+ tools), Claude searches on demand and loads only what it needs (3–5 tools per search). Saves ~85% context overhead.

**Who supports it:** Requires Sonnet 4.5+ or Opus 4.5+. **Haiku does not support tool search** (on Claude Code or API).

**Enabled by default:** Yes. Falls back to upfront loading on Vertex AI or custom `ANTHROPIC_BASE_URL`.

**Configure via `ENABLE_TOOL_SEARCH` env var:**

| Value | Behavior |
|-------|----------|
| (unset) | Deferred on demand (default). Falls back to upfront on Vertex AI / proxy. |
| `true` | Force deferred (fails on older models or proxies without `tool_reference` support). |
| `false` | Force upfront; load all tool defs at startup. |
| `auto` | Threshold: upfront if <10% of context, deferred otherwise. |
| `auto:N` | Threshold: upfront if <N% of context. Example: `auto:5` for 5%. |

**Set in settings.json:**
```json
{
  "ENABLE_TOOL_SEARCH": "true"
}
```

**Override per query (Agent SDK only):**
```typescript
for await (const msg of query({
  prompt: "...",
  options: { env: { ENABLE_TOOL_SEARCH: "auto:5" } }
})) { ... }
```

**Always load one server upfront (skip search):**
```json
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "...",
      "alwaysLoad": true
    }
  }
}
```

---

## Permissions

Tools from MCP require explicit allow-list.

**CLI (first time):**
- Claude asks: "Allow use of `mcp__<server>__<tool>`?"
- Approve in session.

**Pre-approve via settings.json:**
```json
{
  "permissions": {
    "allow": [
      "mcp__github__*",
      "mcp__stripe__*"
    ]
  }
}
```

Use wildcards to avoid per-tool approval.

---

## Scope Precedence

When the same server is defined in multiple scopes:

1. Local
2. Project
3. User
4. Plugin-provided
5. Claude.ai connectors

The entry from the highest-precedence source is used entirely (fields not merged).

---

## Connection Status

Run `/mcp` in session or `claude mcp list` from shell:

| Status | Meaning | Fix |
|--------|---------|-----|
| ✓ Connected | Ready. | Use it. |
| ! Needs authentication | OAuth/token required. | `/mcp` → select → `Authenticate` or `--header` on add. |
| ✗ Failed to connect | Server down, unreachable, or bad config. | Check URL (HTTP), command (stdio), env vars, timeouts. |
| ⏸ Pending approval | Project-scope server awaiting approval. | `/mcp` → approve, or add to `permissions.allow`. |

**Debug stdio:**
Run the command directly to see errors:
```bash
npx -y @playwright/mcp@latest
```

**Debug HTTP:**
```bash
curl -I https://mcp.sentry.dev/mcp
# 404/405: up, reachable.
# 401/403: auth missing/invalid.
# No response: network/DNS issue.
```

**Startup timeout:**
```bash
MCP_TIMEOUT=60000 claude
```

---

## Resources and Prompts

**Reference resources in prompts** (like `@file.md`):
```
@server:protocol://path
@github:issue://123
@postgres:schema://users
```

**Execute MCP prompts as commands:**
```
/mcp__servername__promptname [args...]
/mcp__github__pr_review 456
```

---

## When to Use MCP vs Skills/Scripts

**Use MCP when:**
- Tool is external API/service/database with live state.
- Needs to read/act on remote system (GitHub, Stripe, Slack, browser).
- Shared across projects (user or project scope).
- Already exists and MCP-compatible.

**Use skill/script when:**
- Repo-local logic, refactoring, generation, testing.
- Parses your codebase and emits artifacts.
- Runs only in this project.
- Custom to your workflow.

---

## Examples

**Stdio server (local CLI, no auth):**
```json
"mcpServers": {
  "my-tools": {
    "command": "my-mcp-server",
    "args": ["mcp", "--transport", "stdio"],
    "description": "what this server exposes"
  }
}
```

**Common servers people add:** `context7` (live library docs), `github` (GitHub API), `stripe` (Stripe API), plus filesystem, database, and browser/automation servers.

Check your actual servers: `/mcp` in session or `claude mcp list` from shell.

---

## Troubleshooting Checklist

1. **Server not in `/mcp` list?**
   - Check scope: `claude mcp get <name>` or grep `~/.claude.json` and `.mcp.json`.
   - Local servers tied to project root or exact directory. Re-add if different project.

2. **Status: "Failed to connect"?**
   - HTTP: `curl -I <url>` to confirm reachable.
   - Stdio: run command directly to see error.
   - Missing env var / token / startup timeout.

3. **Tools visible but Claude won't call?**
   - Missing `permissions.allow` pre-approval. `/mcp` to approve, or add to settings.

4. **No tools in `/mcp` tool list?**
   - Server started but no tools registered → likely missing API key / env var.
   - Check server docs for required vars; pass via `--env KEY=value` or `env` field.

5. **Changes to `.mcp.json` don't apply?**
   - Restart session (Claude reads `.mcp.json` at startup).
   - Check file syntax (valid JSON).
   - Run `claude mcp reset-project-choices` if you rejected server earlier.

---

## Key Settings You Control

```json
{
  "mcpServers": {
    "name": {
      "type": "http|stdio|sse|ws",
      "url": "...",
      "command": "...",
      "args": [...],
      "env": { "KEY": "${VAR}" },
      "headers": { "Authorization": "Bearer ${TOKEN}" },
      "alwaysLoad": true,
      "timeout": 600000
    }
  },
  "ENABLE_TOOL_SEARCH": "auto|auto:5|true|false",
  "permissions": {
    "allow": ["mcp__<server>__*"]
  }
}
```

---

## Related

- [MCP quickstart](https://code.claude.com/docs/en/mcp-quickstart)
- [MCP full reference](https://code.claude.com/docs/en/mcp)
- [Managed MCP](https://code.claude.com/docs/en/managed-mcp) (team/enterprise control)
- [MCP specification](https://modelcontextprotocol.io)
- [MCP server directory](https://github.com/modelcontextprotocol/servers)
- [Build your own server](https://modelcontextprotocol.io/quickstart/server)
