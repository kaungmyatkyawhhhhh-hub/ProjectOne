# Token-saving plugins

Tools that make Claude use fewer tokens. Checked 2026-10-10.

## Installed
- **Caveman** ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)): makes Claude's replies shorter. Turned on for cloud sessions on this vault through `.claude/settings.json`.
  - `/caveman`: on. `/ultracave`: even shorter. `/caveman off` or "stop caveman": back to normal.
  - Only shortens chat text. Code is written in full.

## Skipped, and why
- **Claude Mem** ([thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)): saves its memory on the computer it runs on. Cloud sessions are wiped after each session, so it would forget everything. This vault already does the same job.
- **Headroom**, **RTK**, **Codebase Memory MCP**, **Token Optimizer MCP**, **PromptThrift MCP**: only work with Claude Code installed on a PC (the terminal version). I use cloud sessions and the Claude app, so they don't apply. Headroom also mostly saves money for people paying per API call, not on a Claude plan.
- **DensePack**: couldn't find a real, trustworthy project. Skipped.

## To add Caveman to another repo (e.g. ClaudeOne)
Ask Claude in a cloud session on that repo: "add the Caveman plugin to this repo's .claude/settings.json, same as my vault".
