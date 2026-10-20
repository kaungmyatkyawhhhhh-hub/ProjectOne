---
date: 2026-10-20
tags: [gymarc, prompt]
status: done
---
# 13 Find the body lag

Back to [[00 GYM ARC Home|GYM ARC Home]]

Checked 20 Oct: the new mesh folders (trapsbig, innerfix, backfix) are already low-poly (torso 4,986 tris, leg skin 2,002, shorts 1,348). The meshes in those folders are not what's making the game lag. But Downloads also has an OLD high-poly folder with the same name, Downloads\other_player_stages\ (torso about 20k tris, files about 1.1 MB, from 9 Oct). It may have been imported by mistake.

```text
The game started lagging after the latest body changes. Find the cause and fix it. Follow CLAUDE.md Speed rules.

Facts: the new stage mesh files in Downloads\gym_arc_meshes_lowpoly_trapsbig, _innerfix and _backfix are low-poly (torso 4,986 tris, leg skin 2,002, shorts 1,348, arms about 3,432). There is also an OLD high-poly folder Downloads\other_player_stages\ (torso about 20k tris, about 1.1 MB per file) and Downloads\upper_traps_stages\. Neither one should be in the game.

1) CHECK WHAT'S IMPORTED
- For every MeshPart in ReplicatedStorage.BodyStages / LimbStages, and on players, NPCs, trainers, statue and mirrors: print the name, triangle count (or file size), RenderFidelity, CollisionFidelity, CanCollide, CanQuery, CanTouch and CastShadow.
- If any stage mesh is above the low-poly counts (torso over ~5,500, arm over ~3,800, leg skin over ~2,300, shorts over ~1,500), it came from the wrong folder. List those, and tell me exactly which files from which folder to import instead.
- Look for duplicate meshes: old stage meshes still parented somewhere, or two copies on the same body.

2) CHEAP SETTINGS ON ALL BODY MESHPARTS
- CanCollide, CanTouch and CanQuery false; CollisionFidelity Box; CastShadow false on everything except the torso; DoubleSided off; RenderFidelity Automatic.
- Statue and mirror bodies: Anchored, and never rebuilt every frame.

3) CHECK THE LIVE BODY (your own EditableMeshes, about 97k tris)
- Measure how often the EditableMesh rebuild runs. It must only run when a muscle stat or pose changes, never every frame or every rep. Batch changes so it runs at most once per second.
- Check the new parts (upper traps, adductors, chest, joint fillers): make sure they don't add a new rebuild loop or a second copy of the mesh.
- Phones: if the device is low-end (or FPS stays under 40 for 5 s), use the low-poly stage mesh for your own body when the camera is more than 15 studs away.

4) MEASURE
Use the MicroProfiler or ScriptProfiler. Report FPS and the top 5 costs (scripts + rendering) before and after, on a phone-size emulator with 6 or more bodies on screen.

Short progress note in the vault with the numbers.
```
