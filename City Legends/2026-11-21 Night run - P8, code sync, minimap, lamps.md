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

## Saved v1656 (not published)
- Road mesh collision data stripped on 1,995 of 2,107 meshes (112 would not load tonight: "Failed to load mesh asset"; retry later). Size, position and DoubleSided unchanged on every one. The place saved straight after.
- v1656 holds: P8 roads + lanes, the 14 synced code files, lamp code fixes, new minimap art, and the builders' work in progress (IrlNight21Nov, City Hall, Dala Bridge).
- Still to do: P8 Play drive test, night lamp check, the 112 meshes, U Chit Maung deck dip, flyover feet + yellow lines rebuild.

## Flyover feet + yellow lines: generator fixed in the repo (not rebuilt yet)
- **Why the feet looked wrong** (owner's picture = Banyar Dala south foot): `roads05_fix.py` `deck_joints` narrowed the ground road at every deck foot to the deck width, undoing the gore widening, so the side lanes ended on grass and the main road's kerb and pavement crossed them. The stray grey box was a small pavement piece; the pointed island was the kerbed median starting inside the gore.
- **Fixed in code:** decks with side lanes keep the gore width; no kerbed median within 150 studs of such a foot; 6 yellow barriers per edge at each nose (mesh + collision); centre line of undivided two-way roads and decks is double yellow (230, 222, 114). Test `roads05_deckfoot_test.py` passes.
- **U Chit Maung deck dip cause:** the bake sampled the ground junction's height (29.9) because that deck's own surface was not in the P8 export. Bake now ignores surfaces more than 8 studs off the data height.
- **To see it in the game:** fix -> paint must run on the HOME PC (the laptop has no `roads_unfixed.json`). Then rebuild + bake 11 cells for the 9 feet of the 5 decks with side lanes: 22x18, 22x19, 22x21, 22x23, 23x28, 24x28, 25x21, 25x22, 26x20, 26x21, 26x22. Yellow centre lines need a bake of all 252 cells.
- Only 5 of 52 decks have side lanes in the data. 12+ other decks have separately named ground roads beside them; those are unchanged and not yet looked at.

## 02:10 usage limit hit; Studio changed
- Three agents stopped mid-work at the usage limit: landmarks (City Hall, Sule, roundabout, fence), Dala Bridge, car lamp shells. Their Studio work up to then is in the open place only if it was still open; last save is v1656.
- After the reset, the only Studio open was "rongstrix's Place: 11202026_2" (placeId 115768373987676), not City Legends. Nothing was done in it (rule: never touch another game's Studio).

## After the owner published (about 03:00)
- Owner published the place himself; live = the state with the builders' half-finished work (City Hall, Sule, fence, roundabout).
- **"Stuck in black screen after skipping loading"**: not a crash. All scripts compile; a Studio Play test loads the menu with no script errors; the owner got into the game a few minutes later. Skipping while the big map is still loading leaves nothing ready behind the loading screen.
- **"Map loading is bugged, sometimes it doesn't fully load, lag spikes"** (screenshot: kerbs there, asphalt missing; client memory 1.8 GB):
  - Roblox's mesh servers were failing tonight (HTTP 502, "Failed to load mesh asset"): 112 road meshes would not load at 01:30, 108 of the same ones loaded fine at 03:10. A mesh that fails to download is simply not drawn.
  - Road cells are 1536-stud Atomic models with about 9 big meshes each, so a whole cell arrives at once = a spike. Client memory is high (1.8 GB) with 7 districts in.
  - Not fixed yet. Needs a measured pass (memory by type, streaming radius, cell size).
- **Expanded map closes while dragging**: fixed (owner: "make the expanded map only close when i the X button"). The click-outside-to-close on the backdrop is gone; only the X closes it. Repo + Studio.
- Road mesh collision strip: 2,103 of 2,107 done now. Leftover test stages `_LampStage`, `_WheelStage` deleted. Saved **v1662** (the map-close fix was made after this save).
- Test note: the Studio account tonight is "rongstrix", not the owner's; owner's save is `p_848360565` (L64, lexis_lfa).

## About 03:30-04:00
- **City Hall rebuilt** (`Landmarks.city_hall.Rebuild21Nov`, 973 parts; old mesh groups hidden; backup `ServerStorage.CityHall_before_21Nov`): cream walls, four corner towers + entrance tower on the roof, lilac tiers, gold spires, night lights. The floating tower was in the original mesh. Checked by screenshot: nothing floats. Tiers are plain (no carving); colours not measured.
- Also in `Landmarks.IrlNight21Nov`: Hanthawaddy roundabout monument (28250, 76, 32194), Maha Bandula fence neon (508 parts), Sule shops lights, Sule stupa lights. Script `tools/yangon/IrlNight21Nov.luau` (never run end to end).
- **Dala Bridge built** (`Landmarks.DalaBridge`, 2,384 parts, script `tools/yangon/DalaBridge.luau`): 3 studs per metre, OSM centreline, main bridge 690 m with a 370 m main span, total 1,868 m, 6% grade, clearance 48.8 m, deck 26.5 m with 2+2 lanes. From the videos only (no source): pylon 84 m above deck, 14 stays per fan, lamps every 35 m. Yangon end flush on Phone Gyi (31575, 40.2, 44231); Dala end (30734, 16.5, 50749) has no ground or road under about 800 m of it. The old flat generic deck of the road network still sits under it on the same line and must go; lanes need regenerating; not drive-tested.
- **Why roads vanish ("map doesn't fully load")**: PROVEN. Roads sit only 1-4 studs above the carved ground. Far away Roblox draws terrain more coarsely and it rises over the road. A copy of a Sule road mesh lifted 3-6 studs is fully visible from the same far camera. Not a download or mesh problem. Fix running: deepen the ground under every road (`tools/yangon/RoadBedDeepen.luau`), test cell first (x23 z29, backup `ServerStorage.TerrainBackup_21Nov`).
- **Rare traffic cars** (owner: "the rare cars ai is glitching and also i keep on spotting them"): RareChance 0.07 -> 0.01; caps ferrari 2, lambo 2, gtr 10, r34 3, bugatti 1 -> 1 each. The racer driving itself (19 Nov "swimming through traffic at 100-220 mph") is NOT changed yet.
- **Side buttons** (owner: "remove despawn and replace it with cars in the side buttons"): DESPAWN hidden, CARS shown.

## Rare cars pass instead of stopping (repo + Studio, identical; not watched in Play)
Owner: "dont make the rare car ai stop for players cars, make them cut up by merging into another lane if the lane is open".
- Behind a player's car a racer now only slows to the player's speed at the normal gap, and keeps rolling at 6 studs/s while it moves over to a free strip (`TrafficMix.racerBehindPlayer`; the old 1 s wider gap + full stop is gone). It still never moves into an occupied strip and never pushes a car.
- Glitch causes found: stop-go behind players (fixed); the nose snapping over 40 degrees at lane changes (now eases, max 19 degrees); crabbing sideways at standstill (limited). Not changed: a slide cancelled mid-lane and re-picked 0.2 s later (wobble); a racer 1500 studs away respawning 220-520 studs from the player (may be why they are "spotted" often).
- Test `tools/racer_pass_test.luau` 11/11.

## Fast buses and taxis (repo + Studio)
Owner: "also sometimes the ybs and taxis need to be fast". 30% of YBS buses and Probox taxis get a top speed of 62-80 mph (everyday traffic: 24-54). Only the top speed changes; gaps, lights and turns are as before. `TrafficMix.Hurry`. Not watched in Play.

## CORRECTION: the ground-deepening fix did NOT work
- The agent carved the ground 10 studs deep under the roads in 251 of 252 cells (4.2 million voxels, margin 4 studs, ramps and water skipped) before its controlled test showed no gain. Cell 23x29 was restored from `ServerStorage.TerrainBackup_21Nov`; the other 251 have no backup except place version 1662.
- What the controlled test showed: after the camera jumps, far terrain is drawn coarse for a while and covers the roads; held still for about 28 s it refines and the roads show 900 studs away, with the ORIGINAL ground too. A narrow deep cut under the road changes nothing, because the coarse far terrain does not keep a narrow trench.
- So my earlier "PROVEN" note was only half right: coarse far terrain does cover the roads (a mesh lifted 3-6 studs shows at once), but deepening the bed is not the cure.
- The carve is kept: one kerb spot looked identical before and after, and cars drive on the `RCol` boxes, not on terrain. Risk: where the collision boxes have a hole (known: Sule Pagoda Road), a car now drops 10 studs instead of 1-4.
- **Still open: roads hidden by coarse far terrain while it refines** (worse when driving fast or on a slow device). Ideas not yet tried: lower the ground in a WIDE band around roads so even the coarse version stays under them (needs the grass-edge meshes to hide the dip), or keep the nearest road cells' terrain refined. Test on ONE cell with equal waiting times before touching the rest.
- Lesson: an agent must finish the one-cell test, with equal wait times before each screenshot, before running a change on every cell.

## Car lamp shells: 4 of 8 done (paused for the Play test)
- Done with real cut shells (12 each: head core, head glass, front / rear indicator, reverse, tail): `bentlee_contgt`, `astin_dbx`, `bentz_sl65bs`, `bnw_330i_g20`. Added to CarLamps CARS / NO_DRL / TINT (repo = Studio, 19,448 chars). Backups in `ServerStorage.LampBackup_21Nov`.
- Not done: `bentz_sls` (shells uploaded, asset 118050194412654, not applied), `ferrara_599`, `mclaran_12c`, `nisun_350z`, the 12 tail-shell cars, 5 re-cuts.
- Method: `tools/lamps/lampfx_studio.py` + `tools/lamps/jobs_studio/<id>.json` -> .glb in `imports/sync/lamp_shells/` (x and z negated) -> upload as Model to the group -> LoadAsset. The Studio helper lives only in `_G.LS` and is lost on a Studio restart (not in the repo yet).
- Not real-life yet: no third brake lamp role, DBX intake ring is indicator only, 330i fog lamps unlit. Nothing seen at night in Play.

## Owner orders at about 03:00 (with the traffic code agent)
- "fix everything".
- Rare cars: "slow down on turn every 1 degree = 3% slower ... 10 degrees = 30% slower so 100 mph to 70 mph".
- "put more traffic, it dont feel like yangon rn cuz it needs more traffic": +60-70% on normal devices, low-end numbers unchanged.

## Owner, about 03:15
- "do everything in known but not started": far roads, lag spikes, Sule Pagoda Road hole, P8 deck dip, remaining car lamps, Dala Bridge route, more real-Yangon look, the 4 road meshes. Studio work starts when the Play test ends.
- **"dont make the land beyond dala"**: no ground, town or road is built on the Dala side. The bridge is made drivable only as far as its own structure; it ends at its Dala end.

## Traffic + loading code ready (repo, commit 5a34bbd1; NOT in Studio yet: waits for the Play test to end)
- **Skip can't leave a black screen:** during startup SKIP / the time limit keep the loading screen with "Still loading the city..."; the menu opens first, then loading hides; watchdog now runs from the start (new `src/shared/StartupGuard.lua`). Likeliest long wait found: `GetData:InvokeServer` with no timeout.
- **Rare cars:** 3% slower per degree of turn (`TrafficMix.racerTurnSpeed`, `TurnSlowPerDeg` 0.03); a started lane slide finishes (eases back if blocked, 1 s hold); a racer that gets far away is removed and replaced by a normal roll.
- **More traffic:** CarCount 28 -> 46, HighwayCars 18 -> 30; low-end stays 14.
- Sync pack uploaded: Model asset 81044857236765 (`imports/sync/sync_21nov_b.rbxmx`: Config, Strings, TrafficMix, StartupGuard, UI, Traffic, Main). Script-pack uploads work again (last night's one, 130702191529633, also finished).
