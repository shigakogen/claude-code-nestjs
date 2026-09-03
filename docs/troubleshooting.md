# Troubleshooting

## Rules never load

**Symptom.** The agent violates a rule that is clearly written in `.claude/rules/`. `/context` does not list the rule file.

Check in this order:

1. **Globs do not match your layout.** The shipped globs default to filename-suffix (`*.controller.ts`) plus a layered-by-type directory fallback (`src/controller/`). If your repo uses a very different naming convention (rare in NestJS, but possible in a legacy port), edit the globs. See [customization.md](customization.md#1-fix-the-globs--do-this-first).
2. **Wrong frontmatter key.** The documented key is `paths:`, but several builds only honour `globs:`. This kit uses `globs:`. If yours wants the other, swap it:
   ```yaml
   paths: ["**/*.controller.ts"]
   ```
   A CSV form on one line also works more reliably on some builds than a YAML list.
3. **Malformed frontmatter.** It must start on line 1 with `---`, and both delimiters need their own line. A leading blank line breaks parsing silently.
4. **Rules are not supported in your version.** Run `claude --version`. If path-scoped rules are not available, temporarily fold the two or three most important lines into `CLAUDE.md` and keep the rule files ready.

Quick check: ask the agent directly — *"which rule files are currently loaded?"*

## `CLAUDE.md` is not picked up

Claude Code loads `./CLAUDE.md` from the repo root. The installer puts it there. If your repo already had one, the kit's copy went to `.claude/CLAUDE.md` and an import line was appended:

```markdown
@.claude/CLAUDE.md
```

If that import is not honoured in your version, merge the two files by hand and delete `.claude/CLAUDE.md`. Two overlapping memory files cost tokens on every turn and give the model contradictory instructions.

Confirm with `/memory`.

## Hooks do not fire

1. **`jq` is missing.** Every hook parses its payload with it. `jq --version`; install with `apt install jq` or `brew install jq`.
2. **Not executable.** `chmod +x .claude/hooks/*.sh`. Cloning on Windows or copying through some tools drops the bit.
3. **`$CLAUDE_PROJECT_DIR` is unset.** Hooks resolve paths through it. If your version does not set it, hardcode an absolute path in `settings.json` as a temporary fix.
4. **CRLF line endings.** `#!/usr/bin/env bash\r` fails with a confusing "no such file" error. Fix: `sed -i 's/\r$//' .claude/hooks/*.sh`, and add `*.sh text eol=lf` to `.gitattributes`.

Test a hook directly, outside Claude Code:

```bash
export CLAUDE_PROJECT_DIR=$PWD
echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/gate-dangerous.sh
# expect: {"hookSpecificOutput":{...,"permissionDecision":"deny",...}}
```

Then check `.claude/logs/denied.jsonl` — if denials are being logged, the wiring works.

## `protect-migrations.sh` blocks a *new* migration

It only denies files tracked by git (`git ls-files --error-unmatch`). If a genuinely new file is blocked, it was already staged with `git add`. Unstage it (`git restore --staged <file>`) or, if it is committed, create a new migration instead — which is the rule the hook exists to enforce.

## `format-source.sh` slows every write

It runs ESLint and/or Prettier per file via `npx`.

- If neither `.eslintrc*`/`eslint.config.*` nor `.prettierrc*`/`prettier.config.*` exists, the hook exits immediately — it checks for either before running anything.
- `npx` resolving a package it has not cached yet is the usual slow path. Run the formatters once manually (`npx eslint .`) to warm npm's local cache.
- Still too slow? Raise the `timeout` in `settings.json`, or drop the hook and run lint/format in your pre-commit hook instead.

## MCP servers do not connect

Run `/mcp` inside the session for per-server status.

- **Env vars not expanded.** `.mcp.json` uses `${GITLAB_TOKEN}`. Those must be in the environment *before* `claude` starts: `set -a; source .env.mcp; set +a; claude`.
- **Server not enabled.** `.claude/settings.json` sets `enableAllProjectMcpServers: false` and enables servers explicitly in `enabledMcpjsonServers`. `db-local` is off by default — enable it in `.claude/settings.local.json`.
- **Self-hosted GitLab behind a private CA.** Set `NODE_EXTRA_CA_CERTS=/path/to/ca.pem` in the server's `env` block.
- **`npx` blocked by a corporate proxy.** Pre-install the package globally and point `command` at the binary directly.

## The database MCP can write

It should not be able to. Confirm `--readonly` is present in the `db-local` args and that `LOCAL_DB_DSN` points at localhost. If either is wrong, fix it now — a read-only intent expressed only in a rule file is not a control.

## Token usage is higher than expected

Run `/context`. Reading in order:

- **`CLAUDE.md` over ~1.5k tokens** — move detail into `rules/`.
- **MCP tool schemas dominating** — you have too many servers. Three is the target; each additional one is charged on every turn.
- **Many rule files loaded at once** — globs are too broad. `**/*.ts` matches everything and defeats the point.
- **Old tool results filling the window** — start a fresh session. Long conversations accumulate stale observations, and no configuration fixes that.

## Agents are not offered

Check `/agents`. If the list is empty, `.claude/agents/*.md` frontmatter is malformed — `name:` and `description:` are both required, and `name` must match the filename without the extension.

If an agent exists but is never chosen on its own, its `description` is too vague. Descriptions are what the main loop matches against; say *when* to use it, not just what it is.

## Everything worked, then stopped after a Claude Code upgrade

Frontmatter schemas and hook event names do change between versions. Run `./tests/run.sh` from the kit repo — it validates JSON, frontmatter and hook output shapes, and will usually point at what moved. Then check the [Claude Code changelog](https://docs.claude.com/en/docs/claude-code) for the events and keys you rely on.
