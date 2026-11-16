---
tags: [mega-bite, 3d, exploded-diagram, mosasaurus]
created: 2026-11-16
---
# Mosasaurus Tier 6 - exploded sheet v1 (ChatGPT)

Method: [[Brain/Skills/roblox-3d-model-from-sheet/SKILL|3D model from sheet]] step 1a. Ref: the owner's "Mosasaurus - Tier 6" card (green low-poly, cyan crystal dorsal spikes, yellow eye), attached to the prompt.
Chat: https://chatgpt.com/c/6afa9256-2cc0-83ec-9825-d714f6e1b01a

Saved via overlay + 2 zoom captures stitched (1536x1024), so it is slightly resampled.

Parts (label = Blender object / MeshPart name): UPPER SKULL, LOWER JAW, UPPER TEETH ROW, LOWER TEETH ROW, MOUTH INTERIOR, EYE, NECK, TORSO, TAIL BASE, TAIL TIP, FRONT/BACK FLIPPER LEFT/RIGHT, 15 DORSAL CRYSTAL SPIKES (largest at mid-back).

Known gaps vs the card: body is straight (card is curved, pose it with the rig); no tail fluke drawn; flippers are shown side-on only, so take their plan shape from a turnaround sheet.

## Prompt
Create an image: a technical EXPLODED-VIEW diagram of the creature in the attached image, copied exactly from the attached image (same Roblox low-poly faceted style, flat shading, same colours: dark mossy green scales with darker green facets, lighter yellow-green belly, glowing cyan ice-crystal dorsal spikes, glowing yellow eye, dark red mouth interior, cream-white teeth). Orthographic SIDE view, nose pointing RIGHT, body straightened out horizontally (not curved). Every part pulled apart along the body's long axis with thin dashed alignment lines, each part labelled with a short name: UPPER SKULL, LOWER JAW, UPPER TEETH ROW, LOWER TEETH ROW, MOUTH INTERIOR, EYE, NECK, TORSO, TAIL BASE, TAIL TIP, FRONT FLIPPER LEFT, FRONT FLIPPER RIGHT, BACK FLIPPER LEFT, BACK FLIPPER RIGHT, DORSAL CRYSTAL SPIKES (shown as a row of separate crystals, largest at mid-back, smaller toward head and tail). Add a small ASSEMBLED side view at the bottom. Flat MAGENTA #FF00FF background, no shadows, no perspective, no glow halo bleeding onto the background, 1536x1024 landscape.

![[mosasaurus_exploded_v1.png]]

---
# Turnaround sheet v1 (same chat, 2026-11-16)
`mosasaurus_turnaround_v1.png`: side (top row), top (bottom left), front (bottom right). Replaces the old teal/orange `sheet.png` (evolution 9 look) for the Tier 6 model.

Checks:
- Top view is NOT the side view's length: side spans x 51-1478 (1427 px), top spans x 35-1043 (1008 px). Scale the top view by 1.416 before lofting. ChatGPT ignores the "same length" instruction, so fix it in analysis.
- Side view shows the 2 near flippers only; the top view shows all 4 spread out.
- Front view: the crystals stack into a tall crest and the open mouth is wider than the side suggests. Run step 1b (guide lines) before modelling the head.

## Prompt
Create a new image: a full orthographic TURNAROUND model sheet of the same creature, matching the first attached image and the exploded diagram you just made exactly (same Roblox low-poly faceted style, flat shading, same colours: dark mossy green with darker green facets and raised hexagonal scale plates on the back, yellow-green belly, 15 glowing cyan ice-crystal dorsal spikes largest at mid-back, glowing yellow slit eye, dark red mouth interior, cream-white teeth, pointed tail tip, 4 paddle flippers). Body straight, mouth slightly open as in the exploded sheet. Layout on a 1536x1024 landscape canvas: TOP ROW the full SIDE view, nose pointing RIGHT, spanning nearly the full width. BOTTOM LEFT the TOP view (looking straight down), nose pointing RIGHT, exactly the same length as the side view and directly under it, showing the flippers spread out and the crystal row down the spine. BOTTOM RIGHT the FRONT view (looking straight at the nose), showing the head, both eyes, the flippers spread, and the crystals sticking up. No labels, no text. Flat MAGENTA #FF00FF background, no shadows, no perspective, no glow halo bleeding onto the background.

