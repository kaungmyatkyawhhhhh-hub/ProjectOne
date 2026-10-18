---
date: 2026-10-13
tags: [gymarc, feature]
status: done
aliases: ["GYM ARC - Bodies and muscles", "GYM ARC - Muscles and bodies"]
---
# GYM ARC - Muscles and Bodies

Back to [[00 GYM ARC Home|GYM ARC Home]].

Everyone wears the same Robloxian 2.0 body, and 18 real muscles grow on it as you train. Your own muscles are live 3D meshes; everyone else wears ready-made "body stage" meshes.

## How it works
- **18 muscles in 6 groups:** Chest (Upper, Mid), Shoulders (Front, Side, Rear Delts), Back (Lats, Traps, Rhomboids, Lower Back), Arms (Biceps, Triceps, Forearms), Legs (Quads, Hamstrings, Glutes, Calves), Core (Abs, Obliques). Each muscle has its own level and EXP.
- **Group numbers:** a group's level is the average of its muscles (used for the Growth Spurt goal); the EXP shown is the muscles added up.
- **One body for all:** players, NPCs, the statue and mirrors all use the Robloxian 2.0 body. Head, face, hair, hats, skin color and animations stay the player's own. Back, front and neck accessories (capes, backpacks, guitars) are removed so they never hide muscles.
- **Shoulder width from genetics:** Narrow 0.9x, Average 1x, Wide 1.05x, V-Taper 1.1x (owner, 19 Oct; was Wide 1.1x, V-Taper 1.2x), tapering back to the waist so it reads as a V.
- **Golden ratio:** legs a bit longer and torso a bit shorter (1 : 1.618) at the same total height.
- **Widths grow with height and muscle:** tall skinny players start with narrow shoulders and hips that widen as they get stronger (shoulders always wider than hips). Owner, 19 Oct: the bodies are narrower at the top end: shoulders 0.4 (skinny) -> 0.85 (full look) -> 1.05 (mass monster), hips 0.2 -> 0.65 -> 1.1 (was shoulders 1.15 / 1.4, hips 0.7 / 1.2). The "shoulders always wider than the hips" rule (ShouldersOverHips 1.1) is still in the code; with these numbers the shoulders stay wider on their own.
- **Your own muscles (muscle v9 "unified"):** the torso and upper arms are each one welded mesh, so any mix of levels (one muscle huge, the rest flat) stays smooth with no holes. 7 live meshes: torso front + back, 2 upper arms, 2 upper legs, the waist. Forearms and calves use static stage meshes. The traps rise from the neck toward the shoulders (added 9 Oct).
- **Other players and NPCs:** a client can only hold 8 live meshes, so everyone else wears static **body stage meshes**: 7 stages per body region (look 0, 0.2 ... 1.0, mass monster), picked from their replicated look values with a 0.3 s cross-fade.
- **The look:** reaching the Growth Spurt goal gives about two thirds of the look; 2x the goal's EXP is the full lean V-taper; 2x to 5x grows on to the "mass monster" (veins come in); past 5x the look stays but stats keep going.
- **Clothing:** muscles wear the character's own classic Shirt/Pants. Default look is shirtless with game shorts. Under the shorts the thighs grow like fabric over muscle (about half the bulge).
- **Skin texture stages:** 5 skin textures tinted to the skin color: Stage1 at level 0, Stage2 about half, Stage3 at the full look, Stage4-5 toward the mass monster (rock-like skin).
- **Performance rule:** every change to a muscle mesh costs about 40 ms, so the look moves in small steps, one body region per frame, and tints fade with a cheap part property instead of rewriting the mesh.

## How the body works now (checked in Studio, 19 Oct)
- **Your own body:** live EditableMeshes, made in your client from `ReplicatedStorage.MuscleData` (muscle v9). Checked on your character in play: UpperTorsoMusclesFront / Back, Left / RightUpperArmMuscles, Left / RightUpperLegMuscles + Layer, LowerTorsoSnatched. Triangles (from the muscle data): torso 39,900 (two halves), upper arms 2 x 13,728, thighs 2 x about 11,200 (quads, hamstrings, glutes and their shorts parts), waist about 160. Forearms and calves are NOT live: they are the static low-poly LimbStages meshes (about 1,800 triangles each, 4 of them). About 97k triangles in all for your own body.
- **Everyone else (other players, NPCs, statue, mirror day-one body):** the static stage meshes in `ReplicatedStorage.BodyStages` (62 templates) and `ReplicatedStorage.LimbStages` (28). Still in use (`Shared/BodyStages`, `Shared/LimbStages`). All 84 torso / arm / thigh / shorts / forearm / calf templates still have your low-poly meshes from 15 Oct (every MeshId matches the "new" column in `Config/StageMeshBackup`); the 6 waist templates still have the old mesh. About 31k triangles per body.
- **Mass monster size of your own muscles (owner, 19 Oct):** `MuscleData.Index monsterG` sets how big each of your live muscle meshes is drawn at the full mass monster. New values: Abs 2.416, Biceps 2.883, Calves 1.675, Forearms 2.55, FrontDelts 1.826, Glutes 2.3, Hamstrings 2.8, LowerBack 2.4, MidChest 1.222, Obliques 2.2, Quads 0.6, RearDelts 1.9, Rhomboids 3.2, SideDelts 0.8, UpperTraps 2.6 (Lats, Traps, Triceps, UpperChest, DeltCap unchanged). Quads 0.6 is below 1, so past 2x the goal the quads shrink back below their full-look size as the rest grows. (SideDelts was 0.8: set to 1.5 on 19 Oct, prompt 7, so the shoulders keep growing.) Old values are in [[GYM ARC - Config values]].
- What does NOT follow the new monsterG: the static mass monster stage meshes (BS_*_gmon, made from the old numbers), the forearm / calf stage meshes, and the look numbers in `Config/Muscles` (Look.MonsterG, unchanged) that the game uses to decide how far along the mass monster you are. So other players see a mass monster made from the old sizes, and you see yours with the new sizes.
- `MuscleData/Index` is a GENERATED file (`tools/gen_muscle_data`): running the generator again would put the old monsterG numbers back. Your numbers are only in the place and in `src/` (committed 19 Oct).
- NPC giants (Dante, Coach Dex): their replicated look values still read the Config/Muscles monster numbers, and they wear the static stage meshes, so the 19 Oct monsterG change does not show on them.

