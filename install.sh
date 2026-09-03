#!/usr/bin/env bash
#
# claude-code-nestjs — install the .claude/ config kit into a NestJS repo.
#
#   ./install.sh [TARGET_REPO] [--dry-run] [--force]
#
# Safe on existing repos: never overwrites an existing file unless --force.
set -euo pipefail

VERSION="1.0.0"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/template"

TARGET="."
DRY=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --force)   FORCE=1 ;;
    -h|--help)
      sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  TARGET="$1" ;;
  esac
  shift
done

# --- colours (disabled when not a tty) ---------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; D=$'\033[2m'; N=$'\033[0m'
else B=""; G=""; Y=""; D=""; N=""; fi

info() { printf '%s\n' "$*"; }
step() { printf '%s==>%s %s\n' "$B" "$N" "$*"; }
warn() { printf '%s!  %s%s\n' "$Y" "$*" "$N"; }

[ -d "$SRC" ] || { echo "Missing template/ next to install.sh" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "No such directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

step "claude-code-nestjs v$VERSION"
info "    target: $TARGET"
[ "$DRY" -eq 1 ] && warn "dry-run: nothing will be written"

# --- sanity checks -----------------------------------------------------------
if [ ! -e "$TARGET/package.json" ]; then
  warn "No package.json found — is this a Node project? Continuing anyway."
fi
if [ ! -d "$TARGET/.git" ]; then
  warn "Not a git repository — the protect-migrations hook needs git to work."
fi
command -v jq >/dev/null 2>&1 || warn "jq not found. Hooks require it: apt install jq / brew install jq"

# --- copy --------------------------------------------------------------------
copied=0; skipped=0
copy() {
  local rel="$1" from="$SRC/$1" to="$TARGET/$1"
  if [ -e "$to" ] && [ "$FORCE" -eq 0 ]; then
    printf '    %sskip%s  %s %s(exists)%s\n' "$D" "$N" "$rel" "$D" "$N"; skipped=$((skipped+1)); return
  fi
  if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$to")"; cp "$from" "$to"; fi
  printf '    %scopy%s  %s\n' "$G" "$N" "$rel"; copied=$((copied+1))
}

step "Copying files"
while IFS= read -r rel; do
  [ "$rel" = ".claude/CLAUDE.md.template" ] && continue
  [ "$rel" = "SERVICE_MAP.md.template" ] && continue
  copy "$rel"
done < <(cd "$SRC" && find . -type f | sed 's#^\./##' | sort)

[ "$DRY" -eq 0 ] && chmod +x "$TARGET"/.claude/hooks/*.sh 2>/dev/null || true

# --- detect project facts ----------------------------------------------------
step "Detecting project settings"
name="$(grep -m1 '"name"[[:space:]]*:' "$TARGET/package.json" 2>/dev/null \
  | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')" || true
[ -z "$name" ] && name="$(basename "$TARGET")"

node_ver="$(grep -m1 '"node"[[:space:]]*:' "$TARGET/package.json" 2>/dev/null \
  | grep -oE '[0-9]+' | head -n1)" || true
if [ -z "$node_ver" ] && [ -e "$TARGET/.nvmrc" ]; then
  node_ver="$(grep -oE '[0-9]+' "$TARGET/.nvmrc" 2>/dev/null | head -n1)" || true
fi
[ -z "$node_ver" ] && node_ver="20"

nest_ver="$(grep -m1 '"@nestjs/core"' "$TARGET/package.json" 2>/dev/null \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)" || true
[ -z "$nest_ver" ] && nest_ver="10.x"

pkg_manager="npm"
[ -e "$TARGET/yarn.lock" ] && pkg_manager="yarn"
[ -e "$TARGET/pnpm-lock.yaml" ] && pkg_manager="pnpm"

info "    service=$name  node=$node_ver  nest=$nest_ver  pkg-manager=$pkg_manager"
[ "$pkg_manager" != "npm" ] && warn "$pkg_manager detected — CLAUDE.md's Build & test section shows npm commands. Edit it to match."

# --- render memory file ------------------------------------------------------
# Claude Code loads ./CLAUDE.md at the repo root. If the repo already has one,
# keep it and add an import line instead of clobbering the team's file.
step "Installing memory file"
render() {
  sed -e "s|{{SERVICE_NAME}}|$name|g" \
      -e "s|{{NODE_VERSION}}|$node_ver|g" \
      -e "s|{{NEST_VERSION}}|$nest_ver|g" \
      -e "s|{{PKG_MANAGER}}|$pkg_manager|g" \
      -e "s|{{ONE_LINE_PURPOSE}}|TODO: one line on what this service does.|g" \
      "$SRC/.claude/CLAUDE.md.template"
}

if [ ! -e "$TARGET/CLAUDE.md" ]; then
  [ "$DRY" -eq 0 ] && render > "$TARGET/CLAUDE.md"
  printf '    %scopy%s  CLAUDE.md %s(repo root)%s\n' "$G" "$N" "$D" "$N"
elif [ "$FORCE" -eq 1 ]; then
  [ "$DRY" -eq 0 ] && render > "$TARGET/CLAUDE.md"
  printf '    %sover%s  CLAUDE.md %s(--force)%s\n' "$Y" "$N" "$D" "$N"
else
  if [ "$DRY" -eq 0 ]; then
    render > "$TARGET/.claude/CLAUDE.md"
    if ! grep -q '@\.claude/CLAUDE\.md' "$TARGET/CLAUDE.md"; then
      printf '\n@.claude/CLAUDE.md\n' >> "$TARGET/CLAUDE.md"
    fi
  fi
  printf '    %skeep%s  CLAUDE.md (yours) + wrote .claude/CLAUDE.md and imported it\n' "$Y" "$N"
  warn "Merge the two by hand later — duplicated rules cost tokens on every turn."
fi

# --- render service map -------------------------------------------------------
# Root file, next to CLAUDE.md, but NOT auto-loaded — read on demand only.
step "Installing service map"
render_map() { sed -e "s|{{SERVICE_NAME}}|$name|g" "$SRC/SERVICE_MAP.md.template"; }
if [ ! -e "$TARGET/SERVICE_MAP.md" ]; then
  [ "$DRY" -eq 0 ] && render_map > "$TARGET/SERVICE_MAP.md"
  printf '    %scopy%s  SERVICE_MAP.md %s(repo root)%s\n' "$G" "$N" "$D" "$N"
elif [ "$FORCE" -eq 1 ]; then
  [ "$DRY" -eq 0 ] && render_map > "$TARGET/SERVICE_MAP.md"
  printf '    %sover%s  SERVICE_MAP.md %s(--force)%s\n' "$Y" "$N" "$D" "$N"
else
  printf '    %sskip%s  SERVICE_MAP.md %s(exists)%s\n' "$D" "$N" "$D" "$N"
fi

# --- gitignore ---------------------------------------------------------------
step "Updating .gitignore"
gi="$TARGET/.gitignore"
[ "$DRY" -eq 0 ] && touch "$gi"
for line in ".claude/settings.local.json" ".claude/logs/" ".env.mcp"; do
  if [ -e "$gi" ] && grep -qxF "$line" "$gi" 2>/dev/null; then
    printf '    %sskip%s  %s\n' "$D" "$N" "$line"
  else
    [ "$DRY" -eq 0 ] && printf '%s\n' "$line" >> "$gi"
    printf '    %sadd%s   %s\n' "$G" "$N" "$line"
  fi
done

# --- done --------------------------------------------------------------------
step "Done — $copied written, $skipped skipped"
cat <<EOF

${B}Next steps${N}
  1. cp .env.mcp.example .env.mcp   and fill GITLAB_API_URL, GITLAB_TOKEN, LOCAL_DB_DSN
     then:  set -a; source .env.mcp; set +a
  2. Open ${B}claude${N} in the repo and run ${B}/onboard${N} — it inspects the codebase and
     proposes the exact lines to fix in CLAUDE.md (real modules, real npm scripts).
  3. Adjust ${B}globs:${N} in .claude/rules/*.md to match your package layout.
  4. Run the ${B}update-service-map${N} skill to fill in SERVICE_MAP.md from the code.
  5. Verify with  /memory  /agents  /mcp  /context
  6. Commit .claude/ and .mcp.json so the whole team gets the same setup.

  Docs: docs/customization.md · docs/troubleshooting.md
EOF
