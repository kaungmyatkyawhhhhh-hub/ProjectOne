---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.2: AUTOMATION (6 Nov, Claude Code)

Step 2.2 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. Checklist rows: **#50 #55 #94 #417**.

## What's new
- **Ring 2 AUTOMATION branch** (the "each layer automates the last layer's busywork" rule):

  | Node | Shards | Needs | What |
  |---|---|---|---|
  | AUTO-BUY I | 1,000 | Supernova 20 | buys Asteroid + Moon levels for you |
  | LONG NIGHT | 600 | Supernova 17 | offline up to 6 h (was 4) |
  | KEEP RING 1 | 1,500 | Supernova 21 | the 3 tier unlocks stay through a Supernova |
  | AUTO-BUY II | 2,500 | Supernova 23 | buys every other body's levels too |
  | DEEP SLEEP | 1,500 | Supernova 22 | offline 75% (was 50%) |

- **Auto-buy (server):** every tick, the cheapest affordable level of the covered bodies, up to 8 a tick.
  - INFO's button becomes **AUTO: ON / OFF** for the one you own (saved).
  - The Levels quest only counts levels you buy yourself.
- **The moment:** the cutscene template's short beat (4 s, green, the gear) "AUTOMATION ONLINE".
  - It ends on a tease: "NEXT: KEEP RING 1 THROUGH A SUPERNOVA".
  - KEEP RING 1 and AUTO-BUY II get their own titles and teases.
- **Prices + gates PROPOSED, re-priced after the first bot run** (the first prices, 1.5K-5K, were never reached: by minute 55 the bot had 546 shards and the 17th Supernova was 18 min away). Now ~200-500 shards a Supernova after Ignition buys about one node a Supernova.
- **Bot run 2 (the new prices): AUTO-BUY I opens at Supernova 20 = minute 81. The bot did NOT buy it by minute 90**: its BUY ALL takes the cheapest first, so it bought LONG NIGHT + FORGE LUCK (600 each) at minute 81 instead. A player who taps AUTO-BUY I gets it at ~81 min. Flagged in the report (the aim was ~60 min).

## Tests
- Studio test save:
  - Bought AUTO-BUY I; the AUTOMATION ONLINE beat played (screen `2.2-pc-automation-online-cutscene`).
  - The levels bought themselves: income went from 20.1M/s to 39.6M/s within a second (screen `2.2-pc-autobuy-on-income-doubled`).
  - The AUTO switch works.
- **The tree** (built here for all branches, see 2.6) on PC (`2.2-pc-tree-4-branches`) and on the phone after the 2.7 phone fix.
- Bot timing: [[2026-11-06 Galaxy Incremental phase 2 - REPORT]].
- New Studio switches: `TestGiveShards = n`, `TestSetNovas = n`.

## Note
- Auto-buy can spend all your stardust before a pad.
  - Your switch decides that.
