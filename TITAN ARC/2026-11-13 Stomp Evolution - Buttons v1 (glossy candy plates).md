# Stomp Evolution - Buttons v1: glossy candy plates (13 Nov 2026, 01:00, autopilot)

Owner, about the flat K.Btn3D pills (MY BUILD / LATER / PICK / REFORGE / AWAKEN): **"those ui's are very ugly"**.

## Why they looked bad
The Modern UI research note calls it "stone-age": flat plates, plain strokes and simple pills. Ours had:
- a flat 2-stop gradient;
- a thin lip;
- a navy outline on every colour;
- an ice-tinted title that looked washed out;
- a stuck-on shine strip.

## Fix
- **Plates drawn in code** (Pillow, 3x supersampled, 600x220), in `Art/UI/buttons_v1/`, preview `preview.png`. Each plate has:
  - a thick navy outline and a thick darker 3D lip;
  - a 3-stop face gradient;
  - an inner bottom shade and a top rim highlight;
  - a glossy band across the top third;
  - faint diagonal stripes;
  - 2 four-point sparkles (not a ray ring).
- I didn't use ChatGPT: another session was using the ChatGPT tab at the same time, and plain plates are cleaner and more consistent drawn in code.
- Text: solid white, outlined in a dark shade of the button's own colour (green ink on lime, brown on gold), not navy everywhere, plus a 3 px drop copy. The white plate gets slate text with a white outline.

## Asset IDs
| Plate | ID |
|---|---|
| lime | 106751242849864 |
| violet | 82311942647898 |
| gold | 82997998257270 |
| sky | 134609106602451 |
| coral | 94985997709007 |
| white (for grey) | 96429861662492 |

## Code
- `UIKit.K.BtnPlates` holds the plates. `K.Btn3D` picks the plate nearest the colour it's asked for.
- The image is 9-sliced: SliceCenter (95,60,505,150), SliceScale = height / 220.
- On press, the plate moves down 5% and dims.
- The return values are unchanged, so every click handler still works.
- The close X keeps its own image.

Checked in Play with all 5 buttons on a white card; no errors. Saved as v71.
