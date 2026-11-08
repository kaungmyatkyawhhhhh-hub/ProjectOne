# Prompt: rear-wheel-drive cars slide more, and much more with traction control off

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **No errors** (if something can't be done cleanly, drop it and write it at the top of the notes)._

## What the owner wants (2026-11-08)
"Make the RWD slide more, and slide even more when TCS is off."

## NO errors (owner, 2026-11-08: "I don't want any errors")
- No console errors or warnings (server and client, PC and phone size, 2 players), no physics glitches (flips, flinging, jitter, cars sinking or sticking), no camera problems, nothing broken in other systems (races, drift scoring, police, traffic, trailers, wear / fuel).
- If any part can't be made to work without errors, **leave it out** and write it at the top of the notes (what, why).

## What's there now (check first)
- `Config.DrivingFeel` (or the block it lives in): `PowerOversteer = 0.6` ("traction control off: flooring it lets the rear step out this much more"), `TrailBrakeLoose`, `SquatGrip`, `StabilityAssist`, `TouchSteerAssist`, the drift assist, and the traction control setting the driving code reads (On / Sport / Off, or On / Off).
- First drive 4 RWD cars (e.g. the Z33, a F80, the F142 Speciale, the SLS / Supra), 1 AWD and 1 FWD car on a roundabout, the Grand Hairpin and an open car park, with traction control on and off, and write down how far the rear steps out now (a short clip or frame grabs).

## The change
**Only rear-wheel-drive cars** (each car's drive type in its data). AWD and FWD cars feel exactly as now.

### Traction control ON (default)
- RWD cars get a **little more** rear slip: flooring it out of a slow corner lets the rear step out a few degrees, then traction control catches it smoothly (a short cut in power, the TC light flickers on the cluster / HUD). Easy for new players: never a spin from normal driving.

### Traction control SPORT (if the setting has it; add it if not)
- A **clear slide** on power: the rear comes round 10–20°, you hold it with a bit of countersteer, TC only steps in if it goes too far.
- **Donuts in Sport too** (owner, 2026-11-08): from a standstill or slow speed, full steering lock + full throttle makes a RWD car spin round in a **donut** (smoke, rear tyres spinning), held as long as the player holds it; TC only stops it from turning into an uncontrolled spin at speed. Works on every RWD car with enough power (most sports cars, muscle cars, supercars); very weak RWD cars may only manage a slow one. Test it on a few of each.

### Traction control OFF
- **Much more slide:** a RWD car can **power-oversteer and drift**: full throttle in 1st–2nd (and 3rd on powerful cars) breaks the rear loose, wheelspin and smoke, long held drifts with throttle and countersteer, **donuts** from a standstill, power-slides out of every corner.
- How much depends on the car: **more power and less weight = more slide** (a supercar / muscle car slides easily; a heavy luxury RWD car slides slowly and lazily); tuned power (parts, engine swaps) slides more; drift tyres slide more, semi-slicks less; wet roads much more.
- Still **catchable**: grip comes back smoothly when you lift or countersteer; no snap spins out of nowhere, no slides at a steady cruise in a straight line.
- Lifting off mid-corner lets the rear rotate a little more (lift-off oversteer), braking into a corner more than now (`TrailBrakeLoose`).

### Assists and phones
- The keyboard / phone **countersteer help** still works (a little weaker when TC is off, off in "Pro"), so phone players can drift too.
- The drift scoring / drift cash keep working and reward longer, bigger RWD drifts.

### Show it
- The **TC light** on the HUD and on the car's live cluster (where it has one) flashes when TC is working, stays on when TC is OFF (like real cars).
- Tyre smoke, skid marks and the tyre screech follow the slide (from the rear tyres).

## Rules
- All numbers in `Config` (e.g. `RwdSlideOn`, `RwdSlideSport`, `RwdSlideOff`, power-to-weight and tyre factors), easy to tune; note old → new values.
- Races stay fair: TC off is the player's choice; check the PI / class doesn't need to change.
- Traffic, police and NPC cars unchanged.
- Works the same on PC and phone, and other players see the slides smoothly (no jitter).

## Check before you say done
- In Play, with the same 4 RWD cars + AWD + FWD, TC On / Sport / Off: before / after clips or frame grabs; **donuts in Sport and Off**; long drifts with TC off; no spins at a steady cruise; AWD / FWD unchanged; phone-size test with countersteer help.
- Wet road test (rain on): more slide, still catchable.
- No console errors; Lune tests and `luau-lsp analyze` clean; FPS fine.
- Save the place, commit, push; note it in `City Legends/City Legends.md` (the values and how to tune them).

## When done, tell the owner (short)
- what changed per TC setting;
- the clips / frame grabs;
- the 2–3 numbers to change if it slides too much or too little.
