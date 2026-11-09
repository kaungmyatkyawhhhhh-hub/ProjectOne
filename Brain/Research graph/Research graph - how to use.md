---
tags: [brain, graph, graphify]
created: 2026-11-09
---
# Research graph (Graphify) - how to use

Back to [[00 BRAIN]] · Owner (9 Nov): "do on roblox playbook/research notes".
Built with Graphify 0.9.104 from the 52 notes in `Roblox Playbook/Research notes` (~114K words): **625 concepts, 874 links, 48 topic groups** (84% links taken straight from the notes, 16% inferred).

## What's here
- `wiki/index.md` → [[index]]: the entry point. One short article per topic group (thumbnails, UI/sound, incremental maths, updates, VFX, trends, policy, money, analytics...), each listing its concepts and which note they came from. **Claude reads this first instead of the big notes.**
- `GRAPH_REPORT.md` → [[GRAPH_REPORT]]: the hub concepts, surprising connections between notes, and suggested questions.
- `graph.html`: the interactive map. Open it in a browser (double-click the file in Windows Explorer).
- `graph.json`: the data for the `graphify query` command.

## How Claude uses it
1. Read the matching wiki article (a few hundred words) to find which concepts and source notes answer the question.
2. Open only those source notes (and only the section needed).
- Measured: a graph lookup costs ~1,600 tokens vs ~42,000 for reading the notes' summaries naively (about **25× less**). The full notes are ~150K tokens.
- The graph holds names + links, not the full details: the details always come from the source note.

## Keeping it fresh
- When new research notes are added, rebuild: `graphify update` only re-reads changed notes, but this first build's cache stayed in the cloud workspace, so the next run re-reads everything (~800K tokens, about 5 helpers × 2-5 minutes). Rebuild about once a month, or after a big research batch.
- Known weak spot: 5 big notes (Logos, Monetization, Names and descriptions, Onboarding/retention, Optimization) came out with few links to the rest; their content is still in the K notes.

## The coloured graph (separate vault)
- Colours come from Graphify's **Obsidian export**: one note per concept (673 notes) tagged `#community/<topic>` + colour groups in its own `.obsidian/graph.json`. It's kept as a SEPARATE vault so the 673 notes don't clutter the main vault's search and graph.
- File: `Research Graph vault.zip` (this folder). Extract it to `C:\ObsidianOne\` → Obsidian → Open folder as vault → `C:\ObsidianOne\Research Graph` → Graph view. It also has `graph.canvas`.
- Rebuilds replace the zip; extract again over the old folder.
