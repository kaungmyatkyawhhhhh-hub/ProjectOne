# Overlaps round 3: backup manifest (deleted from the place, 26 Nov 2026)

The place stopped saving ("could not upload place. File too large") after the P1-P3 building swap. The swap's backups
were the biggest new thing in it. They were deleted from `ServerStorage.OverlapFixBackup` after this record was written.

## What was deleted, and how to get it back
| Backup folder | Parts | What it held |
|---|---|---|
| RebuildOld_P1 | 10,533 | old P1 shells and roofs (10,339), 30 old night cells, old `Data_P1`, 164 new shells left out in KeepOut boxes |
| RebuildOld_P2 | 13,081 | old P2 shells and roofs (12,954), 46 night cells, old `Data_P2`, 81 new shells in KeepOut |
| RebuildOld_P3 | 14,721 | old P3 shells and roofs (14,673), 44 night cells, old `Data_P3`, 4 new shells in KeepOut |
| OldShellsP123 | 0 (2.7 MB strings) | the old S / R shell records used for the matching (also asset 92302468599227) |

- **Old buildings:** they can be built again from the builder. Tool: `tools/yangon/city/buildings_1to1.py`, last changed in
  commit ff9a22de. The old footprints are `build/city_1to1/buildings_P1/plots.json` as of commit 8783fc89 (the
  version before 520edd77), and the same for P3. P2's plots did not change. The old run's full outputs (Shell / Inst
  pages, kit glbs, night cells, `ygnkit_p*.rbxmx`) are on the home PC in `build/city_1to1/_pre_rebuild_P1P2P3_26nov/`.
  The old shell records are Roblox asset 92302468599227. The rebuild steps are in `tools/yangon/RebuildSwap.luau` and
  `tools/yangon/DistrictPlace.luau`.
- **Old night cells (120 MeshParts):** each one's name, CFrame, size and MeshId is in
  `2026-11-26 Overlaps round 3 - backup parts (night originals, road-trim originals).json` (kind `night_old`). To put
  one back, make a MeshPart from that MeshId at that CFrame and size.
- **New shells in KeepOut:** not needed. They come out of the new packs again (`rebuild_ids_26nov.txt`), and
  `RebuildSwap.placeNew` drops them the same way.

## Kept in the place (small hand items)
- `RoadTrim26` (184 originals of the shells cut back from the roads; also in the JSON, kind `roadtrim_original`).
- `Shells` (67: the Shwedagon-edge and station buildings deleted in rounds 1-2), `ParkTrees` (28), `PrepareTaken` (32),
  `Night` (10), `Parts2` (1), and the `Data_*` tile string copies from rounds 1-2.

## Save fix (26 Nov, v2178)
- The place hit "File too large" after the P1-P3 swap and the road agent's RB10 / RB6 / RB11 swaps.
- Deleted from the place:
  - The four backups above: 38,335 parts and about 9.3 MB of strings.
  - `ServerStorage.DealerBody_before_RiderLook` (1,882 parts), `DealerBody_before_remodel` (880) and `StraightLinkOld`
    (782). No script names them; the live `DealerBody` and the built Straight Link replaced them.
  - In all, about 41,900 parts and 9.3 MB of strings.
- Kept:
  - `OldModelCars`: `TrafficLOD` reads it to make traffic bodies, and the Pending cars' models are there.
  - `OldCarModels`: CarSwap / RimSwap / LogoFix undo copies of the owner's imported cars, and the E92's own wheel.
  - `ToolboxHouses` and `DalaBridge_WIP_21Nov`: no script uses them, but they are the owner's Toolbox houses and
    another job's work in progress. That is the owner's call.
- `workspace.Camera._YgnEditPreview` (about 8,600 parts) is NOT in the saved file. The Yangon Edit preview plugin
  (`tools/yangon/YangonEditPreview.plugin.lua`) makes it Archivable = false, so a save skips it. Nothing to change.
- Saved v2178 with the road agent's swaps in it: 415 road cells, 3,791 meshes, 0 duplicates.
