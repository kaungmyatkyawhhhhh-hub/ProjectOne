---
date: 2026-10-15
tags: [gymarc, prompt, performance]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: low-poly body stage meshes (15 Oct)

```text
LOW-POLY BODY STAGE MESHES: I already imported all of them myself in Studio (the 91 files from Downloads\gym_arc_meshes_lowpoly\, same names as the originals: BS_Torso_Front/Back, BS_Left/RightArm_Arm, BS_Left/RightLeg_Skin, BS_Left/RightLeg_Shorts, BS_UpperTraps, and Left/Right Forearms/Calves, 7 stages each). Don't ask me to import again.

1. Find the newly imported meshes (search the place and the asset manager / search_asset by exact name). Get each one's new MeshId.
2. Point every stage template in ReplicatedStorage.BodyStages and LimbStages (and the upper traps stages) to the new MeshIds (run tools/body_stages_setup or update the config). Save the old MeshIds in a backup table in Config so we can roll back.
3. Delete any stray imported copies left in Workspace after you've got the IDs.
4. Don't touch my own character's live muscle meshes (MuscleClient / muscle v9). BS_Waist stays the old one.
5. Keep CollisionFidelity Box, same sizes and offsets.
6. Check an NPC/other player at every stage (g000 to gmon), front and back, close up: no gaps at the seams, skin texture and shorts look the same. Screenshot before/after.
7. Measure again at the starter gym, same view as the 14 Oct lag check: triangles, draw calls, FPS. Put the numbers in PROGRESS.md and the Obsidian Performance note.
Commit.
```

Message sent while this was running:

```text
everyones clothes disappear when i look through the glass
```
