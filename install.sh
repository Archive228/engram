#!/usr/bin/env bash
# memory installer — Copyright (c) 2026 Archive228 MIT.
# Install pattern adapted from thedotmack/claude-mem (Apache-2.0).
set -euo pipefail

REPO_TARBALL="https://codeload.github.com/Archive228/memory/tar.gz/refs/heads/main"
FORCE="${FORCE:-0}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '[memory] %s\n' "$*"; }
die() { printf '[memory] error: %s\n' "$*" >&2; exit 1; }

# Preflight: required tools.
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar  >/dev/null 2>&1 || die "tar is required"

# Backup existing .claude/ unless FORCE=1.
if [ -d ".claude" ] && [ "$FORCE" != "1" ]; then
  BACKUP=".claude.bak-${STAMP}"
  say "existing .claude/ found — backing up to ${BACKUP}/"
  cp -a ".claude" "$BACKUP"
fi

# Fetch tarball into a temp dir.
TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t memory)"
trap 'rm -rf "$TMPDIR"' EXIT

say "downloading memory main tarball"
curl -fsSL "$REPO_TARBALL" -o "$TMPDIR/memory.tar.gz" || die "download failed"

say "extracting"
tar -xzf "$TMPDIR/memory.tar.gz" -C "$TMPDIR"
SRC="$(find "$TMPDIR" -maxdepth 1 -type d -name 'memory-*' | head -n1)"
[ -n "$SRC" ] || die "extracted source dir not found"

# Copy MEMORY.md to project root only if absent.
if [ ! -f "MEMORY.md" ]; then
  say "installing MEMORY.md"
  cp "$SRC/MEMORY.md" "MEMORY.md"
else
  say "MEMORY.md already exists — leaving untouched"
fi

# Copy .claude subtrees into place.
mkdir -p ".claude"
for sub in memory skills agents hooks; do
  if [ -d "$SRC/.claude/$sub" ]; then
    say "installing .claude/$sub/"
    mkdir -p ".claude/$sub"
    cp -a "$SRC/.claude/$sub/." ".claude/$sub/"
  fi
done

# Copy dreaming.sh helper if present.
if [ -f "$SRC/dreaming.sh" ]; then
  cp "$SRC/dreaming.sh" "dreaming.sh"
fi

# Handle settings.json. If DST doesn't exist, copy in place. If it exists
# and is byte-identical to SRC, skip (idempotent). Otherwise, drop SRC
# beside as .claude/settings.memory.json for manual review — we never
# overwrite an existing user settings file.
SRC_SETTINGS="$SRC/.claude/settings.json"
DST_SETTINGS=".claude/settings.json"
if [ -f "$SRC_SETTINGS" ]; then
  if [ ! -f "$DST_SETTINGS" ]; then
    say "installing .claude/settings.json"
    cp "$SRC_SETTINGS" "$DST_SETTINGS"
  elif cmp -s "$SRC_SETTINGS" "$DST_SETTINGS"; then
    say ".claude/settings.json already matches — no change"
  else
    say "existing .claude/settings.json differs — writing ours alongside as settings.memory.json for review"
    cp "$SRC_SETTINGS" ".claude/settings.memory.json"
    say "review .claude/settings.memory.json and merge its 'hooks' block into .claude/settings.json"
  fi
fi

# Make scripts executable.
chmod +x dreaming.sh 2>/dev/null || true
find ".claude/hooks" -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true

say "done."
cat <<'EOF'

Next steps:
  1. Open Claude Code in this directory.
  2. Try: "What do you know about my project?" to see recall in action.
  3. MEMORY.md at the project root is your shift-notes file — edit freely.

EOF
