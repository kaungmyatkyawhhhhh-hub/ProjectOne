---
tags: [gym-arc, progress, gem-mine, hud, review-loop]
date: 2026-11-28
---

# Gem Mine remodel + veteran HUD, review rounds 4-11 (loop to 9/10 with ChatGPT + Gemini)

Follows [[2026-11-28 GYM ARC - Full-game review round 2 (Mythic aura, GUI, audio)]] (round 3 is there). Last save: **v2116** (Studio save, not published).

## Scores

| Round | ChatGPT mine (shot 1 / shot 2) | ChatGPT HUD | Gemini mine (shot 1 / shot 2) | Gemini HUD |
|---|---|---|---|---|
| R4 | 8.6 | 7.6 | 7.2 / 7.8 | 6.8 |
| R5 | 8.6 / 8.8 | 8.1 | 8.3 / 8.5 | 8.1 |
| R6 | 8.9 / 8.8 | 8.8 | 8.6 / 8.2 | 8.7 |
| R7 (button guide sent) | 9.0 / 8.8 | 9.0 | 8.7 / 8.4 | 8.8 |
| R8 | 8.9 / 9.1 | 9.2 | 9.0 / 8.9 | 9.1 |
| R9 (daytime) | 8.9 / 9.1 | **9.3** | **9.2 / 9.1** | **9.3** |
| R10 | 8.9 / (not re-rated) | - | - | - |

- Gemini: everything 9+ ("nothing blocks 9+").
- ChatGPT: HUD 9.3 ("freeze the design"); stage shot 9.1. Front shot still 8.9; its last two notes are the machine frames (done in R11, **not re-rated yet**: the Chrome review tabs closed) and the photographic ceiling texture (not done).

## Owner correction (28 Nov)
"tell gemini and chatgpt about what the buttons do too, because rn they think some of it are not important which are important".
- From R7 on, every review prompt lists what each left button does: SHOP, STATS, MUSCLES, INVENTORY, GENETICS, POSES, CREW, TRAINERS, plus the rotating gold footer, ADMIN (dev only), boosts, hotbar and the right card.
- Both reviewers then dropped the "MORE drawer for GENETICS/POSES/CREW/TRAINERS" idea. ChatGPT: "All eight core navigation buttons are justified."
- The lesson is in the vault copy of `roblox-ui-pro`; the plugin needs a re-upload.

## New meshes (Blender, low-tri faceted, `GYM ARC/Art/GemMine/`)
- **Onyx Throne:** `build_throne.py`, asset 89188597756437. Old parts invisible (`OrigTransparencyR4`); backup `RemodelBackup.OnyxThrone_pre`; stone 58,52,72.
- **Stalactites + wall rocks:** `build_gemkit2.py`, asset 132557326929308. All 40 CeilSlab RockDark parts replaced (`StalacR5`); 14 WallRocks (`GemMineGym.WallRocks`).
- **Plate Forge shell:** `build_forge.py`.
  - v1 127926806126834.
  - v2 130048300781547 (cap bug).
  - v3 131020300290681 (stepped top + sloped cap).
  - **v4 118015374834371** (mid-height ledge + 0.6-stud corner pilasters).
  - Placed in `PlateForge.ForgeShell`, anchored to `BackWall.CFrame * CFrame.new(0,-0.075,-6)`: the model pivot drifts and flipped the mesh.

## Map changes (old values in attributes)
- Giant Flint Stage crystals: rotated 12°, ×0.9 (`ShrunkR6`); the tallest ×0.82 more, base kept on the floor (`OrigScaleR7`).
- Gold ring 188,153,77, Metal (`OrigColorR6`/`OrigMatR6`).
- Left minecart (122,130) moved 2.5 studs -Z along the track (`OrigPivotR7`).
- Floating ceiling slab at (125,-7.7,122) raised 8 studs into the rock (`OrigPivotR8`).
- Wall rocks lightened to 95,92,110, chips 66,64,80 (`OrigColorR8`).
- `GemMineGym.BenchFill`: 2 neutral PointLights (185,190,215, 0.4, range 12).
- `GemMineGym.OnyxFill` light (0.3, range 8).
- `GemMineGym.WallBaseCrystal`: a small crystal cluster at the masonry base (`AddedR8`).
- 509 near-black machine parts → 48,49,62 (`OrigColorR9`). Cracks, signs, lock plate and LaunchCover left as they were.
- Earlier: 2 CrystalM clones, forge warm light, purple neon pads ×0.85.

## Bug fixes
- **GymLightsClient:** zone-based gyms are checked first. The Starter Gym's box reached about 1e6 studs down because of a parked snow patch, so the mine's lights were OFF.
- **Daytime cave:** by day the sun, the sky light and the town haze leaked underground and the mine went milky grey.
  - `DayNightClient`: inside `GemMineGym.Zone` the outdoor fill eases to the night value.
  - `GymMoodClient`: a new Gem Mine mood (box 68..214 × 94..168, top y -6) with haze 0.2, density 0.08, sky light 0.05/0.2, sun 0.2, exposure -0.12 and a faint violet tint.
  - Voxel lighting takes about 10 s to settle after the change, so wait before judging a capture.

## HUD changes
- Pager under the right card: `CardPager` LayoutOrder 4 → 2. An empty but visible "Middle" slot was the 28 px gap.
- Run Cards: the upper-right count is removed; the line reads "N CARD PICKS READY".
- Left collapse tab flush to the grid (`SideMenu`, +3 → +0).
- Right collapse tab: `TAB_GAP` 6 → 1 and top-aligned to the card, not the card + pager.
- Earlier rounds: RightColumn width 164, streak toast 252×42, nav scale 0.72 gap 7, hotbar slot 39 gap 1, ProgressClient one card at a time.

## Review shots
In the session folder `review_r7` / `review_r8` / `review_r9` (R7_gem_a/b, R8_gem_a/b + forge_back, R9_gem_a/b, R10/R11_gem_a).

## Next
- Send R11_gem_a (frames lifted) to ChatGPT for the last 8.9 → 9 shot.
- If it still asks: soften the ceiling's photographic terrain texture, and close the bright seams in the masonry joints (0.03-0.05 studs).
- Not checked: phone sizes, night time after the mood change (the mood is the same at any hour, so it should hold), the cutscenes.
