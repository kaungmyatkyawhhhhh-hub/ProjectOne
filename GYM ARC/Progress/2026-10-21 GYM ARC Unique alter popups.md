---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Unique alter popups

Prompt: [[2026-10-21 GYM ARC Prompt - 22 Unique alter popups]]. Feature note: [[GYM ARC - Body Alters]] (section "Popups and transformation").

## Done
- The 5 Tier 1 backgrounds uploaded (ids in `Config/AlterThemes`). Every alter (1-30) has its own theme; tiers 2-6 colors only for now.
- New popup (`Shared/UI/AlterPopup`) matching mockups.png, with the full dramatic entrance and loops; fits 667 x 375.
- New transformation (`Shared/VFX/AlterFX`) themed per alter, skippable, the ALTER action fired at the flash; the body flexes after; players nearby see the flash.
- Layered sounds (28 ids, all Pro Sound Effects / APM licensed library), listed in [[GYM ARC - Music and Sounds]]. Music ducks to 30% and is muffled during the moment (`Audio.Duck`, `Audio.Muffle`).
- Inventory > Alters and PUMP SHOP > Alters cards: art strip + accent line. The PUMP SHOP's ALTER NOW plays the same transformation.

## Tested in Studio
- Popups: Pumped, Shredded (at 667 x 375), Vascular, Peak (TIER 1 COMPLETE), Steel (no art yet). Vascular's art took a few minutes to be approved after the upload.
- The transformation for Tanned (near a wall: fixed the camera to pick a clear angle) and Peak in the street: flash, title card, gold dust.
- Not done with your real save: the actual ALTER (it would use up your next alter), so the server flex pose and the flash for other players are untested live (one player here). I can't hear sounds: please listen and swap any id in `Config/AlterThemes`.

![[GYM ARC/Screenshots/alter_popups/pumped.jpg]]
![[GYM ARC/Screenshots/alter_popups/shredded_phone.jpg]]
![[GYM ARC/Screenshots/alter_popups/peak.jpg]]
![[GYM ARC/Screenshots/alter_popups/steel_no_art.jpg]]
![[GYM ARC/Screenshots/alter_popups/transform_title.jpg]]
![[GYM ARC/Screenshots/alter_popups/inventory_strips.jpg]]

## Needs the owner
- Listen to the sounds (picked by their library descriptions).
- Image ownership of the 5 new backgrounds (uploaded by the Studio tool, like the alter textures).
- Studio's "Allow HTTP Requests" was off; it was switched on only while pushing scripts and set back off each time.
