# 2026-11-27 Trees - new broadleaf tree

Owner, 27 Nov: "Trees next", after comparing our game with TorqX Racing (realistic leafy trees). The broadleaf tree (`ot1`, the old map's Toolbox acacia: a few big flat polygons in one colour) is replaced by our own **rain tree** (Yangon's *Samanea saman* umbrella tree). Palms are unchanged.

## What was built
- **Leaf atlas** (`tools/trees/leaf_atlas.py`, pure Python + PIL): 1024 px. Six cut-out leaf-cluster sprites (2 shapes x light / mid / dark), drawn as fine compound leaves (rain tree and flame tree both have fern-like leaves), with colour bled into the clear pixels so there are no light halos. Bark strip at the bottom. Also a **flame atlas** (the same leaves with red-orange blossoms) and a small far texture.
- **Tree mesh** (`tools/trees/rain_tree.py`, headless Blender 3.6): a trunk with a root flare, 5 limbs with 2 side branches each, and 16 crown lobes covered with about 830 leaf cards. Top cards use the light sprite and underside cards the dark one. The card normals follow the crown's dome, so the crown is lit as one shape and not card by card. Top cards are never flatter than about 35 degrees, because flat cards showed as hard streaks from the street. **One MeshPart: 1,670 triangles** (leaves and bark share one atlas, so it is one part where the old tree had two). Roblox imports it with `DoubleSided` on, so the cards have no back faces.
- **Far look:** one opaque part of **220 triangles** (a lumpy umbrella dome wrapped round the crown lobes, plus the trunk and limbs). It replaces the far acacias in `Workspace.Yangon1to1.Green.Far`.
- **Scale:** record scale 1 still means an 18.3 m crown (`green_1to1.py OLD_KIT`). The mesh is 17.3 m, so the template is grown by F = 1.06. At scale 1 the tree is about 13.3 m tall. The old acacia was 9.6 m tall.

## What changed in the place (saved, Team Create **v2261**)
- `ReplicatedStorage.YgnKit.Templates`: `OKA_ot1` is now the rain tree. It has a SurfaceAppearance with AlphaMode Transparency and a plain white roughness map, because without one the leaves had a cyan sky sheen. `OKB_ot1` (the old trunk) is removed. `OKF_ot1far` is the far template; its pid `ot1far` is in no Meta PIDS, so the streamer never builds it.
- **187 placed "Acacia" models became `RainTree` (172) and `FlameTree` (15, the ones that had red LeafyGrass crowns).** Each keeps the same foot, yaw and scale, worked out exactly from the old trunk (largest error 0.006 studs). The `BANKTREE` Collider parts are untouched. The same swap was made in the kit template `ServerStorage.GreenEdgeKit.BANKTREE`.
- **Far layer:** 26,986 far trees in 557 cells. Each was a crown and a trunk part (53,977 parts); each is now one part, so there are 26,991 fewer instances.
- **Backup:** everything old is in `ServerStorage.TreeBackup_20261127` (`Templates`, `Placed` with 188 models, `Far`). `tools/yangon/RainTree.luau` `R.undo()` puts it all back (each new model has an `Old` ObjectValue).
- `YangonGreen1to1.farOld` now uses `OKF_ot1far` when it exists, so re-running the far tool keeps the new tree (changed in the repo and in Studio's ClaudeTools).

## Asset ids (group 33151111)
| What | Id |
|---|---|
| Model "CL RainTree v3" (RainTree + RainTreeFar) | 125285857865594 |
| near mesh / far mesh | 131205659894330 / 112295840434693 |
| rain leaf atlas (image) | 127614795774772 |
| flame atlas v2 (image) | 86540793969262 (v1 127408360340598, not used) |
| far texture (image) | 102023366540990 |
| white roughness (image) | 129339459957618 |
| older uploads, not used | models 70576316997603 (v1), 85476332907982 (v2) |

## Numbers (Studio Play on PC, RenderDist 0.75 = the phone default, same spot and camera at Myanmar Plaza spawn)
| | before | after |
|---|---|---|
| FPS | 55.4 | 52.7 / 54.8 (two 6 s runs) |
| worst frame | 39 ms | 35 ms |
| near ot1 trees built | 195 | 162-201 |
| far trees shown | 1,583 | 1,629-1,807 |
| parts per near tree | 2 | 1 |
| far parts in the place | 53,977 | 26,986 |
| triangles per near tree | ? (Toolbox mesh, no access to count) | 1,670 |

The FPS is the same within noise. Roughly 200 near trees x 1,670 = about 0.33 M triangles of trees, before Roblox's own mesh LOD.

## Pictures
![[2026-11-27 Trees - Myanmar Centre lake row (Edit) - before.jpg]]
![[2026-11-27 Trees - Myanmar Centre lake row (Edit) - after.jpg]]
(This after shot still has the first flame atlas. The blossoms were made denser after it: flame atlas v2.)
![[2026-11-27 Trees - Myanmar Plaza spawn (Play) - before.jpg]]
![[2026-11-27 Trees - Myanmar Plaza spawn (Play) - after.jpg]]
![[2026-11-27 Trees - street trees into the sun (Play) - after.jpg]]
![[2026-11-27 Trees - street trees and flame trees (Play) - after.jpg]]
![[2026-11-27 Trees - Blender renders (front, 3-4, from below, near vs far).jpg]]
![[2026-11-27 Trees - leaf atlas (rain).jpg]] ![[2026-11-27 Trees - leaf atlas (flame).jpg]]

## Lessons / traps
- A SurfaceAppearance with no RoughnessMap makes the leaves shiny: they reflect the sky as a cyan haze. Give foliage a white roughness map.
- Roblox imports a card mesh with `MeshPart.DoubleSided` on, so back-face copies only double the triangles.
- Cards lying flat on top of the crown read as long dark streaks from street level. Keep top cards steep and underside cards flat.
- `rain_tree.json` is rewritten on every Blender run, so check it against the uploaded mesh (EditableMesh vertex span / MeshSize = 33.33 x the json studs).
- Open Cloud decal uploads give the image id in the child operation, but sometimes that operation has no response. Then `InsertService:LoadAsset(decalId)` and read `Decal.Texture`.

## Not checked / risks
- **Not tested on a real phone.** The FPS above is Studio on the PC. Transparent foliage costs more fill rate on cheap phones than the opaque acacia did; watch the phone FPS in a park.
- Some edge-on cards still show as thin streaks when you stand right under a tree. Shadows from the leaf cards were not checked closely.
- Only one FPS spot has a before / after pair. A park spot was looked at only after the change.
- The flame atlas v2 was only seen in the Play spawn shot, not close up.
- The old-map kit `ServerStorage.YangonData.GreenKit.Tree` (Monaco acacia) is unchanged. `G.oldTemplates()` would bring back the old `OKA/OKB_ot1` if someone re-runs it. Run `RainTree.templates()` after it.
- Studio's `ClaudeTools.YangonGreen1to1` was already different from the repo before today (29.8k vs 32.8k characters). Only today's two edits were made there.
