---
date: 2026-10-28
tags: [speedarc, feature]
status: done
---
# SPEED ARC - Code and Sync

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- The code lives in this vault: `Games/SpeedArc/src` (so it's backed up on GitHub, not only in Studio: GYM ARC lesson 1).
- Studio gets a copy with the sync step: `tools/serve.bat` serves the folder, `tools/sync.luau` (Studio command bar) writes every script into the place. HTTP is switched on only during the copy.
- Structure: `Shared/Config/*` (every number), `Shared/UIKit`, `Shared/Util/*`, `Server/Services/*Service`, `Client/Controllers/*Controller`. Full list in `Games/SpeedArc/README.md`.

## Studio test switches (Workspace attributes)
`FreshPlayer`, `TestSpeed`, `TestCoins`, `TestRaceNow`, `TestRaceInterval`. Studio only; remove after testing.

## Notes
- This place has no default PlayerModule, so code never waits for it.

## Related
[[SPEED ARC - Player Data and Saving]]
