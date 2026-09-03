#!/usr/bin/env bash
# PermissionDenied / PostToolUse audit: ghi lại thao tác bị từ chối để rà soát về sau.
set -uo pipefail
dir="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$dir"
cat | jq -c --arg ts "$(date -Iseconds)" '. + {ts: $ts}' >> "$dir/denied.jsonl" 2>/dev/null || true
exit 0
