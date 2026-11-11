---
tags: [research, ui, vfx, pets, reference-study]
created: 2026-11-12
---
# Watch study - the 3D pet card and the egg hatch screen (12 Nov 2026)

Owner (12 Nov, 00:40): "look at Roblox 2026-11-11 09-44-53.mp4 in downloads, how does the pet 3d screen work?"
Source: the owner's own recording of a pet simulator (1920x1080, 60 fps, 92 s; game name not visible in the recording). Method: [[Brain/Methods/Reference study]], frames every 0.25-0.5 s.
**Everything under "How it is probably built" is worked out from the picture. The game's code was not seen.**

## What is on screen: the Pets window (13-23 s)
- The world behind is blurred and a little darker; the HUD is hidden.
- Left: a flat white panel (title, Team Power, a row of small pet tiles, Unequip All, counters). Ordinary 2D UI.
- Right: ONE tall pet card in the pet's rarity colour (blue = Common, green = Rare) with a soft glow of the same colour around it.
  - The card is seen in perspective: its top and bottom edges are not parallel, and the angle keeps changing a little, following the mouse.
  - When another pet is clicked the card SPINS around its vertical axis: at 21.1 s it is edge-on and you can see it has thickness; at 22.1 s its back is showing ("Select a Pet!" on blue).
  - The pet on the card is a real 3D model: it turns with the card, and its ears stick out past the card's edge during the spin (14.1 s, 15.6 s). So it is not a flat picture and not clipped to the card.
  - On the card: name, stars, rarity pill, weight, stat rows (Power x3, Egg Luck +3%), level bar, enchant slot, Unequip and Delete buttons. They tilt with the card, so they are drawn ON the card.
- Hovering a small tile shows a flat tooltip (name, rarity, x2, Level 1, 0%).

## What is on screen: the egg hatch (7.5-12 s)
| Time (s) | What |
|---|---|
| 7.4 | HUD hides, the egg is big in the middle, the world behind is blurred |
| 7.9-8.7 | a white ring expands from the egg; four-point sparkles at the screen edges |
| 8.4-9.7 | green glowing cracks grow over the egg; it wobbles more and more |
| 9.4-9.9 | a green light beam, the egg squashes to a bright green blob |
| 10.2 | white-green flash over the whole screen |
| 10.4-10.9 | the pet pops out of a burst of white rays; name and "1 in 10" under it; coloured confetti squares |
| 11.2-12.0 | rays fade, "Equipped 1 pet", the pet shrinks and flies down to follow the player |

## How it is probably built (Roblox)
1. **Blur behind:** a DepthOfFieldEffect on the camera with the focus set close (far things fully blurred), switched on when the window opens. A BlurEffect would also blur the card and the pet, and they stay sharp, so depth of field fits better. A dark ColorCorrection tint is added on top.
2. **The card is a real Part, not a ScreenGui:** a thin block held in front of the camera every frame (camera CFrame x a fixed offset to the right), with a SurfaceGui on the front (the stats UI) and one on the back ("Select a Pet!"). That is why it has true perspective and thickness.
3. **Tilt toward the mouse:** each frame the card's angle = a small amount (about 5-10 degrees) from the mouse position, smoothed with a spring.
4. **Spin on change:** click a tile -> tween the card 180 degrees, swap the content when it is edge-on, tween it back (or keep turning).
5. **The pet:** the real pet model, welded a little in front of the card, scaled to fit, with an idle animation. Being in the world, it is lit, turns with the card and can stick out past its edges.
6. **Glow:** a soft glow picture in the rarity colour on a slightly larger plate behind the card (or a neon rim plus bloom).
7. **The left panel and tooltip:** a normal ScreenGui, laid out so the right third of the screen is free for the card.
8. **Hatch:** the same trick: the egg and then the pet are real models held in front of the camera, world blurred. The ring, sparkles, rays, flash and confetti are 2D images in a ScreenGui placed over the model's screen position; the cracks are a second glowing texture faded in on the egg; the beam is a Beam or a neon part.

## Why it feels good
- One thing on screen has real depth and reacts to the mouse, so the whole window stops feeling like a flat menu.
- The card colour and glow tell the rarity before any text is read.
- The spin gives every click a response.

## For our games (TITAN ARC armour sets, MEGA BITE sharks, pets anywhere)
- Use it for the ONE hero object of a window (the selected set, shark or pet), never for lists.
- Phone rules still apply (Lessons note): depth of field and bloom are full-screen passes, so test on the cheapest phone and give a fallback (plain dark tint, no blur). Keep text on the card at 14 px or more as seen on screen; respect Reduce Motion (no mouse tilt, a fade for the spin).
- On phones there is no mouse: tilt from a slow idle sway or from the finger while dragging.
- A SurfaceGui close to the camera needs a high pixels-per-stud value or the text goes soft.
