---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# Coach Dex portrait muscles + dialog wrap

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Coach Dex dialog portrait: sometimes his muscles don't show (plain blocky body, see owner screenshot). Find why (likely the portrait clones Coach Dex while he's culled/LOD'd far away or before his muscle meshes have streamed in) and fix it so it ALWAYS shows the full muscled Coach Dex:
- Build the portrait from a dedicated copy of Coach Dex kept in ReplicatedStorage (never from the live NPC in the world), with his muscle stage meshes, at his full size.
- Preload its meshes and textures on join (ContentProvider:PreloadAsync) before the first dialog can show; if it's not loaded yet, wait (max 1 s) instead of showing the blank body.
- Same check for the trainer portraits/ViewportFrames anywhere (reveal, My Trainers) and the unlock-guide dialogs.
Also: the dialog line is cut off ("The POWERLIFTIN..."). The text must wrap onto the next line and the box grows to fit (prompt 53a dialog rules); never cut words.
TEST: open the dialog 10 times from far away and right after joining on a phone; screenshot that the muscles show every time. Short note in the vault.
```
