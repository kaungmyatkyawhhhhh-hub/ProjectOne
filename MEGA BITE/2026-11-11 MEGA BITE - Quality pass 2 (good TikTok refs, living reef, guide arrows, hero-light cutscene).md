---
date: 2026-11-11
tags: [megabite, quality, world, hud, cutscene, build]
status: built in Studio and checked in Play. Not published.
---
# MEGA BITE: quality pass 2 (11 Nov, 18:24–19:05)

Owner at 18:24: "the tiktok references uis and animations and game quality are way better than this." Then at 18:29: "not the shark video in tiktok reference, that one is one of the worst one."
Direction note: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]]. The Shark Shop TikTok is banned as a reference for everything.

## Gap audit (our new-player view vs the references)
1. **World:** one flat pale blue with low contrast, an empty sand floor, no focal point, little life.
   - The diving-game reference has dense colourful coral, god rays and depth haze.
   - The modern-UI reference has strong contrast and a landmark at spawn.
2. **HUD:** on PC our HUD inflated 1.3x (the tablet path), about 1.5x the reference's size.
3. **Motion:** no guiding arrows in the first seconds. The evolve cutscene darkened the screen flatly, so the shark went dark too.

## Built
- **Living reef (from the diving game):**
  - The 30 flat-top "Mesa" pillars with pink table-coral tops (the Shark Shop look) were swapped for the plain Spire and Boulder rock meshes.
  - 673 coral pieces form `MB_Map.CoralOutcrops`: 57 outcrops of 10–26 pieces around every rock in the reef and down the slope (thinner past r 440), plus a 90-piece `SpawnReef` around the spawn. They hug the terrain normal and have CanCollide and CanQuery off, so sharks never snag.
  - Coral is recoloured from the cyan textures to a reef palette: BranchCoral pink, violet, orange, yellow or teal; BubbleCoral yellow, orange, pink or violet; BrainCoral lime, orange, violet or rose; SeaFan magenta, violet, red or orange; Kelp greens. The original texture is kept in the `OrigTexture` attribute.
- **Water:**
  - Atmosphere: Density 0.40, Offset 0.18 (clear up close), Colour 46,150,196, Decay 10,38,98 (deep blue far away), Glare 0.15, Haze 1.9.
  - Colour correction: Contrast 0.26, Saturation 0.38. Exposure -0.1. Sun rays 0.13.
  - The 14 light-shaft beams are brighter (1.6) and more opaque.
  - Backups are in `ServerStorage.MB_Backup_TrenchRing_11Nov`: `Lighting_preDiving` and `Border/Landmarks/Reef_preDiving`.
- **HUD size:** `UIKit.AttachScale` now uses the 1.3 boost only on TOUCH tablets. On PC the HUD stays at 1.0, the reference's size; phones are unchanged.
- **Guide arrows (`MB_GuideArrows`, from the modern-UI reference's ground chevrons):**
  - What they look like: 8 white chevrons with a navy outline, laid on the sea floor by raycast. They flow from your shark toward the nearest fish you can eat, at 10 studs/s.
  - When they show: only for Evo 1, before your first Fossilize, and only when the nearest edible fish is 20–260 studs away. They fade in and out at both ends.
- **Evolve cutscene, hero light (from the RNG Battlegrounds and bbstudios references):**
  - The flat dark overlay is gone; it now sits at 0.92.
  - The world grade drops to Brightness -0.24, Saturation -0.45, Contrast 0.25. The Atmosphere closes in (Density 0.6, dark Colour and Decay) and is restored afterwards.
  - The shark gets a Highlight (the hero colour at fill 0.9, a white outline at 0.2), a PointLight in the hero colour (brightness 6), and rising glowing motes. It fades out with the rest and is cleaned up.
  - Result: dark water, the shark glowing in one colour, the name card on the dark.

## Files
`MEGA BITE/Art/../map/`: reef_before_after_diving.jpg, evolve_cutscene_hero_light.jpg, guide_arrows_first.jpg (the outputs folder).

## Next (my order)
1. The quest card, the toasts, and EXP "+N" pops with fly-to-counter to match the modern-UI reference's juice.
2. A focal landmark at spawn (a wreck with a glowing chest, or a giant coral arch) and a gentle giant passing near spawn.
3. A Red Trench boss/threat intro card (Wisp and Blade).
4. Bring back the caustic light on the terrain.
