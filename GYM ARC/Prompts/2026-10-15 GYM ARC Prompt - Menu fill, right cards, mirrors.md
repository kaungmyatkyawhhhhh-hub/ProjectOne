---
date: 2026-10-15
tags: [gymarc, prompt, bug]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: menu fill, right cards under the top bar, mirrors (15 Oct)

```text
THREE FIXES.

1. MAIN MENU / LOADING SCREEN don't always fill the screen (a gap on the right shows the game world behind it).
   - The ScreenGui must have IgnoreGuiInset = true and ScreenInsets = None for the background, and the background frame + image must be Size UDim2.fromScale(1,1), Position (0,0). Never a fixed pixel size or a size calculated once at startup.
   - If anything is sized from the screen, recalculate on Camera:GetPropertyChangedSignal("ViewportSize") (phones change size after joining and when rotating).
   - Background image ScaleType Crop so it always covers the whole screen (no black/gap bars), character stays visible on the right.
   - The GYM ARC logo is hidden under Roblox's top-left buttons: keep the logo and buttons inside the safe area (start below GuiService.TopbarInset.Max.Y + 8, and right of the Roblox buttons).
   - Test: join 10 times on a phone and rotate; it must always cover the whole screen.

2. RIGHT-SIDE CARDS (Drink Shake, Today's Quest, collapse tab) overlap the top bar's Daily / Quests / Settings buttons.
   - The whole right-side container starts below the top bar: top = GuiService.TopbarInset.Max.Y + 8 (update when TopbarInset changes). Nothing on the right may ever overlap the top bar.
   - The collapse tab moves with the container.
   - Also: a "MAX GROWTH SPURT REACHED - 7'0"" card is showing again. Remove it from the HUD (we removed it before); max height is shown in the top bar / Stats only.

3. MIRRORS: remove the reflections.
   - Delete the mirror reflection system (ViewportFrame/cloned characters/update loop) completely. Mirrors become plain glass: a light grey-blue SmoothPlastic or Glass part with a little Reflectance (0.1-0.2) and a subtle frame. No scripts.
   - Keep the Progress Mirror feature working only if it doesn't depend on the reflection (otherwise tell me first).
   - This also saves performance; measure FPS near the mirrors before/after.

Test on phone 844x390 and PC, screenshot all three. Commit, update PROGRESS.md and Obsidian.
```