![[mosasaurus_turnaround_v1.png]]

---
# Build v1 (2026-11-16)
Built in Blender 5.2 by `mosa6_build.py` from `mosa6_data.json` (measured from the turnaround by `analyse.py` + `data.py`). Rebuild from the script, never hand-edit.
- Run headless: `blender -b --factory-startup -P mosa6_build.py -- mosa6_data.json <out_dir> render <out>.blend`
- In the owner's Blender: scene **Mosasaurus T6**, collection `Mosasaurus_T6` (exec the script with `ARGS=[data, out_dir]`).
- **29 parts, 5,568 triangles**, length 6.4 m. Part names follow the exploded sheet: TailTip, TailBase, Torso, Neck, UpperSkull, LowerJaw, MouthInterior, Upper/LowerTeethRow, Eye, Front/BackFlipper Left/Right, DorsalCrystal_01-14, ScalePlates. Materials: `M6_Body` (vertex colour `Col`), `M6_Glow` (crystals and eye, emission).
- 14 crystals, not 15: both turnaround views show 14.

Checks (`compare.py`, `gates.py`, pictures in `checks/`):
- Silhouette IoU: **side 0.922** (passes 0.90), top 0.864, front 0.707.
- Top and front miss because the sheet's views disagree on the flippers: the side puts the tips further back, the top further forward, and the front draws them broad and low. The build puts the tips halfway and twists each paddle 35 deg. Owner to say which view wins.
- Gates PASS: zero open edges, every part faces outward (signed-volume fix for the thin flippers), every flipper and crystal rooted in the body.

Not done yet: rig (8 spine bones + Jaw) and Swim clip, baking colours into one texture, FBX export, Studio import, and which game it goes in.

**Owner decision (2026-11-16):** keep the flipper compromise (tips halfway between the side and top views, 35 deg twist). Top/front IoU below 0.90 is accepted for the flippers only.

---
# Rig + export v1 (2026-11-16)
`mosa6_export.py` (run on `mosasaurus_t6.blend`): `blender -b mosasaurus_t6.blend -P mosa6_export.py -- mosa6_data.json export`
- **`export/Mosasaurus_T6.fbx`** (237 KB, texture embedded) + `export/Mosasaurus_T6_tex.png` (512 px) + `export/Mosasaurus_T6_rigged.blend` (with a Swim action).
- Layout = FishKit species rig: nose at x=0, body down -X, **Root + Spine0..7 (head to tail) + Jaw** under Spine0, at the old Mosasaurus' bone span (x0 -0.1536, x1 -6.0736), so the existing Mosasaurus swim/bite clips should play on it. Not tested in Studio.
- Two skinned meshes: `Mosasaurus_T6` (body, eye, teeth, mouth, flippers, plates; 5,232 tris) and `Mosasaurus_T6_Crystals` (336 tris): set that MeshPart to **Neon** in Studio for the glow. The per-part names from the exploded sheet live on in `mosasaurus_t6.blend`; the FBX joins them (one skinned mesh is the house convention).
- Texture = palette atlas: each face's flat colour gets an 8 px cell (242 colours), so it matches the model exactly. No light bake: Roblox lights it.
- Weights: 3 nearest spine bones by position (Gaussian, like FishKit); LowerJaw, LowerTeethRow and MouthInterior 100% Jaw. Max 3 influences, no unweighted verts.
- Checked: FBX re-import (`fbxcheck.py`), bite pose (Jaw -22 deg opens cleanly), static 6 deg-per-bone bend from above (smooth, flippers follow). Pictures: `checks/mosa6_poses.jpg`, `checks/mosa6_bend_test.png`.
- Not done: Studio import + Neon setting, playing the old clips on it in Play, which game it goes in.

