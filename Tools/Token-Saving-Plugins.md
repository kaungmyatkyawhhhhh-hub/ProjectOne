# Token-saving plugins

Tools that make Claude use fewer tokens. Set up 2026-10-10 for cloud sessions on this vault (ProjectOne). They load when a new session starts.

## Installed
- **Caveman** ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)): makes Claude's replies shorter.
  - `/caveman`: on. `/ultracave`: even shorter. `/caveman off` or "stop caveman": back to normal.
  - Only shortens chat text. Code is written in full.
  - **Problem (2026-10-10):** in a new cloud session `/caveman` didn't work. The plugin is listed in settings but didn't actually install. RTK and Codebase Memory did load. Until fixed, just say "talk caveman" and Claude will copy the style by hand.
- **Claude Mem** ([thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)): memory across sessions. Note: it saves memory on the machine it runs on, and cloud sessions are wiped, so it may not remember between sessions.
- **RTK** ([rtk-ai/rtk](https://github.com/rtk-ai/rtk), version 0.51.0): shortens long command output (like `git status`) before Claude reads it. Installs itself at the start of each cloud session.
- **Codebase Memory MCP** ([DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp), version 0.11.0): builds a map of a codebase so Claude reads fewer files. Most useful on code repos, less on this vault.

- **Claude Code Setup** (`claude-code-setup@claude-plugins-official`, added 2026-10-31 from a TikTok the owner sent): scans the project and suggests skills, hooks, MCP servers and subagents for the work you repeat. Run it by asking "set up Claude Code for this project". Enabled in `.claude/settings.json`. If it doesn't load, type `/plugin install claude-code-setup@claude-plugins-official`.

## Not installed, and why
- **OmniRoute** (from the same TikTok, 2026-10-31): it doesn't give more Claude. It swaps Claude for other free AI models through a local gateway, which are much weaker at game code, send the vault and code to unknown third-party companies, and need Claude Code's connection settings changed (it can break sessions).
- **Token Optimizer MCP**: the package is marked "no longer supported", and it adds 67 tools, which can cost more tokens than it saves.
- **Headroom**: sends all traffic to Claude through itself. If it breaks, cloud sessions stop working. (Asked again 2026-10-31 from a TikTok: still skipped.)
- **PromptThrift MCP**, **DensePack**: couldn't find a real download.

## Where the setup lives
- `.claude/settings.json`: plugins and the RTK hook
- `.claude/hooks/install-rtk.sh`: installs RTK each session
- `.mcp.json`: Codebase Memory MCP

## To add these to another repo (e.g. ClaudeOne)
Ask Claude in a cloud session on that repo: "copy the token-saving setup from my vault (ProjectOne) into this repo".
