---
date: 2026-11-05
tags: [gymarc, plates, art, progress]
---
# GYM ARC - Plates v4: a stripe on every plate + a metal look (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plates: [[2026-11-05 GYM ARC Plate Forge booth and forge window]] · Concept: `GYM ARC/Assets/plates/gymarc_plates_concept_v3.png`

In Studio only. **Not published.** Waiting for ONE owner step (the mesh import, below); until then the plates look exactly as before.

Owner (5 Nov): only the outermost plate had the edge stripe, inner plates plain white, plates like matte plastic. Wanted: a stripe on EVERY plate by its size / tier, polished metal via SurfaceAppearance (Color + Metalness + Roughness maps, no Reflectance), Ruby / Diamond crystal, the words on the outer face as before, one MeshPart per plate <= 50 triangles, shared looks.

## Made
- `GYM ARC/Assets/plates/metal_v4/` (made by `make_plates.py`, pure Python):
  - `gymarc_plate_disc.obj`: a 12-sided disc, **48 triangles**, UVs, axis X, 1 x 1 x 1 (the old PlateMesh was 1,120; a Roblox cylinder part ~790 up close).
  - 14 ColorMaps (512 x 256: the face circle + the rim strip): std 5 chrome, 10 green, 25 yellow, 35 orange, 45 blue, 55 red, 65 black, 75 teal (brushed steel face, hub, the stripe on the face edge and the whole rim); Bronze / Silver / Gold / Platinum metal in their colour with their tier stripe; Ruby red faceted crystal; Diamond clear (alpha 150) crystal.
  - Shared maps: metal Metalness (plate 1, painted stripe ring 0) + Roughness (face 0.25, rim / bevel 0.15, paint 0.45); crystal Metalness / Roughness (face 0 / 0.08).
- Uploaded on the owner's account (like the icons): 18 images. `ReplicatedStorage.GymAssets.PlateLooks`: 14 SurfaceAppearances (Diamond AlphaMode Transparency).
- `Shared/PlateLook`: when `GymAssets.PlateDisc` exists, EVERY plate (inner too) is one Disc with its type's SurfaceAppearance (swapped only when the type changes; pooled in PlateClient), Reflectance 0, no stripe / inset parts; the outer plate keeps the invisible NumberFace ("M WEIGHTS" + the number, white with the dark outline, PlateNumbersClient). Members / VIP themed plates use the ruby / diamond look.

## Owner step (1 min)
Studio > Import 3D > `GYM ARC/Assets/plates/metal_v4/gymarc_plate_disc.obj` > name the MeshPart **PlateDisc**, put it in **ReplicatedStorage.GymAssets** (Size 1, 1, 1, axis along X like the old PlateMesh). Studio can't upload a mesh made by a script (AssetService.CreateAssetAsync "not available yet"), so the import has to be done by hand. Then the plates switch over by themselves; I'll take the in-game shots and the FPS.

## Tested
- Look: a session copy of the disc built in Studio (not saved): 45 stack, 55 / 45 mix, Ruby / Diamond, close and from 20 studs (Edit mode, outdoors: the in-game words show only in Play). ![[GYM ARC/Screenshots/2026-11-05_plates_v4/03_55_45_mix_close.jpg]] ![[GYM ARC/Screenshots/2026-11-05_plates_v4/04_diamond_ruby_close.jpg]] ![[GYM ARC/Screenshots/2026-11-05_plates_v4/05_all_from_20_studs.jpg]]
- Performance (Studio PC with tools attached, the Starter Gym with every bar at its heaviest standard weight, client-side): BEFORE 309 plate parts, 42 FPS. With the session disc 248 parts (no stripe parts), 37 FPS, but that session mesh doesn't survive into Play (it drew as a box), so the real after-number needs the imported mesh. A real phone: not measurable from here.

## Also (owner, 5 Nov)
- BEST LIFT (profile) and the old heaviest-lift board value no longer count the Truck Pull (8,000-15,000 lb is a pull, not a lift): `ProfileService.bestLift`, `LeaderboardService.heaviestLift`.
