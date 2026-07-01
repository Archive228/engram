# engram

The memory system Anthropic engineers describe publicly, packaged as a drop-in `.claude/`.

Claude Code sessions are stateless. Every new session starts cold: no idea what the last one shipped, what's half-done, or what to avoid. Anthropic engineers have written about how they solve this internally — Boris Cherny's `CLAUDE.md` docs, Justin Young's shift-notes discipline for long-running agents, Prithvi Rajasekaran's multi-agent handoff pattern, the `managed-agents-memory` skill in `anthropics/skills`, the graph engine in `modelcontextprotocol/servers/src/memory`. The pieces are all public. Nobody has packaged them.

engram is that package. A single `MEMORY.md` at the root of your project, a `consolidator` subagent that merges and prunes at session end, a `dreamer` subagent that runs overnight to promote abstractions, and the hooks that wire it all together. Nothing here is leaked and nothing here is secret — it is the pattern Anthropic engineers describe publicly, assembled into one install.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Archive228/engram/main/install.sh | bash
```

Run it from the root of any project. It backs up your existing `.claude/` to `.claude.bak-<timestamp>/` and drops the engram harness in place.

## What it does

- **MEMORY.md** — durable per-project shift-notes at the root of your repo, in the four-section format from Justin Young's paper: What's done / In progress / What's next / Notes for next session.
- **consolidator subagent** — fires on session end, merges duplicate entries, prunes stale ones, keeps the index tight.
- **dreamer subagent** — runs overnight via `dreaming.sh` (or cron), reads accumulated topic files, and promotes recurring patterns into higher-altitude abstractions.

## What lands in your repo

```
.
├── MEMORY.md                         # root shift-notes
├── dreaming.sh                       # overnight dreamer trigger
├── LICENSES/
│   ├── claude-mem-Apache-2.0.txt
│   └── mcp-memory-MIT.txt
├── NOTICE                            # donor credits
└── .claude/
    ├── settings.json                 # hooks + skill wiring
    ├── memory/
    │   ├── index.md                  # topic index
    │   └── topics/                   # append-only per-topic notes
    ├── skills/
    │   ├── remember/SKILL.md         # write to memory
    │   └── recall-graph/SKILL.md     # graph-based recall
    ├── agents/
    │   ├── consolidator.md           # session-end merger
    │   └── dreamer.md                # overnight abstractor
    └── hooks/
        ├── session-start.sh          # loads MEMORY.md into context
        ├── session-end.sh            # fires consolidator
        └── pre-compact.sh            # snapshots before compaction
