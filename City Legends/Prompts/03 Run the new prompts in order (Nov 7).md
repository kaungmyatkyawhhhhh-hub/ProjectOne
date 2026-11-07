# Prompt: run all the new prompts (Nov 6–7), in order

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras: each prompt below says exactly what to do._

## How to work
- **The owner leaves the PC on and can't reply. You have all permission** to finish every step **and to import** models into Studio yourself (owner, 2026-11-06). Don't stop to ask: when a choice is needed, pick what fits the owner's rules, write the choice and why in `City Legends/City Legends.md`, and carry on. Keep choices easy to undo (Config values, dated backups in `ServerStorage`).
- Before each step: pull from git, read the prompt file, and check the notes to see whether it's **already done** (skip what's done after a quick check, and say so).
- **One step at a time.** After each step:
  - play-test (PC and phone size 667 × 375), day and night;
  - no console errors; Lune tests and `luau-lsp analyze` clean; FPS not worse;
  - save the place, commit and push;
  - write what you did in `City Legends/City Legends.md`, with screenshots.
- If Studio shows "… is not responding" for a built-in panel (Toolbox, Footer), wait; save often; restart Studio if it keeps freezing, then carry on.
- If the usage limit hits: finish the current change cleanly, save, push, and write **"Next: step N"** at the top of the notes.

## The order (new models first, then the systems that use them)
1. `Rename car models (fake model names).md`: check it's done (the names in `Cars.lua` look done); finish anything missing (Ironclad brand, the ZV / ZVX / VTZ side lettering, old model words in the UI).
2. `New imports - LFA, Maybachs, Countach.md`: the LFA, LFA Circuit (new), S-Class Maybach, Maybach GLS, Countach 5000 QV, with the owner's cluster photos; import them yourself.
3. `One Urus and only two 458s.md`.
4. `Better upgrade area and part shop.md`: Part 1 (the workshop, Part Shop, 68 parts, 43 engine swaps, at real prices × 2.5) and Part 2 (the starter cars: 350Z, 330i, Ford Focus RS; the Focus model is in `imports/importing cars/`).
5. `Real car prices and harder cash.md`: real dealer / used / collector prices and the fairer economy (after step 4, so the parts' prices are checked together).
6. `Lighting and car look like the Ghost Driver videos.md` (car changes on new models only).
7. `Small design changes on famous new cars.md` (vents, sides, tail lights, our own wheels; **headlights skipped**; new models only).
8. `Proper working headlights.md` (headlights, tail / brake / reverse lights and indicators in their proper place; new models only).

Not now: `812 body kit (use after importing the 812).md` (no 812 model yet).

## At the end
At the **top** of `City Legends/City Legends.md`, a short summary for the owner:
- what was done (step by step) and what's left ("Next: step N");
- what the owner needs to do (models, sound IDs, licence decisions, Robux prices);
- the choices made and how to undo them;
- before / after FPS.
