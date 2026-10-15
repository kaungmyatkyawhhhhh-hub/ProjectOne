---
date: 2026-10-15
tags: [gymarc, prompt, bug]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt:  Machine HUD phone layout (15 Oct)

```text
BUG: on some phones the machine HUD uses the PC layout (panel stacked at the bottom under REP, AUTO TRAIN cut off at the bottom edge, no space for the jump button). My phone shows the correct phone layout; my friend's phone (same screen size ~2000x920) shows the PC one. His screen has no Roblox jump button visible.

1. Find how the HUD picks "phone" vs "PC" layout. Don't decide it from the jump button existing, from KeyboardEnabled, or from a single check at startup.
2. New rule:
   - Use UserInputService.PreferredInput (Touch / KeyboardAndMouse / Gamepad) if available, otherwise TouchEnabled and not KeyboardEnabled = phone.
   - Listen for changes (PreferredInput / LastInputType changed) and re-layout live, e.g. if a phone player connects a controller or keyboard.
   - Also use screen size: if the short side is under ~500px (after UIScale), always use the compact phone layout, whatever the input.
3. Phone layout must work even if TouchGui/JumpButton doesn't exist or is hidden (seated): use a fixed bottom-right spot as a fallback instead of switching to PC.
4. Every layout must fit on screen: nothing cut off at the bottom (AUTO TRAIN, BEST WEIGHT), respect safe area insets.
5. Add a debug line in the F9 console on join: "HUD layout = phone/pc, reason = ...", so I can ask testers to check.
6. Test: phone emulator with touch only, phone + keyboard, phone with jump button hidden, tablet, PC. Screenshot each. Commit.
```
