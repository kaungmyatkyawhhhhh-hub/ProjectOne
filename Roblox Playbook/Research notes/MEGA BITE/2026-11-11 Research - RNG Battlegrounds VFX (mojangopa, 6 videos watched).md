---
date: 2026-11-11
tags: [research, vfx, megabite, tiktok, rng-battlegrounds]
---
# RNG Battlegrounds VFX (@mojangopa): what makes them look pro (watched 11 Nov 19:00)

Owner at 18:41: "our vfx SUCKS, just look at those RNG Battleground tiktok videos". At 18:43: "cant u use /ytdlp-video-watch to watch it".
Downloaded with yt-dlp on the owner's PC (run through Blender's Python) into `MEGA BITE\Ref\rng_tiktok\`, with mp4 and info.json. Contact sheets were made with ffmpeg.

| Video | What |
|---|---|
| 7705457877497990422 "Making Roblox auras" (10.6K views) | ROOT ACCESS (red hacker: floating glyph code columns, a red HUD ground ring), NOVA (violet: white-hot loop arcs swirling up, a white starburst core, a runic ground circle), THALASSOR (teal jellyfish + bubbles + a ghost manta), CHRONOS (teal clock face + gears + a ground clock dial, "1 in 2,000"), DREADNOUGHT (gold mech + an ornate gold ground circle + sparks) |
| 7705525549464030486 "Part 2" (15.3K) | AXIOM ZERO (blue gyroscope rings around the player, white lightning cracks on the floor, a glyph ring), RIMEHEART (ice crystal crown + aurora), RAZORBLOOM (teal crystal flower halo + roots), SAUM (monochrome black/white: a broken ring + floating serif words + shards), GILDED HOURGLASS (a gold hourglass + an orbiting light ribbon + an ornate base with candles) |
| 7705961352082230550 "Part 3" (20.8K) | CELESTIAL (gold wings + halo + a light column + a gold rune ring), MIDNIGHT LOTUS (pink lotus + petals + white needle spikes + a floral floor), ECLIPSE (black sun with a fire corona + a huge red-gold shockwave ring), UNBOUND (white swirling smoke + a rune circle), CHRONOS V2 (violet crystal fan crown), UNWRITTEN (black ink shards + crescents) |
| 7705869022247570710 "insane cutscenes" | THALASSOR sea monster rising in a storm, SAUM monoliths slam down, DREADNOUGHT mech, NOVA burst |
| 7705095621400726806 "ultimate" | GIANT 3D mesh blades and arcs (dark metal + blue neon + yellow stripes) sweep around the player; ground shockwave rings; a white-out flash; huge crescent rings slam into the ground |
| 7706610542370196758 "Top 5 tools" (41K) | (tools list, not watched for VFX yet) |

## The rules (the reasons it reads as "pro")
1. **Built from 3D meshes, not flat sprites.** Every aura is a little sculpture: a glowing ground circle plus a hero object (wings, clock, sun, hourglass, crystals) plus orbiting thin rings and arcs plus star glints plus motes.
2. **A ground circle under EVERY effect:** concentric glowing rings, tick marks, runes or numerals, slowly rotating.
3. **One hero colour on darkness**, emissive with a white-hot core and bloom. White and black only for the special ones.
4. **Slow constant motion** (rings rotating, objects bobbing, motes drifting) **plus one burst** (a flash, a shockwave, a starburst).
5. **Scale:** big effects are huge next to the character (the ultimate's arcs are 5–10x the player).
6. **A name card on every reveal:** clean white caps (sometimes "1 in 2,000").

## For MEGA BITE (original, ocean-themed, no copying)
- **VFX kit:** a ground glyph circle (ocean runes: waves, scale arcs, shark-tooth ticks, a compass rose), thin neon rings and broken arcs (MeshParts, Neon), a ring of teeth (the "jaw halo"), 4-point star glints, motes, light columns, shockwave rings.
- **Use it in:**
  1. Evolve cutscene: an aura per evolution in its hero colour.
  2. Abilities (Roar = shockwave rings; Ram = giant crescent arcs; Frenzy = red spiral rings).
  3. Skins as real auras.
  4. The bite.

## Built from it (19:10–19:45): MB_VFX.AuraKit + 3D ability layers
- **Kit art** (`MEGA BITE/Art/VFXKit/`, made by code so it's original):
  - Images: an ocean rune circle (shark-tooth ring, ticks, wave/shell/fish/bubble/compass glyphs, an 8-point compass star) 108734722465875; a 4-point star glint 87315468959310; a soft glow 98257710242776; a shock ring 132453573028089; a beam streak 103771105778948.
  - Meshes (bpy → FBX; in `ReplicatedStorage.MB_VFX.Kit`, Neon): RingThin 139335930830038, ArcBroken (3 tapered arcs) 86205609819340, ToothHalo (a ring of 18 shark teeth) 129305855949568, Crescent blade 79695177185212.
- **`MB_VFX.AuraKit`:**
  - `Aura(model, {colour, size, life, resolve})`: a rotating rune circle + a counter-rotating inner circle under the shark, a 3-ring gyroscope (2 thin rings + a broken arc band), a floating crown of teeth, a light column (Beam), star glints, rising motes, a glow core, a point light, and a burst (glint + shockwave). It follows the new model when evolving swaps the shark.
  - Also: `Shockwave`, `Glint`, `RingTunnel` (neon rings punched out along a direction, growing as they fly) and `Crescent` (a giant neon blade sweeping an arc).
- **Evolve cutscene:** an aura in one hero colour per evolution (cyan, red, mint, blue, gold, white, violet) on the darkened water.
- **`AbilityVFX` gets 3D layers on top of the sprites:**
  - Frenzy: twin crescent jaws snapping.
  - Torpedo: a ring tunnel and a glint.
  - Shark Sense: neon sonar shockwaves.
  - Hammer Ram: a glint, two crossing gold crescents and a ring tunnel.
  - Breach: a white shockwave and rings shooting up.
  - Tidal Roar: a glint, a 6-ring tunnel and shockwaves.
  - Big bite: neon crescent jaws.
  - Others evolving: a short gold aura.
- Checked in Play: the real Tidal Roar (F) fires the tunnel, with no script errors.
- **Found:** the image 119101480444141 (the "flare" used by the old cutscene glow and the trench intro) fails to load ("No asset content representation"), so that glow never showed. To fix: replace it with the kit's glow.
