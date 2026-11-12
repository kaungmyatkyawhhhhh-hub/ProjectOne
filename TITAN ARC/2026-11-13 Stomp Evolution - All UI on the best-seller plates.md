# Stomp Evolution - all UI on the best-seller plates (13 Nov 2026, 02:49-03:30, autopilot)

Owner, showing the Buttons v4 picture (ChatGPT plates + icons that poke out + Title Case round font): **"i mean for all the ui's, like these ones look good"**.
- Reference: [[2026-11-13 Research - BuiltByBit best-selling Roblox UI packs (button look)]]
- Plates: [[2026-11-13 Stomp Evolution - Buttons v4 (ChatGPT plates, best-seller look)]]

## How (changing the kit = changing every UI at once; backup `ServerStorage.UIKit_preAllPlates_13Nov`)
- **`K.PlateFor(color)` / `K.SetPlate(img, color)`:** the nearest of the 6 ChatGPT plates (lime, violet, gold, sky, coral, white).
- **`K.Card` is now a 9-sliced plate:** SliceCenter (30, 30, 627, 170), SliceScale = height / 208 clamped to 0.13-0.34. It returns (holder, body ImageLabel). `slab` and `radius` are ignored.
  - This changes the quest card, quest reward pill, COMING NEXT tiles, toasts, height tags, evolve card ("You Evolved!" sticker + BRAWLER!), lock badges and the upgrades card.
- **`K.Sticker`:** a small plate with Title Case FredokaOne and a black outline ("Next Up!", "Upgrades", "Height").
- **`K.Square`:** a plate; the icon is big and pokes out of the top; Title Case label (TALENTS → "Talents").
- **Fonts and outlines:**
  - `K.Big` uses FredokaOne with a black outline (was LuckiestGuy + navy);
  - `K.Body` is FredokaOne (was GothamBlack);
  - `K.Track` has a black outline.
- **Toasts:** the extra gradient on the body is removed (it would tint the plate).
- **SE_Upgrades price pills:** use `K.SetPlate` (lime / white / gold MAX).
- **TalentUI:**
  - windows are the white plate (no parchment), with the title as a K.Sticker in the window colour; window text uses FredokaOne in dark navy;
  - MY BUILD tags are plates: owned = the family colour plate with white outlined text; not owned = a faded white plate; locked Advanced = a faded gold plate;
  - the kid hand cards are plates in the family colour, with a white plate strip for the line and the rarity as a K.Sticker.
- **QUAKE's colour is now coral red** (245, 70, 80), so its plate is red and doesn't clash with GREED's gold.

## New family icons (ChatGPT, one try)
Prompt: 4 icons in a row on magenta. A red/orange boot stomping with impact lines and cracked ground; a gold coin stack with a sparkle; a sky-blue winged sneaker with speed lines; a green sprout with an up-arrow. Glossy 3D cartoon, thick near-black outline, no badge behind. Chat: https://chatgpt.com/c/6af620f4-54e8-83ec-bf5d-da0d23f30776

Keyed and cut in the browser, then uploaded through a Roblox tab (postMessage).

| Family | Icon ID |
|---|---|
| Quake | 94810581165522 |
| Greed | 98363583092365 |
| Stride | 78215721281151 |
| Growth | 99074864807034 |

They replace the sepia medallions in `C.CardArt`.

## Bugs found and fixed
- **Height counter lost its " m":** the self-sizing label kept TextWrapped on, so " m" wrapped onto a hidden line. TextWrapped is now false for every AutomaticSize X label in StompClient.
- **Fresh images showed blank plates/icons for a few seconds:** new `StarterPlayerScripts.SE_Preload` preloads every plate, K.Img icon, card art and the sparkle at startup.

Checked in Play: the HUD, the MY BUILD window, the evolve card and the hand. Saved.
