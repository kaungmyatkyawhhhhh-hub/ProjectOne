# Prompt: import the new LFAs, the two Maybachs and the Countach (realistic, live clusters, no grey parts)

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works like `New imports - Murcielago, Urus Performante, Ferraris.md` and `Lamborghini imports.md` (done): reuse their tools and notes._

## How to work (owner, 2026-11-06)
- **The owner is leaving the PC on and can't reply. You have all permission** to finish everything **and to import** the models into Studio yourself (Import 3D or any way that works through the MCP), check them in Play, and put them in the game. Don't stop to ask: decide, note the choice and why in `City Legends/City Legends.md`, and carry on.
- If importing yourself truly can't work, leave the packs ready in `imports/new_cars/` and write the exact steps for the owner at the **top** of the notes.
- Keep backups (old models in `ServerStorage`, dated) before replacing anything. Save the place, commit and push after each car.

## The new files (owner, 2026-11-06), in `Games/CityLegends/imports/importing cars/`
| File | In the game | Licence (from the file) |
|---|---|---|
| `2011_lexus_lfa.glb` (217k tris) | **replaces the model of `lexis_lfa`** ("Stealth-Apex V10 Halo"): keep the id, price, level and class | Ddiaz Design, **CC-BY-NC-SA** |
| `2012_lexus_lfa_nurburgring_package.glb` (231k tris) | **new car:** the LFA's track version, above the LFA in its line; fictional name like **"Stealth-Apex V10 Halo Circuit"** (never "Nürburgring" or "LFA"); suggest price / class / PI and the real wheelbase | Ddiaz Design, **CC-BY-NC-SA** |
| `2021_mercedes-benz_s-class_maybach.glb` (293k tris) | **replaces the model of `bentz_s680`** ("Tri-Star Silber Z223 Royale V12") | Ddiaz Design, **CC-BY-NC** |
| `mersedes-_benz_maybach_gls_600.glb` (474k tris: reduce carefully) | **replaces the model of `bentz_gls`** ("Tri-Star Silber X167 Royale") | Black Snow, **CC-BY** (credit "Black Snow" in the credits) |
| `1985_lamborghini_countach_5000_qv_inaccurate.glb` (196k tris) | **replaces the model of `lambrini_countach`** ("Enfurecido Classico 400"); it's the 5000 QV, so rename it **"Enfurecido Classico 5000"** (keep the id) | Ddiaz Design, **CC-BY** (credit) |

- Also in the folder: `2018_ford_focus_rs.glb` (Ddiaz Design, **CC-BY-NC-SA**): the new starter car from `Better upgrade area and part shop.md`, Part 2. If that prompt is already done, do it there; if not, do it here with the same rules.
- **Licence warnings** for the owner, at the top of the notes: the LFA, LFA Circuit, S-Class Maybach and Focus RS are **NC (non-commercial)**: risky in a game that sells Robux; Ddiaz Design files may also be ripped from a racing game (check the part names). The GLS and the Countach are CC-BY (OK with credit).
- Fictional names only, no badges or logos anywhere (Lexus "L", Mercedes star, Maybach "MM", Lamborghini bull, lettering on the body, wheels, steering wheel, seats, tyres and clusters).

