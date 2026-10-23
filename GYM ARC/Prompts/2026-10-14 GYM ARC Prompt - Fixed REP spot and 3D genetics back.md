---
date: 2026-10-14
tags: [gymarc, prompt]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: fixed REP spot and the 3D genetics stage back (14 Oct)

```text
Two fixes. Both undo things from my last message.

1. REP button keeps moving between two places (sometimes high and small, sometimes low and big).
   - Remove the "jump button hidden -> move REP" logic completely. REP never changes position or size while playing.
   - One fixed layout, always: REP sits directly above the Roblox jump button with a 12px gap, right edges lined up. PUMP bar sits directly above REP. Same size every time (REP ~150x46 at phone scale, through UIScale only).
   - Work out the position once, from TouchGui.TouchControlFrame.JumpButton's AbsolutePosition/AbsoluteSize. If there's no touch UI (PC), use a fixed bottom-right spot. Only recalculate when the screen size changes, never during a set.
   - Test: sit on 3 different machines, leave, sit again, rotate the phone/resize. REP must be in the exact same spot every time.

2. GENETICS: bring back the OLD 3D genetics stage (the character on the stage with the reveal, like on PC). Delete the new flat Genetics panel (the grid with CHEST B x1.00 etc.).
   - Move the set pieces back from ServerStorage.Unused.GeneticsStage to where they were, and restore the old script from git history.
   - The only problem with the old one was the camera on mobile. Fix only that, by making mobile frame the stage the same as PC:
     - Keep the same camera position/angle as PC.
     - Phones are wider, so adjust FieldOfView from the screen aspect ratio so the character and stage fit exactly like on a 16:9 PC screen (keep the PC horizontal view; on narrow/tall screens widen the vertical FOV so the character's head and feet are never cut off).
     - The stage UI (grades, Reroll, Keep) must sit beside or under the character, never on top of them. Use the final black + gold kit for those buttons.
   - Test at 844x390, 667x375 and 1920x1080, and screenshot all three next to each other in screenshots/genetics_camera/.

Commit, update PROGRESS.md and Obsidian.
```
