---
date: 2026-10-14
tags: [gymarc, feature, performance]
status: done (owner: streaming radius setting)
aliases: [GYM ARC Performance, Culling and LOD, Streaming]
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Performance

How the game stays smooth on phones. Owner's request: [[2026-10-14 GYM ARC Prompt - NPC culling, LOD and streaming]].

## Measured before the changes (14 Oct)
Studio test, one player, starter gym floor looking down the gym, 16 NPCs:
- About 30-40 frames a second, about 250 draw calls, about 720 shadow draw calls, about 1.78 million triangles.
- With the NPCs hidden: about 48 frames a second, 114 draw calls, 411 thousand triangles. So the NPCs were about three quarters of everything drawn.

## Step 1: NPC culling (done)
- One manager on each player's device looks at the NPCs a few at a time, never all at once.
- Close (under 40 studs) and on screen: everything moves and sparkles.
- 40 to 100 studs: still animated, fewer particles.
- Further than 100 studs, or behind the camera: frozen in their pose, no particles.
- On the server, a gym regular with no player within 120 studs stands still (no walking, no path finding) until someone comes near.
- Your own trainer is never frozen; an arm wrestling opponent is always treated as close.
- Result in the same scene: 211 draw calls (was about 250), 1.41 million triangles (was 1.78).

## Step 2: LOD (simpler far NPCs) (done)
- An NPC further than 60 studs away shows a plain body (no muscle shapes, no hair or hats); closer than 50 studs it gets its full look back. The gap stops it flickering.
- Nothing is rebuilt when it switches: the muscle shapes are just hidden and shown again.
- Never for your own character, other players, the statue or an arm wrestling opponent.
- This replaces the old rule from 13 Oct ("never a visible change by distance") for NPCs.
- Also across the map: meshes now simplify themselves when far away, decorations use simple collision shapes, and 491 small props no longer cast shadows (machines, the arm wrestling table and characters keep theirs).
- Result in the same scene: about 47-48 frames a second (was 30-40), the slowest frame 24 ms (was up to 142 ms), 125-146 draw calls (was 250), about 0.5-0.7 million triangles (was 1.78).
- Still high: about 700 shadow draw calls, from the gym's many lights that cast shadows. That is the next thing to look at.
Before, then after:
![[GYM ARC/Screenshots/performance_scene_before.jpg]]
![[GYM ARC/Screenshots/performance_scene_after_lod.jpg]]

