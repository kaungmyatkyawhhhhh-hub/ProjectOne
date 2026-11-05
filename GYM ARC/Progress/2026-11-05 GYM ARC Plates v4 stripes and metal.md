---
date: 2026-11-05
tags: [gymarc, plates, art, progress]
---
# GYM ARC - Plates v4: a stripe on every plate + a metal look (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plates: [[2026-11-05 GYM ARC Plate Forge booth and forge window]] · Concept: `GYM ARC/Assets/plates/gymarc_plates_concept_v3.png`

In Studio only. **Not published.** The owner imported the mesh (5 Nov): **the v4 plates are ON in Studio** (see "Live in play" below).

Owner (5 Nov): only the outermost plate had the edge stripe, inner plates plain white, plates like matte plastic. Wanted: a stripe on EVERY plate by its size / tier, polished metal via SurfaceAppearance (Color + Metalness + Roughness maps, no Reflectance), Ruby / Diamond crystal, the words on the outer face as before, one MeshPart per plate <= 50 triangles, shared looks.

## Made
- `GYM ARC/Assets/plates/metal_v4/` (made by `make_plates.py`, pure Python):
  - `gymarc_plate_disc.obj`: a 12-sided disc, **48 triangles**, UVs, axis X, 1 x 1 x 1 (the old PlateMesh was 1,120; a Roblox cylinder part ~790 up close).
  - 14 ColorMaps (512 x 256: the face circle + the rim strip): std 5 chrome, 10 green, 25 yellow, 35 orange, 45 blue, 55 red, 65 black, 75 teal (brushed steel face, hub, the stripe on the face edge and the whole rim); Bronze / Silver / Gold / Platinum metal in their colour with their tier stripe; Ruby red faceted crystal; Diamond clear (alpha 150) crystal.
  - Shared maps: metal Metalness (plate 1, painted stripe ring 0) + Roughness (face 0.25, rim / bevel 0.15, paint 0.45); crystal Metalness / Roughness (face 0 / 0.08).
- Uploaded on the owner's account (like the icons): 18 images. `ReplicatedStorage.GymAssets.PlateLooks`: 14 SurfaceAppearances (Diamond AlphaMode Transparency).
- `Shared/PlateLook`: when `GymAssets.PlateDisc` exists, EVERY plate (inner too) is one Disc with its type's SurfaceAppearance (swapped only when the type changes; pooled in PlateClient), Reflectance 0, no stripe / inset parts; the outer plate keeps the invisible NumberFace ("M WEIGHTS" + the number, white with the dark outline, PlateNumbersClient). Members / VIP themed plates use the ruby / diamond look.

## Owner step (1 min) - DONE 5 Nov
Studio > Import 3D > `GYM ARC/Assets/plates/metal_v4/gymarc_plate_disc.obj` > name the MeshPart **PlateDisc**, put it in **ReplicatedStorage.GymAssets** (Size 1, 1, 1, axis along X like the old PlateMesh). Studio can't upload a mesh made by a script (AssetService.CreateAssetAsync "not available yet"), so the import has to be done by hand. Then the plates switch over by themselves; I'll take the in-game shots and the FPS.

## Tested
- Look: a session copy of the disc built in Studio (not saved): 45 stack, 55 / 45 mix, Ruby / Diamond, close and from 20 studs (Edit mode, outdoors: the in-game words show only in Play). ![[GYM ARC/Screenshots/2026-11-05_plates_v4/03_55_45_mix_close.jpg]] ![[GYM ARC/Screenshots/2026-11-05_plates_v4/04_diamond_ruby_close.jpg]] ![[GYM ARC/Screenshots/2026-11-05_plates_v4/05_all_from_20_studs.jpg]]
- Performance (Studio PC with tools attached, the Starter Gym with every bar at its heaviest standard weight, client-side): BEFORE 309 plate parts, 42 FPS. With the session disc 248 parts (no stripe parts), 37 FPS, but that session mesh doesn't survive into Play (it drew as a box), so the real after-number needs the imported mesh. A real phone: not measurable from here.

## Live in play (after the owner's import, 5 Nov)
- The owner imported the OBJ into Workspace (a Model `gymarc_plate_disc` with a MeshPart `default`, mesh rbxassetid://120545642266212). I moved the MeshPart to `ReplicatedStorage.GymAssets.PlateDisc` (Size 1, 1, 1, Anchored, no collide / touch / query, no shadow, like PlateMesh; RenderFidelity Automatic -> **Precise** like PlateMesh, so no crude far version / "blobs" as on 4 Nov) and removed the empty model.
- Play (temporary save): 94 plates near the camera became discs, every one with its SurfaceAppearance (std_5 / 10 / 25 / 45, ruby in the Members gym, diamond in the VIP gym). No errors.
- Fixed: through a clear Diamond plate you saw the plate behind's "M WEIGHTS" too (twice). `PlateClient`: a plate behind a Diamond-look plate doesn't print its face any more (VIP deadlift 4 -> 2 NumberFaces, one per side).
- Parts (Starter Gym view, all the near bars): old look 535 plate parts -> discs 424 (-21%); each plate is 48 triangles (the old outer plate mesh was 1,120). FPS: not measurable here (Studio caps an unfocused window at 15 fps, both runs read 15.0); a real phone: not tested.
- The 12 sides show up close on the rim (the <= 50-triangle budget); from normal camera distance they read round.
![[GYM ARC/Screenshots/2026-11-05_plates_v4/07_ingame_25_45_face_close.jpg]]
![[GYM ARC/Screenshots/2026-11-05_plates_v4/06_ingame_starter_deadlift.jpg]]
![[GYM ARC/Screenshots/2026-11-05_plates_v4/08_ingame_members_ruby.jpg]]
![[GYM ARC/Screenshots/2026-11-05_plates_v4/11_ingame_vip_diamond_fixed.jpg]]
![[GYM ARC/Screenshots/2026-11-05_plates_v4/10_ingame_starter_gym_overview.jpg]]
(`09_ingame_vip_diamond_before_fix.jpg` = the double "M WEIGHTS".)

## Also (owner, 5 Nov)
- BEST LIFT (profile) and the old heaviest-lift board value no longer count the Truck Pull (8,000-15,000 lb is a pull, not a lift): `ProfileService.bestLift`, `LeaderboardService.heaviestLift`.
