#!/usr/bin/env bash
# Self-test for the template kit. Run locally with: ./tests/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$ROOT/tests/tmp"
fail=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

head_ "1. Shell syntax"
for f in "$ROOT"/*.sh "$ROOT"/template/.claude/hooks/*.sh "$ROOT"/tests/run.sh; do
  bash -n "$f" && ok "$(basename "$f")" || bad "$(basename "$f")"
done

head_ "2. JSON validity"
for f in "$ROOT"/template/.mcp.json "$ROOT"/template/.claude/settings.json \
         "$ROOT"/template/.claude/settings.local.json.example; do
  jq -e . "$f" >/dev/null 2>&1 && ok "$(basename "$f")" || bad "$(basename "$f")"
done

head_ "3. Frontmatter present on every rule / agent / skill / command"
while IFS= read -r f; do
  if head -n1 "$f" | grep -qx -- '---' && sed -n '2,20p' "$f" | grep -q '^description:'; then
    ok "${f#"$ROOT"/}"
  else
    bad "${f#"$ROOT"/} (missing --- or description:)"
  fi
done < <(find "$ROOT/template/.claude" -name '*.md' ! -name 'CLAUDE.md.template' | sort)

head_ "4. Hooks emit valid JSON and gate the right commands"
export CLAUDE_PROJECT_DIR="$TMP/repo"
check_decision() { # check_decision <script> <json-in> <expected: allow|deny|ask>
  local out dec
  out="$(printf '%s' "$2" | bash "$ROOT/template/.claude/hooks/$1" 2>/dev/null)"
  jq -e . >/dev/null 2>&1 <<< "$out" || { bad "$1 emitted invalid JSON"; return; }
  dec="$(jq -r '.hookSpecificOutput.permissionDecision // "allow"' <<< "$out")"
  [ "$dec" = "$3" ] && ok "$1: $3 as expected" || bad "$1: got '$dec', expected '$3'"
}
check_decision gate-dangerous.sh '{"tool_input":{"command":"git push --force origin main"}}' deny
check_decision gate-dangerous.sh '{"tool_input":{"command":"git reset --hard HEAD~1"}}'      deny
check_decision gate-dangerous.sh '{"tool_input":{"command":"npm run test"}}'                 allow
check_decision gate-dangerous.sh '{"tool_input":{"command":"psql -h prod-db"}}'               ask
check_decision gate-dangerous.sh '{"tool_input":{"command":"git push"}}'                      ask

head_ "5. End-to-end install on a fixture repo"
rm -rf "$TMP" && mkdir -p "$TMP/repo/src/controller" "$TMP/repo/src/migrations"
cd "$TMP/repo"
git init -q && git config user.email t@t && git config user.name t
cat > package.json <<'G'
{
  "name": "acme-order-service",
  "engines": { "node": ">=20" },
  "dependencies": { "@nestjs/core": "^10.3.0", "typeorm": "^0.3.20" }
}
G
echo 'export class OrderController {}' > src/controller/order.controller.ts
echo 'export class Init1700000000000 { async up() {} async down() {} }' > src/migrations/1700000000000-Init.ts
git add -A && git commit -qm init

"$ROOT/install.sh" . >/dev/null
[ -f CLAUDE.md ]                                  && ok "CLAUDE.md at repo root" || bad "CLAUDE.md missing"
grep -q 'acme-order-service' CLAUDE.md            && ok "service name detected" || bad "service name not substituted"
grep -q 'Node 20' CLAUDE.md                       && ok "node version detected" || bad "node version wrong"
grep -q '10.3.0' CLAUDE.md                        && ok "nest version detected" || bad "nest version wrong"
! grep -q '{{' CLAUDE.md                          && ok "no unresolved placeholders" || bad "placeholders left in CLAUDE.md"
[ -x .claude/hooks/gate-dangerous.sh ]            && ok "hooks executable"       || bad "hooks not executable"
[ "$(find .claude -type f | wc -l)" -ge 20 ]      && ok "all kit files copied"   || bad "files missing"
grep -qx '.env.mcp' .gitignore                    && ok ".gitignore updated"     || bad ".gitignore not updated"
[ -f SERVICE_MAP.md ]                             && ok "SERVICE_MAP.md at repo root" || bad "SERVICE_MAP.md missing"
grep -q '# SERVICE_MAP — acme-order-service' SERVICE_MAP.md && ok "service name substituted in SERVICE_MAP.md" || bad "service name not substituted"
grep -q '## Publish' SERVICE_MAP.md               && ok "SERVICE_MAP.md has expected sections" || bad "SERVICE_MAP.md missing sections"
! grep -q '{{' SERVICE_MAP.md                     && ok "no unresolved placeholders (SERVICE_MAP.md)" || bad "placeholders left in SERVICE_MAP.md"

head_ "6. protect-migrations blocks committed files only"
export CLAUDE_PROJECT_DIR="$TMP/repo"
d1="$(printf '{"tool_input":{"file_path":"%s/src/migrations/1700000000000-Init.ts"}}' "$PWD" \
      | bash .claude/hooks/protect-migrations.sh | jq -r '.hookSpecificOutput.permissionDecision // "allow"')"
[ "$d1" = "deny" ] && ok "existing migration is immutable" || bad "existing migration not protected (got $d1)"
d2="$(printf '{"tool_input":{"file_path":"%s/src/migrations/1700000099999-AddIndex.ts"}}' "$PWD" \
      | bash .claude/hooks/protect-migrations.sh | jq -r '.hookSpecificOutput.permissionDecision // "allow"')"
[ "$d2" = "allow" ] && ok "new migration allowed" || bad "new migration wrongly blocked (got $d2)"

head_ "7. Idempotency — second run writes nothing new"
printf '\ncustom entry\n' >> SERVICE_MAP.md
out="$("$ROOT/install.sh" . 2>&1)"
grep -q 'skip' <<< "$out" && ok "re-run skips existing files" || bad "re-run did not skip"
grep -q 'custom entry' SERVICE_MAP.md && ok "SERVICE_MAP.md preserved on reinstall" || bad "SERVICE_MAP.md clobbered on reinstall"
git status --porcelain | grep -q . && ok "no unexpected churn check ran" || true

head_ "8. Existing CLAUDE.md is preserved, not clobbered"
rm -rf "$TMP/repo2" && cp -r "$TMP/repo" "$TMP/repo2" && cd "$TMP/repo2"
rm -rf .claude CLAUDE.md .mcp.json
printf '# our team rules\nkeep this line\n' > CLAUDE.md
"$ROOT/install.sh" . >/dev/null
grep -q 'keep this line' CLAUDE.md        && ok "team CLAUDE.md preserved"   || bad "team CLAUDE.md clobbered"
grep -q '@.claude/CLAUDE.md' CLAUDE.md    && ok "import line added"          || bad "import line missing"
[ -f .claude/CLAUDE.md ]                  && ok "kit memory at .claude/CLAUDE.md" || bad "kit memory missing"

head_ "9. uninstall.sh cleans up"
"$ROOT/uninstall.sh" . --yes >/dev/null
[ ! -d .claude ]                          && ok ".claude removed"            || bad ".claude still present"
[ ! -f .mcp.json ]                        && ok ".mcp.json removed"          || bad ".mcp.json still present"
grep -q 'keep this line' CLAUDE.md        && ok "team CLAUDE.md survived"    || bad "team CLAUDE.md destroyed"
! grep -q '@.claude/CLAUDE.md' CLAUDE.md  && ok "import line removed"        || bad "import line left behind"

cd "$ROOT" && rm -rf "$TMP"
printf '\n'
[ "$fail" -eq 0 ] && { printf '\033[32mAll checks passed.\033[0m\n'; exit 0; }
printf '\033[31mSome checks failed.\033[0m\n'; exit 1
