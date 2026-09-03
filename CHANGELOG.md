# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Added
- README: an optional "keep it local, not shared with the team" section documenting
  `.git/info/exclude` as an alternative to committing the kit — for trying it on a shared
  repo before proposing it to the team.

### Changed
- `gate-dangerous.sh` is now branch-aware: any `git push`/`git merge`/`git rebase`/force
  `git branch -D` targeting `main`, `master` or `prod` is now denied outright rather than
  merely asked; the same operations touching `uat` always ask (never denied outright).
  Push-target detection is best-effort string parsing of the command, with a fallback to
  the repo's current branch when the command doesn't name one explicitly (plain `git
  push`). `gh pr merge` — previously ungated entirely, since it doesn't contain the string
  `git` — now always asks.

### Added
- `SERVICE_MAP.md` — a new root file, rendered by `install.sh` alongside `CLAUDE.md` but
  never auto-loaded, documenting a service's external interface (outbound/inbound REST,
  Kafka/RabbitMQ/Redis pub-sub, WebSocket/socket.io, owned tables). Not asserted as fact —
  the kit has no contract registry to check against, so every entry is inferred from code
  and needs human confirmation.
- New skill `update-service-map`: greps a repo for outbound calls and inbound
  listeners/consumers across REST, Kafka, RabbitMQ, Redis pub/sub and WebSocket/socket.io,
  and proposes edits to `SERVICE_MAP.md` for the user to confirm before writing.
- `CLAUDE.md.template` and `service-layer.md` each gained one pointer line to
  `SERVICE_MAP.md`; `/onboard` now suggests running `update-service-map` after the first
  survey when a service talks to others.
- Sibling kit `claude-code-workspace` (separate repo) for the cross-service tier this file
  feeds into — see `docs/design.md`.

## [1.0.0] — 2026-09-03

### Added
- `CLAUDE.md.template` — memory file under 60 lines, rendered per repo by `install.sh`.
- Six path-scoped rule files: `api-layer`, `service-layer`, `persistence`, `tests`,
  `migrations`, `infra-config`.
- Four subagents: `nest-reviewer`, `test-runner`, `db-migration-auditor`, `log-triage`.
- Five skills: `new-endpoint`, `debug-failing-test`, `new-migration`, `mr-checklist`, `perf-triage`.
- Five hooks: `session-start`, `gate-dangerous`, `protect-migrations`, `format-source`, `log-denied`.
- Three slash commands: `/onboard`, `/review`, `/fix-test`.
- `.mcp.json` with GitLab, Context7 and a read-only local database server.
- `install.sh` with project detection (service name, Node/Nest version, package
  manager), `--dry-run`, `--force`; `uninstall.sh`.
- CI: shellcheck, JSON validation, frontmatter checks, end-to-end install test.

Defaults: TypeORM, layered-by-type source layout (`src/controller/service/entity/...`),
npm. See `docs/customization.md` for Prisma, yarn/pnpm, and feature-colocated layouts.

[Unreleased]: https://github.com/shigakogen/claude-code-nestjs/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/shigakogen/claude-code-nestjs/releases/tag/v1.0.0
