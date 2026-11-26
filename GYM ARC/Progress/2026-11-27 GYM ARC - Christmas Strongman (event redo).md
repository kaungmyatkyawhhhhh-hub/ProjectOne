---
tags: [gym-arc, christmas-update, progress]
date: 2026-11-27
build: Studio, NOT saved yet (last save v1936), NOT published
---
# GYM ARC: Christmas Strongman (the Christmas event redo)

Plan: [[2026-11-27 GYM ARC - Christmas event redo plan (ChatGPT + Gemini + Gym League study)]]. Before: [[2026-11-26 GYM ARC - Christmas Phase 2f 2c 3 5 6 (events, chair, launch)]].

## Built
| # | Item | What it does | Where |
|---|---|---|---|
| 1 | Whole-gym makeover | Warm string lights sagging along every ceiling beam plus 6 swoops, garland with bows, baubles and bulbs on every wall, wreaths, 3 peppermint plate stacks, snow falling outside the windows and over the yard. Street door: a candy-cane arch with a garland and lights, and a "MERRY CHRISTMAS!" sign above GYM ARC. Lighting unchanged (bright). | Workspace.Gym.StarterGym.Xmas.Makeover |
| 2 | Winter Training Yard | The back wall opens into a snowy yard (the wall, a skirting piece, a mirror panel and the town fence hide while the event is on; tag `XmasHide`; new invisible boundaries keep players in). The yard has a landmark tree (~30 studs, a star, 46 ornaments, 91 lights, presents), the free gift, the lift rig, the Candy Cane Shop stall and the Frost Titan pedestal. | Xmas.LandmarkTree, Xmas.Yard |
| 3 | MEGA GIFT LIFT | Every 10 min (first after 2 min): a banner countdown with GO, 30 s to join, 60 s of lifting. Tap LIFT (or Space / R2 / X) on the pad; a shared bar fills and the giant present rises in the steel rig. Target = max(90, 90 × players^0.85), so one player alone can finish. Done = the present bursts (particles, boom, fanfare). Pay once per round on the server: 5 canes for 5+ lifts, +20 if the gift was lifted, and 2x EXP for everyone for 3 min. 8 taps/s cap; only counts on the pad. | Config/Advent.Lift, Server/MegaLiftService, MegaLiftClient, ActiveBoostsClient |
| 4 | Candy Cane Shop | One CHRISTMAS window (top-bar pill renamed), tabs REWARDS / CALENDAR. Rewards: Santa hat 40, Gingerbread alter 200, Frost Titan alter 750, each with a picture, name, one line and a price button (WEAR / WEARING once owned). Opened from the pill or the stall's SHOP prompt. Bought = saved first (SaveNow, refund on failure), then worn. | Config/Advent.Shop, AdventService, AdventClient, Config/Alters |
| 4 | Frost Titan pedestal | An icy statue on a slowly turning pedestal next to the shop, shown only while the event is on. | Xmas.Yard.TitanPedestal |
| 5 | Cuts | Gift Rush, the AFK chair, the falling gift drops, Protein Drop, the old tree, the CHRISTMAS ALTERS n/150 chip and cane dumbbells are gone. The 10 s cutscene is now a 3 s reveal: "CHRISTMAS STRONGMAN – Lift the Mega Gift · Candy Cane Shop · Frost Titan". Launch text updated. Calendar kept as the second tab; the calendar now uses icon tiles (no ViewportFrames). | Config/LiveEvents, VFX/LaunchCutscenes |

## Map (placed by code)
| object | position (x, z) | facing | why |
|---|---|---|---|
| LandmarkTree | (0, -133) | — | centred in the yard, seen straight through the wall opening |
| FreeGift | (1.5, -121.5) | the gym | in front of the tree |
| LiftRig (16×16 pad) | (-22, -120) | +Z (the gym) | left of the opening, sign readable from the gym |
| CaneShop | (22, -110) | toward the opening | right of the opening, first thing on the right |
| TitanPedestal | (24, -131) | turns | beside the shop: see it, want it |
| EntranceArch | street facade, z 15.4 | the street | frames the GYM ARC door |

MapAudit (yard): 4 flags, all false: SnowFloor "sunk" into the terrain (meant to cover it), the pedestal "floats/tilts" (its base is a rotated cylinder; the bottom sits at y 0.15), the shop "unreachable" (the audit runs in Edit with the back wall still there; in Play the paths gym → shop and gym → rig both succeed).

## Tested (Studio Play)
- Lift round: 90/90, burst, +25 canes, the 2x EXP chip; the tap cap holds.
- Shop: 300 → 60 canes; the hat and Gingerbread bought and worn; Frost Titan refused (not enough canes); buying the hat twice refused.
- Shop window: all three pictures load; the window doesn't open during the tutorial on the bench (correct: no windows while training).
- Street arch and 3 s cutscene: screenshots OK.
- Console: 0 errors.

## Owner to do
- **Art (Gemini):** a real Gingerbread skin and a Frost Titan skin. Right now Gingerbread reuses the Clay art and Frost Titan the Frost art, so the worn Frost Titan has no unique shape.
- **Santa hat:** it's code-built; pick the final hat (house rule: you pick avatar clothing).
- **Music:** no festive track in Config/Sounds yet; add one if you want music.
- Still from before: the dev product "Restore a present" and the holiday pass id.
- **Saving:** Studio isn't saved. FastEvents is cleared, FreshPlayer = true; RestoreTemplates() runs at save time.

## Risks / not checked
- About 2,250 parts in the Xmas folder: phone FPS not measured.
- The lift uses its own LIFT button, not the REP button.
- The MegaLift toast slightly overlaps the bar panel on PC.
- Not tested with 2+ players (bar scaling, shared pay).
