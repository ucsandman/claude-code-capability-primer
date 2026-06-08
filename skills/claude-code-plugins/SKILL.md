---
name: claude-code-plugins
description: "Use when building, debugging, or installing Claude Code plugins—understanding plugin structure, CLI commands, marketplace configuration, or skill/agent packaging."
user-invocable: true
---

# Claude Code Plugins

A **plugin** is a self-contained directory containing skills, agents, hooks, MCP servers, or LSP servers that extends Claude Code with custom functionality shareable across projects and teams.

## Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   ├── plugin.json              # [Required] Plugin manifest
│   └── marketplace.json         # [If hosting a marketplace] Lists plugins
├── skills/                      # Skills: subdirs with SKILL.md
├── agents/                      # Custom agent definitions (markdown)
├── hooks.json                   # Hook definitions (at plugin root)
├── .mcp.json                    # MCP server configs
├── .lsp.json                    # LSP server configs
├── monitors/monitors.json       # Background monitor definitions
├── bin/                         # Executables added to Bash PATH
├── settings.json                # Default settings when plugin enabled
└── [README.md, LICENSE]
```

**Critical:** Only `plugin.json` and optionally `marketplace.json` go inside `.claude-plugin/`. Directories like `skills/`, `agents/`, `hooks.json` live at plugin **root**.

## Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "description": "What the plugin does; shown in plugin manager",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "you@example.com",
    "url": "https://github.com/you"
  },
  "homepage": "https://...",
  "repository": "https://...",
  "license": "MIT",
  "keywords": ["tag1", "tag2"]
}
```

**Fields:**
- `name`: unique identifier + skill namespace. Skills use `/{name}:{skill-name}` format.
- `description`: required; shown in plugin manager; max ~1024 chars.
- `version`: optional; if omitted, git commit SHA used (every commit = new version). If set, users only receive updates on version bump.
- `author`, `homepage`, `repository`, `license`, `keywords`: optional metadata.

## Marketplaces

A **marketplace** is a directory or git repo containing a `.claude-plugin/marketplace.json` that lists plugins. Users install plugins *from* marketplaces.

### marketplace.json Schema

```json
{
  "name": "my-marketplace",
  "owner": { "name": "...", "url": "..." },
  "metadata": { "description": "..." },
  "plugins": [
    {
      "name": "plugin-name",
      "description": "...",
      "version": "1.0.0",
      "author": { "name": "...", "url": "..." },
      "source": "./plugins/plugin-name/" or "./",
      "category": "productivity",
      "homepage": "https://...",
      "tags": ["tag1"]
    }
  ]
}
```

- `source`: path relative to marketplace root (`./ ` = marketplace root is the plugin, `./plugins/name/` = subdirectory), or a git URL in known_marketplaces.
- **Relative paths** work for file, git, and directory sources only.

### Marketplace Sources (settings.json)

```json
{
  "github": {
    "source": "github",
    "repo": "username/repo"
  },
  "git-url": {
    "source": "git",
    "url": "https://github.com/username/repo.git"
  },
  "local": {
    "source": "directory",
    "path": "/absolute/path/to/marketplace"
  }
}
```

- **GitHub:** clones to `~/.claude/plugins/marketplaces/{name}/`; plugin sources are relative paths into the clone.
- **Git URL:** same as GitHub; use for non-GitHub git hosts.
- **Directory:** local filesystem path; direct access without cloning.

## Skills in Plugins

Skills live in `skills/<name>/SKILL.md`. Each skill becomes `/plugin-name:skill-name`.

**SKILL.md frontmatter:**
```yaml
---
name: hello
description: "What the skill does. Use when [context]."
disable-model-invocation: true
allowed-tools: Bash, Read, Write
---

Skill instructions. Reference $ARGUMENTS for user input.
```

**Reference files:** Store supporting files in `references/` subdirectory; include in SKILL.md as `` `references/file.md` `` or inline with `` @./references/file.json ``.

## Agents in Plugins

