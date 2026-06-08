# Capability Primer — Refresh Runbook

The contract a refresh agent (the scheduled remote routine, or a local Claude
session) follows to keep this primer current with Claude Code — **safely**.
Goal: when Claude Code ships new commands/capabilities, the card, the capability
map, and the `claude-code-*` skills learn about them, with every claim verified.

## Inputs

1. Run `bash scripts/update-docs.sh` first — it fetches the latest official
   changelog + doc pages into `skills/claude-code-capabilities/references/cache/`.
2. **Authoritative source of truth = the live official docs** at
   https://code.claude.com/docs (especially `/en/commands`, `/en/hooks`,
   `/en/plugins`, `/en/mcp`, `/en/sub-agents`, `/en/model-config`). The cache is
   a pointer; VERIFY against the live pages.
3. `references/.generated-for` records the Claude Code version + date the content
   was last generated for.

## Steps

1. Read `references/.generated-for` and get the installed version (`claude --version`).
2. From the changelog + commands reference, find capabilities/commands that are
   **genuinely new or changed** since `.generated-for` and are **not already**
   covered in `references/capability-map.md`, `references/startup-card.md`, or a
   `claude-code-*` skill.
3. For each genuinely new capability:
   - Add a row to `references/capability-map.md` (signal → capability → how → which skill).
   - If it is top-tier (Claude should consider it often), add one line to `references/startup-card.md`.
   - Create or update the matching `skills/claude-code-<topic>/SKILL.md`
     (frontmatter `name`, a triggering `description`, `user-invocable: true`;
     body terse, decision-first, written for Claude-as-reader).
   - Fix any now-incorrect facts (renamed flags, changed keys) wherever they appear.
4. Regenerate `references/changelog-latest.md` as a short themed summary.
5. Update `references/.generated-for` to the current version + today's date.

## VERIFY — mandatory (this is what makes auto-merge safe)

For EVERY claim you add or change — command names, flags, settings keys, hook
event names, model IDs — confirm it against the live official docs by fetching
the relevant page. This is the same adversarial fact-check that caught
hallucinated commands and an inverted fast-mode cost during the v1.0.0 build.
- Do NOT invent commands/flags. Do NOT trust changelog phrasing over the actual docs.
- If you cannot confirm a specific claim, mark it inline `[unverified]`.

## Diff sanity — hard limits

Your changes may ONLY touch:
- `skills/claude-code-capabilities/references/{startup-card.md,capability-map.md,changelog-latest.md,.generated-for}`
- `skills/claude-code-*/SKILL.md` (add or edit)

You must NOT delete an existing skill, wholesale-replace files, or touch
`hooks/`, `scripts/`, or the manifests. Then run `claude plugin validate . --strict` — it must pass.

## AUTO_MERGE_POLICY = verified

- **`verified`** (default): open a PR, then auto-merge to `main` ONLY IF all of:
  (a) no `[unverified]` claims were added, (b) the diff respects the sanity
  limits above, (c) `claude plugin validate . --strict` passes. Otherwise LEAVE
  THE PR OPEN and report "needs human review" — do not merge.
- **`always`**: merge regardless. NOT recommended — this publishes unreviewed AI
  edits to a public repo that others install.
- **`never`**: never auto-merge; always leave the PR for a human.

Edit the value on the heading line above to change the policy; the scheduled
routine reads it.

## After merge

The user's local install tracks `main` via `hooks/auto-update.sh` (throttled
`git pull --ff-only`), so merged changes land within a session or two. New skill
files are auto-discovered by Claude Code at session start (or `/reload-skills`).
