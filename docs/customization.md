# Customization

The installer gets you a working baseline. These are the adjustments that make it fit *your* repo. Budget ten minutes.

🇻🇳 [Tiếng Việt](customization.vi.md)

## 1. Fix the globs — do this first

The rule files default to a **layered-by-type** layout, matching a real internal NestJS reference repo used to build this kit:

```
src/controller/  service/  entity/  dto/  guard/
```

Filename-suffix globs (`**/*.controller.ts`, `**/*.service.ts`, ...) are the primary match in every rule, so they still load correctly even if your repo does **not** use this directory layout — NestJS's naming convention is strong enough that the suffix alone is usually sufficient.

If your repo uses Nest CLI's default **feature-colocated** style instead (`src/orders/orders.controller.ts`, `orders.service.ts`, `orders.module.ts` all in one folder), the directory-based globs (`src/controller/**` etc.) simply never match — harmless, since the suffix globs already cover it, but you can drop the dead directory patterns to keep the frontmatter tidy:

```yaml
# .claude/rules/api-layer.md
globs:
  - "**/*.controller.ts"
  - "**/*.controller.spec.ts"
  - "**/*.dto.ts"
  - "**/*.guard.ts"
```

Verify: open `claude`, ask it to read a controller, then check `/context` — the rule should appear as loaded.

## 2. Fix the build commands

`CLAUDE.md`'s *Build & test* section is what the agent copies when it runs anything. Wrong commands there cost a wasted turn every time.

Delete lines for tooling you do not have. No ESLint or Prettier config? `format-source.sh` already checks for either before running it and exits quietly if neither is present, so nothing breaks — but the agent should not be told to run `npm run lint` if that script does not exist.

If there is no separate e2e source set, drop the `test:e2e` line rather than leaving a script name that does not exist.

## 3. yarn or pnpm instead of npm

The kit works; the commands do not. `install.sh` already detects your package manager from the lockfile and prints it in the header line, but `CLAUDE.md`'s *Build & test* section always shows `npm run ...` — replace it:

```markdown
## Build & test
- Build:           `pnpm build`
- Unit test:        `pnpm test`
- One test:         `pnpm test -- <pattern>`
- E2E:              `pnpm test:e2e`
- Lint + format:    `pnpm lint`
- Run local:        `docker compose up -d && pnpm start:dev`
```

(swap `pnpm` for `yarn` as needed). Then update the `tools:` allowlist in each agent (`Bash(pnpm:*)` instead of `Bash(npm run:*)`), the `allowed-tools` in each skill, and `permissions.allow` in `.claude/settings.json`.

## 4. Prisma instead of TypeORM

`persistence.md` and `migrations.md` assume TypeORM's decorator-based entities and its `migration:generate`/`migration:run` CLI. For Prisma:

- Replace the entity conventions with `schema.prisma` model conventions (naming, relation mode, index declarations).
- Replace the migration CLI section with `npx prisma migrate dev --name <name>` (local) / `npx prisma migrate deploy` (CI), and the immutability rule with Prisma's own migration-history convention (`prisma/migrations/`, never edit a folder already applied anywhere).
- `protect-migrations.sh` matches `*src/migrations/*` — change it to `*prisma/migrations/*`.
- The transaction pattern in `service-layer.md` (`dataSource.transaction()`) becomes `prisma.$transaction(async (tx) => {...})`; update that rule and the `nest-reviewer` agent's checklist accordingly.
- The N+1/eager-loading framing in `persistence.md` is TypeORM-specific (`eager: true`, `relations: [...]`); Prisma's equivalent is `include`/`select` — the underlying advice (fetch relations explicitly, avoid per-row queries in a loop) carries over, only the API names change.

## 5. GitHub, Bitbucket or Gitea instead of GitLab

Replace the `gitlab` block in `.mcp.json`:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
}
```

Update `enabledMcpjsonServers` in `.claude/settings.json` to match, and rename "merge request" to "pull request" in `mr-checklist/SKILL.md` and `CLAUDE.md`.

## 6. Monorepos (Nx, multiple apps/libs)

For an Nx workspace or a `apps/*`/`libs/*` layout, prefer **one rule file per app or lib** over one big rule set:

```yaml
# .claude/rules/app-payment.md
globs:
  - "apps/payment/**"
```

Each app's rule can then carry its own build command (`nx test payment`) and its own conventions. Keep the shared rules — `tests.md`, `migrations.md` — global at the workspace root.

If apps are owned by different teams, `.claude/rules/` is also where ownership notes belong. Not `CLAUDE.md`.

## 7. Tightening or loosening permissions

`.claude/settings.json` ships deliberately cautious. Two directions to move it:

**Tighter** — for repos touching money or personal data, move `Edit(src/**)` from `allow` to `ask`, and add `Bash(docker compose:*)` to `ask`.

**Looser** — for a personal sandbox repo, move `Bash(git commit:*)` to `allow`. Leave `git push` in `ask`; that boundary is worth keeping everywhere.

Check `.claude/logs/denied.jsonl` after a couple of weeks. It tells you empirically which way to move.

## 8. Language

Rule and skill files ship in Vietnamese, with English reserved for code, identifiers, commit messages and log output — the split most Vietnamese teams already use.

To switch to English, translate the `.md` files under `.claude/`, and change the last section of `CLAUDE.md`:

```markdown
## Language
Respond in English. Code, identifiers, commit messages and log messages in English.
```

The frontmatter keys (`name`, `description`, `globs`, `tools`, `model`, `allowed-tools`) must stay in English regardless.

## 9. `SERVICE_MAP.md` and the transports you actually use

The shipped template lists six sections (outbound REST, inbound REST, publish, consume,
realtime, data ownership) because the kit doesn't know in advance which of REST, Kafka,
RabbitMQ, Redis pub/sub or WebSocket/socket.io a given service actually speaks. Once you
know, delete the sections that will never apply rather than leaving them empty forever — an
empty heading invites the `update-service-map` skill (and future readers) to wonder whether
it was never filled in or genuinely doesn't apply.

If this service talks to others over a transport not listed at all (gRPC, GraphQL
federation, SQS/SNS...), add a section for it and extend the `update-service-map` skill's
grep list for that transport's client/listener calls or decorators.

## 10. Team rollout

Commit `.claude/` and `.mcp.json`. Do not commit `.env.mcp` or `.claude/settings.local.json` — the installer adds both to `.gitignore`.

Each developer runs:

```bash
cp .env.mcp.example .env.mcp   # their own GitLab token
set -a; source .env.mcp; set +a
```

Personal preferences go in `.claude/settings.local.json` (gitignored). Anything the whole team should share goes in `settings.json` and through code review like any other change.
