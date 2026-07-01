#!/usr/bin/env bash
# engram PreCompact hook — snapshot before context compaction so consolidator can absorb the tail.
set -euo pipefail

# Resolve project root (this file lives at .claude/hooks/pre-compact.sh).
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"

MEMORY_FILE="$PROJECT_ROOT/MEMORY.md"
TOPICS_DIR="$PROJECT_ROOT/.claude/memory/topics"
mkdir -p "$TOPICS_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
SNAPSHOT="$TOPICS_DIR/_precompact-$TS.md"

{
  echo "# PreCompact snapshot — $TS"
  echo
  echo "## MEMORY.md at compaction time"
  echo
  if [ -f "$MEMORY_FILE" ]; then
    cat "$MEMORY_FILE"
  else
    echo "_(no MEMORY.md found at $MEMORY_FILE)_"
  fi
  echo
  echo "## Transcript tail (last 200 lines)"
  echo
  # Best-effort transcript location: env var, then a common default.
  TRANSCRIPT="${CLAUDE_TRANSCRIPT:-$HOME/.claude/session.jsonl}"
  if [ -f "$TRANSCRIPT" ]; then
    echo '```'
    tail -n 200 "$TRANSCRIPT"
    echo '```'
  else
    echo "_(no transcript found; checked \$CLAUDE_TRANSCRIPT and $HOME/.claude/session.jsonl)_"
  fi
} > "$SNAPSHOT"

echo "engram: pre-compact snapshot written to $SNAPSHOT" >&2
