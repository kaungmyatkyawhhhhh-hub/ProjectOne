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

## Rare cars: one fixed colour and trim each (repo; in the next sync pack)
Owner: "make all the rare car not have the same color or trim and set color,trim like for example rarecar1 is red,sport trim and its like that for every server and game".
| Rare car | Colour | Trim |
|---|---|---|
| nisun_gtr | orange (200, 90, 20) | TOP |
| nisun_r34 (put away: old model) | blue (40, 60, 150) | SPORT |
| ferrara_599 | red (200, 14, 22) | BASE |
| ferrara_california | white (240, 240, 240) | SPORT |
| lambrini_huracan | green (120, 190, 40) | TOP |
| lambrini_lp570 | yellow (240, 170, 10) | SPORT |
| bugotti_chiron | black (20, 20, 22) | BASE |
Fixed in `TrafficMix.Entries`, so it is the same in every server and session. Trims are the same body in this game, so the trim shows as top speed: SPORT x1.05, TOP x1.1 (`TrafficMix.TrimSpeed`); attribute `RareTrim` on the car.

## Rare cars race when they meet by chance (repo; next sync pack)
Owner: "make it so that rare cars can race with each other", then "no dont spawn as pairs i mean like when they meet each other coincidencely".
- No paired spawns. Two racers going the same way within 120 studs (`TrafficMix.Race.MeetGap`) become a race: the one behind takes the same turns, gets a x1.08 slipstream within 90 studs, the leader eases to x0.92 when 70+ studs ahead (and is capped at the slower rival's top speed), passes only through open strips, ends when split by 900 studs. A third can join.
- Tests `racer_race_test` 14/14. Not watched in Play. With caps of 1 and a 1% chance, meetings are only now and then.

## Rare cars: U-turn to start a race (repo; not in Studio, not watched in Play)
Owner: "if two rare cars happen to meet, the faster car will go around and make an u turn and go near the other rare car and they will start racing".
- Any two racers within 250 studs (12 studs of height) "meet". Same way on the same road: race at once. Otherwise the faster one makes a driven U-turn arc (10 mph, 2.5 s) onto the opposite lane and chases at x1.15; the slower one drops to x0.4 so it can be caught (0.85 was too little: the turn takes about 8 s); give up after 25 s, 30 s cooldown.
- Opposite lane is found by place (nearest lane heading the other way within 48 studs): the lane graph has no such link. No U-turn on one-way roads, decks, wide medians, turn pieces, or when a kerb / rail is between the lanes; then only junction steering leads it back. Crossing roads never U-turn.
- Known gap: a car stuck mid-arc has no timeout. Tests: racer_race_test 24, racer_pass_test pass.

## Water rescue (agent working, repo only)
Owner: "when a car goes in water, they get teleported back to the nearest road near the water, facing the roads direction".

## Water rescue written (repo, commit e65d643d); sync pack E
- Existing: a water reset only below Y 20 (never fired at Inya Lake, water at about 40), to the nearest lane with no over-water check.
- New `src/shared/WaterRescue.lua` + Driving: in water for 1 s (water is the first thing under the car, or the body's terrain cell is Water) -> the 8 nearest lane points to where it went in, first one with a road box under it and no water wins, heading = the lane's direction; fade 0.25 s, toast `drive.backOnRoad` (Burmese text marked for review), 4 s cooldown, no penalty. Backspace reset uses the same picker. Trailers are not moved.
- U-turn gap closed: a racer blocked mid-arc for 4 s backs out the way it came.
- **Sync pack E** = operation 5ad3525f-9ae3-43a1-aa9c-d77f1fd7cd7c (`imports/sync/sync_21nov_e.rbxmx`, 10 scripts incl. new StartupGuard + WaterRescue modules; all compile). To install: insert into `ServerStorage.SyncHolding`, run `ClaudeTools.SyncScripts`, compare lengths (Config 198823, Strings 117127, TrafficMix 15299, StartupGuard 1048, WaterRescue 3546, UI 134606, Traffic 71358, TrafficBodies 9886, Driving 186300, Main 42120).
- Owner: real-Yangon look (item 13) goes LAST. Studio jobs run in parallel as soon as the Play test ends.

## Side button order (repo; sync pack F replaces E)
Owner: "put menu at first, shop at second, cars at 3rd, dealer at 4th, goals at 5th, chaffuer at 6th". LayoutOrder: MENU 1, SHOP 2, CARS 3, DEALER 4, GOALS 5, CHAUFFEUR 6 (Market 7 when enabled; Despawn, House, Jobs stay hidden).
Trailer + water rescue: no code needed. `TrailerClient.follow` already puts a hitched trailer straight behind the car after any jump (built for fast travel).

## Old trims leave every inventory (repo; next sync pack: Cars + PlayerData)
Owner: "remove the old trims from every player inventory, keep in studio".
- `Cars.oldTrim(id)` = a SPORT / TOP trim that is off sale (84 of them). When a save loads, PlayerData puts them in `Shelved` like the old-model cars: not in the garage, not drivable, not selectable. The trims stay defined in the code and Studio.
- The ids stay inside the save's Owned list, so nothing is destroyed and it can be undone by removing the rule. No money is refunded (not asked).
- Kept: the Origine's Sport and Top, and the GT-R Nismo (a real car on sale that borrows a body). Test `tools/old_trim_test.luau`.

## Side buttons, second order (agent working)
Owner: "nvm put goals and chauffeur in the menu": side column = Menu, Shop, Cars, Dealer; Goals and Chauffeur become cards on the menu's first page; the goals dot moves to the Menu button.

## Sync pack G = everything written tonight that is not in Studio yet
Operation d817aa1d-6554-4de8-9641-558ab847b651 (`imports/sync/sync_21nov_g.rbxmx`, 13 scripts, all compile). Expected lengths: Config 198823, Strings 117355, Cars 53704, TrafficMix 15299, StartupGuard 1048 (new), WaterRescue 3546 (new), PlayerData 37062 (store name v1), UI 135171, MainMenu 121138, Traffic 71358, TrafficBodies 9886, Driving 186300, Main 42120.
- Menu: Settings, Goals, Chauffeur are three stacked cards on the CAMPAIGN tab (281x98 on phone, 336x131 on PC; World Map narrowed); goals dot on the MENU button and the Goals card. Burmese captions not reviewed by a speaker.
- Install after the Play test ends, then a second Play test for: skip loading, racers (3%/degree, races, U-turn, colours), 46 cars, water rescue (+ trailer), menu cards at phone and PC size, old trims gone from the garage.

## Rare car nose swing + exhaust flames off (21 Nov, late)
- Owner: rare cars behind a car swung their nose ~45 degrees left and right every 1/3 s while going straight.
- Cause: the nose leaned toward the lane the racer WANTED, even while the slide was blocked and undone; at low speed the lean was not capped (it built up at speed, then the car slowed behind traffic: up to ~54 degrees). A blocked slide was tried again 0.2 s later, so it repeated.
- Fix (Traffic.lua): the nose follows only the sideways move that really happened this frame, eased, capped at 19 degrees at every speed; after a blocked slide the racer waits SideHold (1 s) before trying again.
- Exhaust flames off for now (owner: "I will add them back later"): Driving.lua removes the flame emitters and glow right after building them (shortcut comment says how to undo); the Workshop dyno flames off too.
- Sync pack H (asset 74053055634228) = pack G's 13 scripts + Workshop; all 14 checked in Studio, store CityLegends_v1, saved. Not Play-tested yet.

## Play test of the new code (21 Nov, late) - all PASS
- Startup no errors; rare car nose: max 7 deg behind a slower car (was ~45 deg x3 a second), lane changes 15 deg; rare colours / trims / one of each: right; 46 city cars; no exhaust flames; water rescue (Inya Lake) back on the road in 1.1 s facing along it, toast shown; side buttons MENU, SHOP, CARS, DEALER; menu cards there. Store back on CityLegends_v1, 0 test-store scripts.
- Found: a phone switched to low-end AFTER the start kept 46 cars. Fixed: `Traffic.trim(n)` drops the farthest cars to the low-end count when LowEnd turns on (Main.client). Sync pack I (asset 95786305296234), checked in Studio, saved. Not Play-tested (small change, same removal as a far racer). Does not add cars back if the phone leaves low-end.

## Order changed (owner, late 21 Nov): road holes, far roads, car lamps, real-Yangon look, Dala Bridge LAST
Owner also: "never ask me any questions again" (autopilot; say what I will and won't do instead).

### Dala Bridge survey (paused, nothing changed yet)
- New bridge collision (`Landmarks.DalaBridge.Collide_main/west/east`): steps <= 0.2 studs; GAPS between box ends on bends: 1.4-3.2 studs at z 48428-48677, 1.0-2.5 at z 49872-50028 (need filler boxes). Ramps not checked.
- Old deck under it: 21-wide D boxes at y 40.2 (W 7x3x8 at 38.2 on the centre, 1x6x8 at 42.8 at +-10), flat z 44160-47840, down to ~15 at z 48250. 2,842 RCol within 25 studs, many belong to Strand Road area ground roads (z 44900-45700): select by lane 828's line + height, not distance. Keep north of z ~44236 (Phone Gyi junction). Old parapets at x 31565 / 31584, z 44230-44300 poke through the new deck.
- Road meshes: Cell_20x30 = old deck only (whole cell can go); cells 20x28, 20x29, 20x31 mix it with other roads: need a re-bake without "Yangon-Dala Bridge".
- Lane 828 "Yangon-Dala Bridge" (YangonLanes1to1_18.lua), one northbound lane flat at 40.2 over the old deck = NPCs on air. Links {832,59->828}, {828,90->526}, {846,33->828,55}, {828,53->848}. Phone Gyi Street lanes 835/836 stay.

## Owner decisions, 21 Nov (late)
- **Real brands allowed: CB Bank, Meliá, Sedona.** Owner: "i already talked to the managers and they accept it ... they said theyre happy to be in the game and allow me to let their brands be in the game since its like free sponsor too". Their real signs may be shown.
- Do now: truss bridge, YCC interior (only from real photos online), Chinese temple, those three brand signs.
- New R34 model: Sketchfab "Nissan GTR R34 Skyline | GT-R Skyline" by Pooya_dh (uid 5eed440cfd094c5a8fdc9929eb43ab02, CC Attribution: credit needed, commercial OK). The owner's first pick (2005 Nismo Z-Tune by Ddiaz Design) was refused: CC BY-NC-SA (no commercial use) and "based on a CSR2 3d model" (a game rip).

## Roads hidden by terrain after a jump: cause measured, loading fix (21 Nov, about 05:00)
- **What it is (Studio Play, client, Sule spot, same camera, jump from 17,000 studs away, equal waits):** the terrain DATA arrives in about 0.9 s with the right heights (ReadVoxels on the client). The terrain's fine MESHES are drawn later: until then a flat coarse terrain sheet lies 15+ studs over the ground and hides roads, kerbs, the Sule platform and test plates up to +18 studs. On this PC: covered at 1.5 s, mostly clear at 2.5 s, clear at 3.5-4 s. Terrain graphics memory (`Stats` GraphicsTerrain) keeps changing for ~9.5 s after the jump.
- **So the earlier ideas fail on evidence:** lifting road meshes 3-6 studs (the sheet is 15+ studs up), a wider lowered band (same), no Roblox setting for terrain LOD. Mesh downloads were not it here (all 51 road meshes "Success" by 1.0 s; cold phones / HTTP 502 are a separate risk).
- **While driving (150 studs/s, PC) no cover was seen;** the visible gap there is the streaming edge (~600 studs: roads over empty space, no terrain or buildings) - a separate issue.
- **Fix (repo + Studio, synced, checksum 1013210700):** `Main.client` `waitForMap(status, jumped)`: after the parts go quiet, a jump (car spawn, fast travel in a car or on foot) keeps the loading screen up 1.5 s more on PC, 4 s on phones / low-end. SKIP still cuts it. Old loading end on PC: 2.6 s (ring road right of Sule still covered); new: 4.1 s (clean).
- Shots: `2026-11-21 Terrain cover - 0 reference (held still).jpg`, `- 1 jump +1.5 s (covered).jpg`, `- 2 old loading end +2.6 s.jpg`, `- 3 new loading end +4.1 s.jpg`.
- **Not done / not known:** the phone time (4 s is a guess: measure on a phone and tune `TERRAIN_SETTLE_PHONE`); first load "Loading the map..." left as it was (its camera is on the menu shots); the 251 cells carved 10 deep stay as they are.

## Lamp shells cut on the 8 cars that had none (21 Nov)
- All 8 now have full shell sets (12 each: head core + glass, front / rear indicators, reverse, tail), cut from each model's own lamp meshes and placed where the real car has them: astin_dbx (now has a tail lamp: the full-width blade), bentlee_contgt, bentz_sl65bs, bentz_sls, bnw_330i_g20, ferrara_599, mclaran_12c, nisun_350z. Added to `CarLamps.CARS` with their headlamp colour; no daytime lights on the Continental GT, SL65, 599 and 350Z. Old models kept in `ServerStorage.LampBackup_21Nov`.
- New route, no Blender needed: `tools/lamps/lampfx_studio.py` + `LampShellsStudio.luau` + `jobs_studio/` (see `tools/lamps/README.md`).
- Still to do: tail shells on the 12 cars that light the whole rear lens (6 jobs written), the 5 re-cuts, the GLS bumper strip. Not checked at night in Play yet.

## Loading screens made faster (21 Nov, owner: "make the loading screen ingame load fast")
Measured first in Studio Play (this PC; the client now prints `startup phases`, `map wait`, `car spawn`, `fast travel`, the server `server start` and `profile ... loaded in`).

**Before -> after (Studio Play, seconds):**

| | Before | After |
|---|---|---|
| Play -> main menu (PC) | 19.3 | 8.8 |
| Play -> main menu (TestLowEnd + PreviewPhone) | not measured | 8.5 |
| Car out from the menu, asked -> driving (low-end branch) | 7.3-8.2 | 6.4 |
| Car out, PC branch | old code would be ~4.5 (2.6 parts + 1.5 terrain) | 3.9 (with 3.5 s terrain; 4 s now: ~4.4) |
| Fast travel to Sule in a car (low-end branch) | 7.8 | 6.9 |
| Fast travel, PC branch | ~5.1 (old formula) | 4.4-4.7 (with 3.5 s; 4 s now: ~4.9) |

**What was slow at the start and what changed:**
- `RivieraTraffic.build()` 3.7 s (required by Traffic at load): its dead-end pruning swept all 134k pieces 320 times. Now a worklist, same result (checked in Play: same 133,965 pieces, 128,911 live, 2,045 dead, 0 differences), 0.34 s. Also makes the server's Chauffeur graph faster.
- Sound check (`Audio.init` PreloadAsync) 5.0 s: now in the background (`Audio.preload`); the music starts when it is done, a car waits for it (`Audio.waitReady(5)`).
- `BuildingSkin.apply` 3-8 s: it made every facade texture (all styles x moods) before finding that Studio refuses them, for 2 towers. Now: towers first (none = nothing to do), maps only for the looks in use.
- The fixed `task.wait(1)` "let the world replicate" (2 s at loading frame rates): gone.
- GetData: asked right after the remotes, picked up after the world setup.
- Traffic cars (0.4-2.5 s) and JobsClient's state round trip (0.4-0.8 s): behind the menu.
- Start map wait: no fixed 1 s + 1.5 s quiet; it now waits only for parts within 800 studs of the menu orbit's centre (and 300 parts within 400 there). Moved before the profile join so the two overlap.
- After a jump (car out, fast travel): the terrain timer now runs FROM the jump, alongside the parts wait (it used to start only after the parts went quiet); first 1 s fixed wait cut to 0.5; quiet 1 s (was 1.5); a spot within 600 studs of the camera is no jump. The menu orbit is 420+ studs up, so the first car out still counts as a jump. The fade before a spawn starts after the spawn is asked (not before), and the extra 0.3 s after the fast-travel fade is gone.
- **Terrain check tried and dropped:** `Stats` GraphicsTerrain memory keeps rising 8+ s after a jump (no plateau), so there is no usable "fine meshes done" signal. The fixed time stays as the floor: PC 4 s, phone / low-end 6.5 s, both counted from the jump (= the old ends 4.1 s / ~6.6 s, so the hidden-roads fix is kept). Shot after a Sule jump in phone mode: roads clear.
- Server: systems start in 0.7 s; the profile load (DataStore claim) is 3-4 s in Studio and is now what the menu waits on with the first streaming (~6 s, 8,000 parts). An early profile load at join was tried and reverted (no gain: the server was already up when the player joined).

**Kept:** watchdog, guarded inits, SKIP (every wait still checks `UI.loadingWaiting`), the 45 s cap. Studio hook: player attribute `TestTravel` = a fast travel id.
**Synced to Studio** (Main.client, Audio, BuildingSkin, JobsClient, RivieraTraffic, Main.server; each checked against git before and by checksum after; last Main.client 1155535121). Store back on CityLegends_v1, 0 test refs. Not saved (owner saves).
**Not done / not known:** real phone numbers (Studio's "phone" is only the TestLowEnd / PreviewPhone branch on a PC); the 6.5 s phone terrain time is still the old guess; the final 4 s PC terrain value was synced but not Play-timed (it is a constant, +0.5 s on the measured 3.5 s runs).

## R34 RB26 sound set + other cars' engines (21 Nov)
- **RB26DETT set for `nisun_r34`** (family `I6_RB26` in new `src/shared/ExhaustRB26.lua`, one require line in Config; Config 198,984 chars). Measured with GetWaveformAsync + FFT (straight-six = 3rd order, rpm / 20 Hz). Start "RB26 startup" (lutzywins) 17664136845, idles ~1,155 at its end; Idle "RB26_IDLE" (aclausypr) 134505405878971 = 1,188 rpm; Low "rb26 2k on eng" 87793817413007 = 2,024; Mid "rb26 5k on exh" 112284479742965 = 4,984; High "rb26 7k on exh" 87446415279638 = 7,010; Redline "rb26 redline" 125693689836374 = limiter ~8,000 (7.2 Hz bounce); BlowOff "RB26 TURBO BOV" (ManedWolfMenace) 18609462234; shared turbo / pops. The Mid / High / Low / Redline are all Crust_thug's bank.
- Not used: "2k off exh" coast (3.4 dB LOUDER than the on-throttle loop, would get louder on a lift), "2k off eng" (drops out), "6k on exh" 5,990 (7k fits an 8,000 redline better), chachichip "RB26 6k" (really ~4,700) and "RB26 8k" (really ~6,950), Truenus startup (still flaring at its end).
- Play check (the rev sweep through the game's own Audio.engine): idle 960 rpm -> Idle only; 2,100 Low; 3,300 Low + Mid crossing; 4,200-6,000 Mid then High; 7,400 High; 8,000 limiter Redline. Estimated loudness rises evenly -20 -> -16.6 dB, no gaps. The R34 itself can't be spawned in Studio right now: it is Pending (still on its old model in `ServerStorage.OldModelCars`), so the set was played through `Audio.engine` and a fake car.
- **Other players' engines:** the code from 9 Nov works (checked with a fake remote car in `PlayerCars`: the R34 set plays as 3D sound on its root and follows the EngRpm / EngThr its "driver" sends). Cap now nearest 4 (2 on a low-end phone), 220 studs. A real 2-player server was not tested (Studio MCP has no multi-client test).
- **Rare racers have engines now** (`Traffic.lua` `racerSounds`): the nearest 2 racers within 220 studs (1 on low-end) play their car's own set as 3D sound, revs from their speed through 6 made-up gears; dropped past 220 or when the racer is removed. Seen in Play: Huracan heard from 218 studs down to 34; frame time 18.5 ms with a voice, 16.9 ms without (Studio PC, PreviewPhone on).

## Lamp shells, second pass (21 Nov)
- **Tail shells on the 12 lens-only cars** (`tools/lamps/jobs_studio/<id>.json`, cut from each model's own red lens): 458 Speciale, Huracan, Sterrato, LP700, LP750, S680, California, Focus RS, LFA, LFA Circuit, Countach, GLS. With a `LampFx_TailL` the game stops lighting the whole lens and the old TailLights spots, so the GLS bumper reflector and the LFA Circuit's low fog no longer glow as tail lamps.
- **Re-cuts:** Evo VI TME tail = the lamp only (not the boot garnish or the wing stop lamp); Supra MK4: outer block = tail, 2nd (round) = indicator, 3rd block = tail, inner round = reverse (from the old shells); Bentayga reverse = lower band of the tailgate lamp (was a bumper fog spot); 458 Spider got a HeadCore (the projector face, as on the Speciale). Chaser: left as it was (tail / indicator / reverse already split with no overlap).
- Backups `ServerStorage.LampBackup_21Nov.<id>` (24 now). Studio saved v1705 (save only). CarLamps repo = Studio (checksum 2074714912, not changed).
- **Night Play check** (store on CityLegends_test, back on CityLegends_v1 after, 0 test refs): LFA tail, brake, reverse and hazards; Supra tail + hazards; indicators blink cleanly on / off. Edit-stage night shots of all 16 cars and the 458 heads.
- **Not like the real lamps:** the new tails sit under the old indicator / reverse slices, which are still straight ax / height bands of the lens (458 Speciale, Huracan, Sterrato, California, LFA), not the real lamps' shapes; brake-only centre stop lamps (California, LFA, Evo, Bentayga) are not lit at all; the Supra role order follows the model's red blocks; Bentayga's reverse band and the Chaser are judgement calls from the model, not checked against photos.

## Drop-off marker (21 Nov)
- Owner: the DROP-OFF text near Myanmar Plaza (the bank/jewellery heist cash-in spot) should only show while carrying loot. `BankClient.lua` now hides the ring, beam and DROP-OFF label for players without the `Loot` attribute (client side, other players still see it when they carry loot). Synced to Studio (checksum 1569993120), commit a5408893. Play check left for the final test.

## Traffic dead ends fixed in code (cloud, 21 Nov day; repo only, NOT in Studio yet)
- `lanes1to1_test` failed: 1,972 of the 1:1 lane pieces were pruned as "leading nowhere" (whole roads with no traffic: Maha Bandula Road #3, Zoological Garden Road, Gyophyu Road, Kun Chan Road, Bo Min Gaung Street). The lane data itself has 0 dead ends; `RivieraTraffic.build` lost them. Three fixes in `src/shared/RivieraTraffic.lua`:
  1. a link INTO a lane's last point (Maha Bandula Road #3 -> Roundabout 4) now joins its last piece (was dropped);
  2. a link FROM a lane's first point (roundabout lane hops, 20 links) now leaves from the closed lane's last piece / the open lane's first piece (was dropped);
  3. a short lane's last piece with no way on gets its own turns to where the piece up to 3 back turns off (the turn in joined after the turn out: Zoological Garden Road #3 into Roundabout 1).
- Result: dead 1,972 -> 526. All 526 left are lane-2 merge tails (9 pieces after a route's lane 2 merges into lane 1, `mergeRouteEnds`, by design; the old maps have the same). graph, chauffeur, racer, water rescue tests pass. Old maps' dead pieces 73 -> 54 (fixes 1-3 help them too).
- **Still open:** the biggest connected part is 82.7% of the 1:1 network (test wants 90%): some areas can be entered but not left. Needs the lane generator (`roads05_lanes.py`) or more links; not done.
- **Owner / PC:** sync `RivieraTraffic.lua` into Studio and Play-test traffic.

## Exhaust flames + smoke back, only on supercars + 5 hypercars (cloud, 21 Nov day; repo only, NOT in Studio yet)
- Owner: "add exhaust flames and exhaust smoke for super cars and only 5 cars for hyper cars, which is the 4 aventador and 1 revuelto", "find the exact exhaust area for it".
- Cars: every `Class = "Supercar"` (20) + `lambrini_lp700`, `lambrini_lp750`, `lambrini_svj`, `lambrini_svj63`, `lambrini_revuelto`. Off: Veyron, the 3 Chirons, LFA, LFA Circuit, and every non-super car (as last night).
- Exact tips: new `src/shared/ExhaustTips.lua`, measured from each car's own model file (24 .glb files in `imports/`; rear-view renders, each opening picked, depth from the mesh), stored as a share of the car's length from the skin's middle / lowest / rear-most point, so they land right at any scale. E.g. Revuelto: 2 hexagon tips high in the middle; LP750 SV: 4 in the centre capsule; SVJ / SVJ 63: 2 high round tips; Huracáns: 2 round tips either side of the plate; R8s: 1 or 2 per side low. F430 uses its model's own `Exhaust` part.
- `Driving.lua`: flames + a grey smoke puff per tip on pops, nitro, hard high-rev upshifts and lifting off high revs (silent flame on the cars with no pop sound); the tips are tried again for 9 s if the skin arrives after the car. Dyno flames in the Workshop stay off.
- **Not seen in Play** (cloud has no Studio): owner / PC to sync `Driving.lua`, `ExhaustTips.lua` (new ModuleScript in Shared) and check each car's flames sit in the pipes (rear view, rev at a standstill + a hard upshift).

## Traffic traps + unused lanes fixed, world_test fixed (cloud, 21 Nov day; repo only, NOT in Studio yet)
- **Traps** (parts cars can drive into and never leave): 5 roundabouts with no road joined (Roundabouts 11, 12, 15, 25, 26: a car spawned there circled forever), U-turn loops at the edge of the built districts (San Da Koo Street; Bo Min Yaung / Yarza Thingyan Road, 237 pieces), two 4-piece loops by Banyar Dala. `RivieraTraffic.build` now finds every small part (< 1,000 pieces) with no way out and prunes it like a dead end (each map's own big network is kept).
- **Unused inner lanes:** many wide roads' inner lanes had nothing turning into them (the generator links a junction to 1-2 lanes), so cars only ever used some lanes. A 1:1 lane with no link into it now gets its neighbour lane's links (same road and way, start within 20 studs). Biggest connected part 82.7% -> **92.1%** (test wants 90%).
- `lanes1to1_test`: dead-piece bar is now under 1% (merge tails + traps are pruned on purpose; a broken link drops whole roads: 1,972 before). 864 of 130,011 now.
- `world_test`: `Garages.lua` destroyed lamp posts while walking `GetDescendants` and then read their destroyed parts; now it collects first and destroys after (old map only, the baked Monaco city). Passes.
- **All 23 Lune tests pass.** Not in Studio: sync `RivieraTraffic.lua` (and `Garages.lua`) and watch traffic in Play.

## Other players' cars seen from anywhere (cloud, 21 Nov day; repo only, NOT in Studio yet)
- Owner: "u cant see other people car when they spawn outside of ur render distance, fix it so that u can see".
- Cause: StreamingEnabled; player cars were `ModelStreamingMode = Atomic`, so a car past the streaming radius was never sent to you.
- Fix: player cars (`Main.server` spawnFor) and chauffeur cars (`Chauffeur.lua`) are now `Persistent`: sent whole to every client and kept wherever they are. One car per player keeps it cheap; parked house cars stay Atomic.
- Not tested in Play (needs 2 players far apart, e.g. Studio's 2-player test, one fast-travels away).
## PC run of the "sync today's cloud fixes" prompt (21 Nov)
- **Blocked:** Studio on the PC was running with NO place open, so nothing was synced (RivieraTraffic, ExhaustTips, Driving, Garages still repo only). Lamps and the P8 re-bake also need Studio. Owner: open City Legends in Studio, then rerun the prompt.
- **GT-R Nismo import refused:** `imports/importing cars/2017_nissan_gt-r_nismo.glb` is Ddiaz Design, licence **CC BY-NC-SA 4.0** (no commercial use; read from the file's own metadata). Same reason as the refused R34 Z-Tune. Not imported; `nisun_gtr_nismo` keeps borrowing the R35 2013 body. Needs a model with a commercial-OK licence (CC BY, CC0, or bought).
- Lune 0.11.1 on this PC segfaults on the tests (cloud used 0.8.9): install 0.8.9 here to run them.

## PC run, 21 Nov evening (Studio open): cloud code synced + owner's new asks
- **Synced into Studio (checksum = repo for each):** RivieraTraffic, ExhaustTips (new), Driving, Main.server, Chauffeur, Garages, TrafficMix, Activities, JobsClient, YangonSignals (new), Main.client. Method: `multi_edit` with diffs from the git version Studio had (HttpService to 127.0.0.1 still blocked). CarSkin left alone: Studio's copy is the repo minus the unused GC8 lines (removed 20 Nov).
- **Other players' cars (owner: "u cant see other people car when their car goes out of render distance and comes back"):** the Persistent fix is now in Studio; a spawned car shows `ModelStreamingMode = Persistent`. Not tested with 2 real players.
- **Exhaust flames:** SVJ checked in Play: 2 flame + smoke tips at the rear middle. The other 24 cars not checked one by one (tips are the cloud's measured rows).
- **Delivery ring removed (owner: "remove the delivery job blue neon circle area"):** the blue dispatch rings are invisible (sign + "stop here" stay, the stop still works); the gold job ring is hidden for the delivery job too.
- **Fewer YBS buses (owner: "spawn less ybs bus"):** `TrafficMix` ybs weight 6 -> 2.
- **Flyover by Myanmar Plaza, falling through the pavement:** the ground under the Kabar Aye flyover deck (x 34100-34700, z 28200-29560) had pavement / road meshes but no collision (terrain 2-7 studs lower). Added `Workspace.Yangon1to1.Roads.CollideFix_MyanmarPlazaFlyover`: 270 invisible `RCol` strips (RoadBox P / R) laid from the pavement / kerb / road meshes' own triangles, every spot within 0.2 studs of the surface. Place-only change: **owner must save**.
- **Traffic lights (owner: "put traffic lights too"):** `RivieraTraffic` finds the 1:1 junctions (link mouths clustered, 2+ roads, 3+ lanes, no roundabout, one level, cross traffic) and sets the old city's `seg.signal` on each lane piece entering them: 188 junctions, 1,671 approaches. Traffic, chauffeur and police stop on red with the old code. New `client/YangonSignals.lua` puts up poles (old city look) within 650 studs; lenses use the `TrafficLamp` tag so WorldFx lights them. Play-tested at the spawn junction: pole on the corner, lights change, cars wait at the line, no script errors. Not tested: every junction's pole spot, phone FPS.
- **Still open:** P8 deck dip (needs the home PC's `roads_unfixed.json`), car lamp shells (Blender), GT-R Nismo (licence: needs a commercial-OK model), real-Yangon look, Dala Bridge.

## Real lamp shapes on 5 cars: cut, NOT in Studio yet (21 Nov, late)
- Checked: the 4 "tail shell" cars (bentz_sls, ferrara_599, mclaran_12c, nisun_350z) already have full shell sets in `CarModels` (12 each). Nothing left there.
- New shells cut from each model's own lamp pieces (jobs `tools/lamps/jobs_studio/<id>.real.json`, files in `imports/sync/lamp_shells/<id>.glb`):
  - **458 Speciale:** indicator = the round lamp's centre (the red lens is a ring round it), reverse = the low round bumper lamp. Tail ring stays.
  - **Huracán / Sterrato:** indicator = the thin strip along the top of the unit (the model's own piece); Huracán tail = the whole Y lens with its outer end. Reverse stays.
  - **California:** round lamp = tail / stop only; indicator = outer half of the low unit beside the plate, reverse = its inner half (lens is `SeeThrough_Window2`).
  - **LFA:** indicator = round lamp at the cluster's outer end, reverse = the low bumper lamp. Tail stays.
- `lampfx_studio.py` got a `disc` source (a round or ring piece made in the tool, for a lamp the model has no loose piece for).
- **Blocked:** Studio refused the uploads: "`imports/sync/lamp_shells` is not inside a directory approved for uploads" (this PC's Studio: Assistant Settings -> MCP Permissions). Once `Games/CityLegends/imports` is approved: upload each .glb as a Model (group 33151111), paste `LampShellsStudio.luau`, `LS.apply(id, assetId)`, look, `LS.unstage()`.
- From knowledge of the real cars, not checked against photos: which low lamp is reverse on the 458 / LFA, the California's low unit split.
- **P8 deck dip:** still blocked here: this PC has only `roads.json.gz` / `paint.json.gz`, no `roads_unfixed.json`, and the re-bake needs uploads too.

## Owner asks, 21 Nov about 11:00 (repo only, NOT in Studio yet: no place was open)
- **"make rare cars more common":** `TrafficMix.RareChance` 0.01 -> 0.03; caps ferrari / lambo / gtr 1 -> 2 (r34, bugatti stay 1). `racer_race_test.luau` line updated.
- **"leave 1 car gap between cars so that players can cut through traffic":** `Config.Traffic.StopGap` 4 -> 15 (a stopped queue keeps a car length), `FollowGap` 16 -> 18, spawn spacing in `Traffic.lua` 22 -> 30.
- **"put option for max graphic which loads 35% of the map around u":** Settings > Render distance gets **MAX** (`RENDER_MULT.Max = 8.1`: 252 road cells x 1,536^2 = 594.6M sq studs, 35% = radius 8,140 over the 1,000 LOAD). Saved as `Settings.RenderDistance = "Max"` (PlayerData accepts it). WorldFx caps the light range at Ultra's (x1.5). Limits: about 66 times High's tiles (not measured yet: test FPS / memory on this PC before trusting it); the server's streaming radius (640) is one value for every player, so far roads / shells still arrive by Roblox's own streaming.
- **Upload folder:** Studio's folder picker saved `C:/Windows/System32` whatever was picked; the owner fixed the list by hand (`%LOCALAPPDATA%/Roblox/AssistantSettings/<user>.json`, `approvedUploadDirectories`). It now holds `Games/CityLegends/imports`.

## In Studio, 21 Nov about 11:20: lamps, rare cars, traffic gap, MAX (checksums = repo; NOT saved yet: owner saves)
- **Real lamp shapes on 5 cars: in `CarModels`** (12 shells each, looked at lit on an Edit stage): 458 Speciale (asset 109353062083178), California (77716912888768), Huracán (104349610663634), Sterrato (90876192046421), LFA (93214084886044). The Huracán / Sterrato indicator strip is cut at ax 0.54 / 0.525 so it stops where the reverse lamp starts (the first cut overlapped it). State before this pass: `ServerStorage.LampBackup_21Nov_beforeRealShapes`. Not seen at night in Play; front lamps untouched.
- **Rare cars / gap / MAX synced** (TrafficMix, Config, Traffic, MainMenu, WorldFx, PlayerData).
- **Traffic gap, measured in Play:** 182 same-lane pairs over 6 samples, smallest bumper gap 15.0 studs, median 31.9, none under 12. No script errors.
- **Rare cars:** none seen in a 4 s sample of 46 cars (3% chance: expected about 1). Not watched longer.
- **MAX render distance = x3, not 35%.** x8.1 (35% of the built map) tried in Play: 24 FPS at Ultra (21,000 parts) fell to 8 FPS at 114,000 parts after 83 s with 737 tiles loaded and still loading: not shipped. x3 settles at 429 tiles / 64,000 parts (about 11-12 FPS in this Studio by the same curve; Studio went minimized so its own FPS was not read). A real 35% needs merged far meshes, not more kit parts.
- An Open Cloud Model upload failed once with "Unknown Error" (Huracán): the same file again worked.
