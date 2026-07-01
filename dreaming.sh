#!/usr/bin/env bash
# engram dreaming.sh — trigger the dreamer subagent to consolidate topic files into MEMORY.md notes.
#
# Runs the overnight dreamer agent (see .claude/agents/dreamer.md) which reads
# append-only topic files under .claude/memory/topics/, promotes durable facts
# into MEMORY.md's "Notes for next session" section, and archives digested
# topics into .claude/memory/topics/_archived/.
#
# Intended for manual invocation or a nightly cron.

set -euo pipefail

# Resolve project root (directory containing this script).
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Ensure the Claude Code CLI is available.
if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not found in PATH." >&2
  echo "install Claude Code from https://claude.com/claude-code and retry." >&2
  exit 1
fi

# Ensure the dreamer agent file exists before invoking.
DREAMER_AGENT=".claude/agents/dreamer.md"
if [[ ! -f "$DREAMER_AGENT" ]]; then
  echo "error: dreamer agent not found at $DREAMER_AGENT" >&2
  echo "re-run install.sh or restore the engram .claude/ tree." >&2
  exit 1
fi

# Invoke the dreamer subagent. The Claude Code CLI accepts --agent PATH to
# run a specific agent file non-interactively.
claude --agent "$DREAMER_AGENT"

echo
echo "Dreamer done. Diff MEMORY.md and .claude/memory/topics/_archived/ to see promotions."
echo
echo "Suggested crontab (runs every night at 03:00):"
echo "# 0 3 * * * cd $PROJECT_ROOT && bash dreaming.sh >> .claude/memory/_dream.log 2>&1"
