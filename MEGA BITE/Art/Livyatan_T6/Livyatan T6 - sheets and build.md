---
tags: [mega-bite, 3d, livyatan, tier-6]
created: 2026-11-18
---
# Livyatan Tier 6 - sheets and build v1 (18 Nov 2026)

Method: [[Brain/Skills/roblox-3d-model-from-sheet/SKILL|3D model from sheet]] (incl. the new step 1a exploded sheet).
Reference: the owner's "Livyatan - Tier 6" card with notes: **OUTLINES**, **BLUE AURA**, arrows at the sparkle trail, **SCALES** (read as the segmented armour plates). `card_annotated.png`.
ChatGPT chat: https://chatgpt.com/c/6afc9c72-7c10-83ec-9c87-8c299adf9bc6

## Sheets
- `livyatan_turnaround_v1.png` = the CONTRACT (side / top / front). Close to the card.
  - Side view draws an UPRIGHT fish tail; top view a flat whale fluke. Built the flat whale fluke (top view + real animal). Owner can overrule.
  - Top view is 1/1.376 the side's length (scaled in analysis). Front view = 0.9 of side scale.
- `livyatan_exploded_v1.png`: parts and names: UPPER HEAD, LOWER JAW (hinge at its back end), UPPER/LOWER TEETH ROW, MOUTH INTERIOR, EYE, ARMOUR SEGMENT 1-7 (head to tail), TAIL STOCK, TAIL FLUKE, PECTORAL FIN L/R. Its runes are redrawn differently, so runes come from the turnaround.
- `livyatan_head_v1.png`: head close-up; drifted (shorter head). Used only for the eye look (round glowing lens under a brow ledge).
- Prompts: in the chat above (turnaround, exploded, head).

## Pipeline (rebuild, never hand-edit)
`analyse.py livyatan_turnaround_v1.png` -> `data.py` (-> `livy6_data.json`) -> `runes.py` (-> `runes_2d.json`, needs cv2, so outside Blender) -> `livy6_build.py` -> `gates.py` / `compare.py` -> `livy6_preview.py`
- Headless: `blender -b --factory-startup -P livy6_build.py -- livy6_data.json out render livyatan_t6.blend`
- Owner's Blender: scene **Livyatan T6**, collection `Livyatan_T6` (exec livy6_build.py with `ARGS=[data, out_dir]`, then livy6_preview.py). Copy: `livyatan_t6_preview.blend`.

## Build v1
- **19 parts, 8,391 triangles**, 8 m long. One object per exploded-sheet part (`L6_` prefix) + `RunesGold` / `RunesCyan` (traced from the sheet, ray-cast onto the skin as glowing decals from the side, top and front views).
- Armour segments: separate closed lofts whose ends shrink to 0.86 and overlap 2 px -> V grooves, dark groove colour, no see-through slit.
- Eye: half-dome cyan lens seated in a carved socket, turned 30 deg forward.
- Mouth interior only to x1290: the sheet's gape in front of it is see-through.
- Palette lifted from the sheet medians (they sit in shade) to the card's lit look.

## Checks (`checks/`)
- Silhouette IoU: side 0.87 (**0.945 without the tail**, the tail differs by design), top 0.887, front 0.839. Below 0.90 on top/front because the sheet's views disagree on the fins (side: low and back, top: forward and wide, front: steep down) and the fluke. Fins are a split-the-difference compromise. Picture `compare.png`, `head_compare.png`.
- Gates PASS: zero open edges on every solid part (runes were flat decals in v1-v1.2; modelled since v1.3), outward normals, fins + fluke + jaw rooted in the body.
- Preview look (EEVEE, `livy6_hero.png`): cyan-white OUTLINE + BLUE AURA (one voxel-remeshed copy of the body pushed out, only its back faces glow, BLENDED; per-part shells drew a ring at every groove; the shells must not cast shadows or the body goes black), gold + cyan sparkles.

