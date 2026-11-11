```text
GALAXY INCREMENTAL (P&L Studios XP place, never GYM ARC): REBUILD THE PERSONAL ISLAND BOARDS AS A COPY OF REGROWTH'S BOARDS. This replaces "Boards fix 2". Only the boards on each personal island; don't touch the centre's Leaderboard / Star Surge.
Read: Celestial Incremental\2026-11-02 Galaxy Incremental - Island boards like Regrowth 1to1.md (the law). Study the Regrowth screenshots in Map\screens\regrowth_boards\ closely and match their form, layout, proportions and behaviour. Use our own icons/text/colours (no Regrowth textures or icons).
1) TILT: the pair is UPRIGHT (0 deg). My 18 deg was wrong. Bodies + Star Upgrades boards 10 deg back on a stand.
2) BOARDS per island (MapConfig.Boards, one table):
   - far edge: CONSTELLATION TREE (Perks Tree layout: grid of rounded node tiles with icon, multiplier, cost; locked = dark silhouette) + INFO (selected item: icon, name, LEVEL/TIER, value + green step, progress bar, 10x toggle, big UPGRADE + cost). Two separate panels in a shallow V toward the player, gap ~3 studs, player stands in front between them.
   - left edge: BODIES (Machines layout): rows with name, LEVEL, TIER, +x/s, UPGRADE (cost), M (max), count; locked rows show UNLOCK + cost.
   - right edge: STAR UPGRADES (Factory Upgrades layout): cards with icon, name, short text, value + step, star level badge, UPGRADE + price.
   Frames: chunky rounded 1.2-stud frame, lavender stone + brass trim, dark screen, animated neon edge (violet tree, blue info, violet bodies, gold upgrades). Big white titles with dark outline. Scrolling lists, no pages; keep scroll position on refresh.
3) Same data and remotes as now (one source of truth); U still opens the same panels on screen. Owner-only buying, visitors see VISIT. Tutorial step 1 arrow -> Asteroid UPGRADE on the BODIES board. Spawn faces the pair.
4) Delete the old two boards (UpgradesPanel board / TreePanel board on islands) after the new ones work.
5) PROOF: screenshots side by side with each Regrowth reference (same camera angle as their pic), spawn view, phone 667x375 tapping a button, a visitor view. Progress note.
```
