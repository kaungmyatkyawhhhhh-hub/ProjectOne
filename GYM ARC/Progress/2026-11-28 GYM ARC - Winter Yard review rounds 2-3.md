---
tags: [gym-arc, christmas-update, review-loop, level-design]
date: 2026-11-28
---
# Winter Yard review, rounds 2-3 (loop to 9/10 with ChatGPT + Gemini)

Scores: R1 ChatGPT 4.8 / Gemini 3.5 -> R2 6.9 / 5.5 -> **R3 7.7 / 7.0**. Saved **v2069** (pre-save steps done, not published).
ChatGPT R3 verdict: "Do not rebuild the layout again." Next effort is detailing (40%), model craft (30%), lighting (20%) and signs (10%). Do NOT add 30 random props; improve the existing scenes.

## Done in round 3 (after R2 review)
- Paths v2 (`Art/YardKit/build_paths.py`): an even grid with 0.1 gaps and no jitter. Muted gold curb 188,153,77 (0.6 wide). Each branch ends in a 12x10 plaza. New photo-corner branch. Asset **111300721809087**; old meshes are in `RemodelBackup.Paths_v1`.
- **Entrance arch** "WINTER YARD" (`Art/YardKit/build_arch.py`, 3,680 tris): candy columns (one ring per tilted band), wood beam, red board with gold frame, pine garland, baubles and bows. Asset **104179125689501**; model `Xmas.Yard.EntranceArch`. The SurfaceGui text sits on the invisible `SignFace` part.
- Terrain: grass, leafy grass, ground and mud turned to Snow in x -120..288, z -400..-140.
- Pines: 16 `EastRidgePine` on the east crest (hide the city); 10 `ScreenPine` outside the south fence hide `ProGym.Shell.BackWall` (dark wall, 18 tall, z -90); 2 `ShopPine` behind the shop.
- Photo corner recomposed around S=(85.6,-116.8): sleigh x1.1 angled 30° to the approach, snowman spotter x1.2 facing players, gift stacks beside it, benches angled in. Backup: `RemodelBackup.PhotoCorner_preR3`.
- Lift: LR_Hazard 208,166,39, LR_Gold 198,151,54, canes 2.5 studs outward. Fence bulbs: green turned warm white 255,236,200, yellow turned 239,186,70. Star 245,193,60. OutdoorAmbient 128,136,155 (old value kept in the Lighting attribute `OA_preR2`).
- Lamps pushed 2.5-3 studs outward; signpost moved off the main path; snowbanks x1.35 wide and x0.65 high, plus 12 more; crates x1.25; 2 counter props (`ShopCounterProp`).

## Round 4 checklist (merged R3 feedback)
- [ ] Signpost labels (SHOP / GIFT LIFT / FROST TITAN / PHOTO SPOT), cream Montserrat. Gemini still sees the signpost too close to the path: move it 8-10 studs out.
- [ ] Arch: garland made of faceted pine clumps in 3 greens (22,71,46 / 36,106,62 / 57,131,79), gold stems on the baubles, volumetric bows. Shoot the sign from 15-25 studs outside.
- [ ] Lift: hazard trim to candy red/white or gold; remove the 2 stray red ticks beside "MEGA GIFT LIFT"; fewer canopy bulbs; pulley wheel; 5x4 standing mat; barbell rack 4 studs from a column; cane bases.
- [ ] Shop: wider column stripes (+30%), smaller bulbs (-20-25%), snow strip on the awning, counter garland, 2 wreaths + 3 swags on the gym wall, warm fill light (0.4 / 6), vary the 3 hats, crates with slats.
- [ ] Photo corner: oval snow base 18x14 (210,226,238), sleigh with real curved runners and a gift load, bench snow as patches, a string of bulbs between the back pines, stagger the pine hedge.
- [ ] Titan: circular blue-grey base 20-24 wide; plaque -15-20% and squared to the approach, text "FROST TITAN / LEGENDARY ALTER / 750 CANDY CANES"; real snowflake emblem; crystals in 2 side + 2 rear clusters; ice dumbbells on a navy rack; pines clear of the crown.
- [ ] Tree: 8-12 snow patches, baubles +10-15%, 3 gift clusters, free gift 1.4x on a gold-trimmed plinth (no text).
- [ ] Ground: 4 landscaping islands (pine + gifts + snowbank) in the empty snow; path foundation edge 176,192,207; vary the row-like hill pines; rocks at the hill bases; brighter snowbank crests.
- [ ] Lighting: ClockTime ~13, light haze, less blue in OutdoorAmbient. Test the gym too.
- [ ] Signs: "LIFT FOR REWARDS"; shop sub "EXCHANGE CANDY CANES"; 8-10% padding on the lift title.
