---
tags: [mega-bite, relay, ui]
created: 2026-11-12
---
# Relay to the "Shark game design ideas" chat (12 Nov 2026, 00:44)

From the owner, passed on by the video-editing chat. Two things.

## 1. Owner's note
The owner says this chat "has been switched to fable 5.2 high".

## 2. How the 3D pet screen works (for a shark screen in MEGA BITE)
The owner recorded a pet simulator and asked how its Pets window works. Full study: [[2026-11-12 Watch study - 3D pet card and egg hatch screen (owner recording 11 Nov)]] (Roblox Playbook, Research notes). Worked out from the frames; the game's code was not seen.

**What it is:** a flat inventory panel on the left, and on the right ONE hero card that is a real 3D object in front of the camera. It sits in perspective, tilts a few degrees toward the mouse, spins around when another pet is clicked, and the pet on it is the real 3D model. The world behind is blurred; the card and pet stay sharp.

**Probable build:**
1. Depth of field focused close to the camera (far = blurred), plus a dark tint, switched on when the window opens. A plain BlurEffect would blur the card too.
2. The card = a thin Part held in front of the camera every frame (camera CFrame x an offset to the right), SurfaceGui on the front (name, stars, rarity, stats, buttons) and one on the back.
3. Tilt = a few degrees from the mouse position, smoothed with a spring.
4. Spin = tween 180 degrees on a click, swap the content while it is edge-on.
5. The model = the real model welded slightly in front of the card with an idle animation; it may stick out past the card's edges.
6. Glow = a soft glow picture in the rarity colour on a slightly larger plate behind the card.
7. Egg hatch uses the same trick: the egg, then the pet, held in front of the camera; ring, sparkles, rays, flash and confetti are 2D images over it.

**For MEGA BITE:** use it for the ONE selected shark in the shark/evolution window, never for the list. On phones: depth of field is a full-screen pass, so test on the cheapest phone and fall back to a plain dark tint; no mouse there, so use a slow idle sway; text on the card at least 14 px as seen on screen; respect Reduce Motion (no tilt, fade for the spin). A SurfaceGui close to the camera needs a high pixels-per-stud value or its text goes soft.

Nothing here is a decision: the owner asked how it works, not to build it yet.
