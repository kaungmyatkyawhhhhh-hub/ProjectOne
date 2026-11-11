---
date: 2026-11-02
tags: [galaxy, prompt, map]
status: todo (Claude Code, Galaxy session)
---
# Prompt for Claude Code: redo the Galaxy map to scale

```text
GALAXY INCREMENTAL (P&L Studios XP place only, never touch GYM ARC): REDO THE MAP TO SCALE.
Owner: the scaling is wrong for every single thing, and the boards show the declined UI. Rebuild, do not patch.
Read first: Celestial Incremental\2026-11-02 Galaxy Incremental - Map scale spec (redo).md (the size table is the law), Map design and quality.md (DECIDED personal islands), Map\galaxy_map_concept_v3.png (look only, NOT sizes).

1) SCALE: size every piece against a real R15 character using the spec table (island 60 across, plaza 140, bridges 8 wide, lamps 9 tall, Core ~26 footprint / 20 tall, BH ring 22, anvil 8x3.5, terminals 15x10.3...). Put every size + position in ReplicatedStorage.Galaxy.MapConfig and build ONLY from MapConfig (no hard-coded numbers in GalaxyMapBuilder). Rescale/re-export the kit meshes if needed; do not just stretch them non-uniformly.
2) LAYOUT: centre plaza (Core, leaderboard wall 24x12 + players-near-you, STAR SURGE bar, Star Forge platform, Black Hole gate, Sector 2 arch 14x12 with a 10-wide bridge), 8 personal islands in a ring, each with an 8-wide bridge 20-25 long. Free slots = dim empty rock + bridge.
3) BOARDS 1:1: delete the old images (101241710618078 / 119028925930340). Use the new ids the owner gives for board_upgrades_v12.png / board_tree_v12.png. Screen part exactly 745:512 (15 x 10.3), image unstretched/uncropped, one-sided. They are TERMINALS on EACH personal island (tier-1 piece), facing the island spawn, open by click AND ProximityPrompt. If the ids aren't there yet, leave a placeholder part named BoardImagePending and tell me.
4) FIXES: padlock on the anvil front; BH swirl stronger + animated, void opaque; all text readable (2.5-3 stud letters for plaza signs, name plates 2.5); Forge/BH signs keep facing inward.
5) KEEP: tier growth pieces, star system above islands (~22 up, star 4->8, orbits 6-14), Supernova shockwave, look rules (low-poly, static textures, animated VFX, no glass, no emojis), StreamingEnabled, few lights.
6) PROOF: screenshots WITH a character standing next to: an island terminal, a bridge, a lamp, the Core, the anvil, the BH gate; one wide shot; one phone view 667x375; a side-by-side with concept v3. Save to Map\screens\ and write a progress note in Progress\.
```
