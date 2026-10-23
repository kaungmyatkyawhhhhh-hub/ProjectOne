---
date: 2026-10-19
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 6 Install Graphify

```text
Set up Graphify (code knowledge graph, pip package "graphifyy" with two y's, site graphify.com) so you search a map of the code instead of opening lots of files.

1. Check first: confirm the package is the real one (graphify.com docs / its GitHub), and tell me if it sends code anywhere or needs an API key. If anything looks unsafe, stop and tell me.
2. Install on this PC (Windows): install uv if it's missing, then
   uv tool install graphifyy
   graphify install --project      (repo-local, in C:\Users\kaung\ClaudeOne\.claude\)
   If "graphify" isn't found: uv tool update-shell, then a new terminal.
3. Build the graph ONLY for the code backup: run it on C:\Users\kaung\ClaudeOne\src (not Downloads, not the Obsidian vault, not the muscle/mesh folders). Output goes to graphify-out\.
4. Keep it fresh: after every script export to src/, run "graphify update src" (it only re-reads changed files, no API cost). You can also add "graphify hook install" so git updates it on commit.
5. Add graphify-out/graph.html to .gitignore (keep GRAPH_REPORT.md and graph.json).
6. Add 2 lines to CLAUDE.md under "What to read, and when":
   - "To find code: query the Graphify graph (graphify-out/) first, then open only the files it points to."
   - "After exporting scripts to src/, run graphify update src."
7. Tell me: how long the build took, how big the graph is, and test it on one real question (e.g. "where is the crew tag checked?") and compare how many files you had to open with vs without it.
Commit.
```
