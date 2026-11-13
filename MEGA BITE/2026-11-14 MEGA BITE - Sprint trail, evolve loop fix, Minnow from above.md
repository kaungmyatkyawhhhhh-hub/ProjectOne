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
