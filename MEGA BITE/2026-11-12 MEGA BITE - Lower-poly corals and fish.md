# MEGA BITE - lower-poly corals and food fish (12 Nov 2026, 22:40)
Owner: "ok do it" (after [[2026-11-12 MEGA BITE - Map culling for phones]] said the repeated decor meshes were the remaining cost).

## Corals (world kit B)
Triangle cost per mesh across the map (faces x copies), measured with EditableMesh:
| Mesh | Before | Copies | After |
|---|---|---|---|
| SeaFan | 6,000 | 651 | 1,300 |
| BrainCoral | 5,120 | 380 | 2,000 (at 1,000 the groove pattern went; 2,000 keeps it) |
| BranchCoral | 2,576 | 444 | 1,000 |
Others were already light (BubbleCoral 560, Kelp 190, Starfish 472, TableCoral 608).
- Made from `Art\Kit\export\MB_Kit_B.fbx` with Blender's Decimate (collapse, UV seams kept so the palette colours stay), exported with the kit's own axes. Script + before/after pictures: `Art\Kit\lod\` (lod.py, lodcmp.jpg, brain_2000.jpg).
- Model assets: SeaFan 77588199804472 (mesh 74504780753169), BrainCoral 139138531155787 (mesh 130387025030937), BranchCoral 90477868966879 (mesh 92541551291773). All Approved.
- Swapped in place with `MeshPart:ApplyMesh` on every copy (workspace + ReplicatedStorage): size, colour and texture kept. Old mesh ids to go back: SeaFan 95515351938369, BrainCoral 76852038507124, BranchCoral 138199843871351.

## Food fish
- The "lite" fish were 1,500-2,800 body triangles (3,000-5,600 with the outline hull). `fishbuild.py` got a `decimate_to` option: the body is collapsed to about 1,000 triangles BEFORE the outline hull is built, UV seams kept. Result: about 2,000 triangles per fish with the outline, side-by-side with lite looks the same (`Art\Fish_hse\lod\sardine_lite_vs_lod.jpg`, `fish_lod_all.jpg`).
- Model assets (all Approved): Damsel 123266935708656, GoldenFish 93301243347632, Mackerel 116040790278286, Puffer 74767660041909, Sardine 116878521724209, Shrimp 109605132800903, Squid 126939878193832, Tuna 136630070754391. Installed with `MB_InstallFish(key, id, current texture)`; sizes match lite. Backup: ServerStorage.MB_Fish_lite_backup_12Nov.
- Note: ContentProvider:PreloadAsync reports Failure for some fish textures (Tuna, Mackerel, Squid, Golden) with "No asset content representation found while do_not_fallback_to_baseline", but they render fine in Studio. Not a real fault; a re-upload of the Tuna texture (109835251493044) showed the same, so it was not used.

## Result (spawn reef, Megalodon camera, Studio Play)
| | Triangles with culling | Without culling |
|---|---|---|
| Before today | ~1.0-1.2 M | 2.2 M |
| After corals | 0.50 M | 1.12 M |
| After corals + fish | 0.51 M | 0.90 M |
Target was about 1 M: now about half that with culling on.
