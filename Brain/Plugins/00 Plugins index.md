---
tags: [brain, plugins]
updated: 2026-11-17
---
# Plugins index (Brain/Plugins)
Back to [[00 BRAIN]] · see also [[00 Skills index]]. Each folder is a copy of one installed Claude plugin (`.claude-plugin/plugin.json`, `skills/`, `commands/`, hooks). Same rule as skills: when a plugin is added or updated, copy it here in the same turn and update this index.

| Plugin | Version | What it does | Skills / commands |
|---|---|---|---|
| firecrawl | 1.0.9 | Scrape, search, crawl and map the web with one command. | [[Plugins/firecrawl/skills/firecrawl/SKILL\|firecrawl]], agent, crawl, developer-index, download, interact, map, monitor, parse, research-index, scrape, search · `/skill-gen` |
| caveman | 1.3.2 | Short, direct answers: answer or code first, no filler. | [[Plugins/caveman/skills/caveman/SKILL\|caveman]] · `/caveman` |
| headroom | 1.3.2 | Work with huge logs, docs, JSON and CSV without filling the context: outline first, read only what matters. | [[Plugins/headroom/skills/headroom/SKILL\|headroom]] · `/peek` |
| ponytail | 5.3.3 | Lazy senior dev mode: smallest complete change. Also audit, review, debt, gain, help. | [[Plugins/ponytail/skills/ponytail/SKILL\|ponytail]] and ponytail-* (also in [[00 Skills index]]) |

The owner's own Roblox skills (kid sims, roblox-*, video, etc.) live in `Brain/Skills/`, not here.

## Log
- 2026-11-17: created. Copied firecrawl, caveman, headroom (synced from claude.ai) and ponytail 5.3.3 (core files only: plugin.json, skills, commands, hooks, README; the 13 MB of other-editor configs, benchmarks and docs were left out).
