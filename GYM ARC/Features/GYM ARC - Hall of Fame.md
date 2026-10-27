---
date: 2026-10-28
tags: [gymarc, feature]
status: built, waiting on the live test
---
# GYM ARC - Hall of Fame

Back to [[00 GYM ARC Home|GYM ARC Home]]. Brief: [[2026-10-27 GYM ARC Prompt - 66 Hall of Fame, Profiles, Codes, Strongman at Alter 2]] (part 2). Built 28 Oct for the owner's HALL OF FAME event (Sat 31 Oct, 9:30-9:45 PM). Progress: [[2026-10-28 GYM ARC Leaderboard reset, trainer slots, pity stages]].

## What it is
The rebirth after Alter 15 (`Config/HallOfFame.RequiredAlter`, never moves). Never forced.
- **Start over:** height, Growth Spurts (start at the new star's `startSpurts`), muscle levels, Body Alters and their gains. Heavy weights lock again by themselves (every lift checks the main muscle's level, same as after a spurt).
- **Keep:** trainers, coins, alter skins (all reached ones become owned looks, `data.alter.bought`; the worn one stays worn), titles, auras, styles, gear, passes, Robux buys, LVL (the muscle levels go into `stats.levelBase`).
- **Stays unlocked:** every gym (`data.gymAccess` Beach / Pro / Powerlifting) and every feature that opens up to Alter 15: `Config/Guides.Met`, `Strongman.Unlocked`, `Court.Unlocked`, AuraService height / alter auras, PumpShopService sections + gear, GearPanel all pass when `HallOfFame.Unlocked(data)`.
- **Stars** (`Config/HallOfFame.Stars`): 1 +25% EXP + start at GS 2; 2 +50%; 3 +75%, +10% coins, GS 3; 4 +100%; 5 +125%, +20% coins, GS 4; 6-9 +15% a star; 10 +200% + LEGEND; then +10% a star. EXP outside the gains cap (`Config/Gains.PerRep`, next to the alter bonus); coins = boost source "HallOfFame". First star: a free trainer roll + the HALL OF FAMER title; 10: the LEGEND title.
- Save: `data.fame = { stars, peak = { spurts, alter, equipped, muscles }, enteredAt }` (never inside `data.alter`).

## Screens
- **HUD pill** (ProgressClient) at Alter 15: gold "HALL OF FAME / Tap to become a legend".
- **The Hall of Fame screen** (HallOfFameClient): its own full-screen moment (owner: "too complex, texts tiny" -> "lots of vfx and bright stuff... HUGE and SPECIAL"): turning gold rays, a pulsing gold glow, HALL OF FAME with a shine sweep, the next star glowing with a ring, sparkles drifting up, the perks big, YOU KEEP / START OVER in one line each, the owner's heavy-weights line, a glowing ENTER, Not yet, Update alerts (Roblox notifications prompt). Players already at Alter 15 see it once ("NEW: HALL OF FAME", flag `onboarding.hallIntro`).
- **Ceremony** (~6.5 s): the HUD hides, you stand on the Hall's stage (body kept at its peak: player attribute `HallCeremony`, BodyService + MuscleClient), camera swings round, gold flash, "★N HALL OF FAME" slams in with rays, glow, two shockwaves and sparkle bursts; nearby players see the stage spotlight, gold confetti and a cheer. Then a fade, you respawn small at the gym, toast with the perks. SKIP from the 2nd star.
- **Over the head:** "★N" in gold before the title (TitleService tag).

## The Hall (world)
- Built by `ServerStorage._Builders.HallOfFameHall` -> `Workspace.Town.HallOfFame`. At the east end of the beach (x 182..195, z 180..222), back to the town's east edge, open front facing west over the sand to the Posing Stage (owner: the plaza spot hid the leaderboards -> "Move the Hall away"; the plaza is back exactly as it was). Two palms moved just past its ends.
- White marble floor / walls / 6 columns with neon gold bands, a gold-edged roof, the HALL OF FAME sign with a warm glow, gold dust drifting inside, warm spotlights.
- Pedestals 2 / 1 / MINE / 3 and the gold board (TOP 10 ALL TIME + LEGENDS IN THIS SERVER, client-drawn); the ceremony stage in front of the middle.
- **Statues:** the top 3 by stars (OrderedDataStore `LB2_HallOfFame`, refreshed every 180 s, `ReplicatedStorage.HallOfFameData`) as marble statues of their peak body. **VIEW MY STATUE** (prompt on the round stage in the middle, `PedestalMine` marker): your peak statue there, your screen only, 60 s.

## Console
`game.ServerStorage.Admin:Invoke("stars", "<player or all>", n)` sets stars (title / tag / boost follow).

## Not done yet (brief items)
- The star-only aura on the first star; the Coach Dex line; analytics "SecondRun_Done"; pacing check of run 2 (+25% EXP and GS 2 start).
- Profiles (part 3) and Codes (part 1).

## Redesign (28 Oct, prompt 80)
The Hall is now on the park block behind the plaza (Blender model + builder), with its own flipbook VFX, torches and a gold light pillar; soul cutscenes per star count (never skipped); a calm prestigious confirm screen; the HUD pill wears the gold alter art. Studio testing: Workspace `TestHallOfFame`, `TestStars`, `TestCutscene`, `TestCutsceneFreeze`. See [[2026-10-28 GYM ARC Leaderboard reset, trainer slots, pity stages]].

## Fixes (28 Oct, prompt 81)
[[2026-10-28 GYM ARC Prompt - 81 Hall of Fame fixes, clock spike, test stats on]]. Statue auras stand on the pedestal tops (they floated in the niches). New look: polished marble (`GymArc_HallMarble`), smooth shiny gold (no Foil), dark roof (`GymArc_HallRoof`). v2 Blender model (`HallOfFame_v2.fbx`: rounded edges, no stacked faces, a real roof, glass, light lines) is installed (v1 in `ServerStorage._Removed_HallV1_28Oct`); walls + columns smooth bright white. The builder makes roof slabs only for v1 (no `HallNeon` part).

## Confirm (28 Oct, prompt 82)
ENTER opens ARE YOU SURE? (what starts over, what you keep), GO BACK / red YES, ENTER; only YES enters. [[2026-10-28 GYM ARC Prompt - 82 Hall of Fame are you sure]]
