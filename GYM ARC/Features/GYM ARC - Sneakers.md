---
tags: [gymarc, feature]
status: removed (23 Oct, owner)
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Sneakers

> **Removed 23 Oct (owner: they look bad).** [[2026-10-23 GYM ARC Prompt - 35b Remove sneakers|Prompt 35b]], [[2026-10-23 GYM ARC Sneakers removed|progress]]. Nobody wears them now: feet are back to how they were before prompt 35 (block feet visible; Duke, Volta and The Shadow have their old black block shoes again; coaches 1-4 their shoe images). Players' own Roblox shoes still show. The code is gone from `Shared/Gear`, `Config/Trainers` and the services. The mesh is kept in `ServerStorage.SneakerBackup.Sneaker` (not loaded by anything). To bring them back: revert commit d9fccdd in the game repo and move the model back to `ReplicatedStorage.GearMeshes`.
>
> **23 Oct, prompt 35c:** no shoes at all now. Duke, Volta and The Shadow's block shoes, the coaches' shoe pictures and the dark feet of Dante, Coach Dex and the posing show NPCs are gone: everyone's feet are bare, in their skin colour. Players' own Roblox shoes still show.
>
> Everything below is how it worked (history).

Built 22 Oct ([[2026-10-21 GYM ARC Prompt - 35 Sneakers|prompt 35]]). Every trainer, NPC and player wears sneakers instead of the plain black block feet.

## How it works
- A gear kind in `Shared/Gear` ("Sneakers"), like the belts and wraps: one copy welded to each foot, so it moves with every walk, run and pose.
- **Size:** the length (and height) from the foot, or from the calf when the calf is big (the muscle stage meshes): a mass monster gets a big shoe, never smaller than the foot. The width follows the foot. Re-fitted on each client about twice a second (`GearClient`), like the other gear.
- **Placed:** the sole on the foot's bottom, toe forward (the heel tab tells which end is the heel, so the import's facing doesn't matter). The block foot under it is hidden.
- **Colors** (`Config/Trainers` gear lists): Coach Sam red, Coach Nia green, Coach Lou yellow, Coach Rex purple (white stripes); Duke black + gold; Volta black + red; The Shadow black + purple (dark sole); Atlas white + gold. Gym NPCs: black with a stripe in one of six colors (Coach Dex red). Players: black + white; a player wearing their own Roblox shoes keeps theirs.
- Nothing on the shoe collides, is touched, is hit by rays or casts a shadow.

## The real sneaker (imported by the owner, 22 Oct)
Done: `GearMeshes.Sneaker` is the planner's mesh now (flattened into one model of named pieces). The old steps, for a re-import:
There's no way for Claude to import a mesh file into Studio (no tool, and a live mesh would use the last of the 8 live-mesh slots the muscles need). So the shoe in the game right now is a **stand-in made of plain parts** (`ReplicatedStorage.GearMeshes.Sneaker`, attribute StandIn).
To swap in the planner's mesh (about 2 minutes):
1. Delete `ReplicatedStorage.GearMeshes.Sneaker` (the stand-in).
2. File > Import 3D > `Downloads\gym_arc_gear_meshes\sneaker.glb`, Import.
3. Put the imported model in `ReplicatedStorage.GearMeshes`, name it **Sneaker**. Keep the part names (Shoe_Upper, Shoe_Midsole, Shoe_Lace, Shoe_Lace.001 ...). One model holding the MeshParts (move them out of the import's inner models if there are any, like the belt and wraps).
4. Play: every foot uses the new mesh, no code change.
If the old block shoes ever come back: the Sneaker model is missing or misnamed.

## Where it lives
`Shared/Gear` (kind, fit "foot"), `Config/Trainers` (colors), `TrainerService` (old block shoes only without the model), `GymGoerService` + `NpcService` (NPCs), `CosmeticService` (players).
