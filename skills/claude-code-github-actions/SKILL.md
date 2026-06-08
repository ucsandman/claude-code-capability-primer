---
name: claude-code-github-actions
description: "Use when setting up or debugging Claude Code GitHub Actions automation, or deciding whether to route CI/CD tasks to GitHub Actions vs local session."
user-invocable: true
---

# Claude Code GitHub Actions

## What It Is

**Claude Code GitHub Actions** (`anthropics/claude-code-action@v1`) runs Claude inside GitHub Actions. Triggered by `@claude` mentions in PR/issue comments or automatically on repository events. Responds with code changes, reviews, implementations. Executes server-side on GitHub runners (not locally).

Distinct from: GitHub MCP server (raw API access); local Claude Code CLI (interactive terminal); GitHub Code Review (automatic PR reviews without triggers).

## Setup

**Quick install:** Run `/install-github-app` in Claude Code terminal. Guides you through:
- Installing the official Anthropic GitHub App at `https://github.com/apps/claude`
- Adding `ANTHROPIC_API_KEY` to repository secrets
- Creating `.github/workflows/claude.yml`

**Requirements:** Repository admin access. GitHub App requests read & write permissions for Contents, Issues, and Pull Requests.

**Manual setup** (if quickstart fails or for cloud providers):
1. Install app at `https://github.com/apps/claude`
2. Add `ANTHROPIC_API_KEY` secret to repository
3. Copy workflow YAML from `https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml` into `.github/workflows/`

## Workflow Structure

Tag-based (responds to mentions):
```yaml
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          # Omit prompt → Claude waits for @claude mention
```

Automation (runs on event):
```yaml
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "/code-review:code-review"
          # Has prompt → Claude runs immediately
```

## Key Parameters

| Param | Required | Purpose |
|-------|----------|---------|
| `prompt` | No* | Instruction or skill invocation (e.g., `"/code-review:code-review"` or plain text). Omit for tag-based mode. |
| `claude_args` | No | CLI flags as single string (e.g., `"--max-turns 5 --model claude-opus-4-8"`) |
| `anthropic_api_key` | Yes** | Claude API key from secrets |
| `plugin_marketplaces` | No | Newline-separated plugin Git URLs |
| `plugins` | No | Newline-separated plugin names to install |
| `github_token` | No | Custom GitHub token (auto-generated if using GitHub App) |
| `trigger_phrase` | No | Custom @mention trigger (default: `@claude`) |
| `use_bedrock` | No | Route to Amazon Bedrock instead of Claude API |
| `use_vertex` | No | Route to Google Vertex AI instead of Claude API |

*Prompt optional — omit for tag-based mode (responds to `@claude` mentions).*
**Required for Claude API; not needed for Bedrock/Vertex (use cloud auth instead).*

## When to Use It

**✅ Route to GitHub Actions for:**
- Recurring PR reviews on every push/PR
- Auto-implement issues as PRs
- On-demand fixes via `@claude` comments
- Team workflows (you don't own local session)
- Scheduled automation (cron, event-triggered)

**❌ Use local Claude Code instead for:**
- Interactive, exploratory work (tight feedback loops)
- Real-time debugging
- Tasks needing manual approval mid-stream

## Trigger Modes

**Tag-based (default):** Omit `prompt`. Claude responds only to `@claude` mentions.
**Automation:** Add `prompt`. Claude runs immediately on event without waiting for mention.
**Skills:** Use `/skill-name` or `/plugin-name:skill-name` in prompt. For repo skills, include `actions/checkout@v4` before the action step.

## Common Examples

**PR review on every change:**
```yaml
on:
  pull_request:
    types: [opened, synchronize]
prompt: "/code-review:code-review"
```

**Issue → PR implementation:**
```yaml
on:
  issues:
    types: [opened]
prompt: "Implement this feature. Create a PR with all changes."
```

**Scheduled report:**
```yaml
on:
  schedule:
    - cron: "0 9 * * *"
prompt: "Summarize yesterday's commits and open issues"
```

**In-comment triggers (tag-based):**
```
@claude implement this feature
@claude review for security
@claude fix the TypeError
```

## Project Guidance

Claude respects `CLAUDE.md` at repo root (coding style, review criteria, project rules). Place it there; action reads automatically.

## Upgrading from Beta

Breaking changes in v1.0:

| Old (Beta) | New (v1.0) |
|---|---|
| `@beta` | `@v1` |
| `mode: "tag"` / `"agent"` | *(removed — auto-detected)* |
| `direct_prompt` | `prompt` |
| `max_turns: "10"` | `claude_args: "--max-turns 10"` |
| `model: "claude-sonnet-4-6"` | `claude_args: "--model claude-sonnet-4-6"` |
| `custom_instructions` | `claude_args: "--append-system-prompt ..."` |

## Amazon Bedrock & Google Vertex AI

For enterprise environments, route through your own cloud infrastructure (data residency, billing control).

**Setup requires:**
1. Create custom GitHub App (or use Anthropic's official app)
2. Configure cloud provider authentication (OIDC for security — no static keys)
3. Add secrets to repository
4. Create workflow with cloud auth steps + `use_bedrock: "true"` or `use_vertex: "true"`

**Bedrock:** Request Claude model access in Bedrock; configure GitHub OIDC → AWS IAM role with `AmazonBedrockFullAccess`; set `AWS_ROLE_TO_ASSUME` secret; use region-prefixed model IDs (e.g., `us.anthropic.claude-sonnet-4-6`).

**Vertex AI:** Enable Vertex AI + IAM APIs; configure Workload Identity Federation for GitHub; create service account with `Vertex AI User` role; set `GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT` secrets; action auto-retrieves project ID from auth.

See official GitHub Action repo for complete cloud setup guides.

## Costs & Limits

**GitHub Actions minutes:** Each run consumes org quota. See [GitHub billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions).

**API tokens:** Each Claude interaction charges tokens (varies by complexity/codebase size). Set `--max-turns` cap to control iterations.

**Optimize:**
- Use specific `@claude` commands to reduce unnecessary runs
- Set `claude_args: "--max-turns 5"` to cap iterations
- Use workflow `concurrency` limits to prevent parallel runs
- Schedule at off-peak times

## Troubleshooting

| Issue | Check |
|-------|-------|
| Claude not responding to `@claude` | Workflow triggers include `issue_comment` or `pull_request_review_comment`; comment has `@claude` (not `/claude`); app is installed |
| CI doesn't run | API key valid in secrets; workflows enabled; GitHub App has Contents/Issues/Pull Requests permissions |
| Bedrock/Vertex auth fails | OIDC role/provider configured; secret names correct; env vars set (e.g., `ANTHROPIC_VERTEX_PROJECT_ID` for Vertex) |
| Slow/expensive runs | Increase `--max-turns` cap; use narrower prompts; check codebase size |

## Model IDs

Defaults to Sonnet. Override with `claude_args: "--model <id>"`:
- Claude Opus 4.8: `claude-opus-4-8`
- Claude Sonnet 4.6: `claude-sonnet-4-6`
- Claude Haiku 4.5: `claude-haiku-4-5-20251001`
- Bedrock (region-prefixed): `us.anthropic.claude-opus-4-8`

## Next Steps

1. Run `/install-github-app` in Claude Code
2. Test with `@claude help` in a PR comment
3. Add `CLAUDE.md` to repo root to guide Claude's decisions
4. See `https://github.com/anthropics/claude-code-action/tree/main/examples` for complete workflows
