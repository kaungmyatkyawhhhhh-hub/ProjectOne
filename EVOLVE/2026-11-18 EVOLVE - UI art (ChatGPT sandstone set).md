# EVOLVE - UI art (ChatGPT sandstone set)

18 Nov 2026. The game's UI is now drawn with painted ChatGPT art instead of code-built Frames. The owner picked this in an A/B test (Figma vectors vs ChatGPT art), then asked for v2: "the texts are small and it could be ALOT better".

- Studio script: `StarterPlayer.StarterPlayerScripts.EvolutionUI`.
- Backup of the old code-built UI: `ServerStorage.EvolutionUI_backup_codeUI`.
- Files in this folder: `Assets/UI art/`
  - `pieces/`: the cut PNGs that were uploaded
  - `sheets/`: the raw ChatGPT images
  - `mockups/`: the A/B and v2 mockups
  - `scripts/`: the cut and compose Python
  - `chatgpt-prompts.txt`: the 4 exact prompts
  - `scripts/EvolutionUI.luau`: a copy of the final in-game UI script, in case the unsaved place is lost

## Style block (reuse for any new piece)
The piece list is in the prompts. This is the style part:

> chunky hand-crafted Roblox simulator UI, rims of carved warm sandstone and polished dark walnut wood, a thick dark brown outline around everything, deep chocolate-brown slightly glossy insides on panels, faint fossil and leaf etchings carved into the rims only, a soft cream highlight along the top edge of each piece, rounded friendly corners, consistent lighting from the top, clean vector-like painted finish. NOT a photo, NOT realistic, NOT 3D render.

The background colour depends on the piece:
- Frames go on magenta `#FF00FF` and are keyed by a border flood fill (`cut.py`).
- Icons and items go on black `#000000` (`icons.py`, `items.py`).

Ask for "ornaments only in the corners" so the frames 9-slice cleanly.

## Asset table
Insets are left, top, right, bottom in image pixels. SliceScale is in design points: the UI is a 720x360 design that a UIScale fits to the screen.

| Piece | rbxassetid | Size px | 9-slice insets | SliceScale |
|---|---|---|---|---|
| status plate | 85047550391207 | 859x250 | drawn whole (Stretch; the crest smears if sliced) | n/a |
| DNA pill | 129184827451314 | 529x215 | 175,70,60,70 | 0.19 |
| button green | 93568833703046 | 376x229 | 60,60,60,65 | 0.16 |
| button amber | 91232997575427 | 377x229 | 60,60,60,65 | 0.16 |
| close button | 120631533939054 | 236x247 | Fit | n/a |
| locked button | 113298329723372 | 248x247 | Fit (unused) | n/a |
| window | 136582912915809 | 564x373 | 70,115,70,75 | 0.56 |
| list row | 120415667377266 | 795x199 | 60,55,60,55 | 0.21 |
| progress bar | 82455533752749 | 810x119 | 50,45,50,45 | 0.19 |
| card brown | 79800944653271 | 452x591 | 90,90,90,90 | 0.21 |
| card gold (VIP) | 86374205025766 | 456x595 | 90,90,90,90 | 0.21 |
| card teal (consumables) | 99603068148329 | 459x592 | 90,90,90,90 | 0.21 |
| tab plaque | 75713343472009 | 906x229 | 130,70,130,70 | 0.19 |
| icon shop | 84740887022585 | | Fit | |
| icon diet | 122438632943803 | | Fit | |
| icon index | 137810853551545 | | Fit | |
| item brain | 117432550574038 | | Fit | |
| item hourglass | 74464036005413 | | Fit | |
| item cradle | 131960657761337 | | Fit | |
| item asteroid | 104163766579401 | | Fit | |
| item dna2 | 130457498968000 | | Fit | |
| item stopwatch | 132145357276404 | | Fit | |
| item crown | 95631665044809 | | Fit | |
| item moon | 109592388054789 | | Fit | |
| item skip | 82169164163750 | | Fit | |
| item jar | 125315930034398 | | Fit | |

Card mapping:
- DoubleDNA: dna2 on a brown card
- FastLife: stopwatch on a brown card
- VIP: crown on the gold card, shown first
- OfflinePlus: moon on a brown card
- Skip5 and Skip20: skip on a teal card
- DNAPack: jar on a teal card
- Upgrades: brain, hourglass, cradle; Extinction uses the asteroid

## Notes
- Upload batches of 26 timed out, so there may be duplicate images on the owner's account. Batches of 5-7 worked.
- Newly uploaded images can show blank for a few minutes while Roblox moderates them.
- Text sizes are phone points: body 13, names and prices 15-16, window titles 26.
