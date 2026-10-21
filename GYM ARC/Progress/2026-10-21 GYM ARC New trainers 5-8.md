---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC New trainers 5-8

Prompt: [[2026-10-21 GYM ARC Prompt - 25 New trainers 5-8]] (with the owner's decisions on prompt 24). Feature note: [[GYM ARC - Personal Trainers]].

## What prompt 24 had for 5-8
Placeholders: Coach Atlas / Blaze / Shade / Aeon, bare-chested with part-built shorts, shoulder pads / cape / hood / crown and AuraVFX auras (screenshot: [[2026-10-21 GYM ARC Trainer rolls]], followers_eternal_mythic.jpg).

## Done
- 5-8 remade: **Duke Ironside** (Legendary powerlifting coach), **Volta** (Mythic strongwoman coach), **The Shadow** (Secret, hood with glowing eyes), **Atlas** (Eternal living statue in white marble with gold veins). Ids unchanged (saves keep working).
- Own idles (chalk clap + neck crack, bouncing + shadow-boxing, watching you, double biceps every 8 s), equip lines for all 8, small auras (max ~15 particles, no shadows).
- Rendered icons + reveal pictures for all 8 (and the Secret silhouette), on the Agency list, the boards, the Trainers tab and the roll reveal (with the line).
- Owner decisions: odds Mythic 0.6%, Secret 0.15%, Eternal 0.035%, Common 50.215%; Coach Nia +15% stamina regen; gains cap +1 per alter tier and a MAX BOOST tag.

## Measured (`lune run tests/trainers`)
First Epic+ ~20 min, Legendary ~57 min, **Mythic ~3.4 h**, **Secret ~14.6 h**, Eternal ~76 h (1.6 min of coins a roll). All 19 test suites pass.

## Tested in Studio (fresh test player, nothing saved)
- All 8 on a stage, the four new ones as followers (lines, idles, auras), forced Legendary / Secret / Eternal rolls (reveal pictures and lines), the Agency list and board icons (Secret silhouette until owned), Inventory > Trainers, the MAX BOOST tag (shown by hand: a fresh player can't reach the cap). No script errors.

![[GYM ARC/Screenshots/trainers_5_8/all_8_lineup.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/agency_board.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/agency_window.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/reveal_duke.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/reveal_shadow.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/reveal_atlas.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/inventory_trainers.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/following_shadow_atlas.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/max_boost_tag.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/icons_and_reveal_pictures.png]]

## Needs the owner
- Volta uses Roblox's "Chill" face with a ponytail and side locks (no lashes face in our list). OK, or pick a face id?
- 32 new images were uploaded (7 clothing templates, 8 marble maps incl. a retake, 17 pictures): check they're owned by the group in the Creator Dashboard.
- Atlas's gold veins are a texture pattern (MaterialVariant, 6 studs a tile): look at him up close.
- The MAX BOOST tag was only checked by hand (the cap needs very big boosts).
