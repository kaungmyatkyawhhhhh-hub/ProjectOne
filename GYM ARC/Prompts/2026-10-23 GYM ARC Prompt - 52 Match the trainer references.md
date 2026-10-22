---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 52 Match the trainer references (Agency, My Trainers, Evolutions)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner says the Trainer Agency and MY TRAINERS screens "look nothing like" the references. Rebuild their LAYOUT and LOOK to match the references closely. Logic, numbers and saves stay the same. Follow CLAUDE.md Speed rules. Mobile first (667x375 and 844x390; scale the whole panel with UIScale). Never undo the owner's manual Studio changes.

Files: C:\Users\kaung\Downloads\gym_arc_trainers_refs\
- ref_agency.png, ref_my_trainers.png, ref_evolutions.png = THE TARGETS. Match them.
- now_agency.png, now_my_trainers.png = how it looks now (wrong).
Put each new screenshot next to its reference in the note and list anything that still differs.

0) SHARED TILE (used on all 3 screens, same as the references)
- Big square tile with a rounded 4 px border in the RARITY colour (Agency) or TIER colour (My Trainers / Evolutions), with a soft outer glow of the same colour.
- Background: the tier hex texture + its VFX (evo_bgs, prompt 33) or the rarity-colour hex + light rays (Agency), filling the WHOLE tile. Never a plain dark tile.
- Top: trainer NAME in white chunky text with a dark stroke.
- Middle: the trainer art BIG (fills ~60% of the tile, waist-up, centred).
- Below the art: the rarity / tier word big in its colour with a dark stroke (LIMITLESS in its rainbow gradient).
- Bottom: "LV 18" (My Trainers) or the chance "12%" (Agency) in big white stroked text.
- Owned / equipped: small gold check top-right. Dupe count "x2" bottom-right.
- Not owned (Agency): solid black silhouette with a thin rim in the rarity colour on a bright rarity burst. Secret name "???" until owned.

1) TRAINER AGENCY (match ref_agency.png)
- ONE panel: title "TRAINER AGENCY" in heavy italic white with a short gold underline. No AGENCY / MY TRAINERS tab pills on this screen, no keycaps, no long grey text, no "Following" text.
- Inside: the 8 trainers as 2 rows of 4 SHARED TILES, large (the grid fills the panel).
- Chances stay as percentages (0.6%, 0.15%, 0.035%), never "1/167".
- UNDER the panel, centred, separate from it: a dark pill with "EPIC GUARANTEED IN 63 ROLLS" and a thin teal progress bar under the text (fix the current broken teal block). Under that, one row: a big red ROLL button ("525 COINS"), then flat dark X3 (price) and AUTO (OFF/ON). The gear (auto-delete) is a small icon button at the end of that row.
- A small "MY TRAINERS" button can sit at the panel's top-right next to the X, in the flat dark style.

2) MY TRAINERS (match ref_my_trainers.png)
- Title "TRAINERS" heavy italic with the gold underline, then two pills: "● EQUIPPED 3/3" (green dot) and "● OWNED 16/50" (teal dot). X top-right. No tab pills.
- LEFT (about 60% of the width): a 4-wide grid of BIG shared tiles (4 rows per page on desktop, 2-3 on phones), sorted best first (tier, then rarity, then level). Equipped ones have the gold check. Under it: PREV · "PAGE 1/2" · NEXT in chunky style. (EVOLVE ALL can stay as a small flat button next to them.)
- RIGHT: the detail panel:
  - The selected trainer as a big shared tile (name, art, tier word, LV), with the tier border.
  - EXP bar: a pill bar with "LV 18" on the left end, "7.2K / 10K EXP" in the middle, "LV 19" on the right end, in the tier colour.
  - A dark box with the boosts as big coloured rows with an icon each: "+12% EXP" (blue bolt), "+8% COINS" (gold coin), "+5% PROGRESS" (green arrow). Real numbers from the config.
  - "NEEDS 3X BEAST-MODE · 2/3" in white stroked text with 3 mini tiles on the right (missing one dimmed).
  - Two big buttons: a green EQUIP (or dark UNEQUIP when equipped) and the NEXT EVOLUTION button styled as a mini tile of the next stage ("COLOSSUS LV1" on its background). Tapping it opens the evolve confirm. At max: "MAX STAGE".
  - The total line ("TOTAL +40% EXP (MAX +400%)") small under the buttons.
- Remove the separate middle preview column; the layout is 2 columns like the reference.

3) EVOLUTIONS CHART (match ref_evolutions.png)
- Opened from an "EVOLUTIONS" button in My Trainers. A wide panel with a gold border and hex background, title "TRAINER EVOLUTIONS" with gold underline.
- The selected trainer shown 5 times as shared tiles: BASE > IRON-BORN > BEAST-MODE > COLOSSUS > LIMITLESS, small arrows between, each on its tier background + VFX, "LV 1" on all.
- Under each tile in grey italic: FROM ROLLS · 3x BASE · 3x IRON-BORN · 3x BEAST-MODE · 3x COLOSSUS.
- No "???" (prompt 48).

4) MOTION (light)
- Tile borders get the slow travelling highlight (prompt 40). Tier VFX animate (fire flicker, lightning flash, rainbow ring turning). Selecting a tile: small pop. Pause all of it when the panel is closed.

TEST (phone + desktop): Agency, My Trainers with 2 pages, a selected BEAST-MODE trainer, a max LIMITLESS one, and the Evolutions chart. Each screenshot next to its reference. Short progress note in the vault.
```
