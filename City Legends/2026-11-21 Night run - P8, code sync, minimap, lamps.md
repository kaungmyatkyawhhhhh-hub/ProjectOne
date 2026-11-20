# 21 Nov night run (laptop) - due 6 AM

Owner rule repeated tonight: **always update the vault** as work lands.

## Done
- Studio upload folders approved on the laptop (imports + build). Road file (.glb) uploads work.
- **Code fixes are in Studio** (14 scripts, checksum-identical to the repo): Cars (GC8 put away), Config (minimap ZoomNear 0.24), TrafficMix + TrafficBodies (no old-model traffic), Chauffeur (stand-in cars), new Frame module + Driving / UI / Weather / HousingClient / TrailerClient / CarDoors / LowEnd (locked-PC fix), Minimap (tile retry).
  - Put in by exact find-and-replace, because script-pack (.rbxmx) uploads sat "not done" for 10+ minutes on Roblox's side.
- Not synced on purpose: BrandMarks, CarSkin, DashGauges, LamboClusterArt, CarFinish, CarLamps, Windscreens. The repo copies are newer (15 Nov car work) than this laptop's place; left alone until checked.

## Running (agents)
1. P8 road swap: upload 40 road files, swap, scans, kit props, grass edges, deck feet, lanes. No Play test by the agent.
2. Minimap: building shapes exported from Studio, P8 added, tiles uploaded, YangonMapArt regenerated.
3. Lamp audit (read-only): every on-sale car's headlights and taillights vs the real car -> `Games/CityLegends/build/lamp_audit_21nov.md`.

## Left
- P8 Play drive test (roads + 7 decks), save.
- Apply the lamp fixes (owner, 21 Nov: "make the player cars' headlights and taillights not have bugs and look identical to real life versions").
- Not saved since v1650. Not published.

## Minimap done (in Studio, not play-tested)
- Building shapes: 70,512 boxes exported from Studio (`Buildings.Shell`) into `build/city_1to1/buildings_<tag>/Shell_studio.txt` (P1 7261, P2 8246, P3 13016, P4 14097, P6 10812, P7 4757, P8 12313).
- `minimap_1to1.py` FULL now has P8. 53 detail tiles (5 x 13 grid) + 13 overview tiles, 66 uploaded as Image assets; one (`d_0_0`, 78495515679494) was still in review.
- `YangonMapArt.lua` regenerated and installed in Studio (4914 chars, equal checksums). Minimap.lua reads cols / rows from the art, so the wider grid needs no code change.

## Lamp audit done (read-only) - 53 trims, 52 models
Full list: `Games/CityLegends/build/lamp_audit_21nov.md` (build/ is not in git: laptop only).
- **Code bugs (being fixed in the repo now):** other players never see brake / reverse lamps; lamps stay lit after getting out and brake-red can stick; double tail glow on 22 cars (cut tail shell + whole red lens both lit); stale tail entries (GLS, S680, California, LP750, Focus RS, Countach, LP700, LFA); daytime running lights on cars that never had them (AE86, Chaser, Supra, both CP9A, Countach, LP640, LP670); one white headlamp colour for every car (now warm halogen / cool xenon / LED per car).
- **Data work left (shell cuts with tools/lamps, in Studio):** 8 cars have no lamp shells at all (astin_dbx, bentlee_contgt, bentz_sl65bs, bentz_sls, bnw_330i_g20, ferrara_599, mclaran_12c, nisun_350z; the DBX also has no tail lamp); 12 cars light the whole rear lens; re-cuts for CP9A Champion, Supra, Bentayga reverse, 458 Spider, Chaser; GLS bumper strip lights as a tail lamp.
- **Not possible without new meshes:** LED signatures fused into one piece (Audi / BMW light guides, angel eyes, Lamborghini Y tails, Porsche four-point), separate brake element, AE86 pop-ups, sequential indicators.
- Stray `Workspace._WheelStage.lexis_lfa` (20 visible Neon shells) is in the place: remove before publishing.

## Lamp code fixes in the repo (not in Studio yet, not play-tested)
- Brake / reverse lamps now sent for every car, and shown on other players' cars (Driving.lua, CarLamps.lua).
- Getting out switches lamps and brake off (Driving detach); state resets when the driver changes.
- No double tail glow when a car has cut tail shells (CarSkin.lua).
- 8 stale tail entries removed (TailLights.lua, tools/tail_lights/tails.json).
- `NO_DRL` and `TINT` tables in CarLamps.lua: no daytime lights on cars that never had them; real headlamp colour per car. A bought Customs lamp colour beats the tint.
- New test `tools/lamps_test.luau` passes.

## Owner's real-life references (21 Nov)
Folder `C:\Users\kaung\Downloads\IrlReferences\` (1.6 GB, laptop only, NOT in the vault): 29 videos + photos, Yangon at night, mostly filmed from a moving car: GG Gaming Fest hall, towers, a lit roundabout monument, City Hall lit up, the cable-stayed bridge, street lamps, cars' head and tail lights on the road. Owner, 21 Nov: these are the reference for the real-life Yangon CITY (not for car lamps). An agent is listing each place and what the game must change to match.

## Lamp code fixes now in Studio
CarLamps, Driving, TailLights are checksum-identical to the repo; CarSkin got only the tail-glow change (its Studio copy differs from every repo version, so the rest was left as is). Not play-tested yet.

## P8 road swap done in Studio (not saved yet)
- 40 road files + collide + tools uploaded; old 10 cells + 4,511 boxes out, 42 cells / 384 meshes / 20,708 boxes in.
- Terrain 82 road boxes cleared; 8 trees off the road; 44 kit props removed (`KitTiles_P8`); grass edges 16 tiles; lanes L1234678 installed (1,141 lanes, 0 dead ends, 21 modules); deck feet 11 ok, 1 BAD.
- **Known fault:** U Chit Maung x Banyar Dala junction: the 60.6 deck dips to 29.9 at (39940, 32800), about 46 studs long. Needs a builder fix and re-bake of cell 26x21.
- Deck test starts and 8 road spots are in `rebuild_progress.json` P8.

## Place too large to save (found and being fixed)
- Every save after the swap failed: "could not upload place. File too large" (auto-recovery file 160 MB; 152 MB on 19 Nov still saved).
- Measured the file: **100 MB of 160 MB is collision data stored on MeshParts** (`PhysicalConfigData`, 12,289 blobs). Terrain is 29 MB, everything else small.
- Cause: 2,107 road picture meshes have CollisionFidelity Default although they never collide (the `RCol` boxes do that). Fix: `AssetService:CreateMeshPartAsync(mesh, {CollisionFidelity = Box})` + `MeshPart:ApplyMesh` on each (size / position / DoubleSided checked equal). Setting the property directly does nothing.
- **Rule for the pipeline from now on:** road meshes (and any non-colliding mesh) must be inserted with CollisionFidelity Box.
- Also removed old backups that every saved version still holds: `RB_OldR25`, `RB_OldR25B`, `RB_OldP8.Meshes` + `.Collide` (Temps and TreesOnRoad kept).
