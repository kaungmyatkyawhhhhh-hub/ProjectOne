# Prompt (overnight): import the R8s, Bentayga and GT-Rs, then working doors on every new model: top quality, no errors, no grey parts

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works like the earlier import prompts (`New imports - 12C, SLS, SL65, 599, DBX, Continental, 350Z, 330i, trailer.md`, done): reuse their tools, routine and notes._

## How to work tonight (owner, 2026-11-08)
- **The owner leaves the PC on and gives you all permission to do everything**, including **importing models into Studio yourself**, testing in Play and putting them in the game. **Don't ask anything:** decide, write the choice and why in `City Legends/City Legends.md`, and carry on.
- **Do it properly, take your time.** One car at a time, finished and checked before the next.
- **No errors and no grey parts.** If something can't be done without errors, **sacrifice it** (drop or simplify that detail, or leave that car / door as it was) and write it at the **top of the notes**: what, why, and what it would take later.
- Backups before every replacement (dated, in `ServerStorage` and `imports/backups/`), so anything can be reverted. Save the place, commit and push after each car.
- **Order:**
  1. First finish anything still open from `A million times better wheels (new models).md` (wheels and driving) and `Scissor doors on the SVJ and SVJ 63 (cut properly).md` (check the notes; skip what's done).
  2. Then the 7 imports below.
  3. Then the doors on every new model (Part 3).
- If the usage limit hits: finish the current car cleanly, save, push, and write **"Next: …"** at the top of the notes.

# PART 1: the new files (owner, 2026-11-08), in `Games/CityLegends/imports/importing cars/`
| # | File | In the game | Cluster |
|---|---|---|---|
| 1 | `2010_audi_r8_v10_5.2_fsi_quattro.glb` | **replaces the model of `audy_r8`** ("Precision Type 42 V10"): keep id, name, price, level, class | photo 2 |
| 2 | `2011_audi_r8_gt.glb` | **new car:** the lighter track version of the first R8, above it in its line; fictional name like **"Precision Type 42 V10 Lightweight"** (never "R8", "GT" or "Audi") | photo 2 |
| 3 | `2016_audi_r8_v10_plus_coupe.glb` | **new car:** the second-generation R8; fictional name by chassis code like **"Precision 4S V10"**; its own line | photo 3 |
| 4 | `2023_audi_r8_coupe_v10_gt_rwd.glb` | **new car:** the last, rear-wheel-drive second-generation R8; name like **"Precision 4S V10 Finale RWD"**; top of the 4S line | photo 3 |
| 5 | `2018_bentley_bentayga_v8.glb` | **replaces the model of `bentlee_bentayga`** ("Sovereign Highlands"); it can tow (fit its hitch) | photo 1 |
| 6 | `2013_nissan_gt-r_black_edition_coupe.glb` | **replaces the model of `nisun_gtr`** ("Horizon R35") | the model's own (the owner says the GT-R cluster looks good: keep it, make it live) |
| 7 | `2017_nissan_gt-r_nismo.glb` | **new car:** the track GT-R; name like **"Horizon R35 Track Edition"** (never "Nismo" or "GT-R"); above the R35 in its line | the model's own (same as #6) |

- New cars: suggest price (real price rules from `Real car prices and harder cash.md`), class / PI, real wheelbase in `CarBuilder.REAL_WB`, the right drive type (the 2023 one is **RWD**, the others AWD); note them.
- Add every one to `CarFinish.NEW`.
- **Licence:** all 7 are Ddiaz Design **CC-BY-NC-SA (non-commercial)**: write the warning at the top of the notes (risky in a game that sells Robux; check part names for a racing-game rip).
- **No logos anywhere:** no Audi rings, "R8", "V10" plates, Bentley "B", Nissan or "GT-R" / "NISMO" badges, on the body, wheels, calipers, steering wheel, seats, tyres or clusters.

## Clusters: identical to the owner's photos (no logos), sharp and live
1. **Bentayga: `Games/CityLegends/imports/refs/bentayga_cluster_owner.webp`**
   - two big round dials with chrome rings on a black face: **left** the rev counter 0–70 (rpm × 100) with orange marks at the top end and a small **coolant gauge** (30–150 °C) inside it; **right** the speedometer 0–300 km/h (mph by our setting) with a small **fuel gauge** (0–1) inside it; long orange-white needles;
   - the **middle screen:** a row of small icons at the top (car, media, phone, globe, drive mode), "**Current speed**", the big digital speed with km/h, and the bottom line: the odometer, the range with a fuel icon, a seat-belt light, **P**, the trip and the outside temperature;
   - the **wood veneer** surround (burr walnut style) and chrome edges round the screen; **no Bentley "B"** (blank or our small mark).
2. **R8, first generation (#1 and #2): `Games/CityLegends/imports/refs/audi_r8_gen1_cluster_owner.png`**
   - two deep round dials with silver rings and a **red inner ring**: **left** the rev counter 0–10 (1/min × 1000) with red numbers from 9, warning lights inside it; **right** the speedometer 0–350 km/h; white-silver needles; a small dark screen at the bottom of each dial;
   - between them at the top: two small gauges (water temperature 50–130 °C and fuel ½); in the middle a small screen; small oil and volt gauges at the far sides;
   - **replace the "V10" and "R8" lettering** in the dials with nothing or our own small marks.
3. **R8, second generation (#3 and #4): `Games/CityLegends/imports/refs/audi_r8_gen2_cluster_owner.png`**
   - a wide **digital** screen: in the middle a round rev counter 1–10 with the red zone at 9–10, the big digital speed (km/h) and the gear (P), "READY" and the drive mode in red;
   - **left:** the media panel (a station / song list): use our own text ("Radio", a fictional station and song names, never a real brand like SiriusXM or real songs); **right:** the g-force / tyre display (a circle with four "0.0" values);
   - far left / right: the small temperature and fuel bars; along the bottom: the oil temperature, the clock, the outside temperature;
   - **no "R8" badge** in the middle (blank or our mark).
4. **GT-Rs (#6, #7):** keep the model's own cluster (owner: "it looks good"), make it live; redraw only if a part is blurry.

# PART 2: every car top quality (inside, outside, lights)
For each of the 7 cars (and the doors work in Part 3), all of this must be true before it's done:

### Exterior
- **No grey / white / untextured parts anywhere**: wheel arches, under the bumpers, the engine cover and engine bay (the R8 shows its engine under glass: make it look real), door shuts, the boot, mirrors, grilles.
- Glossy clear-coat **paint** with proper reflections, true to the car's real colours; Customs paint covers every body panel and nothing else.
- **Carbon** that looks like carbon (the R8 side blades, splitters, wings); chrome only where real; black trim matte or gloss as on the real car.
- **Glass:** dark tint you can still see through; no milky or missing windows.
- **Grilles and vents:** real mesh you can see depth through, never a flat picture.
- **Wheels:** the standard of `A million times better wheels (new models).md` (depth, brakes, tyres, our own sidewall text).
- No stretched, blurry or low-resolution textures; no z-fighting or flicker; no floating or clipping parts; panel gaps clean.

### Headlights and tail lights
- **Headlights:** real lenses over a detailed housing (projectors, reflectors, the daytime running light strips in their real shape: the R8's LED strip, the GT-R's boomerang lights, the Bentayga's round lamps), glass that looks like glass; when on, they glow **in their proper place**, with beams from the lamps (see `Proper working headlights.md`).
- **Tail lights:** the real lamp shapes with depth (LED strips / rings), dark red lenses when off, a bright **red glow when on, brighter when braking**, **white reverse lights** only in reverse, **indicators** flashing on the right side; never a flat red sticker.
- No light glowing through the body or from the wrong spot.

### Interior
- The car's **real cabin colours and materials:** leather with visible grain and stitching, Alcantara, carbon, wood (the Bentayga's veneer), brushed metal, soft-touch plastics, carpet, roof lining; seats with real shape and texture.
- **Dashboard and centre console:** every screen lit and readable (no blank grey screens), buttons and switches with depth, air vents with slats, the gear selector, the start button, cupholders; no logos.
- **Steering wheel:** right shape and size, real materials, paddles where the car has them, no logo on the hub; turns with the steering.
- **Pedals, mirrors, seat belts, door cards:** all there and textured.
- **The live cluster** (Part 1) glowing softly at night; a soft cabin light; nothing see-through, missing or grey from the driver's seat or from outside.

### Checks for every car
- Before / after renders (front 3/4, rear 3/4, side, top, the cabin from the driver's seat, close-ups of each light, a wheel, the cluster); the part list before / after (nothing lost).
- In Play: day and night, driving, the driver's seat, the cluster matching the HUD (speed / RPM / gear), all lights, Customs paint, a phone-size screenshot; no console errors.

# PART 3: doors that open properly on every new model
Do this for **every car in `CarFinish.NEW`** (all newly imported models, including the 7 above and the earlier imports), one car at a time, **using exactly the method in `Scissor doors on the SVJ and SVJ 63 (cut properly).md`** (if the SVJ doors are done, copy what worked):
- **If the model already has separate doors:** use them.
- **If not:** cut them out along the real panel gaps, build the **painted door frame** (jamb) and sill behind the opening, give the door **thickness** and an **inner door panel**, and keep the window (and the mirror where it's on the door) with it. **No holes, no see-through, no grey.**
- **The right door type and hinge for each car:**
  - **scissor** (up, hinged at the front): the Aventador family, Murcielagos, Countach, Revuelto;
  - **butterfly / dihedral** (up and out, slanted hinge): the 12C Spider;
  - **gullwing** (hinged at the roof): the SLS;
  - **normal** (outwards, hinged at the front): everything else, **including both LFAs** (owner, 2026-11-08: the LFA has normal doors, not butterfly) (Huracans, Gallardos, Urus, Ferraris, Bugattis, Maybachs, Bentleys, the DBX, R8s, GT-Rs, 350Z, 330i, Focus RS, SL65, 599, California, 458s...);
  - **rear doors** on 4-door cars and SUVs too (normal, hinged at the front); **boot / bonnet** only if they're already separate parts (otherwise leave them).
- **In the game:** smooth open / close (about 0.6–0.8 s), opening when getting in / out and with the door key / phone button when parked, closing when driving off, collisions off while moving, synced to other players, a door sound, Customs paint on the door and the frame.
- **Revert switch per car:** `Config.Doors[carId]`, off = the old model exactly as before; backups first.
- **Zero errors:** if a car's doors can't be made perfect, **leave that car's switch off** (sacrifice) and list it at the top of the notes with why.
- Per car: pictures of the doors closed / half open / open, close-ups of the jamb and inner panel, from outside and inside.

## At the end (top of the notes, short)
- every car: done / not done, with its cluster next to the owner's photo;
- the doors: which cars have working doors, which were skipped and why;
- the sacrifices;
- licence warnings and credits;
- "Next: …" if anything is left.
