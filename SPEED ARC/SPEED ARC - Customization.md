---
date: 2026-10-28
tags: [speedarc, customization]
status: living document
---
# SPEED ARC - Customization

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · [[SPEED ARC - Game Design Document|GDD]]

## Why
Showing off is a big reason kids keep playing. Customization = collection goals + a reason to spend coins (and some Robux) without pay-to-win.

## Rules
- Works on top of the player's own Roblox avatar (we never replace it). Our items are simple, light meshes in the palette.
- Each item: owned forever, equip/unequip in the LOCKER window, preview before buying.
- Stats: only SHOES and TRAILS give (small) boosts. Everything else is cosmetic.
- Locked items visible as silhouettes with how to get them (never hidden).

## The LOCKER (one window, tabs)
| Tab | What | Sources |
|---|---|---|
| SHOES | 10 pairs (GDD 11) + colourways for each pair (3 colours unlock after owning the pair, coins) | Shoe Shop (coins), Legend Laps, events |
| KITS | running outfits: tops (tank, tee, long sleeve), shorts/tights, all in palette colourways; a league kit for each league (earned on Go Pro) | coins, Go Pro, events, VIP kit |
| HEADWEAR | headbands, caps, sweatbands, sunglasses (sport shades), visors | coins, quests, events |
| BIB | your race number on your chest (choose 1-999), bib colour by league; gold bib for World Champions | free number, colours unlock |
| TRAILS | GDD 13 | Trail Booth, passes, events, Legend |
| WIN POSE | what you do on the podium / after a 1st place (8 poses: arms up, point to the sky, bow, flex, wave, kneel, salute, spin) - original poses | wins milestones (10/50/100 wins), events, a pass later |
| FINISH EFFECT | effect when YOU cross the line first (gold burst, blue lightning, confetti storm, fireworks) | medals milestones, events |
| NAME STYLE | name tag colour/gradient (blue, gold, black-gold, ice...) | coins (long goals), VIP |
| TITLE | equipped title | earned |

## Prices (coins, long goals) - tune with the economy
- Shoe colourway: 25% of that shoe's price. Kit pieces: 5-30 min of coins at your league. Headwear: 5-20 min. Name styles: 60-180 min. Event items: event only.
- Robux: only the Trail Pack, VIP (VIP kit + VIP trail + VIP name style) and (later) a Style Pack. Never stats beyond what coins can buy.

## Profile showcase
- The profile shows your equipped look in a small 3D view (ViewportFrame of a simple dummy with your items, built once), your best medals, top coach, favourite trail.

## Performance
- Each worn item = 1 mesh (no layered clothing). Kits = Roblox shirt/pants templates or simple meshes over the avatar.
- Other players' cosmetics far away: hidden past ~80 studs (trails) / 150 studs (meshes).

## Build order
M2: shoes + trails (+ the LOCKER window with those 2 tabs). M5: kits, headwear, bib, name styles. M7: win poses, finish effects.
