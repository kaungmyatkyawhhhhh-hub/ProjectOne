---
date: 2026-11-02
tags: [galaxy, design, retention, story, codes]
status: decided (owner, 2 Nov)
---
# Galaxy Incremental - design additions (2 Nov)

Owner answers (2 Nov): "1. add all four like how u suggested. 2. make it like how regrowth incremental and immortality incremental keeps us making us play. 3. yes to both. 4. as u said 5. as u said 6. sure".
Research: [[2026-11-02 Research - Immortality Incremental and Regrowth, why players keep playing]]. Base design: [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]].

## 1. Regrowth lessons (all four)
- **Tutorial pays Essence per step** + a step counter ("4/12") and a % bar per goal (Regrowth: 25 premium per step). Total ~10 Essence over the tutorial (enough for the first Forge rolls at Supernova 3; check against the Essence economy).
- **GUIDE BOOK (key G)**: one page per feature with a picture and 3 lines; pages unlock when the feature does; a red dot on new pages.
- **"Players near you" board** next to the top-10: the 5 players just above and below your lifetime Supernovas.
- **Something new at ~35 min** (Regrowth's wall): the first Supernova lands about there in our map; check with the calculated pace; if it's later, the comet storm / first challenge fills it.

## 2. "Keep us playing" (story = progression, Immortality + Regrowth style)
- **Premise (one line, shown on the loading screen and the first tutorial card): "The galaxy went dark. Light it up again, one star at a time."** No long story text, no cutscene walls.
- **The story is SEEN**: your star system starts as a dead rock in the dark and visibly grows (planets, rings, moons, nebula colour) with every buy (Regrowth's tycoon feeling).
- **CHAPTERS = SECTORS of the galaxy** (like Immortality's worlds): Sector 1 Ember Belt (stardust, the Supernova), 2 Comet Reach (comets, the Forge), 3 Nebula Gate (Black Hole), 4 Ring Nebula (fusion)... Each sector has a name, its own sky colour on the map and ADDS A NEW SYSTEM, not just bigger numbers. Later updates add sectors in parts ("SECTOR 5 PT1").
- **IGNITION = our breakthrough gate** at the end of each sector: needs several things at once (a stardust amount + a Supernova count + a tree node + sometimes shards). Shown as a big gate with checkboxes, always visible = the next big goal is never hidden.
- **Layers**: Supernova (reset 1) -> Black Hole (reset 2) -> later Big Bang (reset 3); each makes the next run faster (already in the design).
- **Paths (choices)**: at each Ignition pick 1 of 2 paths (e.g. "Comet path" or "Planet path") that change the build; can switch later for shards.

## 3. Title tag + codes (yes to both)
- Title tag per update: "[ALPHA] Galaxy Incremental" -> "[FORGE]" -> "[BLACK HOLE]" -> "[SECTOR 4]"...
- Codes, Immortality style, many and named: milestones (100LIKES, 1KVISITS, 10KVISITS, 100CCU, 1KGROUP, 1KFAV), updates (ALPHA, FORGE, BLACKHOLE, SECTOR4PT1), events (HALLOWEEN, HOLIDAY), apology after a bug (SORRY). Rewards = Essence + **Boost Potions** (x2 Stardust 15 min, x2 Comets 15 min: used when you want, Immortality's potions). Codes are added from the admin console without republishing (GYM ARC system).
- Codes window: in the Store (E) + Settings.

## 4-6
- Icon + 3 thumbnails: Claude makes them in the v12 art style (Blender renders).
- Forge, Tree, Store, Black Hole windows: Claude mocks them up in the v12 style first.
- Second Regrowth session (its 6 chapters): Claude Code plays it (prompt in chat 2 Nov).

## Done 2 Nov
- Icon + 3 thumbnails: `Art\galaxy_icon_1024.png`, `galaxy_thumb_1_chain.png` ("LIGHT UP THE GALAXY!": rock > star system > SUPERNOVA > black hole > ?), `galaxy_thumb_2_before_after.png` (START / LATER, 1 stardust vs a full system; no "day 7" claim so it can't mislead), `galaxy_thumb_3_supernova.png` ("GO SUPERNOVA!"). All Blender renders (`galaxy_scenes_blender.py`: rock, black hole, supernova, star system, galaxy background) + text in Montserrat Black Italic gold, made by Claude. Upload: icon 512x512 (Roblox scales), thumbnails 1920x1080, all to the P&L Studios XP game.
- Window mock-ups in the v12 style: `UI\windows\galaxy_window_forge.png` (anvil hero, ROLL / ROLL x3, pity bar, odds list 60 / 25 / 10 / 4 / 0.9 / 0.09 / 0.01 from the design), `galaxy_window_tree.png` (constellation nodes as diamonds, lit lines, ? nodes, selected node bar with shard cost), `galaxy_window_store.png` (4 passes from the design with Robux prices, no fake "was" prices), `galaxy_window_blackhole.png` (YOU GET / KEEP / RESET, next milestone, COLLAPSE button with motes). Each window has its own theme colour (Forge blue, Tree green, Store red, Black Hole violet). Source `galaxy_windows.html`.
