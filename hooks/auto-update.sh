#!/usr/bin/env bash
# Async SessionStart helper for claude-code-capability-primer.
# Two best-effort jobs, neither of which may ever block or fail a session:
#   1. Throttled `git pull --ff-only` so the install tracks merged `main`
#      (the public repo is read-anonymous, so no credentials are needed).
#   2. Write a one-line staleness flag if the installed Claude Code is newer
#      than the version this primer's content was generated for. The sync
#      card hook (session-start.sh) appends that flag to the injected card.
#
# Runs with "async": true in hooks.json, so it never delays the prompt.

set -u  # NOT -e: this script must never fail the session.

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
REF="${ROOT}/skills/claude-code-capabilities/references"
CACHE="${REF}/cache"
STAMP="${REF}/.generated-for"
mkdir -p "$CACHE" 2>/dev/null || true

# --- 1. Throttled auto-pull (once per ~20h) --------------------------------
PULL_MARK="${CACHE}/.last-pull"
now=$(date +%s 2>/dev/null || echo 0)
last=0
[ -f "$PULL_MARK" ] && last=$(cat "$PULL_MARK" 2>/dev/null || echo 0)
case "$last" in (*[!0-9]*|"") last=0;; esac
if [ $(( now - last )) -gt 72000 ]; then
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    timeout 20 git -C "$ROOT" pull --ff-only --quiet >/dev/null 2>&1 || true
  fi
  echo "$now" > "$PULL_MARK" 2>/dev/null || true
fi

# --- 2. Staleness flag ------------------------------------------------------
FLAG="${CACHE}/.staleness"
rm -f "$FLAG" 2>/dev/null || true
gen=""
[ -f "$STAMP" ] && gen=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$STAMP" 2>/dev/null | head -1)
cur=$(timeout 5 claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -n "$gen" ] && [ -n "$cur" ] && [ "$gen" != "$cur" ]; then
  newer=$(printf '%s\n%s\n' "$gen" "$cur" | sort -V | tail -1)
  if [ "$newer" = "$cur" ]; then
    printf '> NOTE: this capability primer was generated for Claude Code v%s; you are on v%s. Newer commands/capabilities may not be reflected yet — the auto-refresh will update it (see skills/claude-code-capabilities/references/refresh-runbook.md).' "$gen" "$cur" > "$FLAG" 2>/dev/null || true
  fi
fi

exit 0
