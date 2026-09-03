# claude-code-nestjs

A reusable `.claude/` configuration kit for NestJS/TypeScript repositories — memory file, path-scoped rules, subagents, skills, hooks and a deliberately small MCP server list.

Built on one constraint: **the always-loaded context must stay small.** Everything else loads on demand.

[![ci](https://github.com/OWNER/claude-code-nestjs/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/claude-code-nestjs/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

🇻🇳 [Tiếng Việt](README.vi.md)

---

## Install

```bash
git clone https://github.com/OWNER/claude-code-nestjs.git ~/tools/claude-code-nestjs
cd ~/work/my-nest-service
~/tools/claude-code-nestjs/install.sh .
```

Preview first — nothing is written:

```bash
~/tools/claude-code-nestjs/install.sh . --dry-run
```

The installer is safe on an existing repo. It never overwrites a file that already exists (pass `--force` to override), and if you already have a `CLAUDE.md` it keeps yours and adds an `@.claude/CLAUDE.md` import line instead of clobbering it.

Then:

```bash
cp .env.mcp.example .env.mcp     # fill GITLAB_API_URL, GITLAB_TOKEN, LOCAL_DB_DSN
set -a; source .env.mcp; set +a
claude
```

Inside the session run `/onboard`. It reads the codebase and proposes the exact lines to correct in `CLAUDE.md` — real module names, real npm scripts, real modules. **Do this before anything else**; the generated file is a starting point, not a finished one.

Verify with `/memory`, `/agents`, `/mcp`, `/context`. Then commit `.claude/` and `.mcp.json` so the whole team shares the setup.

Removing it: `~/tools/claude-code-nestjs/uninstall.sh .`

### Requirements

| | |
|---|---|
| Claude Code | any recent version |
| `jq` | required — the hooks parse their JSON payload with it |
| Project | NestJS + TypeORM, npm/yarn/pnpm (auto-detected); Prisma works but you must edit the persistence rule and migration commands |
| Optional | Docker Compose for local infra |

---

## What you get

```
CLAUDE.md              rendered at the repo root — under 60 lines, loaded every turn
.claude/
├── rules/             loaded by glob, zero cost when you are not touching matching files
├── agents/            separate context, cheaper model, narrow tool allowlist
├── skills/            packaged workflows; only metadata is loaded until triggered
├── hooks/             deterministic guardrails
├── commands/          /onboard  /review  /fix-test
└── settings.json      permissions + hook wiring (commit this)
.mcp.json              three servers, not fifteen
```

### Rules — six, path-scoped

| File | Glob | Covers |
|---|---|---|
| `api-layer.md` | `**/*.controller.ts`, `src/controller/**`, `**/*.dto.ts`, `**/*.guard.ts` | controllers, DTO validation, error contract, guards |
| `service-layer.md` | `**/*.service.ts`, `src/service/**` | transaction boundaries, DI, business invariants |
| `persistence.md` | `**/*.entity.ts`, `**/*.repository.ts`, `src/entity/**` | eager/lazy relations, N+1, pagination, MySQL/Postgres types |
| `tests.md` | `**/*.spec.ts`, `test/**` | unit vs e2e, no real network, no `.skip()`/`.only()` to go green |
| `migrations.md` | `src/migrations/**` | TypeORM CLI, immutability, expand–migrate–contract, large-table locks |
| `infra-config.md` | `package.json`, `.env*`, `Dockerfile`, `docker-compose*.yml`, `.gitlab-ci.yml` | dependencies, secrets, CI |

Filename-suffix globs (`*.controller.ts`) are primary here, not directory globs — NestJS's naming convention is consistent across both feature-colocated and layered-by-type repos, so rules load correctly regardless of which layout a given repo uses.

### Subagents — four

| Agent | Use it | Why it is separate |
|---|---|---|
| `nest-reviewer` | after implementing, before opening the MR | review reads many files; keep that out of the main context |
| `test-runner` | run and summarise tests | Jest output can be long — read it elsewhere, return five lines |
| `db-migration-auditor` | any diff touching `src/migrations/` | specialised criteria, high blast radius |
| `log-triage` | you paste an exception | maps the familiar NestJS/TypeORM failure families to root causes |

All four run on `sonnet` with a narrow `tools` allowlist. The main loop keeps the stronger model for the hard reasoning.

### Skills — five

`new-endpoint` · `debug-failing-test` · `new-migration` · `mr-checklist` · `perf-triage`

Each follows the same shape: *what to ask before writing code* → *ordered steps with real commands* → *what not to do*. `allowed-tools` enforces the boundary rather than relying on the model to remember it — `mr-checklist` cannot `git push`.

### Hooks — five

| Hook | Event | Does |
|---|---|---|
| `session-start.sh` | SessionStart | one line of live context: branch, dirty files, Node version, compose up/down |
| `gate-dangerous.sh` | PreToolUse `Bash` | **denies** force push, `reset --hard`, `git clean`, `publish`; **asks** on `git push`, `commit --amend`, `compose down -v`, and any command mentioning `prod`/`staging`/`uat` |
| `protect-migrations.sh` | PreToolUse `Edit\|Write` | **denies** edits to migration files already committed to git |
| `format-source.sh` | PostToolUse | runs ESLint `--fix` then Prettier after every `.ts`/`.js` write, if configured |
| `log-denied.sh` | PermissionDenied | appends to `.claude/logs/denied.jsonl` for later review |

`protect-migrations.sh` is the one that pays for itself. A prompt asking the model not to edit old migrations gets ignored eventually; a hook does not.

### MCP — three servers

`gitlab` (self-hosted instance) · `context7` (version-correct library docs) · `db-local` (**read-only**, DSN points at your Docker Compose database only).

Every server's tool schemas are loaded on **every turn**. Fifty tools can cost 10–20k tokens per turn. That is why there is no filesystem server here — `Read`/`Grep`/`Glob` already cover it, for free.

> **Never** point `db-local` at staging or production. The `--readonly` flag is a seatbelt, not permission.

---

## Documentation

| | |
|---|---|
| [docs/design.md](docs/design.md) | why each layer exists and what it costs — read this before adding anything |
| [docs/customization.md](docs/customization.md) | adapting to your module layout, Prisma, yarn/pnpm, other Git hosts |
| [docs/troubleshooting.md](docs/troubleshooting.md) | rules not loading, hooks not firing, MCP not connecting |

## Adoption

Do not turn everything on day one.

| Week | Add |
|---|---|
| 1 | `CLAUDE.md` + two rules (`api-layer`, `tests`) + the formatting hook + three MCP servers. Use Plan Mode for anything risky. |
| 2 | `gate-dangerous` and `protect-migrations`, once you have seen the agent do something you wish it had not. Add `nest-reviewer`. |
| 3 | Package the workflows that have stabilised into skills. |
| 4+ | Parallel worktrees; headless runs in CI (`claude -p --allowedTools ...`). |

## Maintaining it

- Add a rule only after you have seen the agent make **the same mistake twice**. Not on speculation.
- Review `.claude/logs/denied.jsonl` quarterly. A guardrail that never fires is dead weight; one that blocks legitimate work every day is too tight.
- If `CLAUDE.md` passes 200 lines, move detail into `rules/` — do not raise the ceiling. CI enforces this.

## Anti-patterns

- Pasting the engineering wiki into `CLAUDE.md`.
- Installing fifteen MCP servers "just in case".
- Letting the agent `git push` on its own.
- Giving the database MCP write access, or pointing it at a shared environment.
- Writing descriptive rules (*"prefer readable code"*) instead of checkable ones (*"controllers must not return TypeORM entities"*).
- Doing review in the main session.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Run `./tests/run.sh` before opening a PR.

## Credits

The layered approach — small memory file, path-scoped rules, subagents, skills, hooks, a short server list — follows Anubhav's write-up [*I Spent 6 Months Tuning Claude Code*](https://medium.com/data-science-collective/i-spent-6-months-tuning-claude-code-heres-the-exact-setup-that-finally-worked-b41c67628478). This repo applies it to NestJS, alongside a sibling kit for Spring Boot ([claude-code-springboot](https://github.com/OWNER/claude-code-springboot)).

## License

MIT — see [LICENSE](LICENSE).
