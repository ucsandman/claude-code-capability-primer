#!/usr/bin/env bash
# SessionStart hook for the claude-code-capability-primer plugin.
# Injects the capability self-awareness card into Claude's context so that,
# at the start of every session (startup / resume / clear / compact), Claude
# is reminded of the built-in Claude Code capabilities it can reach for.
#
# Contract: emit ONE JSON object on stdout, exit 0. Claude Code reads
# hookSpecificOutput.additionalContext and prepends it to the model context.

set -euo pipefail

# Resolve the plugin root. Claude Code sets CLAUDE_PLUGIN_ROOT; fall back to
# deriving it from this script's location (hooks/ -> plugin root).
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CARD="${PLUGIN_ROOT}/skills/claude-code-capabilities/references/startup-card.md"

card_content=$(cat "$CARD" 2>/dev/null || printf '%s' "[capability-primer] startup card missing at ${CARD}. Run /claude-code-capabilities for the capability map.")

# Escape a string for embedding as a JSON string value. Each ${s//old/new} is
# a single pass (orders of magnitude faster than a char loop). Backslash first.
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Append a staleness note if the async updater (auto-update.sh) flagged that the
# installed Claude Code is newer than the version this primer was generated for.
STALE_FLAG="${PLUGIN_ROOT}/skills/claude-code-capabilities/references/cache/.staleness"
if [ -f "$STALE_FLAG" ]; then
  card_content="${card_content}

$(cat "$STALE_FLAG" 2>/dev/null)"
fi

# Escape the card FIRST, then assemble the JSON string value using literal \n
# for the wrapper newlines (already valid JSON escapes). Do not re-escape.
card_escaped=$(escape_for_json "$card_content")
session_context="<claude-code-capabilities>\\n${card_escaped}\\n</claude-code-capabilities>"

# Claude Code: nested hookSpecificOutput.additionalContext.
# Other harnesses (Copilot CLI / SDK standard): top-level additionalContext.
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -z "${COPILOT_CLI:-}" ]; then
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$session_context"
else
  printf '{\n  "additionalContext": "%s"\n}\n' "$session_context"
fi

exit 0