---
# Uploaded (2026-11-16)
- **Model asset 104031266367399** "MB_Mosasaurus_T6" (group 33151111, Open Cloud, moderation Approved). Its embedded texture came up as image **95389907506981**.
- Checked by `InsertService:LoadAsset` (loaded, never parented): 2 MeshParts (`Mosasaurus_T6`, `Mosasaurus_T6_Crystals`) + bones Root, Spine0-7, Jaw. Comes in 640 studs long (FBX in cm).
- Owner (16 Nov): **"Studio only, not in play"**: goes to `ServerStorage.MB_Mosasaurus_T6`, no game wiring. Script: `install_serverstorage.luau` (scales to 165 studs like evolution 9, crystals Neon, DoubleSided on). NOT run yet: MEGA BITE (place 131715256145044) was not open in Studio.

---
# Blender preview (2026-11-16)
Owner: "lets not import yet. lets just view in blender first with everything set up then when its ready lets import into roblox studio". `install_serverstorage.luau` stays NOT run until the owner says it is ready.
- Owner's Blender, scene **Mosasaurus T6**: the rigged export (rig + 2 meshes) replaced the unrigged parts; Swim action looping (frames 0-23, 24 fps, side-to-side S-wave, tail +/-8 deg); crystals use `Mosasaurus_T6_CrystalGlow` (emission 1.6 = Roblox Neon); EEVEE, Standard view transform (AgX turned the cyan glow white), dark-blue world + one sun, matte body (no white highlights on the flippers).
- Copy of that setup: `export/Mosasaurus_T6_preview.blend`.

---
# Tweaks v2 (2026-11-16, owner picked: glowing eye, thinner lip band, bigger flippers)
- **Glowing eye:** the lens is its own mesh `Mosasaurus_T6_Eyes` (Neon yellow in Studio); the slit pupil (`M6_EyePupil`) stays dark on the body mesh. FBX = 3 skinned meshes now (body 5,152 / crystals 336 / eyes 80 tris).
- **Thinner lip band:** only the outer edge of the jaw's top is cream (|y| > 0.86 of the jaw half-width); the rest is mouth red. Picture `checks/mosa6_head_34.png`.
- **Bigger flippers:** width 88 -> 112 px, 25 % longer (`len_k` 1.25 in mosa6_data.json).
- Gates PASS (30 parts). IoU side 0.927, top 0.814, front 0.691 (top/front lower on purpose: flippers now bigger than the sheet).
- Asset 104031266367399 is the v1 upload (before these tweaks). `install_serverstorage.luau` now needs the NEW upload's id (ASSET_ID) and also sets the eyes to Neon yellow. Not uploaded yet: the owner wants to approve in Blender first.

---
# v3: "exactly like the exploded diagram" (owner, 16 Nov)
The side contract is now the exploded sheet's **ASSEMBLED VIEW** (scaled x1.446 into the turnaround's side frame: `side_ex.png`; with the turnaround's top/front views: `sheet_v2.png`). Overrides read off the exploded sheet live in **`data_exploded.py`** (run after data.py).
Pipeline: `analyse.py sheet_v2.png` -> `crys.py` -> `data.py` -> `data_exploded.py` -> `mosa6_build.py` -> `gates.py` / `compare.py` -> `mosa6_export.py`.
- Part seams as the assembled view: tail tip 52-228, tail base 228-430, torso 430-1080, neck 1080-1205, head 1205-1478.
- **15 crystals** (assembled view draws 14; the parts row has 15, the extra tiny one added at the tail end).
- Belly: a straight band on whole ring quads (16-vertex rings, band from 112 deg = about 20 % of the body height), no zig-zag.
- Plates: two staggered rows (48 / 74 deg), 68 px apart, large flat hexes with dark bevel sides.
- Flippers: the near-side flippers' shapes, broad leaves hanging down and back (width 100, spread 120, no twist). The sheet staggers each left/right pair ~1 m apart so all four show from the side; a symmetric body can't, so both sides use the same position.
- Brighter palette sampled from the assembled view; head lines, jaw gape, eye and teeth from the assembled view.
- Glowing eye, thin lip band kept from v2. The v2 "bigger flippers" are replaced by the sheet's flipper size.
- 31 parts, 6,128 triangles, gates PASS. IoU vs the new contract: side 0.908, top 0.757, front 0.662 (top/front are the turnaround's views, which the exploded sheet doesn't have).
- Picture: `checks/mosa6_side_vs_exploded_assembled.png`. Not uploaded (asset 104031266367399 is still v1).

