# 2026-11-27 Palms - real palms

Owner, 27 Nov: the palms looked like flat dark star-shaped cards (the tall palms in front of Myanmar Plaza near the spawn, and the street palms). They are now real-looking coconut palms and toddy (fan) palms, made the same way as the new rain tree ([[2026-11-27 Trees - new broadleaf tree]]).

## Where the palms came from (census)
| Source | What it was | Count |
|---|---|---|
| Streamed street / park palms `op1` / `op2` (`ReplicatedStorage.YgnKit.Templates` `OKA/OKB/OKC_op1/op2`) | Monaco kit palm: trunk mesh 10562881447 + two flat star crown cards 10562874217 (3 parts per palm) | 48,458 op1 + 39,136 op2 records in `Data_P*G` (40 within 600 studs of the spawn) |
| Placed `FANPALM` models | the same palm, smaller | 131 in `Green.Edges.Props`, 13 in `Parks.OptimaNeighbours`, 2 in `Parks.ThanlwinRoad` |
| Kit copies | the same palm | `GreenEdgeKit.FANPALM`, `MonacoKit.Dressing.Palm` (Hotel / Rewards Palace copy it), `DealerBody(Compact).Remodel.Palm` x2 each |
| 3D landmarks **Myanmar Plaza** (`Landmarks.MyanmarCentre`) and **Sedona** | palms and broad trees baked into one `KTW` (trunks) + one `KTL` (flat dark green fronds / 12-sided crowns) mesh each. **These were the dark star palms in front of Myanmar Plaza.** | Myanmar Plaza 10 palms + 2 trees, Sedona 6 palms + 10 trees |
| `RoadsideKit.ToddyPalm` (median palms, built on the client) | a plain Part trunk + crown mesh 109780764737295 | 1 template |
| Not changed | `YangonData.GreenKit` Palm / PalmA (source of `YangonGreen1to1.oldTemplates`), `RivieraAssets` (Monaco originals), `VenueKit.PottedPalm`, `Camera._YgnEditPreview` (an edit preview) | |
There are no far palms in the place: the far layer has only rain trees (`TFP_fp1` never existed), so no far palm was made.

## What was built
- **Atlas** `tools/trees/palm_atlas.py` (PIL, 1024 px, cut-out alpha, colour bled into clear pixels): 3 coconut frond sprites (green, deep green, dry yellow), 2 toddy fan leaves (green, dry), ringed coconut bark, dark toddy bark, husk, crown fibre.
- **Meshes** `tools/trees/palm_tree.py` (headless Blender 3.6), one MeshPart each, origin = trunk foot:
  - **CocoPalm** (~12 m, for op1 and the FANPALMs): curved ringed trunk with a root flare, 18 fronds that rise then droop, each frond V-folded leaflet cards whose width follows the leaflets, 2 dry hanging fronds, 9 coconuts. **1,190 triangles.**
  - **CocoPalmT** (~16 m, straighter, for op2): **1,190 triangles.**
  - **ToddyPalm** (~19.5 m): straight dark trunk, a ball of 40 folded fan leaves (dry ones low). **300 triangles.**
  - Crown-shaped normals (lit as one head), `DoubleSided` on, SurfaceAppearance AlphaMode Transparency + the rain tree's white roughness map.
- **Swap script** `tools/yangon/Palms.luau`: `templates()`, `placed()`, `toddy()`, `landmarks()`, `undo()`. Backup in `ServerStorage.PalmBackup_20261127` (`Templates`, `Placed`, `Landmarks`).

## What changed in the place (saved, Team Create **v2276**)
- Templates: `OKA_op1` = CocoPalm, `OKA_op2` = CocoPalmT (one part per palm instead of 3); `OKB/OKC_op1/op2` removed. Scale 1 = the old palm's height (op1 36.7 studs, op2 48.9), so every record keeps its height.
- **152 placed palm models** swapped (146 in workspace + the kit copies), same foot, yaw and height.
- `RoadsideKit.ToddyPalm`: one ToddyPalm mesh, 58.5 studs, foot at the pivot like before.
- Landmarks: `KTW` + `KTL` of Myanmar Plaza and Sedona moved to the backup. Their trunks were found in the KTW mesh (EditableMesh, clustered): each palm is now a CocoPalm(T) with its trunk top where the old one was; each broad tree is the rain tree, in a new `Trees` folder in the landmark. Counts match the layout file (Myanmar Plaza 10 palms + 2 trees).

## Asset ids (group 33151111)
| What | Id |
|---|---|
| Model "CL Palms v1" (CocoPalm, CocoPalmT, ToddyPalm) | 111240851902621 |
| meshes CocoPalm / CocoPalmT / ToddyPalm | 98663367910318 / 72042975005593 / 105310359287642 |
| palm atlas (image, approved) | 86989180507805 (decal 71719478200849) |
| roughness (the rain tree's) | 129339459957618 |

## Numbers (Studio Play on PC, same spot and camera at the Myanmar Plaza spawn, two 6 s runs)
| | before | after |
|---|---|---|
| FPS | 58.0 | 58.3 / 59.2 |
| worst frame | 35 ms | 36 / 32 ms |
| streamed palm parts near the spawn | ~596 crown cards + trunks (3 per palm) | ~172 (1 per palm) |
| triangles per palm | ? (Monaco mesh) | 1,190 (toddy 300) |

## Pictures
![[2026-11-27 Palms - Myanmar Plaza front (Edit) - before.jpg]]
![[2026-11-27 Palms - Myanmar Plaza front (Edit) - after.jpg]]
![[2026-11-27 Palms - Myanmar Plaza spawn (Play) - before.jpg]]
![[2026-11-27 Palms - Myanmar Plaza spawn (Play) - after.jpg]]
(the dark umbrellas on the right were Sedona's baked broad trees; now rain trees)
![[2026-11-27 Palms - Myanmar Plaza palms (Play) - after.jpg]]
![[2026-11-27 Palms - lake edge palms (Edit) - after.jpg]]
![[2026-11-27 Palms - toddy palms (Play) - after.jpg]]
![[2026-11-27 Palms - Blender renders (row, from the street, crown).jpg]]
![[2026-11-27 Palms - palm atlas.jpg]]

## Lessons / traps
- The "palms in front of Myanmar Plaza" were not the street kit: the 3D landmarks bake their palms into `KTW` / `KTL`. Look for those groups in every landmark when trees or palms change.
- In a baked trunk mesh each limb tube has vertices only at its ends, so a limb's far end shows up as a tiny separate cluster. A palm trunk leans (cluster 1.3-2.3 wide); a broad tree trunk is upright and exactly 2.2 wide.
- The FBX came in with `DoubleSided` off this time: set it in the script.

## Not checked / risks
- **Not tested on a real phone.** Transparent fronds cost more fill rate than the opaque star cards; watch the phone FPS where palms are dense (lake edges, parks).
- Re-running `YangonGreen1to1.oldTemplates` brings the old op1/op2 back (run `Palms.templates()` after). Re-building a landmark with `LandmarkPlace3D` brings back its KTW/KTL (delete them and run `Palms.landmarks()`).
- `RewardsPalace.palm` / Hotel `realPalm` place the palm by its bounding box; the new palm leans, so its foot can sit 1-3 studs off the old spot (not looked at).
- Shadows of the frond cards and the palms at night were not checked closely. Only one FPS spot.
- `tools/trees/rain_tree.py` now only runs `main()` when started directly (so palm_tree.py can import its helpers); its output is unchanged.
