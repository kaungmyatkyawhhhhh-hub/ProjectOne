---
tags: [mega-bite, kraken, giants, titan-sea, build-log]
date: 2026-11-13
---
# MEGA BITE - The Kraken is the late-game boss (Titan Sea)

Owner 13 Nov 15:08: "it is suppose to be a late game boss" (after [[2026-11-13 MEGA BITE - Kraken x2.75]]).
Based on: [[2026-11-13 MEGA BITE - Bigger sea, landmarks and giant creatures (plan)]] (the Kraken was planned as a world event for
everyone in the Glow Gardens, small sharks on the tentacle tips) and [[2026-11-13 MEGA BITE - The Titan Sea (bigger map)]]
(the Titan Sea is the "even further" place for the Megalodon, but had no giant of its own yet). Decided without asking (owner rule).

## Decisions
- **Where:** its pit moved from the Glow Gardens (-790, 180) to the TITAN SEA, west side, (-2120, 180) (r 2128; the Titan's
  Gate is on the east side). The shelf there is about -54, the same depth as before, so the size and rise are unchanged
  (660 studs, mantle through the surface). Bright gold sand, giant props around it: it stays in the "never dark" rule.
- **Who:** `Kraken.MinEvo = 7` (Megalodon and bigger). Smaller sharks can't hurt it: their bites are ignored on the server,
  and the client shows "Too small to hurt the Kraken! Evolve to MEGALODON" and the bar hint "TOO SMALL! ONLY MEGALODONS AND
  BIGGER CAN HURT IT". Slams still knock them back (never a kill).
- **When:** it only rises while a MinEvo+ player is in the server (otherwise it checks again in 20 s). First 6 min, then every
  10 min (Saturday x2) as before.
- **Who hears about it:** the rise toast, the horn and the red minimap dot are for Megalodon+ players. Smaller players get a
  quiet goal toast instead: "The Kraken is rising in the Titan Sea... only MEGALODONS can fight it!" (something to grow
  towards, without pulling small sharks across the PvP trench). "Beaten / sank" toasts: big players, or anyone near.
- The spawn-reef KRAKEN SATURDAY sign now says "in the TITAN SEA".

## Built (Studio)
- GameConfig: `Kraken.Site = (-2120, -54, 180)`, `UpY -80`, `SunkY -402`, `MinEvo = 7`; `World.Arenas[1].pos = (-2120, 0, 180)`.
- MB_GiantsServer: rise only with a big shark in the server; bites from Evo < MinEvo ignored.
- MB_Giants (client): `big()` gate for toasts, horn, map dot, bites; the bar hint follows your size live.
- Terrain: old pit refilled with `MB_WorldGen.write(-1024, -640, {0, 384})` (natural seabed back); new pit dug (FillCylinder
  r 112, rim bevel r 126). Lair rocks and glow mushrooms moved with it (same height above the floor).
- MB_TitanDress: now keeps `World.Arenas` clear; re-run (2,205 props, 0 in the arena). MB_WorldDress re-run (3,305 props;
  the old pit area is dressed again). MB_WorldBake re-run (14.2 s).
- World map v3: pit drawn at the new place, props re-exported from the live map (`UI\map_art\v3\`, `worldmap_render_v3.py`,
  `clusters_v3.json`). Tiles (Approved): 00 129354522969190, 01 76181550324926, 10 84279543656804, 11 73694853529357.

## Play test
- Clownfish alone: the Kraken does not rise. Clownfish during a fight: 0 damage to it, the "too small" toast shows.
- Megalodon: bites work (HP 0.85 -> 0.70 in 6 s), slams, sink. 0 server and 0 client errors. Test account EXP restored.

## Backups (ServerStorage)
GameConfig_, MB_Giants_, MB_GiantsServer_, MB_TitanDress_, MB_UpdateSign_, MB_WorldMap_, MB_KrakenPit_ (all `_preLateKraken_13Nov`),
terrain `MB_TerrainBackup_OldKrakenSite_13Nov`, `MB_TerrainBackup_NewKrakenSite_13Nov`.

![[kraken_titan_sea.jpg]]
![[kraken_too_small.jpg]]
