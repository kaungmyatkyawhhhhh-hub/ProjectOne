# Prompt (overnight): import the new McLaren, Mercedes, Ferrari, Aston, Bentley, 350Z, 330i and the trailer: clusters like the photos, super realistic, no errors

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works like `New imports - LFA, Maybachs, Countach.md` and the Lamborghini / Ferrari import prompts (done): reuse their tools, routine and notes._

## How to work tonight (owner, 2026-11-07)
- **The owner leaves the PC on all night and gives you all permission to do everything**, including **importing the models into Studio yourself**, testing in Play and putting them in the game. **Don't ask anything:** when a choice is needed, pick what fits the owner's rules, write the choice and why in `City Legends/City Legends.md`, and carry on.
- **You have a lot of time: do it properly.** Slow and careful beats fast. One car at a time, finished and checked (renders, Play test, fixes, re-test) before the next. No shortcuts, no "good enough".
- Before each car: pull from git. After each car: save the place, commit and push, and note it (with screenshots).
- Backups: the old model of each replaced car goes to a dated folder in `ServerStorage` before it's swapped.
- The Toolbox is allowed for small props / materials (scripts removed, no logos, credited).
- If the usage limit hits: finish the current car cleanly, save, push, and write **"Next: car N"** at the top of the notes.

## The new files (owner, 2026-11-07), in `Games/CityLegends/imports/importing cars/`
| # | File | In the game | Cluster | Licence (from the file) |
|---|---|---|---|---|
| 1 | `2013_mclaren_mp4-12c_spider.glb` | **replaces the model of `mclaran_12c`** ("Speedmark P11"); it's the Spider (convertible): rename to **"Speedmark P11 Spider"**, keep the id, price, level and class | photo 1 | CC-BY (credit Ddiaz Design) |
| 2 | `2014_mercedes-benz_sls_amg_black_series.glb` | **replaces the model of `bentz_sls`** ("Tri-Star Silber C197 Wingdoor") | photo 2 | **CC-BY-NC-SA** |
| 3 | `2009_mercedes-benz_sl65_amg_black_series.glb` | **replaces the model of `bentz_sl65bs`** ("Tri-Star Silber R230 V12 Track") | photo 2 | **CC-BY-NC-SA** |
| 4 | `2010_ferrari_599_gto.glb` | **replaces the model of `ferrara_599`** ("Rosso Rampante F141") | photo 3 | CC-BY (credit) |
| 5 | `2023_aston_martin_dbx707.glb` | **replaces the model of `astin_dbx`** ("British Vanguard Highland"); it can tow (check the trailer system's hitch spot) | photo 4 | **CC-BY-NC-SA** |
| 6 | `2010_bentley_continental_supersports.glb` | **replaces the model of `bentlee_contgt`** ("Sovereign Grand Tourer") | the model's own (see below) | **CC-BY-NC-SA** |
| 7 | `2006_nissan_350z.glb` | **replaces the model of `nisun_350z`** ("Horizon Z33", a free starter) | the model's own | **CC-BY-NC-SA** |
| 8 | `2019_bmw_330i_m_sport.glb` | **replaces the model of `bnw_330i_g20`** ("Bavarica Werkz G20 Sport", a free starter) | the model's own | **CC-BY-NC-SA** |
| 9 | `trailer.glb` | **the owner's trailer model:** swap it in for the stand-in "Legends Car Hauler" in the trailer system (`Prompts/Car trailers (SUVs with a tow hitch).md`) | no cluster | CC-BY (credit "3DE_Study") |

- A replacement keeps the **same id, name (except #1's "Spider"), price, level and class**, so owners keep their car. Add every replaced car to `CarFinish.NEW` (the new-model list), so it gets the new-model looks and rules.
- **Licence warnings** at the top of the notes for the owner: #2, #3, #5, #6, #7, #8 are **NC (non-commercial)**: risky in a game that sells Robux; Ddiaz Design files may also be ripped from a racing game (check the part names). #1, #4 and #9 are CC-BY (OK with credit).
- Fictional names only. **No logos or badges anywhere**: McLaren, Mercedes star / AMG, Ferrari horse, Aston wings, Bentley "B", Nissan, BMW roundel, on the body, wheels, steering wheel, seats, tyres, brake calipers and clusters.

## Clusters: identical to the owner's photos (no logos)
Recreate each **1:1** from the photo: the same layout, shapes, sizes, number fonts as close as possible, colours, needles, screens, warning lights and backlight glow, at the exact size and place in each car's dash, **sharp**, and **live** (needles, digital numbers, gear, odometer / fuel where shown). Where the photo has a maker's logo, leave it blank or put our own small fictional mark. Put each finished cluster next to its photo in one picture for the owner.

1. **McLaren 12C (Spider): `Games/CityLegends/imports/refs/mclaren_12c_cluster_owner.webp`**
   - a big round centre rev counter: a black face with white numbers **1–9** (×1000 r/min), orange-red marks from 8 to 9, an orange-red needle, a silver ring; a small orange **digital speed** ("0 MPH") low in the middle; the gear letter on the right edge (orange "N");
   - **left screen:** "HOME", the clock, **ODOMETER** and **TRIP** in miles, temperature, range, the seat-belt and lights icons;
   - **right screen:** **HANDLING NORMAL**, **POWERTRAIN NORMAL** (our drive modes), the **OIL**, **WATER** and **FUEL** bar gauges, the parking-brake and BRAKE warning lights;
   - the curved hood / housing shape with the silver trim.
2. **Mercedes SLS and SL65 (both use this one): `Games/CityLegends/imports/refs/sls_sl65_cluster_owner.png`**
   - two deep round dials with chrome rings and a brushed-silver centre: **left** speedometer 20–240 mph with the fuel gauge (½) and a lights icon; **right** rev counter 0–9 ×1000 with red from 8, and an oil / temperature sub-gauge; red needles;
   - the **centre screen:** **P R N D** with the current one highlighted, an "S" mode box, the digital speed ("0 mph"), the clock and the km/h line;
   - the **top bar** between them: the two indicator arrows and the shift-light / gear bar;
   - the brushed-aluminium panel behind; **no AMG lettering** (blank or our own mark).
3. **Ferrari 599: `Games/CityLegends/imports/refs/ferrari_599_cluster_owner.webp`**
   - a big **yellow** centre rev counter: black numbers **0–10** (rpm × 1000), red zone from about 9, a red needle with a silver hub, the **gear box** (orange "N", "auto") lower right; **no horse** (blank or our mark);
   - **right:** a black speedometer **20–360 km/h** (mph by our setting) with white numbers and a red needle;
   - **left:** the white LCD screen: the clock (23:36), the outside temperature, **SPORT** mode, two small round gauges (water and oil temperature), the fuel bar, "auto", the odometer and the mph readout;
   - the warning lights in their places (engine, battery, oil, fuel, seat belt).
4. **Aston Martin DBX: `Games/CityLegends/imports/refs/dbx_cluster_owner.png`**
   - a wide digital screen: two round dials with **red glowing faces** and white outer rings: **left** speed 0–220 mph with the digital speed in the middle; **right** revs 0–8 with the red line; **no wings logo** in the middle (blank or our mark);
   - the **middle panel:** "Mileage" with the trip (69.1 miles) and the total (2434): use the car's real odometer from the mileage system if it exists;
   - the **top line:** the date, the clock, **P**, **S+** mode, the outside temperature; the warning / assist icons along the bottom; the fuel and temperature bars on the far sides.
5. **Bentley, 350Z, 330i:** no photo: use **each model's own cluster**, made live, and redraw its numbers sharper if blurry. If a cluster is missing or unreadable, find a clear photo of that car's real cluster (Wikimedia Commons or another free-to-use source; save it in `imports/refs/` with its source) and recreate it 1:1 the same way. List any you couldn't do at the top of the notes.

## Every car: super realistic, without any errors
- **No grey / white / untextured parts anywhere, inside or outside.** Every part gets its real material and colour: paint, carbon, black trim, chrome, rubber, glass, lights, leather, Alcantara, wood, metal pedals, carpet, roof lining. Check every part in the parts list and in close-up renders from all angles.
- **Exterior:** glossy clear-coat paint (PBR), dark tinted glass you can still see through, real light lenses, tyres with sidewalls, rims with depth, discs and calipers, carbon that looks like carbon, no stretched or blurry textures.
- **Interior:** each car's real colours and materials; nothing see-through or missing; the cluster and screens glowing softly at night.
- **No errors of any kind:** no floating, clipping or gaps; wheels in the right place, turning and steering right; the steering wheel turns; doors right (**gullwing doors** on the SLS if separate, normal on the others; say if not separate); the **convertible roof** right on the 12C Spider (up or down: pick one, note it); lights in their **proper place** (headlights, tail / brake, reverse, indicators); correct size (real wheelbase in `CarBuilder.REAL_WB`); Customs paint works; no console errors.
- Everything in `Better car models and clean interiors.md` (Parts 1, 2, 2b, 3, 4) and its quality checklist. **No new sounds** (the owner sends IDs).
- Reduce triangles carefully only where needed (keep the shape, cabin and cluster detail).
- Because they're new models now, they also get the rules of the new-model prompts if those are done (`Lighting and car look like the Ghost Driver videos.md`, `Small design changes on famous new cars.md` with our own wheels, `Proper working headlights.md`).

## Check before you say done
- In Play, for each car: outside day and night, the driver's seat, **the cluster working** (speed / RPM / gear match the HUD), the steering wheel turning, doors, Customs paint, all lights, a phone-size screenshot.
- Each recreated cluster next to the owner's photo.
- Close-ups proving no grey parts, inside and out; before / after renders proving nothing was lost.
- The trailer: hitch, load, tow and unload with the new model; its lights work.
- The two starters (350Z, 330i) in the new-player pick.
- Lune tests and `luau-lsp analyze` clean; no errors; FPS not worse.
- Save the place, commit, push; note it in `City Legends/City Legends.md` (credits and licence warnings).

## When done (top of the notes, short)
- every car: done / not done, with its cluster next to the photo;
- licence warnings and credits;
- anything left and why ("Next: car N").
