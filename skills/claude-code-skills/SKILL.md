---
name: claude-code-skills
description: "Use when you need to understand, create, trigger, or debug Claude Code skills—reusable workflows defined in SKILL.md files with YAML frontmatter."
user-invocable: true
---

# Claude Code Skills

**A skill = a workflow saved in SKILL.md with YAML frontmatter that Claude loads on demand and applies when relevant.**

## Core Concepts

- **SKILL.md**: Required markdown file with YAML frontmatter (`name`, `description`) + markdown body (instructions). Lives in `~/.claude/skills/<name>/`, `.claude/skills/<name>/`, or plugin `skills/<name>/`.
- **Frontmatter**: YAML block between `---` markers. `description` is how Claude decides when to use the skill (recommended). Other fields: `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `paths`, `shell`, `argument-hint`, `arguments`.
- **Invocation**: Type `/skill-name` to invoke manually, or Claude loads it automatically when relevant. Plugin skills use namespace: `/plugin-name:skill-name`.
- **Content lifecycle**: When invoked, the rendered SKILL.md enters the conversation as a single message and stays for the rest of the session. Claude Code does NOT re-read the file on later turns. Auto-compaction carries skills forward; after compaction, the most recently invoked skill keeps the first 5,000 tokens.

## Quick Skill Creation

**File structure:**
```
~/.claude/skills/my-skill/
├── SKILL.md (required)
├── scripts/ (optional, for executables)
└── references/ (optional, detailed docs)
```

**Minimal SKILL.md template:**
```yaml
---
description: Use when [trigger condition]. [Concrete signals].
---

## Instructions

