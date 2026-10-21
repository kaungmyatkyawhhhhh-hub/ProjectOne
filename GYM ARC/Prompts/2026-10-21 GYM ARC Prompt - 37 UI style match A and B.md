---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 37 UI style match (chunky buttons + reward tiles)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Restyle the UI to match the approved mockups. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Keep every screen's layout, positions and sizes. Only the styling of the pieces changes.

Mockups (approved, made on screenshots of the CURRENT game) are in C:\Users\kaung\Downloads\gym_arc_ui_style_match\real\. The "before" screenshots are in C:\Users\kaung\Downloads\gym_arc_ui_current\. Open both and match the mockups.

Build it as 3 shared components in the UI Kit. Every screen uses them, with no one-off styling:

1) ChunkyButton (do this first; every button inherits it)
- Vertical gradient face (light at the top, deeper at the bottom), a 3-4 px dark outline (near black), a thick darker bottom edge (6-8 px, so it looks raised), a white highlight line on the top edge, LuckiestGuy text in white with a dark stroke.
- Variants: Red (ROLL, PLAY, REROLL, REP, OPEN GENETICS), Green (EQUIP, CLAIM, WEAR, USE, KEEP, OWNED), Gold (SHOP, VIEW AURAS, REROLL - FREE, TAP TO GROW, toggle ON), Dark (graphite with a grey outline: X3, AUTO, UNEQUIP, LATER, toggle OFF, COME BACK TOMORROW, SKIP, counters like "3 / 40"). Optional soft glow in the button colour on the main button of each screen only.
- Press: face moves down into the bottom edge, then pops back.
- Replace EVERY button in the game with this (EQUIP/EQUIPPED, CLAIM, USE, KEEP, REROLL, WEAR/WORN, Settings toggles, PLAY/SHOP/SETTINGS/NEWS, store prices).

2) RankBadge + ChunkyBar
- RankBadge: a small chunky square with the rank letter, outline, bottom edge and a soft glow. S gold, A silver, B bronze, C grey, D dark iron. Use it everywhere a rank shows (Physique Muscles, Genes, Genetics strip).
- ChunkyBar: dark hex track, dark outline, gradient fill with a top highlight, stroked text. Teal for progress/stamina, gold for LVL/pump/bonus, red for loading. The fill always equals the real progress (an empty bar shows no fill).

3) RewardTile (the trainer tile formula)
- Hex-mesh background tinted in the item's colour, 4 px outline in that colour + 2 px dark inner ring + soft outer glow, the art BIG (icon/swatch fills most of the tile), the name in white stroked chunky text, the rarity in its colour, a ChunkyButton at the bottom.
- States: owned (normal), EQUIPPED/WORN (gold glow + gold check badge + grey "EQUIPPED" button), owned-in-store (dimmed ~50%, small green OWNED button + check, never a big stamp), locked/undiscovered (dark, black silhouette with a rim light in the rarity colour, "LOCKED" or the unlock requirement as a small dark pill, "???" if undiscovered).
- Use it for: Inventory > Looks (Auras, Alters, Titles, All), Store > Auras (+ the other store tabs), the Trainers screens.
- Alters tiles use the alter's own banner background (the alter popup backgrounds) behind the whole tile and the skin swatch as a big circle.
- Titles tiles: a medal icon in the rarity colour on the left, rarity + name on the right.

ONE rarity colour table, used for text, outlines and tile tints everywhere:
Common grey #AAAAB2, Uncommon green #50D264, Rare blue #468CFF, Epic purple #AA50FF, Legendary gold #F5BE28, Mythic pink #FF5AC8, Eternal white #F0F0FF.

Fonts: only 2 in the whole game. LuckiestGuy for buttons, numbers, names, labels; the current italic font for screen titles, tabs and body text. Remove any third font (e.g. on "YOUR GENETICS" and tooltips).

Per-screen notes (see the mockups):
- Title: left column with even spacing, a soft dark backdrop behind it (no brown halo), PLAY red, SHOP gold, SETTINGS/NEWS dark, player strip as a dark tile with gold inner line.
- Loading: tip card above a full-width red loading bar, "LOADING MUSCLES" + gold %, dots under it, SKIP dark pill.
- Quests Daily: CLAIM green, rewards as stroked gold "+60", counters as dark pills, bars ChunkyBar, REROLL gold.
- Quests Streak: days 4 and 7 (DNA token days) are gold-outlined tiles with glow and a big DNA icon; the other days quiet dark tiles; claimed days dimmed with a green check.
- Store Auras: hero card with gold frame and big icon; owned auras dimmed with small OWNED; the one you can't own yet is the loud tile with its requirement pill.
- Genetics: keep the barbell plates. Stat strip as dark tiles with RankBadges, multipliers above x1 in gold, OVERALL tile gold-outlined, REROLL red (with "1 DNA TOKEN"), KEEP green.
- Physique Muscles: RankBadges, ChunkyBars, "MAX GROWTH SPURT REACHED" as a gold-outlined dark pill.
- Settings / Lifts / Genes are info screens: keep them quiet, only the toggles and rank chips change.

Order: ChunkyButton -> RankBadge/ChunkyBar -> RewardTile -> apply to Looks -> Store -> Streak -> everything else.
Test on a phone size. Screenshot each changed screen and compare with its mockup. Short progress note in the vault.
```