## Step 3: instance streaming (done, one setting left for the owner)
- Streaming was already on. Each machine, NPC, arm wrestling table, the posing stage and the smoothie bars now load as one whole piece when you come near (never half), and leave when you're far. Only the spawn area (starter gym, entrance, gym front) is always loaded.
- Every player-side script was checked so nothing breaks when something isn't loaded yet or leaves: the pro gym door, the machines, the mirror, the tutorial's guide path, the machine signs, the rival tags and the arm wrestling tables were fixed.
- Before the server moves a player out of the locked pro gym, it makes sure the spot is loaded on their device.
- **Owner to do (Studio, Properties panel; scripts can't change these):** select Workspace, then under Streaming set StreamingTargetRadius 256, StreamingMinRadius 64, StreamOutBehavior Opportunistic, StreamingIntegrityMode PauseOutsideLoadedArea. Until then the whole map still loads at once.
- Tested: machines in the starter gym, pro gym and beach gym (sit, HUD, REP), both arm tables, the posing stage, the smoothie bars, the mirror, the pro gym door; no errors.

## Before and after (same view)
- Before: about 27-41 frames a second, the slowest frame up to 142 ms, about 250 draw calls, 1.78 million triangles.
- After all three steps: about 36-48 frames a second, the slowest frame 31-84 ms, about 150-190 draw calls, 0.5-1.2 million triangles (it moves as the regulars walk in and out of range).
- Next big lever: the gym's many lights that cast shadows (about 600-700 shadow draw calls).
![[GYM ARC/Screenshots/performance_scene_after_all.jpg]]

## Lag check, 14 Oct
**What causes the lag: drawing (rendering), not scripts or physics.** Scripts take about 1.4 ms a frame and physics about 1.1 ms; drawing takes 15 to 30 ms.

Two things make drawing expensive:
- **Muscle bodies are very detailed.** One body wearing the muscle stage meshes is about 123,000 triangles (torso halves 19,950 each, upper arms 13,728 each, forearms and calves 8,256 each, thighs about 11,000 each). At the starter gym about 750,000 body triangles were drawn at once. This is the part to simplify in Blender.
- **The map has a lot of parts.** 21,859 parts (the town alone 16,844), 294 lights, 424 signs. Streaming is set (radius 256), but the town is compact: almost all of it (20,265 of 21,859 parts) is within 256 studs of the spawn, so the phone still loads nearly everything. A radius of 128 to 160 would about halve that, with far buildings appearing a bit later.

**Quick wins done:** 192 small props no longer cast shadows. The map's mesh settings were already correct. No duplicate parts were found, and no free-model scripts.

**Body mesh collision:** already Box on all 90 muscle stage meshes (checked again; nothing to do).

**Far bodies:** NPCs further than 60 studs already switch to a plain body (checked). Other players never do, by the earlier rule; this could change if wanted.

### Heaviest meshes
| # | Mesh | MeshId | Triangles | Copies in the place | Where |
|---|---|---|---|---|---|
| 1 | BS_Torso_Front_g000 | 78363131212696 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 2 | BS_Torso_Front_g020 | 84851847888387 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 3 | BS_Torso_Front_g040 | 71416633931227 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 4 | BS_Torso_Front_g060 | 115336578035539 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 5 | BS_Torso_Front_g080 | 99677012136257 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 6 | BS_Torso_Front_g100 | 129324753285817 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 7 | BS_Torso_Front_gmon | 137013043275089 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 8 | BS_Torso_Back_g000 | 109599664465114 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 9 | BS_Torso_Back_g020 | 96188948784068 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 10 | BS_Torso_Back_g040 | 114001138197400 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 11 | BS_Torso_Back_g060 | 97198593908439 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 12 | BS_Torso_Back_g080 | 125070479825044 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 13 | BS_Torso_Back_g100 | 140465933559267 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 14 | BS_Torso_Back_gmon | 127301004702519 | 19,950 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (torso stage) |
| 15 | BS_LeftArm_Arm_g000 | 106820270054132 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |
| 16 | BS_LeftArm_Arm_g020 | 76714840120580 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |
| 17 | BS_LeftArm_Arm_g040 | 126982024186662 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |
| 18 | BS_LeftArm_Arm_g060 | 84400921353716 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |
| 19 | BS_LeftArm_Arm_g080 | 127996084088671 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |
| 20 | BS_LeftArm_Arm_g100 | 134822315929590 | 13,728 | 1 template; 1 clone per body at that stage | ReplicatedStorage.BodyStages (upper arm stage) |

Full numbers are in PROGRESS.md.

## Low-poly body meshes, 15 Oct
The owner's simplified (Blender) body meshes replaced the detailed ones on every NPC, other player, trainer and the statue. Your own live muscles are unchanged, and so is the waist piece.
- **One body is now about 31,000 triangles instead of about 123,000 (4 times fewer).**
- Every stage from skinny to mass monster was checked front and back: the clothes and skin look the same, no gaps.
- The old mesh ids are saved (Config > StageMeshBackup) so this can be undone.
- Frame rate in Studio stays about 15 fps either way while it is remote-controlled; the real gain shows on a phone.

| Stage | Before (front) | After (front) | Before (back) | After (back) |
|---|---|---|---|---|
| g000 | ![[GYM ARC/Screenshots/lowpoly_before_g000_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g000_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g000_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g000_back.jpg]] |
| g020 | ![[GYM ARC/Screenshots/lowpoly_before_g020_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g020_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g020_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g020_back.jpg]] |
| g040 | ![[GYM ARC/Screenshots/lowpoly_before_g040_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g040_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g040_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g040_back.jpg]] |
| g060 | ![[GYM ARC/Screenshots/lowpoly_before_g060_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g060_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g060_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g060_back.jpg]] |
| g080 | ![[GYM ARC/Screenshots/lowpoly_before_g080_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g080_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g080_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g080_back.jpg]] |
| g100 | ![[GYM ARC/Screenshots/lowpoly_before_g100_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g100_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_g100_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_g100_back.jpg]] |
| gmon | ![[GYM ARC/Screenshots/lowpoly_before_gmon_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_gmon_front.jpg]] | ![[GYM ARC/Screenshots/lowpoly_before_gmon_back.jpg]] | ![[GYM ARC/Screenshots/lowpoly_after_gmon_back.jpg]] |

## Performance part 2 (15 Oct)
Measured first at the starter gym. The game's own scripts are cheap (about 1 ms a frame, all of them together); the server does very little; network traffic is tiny. Drawing is the cost, as on 14 Oct.
- **Shadows** were the one clear cost: switching them off cut drawing time by about a third. 314 small or see-through parts no longer cast shadows (buildings and big objects still do).
- **65 signs** now stop drawing beyond 100 studs.
- **Not changed:** lights, particles, post effects (no clear cost), and the map's part count (merging parts would change the build; lowering the streaming radius to 128-160 in Workspace Properties is the owner's choice).
- Studio can't give real phone numbers while it is remote-controlled; a test on a phone (F9 Developer Console) is still needed.
Full list in PROGRESS.md.

