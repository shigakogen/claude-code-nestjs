# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [SemVer](https://semver.org/).

## [Unreleased]

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
