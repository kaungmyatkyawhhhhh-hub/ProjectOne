---
tags: [city-legends, people, look, performance]
created: 2026-11-27
---
# Pedestrians: realistic people, no more rows (27 Nov 2026)

**Owner (comparing with TorqX Racing):** the street people look like blocky Roblox figures standing in rows along the kerb. Make them look like real people and stop the rows. Related: [[2026-11-27 TorqX match - road surface, worn paint, render distance]].

## What made the rows
- Not the old `client/Pedestrians.lua`: in Yangon it finds no blocks near the camera (its folder stays empty).
- `client/YangonStreetLife.lua` walkers: the 1:1 paths (`streetlife_1to1.py`) run along the middle of each pavement, and every walker kept the same line (`lat` -0.4..0.5 on narrow paths). Walkers bunched up (spawns 1-5 studs apart) and stood at path ends. From the road they read as a queue facing the kerb.
- The only standing spots in the 1:1 map are the 32 Myanmar Plaza shop-window spots (4 floors, stacked rings): up to 12 standers all ended up there.

## Fix (rows)
- Walkers spread over the pavement width (narrow paths -1.5..1.5 studs, main-road paths -0.6..3) and drift ±0.5 at every path point.
- No spawn within 8 studs of anyone.
- 30% walk in twos side by side (friends, couple, parent + child), same pace.
- Now and then a walker stops 2-7 s and turns to look at a shop, the phone or the street.
- Standers: off the exact mark (±0.8 studs) and facing (±0.6 rad).

## Fix (bodies)
- New pieces modelled in headless Blender 3.6: `tools/people/people_mesh.py` (+ `people_render.py` check renders). Same 8-part split, so `pose()` / BulkMoveTo and PedHits keep working:
  1 shirt / blouse / robe (short sleeves on it), 2 head + neck + ears, 3 hair (short or bun, swapped per person), 4 longyi / htamein (tapered, closed hem), 5 / 6 arms with hands, 7 / 8 feet.
- Size: 1.6-1.8 m (head top 5.2 studs at scale 1; women 0.91-0.98, men 0.95-1.03, kids 0.66-0.78). About **1,680 triangles a person**.
- Colours still come from `dress()` through Part.Color (meshes untextured). Arms are skin; the monk's left arm is robe.
- Faces and sandal straps are **Decals** (the face on the head's Front, a strap V on each foot's Top). Two faces: plain, and with thanaka on the cheeks (60% of women and girls).
- `GEO.real` / `GEO.blocks` hold each body's part centres, sizes and joints. `PedHits` builds its neck / shoulder / hip sockets from them. If the meshes ever fail to load, the old blocks come back.
- Flicker rule: `people_mesh.py` ends with a check for near-parallel faces closer than 0.05 studs between any two pieces in the rest pose. Result: **0**. Hair sits 0.05+ off the skull, the collar clears the neck, the shirt hem clears the longyi, the hands clear the hips and the feet are apart.

## Asset ids (group 33151111)
- Model `94912674677470` (pieces v3).
- Mesh ids: Torso 95116517230231, Head 122525154005592, HairShort 125077740186727, HairBun 74908404628379, Longyi 117548162675945, ArmL 90339926999789, ArmR 140321970177029, Foot 101755076151555.
- Decal images: face 127110709777252, face + thanaka 139673625040739, sandal strap 127958667677139.
- Older uploads, not used: models 98570423613610 / 121560015889845; atlases 112395260665721 / 126526005579587.

## Traps found
- **The FBX import turns each mesh 180° about Y.** The hair's nape edge came in at the front, so the back of the head looked bald. `people_mesh.py` now turns the export first (x and z negated). Blender renders compensate.
- **A MeshPart's TextureID ignores alpha.** With a face atlas whose background was see-through, the heads came out black. Use Decals on the MeshPart instead: their clear pixels show the part's Color.
- Decal-type uploads give the real image id in the child operation. In Studio, `ContentProvider:PreloadAsync` reported `Failure` for these images (and for an older one that had loaded) even while the Decals drew fine. So it is no gate: the Decals are set at once. A picture that has not loaded draws nothing, and the plain skin shows.
- The longyi in Fabric material glittered (knit noise): all pieces are SmoothPlastic.
- `execute_luau` `require` of a client module gives a separate copy, so `YangonStreetLife.stats()` read 0 from there. Count `workspace.YangonStreetLife.People` instead.

## Cost (Studio Play, Myanmar Plaza spawn, same car spot and camera, GUI hidden)
| | FPS | people | parts |
|---|---|---|---|
| before (blocks) | 57.0 | 39 | 312 |
| after (meshes) | 57.5 / 56.1 (two runs) | 38-40 | 304-320 (+3 decals each) |

No measurable change on this PC. `PedMax` stays 40. Not measured on a phone.

## Checks
- PedHits in Play: a 60 km/h hit made a ragdoll with the new joints, and the person stood up again (no errors).
- Pictures:
  - Before: ![[2026-11-27 Pedestrians - before (plaza).jpg]] ![[2026-11-27 Pedestrians - before (row at the kerb).jpg]]
  - After: ![[2026-11-27 Pedestrians - after (plaza).jpg]] ![[2026-11-27 Pedestrians - after (pair at the dispatch).jpg]] ![[2026-11-27 Pedestrians - after (Myanmar Plaza pavement, final).jpg]]
  - Faces up close (Edit): ![[2026-11-27 Pedestrians - faces close-up (Edit).jpg]]
  - Old block figure next to the new people (Edit): ![[2026-11-27 Pedestrians - new people next to the old block figure (Edit).jpg]]
  - Blender line-up and faces: ![[2026-11-27 Pedestrians - Blender line-up.png]] ![[2026-11-27 Pedestrians - Blender faces.png]]

## Studio
- Synced by writing `Source` (YangonStreetLife 34,785 chars, PedHits 16,116, same as the repo). The PlayerData store is back on `CityLegends_v1`. The test line-up was deleted. Saved to Roblox at 22:45 UTC (not published).

## Not done / next
- Standing spots on the 1:1 streets (bus stops, tea shops) don't exist yet (`streetlife_1to1.py` shortcut). People only stand in the mall, or stop for a moment while walking.
- Short sleeves: a swinging arm pokes a little through the back of the sleeve.
- The sandal strap decal mostly sits under the longyi hem: only the toe post shows when standing.
- Hair is a thick cap (kept 0.05 studs off the skull for the no-flicker rule): from very close it reads a bit like a helmet.