## Mirror reflection removed (15 Oct)
The live mirror reflection cost about 42 ms of drawing time every frame near the progress mirror (Studio: 49 ms down to 7 ms on the computer side, 16-20 ms down to 2-7 ms on the graphics side). The mirrors are plain now. See [[GYM ARC - Progress Mirror]].

## Body lag fixed (20 Oct)
Your own body was rewritten up to 26 times a second while training (each one a 65-90 ms frame). Now it's rewritten at most once a second, with no growth animation and no mesh pump. On PC a fresh player training went from about 33 to 46 FPS. Low-end devices (FPS under 40 for 5 s, or graphics quality 1-3) show the low-poly stage body for you when the camera is more than 15 studs away. All stage meshes are low-poly; the biggest cost left is the gym lights' shadows. See [[2026-10-20 GYM ARC Body lag]].

## Blob shadows and light shadows (20 Oct)
Bodies cast no real shadow. Each one gets a cheap soft blob shadow instead (BlobShadowClient). Only 5 of the 296 lights cast shadows (the main spots of the starter gym, the pro gym and the posing stage). On a phone or a low-end device all light shadows are turned off (LightShadowsClient). At low graphics quality Roblox draws no shadows anyway. Most shadow draw calls on a PC come from the sun's shadows, which haven't been changed (owner decides). Numbers: [[2026-10-20 GYM ARC Body lag]].

## Pro Gym valley city shows from everywhere (27 Oct)
Owner: "the Pro Gym valley city becomes blocky". From the beach / west / north of town (outside BackdropClient's area x > 20, z < 200) the cheap far city (dark blocks) showed. The real city is Blender meshes now (1,388 parts, was 3,143; Automatic mesh detail), so `BackdropClient` shows it from everywhere; only low-end phones (`Shared/LowEnd`) still get the far city outside that area. Tried first: full mesh detail (RenderFidelity Precise, ~576k triangles) made no visible difference at that distance, undone. Shot `city_from_beach_real.jpg`.

## Optimization pass, step 0: measured (27 Oct, prompt 67)
Studio play test on the owner's laptop, graphics quality Level 2, window 871 x 584 (phone-like). Laptop numbers, not a real phone (the owner: a phone will be slower).

| Spot | FPS avg / worst 1% | Render CPU | Parts on device | Lights on | SurfaceGuis on |
|---|---|---|---|---|---|
| Starter Gym | 15 / 12 | 31 ms | 32,176 | 282 | 1,498 |
| Plaza | 15 / 14 | 15 ms (+29 ms GPU) | 32,318 | 282 | 1,502 |
| Pro Gym (city view) | 15 / 12 | 27 ms | 31,869 | 282 | 1,507 |
| Powerlifting Gym | 15 / 14 | 32 ms | 32,142 | 282 | 1,507 |

- Client memory ~4.9 GB in Studio (Studio itself counts; LuaHeap 1.3 GB, Gui 1.4 GB, Instances 263 MB, BaseParts 256 MB). Physics 1-2 ms: drawing is the cost, not physics.
- The same ~32,000 parts in every spot: the streaming radius covers almost the whole map.
- **Soak test, 35 min**, one player benching on AutoLift: server Lua memory 73-81 MB (flat, no climb), server instances 184,800-185,300 (flat), heartbeat 0.1-0.7 ms; client Lua 70-117 MB (goes up and down with garbage collection, no climb), client instances ~108,500 (flat), PlayerGui 16,117 -> 16,153 (+36 in 35 min: tiny). **No memory leak.**
- Biggest costs found: (1) everything streamed in everywhere; (2) **1,284 plate number labels** (both faces of every plate showed a number); (3) 282 lights on at midday (gym interior lamps everywhere); (4) the barbell plates: 637 plates x 11 parts = 7,007 parts (23% of the world); (5) buildings 3,357, street 2,818, squat racks ~3,000, palms 1,140, Pump Shop interior 1,166 parts.

## Step 1 done: plate labels (27 Oct)
The 7 plate templates (ReplicatedStorage.GymAssets.Plates) had both number faces on; MachineService only ever turned the outermost plate's on and never the others off. Templates now off (the outermost plate's FaceRight still turns on, as designed); decor plates (plate trees, racks, loose) keep a number only on the face at the end of each stack (229 kept, 247 off).

