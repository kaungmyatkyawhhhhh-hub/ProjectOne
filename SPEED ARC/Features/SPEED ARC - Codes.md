---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M4)
---
# SPEED ARC - Codes

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

- CODES button (left menu) opens SETTINGS: code field + REDEEM, Music ON/OFF, Sounds ON/OFF.
- Launch codes (Config `Retention.Codes.Launch`): **SPEEDARC** = 5 min of coins, **FIRSTRACE** = a coach roll, **RELEASE** = 10 min + a coach roll. Case and spaces don't matter. Each works once per player.
- Live codes are in the DataStore `SpeedArcCodes_v1` (key "list"), re-read every 60 s, so new codes work without publishing.
- Console (live server, F9 > Server):
  - add: `_G.SpeedArcCodes.add("SUMMER", { Minutes = 5, Rolls = 1 })`
  - remove: `_G.SpeedArcCodes.remove("SUMMER")`
  - list: `_G.SpeedArcCodes.list()`
- A reward can have `Minutes`, `Coins`, `Rolls`, `Trail`, `TrainBoost` (seconds), `Expires` (unix time).

## Where it lives
`Server/Services/RetentionService` (codes part), `Client/Controllers/RetentionController` (Settings window).
