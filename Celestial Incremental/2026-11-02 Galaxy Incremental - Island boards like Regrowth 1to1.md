---
date: 2026-11-02
tags: [galaxy, boards, regrowth, decided]
status: decided, replaces "Boards fix 2"
---
# Galaxy Incremental - island boards as a 1:1 copy of Regrowth's boards (2 Nov)

Owner (screen `Map\screens\boards2\boards_tilt18_too_much.png`): "it is tilting even more now. also it should be like 1:1 direct copy boards from regrowth incremental because i like it so much".
-> I had read "tilted a bit upwards" wrong (made it 18 deg). Now: copy Regrowth's boards in form, layout and behaviour. Own art, icons and text (their textures/icons can't be taken; a pixel copy of another game can get a game flagged as a copy).
References: `Map\screens\regrowth_boards\regrowth_board_perks_info_1/2.png`, `regrowth_board_machines.png`, `regrowth_board_factory_upgrades.png`.

## What Regrowth's boards are (from the screenshots)
1. **PERKS TREE + INFO pair**: two separate upright panels side by side, angled in toward the player (a shallow V), standing on the platform edge right behind the railing; the player stands in front between them. Thick chunky rounded frame (light lavender stone, bevelled, 1+ stud), dark screen, animated glowing lightning along the inner screen edge. Title in big white bold letters with a dark outline at the top-left of the screen ("PERKS TREE", "INFO").
   - PERKS TREE: a grid of rounded square tiles, each with an icon, its multiplier ("1x", "1.2x") and a cost with the currency icon under it; locked tiles are dark silhouettes; scrolls.
   - INFO: shows the selected thing: big icon, big name (coloured), "LEVEL x / TIER y", multiplier "1.2x" + green "+0.1x", "TIER 0 [NO TIER]", progress "2/10" bar, a "10x" toggle and a big UPGRADE button with the cost under it.
2. **MACHINES board**: one wide panel on a stand, slightly tilted back, neon edge (pink), title "MACHINES" centred at the top. List rows: name, LEVEL, TIER, "+199/s", buttons UPGRADE (cost), M (max), "+MACHINE" (cost), count "2x" at the right. Scrolls.
3. **FACTORY UPGRADES board**: wide panel with an animated neon flame edge, title at the top, CARDS side by side: name, short description, icon, value "1.26x +0.25x", a star badge with the level, UPGRADE button with the price.
All buttons are clicked on the board; numbers update live; the tutorial arrow points at the board's button.

## Our copy (Galaxy names, galaxy colours: violet/blue neon instead of pink, brass+lavender frame)
On each personal island, around the edge, like Regrowth's plot:
- **Far edge, the pair (upright, 0 deg tilt)**: CONSTELLATION TREE (Perks Tree layout: grid of node tiles, multiplier + cost) + INFO (selected node or upgrade: icon, name, LEVEL/TIER, value + green step, progress, 10x toggle, big UPGRADE + cost).
- **Left edge: BODIES board** (Machines layout): rows Asteroid / Moon / Planet / Gas Giant...: LEVEL (owned), TIER, "+x/s", UPGRADE (buy 1, cost), M (buy max), count "12x"; locked rows show the unlock cost.
- **Right edge: STAR UPGRADES board** (Factory Upgrades layout): cards First Light, Orbit Speed, Comet Lure...: icon, value + step, star level badge, UPGRADE + price.
- Tilt: pair 0 deg; Bodies + Star Upgrades boards 10 deg back on a stand (like Machines). Frames 1.2 thick, rounded, lavender stone + brass trim; animated neon edge (violet / blue / gold per board); titles big white with dark outline.
- Scrolling lists (no pages). Same data/remotes as the 2D windows (U opens the same panels on screen).
- FORGE and BLACK HOLE: later boards in the same style (locked board with a padlock and the unlock text until then).
