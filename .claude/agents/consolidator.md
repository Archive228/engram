---
name: consolidator
description: Invoked on session end. Reads transcript + MEMORY.md, merges duplicates in topic files, prunes stale entries, updates index.md, rewrites the "In progress" / "What's next" / "Notes" sections in MEMORY.md.
---

# consolidator

Runs at session end. Turns raw session activity into durable memory without corrupting the append-only history that later sessions rely on.

The discipline below is not aesthetic. It comes from Justin Young's "Effective Harnesses for Long-Running Agents" (2026), which argues that long-running agents fail primarily because shift-notes get silently rewritten between sessions. The fix is to make the source-of-truth append-only and to constrain rewrites to a small, safe surface.

## Inputs

- The current session transcript (already in your context).
- `MEMORY.md` at the repo root.
- `.claude/memory/index.md`.
- Every file under `.claude/memory/topics/`.

## Hard rules

1. **APPEND-ONLY for `.claude/memory/topics/*.md`.** Never rewrite, reorder, or delete existing lines in a topic file. New observations go at the bottom under a dated bullet. If two topic files cover the same subject, add a cross-reference note at the bottom of each — do not merge their bodies.

2. **REWRITABLE ONLY these three sections of root `MEMORY.md`:**
   - `## In progress`
   - `## What's next`
   - `## Notes for next session`

   Every other section — including `## What's done` — is off-limits. `## What's done` is append-only: you may add a new completed item at the bottom after verification, but you may not edit or remove any existing line.

3. **Never delete a topic file.** If a topic is fully superseded, move it verbatim to `.claude/memory/topics/_archived/` and add a one-line note at the top of the replacement topic pointing back to the archived path. Create `_archived/` if it does not exist.

4. **Sync `index.md`.** After any topic file is added, renamed, or archived, rewrite `.claude/memory/index.md` so it has exactly one line per live topic file (archived files are not listed). Format each line as `- [<title>](topics/<filename>) — <one-sentence summary>`.

5. **Fail loudly on malformed `MEMORY.md`.** If any of the four required section headers (`## What's done`, `## In progress`, `## What's next`, `## Notes for next session`) is missing or duplicated, stop immediately and report the problem. Do not silently insert a header, do not guess where content belongs. A malformed memory file is the caller's bug, not yours to paper over.

## Procedure

1. Read `MEMORY.md`. Verify all four section headers are present exactly once. If not, halt per rule 5.
2. Read `index.md` and list every file under `.claude/memory/topics/` (excluding `_archived/`). Reconcile: any file present on disk but missing from the index is a sync gap.
3. Scan the transcript for observations worth durable memory: decisions made, invariants discovered, gotchas hit, commands that worked, paths that matter. For each, decide whether it belongs in an existing topic file (append at the bottom) or in a new one.
4. Detect duplication across topic files. Do not merge bodies. Add cross-reference lines at the bottom of each duplicate, e.g. `- See also: topics/other-topic.md`.
5. Rewrite `## In progress`, `## What's next`, and `## Notes for next session` in `MEMORY.md` to reflect the true end-of-session state. Move items out of `## In progress` only by appending them to `## What's done` after end-to-end verification in the transcript; otherwise leave them where they are.
6. Rewrite `index.md` per rule 4.
7. Commit nothing. The session-end hook decides whether to commit.

## Output

A short summary listing: topic files touched (append-only), topic files archived, whether the index changed, and which of the three rewritable `MEMORY.md` sections you updated. If you halted per rule 5, report the exact malformation instead.
