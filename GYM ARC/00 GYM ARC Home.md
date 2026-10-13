---
date: 2026-10-13
tags: [gymarc, home]
status: active
---
# GYM ARC Home

Roblox gym game for kids (mostly mobile). Tagline: "Everyone starts tiny." You lift on one-tap machines to grow 18 real muscles. When all 6 muscle groups reach their goal you get a Growth Spurt: you get taller and earn a permanent gains bonus. It also has genetics, titles, spotting, arm wrestling, crews, poses and a beach-side town with a starter gym, a pro gym, a beach gym and a skate park.

- **Studio place:** the cloud place "GYM ARC", owned by the group Myanmar Builders Club. Studio is the source of truth.
- **Code backup:** `C:\Users\kaung\ClaudeOne` (GitHub). Scripts are exported to `src/`. No Rojo.
- **Design brief:** [[2026-10-04 GYM ARC Prompt - Design brief|Design brief]] (repo `docs/DESIGN.md`)
- **Backups:** `Documents\GymArc_backups\GymArc_<date>.rbxl`. After every task: File > Save to Roblox, then File > Download a Copy.

## Current status (13 Oct 2026)
- The whole core game is built and tested in Studio: training, 18 muscles, genetics, Growth Spurts, titles, stats, quests, spotting, arm wrestling, the town and three gyms.
- 13 Oct: Growth Spurts now stop at 7'0" ([[GYM ARC - Growth Spurts]]), the NPC size glitch is fixed ([[GYM ARC - NPC Regulars and Gym Cat]]), and soft shutdown is in ([[GYM ARC - Soft Shutdown]]). See [[2026-10-13 GYM ARC Height cap and soft shutdown]].
- Monetization is OFF; no ids are set yet ([[GYM ARC - Monetization]]).
- Not verified yet: phones on a real device, and anything that needs 2 players (spotting, crews, arm wrestling against a player).

## What's next
1. **Save to Roblox** and make a dated backup, then **publish**. No save is recorded for the 9 and 13 Oct work.
2. Test soft shutdown live: join the game, then use "Migrate to latest update".
3. Run a 2-player test (spotting, arm wrestling, other players' muscles).
4. New prompts, not started yet:
   - [[2026-10-13 GYM ARC Prompt - New features run|New features run]] (Posing Competition, NPC Rivals, Daily Quests and more)
   - [[2026-10-13 GYM ARC Prompt - Monetization and hype|Monetization and hype]] (monetization ON, Aura, music)
5. Pick the sound ids ([[GYM ARC - Music and Sounds]]: 26 slots still reuse another clip).

## Open bugs
All 21 open bugs and engine limits are in [[GYM ARC - Bugs index]]. The main ones:
- [[GYM ARC - Bug - Full look bulkier than lean V-taper|Full look bulkier than the lean V-taper]]
- [[GYM ARC - Bug - Pointed traps and triceps at mass monster|Pointed traps and triceps at mass monster]]
- [[GYM ARC - Bug - Skin pokes through gym fits at mass monster|Skin pokes through gym fits at mass monster]]
- [[GYM ARC - Bug - Rep popup numbers very big|Rep popup numbers very big]]
- [[GYM ARC - Bug - Rep flash hard to see on light skin|Rep flash hard to see on light skin]]
- [[GYM ARC - Bug - High part count on phones|High part count on phones]]

## Links
- [[GYM ARC - Features index|Features]]: one note per system
- [[GYM ARC - Bugs index|Bugs]]: fixed and open
- [[GYM ARC - Config values|Config values]]: every tunable number
- [[GYM ARC - Monetization|Monetization]]: passes, products, badges (ids, prices, status)
- [[GYM ARC - Music and Sounds|Music and Sounds]]: every sound and music slot
- [[GYM ARC - Assets|Assets]]: meshes, textures, images and their ids
- Progress (one note per work session):
  - [[2026-10-04 GYM ARC Full game built overnight]]
  - [[2026-10-05 GYM ARC First playtest fixes]]
  - [[2026-10-06 GYM ARC Overnight run town and muscles]]
  - [[2026-10-07 GYM ARC Muscle meshes UI v7 and genetics]]
  - [[2026-10-08 GYM ARC Place lost and rebuilt]]
  - [[2026-10-09 GYM ARC Spotting menu and Dante]]
  - [[2026-10-13 GYM ARC Height cap and soft shutdown]]
  - [[2026-10-13 GYM ARC Obsidian vault setup]]
- Prompts: the `Prompts` folder (every prompt, saved as it was sent)
- Screenshots: the `Screenshots` folder (copies of the repo's `screenshots/`)
