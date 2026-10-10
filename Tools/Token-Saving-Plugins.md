# Token-saving plugins

Tools that make Claude use fewer tokens. Checked 2026-10-10.

## Installed
- **Caveman** ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)): makes Claude's replies shorter. Turned on for cloud sessions on this vault through `.claude/settings.json`.
  - `/caveman`: on. `/ultracave`: even shorter. `/caveman off` or "stop caveman": back to normal.
  - Only shortens chat text. Code is written in full.

- **Claude Mem** ([thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)): added 2026-10-10 at my request. Note: it saves memory on the machine it runs on, and cloud sessions are wiped, so it may not remember between sessions.

## Not added yet, and why
- **Headroom**, **RTK**, **Codebase Memory MCP**, **Token Optimizer MCP**, **PromptThrift MCP**: only work with Claude Code installed on a PC (the terminal version). I use cloud sessions and the Claude app, so they don't apply. Headroom also mostly saves money for people paying per API call, not on a Claude plan.
- **DensePack**: couldn't find a real, trustworthy project. Skipped.

## To add Caveman to another repo (e.g. ClaudeOne)
Ask Claude in a cloud session on that repo: "add the Caveman plugin to this repo's .claude/settings.json, same as my vault".

## Blocked on 2026-10-10
- RTK, Codebase Memory MCP and Token Optimizer MCP need downloaded code to run in every session. Claude's safety check blocked this. To allow it, I'd have to approve that kind of action in my Claude Code settings.
