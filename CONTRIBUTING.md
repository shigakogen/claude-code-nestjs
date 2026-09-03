# Contributing

Thanks for considering a contribution. This kit has one governing constraint, and it shapes what gets merged: **the always-loaded context must stay small.**

## The bar for new content

Rules, skills and agents earn their place by fixing behaviour someone actually observed going wrong — repeatedly. "This seems like a good practice" is not enough. Every line in `CLAUDE.md` is paid for on every turn, forever.

When proposing something, say which layer should carry it. Prefer the cheapest one that works:

1. **Hook** — deterministic, zero ambient cost. Best when the rule is mechanical.
2. **Path-scoped rule** — free unless the glob matches.
3. **Skill** — metadata only until triggered.
4. **Subagent** — free until invoked.
5. **`CLAUDE.md` line** — always loaded. Last resort.

A proposal that lands in layer 5 needs to justify why layers 1–4 cannot carry it.

## Style

**Rules and CLAUDE.md lines** are imperative and checkable:

- Good: `Controllers must never return TypeORM entities. Return DTOs from dto/.`
- Bad: `Prefer clean layering and good separation of concerns.`

You should be able to look at a diff and say whether the rule was followed. If you cannot, it is not a rule.

**Skills** follow the three-section shape: *inputs to gather first* → *ordered steps with real commands* → *do not*. The third section is not optional; it is where the boundaries live.

**Agents** need a `description` that says *when* to use them, a narrow `tools` allowlist, and `model: sonnet` unless there is a stated reason for more.

**Hooks** must be POSIX-friendly bash, pass `shellcheck --severity=warning`, never block on network, and fail open — a broken hook should not break someone's session.

## Before opening a PR

```bash
./tests/run.sh
shellcheck --severity=warning install.sh uninstall.sh tests/run.sh template/.claude/hooks/*.sh
```

Both run in CI along with a check that `CLAUDE.md.template` stays under 200 lines.

Test on a real NestJS repository, not only the fixture. The fixture proves the installer works; it does not prove a rule is useful.

Add a line to `CHANGELOG.md` under `## Unreleased`.

## Adding a rule file

1. Create `template/.claude/rules/<name>.md` with `name`, `description` and `globs` frontmatter.
2. Keep it under ~120 lines. CI warns past that.
3. Prefer filename-suffix globs (`**/*.controller.ts`) over directory globs where the framework's naming convention is strong enough to carry it on its own — that is what keeps rules loading regardless of feature-colocated vs layered-by-type layout.
4. Say in the PR which layout the globs assume, and whether they need adjusting for a feature-colocated (`nest g resource`) structure.

## Adding an MCP server

The default answer is no — three is the target, and every server's tool schemas are charged on every turn.

If you propose a fourth, name the recurring task it removes and estimate its schema cost. Servers that grant write access to shared systems will not be accepted as defaults; document them in `docs/customization.md` as opt-in instead.

## Translations

The kit ships Vietnamese rule and skill content with English identifiers. Translations of `README.md` and `docs/` are welcome. Frontmatter keys stay in English in every language.

## Code of conduct

Be decent. Assume the other person has context you do not. Technical disagreement is welcome; condescension is not.
