---
date: 2026-10-19
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-19 GYM ARC Owner changes

The owner changed things in Studio by hand. Claude compared the place with the last commit (15 Oct) and wrote everything down. Nothing the owner made was changed or "fixed". Prompt: [[2026-10-19 GYM ARC Prompt - 1 Document owner changes]].

## How it was checked
- Every script exported from Studio into `src/` (440 scripts, same list as before: none added, none deleted) and compared with the 15 Oct commit.
- The stage mesh templates (`ReplicatedStorage.BodyStages` 62, `LimbStages` 28) compared with `Config/StageMeshBackup`.
- The place's folders, NPCs and your character in a running play test looked at (read only).
- Limit: there is no saved copy of the place from 15 Oct (the newest backup in `Documents\GymArc_backups` is 8 Oct), so models and parts can only be checked against what the notes say, not part by part. Nothing new or missing was found in ReplicatedStorage, ServerStorage, StarterPlayer, StarterGui, Lighting or the Workspace's top level.

## What changed (owner)
1. **Mass monster size of your own muscles** (`ReplicatedStorage.MuscleData.Index`, `monsterG`): new sizes per muscle, for example Rhomboids 1.7 -> 3.2, Biceps 2.083 -> 2.883, Quads 2.132 -> 0.6, SideDelts 1.5 -> 0.8. Full list in [[GYM ARC - Config values]] and [[GYM ARC - Muscles and Bodies]].
2. **Narrower bodies at the top end** (`Config/Body.Widths`): full look shoulders 1.15 -> 0.85, hips 0.7 -> 0.65; mass monster shoulders 1.4 -> 1.05, hips 1.2 -> 1.1.
3. **Narrower genetics frames** (`Config/Genetics.Frames`): Wide shoulders 1.1x -> 1.05x, V-Taper 1.2x -> 1.1x ([[GYM ARC - Genetics]]).
4. **Rival titles one rarity higher** (`Config/Titles`): Beat Benny Rare, Beat Coral Epic, Beat Dante Legendary ([[GYM ARC - Titles]]).
5. **Music** (`Config/Sounds`): three songs per area again (Starter, Pro, Beach), five new track ids, one more in the fallback list ([[GYM ARC - Music and Sounds]]).
6. **CLAUDE.md** (repo): replaced by a short version; the old one is `docs/CLAUDE_full_old.md`. New rules include "never undo the owner's Studio changes" and "grunts / screams ARE allowed" (the design brief still says no grunts). It mentions `docs/PROGRESS_archive.md`, which does not exist yet.

## What did NOT change
- No UI script, Theme, Kit or UI config ([[GYM ARC - UI System]]).
- The body system itself: your own body is still live EditableMeshes (muscle v9), everyone else still wears the static BodyStages / LimbStages meshes. All 84 low-poly stage meshes from 15 Oct are still in place; the waist keeps the old mesh. About 97k triangles for your own body, about 31k for everyone else's.
- The looks system: the Wardrobe is still off; gear, top / shorts color and auras work as before ([[GYM ARC - Wardrobe and Gear and Fits Store]]).
- MuscleRig, BodyStages, LimbStages, BodyService, GymGoerService code.

## Also saved to git (not the owner's)
- The Top crews member view from 15 Oct (`CrewService`, `CrewClient`) was in Studio but never committed ([[GYM ARC - Crews]]).

## Side effects worth knowing (not fixed, owner decides)
- The new monsterG only changes YOUR live muscle meshes. Other players, NPCs, Dante and Coach Dex wear the mass monster stage meshes made from the old sizes, so your mass monster looks different on your screen than on other people's.
- Quads 0.6 and SideDelts 0.8 are below 1: past 2x the goal those muscles shrink back below their full-look size.
- `MuscleData/Index` is a generated file: running `tools/gen_muscle_data` again would bring back the old monsterG numbers.
- The design brief (`docs/DESIGN.md`) still lists the old shoulder numbers (frames 1.1x / 1.2x, widths 1.15 / 1.4).

## Older tasks vs these changes
- Low-poly body stage meshes: done 15 Oct and still in place. Conflict: the mass monster stages were made from the old sizes, so they no longer match your new monsterG.
- AuraVFX v3: no conflict. It sits on whatever body parts are there and rebuilds when they change.
- Titles -> Inventory: no conflict. The new rarities show there by themselves.
- Coach Dex body: small conflict. He and Dante are built with the mass monster widths and the V-Taper frame, so your changes make both of them about 20% narrower across the shoulders than when they were set up (Dante 2.88 -> 2.26, Coach Dex 2.67 -> 2.11); their muscles are the old-size stage meshes.
- Physique / Stats overlay lines: no conflict. The dots are placed from the real body part sizes, so they follow the narrower bodies.

## To do for the owner
- File > Save to Roblox, then File > Download a Copy to `Documents\GymArc_backups\GymArc_2026-10-19.rbxl`.

## Prompt queue for today (not started)
[[2026-10-19 GYM ARC Prompt - 2 Inner quad bulge]], [[2026-10-19 GYM ARC Prompt - 3 Mirror statue width and duplicate crew tags]], [[2026-10-19 GYM ARC Prompt - 4 Upper traps missing]], [[2026-10-19 GYM ARC Prompt - 5 Top crews member view]]. Prompt 5 was mostly built on 15 Oct (see [[GYM ARC - Crews]]); its phone / PC test and screenshot are still missing.

## Graphify code map (prompt 6)
Prompt: [[2026-10-19 GYM ARC Prompt - 6 Install Graphify]].
- Checked first: open source (GitHub Graphify-Labs/graphify, Apache-2.0 / MIT), code is read on this PC (tree-sitter), no telemetry, no API key for code. `.luau` counts as code, so nothing is sent anywhere. Built with `--code-only` and `GRAPHIFY_BACKEND=none` to be sure.
- Installed: uv (with pip), then `uv tool install graphifyy` (0.9.92).
- Graph of `src/` only, in `src/graphify-out/` (the generated `MuscleData` folder is left out by `.graphifyignore`): 172 scripts, about 1,760 nodes, 4,048 links, about 110 groups; graph.json 1.8 MB. Full build 6.5 s, update 5.3 s, a question about 1 s.
- Limits: 34 scripts only partly read (the Lua reader doesn't know Luau type notes), and handlers written as `actions.Create = function` don't show up as their own entries.
- Test "where is the crew tag checked?": the graph pointed to the right file (CrewService) but not the right spot (`actions.Create`, line 289); its first hit was a wrong `tag()` in RivalClient. A targeted search found it in one step. Useful as a map, not better than a search for exact lines.
- Not done: `graphify install --project` (Claude Code's safety check blocks Claude from writing its own skill / hooks; the owner can run it), and `graphify hook install` (it would rebuild from the repo root instead of `src/`). CLAUDE.md has the two new lines.
