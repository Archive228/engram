#!/usr/bin/env bash
# engram Stop hook. Derived from thedotmack/claude-mem hook shape (Apache-2.0).
# Body rewritten.
#
# Fires the consolidator subagent to fold this session's context into
# MEMORY.md, then warns (non-fatally) if MEMORY.md or .claude/memory/
# still have uncommitted changes.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# 1. Invoke the consolidator subagent to update MEMORY.md.
#    Failure here is logged but never blocks the Stop hook, since
#    a non-zero exit would surface as an error in Claude Code.
if command -v claude >/dev/null 2>&1; then
  claude --agent .claude/agents/consolidator.md </dev/null \
    >/tmp/engram-consolidator.log 2>&1 \
    || echo "engram: consolidator subagent failed (see /tmp/engram-consolidator.log)" >&2
else
  echo "engram: 'claude' CLI not on PATH; skipping consolidator" >&2
fi

# 2. Warn if MEMORY.md or .claude/memory/ have uncommitted changes.
#    We warn rather than fail: the Stop hook must not error out.
if git rev-parse --git-dir >/dev/null 2>&1; then
  if ! git diff --quiet -- MEMORY.md .claude/memory/ 2>/dev/null \
    || ! git diff --cached --quiet -- MEMORY.md .claude/memory/ 2>/dev/null; then
    echo "engram: MEMORY.md has uncommitted changes. Commit before next session." >&2
  fi
fi

exit 0
