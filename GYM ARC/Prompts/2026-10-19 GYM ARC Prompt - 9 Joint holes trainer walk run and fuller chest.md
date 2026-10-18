---
date: 2026-10-19
tags: [gymarc, prompt]
status: todo
---
# 9 Joint holes and trainer walk/run

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Two fixes. Follow CLAUDE.md Speed rules (max 2 screenshots, one playtest, export only changed scripts, short note).

1) SEE-THROUGH HOLES AT ELBOWS AND KNEES
Owner screenshots: when a big body bends its arms or legs (some exercise poses), you can see right through the body at the elbow and the knee. The upper and lower arm meshes (and the thigh and calf meshes) are open at the joint, so a gap opens when the joint bends. You see empty space and the back faces get culled.
Fix on BOTH bodies: your own live EditableMesh body AND the static stage meshes (BodyStages / LimbStages, used by other players, NPCs, statue, mirrors).
- Add a skin-colored joint filler at each elbow and knee: a low-poly sphere (max ~200 tris) or a closed cap, centered on the joint. Weld it to the upper limb part so it follows the pose. Size it from that limb's current girth, so it grows with the muscle (it must fill the gap at g000 AND gmon without poking out when the arm is straight).
- If the limb mesh ends are open rings, also close them with a cap (fan triangles to the ring center), so you never see inside.
- Match the skin color/material, same as the existing skin (including tan/skin tone changes).
- Test at gmon size: full curl, bench press bottom, squat bottom, and sitting. No holes from any camera angle, and nothing sticks out when the arm or leg is straight.
- Keep it cheap: no extra rebuild of the 97k-tri live meshes, just resize the filler when muscle stats change.

2) TRAINERS NEED WALK AND RUN ANIMATIONS
Trainers currently slide around without leg movement.
- First check how trainers move (Humanoid:MoveTo, TweenService, or CFrame). If they don't use Humanoid movement, the default Animate script won't see their speed, so compute speed yourself from position change per frame.
- Use their Animator: idle when speed < 0.5, walk when below ~12 studs/s, run above that. Crossfade over 0.2 s. Scale the walk/run playback speed to match their actual move speed so the feet don't skate.
- Use Roblox's standard R15 walk and run animations (or whatever the player rig uses), so it matches the players. Make sure it works on their custom rig (Motor6D names must match R15).
- Keep their existing idle and the "look at player within 15 studs" behavior. Only look at the player while standing, not while walking or running.
- Animations should only run on the client, and only for trainers within streaming/culling range.

Write a short progress note in the vault when done.
```
