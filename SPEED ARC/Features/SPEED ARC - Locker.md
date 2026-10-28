---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2 shoes + trails, M5 kits / head / bib / name / title)
---
# SPEED ARC - Locker

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- One window from the LOCKER button (left menu), the Shoe Shop and the Trail Booth.
- Tabs: **SHOES, TRAILS, KITS, HEAD, BIB, NAME, TITLE**. Cards in a row you can scroll: art, name, bonus or "just for looks", price or WEAR / WEARING, locked items dark with how to get them.
- Only shoes and trails give (small) boosts. Everything else is cosmetic (Customization note).
- Windows use the UI kit's `UIKit.window` (dimmed screen, slanted title tab, X button, one window at a time) and `UIKit.tabs`.

## M5 cosmetics (Config/Cosmetics)
| Tab | Items | Price (minutes of coins at your league) |
|---|---|---|
| KITS | Blue Singlet 5, Gold Race Tee 15, Black Zip Top 30 (tops); Blue Race Shorts 5, Black Split Shorts 15, Gold Run Tights 30 (bottoms); VIP Singlet + VIP Shorts (VIP pass) | one top + one bottom |
| HEAD | Headband 5, Team Cap 10, Gold Visor 12, Sport Shades 15, Bucket Hat 18, Winter Beanie 20 | one at a time |
| BIB | your number 1-999 (free), colours Blue (L1), Park Green (L2), Stadium Silver (L3), World Gold (L5) | free |
| NAME | Electric Blue 60, Gold 90, Ice 120, Fire 150, Black Gold 180, VIP (VIP pass) | the colour of your name over your head |
| TITLE | every title you earned | earned |
- Shoe skin: the Starter Pack's gold Canvas Runners (shows in KITS once owned).
- Tap WEARING to take an item off.

## How worn items work
- The server welds them onto the character, so everyone sees them. They live in `workspace.Runtime.Cosmetics.<UserId>`, not inside the character: on 28 Oct the tee did not draw when it was inside the character (the same mesh drew fine outside it; the exact Roblox reason is not confirmed). Each is one mesh from `ServerStorage/Meshes` (`Kit_*`, `Head_*` from `blender/locker_kit.py`), sized to the body part (works on different avatar sizes). Until a mesh is imported, a simple part stand-in shows.
- **Kits as real clothes (28 Oct):** each kit also has a classic Shirt / Pants template (`tools/make_clothing.py`, PNGs in `Downloads\speed_arc_models\clothing\`, preview `Screenshots/models/clothing/`). Once its image id is in `Config/Cosmetics` (`Template`), the kit is worn as the character's Shirt / Pants: it wraps the body and moves with the arms and legs, and the avatar's own shirt / pants come back when it's taken off. Layered clothing on that part of the body is set aside while the kit is worn (not tested yet: no test avatar with layered clothing). `Template = 0` = the mesh is used.
- The meshes are light grey: the game tints each one with the item's colour, so one mesh serves several items.
- Other players' worn items hide past 150 studs.

## Studio test switches
`TestOpenWindow` = "Locker:KITS" / "Locker:BIB" / ...

## Where it lives
`Client/Controllers/LockerController`, `Server/Services/LockerService` (shoes, trails, the collection snapshot), `Server/Services/CosmeticsService` (kits, headwear, bib, name styles), `Config/Cosmetics`.
