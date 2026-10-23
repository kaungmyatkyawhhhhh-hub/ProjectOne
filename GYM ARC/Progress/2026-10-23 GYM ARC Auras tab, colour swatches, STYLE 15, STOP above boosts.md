---
date: 2026-10-23
tags: [gymarc, progress, ui, style]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Auras tab, colour swatches, STYLE 15, STOP above boosts

Prompt: [[2026-10-23 GYM ARC Prompt - Auras tab, alter colours, STYLE 15, STOP above boosts]]. Game commit ccbc060.

## Inventory > Auras
- Tiles in the Alters' premium style: 4 columns filling the space left of the detail panel (the rest scrolls), each aura's own dark themed background with faint rings, a thin outline in the rarity colour, the orb centred on a soft glow, the name white and stroked, the rarity word small in its colour.
- No EQUIP buttons on tiles: tap a tile to pick it, EQUIP / EQUIPPED is in the detail panel. Equipped = thin gold outline + small EQUIPPED tag. A tiny dot in the corner = the colour it wears.
- Not yours yet: a slim grey line with how to get it (e.g. "ALTER 5"); undiscovered: "???".
- Orb pictures: all 13 normal auras already use their own picture from `Downloads\gym_arc_transparent_icons\auras`. **Alike:** the 6 alter auras reuse other orbs (Peak Human = Ember, Stone = Frost, Metal = Storm, Gem and Legend = Golden, Elements = Titan), and Ember / Golden / Peak Human all read as yellow orbs. New art is needed for the 6 alter auras (and maybe a redder Ember).

## Colour swatches (auras and alters)
- The colour row is now small round swatches inside the detail panel only (ORIGINAL + each colour you own). Tap = preview, then the panel's button says WEAR <COLOUR>. Worn colour = a white dot in the swatch.
- Alters: the detail panel lays out top to bottom (icon, name, gains, tier line, swatches) with equal gaps; nothing overlaps the tier line. No owned colours = no row at all.
- Alter tiles: the gold check is gone; the worn alter has a thin gold outline + small WORN tag.

## PUMP SHOP > STYLE (15 on sale)
- NAME TAG (8): Violet 10,000, Ice 12,500, Fire 15,000, Mint 17,500, Gold 20,000 (solid); Sunset 60,000, Galaxy 80,000, Rainbow 100,000 (gradients).
- TITLE COLOUR (7): the same 5 solids + Sunset and Galaxy, same prices.
- Aura colours and alter tints are no longer sold. Owners keep theirs (they show as swatches in the Inventory detail and under YOURS in STYLE).
- Off sale (owners keep them): Crimson, Ocean, Lime, Tangerine, Bubblegum, Aurora, Candy, Royal. Fire is now a solid orange-red (it was a gradient): anyone who bought the old Fire now has the solid one.
- Tiles show your own name (title colours: your current title) written big in that colour; gradients slide slowly. Small upright section labels NAME TAG / TITLE COLOUR / YOURS in the row. Gradients can now have any number of colours (Rainbow = 6).

## STOP above the boost row
- The bottom-left boost row now reserves its height (player attribute `BoostRowHeight`); STOP (and EXERCISE above it) always sit 10 px above it, and move when the row grows or empties.
- Toasts are in the top centre lane and the Coach Dex dialog is bottom centre, so neither reaches that corner.

## Tested (Studio)
- PC: Auras tab (grid, EQUIPPED tag on Titan, ALTER 5 grey line, scroll); Looks > Alters (WORN tag, swatches under the tier line, tap ORIGINAL -> WEAR ORIGINAL; not worn, so the test account keeps its Crimson tint); STYLE tab (15 + YOURS); on the Flat Bench with 0, 3 and 6+ boosts ("+4" tile): STOP clear every time. No errors in Output.
- Phone 667x375 (touch layout): STOP sits above the thumbstick spot, clear of the boost row. 844x390 and tablet not checked separately.
- New Studio-only test hook: Workspace attribute `TestUIBus = "OpenInventory:Auras"` opens any window (players can't use it).