---
# VFX (2026-11-16, owner: "vfx?")
From the card: a cyan glow halo on the crystals and eye, and a cloud of cyan sparkles trailing behind and below the body.
- **Blender preview** (scene Mosasaurus T6, saved in `export/Mosasaurus_T6_preview.blend`): particle systems `SparkleTrail` (body, 2,600, drift back + down, life 64 fr) and `CrystalGlints` (crystals, 260, lift up), both instancing `MosaVFX_Sparkle` (glowing octahedron); compositor group `MosaBloom` (Glare, Bloom, threshold 0.8) shown live in the rendered viewport; camera `MosaHeroCam` (3/4 hero). Particles pre-roll from frame -60 (step frames in order, or the trail won't form). Still: `checks/mosa6_vfx_hero.png`.
- **Roblox version** (in `install_serverstorage.luau`, runs with the import, NOT run yet): `MB_SparkleTrail` ParticleEmitter on the body MeshPart (rate 70, world space so it trails, sinks slowly), `MB_CrystalGlints` on the crystals (rate 18, upward), PointLights `MB_CrystalGlow` (cyan, range 40) and `MB_EyeGlow` (yellow, range 10). Sprite: MEGA BITE's own flare 119101480444141. The halo itself comes from Neon + the game's Lighting Bloom (not changed).
- Note: an F12 render with the `MosaBloom` compositor comes out solid white; the live rendered viewport is correct (the still above is a viewport capture). Fix the final-render bloom before using renders for thumbnails.

---
# Eyes + card pose (2026-11-16, owner: "Eyes", "Curved card pose")
- **Eyes:** bigger and almond-shaped like the card / exploded EYE part (46 x 24 px, was 34 x 24), glow 3.0 in Blender (Neon in Roblox). Picture `checks/mosa6_eye_vs_sheet.png`.
- **Upper lip** is green again: the belly band no longer applies to the skull's underside (`belly_band=False`).
- **Card pose:** action `CardPose` on the rig (Spine pitch [16,18,13,7,-1,-9,-15,-18] deg, yaw [5,5,3,0,-3,-5,-5,-4], Root -20, Jaw -14): the card's dive, tail up, head down-right. Camera `MosaCardCam` (portrait 768x1024). Swim loop still there: action `Swim`.
- **One script for the whole preview:** `mosa6_preview.py` (exec in Blender with ARGS = [export/Mosasaurus_T6_rigged.blend, 'card' or 'swim']): reloads the model, glow materials, both actions, sparkle VFX, bloom, world, hero + card cameras, particle pre-roll.
- Gates PASS (31 parts, 6,128 tris). FBX re-exported. Not uploaded (asset 104031266367399 is still v1).

---
# v4: the CARD is the target (2026-11-16, owner put card and model side by side: "it have so much difference")
Why they differed: the ChatGPT sheets drifted from the card (yellow belly, small even crystals, small flippers, flat skin, slender body), and the Blender shot was flat (far camera, no outline). Card overrides live in **`data_card.py`** (after data_exploded.py):
- **Green all over**: the underside is a lighter green, no yellow belly. **Mottled skin** (smooth dark/mid/light patches by position). **Darker raised scutes.**
- **Chunkier body**: `yz_k` 1.22 (22 % deeper and wider, same 6.4 m length, so the rig and old clips still fit; the export's Jaw bone uses the same scale).
- **Crystals**: 22 (15 + 7 down the tail to its tip), 1.6x bigger, single spikes leaning back 10 deg with gaps (a 3-shard cluster was tried and read as one solid wall).
- **Flippers**: big paddles, front pair sticking out (spread 210, width 140, 1.45x long), no twist so the broad face shows.
- **Eye** orange-yellow (255,196,40); **teeth** longer (24 / 20 px).
- **Outline**: Roblox Highlight `MB_CardOutline` (cyan, fill off) in the install script. In Blender an inverted hull isn't culled by EEVEE, so the preview has no outline.
- 38 parts, 6,296 tris, gates PASS (tail tip now counts as body for the crystal-root check). FBX re-exported. Picture: `checks/mosa6_card_vs_model.png`.
- Still different from the card: its painted camo detail, its stronger S-curve (tail curling back over), the outline/background (card art). Not uploaded.