## Step 2 in progress: remodel into meshes (owner: "remodel everything listed")
Tools in `Downloads\gym_arc_models
emodel`: `export.lua` (Studio: marks every mergeable part with Merge / MergePivot and posts its shapes), `receiver.py`, `build.py` (Blender: each unit's parts become one mesh per material, the parts' exact colours as vertex colours, identical copies share one mesh), `out\*.fbx`.
- props.fbx: 269 meshes for palms, oaks, benches, street lamps, decor plates, squat racks (5,722 parts). The racks' working parts (bar, posts, prompt...) stay.
- town.fbx: 288 meshes for buildings, street, plaza, parks, skate park, greenery, Pump Shop interior, Strongman Yard (5,074 parts; only non-colliding, non-glowing, non-sign pieces; textured materials only on pieces under 8 studs, so walls keep their texture).
- plates.fbx: 21 white meshes (Rim / Hub / Hole per template) so the gold / red recolour still works.
- After the owner imports the three files: `require(game.ServerStorage._Builders.RemodelInstall).Run()` places the meshes and moves the replaced parts to `ServerStorage.RemodelBackup_27Oct` (`.Undo()` puts them back). Expected: about 10,850 parts -> about 3,000 meshes.

## Step 2 done: remodel installed (27 Oct)
The owner imported props / town / plates (578 meshes, now templates in `ServerStorage.RemodelMeshes`); `RemodelInstall.Run()` placed **1,391 meshes in place of 10,852 parts**: world 27,239 -> 17,235 parts. Replaced parts: `ServerStorage.RemodelBackup_27Oct` (`RemodelInstall.Undo()` puts them back). Before / after screenshots look the same (`remodel_town_before/after.jpg`); Pro Gym plates still turn gold, only the outer plate shows its number (`remodel_pro_rack_plates.jpg`). Known: standing inside a merged object (e.g. a palm) shows nothing from inside (mesh faces are one-sided); not visible in normal play.

| Spot (quality 2, same laptop) | Before FPS avg / worst | After FPS avg / worst | Parts on device |
|---|---|---|---|
| Starter Gym | 15 / 12 | **43 / 25** | 32,176 -> 20,704 |
| Plaza | 15 / 14 | **51 / 29** | 32,318 -> 20,850 |
| Pro Gym (city) | 15 / 12 | **53 / 27** | 31,869 -> 20,569 |
| Powerlifting Gym | 15 / 14 | **45 / 24** | 32,142 -> 20,758 |

SurfaceGuis on: ~1,500 -> ~590 (plate labels). Caveat: "after" was measured in a fresh Studio session (the owner restarted Studio), which also helps a little; render CPU 27-32 ms -> ~16 ms. Still to do: streaming radius, lights (282 on at midday), the Gui memory (~1.4 GB), Graphics Auto/Low/High.
