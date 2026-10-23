---
date: 2026-10-08
tags: [gymarc, progress]
status: done
---
# 2026-10-08 GYM ARC Place lost and rebuilt

Back to [[00 GYM ARC Home|GYM ARC Home]]

Prompt: [[2026-10-08 GYM ARC Prompt - Overnight tonight]].

## What got done
- **Overnight tasks**
  - Golden ratio body (longer legs, shorter torso), latest muscle_v8 data, Growth Spurt widths per region; shoulders and hips start narrow and widen with muscle.
  - Task 1: 7 live meshes on your character, forearms and calves as static stage meshes. Task 2: six gym fits x 4 colors. Task 3: treadmill machine. Task 4: map optimize + decor.
  - Look balance cap added, then removed later the same day.
- **Muscles v9**
  - Unified muscles: the torso and upper arms are one welded mesh each, skin texture stages 1-5, big performance pass (bench reps 22 -> 60 FPS).
  - Soft muscle tint and z-fight fix, chest/abs midline fix, floating upper traps removed, arms and legs from level 0, mirror shows your front, shorts fixed.
  - Other players' muscles: 62 static body stage meshes imported, preloaded behind the loading screen with fallback and retry.
- **Machines and gyms**
  - Pro gym lifts on real equipment (arm IK, pec deck), treadmill trains stamina, genetics-style plates on every bar, crunch/leg curl/calf raise animations fixed.
  - Machine signs: a flat card first, then the floating glass diamond with an OCCUPY prompt; per-rep EXP popups; training tint (blue, then red).
  - Bigger gyms (~1.5x floor), premium pro gym (mirror wall, LED lights, smoothie corner), real treadmill running cycle, no back/neck accessories, Plates the gym cat on its bed. See [[GYM ARC - Machines]].
- **Place lost (evening)**
  - The cloud place had fallen back to 7 Oct 21:00. The local autosave was a dead end (no DataStore). The place was rebuilt in the real cloud place from the repo: 370 scripts, regenerated muscle data, builders re-run, plates swapped, world pass redone.
  - New owner rule in CLAUDE.md: after every task Save to Roblox + a dated backup copy.
  - Also: parking lot arrows fixed; bigger skate park (84 x 64) with grinding on rails and smooth quarter pipes.

## Bugs fixed
- [[GYM ARC - Bug - Muscle z-fighting and zigzags|Muscle z-fighting and zigzags]]
- [[GYM ARC - Bug - Highlight flickered on hover|Highlight flickered on hover]]
- [[GYM ARC - Bug - Torso poked through at the chest midline|Torso poked through at the chest midline]]
- [[GYM ARC - Bug - Crunch leg curl and calf raise animations|Crunch leg curl and calf raise animations]]
- [[GYM ARC - Bug - Treadmills were only decoration|Treadmills were only decoration]]
- [[GYM ARC - Bug - Lag near the gym entrance|Lag near the gym entrance]]
- [[GYM ARC - Bug - Bench reps dropped to 22 FPS|Bench reps dropped to 22 FPS]]
- [[GYM ARC - Bug - Floating upper traps piece|Floating upper traps piece]]
- [[GYM ARC - Bug - Blocky arms and spiky legs at level 0|Blocky arms and spiky legs at level 0]]
- [[GYM ARC - Bug - Mirror showed your back and a white torso|Mirror showed your back and a white torso]]
- [[GYM ARC - Bug - Puffy inner tube shorts|Puffy inner tube shorts]]
- [[GYM ARC - Bug - Place lost back to 7 Oct|Place lost back to 7 Oct]]
- [[GYM ARC - Bug - Infinite wait for machine Plates|Infinite wait for machine Plates]]
- [[GYM ARC - Bug - Parking arrows pointed backwards|Parking arrows pointed backwards]]
- [[GYM ARC - Bug - Quarter pipe sides looked like stairs|Quarter pipe sides looked like stairs]]
- [[GYM ARC - Bug - Machine sign text spilled over its frame|Machine sign text spilled over its frame]]
- [[GYM ARC - Bug - Stage mesh downloads sometimes failed|Stage mesh downloads sometimes failed]]

Found and still open (or engine limits):
- [[GYM ARC - Bug - Rep flash hard to see on light skin|Rep flash hard to see on light skin]]
- [[GYM ARC - Bug - Zigzag on the upper arm seam|Zigzag on the upper arm seam]]
- [[GYM ARC - Bug - Traps outline edges visible|Traps outline edges visible]]
- [[GYM ARC - Bug - Skin pokes through gym fits at mass monster|Skin pokes through gym fits at mass monster]]
- [[GYM ARC - Bug - Dark band on forearms and calves|Dark band on forearms and calves]]
- [[GYM ARC - Bug - Pointed traps and triceps at mass monster|Pointed traps and triceps at mass monster]]
- [[GYM ARC - Bug - Small lip at the waistband|Small lip at the waistband]]
- [[GYM ARC - Bug - Full look bulkier than lean V-taper|Full look bulkier than lean V-taper]]
- [[GYM ARC - Bug - MachineClient at the 200 locals limit|MachineClient at the 200 locals limit]]
- [[GYM ARC - Bug - Every mesh change costs 40 ms|Every mesh change costs 40 ms]]
- [[GYM ARC - Bug - Scripts cannot upload meshes|Scripts cannot upload meshes]]

## Saved / published
- Saved to Roblox: Version History 296-299 (9:20-9:36 PM), published once by the owner (v298, 9:34 PM); skate park saved as v302 (9:57 PM); more saves at 22:41 and 22:43. Dated backup `Documents\GymArc_backups\GymArc_2026-10-08.rbxl` made via File > Download a Copy. The later work was not published yet (Publish was the first thing to do next).

## Screenshots
![[GYM ARC/Screenshots/rebuild_starter_gym.jpg]]
![[GYM ARC/Screenshots/unified_front_max.png]]
![[GYM ARC/Screenshots/sign_diamond_flat_bench_side.jpg]]
![[GYM ARC/Screenshots/training_tint_red_bench.jpg]]
![[GYM ARC/Screenshots/starter_gym_bigger_wide.jpg]]
![[GYM ARC/Screenshots/skatepark_new_above.jpg]]
