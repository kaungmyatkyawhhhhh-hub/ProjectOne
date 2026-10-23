---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 47 Boosts bar, new icons, Agency, Trainers, Pump Shop, Pro machines

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Five owner requests in one run. Follow CLAUDE.md Speed rules. Mobile first (667x375 and 844x390). Black + gold chunky style and the prompt 37 components (ChunkyButton, pills, hex tile, rarity table, 2 fonts). Never undo the owner's manual Studio changes. Do them in order, save after each, and keep a checklist in the progress note.

UPLOAD RULE (account safety): list every image you will upload BEFORE uploading and wait for the owner's OK. Upload one at a time and stop at the first moderation problem. Never upload anything from Downloads\gym_arc_alter_preview_DO_NOT_UPLOAD\ and never asset 94284470299221.

1) ACTIVE BOOSTS IN THE BOTTOM LEFT (pet-sim style)
Mockup: C:\Users\kaung\Downloads\gym_arc_ui_style_match\real\boosts_bottom_left.png
- Every ACTIVE boost (drunk shakes, supplements, coconut water, passes with a timer, event boosts) shows as a small square tile in ONE row at the bottom-left corner, above the safe area. Remove the old active-boost display wherever it is now.
- Tile: ~50 px (scale on phones, never under 40 px), dark graphite, thin gold outline, the boost icon filling it, the time left under it in white stroked chunky text ("9:42", "0:41"). Under 1 minute: the timer turns red and gently pulses.
- Same boost drunk twice = ONE tile with a small gold "x2" tag on its top-right corner, not two tiles.
- Order: longest time left first. More than 6 = show 5 + a "+3" tile.
- HOVER (PC) / TAP (phone): the tile lifts 4 px with a gold glow, and an info card pops up above it: icon, NAME (white stroked), a gold pill with the effect ("+50% EXP"), then a small grey line "14:52 left · 2 stacked". It hides when the mouse leaves, or 3 s after a tap on phones. It never covers the tile itself.
- New boost: the tile pops in (scale 0 -> 1.1 -> 1) with a short sparkle sound. Ended: it shrinks away.
- The hotbar (boost slots, prompt 28b) stays where it is. This row is only for ACTIVE effects.

2) NEW BOOST ICONS
Folder: C:\Users\kaung\Downloads\gym_arc_boost_icons\ (transparent 512 PNGs): protein_shake, protein_powder, creatine, pre_workout, supplements, coconut_water, mass_gainer, elite_pre_workout, whey_isolate, bcaa.
- Use them EVERYWHERE that boost shows: the bottom-left boost row, hotbar slots, Inventory > Items, Coach Dex shop, PUMP SHOP, the Daily Streak bonus rewards, quest rewards, popups and tooltips.
- Map by item ID in one config table (icon per boost). Anything without a new icon keeps its current one; list those in the note.

3) TRAINER AGENCY + MY TRAINERS (new look)
- Build / finish the specs in prompt 27 (stand, odds display, ROLL/X3/AUTO bar, rarity-scaled roll reveal) and prompt 33 (trainer tile, levels, evolutions). Restyle all of it with the prompt 37 chunky components so it matches the rest of the new UI. Mockups: Downloads\gym_arc_ui_style_match\02_agency_roll_A.png and 02b_roll_closeup.png.
- MY TRAINERS (the TRAINERS side button): title "MY TRAINERS", pills "EQUIPPED 2/3" and "OWNED 6/50". Left: dense 4-wide grid of the prompt 33 tiles (rarest first, equipped ones with a gold check). Right: the detail card (big portrait on its rarity glow, rarity, name, LV in gold, boosts as stat pills, EVOLVE bar + gold EVOLVE button, quiet EQUIP/UNEQUIP). Same rotating border highlight as the Alters/Auras tiles (prompt 40 ANIMATIONS).
- Empty state: "NO TRAINERS YET" + a red "GO TO TRAINER AGENCY" button that TELEPORTS (fade, 10 s cooldown).
- Odds as percentages; Secret and Eternal show "???" until owned.

4) NEW PUMP SHOP PANEL
- One panel (prompt 31): tabs SUPPLEMENTS · GEAR · DNA LAB, in the new chunky style like the Store (prompt 40 mockups 01_store_A.png, real\store_auras.png).
- Item tiles: big new icon on a soft rarity glow, name (loudest text), the effect as a gold pill ("+50% EXP · 15 MIN"), price on a chunky green BUY button with the coin icon. Can't afford = button greyed + "Need 1,200 more". Owned gear = gold "OWNED" stamp.
- Champion gear tier: gold animated border (the rotating highlight).
- Selecting a tile shows a detail strip at the bottom: icon, name, what it does in one plain line, BUY x1 / BUY x5 for supplements.
- Buying: coin count tweens down, the item flies into the Inventory button, short purchase sound.

5) PRO MACHINES LOOK BETTER THAN NORMAL ONES
- Every Pro Gym machine (prompt 36) must be clearly nicer than its Starter version at a glance:
  - Black frame with a satin/chrome finish (Material: Metal or DiamondPlate where it fits), GOLD accents: handles, pins, weight-stack plate, end caps.
  - Gold plates on the barbells/racks (Starter plates stay their normal colours).
  - Black leather pads with gold stitching (a thin gold trim part).
  - A small black + gold "PRO" plate on each machine, and a faint gold underglow strip on the floor under it (one PointLight or SurfaceLight per machine, shadows off).
  - The machine's label/overhead says "PRO" in gold before the name.
- Keep it light: recolor/material swaps and a few simple parts on the copied models, no new heavy meshes, no shadows from the small parts. Check the Pro Gym still runs smooth on a phone.

TEST: phone + PC screenshots of: the boost row with 4 boosts and the hover card open, the hotbar and Inventory with the new icons, the Agency stand + a Legendary reveal, MY TRAINERS (with and without trainers), all 3 PUMP SHOP tabs, and a Starter machine next to its Pro version. Short progress note in the vault with the checklist ticked and anything you couldn't match.
```