```

## How it works

The flow across a session, in six steps:

1. **SessionStart hook** — `.claude/hooks/session-start.sh` reads `MEMORY.md` and any relevant topic files under `.claude/memory/topics/` and injects them as context. Claude opens the session already knowing what the last one shipped.
2. **remember skill** — invoked before code touches. When Claude learns something worth persisting (a decision, a gotcha, a naming convention), the `remember` skill writes it to the appropriate topic file.
3. **User turn** — the session proceeds normally. Claude has memory the same way you do: consulted when relevant, not narrated.
4. **PreCompact hook** — before Claude Code compacts the conversation, `.claude/hooks/pre-compact.sh` snapshots the current in-progress state into `MEMORY.md` under **In progress**, so compaction never eats the shift notes.
5. **Stop hook fires consolidator** — on session end, `.claude/hooks/session-end.sh` launches the `consolidator` subagent. It merges duplicate entries, moves completed items from **In progress** to **What's done**, prunes stale **What's next** items, and updates the topic index.
6. **Dreamer runs out-of-band** — `dreaming.sh` (invoke manually, wire to launchd/cron, or run before bed) launches the `dreamer` subagent against the accumulated topic files. Recurring patterns get promoted into higher-altitude abstractions in the index. Contradictions get flagged. This is the piece that turns a growing pile of notes into something searchable.

The design constraint throughout: the root `MEMORY.md` is the shift-notes file and only its **In progress** / **What's next** / **Notes** sections are rewritable. Topic files under `.claude/memory/topics/` are append-only. The consolidator and dreamer edit the index and rewrite abstractions; they do not rewrite history.

## Prior art & receipts

engram is a packaging job. Everything in it comes from patterns that Anthropic engineers, the MCP team, or the Claude Code community have already put in public. Receipts:

- **Boris Cherny** — the Claude Code docs on `CLAUDE.md` as the project-memory file, and the design intent that made it the canonical spot for durable per-project instructions. engram's root `MEMORY.md` is the shift-notes cousin of `CLAUDE.md`: same location conventions, different lifecycle.
- **Justin Young — "Effective Harnesses for Long-Running Agents" (2026)** — the four-section shift-notes schema (What's done / In progress / What's next / Notes for next session), the "trust the git log when the progress file disagrees" rule, and the eval data showing incremental sessions outperform single long-context runs. The MEMORY.md format in engram is the format from that paper.
- **Prithvi Rajasekaran** — the planner / generator / evaluator three-agent architecture. engram's consolidator and dreamer are the same idea applied to memory: one subagent does the work, another one runs later with a different prompt to check and abstract.
- **`anthropics/skills` — `managed-agents-memory`** — the concept of memory as a first-class skill that a subagent can be handed. engram's `remember` and `recall-graph` skills follow that shape: YAML frontmatter, self-contained, invokable by any agent in the session.
- **`modelcontextprotocol/servers/src/memory`** — the reference graph-engine memory server. `recall-graph` in engram is the SKILL.md-shaped analog of that server, so the same retrieval story works without running a separate MCP process.
- **Claude Code issues [#27298](https://github.com/anthropics/claude-code/issues/27298) and [#14227](https://github.com/anthropics/claude-code/issues/14227)** — both closed-not-planned, both asking for durable per-project memory. engram is the community answer while the product team decides what to ship.

Nothing above is a leak. It is what the people building Claude Code have described in public. engram is what happens when you take them at their word and wire it together.

## Attribution

engram borrows install-pattern shape and hook conventions from prior work. Full credits in [`NOTICE`](./NOTICE); full license texts under [`LICENSES/`](./LICENSES/).

- **[thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)** — Apache-2.0. Install pattern, hook shape, and `settings.json` layout are derived from this project. All specific text has been rewritten; the structural conventions are theirs.
- **[modelcontextprotocol/servers — `src/memory`](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)** — MIT. The graph-engine concept behind the `recall-graph` skill comes from this reference server. engram's implementation is a SKILL.md-shaped port; the retrieval model is theirs.
- **[anthropics/skills — `managed-agents-memory`](https://github.com/anthropics/skills)** — concept only, referenced not lifted. The idea of memory as a skill handed to a managed subagent is theirs.

If you ship something built on engram, please carry the `NOTICE` file forward.

## Uninstall

The installer backs up your prior `.claude/` before overwriting anything. To restore:

```bash
# find the most recent backup
ls -1d .claude.bak-* | tail -n 1

# restore it (replace <timestamp> with the one you want)
rm -rf .claude
mv .claude.bak-<timestamp> .claude

# and if you don't want the root files either
rm -f MEMORY.md dreaming.sh NOTICE
rm -rf LICENSES
```

engram writes only to `.claude/`, `MEMORY.md`, `dreaming.sh`, `NOTICE`, and `LICENSES/` at the project root. It never touches anything outside the project directory and it never edits your git config.

## Contributing

Issues and PRs welcome at [github.com/Archive228/engram](https://github.com/Archive228/engram). Particularly interested in:

- MEMORY.md schema drift reports from real long-running projects (what fields you added, what you cut)
- consolidator prompts that outperform the shipped one on your workload
- dreamer output samples where the abstraction was clearly wrong or clearly great — both are useful
- hook shapes for Claude Code releases newer than the one this was built against

Please keep PRs small and scoped. One change per PR.

## License

MIT. See [`LICENSE`](./LICENSE).

Donor licenses (Apache-2.0 for claude-mem, MIT for the MCP memory server) are preserved verbatim under [`LICENSES/`](./LICENSES/) and credited in [`NOTICE`](./NOTICE).
