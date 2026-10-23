---
date: 2026-10-22
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Prompt 47 run (boosts bar, icons, Agency, Trainers, Pump Shop, Pro machines)

[[2026-10-22 GYM ARC Prompt - 47 Boosts bar, new icons, Agency, Trainers, Pump Shop, Pro machines]]

No uploads needed: the owner put every picture in the Myanmar Builders Club group himself (10 boost icons, 16 trainer portraits, evo_* and hex_* backgrounds), and imported the sneaker mesh into `GearMeshes.Sneaker`.

## Checklist
- [x] 2 New boost icons: `Config/Boosts.Art` (all 10, group images) used everywhere an item's icon shows (boost row, hotbar, Inventory, shops, streak rewards, toasts, quest reward popup). Without a new icon (they keep their line icon): Endless Stamina, Server Boost, Rush Hour, Max Boost, the old smoothie drinks. (commit 1b7b8cb)
- [x] 1 Active boosts row bottom-left (`ActiveBoostsClient`): 50 px tiles, timer (red + pulsing under 1 min), "x2" when stacked, longest first, 5 + "+3", hover / tap info card (icon, NAME, gold effect pill, "14:52 left · 2 stacked"), pop-in sparkle, shrink away. The old chip row above the stamina bar is hidden. (commit 1b7b8cb)
- [x] 3 Trainer Agency + MY TRAINERS: your portraits and evo / hex backgrounds wired (`Config/Trainers` Portraits + StageArt), one tile everywhere with a highlight running round the border; Agency slots = the tile in rarity colors (silhouette until owned, ??? for Secret / Eternal, gold check, chance); pity bar + ROLL / X3 / AUTO to the mockup (fixed a bug: the big labels had lost their position), AUTO green when on; MY TRAINERS: EQUIPPED / OWNED pills, name + rarity + gold LV, stat pills, evolve bar, gold EVOLVE, quiet EQUIP; empty state NO TRAINERS YET + red GO TO TRAINER AGENCY (fade + teleport, 10 s). Pictures preload at join. (commit a637d26)
- [x] 4 New shop panel (Coach Dex, PUMP SHOP, coconut stand): Store-style tiles (big new icon on a glow, name, gold effect pill, green price / NEED X MORE / gold OWNED / AT COACH DEX), Champion gear's gold running border, a detail strip with BUY x1 / x5 etc.; buying: coins count down, the item flies into Inventory. (commit f81c9f6)
- [x] 5 Pro machines + owner's request: the Pro Gym is ONE hall (the middle wall is gone; its sign, mirror, TVs, speakers and lockers moved to the new east wall). EVERY machine in the Pro Gym (32) has the PRO look: black satin frame, gold handles / pins / caps, chrome bars, black leather pads with gold stitching, diamond plate feet, a black + gold PRO badge, a gold underglow + light; gold plates; "PRO" in gold before the name on the sign. Starter machines unchanged. (commit 4a1e6db)
- [x] Extra: your sneaker mesh (`GearMeshes.Sneaker`): flattened to one model of named pieces, it now shows on every foot.

## Not matched / notes
- Uploads: none (all pictures were already in the group).
- The Legendary reveal's escalating build-up (prompt 27's full version) is still the trimmed reveal (card flip + rarity color + sound), now with the full-body portrait.
- A LIMITLESS trainer's own boost shows uncapped in MY TRAINERS (e.g. +2424%); the total still caps at +400% per kind.
- The Agency tiles don't show the stage effects (rarity colors only), as the prompt asks.
