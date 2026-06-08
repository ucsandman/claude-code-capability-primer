---
name: claude-code-checkpointing
description: "Use when you need to undo code edits, explore alternatives without losing a starting point, recover from a bad edit path, or restore previous conversation state — press Esc Esc or run /rewind to open checkpoints menu."
user-invocable: true
---

# Claude Code Checkpointing and Rewind

## What It Does

Checkpointing automatically snapshots your code state before each Claude edit. You can rewind to any prior checkpoint to restore code and/or conversation history, or compress part of the conversation to free context without changing files.

## How It Works

- Every user prompt creates a new checkpoint automatically
- Checkpoints track **only direct file edits made by Claude** (via Edit/Write/MultiEdit tools)
- Checkpoints **do NOT track** bash commands (`rm`, `mv`, `cp`, etc.) or manual edits outside Claude Code
- Checkpoints persist across sessions (stored 30 days by default; configurable)
- External side effects (DB changes, git pushes, emails) are never undone by rewind

## Invoke Rewind

**Command:** `/rewind` or press `Esc` twice when the prompt input is empty

Opens a menu listing every prompt in the session. Select one, then choose an action:

| Action | Effect |
|--------|--------|
| **Restore code and conversation** | Revert both file edits and chat history to that point |
| **Restore conversation** | Keep current code, rewind chat to that point |
| **Restore code** | Keep chat, revert file edits to that point |
| **Summarize from here** | Compress this message onward into a summary; keep earlier messages intact |
| **Summarize up to here** | Compress everything before this message into a summary; stay at end of chat |
| **Never mind** | Return to menu without changing anything |

After restore, the original prompt from that checkpoint is placed in your input field for re-sending or editing.

## Restore vs. Summarize

**Restore** = undo. Reverts file state (or conversation, or both) on disk.

**Summarize** = compress. Replaces old messages with an AI-generated summary. Original detail is preserved in the transcript so Claude can reference it, but the context window is freed. Optionally guide the summary with your own instructions. (Similar to `/compact`, but targeted to one side of a checkpoint.)

## When to Use

- **Explore alternatives**: try a different implementation, then rewind if it doesn't work
- **Recover from mistakes**: undo a broken edit path without manually reverting files
- **Iterate safely**: experiment knowing you can snap back to a working state
- **Free context**: compress verbose early discussion while keeping recent work in full detail

## Limitations

**Bash changes are not tracked.** If Claude (or you) runs:
```bash
rm file.txt
mv old.txt new.txt
cp source.txt dest.txt
```
Rewind cannot undo these — only Claude's direct file edits are captured.

**Manual and concurrent edits not tracked.** Changes made outside Claude Code (in an editor or other session) are not captured unless they happen to touch the same files Claude edited.

**Not a replacement for git.** Checkpoints are session-local undo. For permanent history, collaboration, and long-term safety:
- Use **git** for commits, branches, permanent history
- Use **checkpoints** for quick session-level recovery ("local undo")

## How It Integrates With Git

- Checkpoints operate at the session level; they don't interact with git directly
- Global git hooks (ruff/vulture on Python) run on commits and code review, independent of checkpointing
- Rewind restores files to their in-memory state, but doesn't stage or commit; use `/commit` to save after restoring
- For multi-session safety, commit working code to git before stepping away; checkpoints expire after 30 days

## Safe Mental Model

- Use `/rewind` to recover from a bad edit path within the current session
- Use `/fork-session` (or `--fork-session` flag) to try a direction while preserving the original session
- Use git `reset` or `revert` for permanent history recovery
- Use `/compact` to summarize the entire conversation; use `/rewind summarize` to compress a specific section
