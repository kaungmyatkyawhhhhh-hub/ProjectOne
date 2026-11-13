---
tags: [mega-bite, kraken, giants, build-log]
date: 2026-11-13
---
# MEGA BITE - Kraken x2.75 (13 Nov 2026)

Owner: "kraken should be 5x bigger than dunkleosteus".

## What changed
- GameConfig `Kraken`: `Scale = 2.75`, Length 240 -> 660 (5x the Dunkleosteus), UpY -78, SunkY -400, JoinRange 715, SlamRadius 52, SlamMin 126, SlamMax 275, CalmRange 630, MantleR 115, MantleH 200, ArmR 50, ArmLen 231.
- Arena `C.World.Arenas[1].r` 150 -> 300 (no props, no predator homes or patrols inside).
- Template `Creatures.Kraken` scaled 2.408 -> 6.623 (bbox 660 x 230 x 243).
- `MB_Giants` (client): `KS = KR.Scale` scales the pit, bubbles, light pillar, light range, body bob/shake, camera cutoff, slam sound/shake ranges, arm bite band, rise shake, death shockwave. HP bar shows within max(430, JoinRange+100).
- `MB_GiantsServer`: slam vertical tolerance 48 x max(1, Scale x 0.6).
- Terrain: pit hole widened to r 112 (FillCylinder Air at (-790,-106.5,180)), rim bevel r 126. Dark/Murk discs 228 x 228. Lair rocks moved to r ~180 (x1.9), glow mushrooms to r 277 (x1.7). WorldDress + WorldBake re-run (0 meshes inside r 300; 3 small corals at r 293-299 left, harmless).
- Design choice: the sea at the pit is only ~130 studs deep, so the Kraken's arms lie over the seabed and its mantle rises up THROUGH the surface (to about +200). It reads as a giant from far away.

## Play test (13 Nov)
- Rise, fight, slams (red rings at r ~146 under the player), bites (+700 EXP, HP bar falls), sink: all work. 0 server and 0 client errors.
- Slams took the test shark to 2 HP; nothing else changed.

## Backups (ServerStorage)
MB_Kraken_preBig_13Nov, MB_KrakenPit_preBig_13Nov, GameConfig_preBigKraken_13Nov, MB_Giants_preBigKraken_13Nov, MB_GiantsServer_preBigKraken_13Nov, terrain MB_TerrainBackup_KrakenBig_13Nov.

![[kraken_x2_75_fight.jpg]]
![[kraken_x2_75_rise.jpg]]
