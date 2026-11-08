# Prompt (overnight): import the new BMW M cars and the GT3 RS: super good quality, no bugs, real clusters

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works exactly like the earlier import prompts (the R8 / Bentayga / GT-R one and the 12C / SLS one): reuse their tools, routine, traps and notes (`Games/CityLegends/CLAUDE.md`: "New cars by Open Cloud", "Imports of 2026-11-08", `CarSwap`, `RimSwap`, `cluster_imports.py`)._

## How to work tonight (owner, 2026-11-08)
- **The owner is asleep and can't reply. You have all permission** to do everything, including importing the models into Studio yourself (Open Cloud / Import 3D), testing in Play and putting them in the game. **Don't ask anything:** decide, write the choice and why in `City Legends/City Legends.md`, and carry on.
- **Order:** if `New imports - R8s, Bentayga, GT-Rs, and doors on every new model.md` isn't fully done, finish it first (check the notes). Then these 9 cars, **one at a time**, each finished and checked before the next.
- **Super good quality and no bugs.** Take your time. If something can't be done without errors, **sacrifice it** (simplify that detail or keep that car on its old model) and write it at the top of the notes.
- Backups before every replacement (`OldCarModels` / dated in `ServerStorage`). Save the place, commit and push after each car.
- If the usage limit hits: finish the current car cleanly, save, push, and write **"Next: car N"** at the top of the notes.

## The new files (owner, 2026-11-08), in `Games/CityLegends/imports/importing cars/`
| # | File | In the game | Licence (from the file) |
|---|---|---|---|
| 1 | `2009_bmw_m5_e60.glb` | **replaces the model of `bnw_m5_e60`** ("Bavarica Werkz E60 V10") | CC-BY (credit "Galaxy Car Showroom") |
| 2 | `2011_bmw_e92_m3_gts.glb` | **replaces the model of `bnw_m3_e92`** ("Bavarica Werkz E92 V8"); keep its name, price and class | **CC-BY-NC-SA** |
| 3 | `2018_bmw_m4_coupe_f82_lci.glb` | **replaces the model of `bnw_m4_f82`** ("Bavarica Werkz F82") | **CC-BY-NC-SA** |
| 4 | `2022_bmw_m5_cs.glb` | **replaces the model of `bnw_m5_f90`** ("Bavarica Werkz F90") | **CC-BY-NC-SA** |
| 5 | `2019_porsche_911_991.2_gt3_rs_weissach_package.glb` | **replaces the model of `porsha_gt3`** ("Stuttgart 991.2 Track") | **CC-BY-NC-SA** |
| 6 | `2010_bmw_m6_convertible.glb` | **new car:** the convertible of the old M6, **"Bavarica Werkz E64 V10"** (E64 = its chassis code), next to the E63 V10 in its line (the E63 coupe keeps its old model) | CC-BY (credit "Galaxy Car Showroom") |
| 7 | `2013_bmw_m6_coupe_f13.glb` | **new car: "Bavarica Werkz F13"** (the next M6), in the M6 line after the E63 / E64 | **CC-BY-NC-SA** |
| 8 | `2025_bmw_m3_cs_touring.glb` | **new car: "Bavarica Werkz G81 Touring"** (the M3 estate), in the M3 line | **CC-BY-NC-SA** |
| 9 | `2025_bmw_m4_competition.glb` | **new car: "Bavarica Werkz G82"** (the new M4), in the M4 line after the F82 | **CC-BY-NC-SA** |

