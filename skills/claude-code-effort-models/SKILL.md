---
name: claude-code-effort-models
description: "Use when deciding how to work on a task - choosing effort level, model, or fast mode to balance reasoning depth, speed, and token cost."
user-invocable: true
---

# Claude Code Effort, Models, and Fast Mode

Quick reference for tuning how Claude Code works: model selection, effort levels, and speed mode. Read this mid-session when deciding how to approach a task.

---

## Models via /model

Switch with `/model` (opens picker) or `/model <name>` to set directly. Persists to next session.

**Available models:**
- `opus` → Claude Opus 4.8 (latest, strongest reasoning)
- `sonnet` → Claude Sonnet 4.6 (daily coding, balanced)
- `haiku` → Claude Haiku 4.5 (fast, simple tasks)
- `best` → currently opus
- `opusplan` → opus during planning, auto-switches to sonnet for execution
- `opus[1m]` / `sonnet[1m]` → same model with 1M token context window (long sessions only)

**Model IDs (full names):**
- `claude-opus-4-8`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001`

**When to pick:**
- **Opus**: hard reasoning, architecture decisions, complex refactors, code review, debugging. Default for Max/Team/Enterprise/API; higher token cost.
- **Sonnet**: most coding work, features, edits, tests. Good speed/capability tradeoff.
- **Haiku**: searches, simple formatting, routine tasks. Cheapest.
- **opusplan**: complex feature design where planning matters but execution is straightforward.

---

## Effort Levels via /effort

Controls adaptive reasoning depth per message. Raise it for complex problems; lower it for routine tasks. Persistent across sessions unless overridden by env var.

**Available levels (varies by model):**
- `low` — minimal thinking, fastest, cheapest. Use: latency-sensitive, low-complexity tasks.
- `medium` — lighter reasoning, cost-conscious work that trades some intelligence.
- `high` — default on Opus 4.8, Opus 4.6, Sonnet 4.6. Balances tokens and capability.
- `xhigh` — deeper reasoning, higher token spend. Default on Opus 4.7. Use: tricky architecture, intricate bugs.
- `max` — deepest reasoning, unbounded tokens, session-only. Can overthink; test first.

**Special:** `/effort ultracode` (Opus only, session-only) sends `xhigh` to model AND orchestrates dynamic workflows for substantive tasks. Reserved for ambitious multi-phase work.

**Usage:**
- `/effort` — open slider picker
- `/effort high` — set directly
- `/effort auto` — reset to model default
- Env: `CLAUDE_CODE_EFFORT_LEVEL=xhigh`
- Skill frontmatter: `effort: xhigh`

**Token tradeoff:** low < medium < high < xhigh < max. Each step costs more tokens but enables deeper reasoning for complex tasks.

---

## Fast Mode via /fast

Opus only. Same model quality, ~2.5x faster output, higher cost per token. Toggle with `/fast` or `"fastMode": true` in settings.json.

**Pricing (per MTok):**
- Opus 4.8 fast: $10 input / $50 output (vs $5/$25 standard)
- Opus 4.7 fast: $30 input / $150 output (vs $5/$25 standard)
- Opus 4.6 fast: $30 input / $150 output (deprecated; migrate to 4.8 or 4.7)

**How it works:**
- NOT a different model. Same Opus, different API config prioritizing latency.
- Auto-switches you to Opus if on Sonnet/Haiku.
- Persists to next session by default (admins can set per-session reset).
- ↯ icon shows it's active.
- Shares rate limit pool across Opus 4.8/4.7/4.6; auto-falls back to standard speed if rate-limited.

**When to use:**
- Rapid iteration, live debugging, tight deadlines. Cost matters less than speed.
- NOT good for long autonomous tasks, batch work, CI/CD.

**Cost gotcha:** enabling fast mode mid-conversation re-caches full history at fast-mode price. Enable at session start for best cost.

**Requirements:**
- Anthropic API or Claude subscription (Pro/Max/Team/Enterprise) with usage credits enabled.
- NOT available on Bedrock, Vertex, Foundry, or AWS Platform.
- Team/Enterprise admins must explicitly enable it; disabled by default org-wide.

---

## Token and Cache Angle

**Model choice drives cost:**
- Haiku ~5x cheaper input than Sonnet, ~15x cheaper than Opus. Suitable for searches/format work.
- Sonnet ~1/3 Opus input cost. Suitable for most coding.
- Opus 3–10x more per token than Sonnet; justifiable for hard reasoning.

**Effort and fast mode interact:**
- Higher effort = more tokens on same model.
- Fast mode = same tokens, higher per-token price, faster latency.
- Combine lower effort + fast mode for max speed on straightforward tasks.
- Don't raise both for cost-sensitive work.

**Prompt caching:** a stable warm prefix re-reads at ~10% of input price. Keep the prefix stable (don't rewrite early messages mid-session). Switching `/model` mid-session invalidates the cache for the next turn.

---

## Quick Decision Tree

**Task is routine (format, search, simple edit)?** → `haiku`, `low` effort, standard mode.

**Task is typical coding (features, tests, refactors)?** → `sonnet`, `high` effort (or `medium` to cut cost), standard mode.

**Task is hard (architecture, complex bug, design)?** → `opus`, `xhigh` effort, standard mode.

**You need output in seconds, not minutes?** → Use fast mode on Opus (higher cost, lower latency). Not a model change.

**You need the deepest reasoning on an ambitious task?** → `opus`, `max` effort, standard mode. Session-only, unbounded tokens.

---

## Environment Variables

- `ANTHROPIC_MODEL=<name>` — set model for this session only.
- `CLAUDE_CODE_EFFORT_LEVEL=<level>` — effort level; overrides session choice.
- `CLAUDE_CODE_DISABLE_FAST_MODE=1` — disable fast mode entirely.
- `ANTHROPIC_DEFAULT_OPUS_MODEL` / `ANTHROPIC_DEFAULT_SONNET_MODEL` / `ANTHROPIC_DEFAULT_HAIKU_MODEL` — pin specific model versions (useful on Bedrock, Vertex, Foundry).

---

## See Also

- Model config docs: https://code.claude.com/docs/en/model-config.md
- Fast mode docs: https://code.claude.com/docs/en/fast-mode
- Commands reference: https://code.claude.com/docs/en/commands.md
