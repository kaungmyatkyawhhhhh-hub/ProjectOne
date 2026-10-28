---
date: 2026-10-28
tags: [mowarc, prompt]
status: todo
---
# 1 Setup, field and upgrades

Back to [[00 MOW ARC Home|MOW ARC Home]]

```text
NEW GAME: MOW ARC (a Roblox incremental: mow grass, upgrade, prestige). SPEED ARC is ARCHIVED: don't change it or publish it.
READ (only these): "MOW ARC\MOW ARC - Quick Rules.md" fully; "MOW ARC - Game Design.md" sections 1-4, 10 and 11. Copy the Quick Rules into MOW ARC's CLAUDE.md (plus the Studio rule: two or three Studios may be open, call list_roblox_studios and only work in the one named "MOW ARC"; never touch GYM ARC placeId 80031260599632 or SPEED ARC placeId 134701616695802).

0) UI KIT FIRST (rule 11 in the Quick Rules; owner: GYM ARC and SPEED ARC UIs looked like placeholders)
- Do NOT copy SPEED ARC's UIKit look; only reuse its code structure (window manager, toasts, button press handler).
- Make the kit as art: 9-slice PNG sprites for buttons (green / blue / yellow / red / grey, normal + pressed), panels, tabs, cards, pills, badges, the currency counter frame, plus icons (grass, seeds, suns, mower, upgrade arrow, close X, settings, store, daily, quests). Chunky, glossy, 3D lip, inner highlight, soft shadow, thick navy outline, bold font with a navy stroke.
- Render a MOCKUP at 667x375: the HUD (grass counter, grass/s, goal line, left menu buttons) + the UPGRADES window with 3 cards + the button set. Put it in MOW ARC\Screenshots\ui_kit\ and STOP: show it to me and wait for my OK before building any screen.
- List every image before uploading, I approve, upload to the GROUP.

1) SETUP
- Ask me to create a new place "MOW ARC" in the group and open it (tell me exactly what to click).
- Code in Games\MowArc\src with the same sync tool as SPEED ARC. Copy + adapt from SPEED ARC (READ only): PlayerData, UIKit code structure only (the look comes from step 0), sound system, loading screen, Settings. Config folder for every number.
- A BigNum module (safe save/load, add/multiply/compare, format with K M B T Qa Qi Sx Sp Oc No Dc...), with unit tests.

2) THE FIELD (design section 3)
- World 1 Backyard: big open field, fence, house back wall, shed, trees at the edges, sprinkler, gnome. Blender meshes per the modelling rule (.fbx to Downloads\mow_arc_models\ for me to import).
- Client-drawn grass grid (start ~40 x 40 cells, Config), each player sees their own grass. Cut = cell drops, clippings burst (pooled), "+X" popup, pop sound with pitch variation. Cells regrow after a few seconds (batched updates).
- The player drives a chunky cartoon MOWER (Blender mesh, attached in front of the character, push-mower walk animation). Mower radius shown as a soft ring on the ground.
- Golden grass (1 in 200) with sparkle + chime.
- Server checks every cut (position, radius, max cells per second) and pays GRASS.

3) UPGRADES (design section 4): Grass Value, Mower Size, Walk Speed, Regrow Speed, Lucky Blades, Helper Mower (a small bot mower that drives around cutting), Fertilizer milestones.
- Upgrade board on the shed + an UPGRADES button. Each card: name, level, one-line effect, cost, BUY / BUY MAX. Cost = base x growth^level (Config).
- Mower Size must be visible (the mower and the ring get bigger).

4) HUD: GRASS counter big at the top (counts up smoothly), grass per second, the next goal line ("Next: Mower Size 2"). Bold sporty look, navy outlines, no pastel/pink.

TEST
- Fresh test save on phone size: cut, buy each upgrade, see the mower grow, a golden grass, a helper mower, rejoin keeps everything (BigNum saved right).
- Field performance: parts, draw calls, FPS while cutting with a big mower; client memory.
- Phone screenshots, progress note in MOW ARC\Progress\, feature notes. List .fbx files to import.
