---
tags: [city-legends, traffic, yangon]
created: 2026-11-19
---
# Yangon traffic: roster cars, our Probox / Hiace / Carry / YBS, rare racers (19 Nov 2026)

Owner, 19 Nov:
- "for traffic, rn the ai cars are blocky and so bad. i think it should be the cars that are common irl in yangon"
- "they should use the cars from the cars that i already made by hand"
- Plus: rare supercars with caps, racers that "swim" through traffic at 100-220 mph.

Research: [[2026-11-19 Research - Yangon common traffic cars]].

## What's in the game now (Studio, saved; not published)
`ReplicatedStorage.TrafficModels` holds 21 cars. The old low-poly pack is kept in `ServerStorage.TrafficModels_old` until the owner has tested; `TrafficLOD.undo()` brings it back.

| Type | Car | Share | Licence / source |
|---|---|---|---|
| Probox / Succeed taxi-van | `Traffic_A_probox` (new, with an amber roof sign) | 18% | ours (tools/yangon_traffic_cars.py), no licence needed |
| Swift | roster `suzaki_swift` (light copy) | 12% | owner's car |
| Belta / Vios | roster `toyoka_belta` | 12% | owner's car |
| Mark II / Chaser | roster `toyoka_chaser` | 9% | owner's car |
| Camry / Axio size | roster `toyoka_camri` | 7% | owner's car |
| Alphard / Wish | roster `toyoka_alfard` | 6% | owner's car |
| Hiace van | `Traffic_C_hiace` (new) | 6% | ours |
| Carry / Hijet kei truck | `Traffic_H_carry` (new) | 6% | ours |
| YBS bus (main roads) | `Traffic_D_ybs` (new; route colours + yellow) | 6% | ours |
| BYD / EVs | roster `byt_seal` | 5% | owner's car |
| Crown | roster `toyoka_crown` | 4% | owner's car |
| Land Cruiser / Prado | roster `toyoka_lc200` | 4% | owner's car |
| New luxury SUV | roster `toyoka_lc300` | 2% | owner's car |
| Lexus LX | roster `lexis_lx700` | 1% | owner's car |

The `kio_ev6` light copy came out with holes (its body is many small pieces), so it is left out.

