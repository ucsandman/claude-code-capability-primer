#!/usr/bin/env bash
# update-docs.sh — refresh the source material the capability-primer skills
# summarize. Two honest jobs:
#   1. Deterministically regenerate references/changelog-latest.md from the
#      official Claude Code CHANGELOG (pure fetch + trim — no model needed).
#   2. Best-effort cache the official doc pages into references/cache/ so a
#      later model pass (or the capability-primer content workflow) can
#      re-summarize the deep-dive skills from fresh sources.
#
# Prose summaries of the claude-code-* deep-dive skills are NOT regenerated
# here — summarization is a model task. This script only refreshes inputs.
#
# Usage:  bash scripts/update-docs.sh [--help]
# Windows: run via Git Bash (bash scripts/update-docs.sh).

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  sed -n '2,18p' "$0"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REF_DIR="${PLUGIN_ROOT}/skills/claude-code-capabilities/references"
CACHE_DIR="${REF_DIR}/cache"
mkdir -p "$CACHE_DIR"

CHANGELOG_URL="https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
NOW="$(date -u '+%Y-%m-%d %H:%M UTC')"

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found. Install curl (Git for Windows ships it) and retry." >&2
  exit 1
fi

# --- 1. Regenerate changelog-latest.md (deterministic) ----------------------
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if curl -fsSL "$CHANGELOG_URL" -o "$tmp"; then
  cp "$tmp" "${CACHE_DIR}/CHANGELOG.raw.md"
  echo "OK  refreshed ${CACHE_DIR}/CHANGELOG.raw.md"
  # Never clobber a curated summary. Bootstrap changelog-latest.md only if it
  # is missing; otherwise leave it for a model re-summarization pass.
  if [ ! -f "${REF_DIR}/changelog-latest.md" ]; then
    {
      echo "# Claude Code — Recent Changes"
      echo
      echo "> Bootstrapped by update-docs.sh on ${NOW} (raw trim — re-summarize for themed prose)."
      echo "> Source: ${CHANGELOG_URL}"
      echo
      # Most recent ~160 lines of the changelog (newest entries are at the top).
      head -n 160 "$tmp"
    } > "${REF_DIR}/changelog-latest.md"
    echo "OK  bootstrapped ${REF_DIR}/changelog-latest.md (was missing)"
  else
    echo "KEEP ${REF_DIR}/changelog-latest.md exists (curated) — re-summarize from cache to refresh."
  fi
else
  echo "WARN could not fetch changelog from ${CHANGELOG_URL}; left existing files unchanged." >&2
fi

# --- 2. Best-effort cache of official doc pages -----------------------------
DOC_BASE="https://docs.claude.com/en/docs/claude-code"
DOC_PAGES="overview skills slash-commands sub-agents hooks hooks-guide plugins plugins-reference plugin-marketplaces mcp settings checkpointing github-actions sdk model-config interactive-mode"

fetched=0
for page in $DOC_PAGES; do
  # Try the markdown variant first (docs.claude.com serves .md), then html.
  if curl -fsSL "${DOC_BASE}/${page}.md" -o "${CACHE_DIR}/${page}.md" 2>/dev/null; then
    fetched=$((fetched + 1))
  elif curl -fsSL "${DOC_BASE}/${page}" -o "${CACHE_DIR}/${page}.html" 2>/dev/null; then
    fetched=$((fetched + 1))
  fi
done
echo "OK  cached ${fetched} doc page(s) into ${CACHE_DIR}"

echo
echo "Done. To re-summarize the deep-dive skills from the refreshed cache,"
echo "re-run the capability-primer content workflow or ask a Claude session to"
echo "update the affected claude-code-* skills using files in:"
echo "  ${CACHE_DIR}"
