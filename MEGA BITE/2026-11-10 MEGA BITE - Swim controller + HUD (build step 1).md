---
date: 2026-11-10
tags: [megabite, swim-controller, hud, ui-kit, camera, build]
status: built in the Mega Bite place (Studio), waiting for the owner's phone test + approval
---
# MEGA BITE: swim controller + HUD (step 1 of the build, 10 Nov)

Owner (10 Nov, 10:58): "yes start now, Quality > Quantity". Built to [[2026-11-09 MEGA BITE - Art style guide]] section 6 (UI kit first, swim controller before content). Scripts: `MEGA BITE\Scripts\swim_hud\` (exported from Studio).

## What's in the place
| Piece | Where | What it does |
|---|---|---|
| GameConfig | ReplicatedStorage.MegaBite.GameConfig | every number: 7 evolutions (cruise/top speed, turn deg/s, agility, grip, accel, SIZE, EXP, ability), swim, camera, zones, vents, quests |
| UIKit | ReplicatedStorage.MegaBite.UIKit | palette tokens + the 3 families only (COUNTER, BUTTON, TILE), our 16 icons, phone scale (designed at 844x390, scaled to the SAFE area) |
| ClientBus | ReplicatedStorage.MegaBite.ClientBus | HUD ↔ controller events (DART, ability, toasts) |
| Sharks | ReplicatedStorage.MegaBite.Sharks | the 7 approved models (copies of MB_ImportTest, DoubleSided, clips attributes) |
| MB_SwimServer | ServerScriptService | every player IS a shark (no Humanoid): builds the model + an invisible ball root, client network ownership, speed + position check every 0.5 s (snaps back cheaters), DART invulnerable window, abilities, quests, streaming-safe spawn, Studio dev evolve |
| MB_Swim | StarterPlayerScripts | the controller, the chase camera, and the animation of EVERY player shark |
| MB_HUD | StarterPlayerScripts | the HUD |
| BonePlayer | ReplicatedStorage.MB_Anim | + playback rate (Swim speeds up with speed) + spine bend for turning |

## How swimming feels (all tunable)
- **You swim only while you steer (owner 10 Nov):** let go of the stick/keys and the shark keeps gliding a bit (~3.5 s, ~25 studs) then hovers (Idle). Controls are camera-relative: W = away from the camera, S = toward the camera. If S points behind the shark (camera behind it) it is a BRAKE: stops in ~0.75 s with no turning; keep holding back after you've stopped = swim slowly backwards (0.4 x cruise, ~5 studs/s for the Minnow). If you look at the shark's face, S makes it swim straight at you and the camera holds that view (owner 10 Nov). Spawn is still too. While stopped you can look around freely (the camera doesn't swing back). Steering is camera-relative (like walking in Roblox): stick/WASD = direction, the camera swings behind the heading with a lag. Drag the screen (or right-mouse) to look; looking up/down makes you climb/dive.
- **Small = fast + twitchy, big = faster top speed + wide turns + more glide:** Minnow turns 240°/s, Megalodon 70°/s; top speed 24 → 42 studs/s.
- **Momentum + glide:** velocity bends toward the nose (grip per evolution). **Bank** into turns (up to 38°), the **spine bends** into the turn (code, not a clip), Swim clip speed follows swim speed.
- **DART:** 2.3x burst for 0.4 s, 2.2 s cooldown, 0.45 s invulnerable (server), camera FOV punch + tiny shake, Dart clip + whoosh for everyone.
- **World:** bounce off rocks (sphere + nose casts, 35% bounce, a bonk on hard hits, nose turns away), never stuck (if the body stops while pushing, it swings ~135° away), sea-floor clearance, surface ceiling, a soft push-back current from r345 to r400 that turns you home. Plants (kelp, sea palms, fans, branch/bubble coral, starfish) are swim-through; rocks, mesas, spires, brain/table coral and the floor use precise collision.
- **Chase camera:** aimed at the shark's body (not above it), distance 8 + 1.0 × body length, looks 12° down (owner 10 Nov: big sharks had the camera hovering high above); zoom with the wheel or a two-finger pinch, from right over the shark's back (0.12 × body length + 6 studs; Megalodon ~18 in practice; the camera is never allowed inside the body, owner 10 Nov) to 1.7 × the default, pulls in when a rock is behind you, returns to default when idle.
- **Controls:** phone = floating thumbstick (let go = stop), pinch to zoom, (left 42% of the screen, follows the thumb) + drag anywhere else to look + DART/ability buttons. PC = WASD/arrows, Shift or Space DART, F ability, right-drag look, wheel zoom. Gamepad = sticks, R2/A DART, X ability. Studio only: [ and ] change evolution.

## HUD (UI kit only)
- Top-left COUNTERS: SIZE (m), EXP (counts up + pop), CARRYING x/30 (grey in the Safe Reef, green in the Open Sea).
- Top-centre: NEXT bar ("NEXT: PIRANHA 0%", turquoise→green fill), QUEST panel under it (live distance in m), toasts below (pop + sound; zone changes, evolves, quest done).
- Top-right TILE: minimap (camera-up, you, vents, Safe Reef ring, border ring, N).
- Left: STORE button (gold) opens the shop (the shop's old button is hidden).
- Bottom-right: DART (biggest button, turquoise, cooldown veil + seconds) with the ability button above it (locked grey "FRENZY / AT PIRANHA" for Minnow, each ability in its own colour after).
- **Icons:** our own ChatGPT sheet (16 icons, magenta-keyed, `MEGA BITE\UI\icons`), uploaded to group 33151111: Size 95887839246654, Exp 103817562812853, Carry 98288386542647, Dart 93646244318779, Frenzy 121738459641180, Torpedo 132373164400986, Sense 130012192441199, Ram 129195683437390, Breach 124841181652402, Roar 110612895195097, Quest 86368454820402, Store 123194289459019, Vent 125941276679270, Index 125449104848178, Lock 119860308577741, Crown 71225619206466.
- **UIAudit (3 phone sizes):** iPhone 844x390 (safe 750x332), Android 640x360 (safe 600x302), iPad 1024x768: no overlaps, nothing off-screen. Smallest text ~14.5 px on the iPhone, ~12.6 px on the small Android (just under the 14 px rule there).

## Checked in Play (Studio)
Cruise, turning (yaw/bank/bend signs checked from top + side views), DART + cooldown, abilities (Tidal Roar on Megalodon), evolve swap Minnow → Reef Shark → Megalodon, border current, server snap-back (a client teleport was put back), no console errors.

## Still to do / known
- **Owner phone test** (the real feel pass: thumbstick size, camera distance, turn speed).
- Ability effects beyond the clip + VFX (damage/eat logic comes with the eating loop).
- The quest list has 1 quest; the real quest chain comes with the core loop.
- Next in order: food fish (~6 species via the sheet method) → eat/EXP/size/evolve → carry + bank → predators.

## Owner change (10 Nov, 15:03): car-style steering
- Cruising = gliding after you let go of W. A/D alone (or the stick pushed only sideways) now TURNS without adding speed, like a car's front wheels, while you glide; a stopped fish turns slowly (25%).
- Reversing (S after stopping) + A/D steers like a car in reverse: the TAIL swings toward A/D, the nose the other way.
- The turn is stronger the faster you move (GameConfig.Swim.CarTurnFrac 0.8, CarTurnMin 0.25). W + A/D still steers camera-relative.
- Tested: glide + A = turned left while slowing 24 -> 5; reverse at -5.1 + A = nose turned right, no speed change.
- (15:09) S toward the camera now follows the camera's tilt too: looking at the face from above, S swims up at you; from below, down. Tested: camera 30 deg above the face, S = straight at the camera, climbing at 30 deg, no turning.
- (15:12) Looking at the face, A/D alone (also standing still) turn the nose toward the SCREEN's left/right, the same side as when swimming with A/D (from the front the shark's own left is the screen's right, so the car steer flips). Tested: camera in front, A = nose swung to the screen's left.
- (15:15) Owner: "megalodon feels so laggy". Frame rate was the same 15 fps for Minnow and Megalodon in the test (Studio in the background), so the lag was the sluggish controls: big sharks now respond faster. Megalodon turn 70 -> 100 deg/s, agility 3.5 -> 6.5, grip 2.8 -> 4.5, accel 3.2 -> 5.0 (Great White 118/7/4.8/5.5, Hammerhead 135/7.5/5/5.5, Reef Shark 155/8/5.5/6, Barracuda 175/9/6/6.5). Tested: Megalodon 0 -> 38 studs/s in about 1 s, a 90 deg turn in about 1 s.
- **15:25 owner: "the camera is shaking and the tail is lagging" (big sharks) + "zoom inside the shark = first person".** Camera now smooths its OFFSET from the aim point (not its world position), aims with the controller's smooth yaw/pitch (no roll/physics wobble), and the not-inside-the-body push is a continuous solve (was 2-stud steps on the Megalodon). Measured as Megalodon while turning: camera jitter mean 0.38 → 0.03 studs/frame, worst 3.3 → 0.38. Tail: turn rate smoothed, spine bend scaled by 14/length (Megalodon 0.35x) and eased slower. **First person:** keep zooming in past the closest chase distance (wheel or pinch) → the camera sits at the shark's eyes, your own body is hidden (only for you), you look/steer with the camera; zoom out = back to the chase cam.
- (15:40) Owner: first person was too instant, make it like the Roblox camera. Zoom is now eased (never jumps). Wheel/pinch zooms normally down to the closest chase view (one stop notch there; the body starts to go 25% see-through as you get near it), then 3 more notches glide the camera INTO the head with the body fading 30% → 75%, and the last notch = first person (body hidden, only for you). Zoom out reverses it. Tested as Megalodon: the camera glides from 35 → 14 studs behind, then into the eyes over about 0.8 s.