**Rare racers** (owner's caps, `TrafficMix.Rare`). They are spawned at 7% per car while their group is under its cap:

| Group | Cars | Cap | Top speed (mph) |
|---|---|---|---|
| Ferrari-style | `ferrara_599`, `ferrara_california` | 2 | 185 / 170 |
| Lamborghini-style | `lambrini_huracan`, `lambrini_lp570` | 2 | 185 / 190 |
| GT-R R35-style | `nisun_gtr` | 10 | 150 |
| R34-style | `nisun_r34` | 3 | 130 |
| Bugatti-style | `bugotti_chiron` | 1 | 220 |

- `ferrara_f430` has no `Wheels` folder in CarModels, so the 599 stands in for it.
- Each racer has the attribute `RareTraffic` (its group), the hook for the later chase bonus.
- Traffic runs on each client, so the caps hold per player's view of the map.

## How it works
- `src/shared/TrafficMix.lua` holds the mix, lengths, liveries, caps and racer numbers. It is a separate module because `Config.lua` is at its 199k sync limit. `TrafficMix.pick` chooses each spawn. Studio test hook: the workspace attribute `TestRareChance` (set it to 1 to fill every cap).
- `client/TrafficBodies.lua`:
  - Each car is scaled to its own real length.
  - Parts with `TrafficPaint` get a random livery colour.
  - Templates with `KeepColors` keep their plain colours.
  - Rare cars get `RareTraffic` and `RacerMph`.
  - Parked cars never use rare cars or buses.
- `client/Traffic.lua` runs the racer profile on rare cars only (everyday cars are unchanged):
  - **Speed:** top speed on straights. It brakes ahead of time for every bend (safe speed from the curve's radius at about 0.9 g), turn piece and red light within braking distance, with the way ahead chosen in advance (`plan`).
  - **Looking ahead:** it looks 2.6 s ahead and keeps 1 s more gap behind players' cars. It accelerates at 40 and plans with 95 studs/s² of braking.
  - **Swimming:** five times a second it looks for a better gap. It slides into a lane beside it (same direction only, from `ChauffeurRoute.graph().lanesBeside`) or onto the line between two lanes (a split), and only when that strip is clear beside it and no faster car is coming up behind. Over another lane's middle it takes that lane over.
  - **At junctions:** before the next junction or light it settles back into a lane and behaves normally.
  - **Distance:** racers think every frame and are recycled at 1,500 studs instead of 700.
- `tools/yangon/TrafficLOD.luau` (Studio, `ServerStorage.ClaudeTools.TrafficLOD`) makes the light copies from `CarModels`:
  - It keeps the exterior only and drops cabin, seats, plates, badge-like flat textured parts, lamp shells, scripts and lights.
  - Glass becomes opaque and dark. Parts get plain colours by role. Rips with no paint parts (R34, Chiron) keep their pictures.
  - It sets RenderFidelity Automatic, no shadows and no collision, and caps the body at 45 parts.
  - It always keeps the `MarkPatch` badge covers.
  - Functions: `make`, `install`, `newSet`, `stage`, `undo`.
- `tools/yangon_traffic_cars.py` builds the four new vehicles: about 600-700 triangles each, vertex colours, Body (paint) + Detail + 4 wheels. Uploaded as asset 87014565089838 (group 33151111).

## Test results (Play on `CityLegends_test`)
- **Before** (old pack): 28 cars, 362 parts.
- **After**: 28 cars, 675-743 parts. GraphicsMeshParts stayed at 43 MB, GraphicsParts went from 19 to 23 MB, total client memory did not rise (12.4 GB before, 12.2-12.4 GB after, in Studio). The part count about doubled because the roster cars are 22-61 parts each instead of 5.
- **Wheels:** 112 wheel motors on 28 cars (4 each), and they turn.
- **Caps:** with `TestRareChance` 1, the live count matched the caps exactly (bugatti 1, R34 3, GT-R 10, ferrari 2, lambo 2). 20,000 pure `pick` calls against random live counts never went over a cap.
- **Racers** (`TestRareChance` 1, about 30 s windows):
  - Top speeds reached: Bugatti 218, Lamborghini-style 184-195, Ferrari-style 173-190, GT-R 154, R34 133 mph.
  - 65-84 lane changes per window, so they do overtake and weave.
  - **Not clean yet:** 6 overlap events in one window after the first fix, with a racer running into the car ahead after cutting in. With the "room to brake" gate added, two GT-Rs ended up inside each other once and a GT-R touched a Swift. Everyday cars had 0 overlaps.
  - Splits between two side-by-side cars never happen on the 12-stud 1:1 lanes: two 6.5-stud-wide cars leave no room. Splits only happen when the cars are staggered.
- **Not done:** P3 shots, a close-up of each type in Play, badge patches, and a check that the switch back to `CityLegends_v1` shows on the Server in a Play (the Edit source is checked). See below.
- **Racer shots:** [[2026-11-19 Yangon traffic - racer weaving 1.jpg]], [[2026-11-19 Yangon traffic - racer weaving 2.jpg]], [[2026-11-19 Yangon traffic - P1 racer and Swift (Play).jpg]].
- **Close-up (Edit):** [[2026-11-19 Yangon traffic - close-up Swift Belta Camry (Edit).jpg]].

## Lessons (also in the Playbook)
- A model's `WorldPivot` can carry a half turn. TrafficBodies does `PivotTo(CFrame.new())`, which turned those cars round so they drove backwards. Give every template a plain pivot at its box middle.
- A kit car's shape is often a `SpecialMesh` child of a plain Part. Stripping a part's children turned the Swift into red boxes. Keep `DataModelMesh` children.
- RenderFidelity `Performance` crumpled the kit cars' shells even up close. Use `Automatic`.
- The 1:1 lanes come in short pieces. A "near the end of the piece" test is always true, so a racer never changed lanes until the test looked for the next real junction (a turn piece or a light).
- Python written through a bash heredoc ate `"\n"` into a real newline again, and the module failed to load. Use `string.char(10)`.

## Racer crashes, second pass (19 Nov, later)
`client/Traffic.lua`, racers only (everyday cars unchanged, so the extra CPU is only on the rare cars):
- **Swept strip:** every frame the racer looks at the strip it covers over the next second, its lane AND the lane it is sliding to (`racerSweep`), and caps its speed to stop behind the nearest car in it.
- **Lane-change gate by closing speed:** a slide needs room ahead = a second of closing speed + braking from its speed down to the car ahead's (`racerRoom`), in the target lane and on the way there.
- **Racer beside a racer:** the one level or behind (along the two's mean heading) waits (`racerBeside`), so two never slide into each other and never both wait.
- **Hard guard:** after each step, the racer's box (+0.4 / 0.25) is tested against every car near it (`racerHit` / `racerBlocked`). A step that touches a new car, or digs deeper into one, is undone and the racer takes that car's speed. A sideways slide is checked all round; if only the slide touches, the racer drives on straight and the slide waits. Straight steps answer only for cars ahead; between two racers "ahead" is along their mean heading. Counter attribute `RacerHolds`.
- **Merge wait creeps:** `holdMerge` used to cap the speed at 0.9x the speed, which at 0 stayed 0 forever (a whole queue of racers froze); it now creeps at 4 studs/s at least.

**Test (Play on `CityLegends_test`, `TestRareChance` 1, 18 racers of 28 cars, an oriented-box overlap count every frame on the client):**

| | Racer overlaps | Time | Avg racer speed | Racers under 5 mph |
|---|---|---|---|---|
| Before | 68 (36 racer x racer) | 202 s | 56 mph | many (queues) |
| After | 14 (6 racer x racer) | 212 s | 90 mph | 1% |

Not 0 yet. The ones left are almost all at junctions at 0-30 mph: crossing / turning cars at an angle, and everyday cars (which have no guard) running into a racer. A final run with a debug counter (does the racer's own step ever make an overlap?) could not be done: Studio's MCP Play button stuck ("Start play hasn't finished yet") for the rest of the session.

## Badges on traffic copies (19 Nov, later)
- **Converted cars:** `TrafficLOD.make` now bakes the game's BrandMarks covers in (badge parts hidden by name / size, printed logos and plates covered, wheel caps), a fifth bigger than measured. Cars in `CarFinish.CARS` (GT-R, 599, California, Huracan, LP570) have their logos out of the model already and get none. New covers: Seal +8, LC300 +13, LX +7, R34 +5. The Chiron and the Chaser have no BrandMarks entry and showed no badge close up.
- **Roblox-built cars, fixed in `CarModels` (player cars too), `tools/brand_marks/RobloxBuiltPatches.luau`:**
  - Belta / Vios taxi: grille emblem (chrome cover), boot emblem, TOYOTA and YARIS letters (paint covers).
  - Camry: the boot emblem + CAMRY + XSE are one small mesh, and the grille emblem is its own part: both deleted (backup `ServerStorage.BadgeRemovalBackup.toyoka_camri`).
  - Swift: both S badges deleted (backup), both "SWIFT" name plates made plain white plates.
  - Land Cruiser 200 (found on the close-up pass): grille emblem covered, boot emblem, VX.R and V8 5.7 covered.
  - Covers on paint are named `MarkPatch_Paint` (the Regent Sport's too), so Customs repaints them with the body and traffic treats them as paint. TrafficLOD keeps every `MarkPatch*`.
- Traffic copies rebuilt with `TrafficLOD.install` (backup of the old set: `ServerStorage.TrafficModels_preBadges`).
- Shots: `City Legends/2026-11-19 Traffic badges - *.jpg` (Belta, Camry, Swift, Land Cruiser 200 before / after; Seal, Belta, Camry, LX, LC300, R34, Chiron, GT-R / LP570 / Huracan, 599 / California traffic copies).
- **Seen, not fixed:** the Camry and Belta traffic copies are open at the rear doors (white seats show through) and the Chiron's copy has no rear panel; they were like that before (parts the copy drops). The LC200's "NY GARAGE" plates on the player car are a made-up garage name, left.

## Left to do
1. Racer overlaps 14 -> 0: run the debug counter (Studio's Traffic had a `DbgV` attribute block for it; remove before saving), then a junction rule for racers (treat crossing cars at an angle as ahead).
2. **Shots:** P3 traffic and a close-up of each type in Play (Play could not start).
3. Switch-back check on the Server in a fresh Play (`CityLegends_v1`; the Edit source is back on it).
4. **After the owner's phone test:** delete `ServerStorage.TrafficModels_old` and `TrafficModels_preBadges`.
