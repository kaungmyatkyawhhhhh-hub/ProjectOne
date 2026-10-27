---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 2 Shoes, coaches, trails, speed feel]]"
---
# Progress 2 - Shoes, coaches, trails, speed feel (M2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Done overnight without questions (owner asleep). Imports and image checks wait for the morning list at the end of prompt 6.

## Fixed first
- **MPH number at phone size:** the MPH block now sits on a solid dark plate, so the stand screen's text behind it never mixes in.
- **Treadmill canopy:** fades (local only) while you train on a treadmill.
- Also: the v2 hub props you imported are in (`ServerStorage/Meshes`, v1 kept in `MeshesV1_Backup`).

## Built
- **Shoes** ([[SPEED ARC - Shoes]]): pairs 1-6 with the GDD numbers, Shoe Shop with 6 turning pedestals (locked pairs dark with "UNLOCKS AT ..."), buy with coins, one worn, TRY ON preview, shown on your feet. Sounds: ka-ching + coin shower, squeak + lace pull, denied boop.
- **Coaches** ([[SPEED ARC - Coaches]]): all 8 original coaches, roll at Coach Corner (price = 1.5 min of coins, min 50), odds + pity counters on the roll screen, name roller with rising ticks, reveal scaled by rarity, themed cutscenes for Legendary+ (storm / sunrise / old film / golden temple, under 4 s, SKIP after the first time), 2 slots (pass slots in Config), evolve 3 duplicates BASE -> PRO -> ELITE -> LEGEND, BEST EQUIP, caps +300% training / +15% pace, first coach follows you, the rest are portrait chips under the coins.
- **Trails** ([[SPEED ARC - Trails]]): Dust, Chalk Lines, Leaf Swirl, Fire Streak, Ice Streak (+ Lightning, Rainbow ready for the Trail Pack). Trail Booth with a looping demo trail. On when you run faster than 22 or race; others' trails simplified and off past 80 studs.
- **Locker** ([[SPEED ARC - Locker]]): one window, SHOES + TRAILS tabs. Left menu: LOCKER and COACHES.
- **Speed feel** ([[SPEED ARC - Speed Feel]]): FOV 70 -> 80 walking, up to 85 in races, +5 kick on BOOST; screen speed lines; dust on grass, sparks on the track at high speed; low graphics = half.

## Tested (fresh test save + the Studio save)
- Bought Canvas Runners and Track Trainers: training x1.0 -> x1.3 -> x1.7, race pace +1%. Light Racers refused until League 1 Gold.
- 20 coach rolls: Rae x6, Benji x8, Ivo x4, Mara x2; pity counters move and reset; rolls cost 90 each.
- Evolve: gave 3 Zephyr with the admin switch -> Zephyr PRO; boosts added up right (x2.93 training, +5.5% pace).
- Pity saves: 5 rolls on the Studio save, rejoined: same pity, rolls, coaches and coins.
- Race with Fire Streak: trail on during the race.
- Legendary / Mythic / Secret+ reveals checked with the Studio switch `TestRollCoach`.

## Numbers
| What | Result |
|---|---|
| Hub parts | 727 with the 3 shops (budget 3,000) |
| Draw calls in a full race | 38 for the world (127 total with UI) |
| Particles on screen in a race | about 7 live (budget 300) |
| CPU per frame | about 1.4 ms |

## Changes / calls I made
- Shoe unlocks that say "L1 Silver / Gold" use the rank thresholds from GDD 9.1 (Silver 100, Gold 400 MPH); prompt 3 adds the full rank system.
- Coach portraits are drawn cards (UI shapes), so **no image uploads were needed**. Coaches in the world are normal-body NPCs in their outfit colours with one prop each.
- Particles use Roblox's built-in textures (no uploads).
- I didn't open GYM ARC (rule: never touch that Studio). Rolls / pity / evolve were written fresh from the GDD.
- Studio test switches added: `TestRollCoach` (forces the next roll), `TestGiveCoach` ("Zephyr,3"), `TestOpenWindow` ("Locker:SHOES", "Coaches:ROLLNOW", "close").

## Waiting for the owner (import list)
`Downloads\speed_arc_models\hub\v3\` (script: `hub_kit_v3.py`):
- Shoe_WornSneakers, Shoe_CanvasRunners, Shoe_TrackTrainers, Shoe_LightRacers, Shoe_ParkPacers, Shoe_SpikeShoes (~1.3-1.5K tris each)
- ShoeShop_Shell (3K), TrailBooth_Shell (1.9K), CoachBoard (0.6K)
Put them in `ServerStorage/Meshes` like before. The game already uses them when they're there (shoes on feet, pedestals and Locker previews; shells replace the part walls).
No images are waiting for an OK.

## Screenshots
![[2026-10-28 p2 phone shoe shop.jpg]]
![[2026-10-28 p2 phone locker.jpg]]
![[2026-10-28 p2 phone my coaches.jpg]]
![[2026-10-28 p2 phone race fire trail.jpg]]
![[2026-10-28 p2 coaches roll.jpg]]
![[2026-10-28 p2 reveal epic.jpg]]
![[2026-10-28 p2 reveal mercury temple.jpg]]
![[2026-10-28 p2 coach follows.jpg]]
![[2026-10-28 p2 treadmill canopy hud.jpg]]
![[M2 shoes.jpg]]
![[M2 shells.jpg]]