## Clusters (owner's photos)
### LFA and LFA Circuit: `Games/CityLegends/imports/refs/lfa_cluster_owner.png`
Both LFAs use this cluster: **recreate it 1:1** (same layout, sizes, fonts as close as possible, colours, glow), sharp, live, **no logos**:
- a big **round centre dial** with a thick silver bezel ring, dark blue-black face with fine tick marks, white numbers **0–10** (×1000 r/min) round the edge, a **red needle** sweeping the revs and a **red zone** from about 9 to 10;
- in the middle: the **digital speed** (big white number, "km/h" under it, use our units setting), the **gear** below it (big white digit, "N" next to it when in neutral), and "TRIP A" with two distance lines;
- on the **left**: a curved water-temperature bar (40–130 °C with the thermometer icon), the outside temperature (22 °C) and a curved fuel bar (E–1/1 with the pump icon);
- on the **right**: a curved oil-temperature bar (40–160 °C with the oil-can icon), the **clock** (12:56), and a curved oil-pressure bar (0–8 ×100 kPa);
- live: needle and red zone from the RPM, speed and gear from the car, fuel / temps can sit at sensible values that move a little, the clock from the game's time; backlit at night.
- (The real LFA's ring slides when you press a button: **not needed**.)

### Maybach S-Class and Maybach GLS: `Games/CityLegends/imports/refs/maybach_gls_s680_cluster_owner.png`
Both Maybachs use this cluster: **recreate it 1:1** on their wide screen, sharp, live, **no logos**:
- **left dial:** speedometer 0–260 km/h (or mph by our setting) with white numbers, a thin white needle with a chrome hub, a deep blue face with fine radial lines and a silver ring; small fuel bar and range under it; **leave out the Maybach "MM" logo** in the dial (blank or our own small mark);
- **right dial:** rev counter 0–6 ×1000/min with 5 and 6 in red, the same style; the coolant gauge under it;
- **middle:** the digital speed ("0", km/h) with small assist icons at the top, a **media tile** (a music note icon on a blue square with ◀ ▶) where the original shows Russian text: use our own English text ("Media") or a blank label;
- the bottom: the clock (12:06), outside temperature (24.5 °C), a "P" and the gear letters **R N D P** on the right with the current one lit;
- live: both needles, the digital speed and the gear; blue backlight glow at night.

### Countach: its own cluster
The Countach model **comes with its own cluster**: keep it, make it live (speed and RPM needles), and **make the RPM and speed numbers much more visible and sharper**: redraw the dial faces at high resolution with clear white numbers and tick marks on black, same layout as the model's own, so they're easy to read from the driver's seat and in close-up. No logos.

## Every car: very realistic, NO grey parts (owner, 2026-11-06)
- **No grey / white / untextured parts anywhere, inside or outside.** Every part gets its real material and colour: paint, carbon, black plastic trim, chrome, rubber, glass, lights, leather, Alcantara, wood (Maybachs), metal pedals, carpet, roof lining. Check every part in the parts list and in close-up renders from all angles (wheel arches, under the bumpers, engine cover, door shuts, seats, dash, roof lining, boot). Use `CABIN_RECOLOUR` / textures from real photos for anything that came in grey.
- **Exterior:** glossy clear-coat paint (PBR), dark tinted glass you can still see through, real-looking light lenses, proper tyres with sidewalls, rims with depth, brake discs and calipers, carbon that looks like carbon, no stretched or blurry textures.
- **Interior:** each car's real colours: the LFAs' dark sporty cabin with carbon and red / black leather; the Maybachs' rich two-tone leather, wood and chrome, quilted seats, soft ambient light at night; the Countach's period leather and simple dash. Nothing see-through or missing.
- Everything from `Better car models and clean interiors.md` (Parts 1, 2, 2b, 3, 4): PBR kept, clean interior, the quality checklist, doors (**scissor doors** on the Countach if separate; normal doors on the others; say if not separate). **No new sounds** (the owner sends IDs).
- Triangle budget: reduce carefully (the GLS is 474k): keep the shape, cabin and cluster detail; cut hidden parts first.
- Add all five to `CarFinish.NEW` so they get the new-model looks (and the headlight / lighting / design-change prompts' rules, when those are done).

## Put them in the game
- A **replacement** keeps the same id, name (except the Countach rename), price, level and class, so owners keep their car. The old model goes to a dated backup only after the new one works.
- The **LFA Circuit** joins the LFA's line above it, with a suggested price / class / PI (note them).
- Credits for CC-BY models in the credits / notes.

## Check before you say done
- In Play, for each car: outside day and night, the driver's seat, **the cluster working** (speed / RPM / gear match the HUD), the steering wheel turning, doors, Customs paint, tail lights, a phone-size screenshot.
- Each recreated cluster next to the owner's photo (one picture per cluster).
- Close-ups showing no grey parts, inside and out. Before / after renders prove nothing was lost.
- Lune tests and `luau-lsp analyze` clean; no errors; FPS not worse.
- Save the place, commit, push; note it in `City Legends/City Legends.md` (with credits and the licence warnings).

## When done, tell the owner (short, at the top of the notes too)
- the cars with names, prices and classes;
- the clusters next to the photos;
- licence warnings;
- anything you couldn't do and why.
