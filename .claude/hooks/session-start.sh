#!/usr/bin/env bash
# engram session-start hook. Fires on SessionStart. See docs.claude.com for hook API.
#
# Injects persistent project memory (MEMORY.md + topic index) into the session
# context as a system reminder so Claude has shift-notes before the first user turn.
set -euo pipefail

# Resolve project root: hook lives at <root>/.claude/hooks/session-start.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MEMORY_FILE="${ROOT}/MEMORY.md"
INDEX_FILE="${ROOT}/.claude/memory/index.md"

# Nothing to inject if memory has not been initialized yet.
[[ -f "$MEMORY_FILE" || -f "$INDEX_FILE" ]] || exit 0

printf '<system-reminder>\n'
printf 'Persistent project memory. Read before responding.\n\n'

if [[ -f "$MEMORY_FILE" ]]; then
  printf '# MEMORY.md\n'
  cat "$MEMORY_FILE"
  printf '\n'
fi

if [[ -f "$INDEX_FILE" ]]; then
  printf '\n# .claude/memory/index.md\n'
  cat "$INDEX_FILE"
  printf '\n'
fi

printf '</system-reminder>\n'
