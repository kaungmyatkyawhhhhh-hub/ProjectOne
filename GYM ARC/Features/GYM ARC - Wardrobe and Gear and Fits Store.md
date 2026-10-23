---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Wardrobe and Gear and Fits Store

Back to [[00 GYM ARC Home|GYM ARC Home]].

Buy gym gear and outfits with coins at the clothing store in town, then wear them from the Wardrobe.


## Switched off for now (13 Oct)
`Config/Features.Wardrobe = false` (owner's call): the Wardrobe tile is hidden (no gap in the menu), the tops (gym fits) are off sale in the clothing store and can't be worn, and anyone who already owned tops got them removed and their coins refunded once (a small "Coins refunded" note). The other gear (belts, headbands, wraps, shakers, skate decks and wheels) still works. The cause of the broken tops is fixed: [[GYM ARC - Bug - Wardrobe tops broken on the muscle body]]. Turn the switch back on in `Config/Features` when you want the Wardrobe back.

## How it works
- **Store:** the Gear and Fits clothing store in town; buy at the counter with coins.
- **Gear slots and prices:**
  - Lifting belts (120-200), headbands (60-80), wrist wraps (70-90), shakers on the hip (100-120)
  - Skateboard decks (80-150) and wheels (150-900, faster each)
- **Gym fits (8 Oct):** 6 tops x 4 colors as classic Shirts: gym tee (150), stringer tank (200), pump cover (300), sleeveless hoodie (300), compression shirt (350), cropped hoodie (400). The muscles wear them.
- **Wardrobe tile:** pick what to wear, plus Top (Shirtless / Tank / Sports) and shorts colors. Default is shirtless with game shorts.
- Gear is built on the body in code (belts, headbands, wraps, shakers).

## Where it lives
- `Config/Cosmetics` (slots, items, Fits + FitTemplates)
- `Server/CosmeticService`, Wardrobe UI, `tools/clothing_templates.ps1` (shirt images)

## Known issues
- At mass monster size bits of skin poke through on the biggest delts / biceps under a fit (any classic shirt).
- Cosmetic headbands can hide under big hair.

## Planned change
- **Monetization prompt, task 1:** hide the Wardrobe button, its UI and the clothing shop items / prompts behind `Config.Features.Wardrobe = false` (code and data kept). Players keep their current outfit; saving, clothing on muscles and NPC outfits must not break.

## Related
[[GYM ARC - Skateboard and Skate Park]], [[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Muscles and Bodies]]

## Screenshots
![[GYM ARC/Screenshots/s3_clothing-store-interior_after.png]]
![[GYM ARC/Screenshots/task2_fit_stringer_front.png]]
![[GYM ARC/Screenshots/skate-wardrobe_after.png]]

## The looks system now (checked 19 Oct)
Nothing here changed in the owner's 19 Oct Studio work. What a player can change today:
- **Wardrobe: still OFF** (`Config/Features.Wardrobe = false`): no Wardrobe tile, tops can't be bought or worn.
- **Gear that works:** lifting belt, headband, wrist wraps, shaker, skateboard deck and wheels (bought at the clothing store with coins, one per slot). Saved in the player's save as `cosmetics.owned` / `cosmetics.equipped`.
- **Top and shorts color:** saved as `settings.top` (default "Shirtless") and `settings.shorts` (default "Black"); with the Wardrobe off nobody can change them.
- **Auras:** saved as `auras.owned` / `auras.equipped`, picked in the INVENTORY window ([[GYM ARC - Aura]]).
- **Body look:** not a choice: it comes from your muscles, height and genetics frame ([[GYM ARC - Muscles and Bodies]]). Your own Roblox head, face, hair, hats and skin color stay; back, front and neck accessories are removed.
- **Your own Roblox clothes:** your avatar's classic Shirt / Pants are worn on the muscle meshes (without them you are shirtless in the game shorts). Layered 3D clothing hides the muscles.

## Gear meshes (21 Oct, prompt 34)
- Belts, wrist wraps, lifting straps and knee sleeves are now the planner's Blender meshes (`ReplicatedStorage.GearMeshes`, built by `Shared/Gear`, fitted to the muscles you see by `GearClient`): a leather belt with stitching and a steel buckle, wraps with stripes and a thumb loop, straps with a tail, knee sleeves with bands. Color = the item's color (PUMP SHOP levels: the level color with a matching trim).
![[GYM ARC/Screenshots/trainer_outfits/player_gear_g000.jpg]]

## Gear rework (23 Oct, prompt 59, [[2026-10-23 GYM ARC Gear, shop items, monetization and economy]])
- Only two gear pieces now: LIFTING BELT (+5% / +10% lower body: legs, back, core) and WRIST WRAPS (+5% / +10% upper body: chest, shoulders, arms). Basic 750 / Pro 4,000 at Coach Dex. Elite / Champion off sale (owners keep them).
- The best level owned counts, worn or not. Straps and knee sleeves are gone: once per player they turned into the matching piece (a higher level) or their coins came back.
- Colours like the pictures: Basic brown leather, Pro black + silver, Elite purple + silver, Champion gold (Config/PumpShop.GearIcons).
