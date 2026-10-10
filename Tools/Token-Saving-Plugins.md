# Token-saving plugins

Tools that make Claude use fewer tokens. Set up 2026-10-10 for cloud sessions on this vault (ProjectOne). They load when a new session starts.

## Installed
- **Caveman** ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)): makes Claude's replies shorter.
  - `/caveman`: on. `/ultracave`: even shorter. `/caveman off` or "stop caveman": back to normal.
  - Only shortens chat text. Code is written in full.
- **Claude Mem** ([thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)): memory across sessions. Note: it saves memory on the machine it runs on, and cloud sessions are wiped, so it may not remember between sessions.
- **RTK** ([rtk-ai/rtk](https://github.com/rtk-ai/rtk), version 0.51.0): shortens long command output (like `git status`) before Claude reads it. Installs itself at the start of each cloud session.
- **Codebase Memory MCP** ([DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp), version 0.11.0): builds a map of a codebase so Claude reads fewer files. Most useful on code repos, less on this vault.

## Not installed, and why
- **Token Optimizer MCP**: the package is marked "no longer supported", and it adds 67 tools, which can cost more tokens than it saves.
- **Headroom**: sends all traffic to Claude through itself. If it breaks, cloud sessions stop working.
- **PromptThrift MCP**, **DensePack**: couldn't find a real download.

## Where the setup lives
- `.claude/settings.json`: plugins and the RTK hook
- `.claude/hooks/install-rtk.sh`: installs RTK each session
- `.mcp.json`: Codebase Memory MCP

## To add these to another repo (e.g. ClaudeOne)
Ask Claude in a cloud session on that repo: "copy the token-saving setup from my vault (ProjectOne) into this repo".
