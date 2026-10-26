---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Body Alters

The endless progression after 7'0" (owner's [[2026-10-20 GYM ARC Gameplay plan]], prompt 21, built 21 Oct). Progress: [[2026-10-21 GYM ARC Body alters]].

## How it works
- **Ladder:** 30 alters in 6 tiers of 5 (Human, Stone, Metal, Gem, Elements, Legend). Alter 0 = Natural (the normal skin stages). Tiers 1-3 have textures (Tier 1 Pumped..Peak; Tier 2 Stone and Tier 3 Metal since 26 Oct); Tiers 4-6 show "Coming soon" and can't be reached yet.
- **Goal:** at 7'0", every muscle group at a level, like a Growth Spurt goal: alter 1 = 205, then +25 per alter (24 Oct; was 95, +10).
- **Doing it:** BODY ALTER READY popup (also on a machine) with ALTER / Later; the player chooses when. Every muscle keeps 25% of its EXP, height stays, the new skin goes on, gains bonus +15% per alter (stacking, outside the gains cap). A camera / flash / "ALTER 3: TANNED" moment.
- **Safety:** the save is written before the alter (if it fails nothing changes) and again right after. Old 7'0" saves start at Natural with their muscles.
- **Tier reward** (every 5th alter): a title (Peak Human, Stone Cold, Heavy Metal, Crown Jewel, Force of Nature, Living Legend), an aura (placeholder looks) and DNA tokens (1/1/2/2/3/3).
- **Skin:** the alter's texture set replaces the skin stages at every muscle size, tinted with the player's skin color; on your live body and on the stage meshes other players see (MuscleRig, `ReplicatedStorage.SkinStages.Alter_<id>`). The statue stays marble.
- **Choose your skin:** Inventory > Alters: wear any unlocked alter; the bonus is always the highest alter's.
- **PUMP SHOP > Alters:** the alters of your tier with their state, the next one's goal and bonus, ALTER NOW when ready, MY SKINS. Nothing is sold (no coin or Robux cost).
- **Best physique:** the biggest body ever (Growth Spurts, then EXP) is saved; the Total / group boards and the statue use it, so an alter never makes them smaller.
- **Shows:** at 7'0" the posing divisions are Open (Natural) and one per alter tier; stage presence at 7'0" = 50% + the rest by alter number (of 30).
- **HUD:** the Growth Spurt card / machine strip become "NEXT: SHREDDED · 62% · Needs LEGS"; top bar "7'0" MAX · Alter 3 Tanned"; a small gold "ALTER 3" pill over the nametag.
  - (23 Oct, prompt 57; [[2026-10-23 GYM ARC Roll card side layout and NEXT pill outline]]) The NEXT pill's outline is the HUD cards' own (1.5 px) in the next alter's colour (no gold); READY = the ready glow (`Shared/UI/ReadyGlow`) in that colour. A dark alter art can get a lighter shade and a wash of its colour on the pill (`AlterThemes` `pillShade` / `pillWash`; SHREDDED has them).

## Popups and transformation (prompt 22, 21 Oct; [[2026-10-21 GYM ARC Unique alter popups]])
- **Every alter has its own theme** (`Config/AlterThemes`): background art (Tier 1, by the planner), accent, title gradient, intro, particles, sounds. Tiers 2-6 use colors only until their art comes (Stone thud + dust, Metal clang + sheen, Gem chime + prism, each Element its own sound and particles, Legend cosmic swell + rays); every alter has its own name colors.
- **BODY ALTER READY popup** (`Shared/UI/AlterPopup`): the screen dims with a vignette, letterbox bars, the music ducks, a riser; the panel slams in (sub boom + punch, shockwave ring, small shake), the name stamps in with sparks, then the theme's beat (Pumped heartbeat x2, Shredded slashes + wipe, Tanned rise, Vascular vein crackles, Peak spotlight + gold dust). While open: border pulse, title shine every 2.5 s, drifting particles, breathing ALTER button, soft hum. Tier finale: "TIER 1 COMPLETE".
- **Transformation** (`Shared/VFX/AlterFX`, ~3 s, tap to skip): camera close (picks a clear angle, never through walls), world darker, music muffled, heartbeat faster + swell, energy pulled into the body with an accent rim glow, 0.2 s silence, FLASH (boom + punch + sparkle + reverb, ground shockwave, particles, camera shake), the reveal chime (a step higher every alter) + the theme's sting + cheer + its screen effect, the body flexes (front double biceps, everyone sees it), the title card "ALTER 3: TANNED". The ALTER action goes to the server at the flash, so the new skin appears under the white.
- **Others nearby** (150 studs) see the flash, the ground shockwave and particles and hear a quieter 3D boom (no camera move).
- **Inventory > Alters and PUMP SHOP > Alters** cards have a strip of each alter's art (or colors) and a line in its accent.
- Sound ids: [[GYM ARC - Music and Sounds]]. Max ~40 particles at the peak, ~20 idle, half on low graphics; Reduced Motion: no shakes.

