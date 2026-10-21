---
date: 2026-10-21
tags: [gymarc, handoff]
---
# GYM ARC Handoff (21 Oct)
Back to [[00 GYM ARC Home|GYM ARC Home]] - details: [[2026-10-21 GYM ARC Audit follow-ups]]
- **Fully done (21 Oct):** 25, 26 (later cancelled), 11, 34 (+ ripped clothes, portrait export), audit of all prompts, lift screams (Monetization task 3), NPC-on-machine test, Performance part 2 leftovers, Town music, 9 (fuller chest), 15 (traps/back: imported with the chestfix set), 29 (trainer follower lag), 32 (old starter gym restored: [[2026-10-21 GYM ARC Old starter gym restored]]), 28 + 28b (UI cleanup, boosts like tools: [[2026-10-21 GYM ARC UI cleanup]]), 38 + 38b (alter textures, bronze Tanned / Peak, head color follows the alter: [[2026-10-21 GYM ARC Alter textures fix]]; hotbar hides on machines), 12 (developer product offers + shop analytics; SKIP TUTORIAL after 5 s: [[2026-10-22 GYM ARC Developer product sales]]), 27 trimmed (Agency grid + reveal + one PT desk: [[2026-10-22 GYM ARC Trainer Agency redesign]]). 30: skipped (owner: already in the game).
- **In progress:** none. Studio is saved state = git (branch claude/eloquent-darwin-b4srob, last code commit for 39).
- **Remaining order (owner, 21 Oct):** done up to 27 -> STOP now so the owner can publish and test. Since then (22 Oct, owner's requests): GO TO teleport + quiet tutorial, Agency odds fixes, grunts, prompt 39 unlock guides ([[2026-10-22 GYM ARC Unlock guides]]).
- **After that:** 31, 33, 22 (banner + ALTER button first; full VFX / sound later), 35 (needs the owner to import gym_arc_gear_meshes/sneaker.glb as .glb, Merge Meshes off).
- **Prompt 36** (Pro Gym expansion: the pro gym's reason to unlock, owner 21 Oct): do it when it comes up in the order. **Prompt 37: do NOT run** until the owner has approved the mockups and updated it.
- **Owner still to decide / do:** the owner's own Face accessory can't be tinted with an alter (normal heads can). Shake Bundle's Roblox description (+20% EXP 5 min) doesn't match the game (full stamina, +50% gains 30 s). treadmill sound ids (licensed library has no clean loop); real-phone + 10-player FPS checks; players' own avatar shirts still tear on others' screens (fix = re-export stage meshes with clean texture seams); trainer outfits are solid colors (no trims) - OK?
- **Starter gym backups:** ServerStorage.StarterGymBackup: Before (= live now), LayoutV2 (prompt 26 layout), ProCopies (prompt 16 pro copies), Removed. All untagged.
- **Bugs / notes:** Studio's screen capture doesn't draw AlwaysOnTop billboards (EXP popups never show in screenshots, they do in game). TestMachine Studio attribute raises growthSpurts to 2 on the test save (avoid). Treadmill sound slots empty.
- **Push pattern:** python -m http.server 34999 in the repo, execute_luau GetAsync + ScriptEditorService:UpdateSourceAsync, then kill python (match 34999/recv in the command line).
