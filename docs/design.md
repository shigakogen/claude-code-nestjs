# Design notes

Why each layer exists, what it costs, and when to reach for it. Read this before adding anything to the kit.

🇻🇳 [Tiếng Việt](design.vi.md)

## The constraint

`CLAUDE.md` is loaded on **every turn**. So is every MCP server's tool schema. Everything else in this kit is designed to load on demand.

That gives a cost hierarchy. When you want the agent to behave differently, reach for the cheapest layer that actually works:

| Layer | Ambient cost | Reliability | Reach for it when |
|---|---|---|---|
| Hook | zero | deterministic | the rule is mechanical and violations are unacceptable |
| Path-scoped rule | zero unless the glob matches | strong | the rule only applies to certain directories |
| Skill | metadata only until triggered | strong | a repeatable workflow with ordered steps |
| Subagent | zero until invoked | strong | a task needing its own context or tool restrictions |
| `CLAUDE.md` line | **every turn, forever** | moderate | genuinely global and unavoidable |

Most teams do this backwards: everything goes into `CLAUDE.md`, nothing is enforced, and the file grows until it stops being read carefully.

## Layer 1 — the memory file

Under 60 lines here; the hard ceiling in CI is 200.

Three tests for a candidate line:

1. **Does it change behaviour?** "Write clean code" does not. "Transaction boundary only in `service/`" does.
2. **Is it checkable?** You should be able to look at a diff and say whether it was followed.
3. **Is it global?** If it only matters in one directory, it belongs in `rules/`.

Write imperatives, not suggestions. "Never return TypeORM entities from controllers" — not "prefer returning DTOs where appropriate". Hedged language gives the model room to negotiate with itself.

## Layer 2 — path-scoped rules

Frontmatter declares the globs; the file loads only when the agent touches a matching path. Editing a controller does not pay for migration conventions.

Two consequences worth planning around:

- **Split by directory, not by topic.** A rule that applies everywhere is a `CLAUDE.md` line, not a rule file.
- **Prefer filename-suffix globs over directory globs where the framework's own convention is strong.** NestJS's `*.controller.ts`/`*.service.ts`/`*.entity.ts` suffixes are near-universal regardless of layout, so this kit's rules key off them primarily — a rule keyed only on `src/controller/**` silently stops loading the moment a repo uses feature-colocated modules instead. See [customization.md](customization.md) for switching the default layout.

One documentation wrinkle: the schema key is `paths:`, but several Claude Code builds only honour `globs:`. This kit uses `globs:`. If a rule is silently ignored, that is the first thing to check.

## Layer 3 — Plan Mode

Not a file — a habit, and the one with the best return.

Plan Mode separates exploring from doing. The explore subagent reads the codebase in its own context and the planner emits a document you can amend before anything is written. Use it for anything touching more than one service, any refactor, and any schema change.

The planning subagent is read-only by design. It cannot mutate the codebase while it maps dependencies.

## Layer 4 — subagents

Write one when a task repeats, needs restricted tools, or needs a system prompt that conflicts with the main configuration.

The two properties that make the four agents here worth having:

- **`tools:` is an allowlist.** `nest-reviewer` gets `Read, Grep, Glob` plus `Bash(git diff:*)`. It cannot write. That is a structural guarantee, not a promise.
- **`model: sonnet`** keeps them cheap. The main loop keeps the stronger model for reasoning that actually needs it; review and log triage run in the background at a fraction of the cost.

Reviewing in the main session is the mistake this layer exists to prevent. Review pulls a lot of file content into context and then that content sits there for the rest of the conversation.

## Layer 5 — skills

Progressive disclosure: metadata at session start, instructions when triggered, bundled resources only when referenced. Fifty installed skills still cost almost nothing ambient.

Every skill in this kit has the same three sections, and the third is the one people skip:

1. **Inputs to gather first** — forces the agent to ask instead of inventing requirements.
2. **Steps** — explicit order, real commands.
3. **Do not** — hard boundaries. `mr-checklist` must not `git push`; `new-migration` must not touch an existing migration file.

`allowed-tools` enforces the boundary at the tool layer, so it holds even if the model would rather not.

## Layer 6 — hooks

Hooks add deterministic guardrails to a probabilistic system. This is the only layer that cannot be talked out of its position.

The two shapes worth knowing:

**Formatting (PostToolUse).** Boring and the highest ROI in the kit. The agent writes a messily indented file, the hook formats it, and the next turn reads clean code. Without it the agent gets confused by its own output.

**Gating (PreToolUse).** Return `deny` for things that must never happen, `ask` for things a human should confirm. `gate-dangerous.sh` denies force pushes and `reset --hard`; it asks on anything mentioning `prod`, `staging` or `uat`, because a command naming a shared environment deserves a human glance even when it looks harmless.

`protect-migrations.sh` is the clearest case for the layer. "Never edit a committed migration" is exactly the kind of rule that holds for thirty turns and then quietly does not. The hook checks `git ls-files` and returns `deny`. It is not subject to attention drift.

`log-denied.sh` closes the loop: every denial is appended to `.claude/logs/denied.jsonl`, so you can tell later whether a guardrail is earning its place or just getting in the way.

## Layer 7 — the server stack

Every MCP server contributes tool schemas to **every turn**. Fifty tools can run 10–20k tokens per turn. Lazy tool-loading cuts that substantially, but fewer servers is still the better strategy.

Three here:

- **`gitlab`** — merge requests, branches, issues on a self-hosted instance.
- **`context7`** — version-correct library documentation. NestJS/TypeORM's API surface moves across majors, and this is what stops the model confidently writing TypeORM 0.2-style code (or an old Nest decorator) into a current project.
- **`db-local`** — schema reads and `EXPLAIN`, read-only, local container only.

No filesystem server: `Read`, `Grep` and `Glob` already do that at no schema cost. Add a fourth server only when you can name the recurring task it removes.

## Layer 8 — worktrees and headless

**Worktrees** let you run several sessions in parallel, each with its own context. Overlapping tasks produce overlapping edits, so scope panes to distinct domains — tests in one, core logic in another — and conflicts stay rare.

**Headless** (`claude -p --allowedTools ...`) runs the agent non-interactively in CI. Combined with `gate-dangerous.sh`, a nightly job can prepare a fix and stop at the push, waiting for a human instead of either failing or being handed blanket permissions.

## What this does not solve

Long-running sessions still degrade as the context fills with stale observations. None of these layers fix that; they only delay it. Start a fresh session when a task changes shape, and use `/context` to see where the budget is actually going.
