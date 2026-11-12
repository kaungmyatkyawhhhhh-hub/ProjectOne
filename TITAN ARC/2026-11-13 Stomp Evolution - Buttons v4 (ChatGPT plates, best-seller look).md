# Stomp Evolution - Buttons v4: ChatGPT plates in the best-seller look (13 Nov 2026, 01:40, autopilot)

Owner's feedback, in order:
1. On v2: "this is way better but u see in the references, they look completely different".
2. Then he invoked the ChatGPT art pipeline skill.

Reference: [[2026-11-13 Research - BuiltByBit best-selling Roblox UI packs (button look)]] (CloudMesh Studs UI Pack 2), studied zoomed in.

## What v2 got wrong vs the reference
| | Reference | v2 |
|---|---|---|
| Corners | almost square | rounded |
| Gradient | vertical (yellow-lime top → green bottom) | diagonal |
| Streaks | crisp slanted glass streaks "/ /" of different widths | soft shine band |
| Texture | Roblox stud "L" marks, faint | round studs |
| Lip | only a thin darker strip at the bottom | thick 3D lip |
| Text | Title Case in a round font ("Daily Rewards", "+5 Levels") | ALL CAPS LuckiestGuy |

## The ChatGPT prompt (one try, worked first time)
Create ONE image, 1536x1024, on a flat solid MAGENTA #FF00FF background (no gradient, no shadow on the background, no magenta anywhere in the art). An exact grid of 6 BLANK game UI buttons, 2 columns x 3 rows, each centred in its own cell with wide empty magenta space around it; the buttons never touch each other or the image edges. Every button is a wide flat horizontal rectangle about 3.5 times wider than tall, with only slightly rounded corners (a small corner radius, NOT a pill, NOT a capsule), seen perfectly straight on. Colours: TOP ROW left = lime green (bright yellow-lime at the top fading to vivid grass green at the bottom), TOP ROW right = purple (light orchid at the top to deep violet at the bottom). MIDDLE ROW left = golden yellow (lemon yellow at the top to warm orange at the bottom), MIDDLE ROW right = sky blue (bright cyan at the top to royal blue at the bottom). BOTTOM ROW left = cherry red (pink-red at the top to deep crimson at the bottom), BOTTOM ROW right = white (pure white at the top to cool light grey at the bottom). STYLE for every button, identical across all six: polished modern Roblox simulator shop UI; a crisp, even, thick near-black outline all around; a thin darker strip of the button's own colour along the bottom edge inside the outline so it looks slightly raised; a thin bright highlight line just inside the top edge; a smooth vertical gradient face; three or four soft semi-transparent white glass streaks of different widths slanting from bottom-left to top-right across the face; a very faint Roblox studs surface texture over the face (tiny embossed square studs in a regular grid, low contrast, subtle); clean flat-shaded vector game art, vibrant and saturated. The middle of every button is clear for text that will be added later. NO text, NO numbers, NO letters, NO icons, NO symbols anywhere. NOT a photo, no drop shadow, no perspective.

- ChatGPT chat: https://chatgpt.com/c/6af60b80-6188-83ec-9463-c31fd103f514
- Processed fully in the browser (no download):
  - magenta border flood-fill key with a 2 px soft edge and un-mix;
  - pieces found by coverage runs, cropped + 3 px;
  - checked on dark and light: no fringe;
  - handed to a Roblox tab with postMessage and uploaded there.
- The PNGs are not in the vault: the art never reached the workspace. They can be re-cut from the chat above.

## Asset table (each piece 657x208)
| Plate | ID |
|---|---|
| lime | 83013642250138 |
| violet | 138573152438183 |
| gold | 97764017501125 |
| sky | 121857646340424 |
| coral | 101562076458690 |
| white | 90802225121698 |

9-slice: SliceCenter Rect(30, 30, 627, 170), SliceScale = height / 208.

## Code (UIKit)
- `K.BtnPlates` now uses the v4 IDs; all inks are near-black (14,14,22).
- New `K.BtnLabel()` turns labels into Title Case: "PICK 1" → "Pick 1", "REFORGE   250" → "Reforge 250".
- Labels use `Enum.Font.FredokaOne` with a white→tint gradient, a 3.5 px black outline and a 2 px drop copy.
- The click ring corners went down to 0.08 to match the near-square plates.
- All motion and VFX are kept, and the icon spacing from v2 (no overlap) is kept.
- Checked in Play; saved as v75.

## Known limit
At phone sizes (44-58 px tall) the 9-slice scale is about 0.22, so the slanted streaks and the studs get faint. The idle sheen sweep makes up for part of it. If it reads too plain, ask ChatGPT for a SHORT plate (about 2.8:1) so less of the art is stretched.
