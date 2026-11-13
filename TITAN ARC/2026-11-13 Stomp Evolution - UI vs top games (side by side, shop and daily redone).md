---
date: 2026-11-13
game: Stomp Evolution
build: v141
tags: [titanarc, ui, reference-study]
---
# Stomp Evolution: UI next to the top games, Shop + Daily redone (v141)

Owner: "but our ui is worse than the top game uis", then "Yes, do it" (the full side by side + redo).
Method: [[Reference study]] + [[Best UI method (skill draft)]]. Reference videos: [[2026-11-13 Watch study - Claude Roblox UI method TikToks]].

## Real screens studied (YouTube gameplay frames in the browser, 13 Nov top chart)
Top 30 by players on 13 Nov: Steal An Egg 717K, Blox Fruits, Throw Food For Animals, Brookhaven, MM2, Adopt Me, RIVALS, 99 Nights, Break and Steal an Egg, Anime Adventures, Fish It!, ... Tap Simulator REBORN #20, Bee Swarm #29.

| Game | Screens seen | What they do |
|---|---|---|
| Tap Simulator REBORN (guide video) | Shop (Passes tab), Pet Index, Pets, Filters | Shop fills ~95% of the screen; tab bar; **sections with a header row** ("Hatching 6/6 owned", a grey line on the right); **every card a different full colour**, big icon, name, a dark stat pill, Owned / Active, a "BEST DEAL" corner ribbon; bundles as wide cards |
| Throw Food For Animals | Food Shop, Index | dark body, magenta title bar; tall cards in the rarity colour, big art, name + rarity, "Tier 7" pill, EQUIP / price pill; Index: rarity tiles, silhouettes, a progress bar "Unlocked 43/164" |
| +1 Venom Evolution | ability shop, Evolve window | slate cards with a coloured tier letter in the corner, big art, cost line; Evolve = current form → next form with an arrow, level / wins chips, big green Evolve + Skip with Robux |
| Steal An Egg | shop cards | huge item art on a rarity gradient card (grey Common, magenta Epic), stat in a dark pill, a green price pill + a purple Robux pill |
| Pet Simulator 99 | crafting / bank windows (small) | white panels, coloured title tab, red round X |
| 10 Nov top-50 notes | one shot per game | [[2026-11-10 Research - Top 50 Roblox UIs]] |

Bing "<game> shop ui" image search was useless (fan-made remakes, script ads): see the Lessons entry.

## Gaps found (ours v139 vs them)
| Gap | Ours before | Top games |
|---|---|---|
| Window body | bright blue stud plate everywhere, items blend in | plain body (dark navy or white), items pop |
| Shop | 45% of screen width, cream cards with a coloured top, small grey text, cut-off second row | 65-95% width, sections with headers, full colour cards, big art |
| Daily | 7 identical coin icons, ~1/3 of the window empty, tiny grey footnote | each day its own picture, the big day stands out |
| Ornaments | stone footprints floating outside the window corners | nothing hanging off the frame |

