---
date: 2026-10-14
tags: [gymarc, prompt]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: world signs and the stats overlay (14 Oct)

```text
BUG: a huge "ARM WRESTLING" billboard with the white diamond shows at spawn, right in the player's face.

1. Find every BillboardGui that uses the machine-sign style (name + diamond). The arm wrestling table (and anything else that isn't a lifting machine: posing stage, smoothie bar, NPCs) must NOT use the diamond sign. Give those a small simple label sign instead (name only, final black + gold kit, no diamond).
2. All world signs:
   - AlwaysOnTop = false (no drawing through walls)
   - MaxDistance = 40
   - Size in studs (scale), not offset, so they don't stay huge on screen when you're close.
   - The diamond sign only shows on lifting machines and only when the player is within ~15 studs, and fades out when they sit on it.
3. Check that the arm wrestling table is actually where it should be (not at spawn), and that the "RIVAL" tag is only shown during a match.
4. Spawn in on phone (844x390) and PC, and screenshot the spawn view: no world signs in your face. Then walk to the arm wrestling table and a machine and screenshot those.

Commit, update PROGRESS.md and Obsidian.
```

```text
BUG: the muscle stats overlay (Chest/Shoulders/Back/Core/Arms/Legs with leader lines) points at the wrong places on the body.

1. Every frame (RenderStepped) while it's open, get the real body point with Camera:WorldToViewportPoint and end the line exactly there:
   - Chest: UpperTorso, front-center
   - Shoulders: RightUpperArm top (shoulder joint)
   - Back: UpperTorso, back-center
   - Arms: LeftUpperArm/LeftLowerArm middle (bicep)
   - Core: LowerTorso, front-center
   - Legs: RightUpperLeg middle (quad)
   Use the muscle mesh part if one exists for that group, otherwise the R15 part. Add a small dot at the end of each line.
2. Offset bug: make the ScreenGui IgnoreGuiInset = true (or subtract GuiService.TopbarInset) so WorldToViewportPoint lines up with the GUI. Use WorldToViewportPoint, not WorldToScreenPoint.
3. Labels sit on the same side as their body part (Chest, Shoulders, Arms on one side; Back, Core, Legs on the other), so lines never cross the character or each other. If a point is behind the character from the camera's view (e.g. Back when facing the camera), still point to it but make the line dashed or faded.
4. While the overlay is open, turn the character to face the camera (or move the camera in front), so Chest/Core/Arms are visible.
5. Strength/Stamina at the top must not overlap the top bar. Labels never cover the character's head or other players' name tags.
6. Test on phone 844x390 and PC, standing still and walking. Every line must stay glued to its body part. Screenshot both.

Commit, update PROGRESS.md and Obsidian.
```
