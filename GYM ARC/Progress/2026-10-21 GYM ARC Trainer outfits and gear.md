---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Trainer outfits and gear

Prompts: [[2026-10-21 GYM ARC Prompt - 34 Trainer outfits and gear meshes]], [[2026-10-21 GYM ARC Prompt - Trainer clothes look ripped]], [[2026-10-21 GYM ARC Prompt - Trainer portrait export]].

## Done
- **Why the clothes looked ripped:** the stage meshes' sideways texture mapping jumps at every corner of the classic template (1 triangle in 5). Details: [[GYM ARC - Muscles and Bodies]].
- **Trainer outfits:** one solid color per outfit on the muscle pieces (no classic Shirt / Pants), sleeves to the elbow / wrist, shorts to the knee (the shorts piece alone looked like underwear), no seams, gaps or white lines at any size. Coaches 1-4 have shoes. [[GYM ARC - Personal Trainers]].
- **Gear meshes** (the planner's .glb files, imported by the owner, in `ReplicatedStorage.GearMeshes`): belts, wraps, knee sleeves, straps, whistles, fitted to the muscles on each client. Trainers: whistles for coaches 1-4, Rex and Duke belt + wraps, Volta belt + knee sleeves (harness removed), Atlas gold cuffs + gold waistband. Players' shop gear uses them too; Elite gear is silver.
- **Followers:** a trainer clone made before his template had fully arrived missed a leg, hair and gear; now the client waits for it.
- **Portraits for the planner:** 16 PNGs in `Downloads\gym_arc_trainer_portraits\` (re-shot with the new outfits).
- Tests: all suites pass (the trainers suite checks outfits and whistles).

## Screenshots
![[GYM ARC/Screenshots/trainer_outfits/01_sam_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/01_sam_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/02_nia_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/02_nia_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/03_lou_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/03_lou_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/04_rex_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/04_rex_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/05_duke_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/05_duke_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/06_volta_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/06_volta_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/07_shadow_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/07_shadow_side.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/08_atlas_front.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/08_atlas_side.jpg]]

Player with Pro belt + wraps + knee sleeves (small body), and the same gear on a mass monster body:
![[GYM ARC/Screenshots/trainer_outfits/player_gear_g000.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/gear_gmon.jpg]]
![[GYM ARC/Screenshots/trainer_outfits/portraits_sheet.png]]

## Needs the owner
- Players' own avatar shirts still tear on other screens (the same stage meshes). Fix = re-export the stage meshes with clean texture seams for the owner to import. Wanted?
- The muscle meshes only take solid colors cleanly, so there are no trims (stripes, zips, collars) on the clothes; the detail is in the gear. OK?
- The mass monster gear test used a trainer body (the player's live body didn't grow from the test setting in that run).
