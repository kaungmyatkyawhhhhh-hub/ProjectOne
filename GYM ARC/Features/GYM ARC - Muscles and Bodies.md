---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Muscles and Bodies

Back to [[00 GYM ARC Home|GYM ARC Home]].

Everyone wears the same Robloxian 2.0 body, and 18 real muscles grow on it as you train. Your own muscles are live 3D meshes; everyone else wears ready-made "body stage" meshes.

## How it works
- **18 muscles in 6 groups:** Chest (Upper, Mid), Shoulders (Front, Side, Rear Delts), Back (Lats, Traps, Rhomboids, Lower Back), Arms (Biceps, Triceps, Forearms), Legs (Quads, Hamstrings, Glutes, Calves), Core (Abs, Obliques). Each muscle has its own level and EXP.
- **Group numbers:** a group's level is the average of its muscles (used for the Growth Spurt goal); the EXP shown is the muscles added up.
- **One body for all:** players, NPCs, the statue and mirrors all use the Robloxian 2.0 body. Head, face, hair, hats, skin color and animations stay the player's own. Back, front and neck accessories (capes, backpacks, guitars) are removed so they never hide muscles.
- **Shoulder width from genetics:** Narrow 0.9x, Average 1x, Wide 1.1x, V-Taper 1.2x, tapering back to the waist so it reads as a V.
- **Golden ratio:** legs a bit longer and torso a bit shorter (1 : 1.618) at the same total height.
- **Widths grow with height and muscle:** tall skinny players start with narrow shoulders and hips that widen as they get stronger (shoulders always wider than hips).
- **Your own muscles (muscle v9 "unified"):** the torso and upper arms are each one welded mesh, so any mix of levels (one muscle huge, the rest flat) stays smooth with no holes. 7 live meshes: torso front + back, 2 upper arms, 2 upper legs, the waist. Forearms and calves use static stage meshes. The traps rise from the neck toward the shoulders (added 9 Oct).
- **Other players and NPCs:** a client can only hold 8 live meshes, so everyone else wears static **body stage meshes**: 7 stages per body region (look 0, 0.2 ... 1.0, mass monster), picked from their replicated look values with a 0.3 s cross-fade.
- **The look:** reaching the Growth Spurt goal gives about two thirds of the look; 2x the goal's EXP is the full lean V-taper; 2x to 5x grows on to the "mass monster" (veins come in); past 5x the look stays but stats keep going.
- **Clothing:** muscles wear the character's own classic Shirt/Pants. Default look is shirtless with game shorts. Under the shorts the thighs grow like fabric over muscle (about half the bulge).
- **Skin texture stages:** 5 skin textures tinted to the skin color: Stage1 at level 0, Stage2 about half, Stage3 at the full look, Stage4-5 toward the mass monster (rock-like skin).
- **Performance rule:** every change to a muscle mesh costs about 40 ms, so the look moves in small steps, one body region per frame, and tints fade with a cheap part property instead of rewriting the mesh.

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
