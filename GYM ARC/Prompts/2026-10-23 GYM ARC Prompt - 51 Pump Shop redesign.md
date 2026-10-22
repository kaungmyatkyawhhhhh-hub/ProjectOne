---
date: 2026-10-23
tags: [gymarc, prompt]
status: todo
---
# 51 Pump Shop redesign (outside + inside)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Redesign the PUMP SHOP again, outside and inside. The owner wants ONE shop counter in the MIDDLE BACK of the room, and the whole place redesigned around it. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Before changing anything: screenshots of the current outside (front, side, above) and inside (from the door), and copy the whole building to ServerStorage.PumpShopBackup_23Oct.
The shop system stays the same: one panel with SUPPLEMENTS · GEAR · DNA LAB (prompts 31 + 47). Only the building and the room change.

1) OUTSIDE (a corner supplement store that fits the town)
- Same size as the neighbouring town buildings, 2 storeys, a town-style facade (dark charcoal or deep red brick, window frames, a cornice, drainpipes, wall lamps). No giant black box, no blank walls.
- Ground floor storefront: big display windows with black frames, a black + gold awning, a glass double door in the middle. Warm light inside so it looks alive from the street, and product displays visible through the windows.
- Sign: "PUMP SHOP" in gold letters on a black board ON the facade above the awning (lit), plus a hanging blade sign with a dumbbell icon sticking out from the wall.
- One side wall gets an original mural (flexing arm / dumbbell / shaker, black, gold and red, no real brands or people).
- Street: sidewalk, 1-2 planters, a bench, a chalkboard A-frame ("NEW: ELITE PRE-WORKOUT"). The entrance is easy to see from the spawn path.

2) INSIDE: LAYOUT
- Walking in, the player looks straight at the COUNTER in the MIDDLE of the BACK wall. A clear, wide aisle leads from the door to it (wide enough for 7'0" players). Nothing blocks the view.
- Both side walls: tall shelves full of supplement tubs and shakers (use the new boost icon designs: Downloads\gym_arc_boost_icons, as 3D tubs/bottles in the same colours), glowing shelf edges.
- Left front: a GEAR display (mannequins / stands with belts, wraps, straps, sleeves; the Champion gear on a gold pedestal under a spotlight).
- Right front: the DNA LAB corner (a glass case with a glowing DNA helix, a few lab bottles, soft teal light, a small sign "DNA LAB").
- Middle of the floor: 1-2 low display islands with stacked tubs (pyramid stacks) and a "BEST SELLER" tag, leaving the main aisle free.

3) THE COUNTER (the hero of the room)
- A long, chunky counter in black with a gold top edge and gold trim, a glass front with tubs inside, lit from inside.
- Behind it: a big back wall feature: "PUMP SHOP" sign in gold letters, a wall of shelves with the special supplements (Mass Gainer, Elite Pre-Workout, Whey Isolate, BCAA) lit like trophies, and a menu board with the 4 specials and their effects in chunky text (like a cafe menu).
- A shopkeeper NPC behind the counter (original character, big and friendly, black + gold shop shirt, leaning on the counter with a slight idle like Coach Dex; a different face/colours so he's clearly not Dex). He looks at the player when close.
- Props on the counter: a shaker bottle, a scoop in a tub, a little bell, a tip-jar-style "THANKS!" jar (no money), a register.
- The shop ProximityPrompt is on the counter ("SHOP" / E), opens the existing panel. Remove the old counter and its prompt.

4) LOOK + FEEL
- Warm and bright, a little fun (it's a kids' game): dark floor with gold inlay lines, warm ceiling spotlights over the shelves and the counter, a gold LED strip along the ceiling edge, light haze. No dark corners.
- Soft background music or ambient shop sound inside (reuse a game track), quieter than outside.
- Optional small motion: a slowly turning tub on a pedestal, a pulsing glow on the DNA helix.

5) KEEP IT FAST
- Simple parts and reused models. Small props: no collisions, no shadows, Anchored. Check the part count before/after and that walking in on a phone doesn't lag.
- Keep the teleport point (move it to the new entrance), GO TO / GuidePath targets and unlock rules working.

TEST (phone first): walk from spawn to the shop, in through the door, to the counter, open the panel and buy something. Screenshots: outside front, side and above (same angles as before), inside from the door, the counter close up, the gear corner and the DNA LAB corner. Short progress note in the vault with before/after.
```