## Where it lives
- `Config/Alters` (all numbers), `PlayerData.Alter / EquipAlter / UpdateBest`, `ActionService` (Alter, EquipAlter), `BodyService.PublishData` (Alter, AlterNumber attributes), `Gains.PerRep` (bonus), `MuscleRig` (skin), `ProgressClient`, `Shared/UI/AltersPanel`, `PumpShopClient`, `TopBarClient`, `OverheadTitleClient`, `ShowOffService` (best physique), `PosingComp`, `Config/AlterThemes`, `Shared/UI/AlterPopup`, `Shared/VFX/AlterFX`, `Audio.Duck / Muffle`.
- Textures: `Downloads\gym_arc_alters\tier1_human`, uploaded 21 Oct (ids in Config/Alters). Skins built with `tools/builders/SkinStages` `BuildAlters()`.
- Pacing: `lune run tests/pacing alters`. Tests: `tests/alters`.

## Adding a tier
1. Upload its 15 maps, put the ids in Config/Alters `textures`.
2. Run `BuildAlters()` in Studio (command bar).
3. Re-run `tests/pacing alters` and tune `FirstGoal` / `GoalPer`.

![[GYM ARC/Screenshots/alters/tier1_preview.png]]

## Texture fix (21 Oct, prompt 38; [[GYM ARC - Bug - Alter textures only change color]])
- The body's UVs spread one texture over 10-14 studs, so Tier 1's detail came out too big and soft ("only the color changes"). Shredded and Peak maps now repeat 2x2 inside the image; Vascular keeps its scale with much stronger veins (`Downloads\gym_arc_alters\tier1_human_tiled`, ids in Config/Alters). Rule for new tiers: design detail for ~10-14 studs per texture (70-120 px per stud), thin lines need strong contrast.
- MuscleRig re-applies the skin on every new body piece and every 2 s, and preloads every skin map (ids from Config/SkinStages + Config/Alters).
![[GYM ARC/Screenshots/alters/alters_side_by_side.jpg]]

## Tint and head (21 Oct, prompt 38b)
- Each textured alter has `mean` (its color map's average). Tanned and Peak have `tone = "Tan"`: their tint comes from `Alters.TanColor(skin)` (a deep bronze, numbers in `Alters.Tan`) instead of the plain skin, so a light skin is warm bronze and a dark one a bit deeper. Others: the skin.
- `Alters.PlainSkin(id, skin)`: the plain color that matches the alter's body. The head (no alter maps on it), the elbow / knee balls and the flat skin under a training tint use it; Natural = the skin. The head's own color comes back on Natural (`NaturalColor` attribute while tinted).
- A Face accessory with the skin baked in can't be tinted (it keeps its color).
![[GYM ARC/Screenshots/alters/alters_bronze_light_dark.jpg]]

## Tier 1 takes 8 hours (24 Oct, owner)
- `Config/Alters`: FirstGoal 95 -> **205**, GoalPer 10 -> **25** (goals 205, 230, 255, 280, 305).
- Estimated times: alter 1 ~1 h 50, 2 ~1 h 15, 3 ~1 h 30, 4 ~1 h 40, 5 ~1 h 55 = **~8 h for all of Tier 1** (was ~1 h).
- Estimate from the EXP curve + the 21 Oct times, not a full sim. Rerun `tests/pacing alters` on the PC with the repo to confirm.
- Players already close to the old goal now need more levels (nothing lost).

## Taller per alter tier (24 Oct, owner)
- Every finished alter tier (5 alters) adds **4 inches**: Tier 1 done (Peak) = 7'4", Tier 2 = 7'8", ... Tier 6 = 9'0".
- `Config/GrowthSpurts.AlterTierInches = 4`, `AltersPerTier = 5`, `GrowthSpurts.PlayerHeight(data)` (Growth Spurt height + tiers from `data.alter.highest`).
- Used for the body (BodyService), top bar, menu, mirror, posing shows, titles, Tallest board. The statue / best physique still use the Growth Spurt height.

## Tiers 2 and 3 (26 Oct; [[2026-10-26 GYM ARC Endgame and first Growth Spurt pass]])
- Stone: Clay, Sandstone, Granite, Marble, Obsidian. Metal: Bronze, Iron, Steel, Chrome, Gold. Our own procedural maps (`tools/alter_textures.py`, `Downloads\gym_arc_alters	ier2_stone`, `tier3_metal`), metalness maps on Obsidian and the metals.
- `tone = "Raw"` in Config/Alters: their own colours, no skin tint (`Alters.Tint` = white). Popups use the tier colours (no background art yet).
- Pacing sim (`lune run tests/pacing alters 15`): Tier 1 ~2 h, Tier 2 ~2 h, Tier 3 ~2 h 40 of bot play. The 24 Oct "8 hours" was an estimate; the sim says ~2 h. Goals unchanged.
