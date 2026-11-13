# Prompt: import the 4 new Audis (RS6 Avant, RS6 Avant GT, RS7 Sportback, R8 LMS Ultra): top quality, no errors, realistic exhaust sounds

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works exactly like the earlier import prompts (e.g. `Finish the 7 waiting imports (E60, E92, F82, F90, GT3 RS, Bentayga, GT-R).md`): reuse their tools, routine, traps and notes (`Games/CityLegends/CLAUDE.md`). Sounds work like `Realistic exhaust sounds for the supercars (real engines).md`._

## What the owner wants (2026-11-13)
"I pushed a new car file and that car will be imported to the game. Make the car very good without any error, and also insert realistic exhaust sounds for it too."

## The files (owner, 2026-11-12), in `Games/CityLegends/imports/new_cars/Audi/`
All four are **new cars** (none is in the game yet). Fictional names by chassis code (never "Audi", "RS6", "RS7", "R8", "LMS" or "Avant GT" as a badge word):
| # | File | In the game | Real engine (reference) | Sound character |
|---|---|---|---|---|
| 1 | `2020_audi_rs6_avant.glb` | **"Precision C8 Avant"** (estate), new line "PRECISION C8" | 4.0 **V8 twin-turbo** (hot-V), ~591 hp, AWD, redline ~6,800 | deep V8 burble, turbo whoosh, crackles in sport |
| 2 | `2024_audi_rs6_avant_gt.glb` | **"Precision C8 Avant Track"** (the limited track-styled estate), top of the C8 line | the same 4.0 V8 twin-turbo, ~621 hp | like #1, louder and rawer |
| 3 | `2020_audi_rs7_sportback.glb` | **"Precision C8 Sportback"**, in the C8 line | the same 4.0 V8 twin-turbo, ~591 hp | like #1 |
| 4 | `2012_audi_r8_lms_ultra.glb` | **"Precision Type 42 V10 Race"**: the race car of the first R8, at the top of the Type 42 line (a track car: race livery allowed, our own sponsor-free design) | 5.2 **V10 NA race engine**, ~570 hp, RWD, sequential gearbox | an open, very loud V10 race scream with straight-cut gear whine and hard shifts |

- Check the engines / power / redlines against a reliable source and fix any mistake.
- For each: a real price (`Real car prices and harder cash.md` rules: new = dealer price; the race car = its real value), class / PI from real numbers, real wheelbase in `CarBuilder.REAL_WB`, drive type, gear count, tow capacity (the C8 Avants can tow a bit: check if it's enough for the trailer; if not, no tow). Note them all.
- Add all four to `CarFinish.NEW` and the new-model systems (lamps, doors, wheels standard).
- **Licence:** all four are Ddiaz Design **CC-BY-NC-SA (non-commercial)**: write the warning at the top of the notes; check part names for a racing-game rip (the race car especially).
- **No logos anywhere:** no Audi rings, "RS" / "quattro" badges, sponsor logos on the race car (replace with plain colours or our own fictional marks), tyre brands, caliper lettering.

## Clusters
- Render each car's cluster close up first. Good → keep it and make it live. Missing / blurry / broken → **search the web for a clear photo of that car's real cluster** (free-to-use sources where possible; save it in `imports/refs/` with a `.txt` of the source) and **rebuild it 1:1** (layout, numbers, screens, colours, sharp, live, no logos).
- The C8 RS6 / RS7 use a wide digital "virtual cockpit" style screen (our own text, no logos); the RS6 GT and RS6 / RS7 can share one cluster. The race car has a race display (a digital dash with shift lights); make that live.

## Quality (no errors, no grey parts)
- **Exterior:** no grey / untextured parts anywhere; glossy paint with proper reflections; carbon that looks like carbon; dark glass you can see through; grilles with depth; clean panel gaps; no floating / clipping / z-fighting. The race car: its wing, splitter, roll cage and livery look right (our own livery, no sponsors).
- **Headlights / tail lights:** real lenses and housings, the LED strips in their real shapes; tail lights glow, brighter when braking, white reverse, indicators, all **in their proper place**.
- **Interior:** real materials (leather, Alcantara, carbon, metal), lit and readable screens, a proper steering wheel (no logo), pedals, belts, door cards; the race car: the bare race cabin with the cage, the bucket seat, the race wheel and switch panel.
- **Wheels:** to the standard of `A million times better wheels (new models).md`.
- **Doors:** working doors (`tools/doors.py`, the SVJ method): normal doors, **rear doors too** on the RS6 / RS6 GT / RS7; no holes. If not perfect, the car's `Config.Doors` switch stays off (note it).

## Realistic exhaust sounds
- Find sounds in the **Roblox Creator Store** (public, usable in any experience; never sounds ripped from other games); credit them.
- Match each engine (measure the firing note: a V8 fires at rpm / 15 Hz, a V10 at rpm / 12): **twin-turbo V8** for the three C8 cars (one shared set, the GT a bit louder), **NA race V10** for the race car.
- Start-up, idle, smooth rising revs to the real redline, louder under load, quieter overrun with **crackles / pops** where the real car has them, turbo whoosh / flutter on the V8s, straight-cut gear whine and hard sequential shifts on the race car, the limiter bounce; quieter inside the cabin and far away. The Workshop's exhaust parts still change it.
- All ids and settings in `Config` (`Config.ExhaustBands` etc.).

## No errors
If anything can't be done cleanly, leave it out (or keep that detail simpler) and write it at the top of the notes.

## Check every car before you say done
- Before / after renders (front 3/4, rear 3/4, side, top, the driver's seat, close-ups of each light, a wheel, the cluster); the part list (nothing lost).
- In Play: day and night, driving, the cluster matching the HUD, all lights, doors, Customs paint, the sound (start, revs, acceleration, lift-off, shifts, limiter), a phone-size screenshot; no console errors.
- Lune tests and `luau-lsp analyze` clean; FPS fine. Save the place, commit, push after each car; note it in `City Legends/City Legends.md` (names, prices, classes, credits, licence warnings).

## When done, tell the owner (short)
- the 4 cars with names, prices and classes, and screenshots;
- which clusters were rebuilt from photos;
- the sounds used (credits);
- licence warnings.
