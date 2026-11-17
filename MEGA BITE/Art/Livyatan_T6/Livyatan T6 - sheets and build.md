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
- Gates PASS: zero open edges on every solid part (runes are flat decals by design), outward normals, fins + fluke + jaw rooted in the body.
- Preview look (EEVEE, `livy6_hero.png`): cyan-white OUTLINE + BLUE AURA (one voxel-remeshed copy of the body pushed out, only its back faces glow, BLENDED; per-part shells drew a ring at every groove; the shells must not cast shadows or the body goes black), gold + cyan sparkles.

## v1.1 gap fixes (owner: "Fix the gaps", 18 Nov)
- **Eye:** bigger (66 x 40 px, the card's size, not the turnaround's), less clipped half-dome, hot white-cyan centre, sits proud of a carved socket under a carved **brow ledge** (head now 32 ring verts + 8 px stations round the eye so the carve has geometry). Preview: own glow material (7) + two small cyan point lights (Roblox: Neon + PointLight).
- **Teeth:** upper row inset to 0.82 of the head width 18 px AHEAD of each tooth, front row moved back 6 px: the cones poked out of the narrowing snout's sides.
- **Sparkles:** now trail behind and below. Cause: a particle point cache can't start before frame 1, so the -80 pre-roll was never simulated. Emission now starts at frame 1 and the preview sits at frame 80. Emission 2.5 (8 blew them out to white).
- 19 parts, 9,471 tris, gates PASS, IoU unchanged (side 0.871 / no-tail 0.946, top 0.887, front 0.837). Picture `checks/livy6_hero_v2.png`.

## Still open
- Top/front IoU under 0.90 = the sheet's views disagree (fins, fluke); kept the split-the-difference fins. Owner can pick a view to win.
- Not done: rig (8 spine + Jaw), Swim, texture bake, FBX, Roblox (Highlight outline, Neon runes/eye, aura + sparkle emitters).
