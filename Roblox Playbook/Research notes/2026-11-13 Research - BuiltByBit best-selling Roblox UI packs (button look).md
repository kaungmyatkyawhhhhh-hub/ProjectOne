# Research: BuiltByBit's best-selling Roblox UI packs - what makes them look good (13 Nov 2026, 01:30)

Owner: "look at those ui packages that they sell, the ui's that they sell are so good". This was for the Stomp Evolution buttons. I only studied the look; I copied nothing from the packs.

## What sells most (BuiltByBit > Roblox > Graphics & UI, "Most popular")
| Pack | Creator | Price | Sales |
|---|---|---|---|
| Studs UI Pack 2 | CloudMesh | $14.99 | 806 purchases, 5★ |
| Studs UI Pack 3 | CloudMesh | $14.99 | 149 |
| Studly Pet - Animated Studs UI Pack | Legend Studio | $24.90 | 45 |
| Steal an Egg FULL Pack | VVANG UI | $26.90 | 22 |

Also seen: Huge Clean Stud GUI Pack (90 sales, 5★), Cartoony UI Kit 25+ Frames.

## The look (CloudMesh Studs UI Pack 2, studied zoomed in)
**Buttons**
- Rounded RECTANGLES with a small corner radius (about 13% of the height). Not pills.
- A thick near-black outline on everything.
- A diagonal gradient: light top-left to deep bottom-right.
- A faint stud texture across the face.
- A soft diagonal shine band, and a lighter bevel line on the top/left inner edge.
- Slight depth underneath.

**Text**
- Chunky white text with a thick black outline and a drop shadow.
- Numbers and highlights often use coloured gradient text (orange "+5", blue "+10", rainbow "0.01%").

**Icons**
- Big glossy 3D-style icons that burst out of their tiles or sit at the left of a button, tilted.
- The window header carries a huge faint watermark of its icon.

**Colour**
- Very saturated, with rainbow/multi-colour gradients on featured cards.
- The same colour family everywhere: red shop, lime buy, purple premium, gold value.

**Motion**
- The top packs sell "animated effects": hover, pop and sheen.

## Applied: Stomp Evolution buttons v2 (assets in `TITAN ARC/Art/UI/buttons_v2/`)
Plates drawn in code (`make2.py`, 600x200), with:
- the black 9 px outline and a bevel ring;
- the diagonal 3-stop gradient;
- studs on a 24 px grid;
- a diagonal shine band and a top gloss;
- a 16 px deep lip.

Asset IDs:
| Plate | ID |
|---|---|
| lime | 123149936324227 |
| violet | 92683045527392 |
| gold | 78779555641359 |
| sky | 113603677488504 |
| coral | 106836936626596 |
| white | 134083418278841 |

Code changes:
- All text outlines are now black (22,22,34), 3.5 px, with a white→tint gradient.
- SliceCenter (60,45,540,140), SliceScale = height / 200.
- Overlap fix: icon 1.05 x the height at x = 0.38h; the text starts at 1.05h.
- The click ring now has rounded-rectangle corners to match the plate.
- All v1 motion and VFX are kept: pop-in, sheen, twinkles, breathing, hover tilt, squash/spring, confetti burst.

Saved as v74.

## Next, if the owner wants the whole UI in this style
Use the same plates for:
- the HUD squares (TALENTS, lock tiles);
- the quest card and the window headers, with a big faint icon watermark;
- coloured gradient text for the numbers (coins, +10).
