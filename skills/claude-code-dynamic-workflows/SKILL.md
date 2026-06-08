---
name: claude-code-dynamic-workflows
description: Use when a task is too big for one context — broad audits, multi-file migrations, multi-source research, or parallel multi-dimension review — and you want to fan out and orchestrate many subagents deterministically with the Workflow tool (requires ultracode / explicit opt-in).
user-invocable: true
---

# Claude Code Dynamic Workflows

The **Workflow tool** runs a deterministic JavaScript orchestration script that fans out subagents. You write the control flow (loops, conditionals, fan-out); the script spawns agents, collects structured results, and returns a synthesis. It runs in the background and notifies you on completion.

Reach for this when the structure of the work — not just its size — needs to be encoded: cover a wide surface in parallel, get independent perspectives before committing, or take on a job one context can't hold.

## When to use (signals)

- A migration, rename, or codemod across **many files** → discover sites, then pipeline a transform+verify over each.
- A **broad audit / review** across dimensions (bugs, security, perf, tests) → fan out finders, then adversarially verify each finding.
- **Multi-source research** → parallel searches by different angle → deep-read → synthesize with citations.
- **Understand a large subsystem** → parallel readers over modules → one structured map.
- Anything where you'd otherwise serially grind through 10+ near-identical subtasks.

If it fits in one focused pass, don't reach for a workflow — use a single subagent or just do it.

## Opt-in gate (important)

The Workflow tool only fires when the user has **explicitly opted into multi-agent orchestration**: the `ultracode` effort/keyword is on, the user asked for a workflow / fan-out in their own words, or a skill's instructions tell you to call it. It can spawn dozens of agents and spend a lot of tokens, so do not invoke it for tasks the user didn't scope to that scale. When unsure, describe the workflow and rough cost and ask first.

## Anatomy of a script

Every script starts with a pure-literal `meta` block, then a body using the hooks:

```js
export const meta = {
  name: 'review-changes',
  description: 'Review changed files across dimensions, verify each finding',
  phases: [{ title: 'Review' }, { title: 'Verify' }],
}

const DIMENSIONS = [{ key: 'bugs', prompt: '...' }, { key: 'perf', prompt: '...' }]

const results = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS }),
  review => parallel(review.findings.map(f => () =>
    agent(`Adversarially verify: ${f.title}`, { phase: 'Verify', schema: VERDICT })
      .then(v => ({ ...f, verdict: v })))),
)
return { confirmed: results.flat().filter(Boolean).filter(f => f.verdict?.isReal) }
```

### Hooks

- `agent(prompt, opts?)` — spawn one subagent. With `schema` (JSON Schema) it returns a validated object (the agent is forced to emit structured output); without, it returns its final text. Opts: `label`, `phase`, `schema`, `model`, `isolation: 'worktree'`, `agentType` (e.g. `'Explore'`, `'claude-code-guide'`, a custom agent). Returns `null` if the agent dies/skips — `.filter(Boolean)`.
- `pipeline(items, stage1, stage2, ...)` — **the default.** Each item flows through all stages independently, NO barrier between stages (item A can be in stage 3 while B is still in stage 1). Wall-clock = slowest single chain. Each stage gets `(prevResult, originalItem, index)`.
- `parallel(thunks)` — run thunks concurrently and **await all** (a barrier). Use only when stage N genuinely needs ALL of stage N-1 (dedup/merge across the full set, early-exit on zero, cross-item comparison). A thunk that throws resolves to `null`.
- `phase(title)` / `log(msg)` — progress grouping + a narrator line for the user.
- `workflow(name|{scriptPath}, args)` — run another workflow inline (nesting is one level only).
- `budget` — `{ total, spent(), remaining() }`: the turn's token target (or `total: null`). Gate dynamic loops on `budget.total && budget.remaining() > N`.
- `args` — the value you passed as the tool's `args` (pass real JSON, not a stringified blob).

## Pick pipeline, not a barrier

Default to `pipeline()`. A `parallel()` barrier between stages is justified ONLY when stage N needs cross-item context from all of N-1. "I need to flatten/map/filter first" is NOT a reason — do that inside a stage: `pipeline(items, stageA, r => transform([r]).flat(), stageB)`. A barrier where the slowest item is 3x the fastest wastes the fast items' idle time.

## Quality patterns (compose freely)

- **Adversarial verify** — spawn N independent skeptics per finding, each prompted to refute; kill the finding if a majority refute. Stops plausible-but-wrong results.
- **Perspective-diverse verify** — give each verifier a distinct lens (correctness / security / repro) instead of N identical ones.
- **Loop-until-dry** — for unknown-size discovery, keep spawning finders until K consecutive rounds surface nothing new (dedup against everything *seen*, not just confirmed).
- **Judge panel** — generate N independent attempts from different angles, score with parallel judges, synthesize from the winner.
- **Completeness critic** — a final agent that asks "what's missing — a modality not run, a claim unverified?"
- **No silent caps** — if you bound coverage (top-N, no retry, sampling), `log()` what was dropped.

## Mechanics & limits

- Concurrency cap is `min(16, cores - 2)` per workflow; excess queues. Lifetime cap 1000 agents; ≤4096 items per `parallel`/`pipeline` call.
- Scripts are plain JS (no TypeScript types). `Date.now()` / `Math.random()` / argless `new Date()` are unavailable (they break resume) — pass timestamps via `args`, vary by index for randomness.
- Subagents return raw data, not human-facing prose. Use `schema` for anything structured.
- **Iterate** by editing the persisted script file and re-invoking with `{scriptPath}`. **Resume** a paused/edited run with `{scriptPath, resumeFromRunId}` — unchanged `agent()` calls return cached results instantly.
- Right-size: omit `model` to inherit the session model (usually correct); only override when a different tier clearly fits.

## Don't

- Don't fan out for work that fits one focused pass.
- Don't use a barrier where a pipeline works (latency tax).
- Don't run it without the opt-in gate above.
- Don't poll a background workflow — you're notified when it completes.

For the orchestration *primitive* (one subagent at a time, model-driven control flow), see `claude-code-subagents`. For long-running async single tasks, see `claude-code-background-agents`.
