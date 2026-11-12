# Stud icons + quest card (v3 UI pass) — 12 Nov 2026

Icon sheet made in ChatGPT ("Create UI Kit Image" chat), magenta key + border flood fill in the browser, cut, uploaded to group 33151111. All Approved.

| Icon | Asset id | Used for |
|---|---|---|
| coin | 77218101788959 | K.Coin (counter, quest reward, fly-to-counter) |
| height | 108984995587821 | K.UpArrow when Lime (HEIGHT plate) |
| crown | 122936788312862 | crown holder's height tag |
| star | 111132681605873 | K.Star when Sky (reward sparkles) |
| lock | 114710128314234 | pad lock badges ("BE 3.00 m") |
| gift | 120035029588768 | spare (rewards later) |
| boot | 87226512186265 | spare (STOMP button later) |
| card | 75517196433924 | spare (TALENTS button later) |

## Code
- UIKit: `K.Img.Icon*` ids, new `K.Icon(parent, id, size, pos)` (ImageLabel, ScaleType Fit). K.Coin / K.Star / K.UpArrow return the icon and keep the drawn version as fallback.
- `K.UpArrow(..., drawn=true)` keeps the drawn arrow: the guide arrow points DOWN, and the height icon upside down looks wrong.
- Quest card: now the stud counter 9-slice (K.Plate), white text, dark bar, gold stud reward chip. Same family as the coins and HEIGHT plates.

## Checks
- Play test: icons load (AssetFetchStatus Success), no HUD overlaps at 1138x841, smallest screen text fine (only world billboards are small, which is distance scaling).
- Saved: version 52.
- Still open: a REAL phone test (Studio can't fake the viewport from a script), music by ear, high-quality props.