- **Names:** BMW cars use their chassis codes (owner's rule): never "M3", "M4", "M5", "M6", "CS", "Competition", "GTS" or "BMW"; Porsche never "911", "GT3", "RS" or "Weissach".
- **New cars:** a real price (rules from `Real car prices and harder cash.md`: new = dealer price, old = used), class / PI from real numbers, real wheelbase in `CarBuilder.REAL_WB`, drive type (the G81 Touring and G82 can be AWD; the others RWD), tow capacity if any (none of these tow); note them.
- A **replacement** keeps the same id, name, price, level and class, so owners keep their car.
- Add all 9 to `CarFinish.NEW` and the new-model systems (lamps, doors, wheels standard, design-change rules) where those exist.
- **Licence warnings** at the top of the notes: #2, #3, #4, #5, #7, #8, #9 are **NC (non-commercial)**: risky in a game that sells Robux; check part names for a racing-game rip. #1 and #6 are CC-BY (credit).
- **No logos anywhere:** no BMW roundel or M stripes logo, Porsche crest or lettering, on the body, wheels, calipers, steering wheel, seats, tyres or clusters. (The M-style tricolour stripe as a plain colour stripe is fine; no letters.)

## Clusters: the model's own, or the real one from photos
For **each** car, render the cluster close up first:
- **If the model's cluster is good** (sharp, readable, complete): keep it and **make it live** (needles / digital speed, RPM, gear, odometer, fuel).
- **If it's missing, blurry, broken or a flat unreadable picture: search the web for a clear photo of that exact car's real cluster** (e.g. "2009 BMW M5 E60 instrument cluster", "991.2 GT3 RS cluster"), from free-to-use sources where possible (Wikimedia Commons and similar). Save the photo in `Games/CityLegends/imports/refs/` with its source link and licence written in a `.txt` next to it. **Recreate it 1:1**: the same layout, numbers, needles, screens, colours, fonts as close as possible, warning lights, backlight glow, at the exact size and place in the dash, sharp and live, **with no maker logos** (blank or our own small mark). Put the photo next to your recreation in one picture for the owner.
- What each car's real cluster looks like (check against your photo):
  - **E60 M5:** analogue dials with a red needle style and a 330 km/h speedometer, an 8,250-rpm-style rev counter with the variable warm-up lights, a small screen in the middle;
  - **E92 M3 GTS:** analogue speedo and tacho with the M-style variable red line lights, a small screen;
  - **F82 M4 / F13 M6 / F90 M5:** black-panel analogue dials with digital centre screens (F90 has the newer digital-style cluster);
  - **G81 Touring / G82:** the curved digital screen with BMW's newest digital layout (our own text, no logos);
  - **E64 M6:** like the E60 M5's cluster;
  - **GT3 RS:** five round dials with the big centre rev counter (yellow / white face), the right-hand screen.
- Families can share a cluster only if the real cars share it (e.g. E60 M5 and E64 M6); never across different designs.

## Every car: super good quality, no bugs
### Exterior
- **No grey / white / untextured parts anywhere**: arches, under the bumpers, engine bay vents, door shuts, the boot, mirrors, grilles (the kidney-grille spot keeps its shape but no logo), diffusers, wings.
- Glossy clear-coat paint with proper reflections in the car's real colours; Customs paint covers every body panel and nothing else.
- **Carbon** that looks like carbon (the GTS / CS / GT3 RS roofs, wings, splitters), matte or gloss trim as on the real car, chrome only where real.
- **Glass:** dark tint you can see through; no milky or missing windows.
- **Grilles and vents** with real depth; no flat pictures.
- **Wheels** to the standard of `A million times better wheels (new models).md`.
- No stretched / blurry / low-resolution textures, no z-fighting, no floating or clipping parts; clean panel gaps.
- **Convertible E64:** the roof down (or up: pick the cleaner one, note it), the cabin finished all round since it's open.

### Headlights and tail lights
- **Headlights:** real lenses over detailed housings: the BMW **angel-eye rings** / LED strips in their real shapes, the Porsche's round lamps with the four-dot LEDs (our own shape is fine, no logo); glass that looks like glass; when on, they glow **in their proper place** with beams from the lamps (`Proper working headlights.md` / `CarLamps`).
- **Tail lights:** real shapes with depth (the BMW L-shapes, the Porsche light strip), dark red lenses off, red glow on, **brighter when braking**, **white reverse lights** only in reverse, **indicators** on the right side; never a flat red sticker.
- No light glowing through the body or from the wrong spot.

### Interior
- The real cabin colours and materials: leather with grain and stitching (the M-style tricolour stitching as plain colours), Alcantara, carbon, brushed metal, soft-touch plastics, carpet, roof lining; seats with real shape (the CS / GT3 RS bucket seats, the GTS roll cage if the model has one).
- **Dash and console:** every screen lit and readable, buttons with depth, vents with slats, the gear selector, the start button; no logos.
- **Steering wheel:** right shape, real materials, paddles where real, no logo on the hub (`HUB_PLATES` if moulded), turns with the steering.
- Pedals, mirrors, belts, door cards present and textured; the live cluster glowing softly at night; nothing see-through, missing or grey from the driver's seat or from outside.

### Doors
- Working doors like the others (`Scissor doors on the SVJ and SVJ 63 (cut properly).md` method, `tools/doors.py`): normal doors on all 9 (rear doors too on the 4-door E60 M5, F90 M5 and G81 Touring); painted jambs, door thickness and inner panels, **no holes** (check with `cull` and mode `holes`); a `Config.Doors` switch per car. If a car's doors can't be made perfect, leave its switch off and note it.

## Check every car before you say done
- Before / after renders (front 3/4, rear 3/4, side, top, the driver's seat, close-ups of each light, a wheel, the cluster); the part list before / after (nothing lost).
- In Play: day and night, driving, the driver's seat, **the cluster matching the HUD** (speed / RPM / gear), all lights, doors, Customs paint, a phone-size screenshot; **no console errors**.
- Each recreated cluster next to its photo (with the source).
- Lune tests and `luau-lsp analyze` clean; FPS not worse.
- Save the place, commit, push; note it in `City Legends/City Legends.md` (credits, licence warnings, prices and classes of the new cars).

## At the end (top of the notes, short)
- every car: done / not done, its cluster (model's own or rebuilt from a photo, with the source);
- the new cars' names, prices and classes;
- licence warnings and credits;
- the sacrifices, and "Next: …" if anything is left.