## Where it lives
- `Config/Body` (body ids, proportions, widths), `Config/BodyStages`, `Config/SkinStages`, `Config/LimbStages`, `Config/Muscles`
- `Shared/MuscleRig`, `Shared/MuscleMeshes`, `Shared/BodyStages`, `Shared/LimbStages`, `ReplicatedStorage.MuscleData`
- `MuscleClient` (client), `BodyService` and `AccessoryService` (server)
- Tools: `tools/gen_muscle_data`, `tools/gen_body_stages`, `tools/body_stages_setup`
- Numbers: [[GYM ARC - Config values]]

## Known issues
- At the full look (2x the goal) the body is bulkier than the brief's "lean V-taper" (comes from the muscle data).
- At mass monster size the traps and triceps can grow pointed tips.
- On the rock skin stages a zigzag shows along the upper arm's texture seam; traps outlines are faintly visible from some angles.
- Forearm / calf stages: a slightly darker band where they meet the upper arm / thigh, and their tint has no soft edge.
- Body stage meshes sometimes fail to download in one session; the game shows the nearest stage and retries.
- Not yet tested with 10+ players or real layered (3D) clothing.

## Related
[[GYM ARC - Genetics]], [[GYM ARC - Growth Spurts]], [[GYM ARC - Game Feel]], [[GYM ARC - Progress Mirror]], [[GYM ARC - NPC Regulars and Gym Cat]]

## Screenshots
![[GYM ARC/Screenshots/unified_front_max.png]]
![[GYM ARC/Screenshots/v9_monster_front.png]]
![[GYM ARC/Screenshots/meshes/stage3_front.png]]
![[GYM ARC/Screenshots/skin_gym_max.png]]

## Quad shape (19 Oct, bug fix)
The inner and front quads no longer grow near the shorts: on the bare thigh they grow fully up to 25% of its height, fade out by 60%, and stay flat above that and under the shorts, so the inner teardrop sits low above the knee. The outer sweep keeps its size. Done in `Shared/MuscleMeshes` (`QUADS` settings) for your own live body; the stage meshes for everyone else are fixed copies of your low-poly thighs that still need importing. See [[GYM ARC - Bug - Inner quad bulge]].

## Upper traps slope (19 Oct, bug fix)
The Traps muscle now also lifts the top of the torso as a slope from the neck to the shoulder (`Shared/MuscleMeshes` `UPPER_TRAPS`), so the upper traps show from the front, side and back. Replaced the same day by the wider yoke below. See [[GYM ARC - Bug - Upper traps never grew]].

## Copies of a body (19 Oct)
The progress mirror's "Now" body and the statue are built with the same body widths as the real character (`BodyService.ApplyFrame`, then the proportions). See [[GYM ARC - Bug - Mirror and statue bodies too narrow]].

## Traps yoke and round shoulders (19 Oct, prompt 7)
Target: your reference picture (`Downloads\gym_arc_traps_shoulders_reference.png`): a wide yoke from the neck to the shoulders and big round delt caps, the shoulders the widest point.
- **Traps yoke:** a Traps "shape layer" lifts the whole top of the torso as one smooth slope from the base of the neck (which lifts too) out to the shoulder edge, thick from behind, about half as much on the front. In that top band the data's own Traps growth fades out (at mass monster it stood up as two horns beside the neck); the mid-traps diamond on the back stays.
- **Round delts:** on the top of each upper arm the data's delts fade out and the three delt heads grow as one smooth cap: at the full look the top of the arm becomes a half-ball (an ellipsoid; the box-like arm's corners pull in, the sides swell), wider than the chest. Front, side and rear delts each grow the part facing their way, with their own level. Below the cap the data's delts stay, so the cap flows into the arm.
- **Shape layers:** the yoke and the caps grow with their muscle's level but have their own gentle mass monster size (Traps 1.35, delts 1.6: `MuscleMeshes.ShapeMonsterG`); times the data's big monster sizes they made horns and folded wings. Lighting normals for the reshaped areas are recalculated from the new shape.
- **SideDelts mass monster size:** 1.5 (your 0.8 shrank the side delts at mass monster; 1.5 is the original value).
- **Everyone else (stage meshes): waiting for the import.** 24 fixed low-poly files (torso front / back and both upper arms, look 20% .. mass monster; same triangle counts as now) in `Downloads\gym_arc_meshes_lowpoly_shoulderfix\other_player_stages\`. They also include the upper traps fix, so the earlier `gym_arc_meshes_lowpoly_trapsfix` folder is NOT needed. After the import: `tools/shoulder_fix_stage_setup.luau` + `tools/quad_fix_patch_config.py`.
- Seen, not changed: at mass monster your Rhomboids size (3.2) makes pointed flaps on the shoulder blades.
![[GYM ARC/Screenshots/shoulders/full_front.jpg]]
![[GYM ARC/Screenshots/shoulders/full_back34.jpg]]
![[GYM ARC/Screenshots/shoulders/monster_back.jpg]]
