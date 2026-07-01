---
name: remember
description: Read the project's persistent memory (MEMORY.md + .claude/memory/) before touching code or answering from prior context. Invoke at the start of a task, before any bash command, or when the user asks about anything you've discussed before.
---

# remember

You have no memory of previous sessions. Everything you need to know about this project is on disk. Read it before you act.

## When to invoke

- At the very start of every task, before any tool call.
- Before running any bash command that touches project state.
- When the user references something you "already know," "discussed," "decided," or "did last time."
- When the user's request names a component, module, or concept you have not seen this session.

## Protocol

Follow these steps in order. Do not skip any.

1. **Read root MEMORY.md verbatim.** Run `cat MEMORY.md` from the project root. This is the shift-notes file — it contains What's done, In progress, What's next, and Notes for next session. Treat it as ground truth for current project state.

2. **Read the topic index.** Run `cat .claude/memory/index.md`. This lists every topic file under `.claude/memory/topics/` with a one-line summary. Use it to decide which topic files are worth opening.

3. **Grep topic files for terms in the current request.** Extract the salient nouns from the user's message (component names, feature names, file paths, error strings, proper nouns). For each, run `grep -l -i "<term>" .claude/memory/topics/*.md` and read every file that matches. If nothing matches, skip.

4. **Synthesize.** In your own head (not out loud), reconcile what the memory says with what the user is asking. If MEMORY.md and the topic files disagree, trust the more recent timestamp. If memory and the git log disagree, trust the git log.

5. **Proceed fully informed.** Only now begin the actual task. If memory made the request trivial or already-answered, say so and cite the file.

## Rules

- Never edit memory files from this skill. Writing is the `consolidator` agent's job.
- Never skip step 1 because MEMORY.md "looked short last time." It is rewritten every session.
- If any of the memory files are missing, note it and continue — the project may be pre-consolidation.
