---
tags: [city-legends, yangon, 1to1, terrain, grass, fix]
created: 2026-11-17
---
# Concrete blobs on the grass removed (P1-P3)

Owner's screenshots: grey irregular "concrete blob" patches all over the grass (yards, beside streets, open lots), like spills.

## Cause
- `tools/yangon/city/green_1to1.py` (STYLE "clean") painted terrain **Concrete** on every OSM `paved` area (parking, commercial / retail land use, pools) and on "forecourts" (up to 9 m between a walk-up / shop / civic building and the road, edges wobbled by noise). `YangonGreen1to1.paint` wrote it into the terrain; smooth terrain blends a painted patch into a soft blob.
- Studio sample (a ray every 32 studs): P1 Concrete 2,986 + Ground 591 samples, P2 Concrete 2,448, P3 Concrete 9,715; about half of each under road parts (road beds). Nothing else non-grass on land.
- Not the cause: `RoadVerge05.luau` (only Grass / Air), `PlacesApply.grade` (only Air over the place slabs).

## Fix in Studio (main place, 17 Nov)
`YangonGreen1to1.unblob(x0, z0, x1, z1, keep)` repainted every non-grass ground voxel (Concrete, Pavement, Asphalt, Slate, Ground, Pebble, Salt, Cobblestone, LeafyGrass) to plain **Grass**, except:
- road beds: a part within 12 studs over the column's top (the road meshes / collision);
- columns with Water or Mud (lake and river edges, Inya's mud bed);
- P3's quay edge and piers (`terrain.py` code 5; mask `build/city_1to1/terrain_P3/keep_quay.txt`, 120 tiles).

| District | Tiles | Columns to grass | Kept under roads |
|---|---|---|---|
| P1 | 1,122 | 202,070 | 121,809 |
| P2 | 1,640 | 138,448 | 99,100 |
| P3 | 3,105 | 614,192 | 400,271 |

Real paved areas stay as `places_1to1.py`'s straight-edged part slabs (fuel forecourts, car parks, courts) in P1 and P2. **P3 has no places layer yet** (`places_1to1.py P3` never ran), so its car parks / fuel forecourts are plain grass until that runs.

## Tool fixed for P4+
- `green_1to1.py`: the clean style paints no terrain concrete at all (only Grass on land). Re-run `green_1to1.py <tag>` before `paint` in the copy Studio, or run `G.unblob` on an already painted district.
- `YangonGreen1to1.luau`: new `G.unblob` (resumable, `Green_unblob` attribute). For a riverfront district pass its quay / pier mask (code 5 of `terrain_<tag>_state.npz`, format in the function's header).

## Screenshots (Edit, `C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`)
Saved as place version after 17:45 UTC ("Saved new changes" in Studio's log).
- P1 roundabout (28032, 32384): ![[Concrete blobs - P1 roundabout before.jpg]] ![[Concrete blobs - P1 roundabout after.jpg]]
- P2 lakeside (37760, 21632): ![[Concrete blobs - P2 lakeside before.jpg]] ![[Concrete blobs - P2 lakeside after.jpg]]
- P3 riverside (42880, 47488): ![[Concrete blobs - P3 riverside before.jpg]] ![[Concrete blobs - P3 riverside after.jpg]]

## Lesson
Never paint terrain to show a paved surface: smooth terrain turns any painted patch into a blob. Paved ground is a part or mesh slab with straight edges at the right height.
