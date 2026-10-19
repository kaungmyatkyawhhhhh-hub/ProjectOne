---
date: 2026-10-19
tags: [gymarc, prompt]
status: done
---
# 10 Fix flex poses

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Fix the 4 flex poses so they look like real bodybuilding poses. Owner reference photos are in:
C:\Users\kaung\Downloads\gym_arc_pose_refs\
  pose_1_side_chest.png
  pose_2_front_double_biceps.png
  pose_3_back_double_biceps.png
  pose_4_abs_and_thighs.png
Use them ONLY for the body position. Don't copy faces, logos, text or clothing. Kids' game: keep it clean.
Follow CLAUDE.md Speed rules (max 2 screenshots per pose check, one playtest, export only changed scripts, short note).

First find where the poses are defined (grep "Pose", "Flex", "SideChest", "DoubleBicep"), and whether they are KeyframeSequences, CFrame tables on Motor6Ds, or uploaded animations. Edit them in the same system. If they are uploaded animation IDs, rebuild them as Motor6D CFrame poses in code, so no upload is needed.

POSE 1 - SIDE CHEST
- Body turned about 70 degrees so the side faces the camera, torso twisted back toward the camera so the chest shows.
- Front leg (closest to camera): knee bent, pushed in toward the back leg, heel up on the ball of the foot (calf flexed). Back leg straight, foot flat.
- Front arm: elbow bent about 90 degrees, forearm flat across the stomach, fist closed.
- Back arm: reaches across the front and grabs the front arm's wrist.
- Chest pushed up and out, shoulders back, front shoulder slightly down. Head turned to the camera.

POSE 2 - FRONT DOUBLE BICEPS
- Facing front, feet a bit wider than shoulders, toes slightly out, knees almost straight (quads flexed).
- Both upper arms raised out to the sides, just above shoulder height. Elbows bent about 80-90 degrees, fists up at about head height, wrists curled in toward the head.
- Elbows pulled slightly back, lats spread wide (waist looks small), chest up, head straight.

POSE 3 - BACK DOUBLE BICEPS
- Back to the camera. Same arm position as pose 2.
- One leg slightly back, heel raised on the toes (calf flexed); the other leg straight.
- Slight back arch, shoulder blades spread, head looking forward (away from the camera).

POSE 4 - ABS AND THIGHS
- Facing front, both hands behind the head, elbows out to the sides and slightly forward.
- One leg forward, knee straight, foot flat (quad flexed). The other leg straight under the body.
- Small forward crunch of the upper body (abs flexed), chin slightly down.

RULES FOR ALL POSES
- Smooth 0.3 s blend into and out of each pose, then hold. Add a tiny breathing sway while holding so it's not frozen.
- Must work at every body size, g000 to gmon. Big arms and traps must not clip into the head, chest or each other: scale arm raise and elbow spread with body size (wider at gmon). Check the elbow/knee joint fillers from prompt 9 cover the bends.
- Both feet stay on the ground (no floating or sinking). Recompute hip height for big bodies.
- Mirrors, the statue and other players' views must show the same pose.
- Test all 4 at g000 and gmon. Screenshot from the front for poses 1, 2 and 4, and from the back for pose 3. Compare with the reference photos.

Write a short progress note in the vault when done.
```