## v1.1 gap fixes (owner: "Fix the gaps", 18 Nov)
- **Eye:** bigger (66 x 40 px, the card's size, not the turnaround's), less clipped half-dome, hot white-cyan centre, sits proud of a carved socket under a carved **brow ledge** (head now 32 ring verts + 8 px stations round the eye so the carve has geometry). Preview: own glow material (7) + two small cyan point lights (Roblox: Neon + PointLight).
- **Teeth:** upper row inset to 0.82 of the head width 18 px AHEAD of each tooth, front row moved back 6 px: the cones poked out of the narrowing snout's sides.
- **Sparkles:** now trail behind and below. Cause: a particle point cache can't start before frame 1, so the -80 pre-roll was never simulated. Emission now starts at frame 1 and the preview sits at frame 80. Emission 2.5 (8 blew them out to white).
- 19 parts, 9,471 tris, gates PASS, IoU unchanged (side 0.871 / no-tail 0.946, top 0.887, front 0.837). Picture `checks/livy6_hero_v2.png`.

## Still open
- Top/front IoU under 0.90 = the sheet's views disagree (fins, fluke); kept the split-the-difference fins. Owner can pick a view to win.
- Rig + FBX done in v1.4 (below). Not done: upload + Studio install (owner approves in Blender first).

## v1.2 (18 Nov, owner asked "are these normal" about blocky shapes in solid view)
- The blocky shells were the PREVIEW glow helpers (`L6_OutlineShell`, `L6_AuraShell`: voxel-remeshed, pushed-out copies of the body). They now live in their own collection **L6_PreviewFX**, hidden in the viewport while modelling; turn it on for the rendered look. They are never exported.
- Real fix found while checking: the tail stock ended in a flat stub over the fluke root; it now runs out to x70 and tapers onto the fluke. Gates PASS, side IoU 0.878.
- The small round bumps on the body in solid view are the sparkle particles, not geometry.

## v1.3 runes MODELLED (18 Nov, owner: "these details should be modelled instead of just slapping on a texture")
- `RunesCyan` / `RunesGold` are now solid raised inlays, not flat decals: each traced glyph outline is resampled every ~6 px, filled (no inner verts), ray-cast onto the skin, pushed 2.5 px proud and 1.5 px sunk into the skin, with walls. One winding per glyph; normals blended with the glyph's mean so glyphs over a groove don't fold; vertices the outline passes twice drop their fan; inside-out glyph shells are flipped.
- Gates now check the runes too: zero open edges, every glyph's signed volume positive. **Gates PASS.** 19 parts, 16,656 tris (RunesCyan 4,220, RunesGold 3,959; each under Roblox's 20K per mesh). IoU side 0.877 (no-tail 0.944), top 0.888, front 0.836.
- In Roblox the rune meshes become Neon parts, so the glow comes from real geometry.

## v1.4 rig + export (18 Nov)
`livy6_export.py` (adapted from the Mosasaurus T6): `blender -b livyatan_t6.blend -P livy6_export.py -- livy6_data.json export`
- **`export/Livyatan_T6.fbx`** (686 KB, texture embedded and packed) + `export/Livyatan_T6_tex.png` (512 px palette atlas, 227 colours, 8 px cells) + `export/Livyatan_T6_rigged.blend` (with the Swim action).
- 4 skinned meshes: `Livyatan_T6` body 5,408 tris, `Livyatan_T6_RunesCyan` 5,760, `Livyatan_T6_RunesGold` 5,392, `Livyatan_T6_Eye` 96 (each under 20K; the modelled runes are the heavy part). Max 3 bone influences, nothing unweighted.
- Rig: Root, Spine0-7 (the old Leviathan's bone layout from `Leviathan_hse/rig.json`, stretched x8/7 to 8 m, so the Leviathan clips can play on it), Jaw under Spine0, hinged at the jaw's back end (x1100, the exploded sheet). Swim = carangiform S-wave, frames 0-23.
- Checked: FBX re-import (`fbxcheck.py`), bite pose (Jaw -22 deg opens cleanly), swim from above. Picture `checks/livy6_poses.jpg`.
- Owner's Blender: collection `Livyatan_T6_Rigged` (rig moved 4.5 m to the side of the parts), runes + eye with glow materials, Swim playing. Saved in `livyatan_t6_preview.blend`.
- `install_serverstorage.luau`: NOT run. Parks `MB_Livyatan_T6` in ServerStorage at 165 studs: runes + eye Neon, gold + cyan sparkle trails, blue aura emitter, rune/eye PointLights, cyan Highlight outline. Needs the FBX uploaded first (set ASSET_ID).
