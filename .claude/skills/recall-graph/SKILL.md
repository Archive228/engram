<!-- Derived from modelcontextprotocol/servers/src/memory (MIT). Full license: LICENSES/mcp-memory-MIT.txt. -->
---
name: recall-graph
description: Optional entity+relation recall for projects that outgrow flat Markdown memory. Wraps a tiny local graph store at .claude/memory/graph.jsonl with verbs create_entities, create_relations, search_nodes.
---

# recall-graph

Use this skill when a project's memory has outgrown flat Markdown — when you need to answer questions like "what depends on the auth module?" or "which components touch the session store?" and grep across `.claude/memory/topics/` no longer scales.

Flat MEMORY.md is the default. Reach for the graph only when relationships between concepts matter more than the prose describing each one.

## Model

- **Node** — an entity. Shape: `{ "kind": "node", "name": "<unique-id>", "type": "<class>", "observations": ["<fact>", ...] }`
- **Edge** — a relation. Shape: `{ "kind": "edge", "source": "<node-name>", "target": "<node-name>", "relation_type": "<verb>" }`

Names are unique across the graph. Types are freeform strings (`module`, `service`, `person`, `decision`, `bug`). Observations are append-only per node — never rewrite, only add.

## Storage

Single file: `.claude/memory/graph.jsonl`. One JSON object per line. Append-only on write. Read via `jq -c`. No indexes, no server — small enough that a full scan is fine up to ~10k lines.

## Verbs

Implemented as `jq` one-liners so the skill has no runtime dependency beyond `jq`.

### create_entities

Append a node. If a node with the same name already exists, merge the new observations into its `observations[]` instead of duplicating.

```bash
# create_entities "auth:module,handles login/logout"
name="auth"; type="module"; obs="handles login/logout"
jq -cn --arg n "$name" --arg t "$type" --arg o "$obs" \
  '{kind:"node", name:$n, type:$t, observations:[$o]}' \
  >> .claude/memory/graph.jsonl
```

### create_relations

Append an edge. Both endpoints should already exist as nodes; if they don't, create them first.

```bash
# create_relations "auth,depends_on,session-store"
src="auth"; rel="depends_on"; tgt="session-store"
jq -cn --arg s "$src" --arg r "$rel" --arg t "$tgt" \
  '{kind:"edge", source:$s, relation_type:$r, target:$t}' \
  >> .claude/memory/graph.jsonl
```

### search_nodes

Find nodes by substring in name, type, or any observation. Also returns edges touching matched nodes so you get the neighborhood, not just the hit.

```bash
# search_nodes "auth"
q="auth"
jq -c --arg q "$q" '
  select(.kind=="node") |
  select(.name|test($q;"i")) or (.type|test($q;"i")) or (any(.observations[]; test($q;"i")))
' .claude/memory/graph.jsonl
```

Follow up with an edge scan on the matched names to walk one hop out.

## When not to use this

- The project has fewer than ~20 remembered topics — grep is faster.
- The relationships are all "X is documented in Y" — that's what topic files are for.
- You want cross-session prose context — that belongs in `MEMORY.md`, not the graph.

The graph is for structural recall. Prose belongs in Markdown.
