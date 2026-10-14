---
date: 2026-10-14
tags: [gymarc, prompt, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Stats overlay, no turning (14 Oct)

```text
STATS OVERLAY: remove the part where the character turns to face the camera when Stats opens.
- Opening/closing Stats must not rotate the character, change its CFrame, or move/lock the camera. The player keeps facing wherever they were, and can still look around freely.
- The leader lines still follow the body parts every frame from whatever angle the camera is at. Body parts on the far side of the character (e.g. Chest when you're looking at their back) get a dashed/faded line instead of a solid one.
- Make sure nothing else from that change is left over (no AutoRotate toggling, no Humanoid facing code, no camera CFrame tweens).
Test: open Stats from the front, back and side, while standing and walking. The character never turns by itself. Commit.
```
