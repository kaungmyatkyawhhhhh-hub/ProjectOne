---
tags: [mega-bite, vfx, sfx, bugfix, minnow, build-log]
date: 2026-11-14
---
# MEGA BITE - sprint trail + sound, the evolve loop, the Minnow from above (14 Nov)
Saved in Studio, not published.

## Sprint VFX + SFX (owner: "when sprinting, leave like a vfx trail of water ... and also some sfx")
- New `StarterPlayerScripts.MB_SprintFx`: foam Trail from the tail tip (rides the last spine bone, so it snakes with the swim),
  two thin wake Trails off the flanks, a bubble ParticleEmitter (the game's own bubble 125800378157946) + a push-off burst.
  All sizes scale with the shark's Length. Sounds from our own set: DartWhoosh (x0.78 pitch) on the start, Swish each stroke,
  Bubbles every ~1 s.
- Other players see it: MB_Swim sends "Sprint" on/off -> MB_SwimServer sets the model attribute `Sprinting`.
- Backups: MB_SwimServer_preSprintFx_14Nov, MB_Swim_preSprintFx_14Nov. Checked in Play (Megalodon): trail + bubbles, no errors.

## "I fall in a loop, get teleported back up, can't move" (Great White evolve card on screen)
- Cause: Studio saves the owner's REAL data. The Studio-only `[` key (DevEvo -1) lowered the evolution but kept ~3M EXP, so
  every fish eaten evolved ONE step with a full cutscene (controls locked, respawn 3 studs up), over and over.
- Fix 1 (all players, MB_FishServer.evolveCheck): straight to the HIGHEST evolution the EXP has earned, one cutscene.
  Test: fresh player given 50,000 EXP -> one jump to evolution 7, one respawn.
- Fix 2 (Studio): `[` / `]` set `DevHold` on the player for the session: no auto re-evolve, EXP untouched.
- Backup: MB_FishServer_preEvoJump_14Nov.
- The owner's real save still has a lower evolution with ~3M EXP: on the next real join the first fish takes it to the
  Leviathan in ONE evolve.

## Minnow from above (owner screenshot: "so ugly from the top, it looks abnormal")
- Was a spearhead from above: widest at the eye bulges, straight taper to a thin tail.
- Edit of the nose version: body widened from the head back (x1.18 -> x1.42 at mid-body -> x1.0 at the tail fin), eye domes
  pressed further (0.10, wider falloff so no crater ring). Nose, tip smoothing, texture, bones unchanged.
- `Art\Minnow_hse\nose_14Nov\Minnow_hse_nose_v4_topfix.fbx` -> model 122404387336994 (Approved), mesh 93435944642225, texture
  95082541061776. Backup `MB_Minnow_preTopFix_backup_14Nov`.

## Minnow: smooth outline from above (owner, with a real fish photo: "its suppose to be like this ... all bumpy. keep our width")
- The body's half-width was measured every 0.05 units along its length and replaced by ONE smooth hump (widest at x -1.25,
  never widening again toward the nose or tail, same max width). The surface bumps (old relief) were smoothed (10 passes), and the
  side-view height per slice kept. All of this fades out toward the nose (x -0.45 -> -0.05), so the round C nose stays.
- The dark outline shell follows its body point; the fins slide with the body side they touch (nothing detaches).
- `Art\Minnow_hse\nose_14Nov\Minnow_hse_v5_smooth.fbx` -> model 94647907639448 (Approved), mesh 108043282655363, same texture
  and skins. Backup `MB_Minnow_preSmooth_backup_14Nov`. Checked in Studio from above and 3/4.

## Faces repainted (owner: Clownfish "mouth texture weird" + "differences in texture based on the face direction"; Minnow "texture needs redesigning after the model change", "eyes not at the eye bump", "now its blurry", "eye should face a bit forward, ~10 deg")
Method (Blender, numpy): every texel of the body is rasterised to its 3D point + normal, then painted in 3D:
- the front of the head blends (by how much it faces forward, no hard edge) into a top-to-bottom colour gradient sampled from the
  SIDE skin near the head; eyes protected (Clownfish) or repainted (Minnow); ONE centred smile; island edges padded (no black bleed).
- Gotchas: Blender image rows run bottom-up (row = v*H); half the mesh is the inverted outline SHELL (render with backface culling
  ON or it hides the body); new Open Cloud "Image" uploads can take 5+ min to serve and Studio caches an early failed load for the
  session -> wait ~5 min before the first request; check by putting the texture on a preview model (PreloadAsync lies).
### Clownfish (Piranha key)
- Body: smooth outline from above (same width). Model 122196184207784. Texture 116819693430896.
  Skins: Coral 121644393185718, Lantern 80301870440702, Ghost 108005810031726, Ember 108714310651768.
  Backups: MB_Piranha_preFaceFix_backup_14Nov, GameConfig_preClownFace_14Nov / _preFaces2_14Nov.
### Minnow
- Body: smooth from above, ORIGINAL nose (owner: "keep the nose flat like before"), eyes smoothed round the bumps.
- The front of the head got its OWN texture area (UV re-map): side paint squeezed into the left 62.5% (640 px), front faces
  (normal.x > 0.5) projected from the front into a 370x370 px area -> ~5x sharper face. Eyes centred on the eye bumps
  (-0.421, +-0.536, 0.124), turned ~10 deg more forward, R 0.30. Old skins do NOT fit this layout.
- Model 96937410372696 (mesh 105120204506808), texture 127487180193418. Skins: Coral 76198960170888, Lantern 113431312755378,
  Ghost 101365112110899, Ember 90992075977855. Backup MB_Minnow_preFaceUV_backup_14Nov.
- Files: Art\Minnow_hse\face_14Nov\, Art\Relief_13Nov\Piranha\face_fix_14Nov\.
