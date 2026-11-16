# MM Outfit Catalog: honest audit + rework plan

- **Date:** 2026-11-17
- **Owner:** "i still dont like the vibe of the place. the outfits dont look good, everything dont look polished, the system is bad, the map is bad, the placements are bad, the entire game sucks"
- **Method:** [[Brain/Methods/Quality-nerd kid simulation]]. Studio audit + a player-eye photo tour + the sim (`Calc/nerdsim.py`).

## What a player actually sees (Studio, 17 Nov)

| Area | What's wrong |
|---|---|
| **Whole map** | 11,237 parts but only **43 mesh parts**. Nearly everything is plain blocks, so it reads as a block-out, not a finished place. |
| **Showroom (spawn)** | A big brown box: 3 small mannequins against one wood wall, a huge bare floor, a flat ceiling, a muddy floor texture, plain text-box signs, and a "Most Purchases" board too small to read. |
| **Furniture** | Blocky sofas in clashing colours (olive, salmon, orange, green); no single palette. |
| **Penthouse** | Blank beige panels floating in front of the windows, beige boxes, orange everywhere, and a zone banner over the top of the screen. |
| **Tower (17 floors)** | Every floor is the same 62×89 wooden box with a staircase and about **2 pieces of furniture**. Theme names (Vinyl Lounge, Winter Garden…) that the rooms don't show. Floors 09 and 14 look identical. |
| **Outfits** | Shown on **R6 classic mannequins with flat 2D shirts and pants**, while players are R15. Top outfit games show R15 bodies, layered 3D clothing and accessories. Only **3 outfits** in the whole game. |
| **Lighting** | The showroom is very dark from one side, the windows wash out white from another, and nothing is graded as one mood. |
| **System** | The loop is: look at 3 outfits → maybe buy pieces. Nothing to do after that and no reason to come back. The tower is a long walk through empty rooms with small "activities" (postcards, a light switch, card match) that don't connect to outfits. |
| **HUD** | 10 buttons (3 left, 5 right, 2 top) + zone banners + prompts, competing with the room. |

![[Screenshots/2026-11-17 audit - showroom front (empty box).jpg]]
![[Screenshots/2026-11-17 audit - showroom back (clashing furniture).jpg]]
![[Screenshots/2026-11-17 audit - penthouse (blank panels).jpg]]
![[Screenshots/2026-11-17 audit - tower floor 09 (same empty box).jpg]]

## Quality-nerd sim (2,000 kids × 10 min, cumulative fixes)

| Version | Tells / 10 min | Wows | Like | Top tells |
|---|---|---|---|---|
| A live build | 77 | 1.6 | 0% | empty views, blocky furniture, flat dated outfits |
| B cut the tower to 3 themed floors | 67 | 2.1 | 0% | blocky furniture, dated outfits, empty views |
| C one palette + lighting grade | 57 | 2.1 | 0% | same |
| D R15 layered outfits, 12+ | 46 | 3.6 | 6% | blocky furniture, empty views, placeholder UI |
| E real furniture / mesh kit | 35 | 3.6 | 23% | empty views, placeholder UI, nothing reacts |
| F set pieces (runway, mirrors, neon) | 29 | 5.4 | 53% | placeholder UI, nothing reacts |
| G ambient life + readable signs | 20 | 5.9 | 85% | empty views, HUD |
| H HUD trimmed | 17 | 5.9 | 93% | – |

**Reading it:** no single fix saves the game. Kids only start liking it after D + E + F, so this is a **rebuild of the place and the outfits**, not more patches.

It's a model with hand-set chances from the audit. The real check is screenshots, then likes and comments after a test.

## Rework plan (in order)
1. **Decide what MM is** (the owner's call; see the options below). Everything else follows from it.
2. **Shrink the map to one great floor + a rooftop.** Delete or hide the 17 empty tower floors. One boutique floor that looks finished beats 19 empty ones.
3. **One look:** pick a palette and lighting grade (e.g. night boutique: warm walnut + black + one accent, pink or brass) and apply it to every surface (roblox-game-lighting).
4. **Outfits:** R15 mannequins with the outfits' real layered clothing and accessories, and 12+ outfits that rotate (daily or weekly drops). Add My Outfit already makes adding them fast.
5. **A real kit:** clothing racks, full-length mirrors, curved sofas, a cash wrap, plants, neon signs. Use meshes from the Creator Store (checked, free) or our Blender pipeline (roblox-3d-model-from-sheet), not blocks.
6. **Set pieces:**
   - a lit runway with pink arches (matches the new thumbnails);
   - fitting rooms with mirrors that show your try-on;
   - an "MM" neon sign;
   - the rain-window café bar.
7. **Life:** NPC shoppers posing in outfits, racks that sway, readable boards (Fit of the day, most bought).
8. **HUD:** 4 buttons + a menu, and no banners over the view (overstimulated-kid sim).
9. **Check:** re-run this sim + player-eye screenshots on PC and phone before the owner tests.
