# Ponytail (index)

Skill/plugin pack for AI coding agents: "lazy senior dev" mode. Smallest change that fully solves the task. Source: https://github.com/DietrichGebert/ponytail (MIT). Claims ~-53% code, -45% tokens (author's own benchmark, unverified).

## Status
- Installed as Claude Code plugin `ponytail@ponytail` v5.3.3, user scope (2026-11-16).
- Hooks (need `node`): SessionStart, SubagentStart, UserPromptSubmit inject the rules each turn. `ponytail-band-import.js` spawns a background process on prompts and reads local transcripts; not audited.
- Remove: `claude plugin uninstall ponytail@ponytail`

## Commands
`/ponytail lite|full|ultra`, "stop ponytail" / "normal mode" to turn off.

## Skill files (copied from repo)
- [[ponytail]] core rules
- [[ponytail-audit]] whole-repo audit
- [[ponytail-review]] change review
- [[ponytail-debt]] list `shortcut:` comments
- [[ponytail-gain]] benchmark savings
- [[ponytail-help]] quick reference
