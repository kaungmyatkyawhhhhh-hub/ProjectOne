---
date: 2026-11-02
tags: [galaxy, boards, ui, regrowth, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - island boards 1:1, pass 2 (2 Nov, Claude Code)

Prompt + the 6 gaps: [[2026-11-02 Galaxy Incremental - Prompt - Boards 1to1 pass 2]]. Pass 1: [[2026-11-02 Galaxy Incremental island boards 1to1 Regrowth]].
Place "Galaxy Incremental" (111654682859982, P&L Studios XP). Only the personal island boards changed. The centre's Leaderboard and Star Surge were not touched, and GYM ARC was not touched.

Screenshots: `Map\screens\boards_1to1_pass2\` (1-3 side by side with Regrowth from the same angles, 4 spawn view, 5-8 more).

## The 6 gaps, what changed
1. **Pair (Tree + Info): big panels in a stone ledge.**
   - Screens are 11 x 13 studs each (~2.5x the player), still upright (0°) in a shallow V, 3 studs apart.
   - **Frame:**
     - A thick lavender stone frame (1.5 top bar, 1.8 deep).
     - A lighter stone lip round the screen (the bevel).
     - Side posts with round caps and two brass bands each.
     - A brass trim on the top bar.
   - **Ledge:** the panels are set into a low lavender stone ledge with a lighter cap, which runs through the gap too. There are no legs. The screen's bottom is at 2.8 studs (waist height).
   - **Spawn:** moved to 12.5 studs in front of the pair (island-local 12.5, -2.5). From the spawn camera the pair fills most of the screen with its titles in view.
     - Closer, and the camera (which looks down at you) cut the titles off the top.
     - The island's star beam stays beside the camera.
2. **Titles:** huge white rounded letters (FredokaOne) with a thick dark outline, at the top-left over the top frame edge ("CONSTELLATION TREE", "INFO"). They're drawn on a see-through plate in front of the frame. The screens no longer have their own title.
3. **Neon:**
   - **The pair:** crackling energy beams run up the posts and across the top, re-bent ~14 times a second (violet on the Tree, blue on Info), with a soft wide glow beam under each. A breathing glow halo spills out round the frame.
   - **Star Upgrades:** a thick animated flame border (fire particles from all four sides, gold turning violet) spills out like Factory Upgrades. The bottom flames don't rise over the screen.
   - **Drawing:** all of this is drawn by your own game only, for boards near you. With Reduced Motion the beams stop crackling.
   - **Not used:** a rectangular halo round the Bodies / Star boards showed square corners, so only the pair has a halo.
4. **BODIES (Regrowth's Machines):**
   - A thin angular frame, wider at the top: lavender tubes with a violet neon tube on their front and ball joints.
   - A neon glow strip on top.
   - Two struts and a stone slab on the ground, tilted back 10°.
   - No chunky bezel; the screen's corners are dark.
5. **Tree tiles:**
   - Bigger (142 x 136 px), 3 a row across the screen.
   - Each is a dark tile with a soft rounded border (corner 20, a soft 3 px outline), the icon centred, the value at the bottom right in big letters, and the cost under the tile.
   - Locked tiles are dark silhouettes.
   - The INFO page is laid out bigger for the 550 x 650 screen (name 56 px, UPGRADE 78 px tall).
6. **Kept and re-checked in Studio Play:**
   - **Live buttons on the big pair:** INFO's UPGRADE bought an Asteroid (70 → 71); tapping Comet Lure switched INFO.
   - **New save:** the floor trail and the arrow on BODIES' Asteroid UPGRADE work, a real click bought it, and step 1 completed.
   - **New player (tier 0):** the pair, the side boards and their pads are in place.
   - **No errors.**
   - **Not re-run this pass** (their code didn't change): M, 10x, VISIT and scrolling. A real phone touch is still untested.

## Side by side (same angles as pass 1)
- `1_sbs_perks_info_vs_tree_info.jpg`: two big stone panels with huge titles and energy round the frames, the player in front.
- `2_sbs_machines_vs_bodies.jpg`: the angular neon board at the left on its stand, the big tree at the right edge.
- `3_sbs_factory_vs_star_upgrades.jpg`: cards with star badges, a flame border round the frame.
- **Still different:**
  - Regrowth's lightning is drawn jagged lines (a texture). Ours are bent glowing beams.
  - Regrowth's pair panels have rounded tops on the frame. Ours have rounded post caps and a flat top bar.

![[Celestial Incremental/Map/screens/boards_1to1_pass2/1_sbs_perks_info_vs_tree_info.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1_pass2/2_sbs_machines_vs_bodies.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1_pass2/3_sbs_factory_vs_star_upgrades.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1_pass2/4_spawn_view.jpg]]

## Code
- **MapConfig:** Boards (Pair frame sizes, Style "Neon", Flames, StoneLight); Islands.Spawn.
- **GalaxyMapBuilder:** BoardFrame in 3 styles; BoardHalfWidth.
- **GalaxyMapService:** the gap ledge.
- **IslandBoardsUI:** corner colours, the pair without its in-screen title, bigger tiles and INFO.
- **GalaxyBoards:** titles, halos, beams, flames.
- **Vault copies:** `Code\` updated, checked identical to Studio.

## Owner to-do
- File > Save / publish.
- If you want the spawn closer (bigger pair, titles cut at the top), it's one number: `MapConfig.Islands.Spawn` (now x 12.5).
