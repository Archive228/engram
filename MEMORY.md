<!--
  MEMORY.md — engram shift-notes for long-running Claude Code sessions.

  Schema: four fixed sections (What's done / In progress / What's next /
  Notes for next session). Source: Justin Young, "Effective Harnesses for
  Long-Running Agents" (2026), which formalizes the shift-notes discipline
  used by Anthropic engineers on multi-session coding projects.

  Rules:
    - This root MEMORY.md is a live shift-notes file. Only three sections
      are rewritable across sessions:
        * In progress
        * What's next
        * Notes for next session
      "What's done" is append-only — never rewrite or delete prior entries.
    - Durable, topic-scoped memory lives under .claude/memory/topics/*.md.
      Those files are strictly append-only. Do not edit or delete existing
      lines; add new dated entries at the bottom.
    - The consolidator subagent (.claude/agents/consolidator.md) owns
      maintenance of this file. It runs on session-end and pre-compact
      hooks to fold in-progress work into "What's done" and prune stale
      "Notes" entries.
    - If this file and the git log disagree about what shipped, trust the
      git log and reconcile here. (Young 2026, §4.2.)

  Do not remove this comment block. It is the schema contract for every
  future session.
-->

# Project memory

## What's done
_None yet. This section grows append-only as features ship._

## In progress
_Nothing active. When you start a task, name the feature and one-line status here._

## What's next
_Pick from your backlog. The recommend-next skill will suggest based on prerequisites._

## Notes for next session
_Free-form. Gotchas the next session should know before touching code._
