# Prompt: make City Legends a million times better: run all the open prompts, in order

_For Claude Code with Roblox Studio connected (MCP) and Blender. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras: each prompt below says exactly what to do._

## How to work
- Before each step, pull from git and read the prompt file. Check `City Legends/City Legends.md` to see whether that step (or part of it) is **already done**. If it's fully done, skip it and say so.
- Do **one step at a time**. After each step:
  - play-test (2 players, PC + phone size);
  - no console errors;
  - Lune tests and `luau-lsp analyze` clean;
  - FPS no worse;
  - save the place, commit and push;
  - note it in `City Legends/City Legends.md`;
  - tell the owner in a few lines, with screenshots.
- **Ask the owner** when a prompt says to ask (questions, prices, names, sound IDs, models). While waiting for an answer, go on to the next step that doesn't depend on it.
- If the usage limit hits, stop cleanly after saving and pushing; next time start at the first unfinished step.

## The order (bugs and feel first, then content, then launch)
**A. Fix what players notice right away**
1. `Fix buildings flashing black and white.md`
2. `Smooth roads.md` (all 4 lanes, sidewalks and kerbs tested)
3. `Speedometer style setting (digital or analogue).md` (with the fixes: no black background, move "Get out")

**B. Driving feel**
4. `Realistic car physics.md` (weight, grip, tyre smoke and marks)
5. `Camera and car movement like the video.md` (including the realistic wind blur)

**C. Cars**
6. `Car class grades and car levels.md` (includes `Remove 10 starter and mid cars.md` and `More fun starter cars.md`; ask its questions first)
7. `Better car models and clean interiors.md` (the pipeline: PBR, interiors, own clusters, doors, checklist)
8. `Six Bugatti imports.md`
9. `Dealership with trims like Midnight Racing.md` (the buy menu, updated for the classes)

**D. The world and venues**
10. `Make the Monaco map look real (from the drive video).md`
11. `Realistic graphics, lighting and buildings.md`
12. `Fix buildings that look off.md`
13. `Remodel the venues.md` (Legends Motors first; `Dealership model 86483010946222.md` for its look)
14. `Replace the casino with a rewards centre.md`

**E. Houses**
15. `Housing like Driving Empire.md` (with `Houses - buy at showroom, place on a lot.md` and `Realistic houses.md` where they still apply; `House model 9112441127.md` as one of the designs)

**F. Menus and launch**
16. `Main menu (tile style).md` (check what's already built)
17. `Make the game a million times better (master plan).md`: the audit, the first 3 minutes, retention, playing with friends, launch prep, then weekly updates.

Older prompts (`Neon at night...`, `New map shaped like Monaco.md`, `One big island...`, `Playtest and bake map.md`, `Research 10 driving games.md`) are already done or replaced by the ones above: only use them as background.

## When each step is done, tell the owner (short)
- which step is done;
- screenshots;
- what's next;
- anything you need from the owner.