Custom agents live in `agents/` as markdown files:

```
plugins/my-plugin/agents/my-reviewer.md
```

**Format:**
```markdown
---
name: my-reviewer
tier: sonnet
description: "What the agent does"
---

You are a code reviewer focused on security and performance...
```

Agents are invoked via the `Agent` tool using bare name (not namespaced). Plugin agents appear in `/agents` UI but are addressed by bare name in tool calls.

## Hooks

Create `hooks.json` at plugin root:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint:fix",
            "timeout": 60,
            "statusMessage": "Running linter..."
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

**Events:** `PreToolUse` (before tool runs), `PostToolUse` (after tool completes), `Stop` (session ends).
**Matcher:** regex pattern matching tool names (e.g., `Write|Edit|Bash`).
**Command:** runs via shell; receives hook input as JSON on stdin. Use `${CLAUDE_PLUGIN_ROOT}` to reference plugin directory.

## CLI Commands

```bash
# Create plugin scaffold in ~/.claude/skills/
claude plugin init <plugin-name>

# Test local plugin during development
claude --plugin-dir ./my-plugin
# Or multiple:
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two

# Test plugin from .zip archive (v2.1.128+)
claude --plugin-dir ./my-plugin.zip

# Test from hosted URL
claude --plugin-url https://example.com/my-plugin.zip

# Reload plugins, skills, agents, hooks in current session
/reload-plugins

# List installed plugins
/plugins

# Browse and search marketplaces
/plugin marketplace browse

# Add marketplace
claude plugin marketplace add github:username/repo
claude plugin marketplace add https://git-url.git
claude plugin marketplace add /path/to/local/dir

# Install plugin from marketplace
claude plugin install <plugin-name>@<marketplace-name>

# Remove plugin
claude plugin uninstall <plugin-name>@<marketplace-name>

# Enable/disable plugin
claude plugin enable <plugin-name>@<marketplace-name>
claude plugin disable <plugin-name>@<marketplace-name>

# Validate plugin structure and manifest
claude plugin validate
```

## Skills-Directory Plugins

Plugins in `~/.claude/skills/` auto-load without marketplace install:

```bash
claude plugin init my-local-plugin
# Creates ~/.claude/skills/my-local-plugin/
# Auto-loads as my-local-plugin@skills-dir
```

## MCP Servers in Plugins

Configure MCP servers in `.mcp.json` at plugin root:

```json
{
  "my-server": {
    "command": "node",
    "args": ["./mcp/server.js"],
    "env": { "API_KEY": "${env:MY_API_KEY}" }
  }
}
```

Server starts automatically when plugin is active. Use `${env:VAR}` for environment variable substitution.

## LSP Servers in Plugins

Configure LSP servers in `.lsp.json` at plugin root:

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

Language server binary must be installed on user's machine.

## When to Use Plugins vs Standalone Config

| Goal | Use |
|------|-----|
| Personal, project-specific skills | Standalone (`.claude/skills/`) |
| Share across projects or teams | Plugin + marketplace |
| Versioned releases and easy updates | Plugin + marketplace |
| Quick experiments | Standalone or skills-directory plugin |

## Publishing to Community Marketplace

1. Set `version` in `plugin.json` or rely on git commit SHA.
2. Host repo with `.claude-plugin/plugin.json` and components at root.
3. Submit via [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit) or [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit).
4. Run `claude plugin validate` before submitting.
5. Approved plugins pin to commit SHA in [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community).
6. Official marketplace (`claude-plugins-official`) is curated separately; no application process.

## Converting Standalone Config to Plugin

1. Create `plugin-name/.claude-plugin/plugin.json` with manifest.
2. Copy `~/.claude/skills/*` → `plugin-name/skills/`; copy `~/.claude/commands/*` → `plugin-name/commands/` (legacy).
3. Convert hooks from `settings.json` to `plugin-name/hooks.json`.
4. Test with `claude --plugin-dir ./plugin-name`.
5. Distribute via marketplace or `.zip`.