[Markdown body with step-by-step instructions.]
```

**Triggering:** The `description` field is the trigger. Write it to start with "Use when..." and name concrete signals (e.g., "Use when the user asks about changes, wants a commit message, or asks to review their diff"). Combined `description` + optional `when_to_use` text is capped at ~1,536 characters; put the key use case first.

## Frontmatter Fields Reference

| Field | Type | Example | Effect |
|-------|------|---------|--------|
| `name` | string | `my-skill` | Display label in listings; directory name is the command (use `/my-skill`). |
| `description` | string | `Use when reviewing code…` | **Critical for auto-triggering.** Claude uses this to decide when to load. |
| `when_to_use` | string | `Trigger phrases: code review, refactor` | Appended to description; shares 1,536-char cap with description. |
| `disable-model-invocation` | bool | `true` | Only you can invoke; Claude won't auto-load. Use for side-effects (deploy, send-message). |
| `user-invocable` | bool | `false` | Only Claude can invoke; hidden from `/` menu. Use for background knowledge. |
| `allowed-tools` | list | `Bash(git *) Read Grep` | Pre-approve tools; Claude can use without per-call approval (while skill is active). |
| `disallowed-tools` | list | `AskUserQuestion` | Remove tools from Claude's pool while skill active. Resets when you send next message. |
| `model` | string | `claude-sonnet-4-6` | Override session model for this skill. Accepts same values as `/model` or `inherit`. |
| `effort` | string | `high` `xhigh` `max` | Override effort level for this skill. Default: inherit from session. |
| `context` | string | `fork` | Run in isolated subagent. Subagent receives SKILL.md as task prompt. |
| `agent` | string | `Explore` `Plan` `general-purpose` | Which subagent to use when `context: fork`. Default: `general-purpose`. Explore/Plan skip CLAUDE.md to keep context small. |
| `paths` | list | `src/**/*.ts` `tests/**` | Glob patterns; Claude loads skill automatically only when working with matching files. |
| `shell` | string | `bash` (default) or `powershell` | Shell for `` !`command` `` and ` ```! ` blocks. |
| `argument-hint` | string | `[issue-number]` or `[from] [to]` | Hint text shown in autocomplete. |
| `arguments` | list | `[issue, branch]` | Named positional args for `$name` substitution in skill body. Maps names to positions. |

## Dynamic Context Injection

Inject live data into the prompt using `` !`command` `` (inline) or ` ```! ` (multi-line) blocks. Commands run BEFORE Claude sees the skill—output replaces the placeholder:

**Inline:**
```markdown
Current changes: !`git diff HEAD`
```

**Multi-line:**
````markdown
```!
git status --short
npm --version
```
````

Command output is plain text. Substitution runs once; output is NOT re-scanned for further placeholders.

## String Substitutions in Skill Body

| Variable | Example | Notes |
|----------|---------|-------|
| `$ARGUMENTS` | `Fix issue $ARGUMENTS` | All args passed when invoking skill. |
| `$ARGUMENTS[N]` or `$N` | `Migrate $0 from $1 to $2` | Specific argument by 0-based index. |
| `$name` | `$issue`, `$branch` | Named arg from `arguments` frontmatter. Names map to positions. |
| `${CLAUDE_SESSION_ID}` | (unique ID) | Current session ID for logging/correlation. |
| `${CLAUDE_EFFORT}` | `low`, `high`, `xhigh`, `max` | Current effort level; adapt instructions. |
| `${CLAUDE_SKILL_DIR}` | `/path/to/skill/dir` | Absolute path of the skill directory. Use in bash injection to reference bundled scripts. |

To escape a literal `$` before a digit (e.g., `$1.00`), use `\$`.

## Where Skills Live (Resolution Order)

| Scope | Path | Precedence |
|-------|------|-----------|
| Enterprise | See [managed settings](https://code.claude.com/docs/en/settings#settings-files) | Highest |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | Medium |
| Project | `.claude/skills/<skill-name>/SKILL.md` | Lowest |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Namespaced: `/plugin:skill` |

Enterprise overrides personal, personal overrides project. Plugin skills don't conflict.

## Limiting Skill Visibility

**Prevent auto-trigger without disabling the skill:**
```yaml
disable-model-invocation: true  # Only you can invoke manually (/my-skill)
```

**Hide from `/` menu (Claude only):**
```yaml
user-invocable: false  # Hidden from menu; Claude can still invoke if relevant
```

**Default behavior:** Both you and Claude can invoke any skill unless one of the above is set.

## Control with settings.json

Override individual skill visibility in `skillOverrides` (persists in settings, not in SKILL.md):
```json
{
  "skillOverrides": {
    "legacy-context": "name-only",    // Show name only, no description
    "deploy": "off"                    // Hide completely
  }
}
```

Values: `"on"` (full), `"name-only"`, `"user-invocable-only"` (hidden from menu but invocable), `"off"`.

## Creating the Skill vs. Editing It

- **Live change detection:** Skills in `~/.claude/skills/`, `.claude/skills/`, or `--add-dir` directories reload automatically mid-session when SKILL.md is edited. Creating a NEW skills directory requires restarting.
- **For plugin skills** (with hooks, agents, MCP servers), reload with `/reload-plugins`.
- **Working tree edits:** If a skill is installed via `npx skills add`, edits to the source repo do NOT auto-propagate. Re-run `npx skills add . -g -y` or symlink the working tree to `~/.claude/skills/<name>/` for live editing.

## Supporting Files & Progressive Disclosure

Keep SKILL.md under 500 lines. Move detailed reference docs to separate files:

```
my-skill/
├── SKILL.md (overview & navigation)
├── reference.md (full API docs, loaded on demand)
├── examples.md (usage examples, loaded on demand)
└── scripts/validate.sh (executable, not loaded)
```

**Reference from SKILL.md:**
```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

Claude loads supporting files only when you ask for them—they don't cost context until invoked.

## Common Patterns

**Manual-invoke only (deploy, send-message):**
```yaml
---
name: deploy
description: Deploy to production
disable-model-invocation: true
---
Deploy to $ARGUMENTS with safeguards: ...
```

**Background knowledge (Claude only, not a command):**
```yaml
---
name: legacy-system-context
description: How the old auth system works
user-invocable: false
---
The legacy system uses... [reference material]
```

**Auto-grant tools (reduce approval prompts):**
```yaml
---
name: commit
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---
Stage and commit changes...
```

**Isolated subagent task:**
```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly...
```

## Troubleshooting

| Problem | Check |
|---------|-------|
| Skill not triggering | Verify `description` includes user keywords. Test with `/skill-name` direct invocation. Reword `description` if too generic. |
| Skill triggers too often | Make `description` more specific or add `disable-model-invocation: true`. |
| Skill descriptions cut short | Run `/doctor` to check listing budget overflow. Trim description or set low-priority skills to `"name-only"` in `skillOverrides`. |
| Changes not taking effect | Ensure you're editing the file Claude Code is reading. Plugin skills need `/reload-plugins`. |

## When to Create a Skill

- You keep pasting the same instructions, checklist, or multi-step procedure into chat.
- A section of CLAUDE.md has grown into a workflow rather than a fact.
- You want Claude to recognize a specific trigger phrase and auto-load guidance.
- You need to control timing (deploy, send-message) → use `disable-model-invocation: true`.
- You bundle scripts or supporting docs alongside instructions.
