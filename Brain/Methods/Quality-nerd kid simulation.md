---
tags: [brain, method]
created: 2026-11-09
---
# Quality-nerd kid simulation

**Owner's words:** "use the impatient-kid-sim for the map and quality-nerd-kid-sim too" (9 Nov); goes with "if game look like slop ai game then the game get dislike" (9 Nov).
**Use when:** a map, world or UI will be judged by eye; before any launch (next to the [[Impatient kid simulation]] in the [[Launch gate]]); "does this look cheap / AI-made?"
**Skill:** not yet (offer to make one)

## Steps
1. List what a player sees on the main routes: set pieces per distance, props per view, kit size (unique meshes), ambient life, zone looks/sounds, borders, streaming.
2. Model a picky kid who looks at a view every ~2 s for 10 min. Tells (each counted, repeats matter less): same prop again, empty view 6 s+, things that don't react, pop-in, zones that look the same, invisible walls, placeholder UI. Wows: hand-made set pieces, a zone that looks and sounds different.
3. Run 2,000 kids per version; report tells per 10 min (the number to trust), the top 3 tells, wows, and a like/dislike split.
4. Change ONE thing per version (cumulative); keep what lowers the tells.
5. Goal: under ~3 tells per 10 minutes, no single tell kind above 1.
6. Check by eye too: player-eye screenshots on a phone ([[Reference study]], K06 "never looks like AI slop").

## Tools
- Python; reference code `MEGA BITE/Calc/mapsim.py` (function `nerd`).

## Used on
- 2026-11-09 MEGA BITE map: tells 104 → 1.8 per 10 min (ambient life + a 14-mesh kit, then zone identity + natural borders + streaming) → [[2026-11-09 MEGA BITE - Map plan + kid simulations]]

## Learned
- The like ratio it gives is all-or-nothing; use the tells count.
- Ambient life (fish that scatter, kelp) is the cheapest fix and helps the impatient kid too.
- 2026-11-09 Galaxy Incremental full UI + world scan (by eye + code checks): 5 tells found and fixed (window-backdrop seam line, icons empty on first open, two icon styles, plain toasts, bare banner) → [[2026-11-09 Galaxy Incremental - First 30 seconds + dead-game features built]] section H

## Learned (Galaxy scan)
- Code checks first (fonts, default text/grey, VFX audit, runtime lighting), then a screenshot of EVERY window: the worst tells (a seam line, empty icons) only show by eye.
- Open each window once fresh after joining: assets that load on first sight look broken the first time, which is the time a new player sees them.
