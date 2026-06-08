# claude-code-capability-primer

A self-awareness layer for **Claude Code**. It makes sure that, at the start of every session, Claude is reminded of the built-in capabilities it can reach for — and gives it on-demand deep-dive skills for each one — without bloating every session with full documentation.

```bash
claude plugin marketplace add ucsandman/claude-code-capability-primer
claude plugin install claude-code-capability-primer@capability-primer
```

<!-- DEMO: add a short GIF at docs/demo.gif and uncomment the line below.
     A fresh session showing the card inject + Claude reaching for a workflow
     or subagent it would otherwise have skipped sells this better than any prose. -->
<!-- ![capability-primer demo](docs/demo.gif) -->

## Why

Claude Code can do far more than single-agent inline edits: skills, subagents, dynamic workflows, hooks, background tasks, checkpointing, MCP, plugins, GitHub Actions, the Agent SDK, and effort/model controls. The failure mode is *forgetting they exist* and single-threading work that should fan out, or declaring something "not possible" before checking. This plugin closes that gap.

## How it works

1. **SessionStart hook** (`hooks/session-start.sh`) injects a tiny **capability card** (`skills/claude-code-capabilities/references/startup-card.md`) into Claude's context on `startup`, `resume`, `clear`, and `compact`. The card is a decision list: *task signal → capability → which skill to read*. It is intentionally small.
2. **Primary skill** `claude-code-capabilities` loads the full opinionated **capability map** (`references/capability-map.md`) on demand — every signal mapped to a capability, plus the anti-patterns this primer exists to prevent.
3. **Eleven deep-dive skills** (`claude-code-dynamic-workflows`, `-hooks`, `-skills`, `-subagents`, `-background-agents`, `-plugins`, `-mcp`, `-github-actions`, `-checkpointing`, `-agent-sdk`, `-effort-models`) carry the exact mechanics. They auto-surface when Claude is doing that kind of work and can be invoked directly.

The heavy docs stay out of context until a skill is invoked — only the ~20-line card and the skill descriptions are ever loaded automatically.

## Structure

```
claude-code-capability-primer/
├── .claude-plugin/
│   ├── plugin.json              # plugin manifest
│   └── marketplace.json         # single-plugin local marketplace ("capability-primer")
├── hooks/
│   ├── hooks.json               # SessionStart: startup|resume|clear|compact
│   └── session-start.sh         # emits the card as hookSpecificOutput.additionalContext
├── skills/
│   ├── claude-code-capabilities/
│   │   ├── SKILL.md             # the index / entry point
│   │   └── references/
│   │       ├── startup-card.md  # the tiny card injected every session (source of truth)
│   │       ├── capability-map.md# the full signal → capability map
│   │       └── changelog-latest.md
│   └── claude-code-<topic>/SKILL.md   # 11 deep-dive skills
└── scripts/
    └── update-docs.sh           # refreshes the official changelog + doc cache
```

## Install

Install straight from this repo as a Claude Code marketplace:

```bash
claude plugin marketplace add ucsandman/claude-code-capability-primer
claude plugin install claude-code-capability-primer@capability-primer
```

Then **restart Claude Code** — SessionStart hooks and skills register at launch, so the card and skills activate on the next session. Verify with `claude plugin list` and `claude plugin details claude-code-capability-primer@capability-primer`.

> Prefer the in-app flow? Run `/plugin`, add the marketplace `ucsandman/claude-code-capability-primer`, then install the plugin from it.

## Update

```bash
claude plugin update claude-code-capability-primer@capability-primer
```

To refresh the cached official docs/changelog that the skills summarize, run the bundled script from your install or clone:

```bash
bash scripts/update-docs.sh
```

Re-summarizing the prose deep-dives from the refreshed cache is a model task — ask a Claude session to update the affected `claude-code-*` skills from `references/cache/`.

## Staying current (auto-update)

The primer keeps itself fresh so you don't have to:

1. **Local auto-pull** — an async SessionStart hook (`hooks/auto-update.sh`) runs a throttled `git pull --ff-only` so your install tracks merged `main`, and adds a one-line staleness note to the card when your Claude Code is newer than the version the content was generated for.
2. **Refresh runbook** (`skills/claude-code-capabilities/references/refresh-runbook.md`) — the verified procedure for turning new Claude Code docs/changelog into an updated card, map, and `claude-code-*` skills.
3. **Scheduled refresh** — a monthly remote routine runs the runbook, **fact-checks every change against the live docs**, opens a PR, and auto-merges only when verification + `claude plugin validate . --strict` pass (`AUTO_MERGE_POLICY = verified`). Set the policy to `always` for blind merge, or `never` to always review.

The scheduled routine needs your GitHub connected to claude.ai (run `/web-setup` once). The default never publishes unverified content — stale-but-correct beats fresh-but-wrong.

## Develop locally

```bash
git clone https://github.com/ucsandman/claude-code-capability-primer
claude plugin validate ./claude-code-capability-primer --strict
claude plugin marketplace add ./claude-code-capability-primer
claude plugin install claude-code-capability-primer@capability-primer
```

Edit `skills/claude-code-capabilities/references/startup-card.md` to change what gets injected every session, or any `claude-code-*` skill, then restart Claude Code.

## Uninstall

```bash
claude plugin uninstall claude-code-capability-primer@capability-primer
claude plugin marketplace remove capability-primer
```

## Notes

- Editing `startup-card.md` changes what is injected every session — it is the single source of truth for the card.
- The plugin lives outside `~/.claude/plugins/marketplaces/` (which Claude Code auto-manages from git), so it will not be clobbered by plugin auto-updates.
