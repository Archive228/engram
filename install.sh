#!/usr/bin/env bash
# engram installer — Copyright (c) 2026 Archive228 MIT.
# Install pattern adapted from thedotmack/claude-mem (Apache-2.0).
set -euo pipefail

REPO_TARBALL="https://codeload.github.com/Archive228/engram/tar.gz/refs/heads/main"
FORCE="${FORCE:-0}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '[engram] %s\n' "$*"; }
die() { printf '[engram] error: %s\n' "$*" >&2; exit 1; }

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
TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t engram)"
trap 'rm -rf "$TMPDIR"' EXIT

say "downloading engram main tarball"
curl -fsSL "$REPO_TARBALL" -o "$TMPDIR/engram.tar.gz" || die "download failed"

say "extracting"
tar -xzf "$TMPDIR/engram.tar.gz" -C "$TMPDIR"
SRC="$(find "$TMPDIR" -maxdepth 1 -type d -name 'engram-*' | head -n1)"
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

# Merge settings.json — prefer jq, fall back to append-with-warning.
SRC_SETTINGS="$SRC/.claude/settings.json"
DST_SETTINGS=".claude/settings.json"
if [ -f "$SRC_SETTINGS" ]; then
  if [ ! -f "$DST_SETTINGS" ]; then
    say "installing .claude/settings.json"
    cp "$SRC_SETTINGS" "$DST_SETTINGS"
  elif command -v jq >/dev/null 2>&1; then
    say "merging hooks into existing .claude/settings.json via jq"
    TMP_MERGED="$(mktemp)"
    jq -s '.[0] * {hooks: (.[0].hooks // {}) * (.[1].hooks // {})}' \
       "$DST_SETTINGS" "$SRC_SETTINGS" > "$TMP_MERGED"
    mv "$TMP_MERGED" "$DST_SETTINGS"
  else
    say "jq not found — writing engram settings alongside existing file for manual review"
    cp "$SRC_SETTINGS" ".claude/settings.engram.json"
    say "review .claude/settings.engram.json and merge its 'hooks' block into .claude/settings.json"
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
