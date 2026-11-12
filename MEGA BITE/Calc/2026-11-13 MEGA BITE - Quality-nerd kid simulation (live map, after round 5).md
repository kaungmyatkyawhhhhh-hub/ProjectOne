# 2026-11-13 MEGA BITE - Quality-nerd kid simulation (live map, after round 5)

Method: vault `Brain\Methods\Quality-nerd kid simulation.md`. This time measured on the LIVE map in Studio, not the plan (code: `MEGA BITE\Calc\nerd_live.lua`).
How: a kid swims at ~16 studs/s 14 studs above the floor (raycast), looks every 2 s. "In view" = map meshes within 70 + 2.5 x size studs in a ~125 deg cone ahead; the kid notices about a third of them. Tells as in the method (same mesh 9+ times in the last 40 noticed props, 6 s+ of an empty view); a WOW = a set piece (40+ studs) coming into view after 8 s+ without one.

## What the live map is made of
- 11 unique meshes (Boulder_Round, Spire, Boulder_Flat, Starfish, Kelp, BubbleCoral, TableCoral, BranchCoral, SeaPalm, SeaFan, BrainCoral), 65-77 mesh + colour variants. 3,064 visible mesh parts. Streaming on; `MB_Cull` hides small far pieces.
- Reef (r < 300): mixed kit, 38 props per view.
- Open Sea + trench ring (r 300-1100): 2,550 parts, but dominated by SeaFan 565, Kelp 508, BranchCoral 359, BrainCoral 330, BubbleCoral 323 (1,666 of them are TrenchFlora). TableCoral 25, SeaPalm 20, Starfish 29.
- Ambient life: fish schools that flee, the manta, kelp sway, bubble streams, marine snow, the new current rings. Zones look and sound different (reef bright, Open Sea darker, trench red-violet). Natural borders (spires and boulders), no invisible walls seen.

## Results (one 10-minute swim: 2 min reef, 5 min Open Sea, 3 min outer ring)
| Stretch | props / view | same-prop tells | empty-view tells | set-piece wows |
|---|---|---|---|---|
| Reef, 2 min | 37.8 | 8 | 0 | 4 |
| Open Sea, 5 min | 15.6 | 38 | 0 | 1 |
| Outer ring, 3 min | 10.2 | 19 | 0 | 1 |

Test: swapping 30 % / 50 % of the Open Sea's SeaFan, Kelp and BranchCoral for the under-used kit pieces only lowers Open Sea same-prop tells 35.7 -> 30.0 -> 22.7 per 5 min. Re-mixing the same 11 meshes is not enough.

## What it says
1. **Top tell: "same prop again" in the Open Sea.** The Open Sea is ~4x the reef's area but uses the same 11 meshes, mostly fan coral and kelp. Needs NEW kit pieces made for the Open Sea (e.g. sponge towers, anemone fields, giant clams, sea-whip forests, rock arches), not more of the reef kit.
2. **Too few set pieces out there:** 1 wow in 5 minutes of Open Sea vs 4 in 2 minutes on the reef. Needs 4-6 hand-made landmarks in the Open Sea ring (e.g. a sunken ship, a giant whale skeleton, a rock arch, a glowing anemone garden, a sunken statue head - all original), each visible from 200+ studs and kept by streaming (persistent).
3. No empty views, no pop-in tells measured, borders natural, zones distinct: those are fine.

Not built tonight: new models need a ChatGPT design sheet and the owner's approval first (HIGH QUALITY rule). Next step: sheets for 4 Open Sea set pieces + 4 Open Sea kit pieces, then FishKit / the sheet pipeline.

Honest limits: a model; it judges meshes, not textures or lighting, and the kid's route is random. The real check is player-eye phone screenshots and likes after a test.
