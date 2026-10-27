---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 2 Shoes, coaches, trails, speed feel (M2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

```text
SPEED ARC milestone M2: the things players collect. Follow CLAUDE.md (Quick Rules). Never touch GYM ARC.
READ (only these): GDD sections 6.2, 11, 12, 13, 19 and 22; "SPEED ARC - Customization.md" sections Rules, The LOCKER (SHOES + TRAILS rows only) and Performance; "SPEED ARC - VFX.md" sections Rules, Speed feel, Trails, Coaches and rolls; "SPEED ARC - Audio (SFX and Music).md" section "Shops and collecting"; "SPEED ARC - Lessons from GYM ARC.md" sections 6 and 10. You may READ GYM ARC's trainer code (rolls, pity, reveal, follow, evolve) to copy and adapt; GYM ARC stays untouched.

0) FIX FIRST (from the prompt 1 screenshots)
- Treadmill screen at phone size: the speed number at the top overlaps its own label ("101 /W 8 MPH"). Fix the HUD so the MPH number and the goal line never overlap at 667x375.
- The treadmill canopy covers the top of the view while training. Move the camera or make the canopy fade/hide while you're on the treadmill.

1) SHOES (GDD 11, pairs 1-6 only for launch; 7-9 come with leagues 4-5)
- Shoe Shop building in the hub (Blender, small sports store front, see World note section 1). Inside: a row of pedestals that turn slowly, locked pairs as dark silhouettes with "UNLOCKS AT ...".
- Buy with coins, owned forever, one pair worn. Shown on your feet as a simple mesh in the palette (Blender, one mesh per pair, light).
- Each pair: training multiplier + small race pace bonus (GDD table). TRY ON preview on your character before buying.
- Sounds: shoe squeak + lace pull on equip, ka-ching + coin shower on buy, soft denied boop when you can't afford.

2) COACHES (GDD 12, all 8 coaches)
- Coach Corner in the hub (bench, whiteboard with coach cards, stopwatch, whistle, big COACHES sign).
- Roll with coins (price = minutes of coins at your league, Config). Odds shown on the roll screen. Pity counters (Rare at 30, Epic 80, Legendary 150...) shown too.
- Reveal: name roller with rising ticks, reveal hit scaled by rarity. Legendary and up get a short themed cutscene each (Zephyr storm wind, Kai sunrise, Flying Ghost old film grain, Mercury golden temple). Keep each under ~4 s; SKIP after the first time.
- Coaches are ORIGINAL characters inspired by runner archetypes only: no real names, faces, poses or nicknames of real people. Each has its own outfit in the palette and one signature pose.
- 1 coach follows you (cheap: hide when far, no per-frame heavy work); the others show as portrait chips.
- Slots: 2 free (passes add more in M5; build the slot count in Config now). Evolve with 3 duplicates: BASE -> PRO -> ELITE -> LEGEND. Boost caps from the GDD (training +300%, race pace +15%).
- BEST EQUIP button (strongest coaches into your slots).
- Coach portraits: make them as cartoon images in Blender or as simple drawn cards. List every image BEFORE uploading, wait for my OK, upload to the GROUP, one at a time.

3) TRAILS (GDD 13; for launch: Dust, Chalk Lines, Leaf Swirl, Fire Streak, Ice Streak, plus Lightning + Rainbow for the Trail Pack later)
- Trail Booth in the hub (neon carnival-style booth with a looping demo trail).
- Each trail = 1 Trail + 0-2 small emitters (VFX note). Shows when walking faster than 22 or in races. Other players' trails simplified, off past ~80 studs.
- One equipped, small bonus each (GDD table).

4) THE LOCKER (one window)
- Tabs for now: SHOES and TRAILS (the other tabs come in M5). Equip / unequip, owned forever, locked items visible with how to get them.
- Left menu buttons: SHOES, COACHES, TRAILS (or LOCKER + COACHES if that fits better at phone size; your call, keep it clean).

5) SPEED FEEL (VFX note "Speed feel", the most important VFX)
- Camera FOV grows with walk speed (70 -> 80 walking, up to 85 at top race pace, +5 kick on BOOST).
- Screen speed lines when running fast or boosting (pooled UI images, density follows pace).
- Footstep dust on grass/dirt, small sparks on the track at very high speed.
- Low graphics / Reduced Motion: half the effects, no shake.

TEST
- New test save: earn coins, buy Canvas Runners and Track Trainers, feel the training gain change, roll coaches 20 times (check pity counter saves), evolve one coach (give yourself duplicates with an admin command), equip Fire Streak and see it in a race.
- Phone size screenshots: Shoe Shop, roll reveal (a common + a Legendary), Locker, a race with trails, the fixed treadmill HUD.
- Part count of the hub after the new buildings (budget 3,000), draw calls, particles on screen in a full race.
- Progress note + update the feature notes (Shoes, Coaches, Trails, Locker). List the .fbx files for me to import and any images waiting for my OK.
```
