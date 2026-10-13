---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Wardrobe and Gear and Fits Store

Back to [[00 GYM ARC Home|GYM ARC Home]].

Buy gym gear and outfits with coins at the clothing store in town, then wear them from the Wardrobe.

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