## What changed (v141, saved, not published)
- **Every window** (`TalentUI` `window()`): the stud plate stays as the rim only; a plain white-to-ice inner panel covers the middle (created first, ZIndex 1, so callers' content sits on top). The two footprint stickers are gone. Windows sit 34 px lower, so the HEIGHT counter stays readable above them.
- **Shop** (`SE_Meta`): 980x520 (phone 740x340 × 0.8).
  - Two sections: **Passes** (header + a "3/3 owned" chip + "Yours forever") and **Boosts** ("Grow faster for a while").
  - Every card is a full colour plate: big art at the top, a white outlined name, a white outlined line, and one pill (green "R$ 39", or grey "✓ Owned").
  - PASS chip; a "Best Deal" sticker on the Starter Pack until it's owned.
- **Daily** (`SE_Meta`): "Daily Rewards", 880x350.
  - Each day is a plate: today gold with a swaying "Today!" sticker and a slow pulse; claimed days green with a big check; future days white.
  - The coin pile grows day by day (a second coin from day 4), potions on Mass days (small/medium/big by minutes).
  - Day 7 is a wide violet card with the chest + "Big Prize!".
  - Bigger header text; the footnote is now 15 px.
- **Codes:** window 40 px shorter (less empty space).
- Index, Top and Talents are unchanged apart from the new window body. Checked Index and Codes: both read fine.

Backups: `ServerStorage.UIKit_preTopUI_13Nov`, `TalentUI_preTopUI_13Nov`, `SE_Meta_preTopUI_13Nov`.

## Checked / not checked
- Checked in Play on PC (1914x860): Daily, Shop (both sections), Index, Codes. Console: no script errors.
- Phone sizes are worked out by numbers only (SMALL = 0.8 scale): the Shop is 592 px wide, which fits 667 px (SE) and 800x360. Small-screen shop cards made taller so the line doesn't touch the button. **Not seen on a real phone or the emulator.**
- Quality-nerd kid sim not run on the new screens.
- Still below the top games: the Index has no progress bar or rarity colours; the Top and Codes windows are plain boxes; there's no shop tab bar.

## Part 2 (v144, saved, not published): Index, Top, Codes + studs no longer stretched
Owner: "Yes, do those", then mid-way: "also the stud texture that ur using rn is being stretched out".

- **Studs fixed (UIKit `K.PlateBody`):**
  - The ChatGPT plates were one wide picture with the studs and streaks baked in. 9-slicing it onto tall cards and big windows stretched the studs into tall rectangles.
  - Now every plate is built in code: a darker lip behind, a gradient face, a black outline, a top shine, and two glass stripes (a gradient mask, so nothing pokes out of tilted stickers).
  - ONE stud picture repeats at a fixed size (ScaleType.Tile, a stud every 14-24 px depending on plate size, centred so no stud is cut). Same look at any size.
  - The stud tile was made in Python (`TITAN ARC/Art/UI/studs_v1/make_stud_tile.py`, `se_stud_tile_64.png`: white/black alpha only, so it takes any plate colour) and uploaded through the Studio MCP: id **119399151178327** (`K.Img.StudTile`).
  - Used by `K.Card` (cards, stickers, HUD squares, toasts), `K.Btn3D` buttons (the sheen is now a white rounded layer) and the window rim (rim without studs).
  - "White" plates paint near-white (238, 242, 250), not grey.
  - `K.SetPlate` recolours coded plates; the new `K.SetPlateExact` takes colours outside the 6-colour palette (bronze).
- **Index:**
  - Header: index icon, a **Found x / 23** bar and a stars chip ("0 / 69 stars = +0% Mass").
  - Tiles are colour plates: small props sky, mid props lime, big props gold, landmarks violet (+ a "Landmark" sticker), all 3 stars = gold + a "Done!" sticker.
  - Not found = a white tile with a black silhouette and "???".
  - The stars sit above the plate (they were hidden under it).
- **Top:** two colour boards ("Tallest Ever" sky, "Sumo Wins" coral) with an icon. #1 gold, #2 silver, #3 bronze plates, your own row lime, the rest plain white rows. "No scores yet. Be the first!" when a board is empty.
- **Codes:**
  - A white code box with the ticket icon and a green Redeem pill.
  - "Next Update: Harbour Giants" is a gold plate with the gift icon and outlined text.
  - The window is shorter.

Backups: `ServerStorage.UIKit_preStudTile_13Nov` (plus the `_preTopUI_13Nov` ones).
Checked in Play on PC: Daily, Shop, Index (with test finds set on my screen only), Top (test scores on my screen only), Codes. Console clean.
Not checked: phone sizes on the emulator, the upgrade price pills and the Auto toggle after the recolour change, the evolve card / Talents windows.
The gift icon (120035029588768) failed to download once in Studio and showed on the next run: an asset fetch hiccup, not code.
