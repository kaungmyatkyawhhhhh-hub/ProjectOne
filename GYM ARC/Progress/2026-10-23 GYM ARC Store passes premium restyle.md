---
date: 2026-10-23
tags: [gymarc, progress, store]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Store passes premium restyle (prompt 61)

Prompt: [[2026-10-23 GYM ARC Prompt - 61 Store passes premium restyle]]

Game commit 4f11665 (`StoreClient`; the premium pieces moved to `Shared/UI/PremiumKit`, shared with the Pump Shop).

## What changed
- **Tiles** (every Store tab uses the same tile):
  - A soft background in the item's colour, faint rings and a glow behind the icon, and a thin outline in its colour.
  - The colours: 2x EXP blue, 2x COINS green, VIP gold, AURA PACK purple, AUTO REP red, EXTRA TRAINER orange (was red).
  - The icon in the top part; the name under it, white and stroked, one line, never over the icon.
  - At the bottom, a slim graphite button with the Robux icon and the price. Auras show how to get them ("AURA PACK", "ALTER 5").
  - The picked tile gets a gold outline.
- **Owned:** full brightness and a slim dark pill with a thin gold outline and gold OWNED. The green checkmarks are gone everywhere in the Store (the old tile code isn't used by it any more).
- **Hero card (left)**, same premium look:
  - **What it shows:** on PASSES, a pass you don't own yet, most popular first (`Monetization.PopularPasses`: Auto Rep, 2x EXP, VIP, 2x Coins, Aura Pack, Extra Trainer; edit the order freely). When that pass becomes owned, the next one comes up. A pass you tapped yourself stays.
  - **All owned:** a gold star, "THANK YOU FOR SUPPORTING GYM ARC" in gold, "You own every pass." and a gold glow round the card.
  - **Card contents:** one title, the short description, then the red buy button (Robux icon + price) or a gold OWNED pill. BEST SELLER stays on Auto Rep.
- **Baked-in words cropped:**
  - Auto Rep's "AUTO" and VIP's "VIP" sat under the art, so they are cropped off in-game (`ART_CROP`, no re-upload).
  - The "2X" on 2x EXP / 2x Coins and the "+1" on Extra Trainer overlap the art, so they can't be cropped (see below).
- **Grid:** 3 x 2 equal tiles that fill the height exactly (no scrollbar, no holes).
- **COACH DEX and GO TO PUMP SHOP:** out of the grid. Two slim graphite buttons with the shop icon in one row across the bottom of the panel, under the hero and the grid, once the PUMP SHOP is open for you (as before).
- **Fixed on the way:** the hero's glow was on the same layer as the card and drew over it. The card now sits one layer above its glow.

## Tested (Studio, desktop 972x584 and phone layout 844x390)
- **All owned:** the test account owns every pass. THANK YOU, every tile OWNED, no scrollbar, the gold halo.
- **Nothing owned** (pass flags set to false on the client only, a test view): the hero on Auto Rep with BEST SELLER and the red 249; Robux prices on the tiles.
- **Some owned** (Auto Rep, 2x EXP, VIP): the hero moved on to 2x COINS; owned tiles in gold OWNED.
- **A tapped owned pass:** the hero shows it with OWNED.
- **Other tabs:** all 31 tiles are built (Coins / Boosts with Robux prices, Auras with OWNED / ALTER n / AURA PACK), none has a checkmark.
- No script errors (the Pump Shop loads with the shared pieces); the logic tests pass.

## Needs the owner
- **Aura Pack icon:** the uploaded icon (96266064858389) still has the dark square behind the orbs. The newer `pass_aura_pack.png` isn't in `Downloads\gym_arc_transparent_icons\shop\`. Put it there and OK an upload (or upload it yourself and give me the id).
- **Clean icon versions needed** (the text overlaps the art, so it can't be cropped): `pass_2x_exp` ("2X"), `pass_2x_coins` ("2X"), `pass_extra_trainer` ("+1"). These labels don't repeat the title, so they may be fine as they are. Your call.

## Not tested
- The Auras / Boosts / Coins tabs by eye (Studio's test clicks don't switch tabs); checked in code only.
- Buying a pass for real.
- 667x375 and tablet.

![[GYM ARC/Screenshots/prompt61/01_desktop_all_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/02_desktop_none_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/03_desktop_some_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/04_desktop_tapped_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/05_phone_all_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/06_phone_none_owned.jpg]]
![[GYM ARC/Screenshots/prompt61/07_phone_some_owned_before_fix.jpg]]
