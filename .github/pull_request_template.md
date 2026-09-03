## What this changes

<!-- One or two sentences. Which layer: CLAUDE.md / rules / agents / skills / hooks / installer / docs? -->

## Why

<!-- Rules and skills earn their place by fixing observed behaviour. What did the agent get wrong,
     and how many times did you see it? "Seemed like a good idea" is not enough — every always-loaded
     line costs tokens on every turn. -->

## Token impact

- [ ] Does not add lines to `CLAUDE.md.template` (or explains why the line must be always-loaded)
- [ ] New rules are path-scoped with a `globs:` frontmatter
- [ ] No new MCP server (or explains why the tool schemas are worth the per-turn cost)

## Checklist

- [ ] `./tests/run.sh` passes locally
- [ ] `shellcheck --severity=warning` clean on any changed shell script
- [ ] New rule/skill/agent files have `---` frontmatter with a `description:`
- [ ] Tried it on a real NestJS repo, not just the fixture
- [ ] `CHANGELOG.md` updated under `## Unreleased`
