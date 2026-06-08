# Changelog

All notable changes to this project are documented here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/); versions follow SemVer.

## [1.1.0] - 2026-06-08

### Added
- **Self-updating.** An async SessionStart hook (`hooks/auto-update.sh`) keeps the
  install on the latest merged `main` (throttled `git pull --ff-only`, anonymous
  read) and flags the injected card when Claude Code is newer than the version
  the content was generated for.
- **Refresh runbook** (`skills/claude-code-capabilities/references/refresh-runbook.md`):
  the verified procedure for learning new Claude Code capabilities into the card,
  map, and skills, gated by `AUTO_MERGE_POLICY` (`verified` default / `always` / `never`).
- `references/.generated-for` version stamp (Claude Code version + date).

## [1.0.0] - 2026-06-08

Initial release.

### Added
- **SessionStart hook** (`hooks/session-start.sh`) that injects a compact
  capability self-awareness card into Claude's context on `startup`, `resume`,
  `clear`, and `compact`. The card is a decision list: task signal → capability
  → which deep-dive skill to read.
- **`claude-code-capabilities`** primary skill (the on-demand index) plus
  `references/capability-map.md` (the full signal → capability decision map) and
  `references/changelog-latest.md`.
- **11 deep-dive skills**: `claude-code-dynamic-workflows`, `-hooks`, `-skills`,
  `-subagents`, `-background-agents`, `-plugins`, `-mcp`, `-github-actions`,
  `-checkpointing`, `-agent-sdk`, `-effort-models`. They auto-surface on the
  matching task signal and can be invoked directly.
- **`scripts/update-docs.sh`** to refresh the cached official docs + changelog
  the skills summarize.
- Single-plugin marketplace (`capability-primer`) so the repo installs directly:
  `claude plugin marketplace add ucsandman/claude-code-capability-primer`.

[1.1.0]: https://github.com/ucsandman/claude-code-capability-primer/releases/tag/v1.1.0
[1.0.0]: https://github.com/ucsandman/claude-code-capability-primer/releases/tag/v1.0.0
