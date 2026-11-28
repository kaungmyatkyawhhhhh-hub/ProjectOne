---
tags: [gym-arc, review-loop, level-design, vfx, christmas-update]
date: 2026-11-28
---
# Full-game review, round 1: whole map, texts/frames, VFX

Owner (28 Nov): "are u sure they even rated the entire map? i see so many flaws and cons", then texts/frames, then GUIs/HUD/animations/SFX/music: "why do i have to mention everything? i already told u to do every details". Earlier scores (Winter Yard R7 8.9 / 9.3) only covered 7 yard screenshots. This round showed the reviewers the WHOLE game for the first time.
Saved **v2083** (pre-save steps done, not published).

## MAP-1 scores (29 images: 19 areas, intro cutscene, tutorial/HUD, 8 VFX in Play)
- **ChatGPT 6.8 overall.** Architecture 7.8, level design 7.2, models 6.5, consistency 5.8, lighting 5.5, VFX 6.0, UI 7.5, Winter Yard 8.9.
  - Worst areas: spawn 4.0, Record Board text 4.5, Gem Mine interior 5.2, Skatepark/leaderboards/Starter Gym 5.5.
- **Gemini, about 6.5.** Its worst items: leaderboard rows 3, clipped street signs 3.5, spawn 5, Gem Mine 5.5.
- **VFX:**
  - Default sparkle glints rated 5-6 (too weak, no personality).
  - FrostFX burst rated 8 by Gemini, but ChatGPT says it overexposes the Titan.
  - HoF firework 7-7.5 (bleaches the building).
  - GrowthFX 6.5; Mythic aura 6 (too mild).

## Fixed in Studio (old values kept in attributes)
- **Hall of Fame title:** `Sign` 26 x 1.9 (was 22.95 x 1.02). Gold heavy text on its own dark band with a gold border (`OrigSize`/`OrigCF`).
- **Plaza string lights:** raised 3.5 studs (`RaisedR8`) with the poles and finials. My "giant white sphere at spawn" was one of these bulbs in front of my camera.
- **Agency beacon** (`AgencyBeacon.Shaft`): width 2.5/6 -> 1.1/2.2, fainter, gold, top 140 -> 60 studs above the desk (`Orig`).
- **Starter Gym:**
  - `LightSpan` rainbow bulbs: blue -> warm white 255,236,200, green -> gold 239,186,70 (180 parts, `OrigColor`).
  - FillLights/CeilingLights brightness x1.9 (`OrigBrightness`).
- **Gem Mine:**
  - 11 purple/pink PointLights rebalanced: main fill 205,212,235 b1.8, violet 150,120,255 b1.2, cyan 90,215,255 b1.2.
  - 49 neon crystals 255,95,210 -> 232,138,222 (`OrigColor`).
- **VFX:**
  - FrostFX burst PointLight 9 / s*5 -> 3 / s*3.5.
  - HofVFX firework glow 8 -> 2.5 (source patched, dated comments).
- **Yard glints:**
  - The 7 sparkle emitters now use `ArtIds.AuraFlare.star.alpha` (4-point star; the alpha version shows on bright snow), LightEmission 0.55, peak size 1.25-1.6, rate about 3x.
  - Each has a `_Soft` second layer (HofVFX sparkle, drifting up).
  - `FrostMist` is now a real cold haze (HofVFX wisp).
  - Attribute `R8Glint`.
  - Don't use `coin_glint`: it's a coin picture.
- **Bug fixed:**
  - `LandmarkTree.Glint` was 133 x 2048 x 89 and had fallen to y -500000, so the tree's sparkles were spread across the sky.
  - Now 17 x 19 x 17 at the foliage. All 5 Glint parts are anchored, with no collision/query/touch.
- **Record Board** (PowerliftingService): an empty server record reads "Be the first!", an empty all-time row "Open spot" (was "-").
- **Christmas in the town:** `Xmas.TownWreaths` holds 14 wreaths, a pair on each gym's main sign: Pump Shop, Golden Era, Gem Mine, Members, VIP, Pro, Powerlifting. They're event-only because the Xmas folder only exists during the event.

## Reviewer "flaws" that were my camera, not the game
- Signs "clipped" at the frame edge.
- Lamps "blocking" the Powerlifting banners/board: only from a high camera; eye level is clear (checked the geometry).
- The "post in the road": it's on the sidewalk (z 44-50).
- The black HoF cover screen: Studio only; LiveEventService puts the cover away when a server starts after the launch.
- The empty leaderboard rows: Studio has no data.
- **Lesson:** shoot from player eye height on walkable ground, never from inside walls or in front of bulbs.

## Still open (not done yet)
- Round 2 scores: ChatGPT's attachments were rate-limited.
- Not yet reviewed: GUI/HUD screens with their open/close animations and motion VFX, sound effects and music, cutscenes beyond the intro.
- Audio found so far: no Christmas/Winter Yard music and no Christmas sounds in Config/Sounds (118 entries, 12 area tracks).
- Modelling: Skatepark identity, beach shade sails, Pro Gym cliff bushes, shop-street blank walls, runway planks, the forge's big magenta crystal.
- Mythic aura looks mild: the owner toned it down on purpose (6 Nov), so leave it unless the owner asks.
