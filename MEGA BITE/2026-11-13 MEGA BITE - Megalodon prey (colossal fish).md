# 2026-11-13 MEGA BITE - Megalodon prey (colossal fish)

Owner 11:14: "put even further ones for megalodon cuz megalodon have no point rn".
Builds on [[2026-11-13 MEGA BITE - Late game v1 (giant prey fish)]]. Nothing is published. Tested in Studio Play, one player, PC.

## What was wrong
The biggest prey (Titan Tuna, 38.6 studs) takes a Megalodon 1.5 bites and a Great White 3. Nothing in the sea was only for
the Megalodon, so reaching it changed nothing.

## What was added
Four colossal fish that ONLY a Megalodon can beat (a Great White would need 7-10 bites, more than `Combat.MaxBites` = 6,
so it sees a padlock). They live in the outermost ring of the Open Sea (THE FAR DEEP, r 930-1200) and in the Red Trench.
| Fish | Length | Base EXP | Megalodon bites | Rarity | Made from |
|---|---|---|---|---|---|
| Emperor Prawn | 60 | 200 | 3.5 | Epic | Shrimp model, gold tint |
| Abyss Squid | 66 | 240 | 4.3 | Epic | Squid model, violet tint (inks) |
| Elder Tuna | 69 | 270 | 4.7 | Legendary | Tuna model, jade tint |
| Thunder Mackerel | 72 | 290 | 5.1 | Legendary | Mackerel model, ice-blue tint |
- EXP is paid on every bite (Combat v1). In the test one Elder Tuna paid +2,160 with the test account's boosts (x2 Open Sea,
  x2 Fossil, x2 pass). Titan Tuna pays 82 base, so these are about 3x the old best.
- Where: `GameConfig.Fish.Species` + `Order` (16 species now), `Pop.Tiers.sea4` (one share each), `Pop.Tiers.trench` and
  `Trench.Fish` (Abyss Squid, Elder Tuna); templates in `MegaBite.Fish`; feat words in `MB_GrindFx`; the Fish Index window is
  476 tall now (four rows of four). Backups `GameConfig_preColossal_13Nov`, `MB_GrindFx_preColossal_13Nov`.
- Checked: all four spawn near a player at r 1040 (2-4 of each), two Elder Tunas and part of an Abyss Squid eaten, Index shows
  14/16 with the two unseen ones as dark shapes, movement audit clean for fish (0 in ground, 0 in props; the audit's
  "predGround 120 / stuck" lines are the four sleeping red hunters parked under the map, not a fault).

## Honest limits
- They are the approved fish models scaled up and tinted, not new models. Real Megalodon-only creatures need design sheets.
- "Even further": they are in the furthest water that exists. The map itself was NOT made bigger: the Red Trench and its
  wall are the edge. A new zone beyond the Trench means regenerating the terrain, the borders, the minimap and the bake.
- The Megalodon still has the same goal as before (Fossilize). These fish make the climb to it faster and give it its own
  hunt; they do not add a new goal.
- The taller Index window is not checked on a phone.
