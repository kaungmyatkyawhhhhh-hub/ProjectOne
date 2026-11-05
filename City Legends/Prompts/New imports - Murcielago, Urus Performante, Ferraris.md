# Prompt: import the new Murcielagos, Urus Performante and Ferraris (realistic clusters)

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works exactly like `Lamborghini imports.md` and `Six Bugatti imports.md` (both done; reuse their tools in `tools/lambo/` and the notes)._

## The new files (owner, 2026-11-05), in `Games/CityLegends/imports/importing cars/`
| File | In the game | Family (share clusters / wheels only inside a family) |
|---|---|---|
| `2010__lamborghini_murcielago_lp650-4_roadster.glb` | the owner's replacement for the old Fast & Furious file (2026-11-05): a **Murcielago LP650-4 Roadster**. It **replaces the model of `lambrini_lp640`** (keep the id, price, level and class so owners keep their car; rename it in the game to a fictional "Enfurecido Murcielago LP650-4 Roadster" style name). Only 3.6 MB: check it's detailed enough (interior, cluster) and say so if not | Murcielago |
| `2010_lamborghini_murcielago_lp670-4_superveloce.glb` | **new car**: Murcielago LP670-4 SV (fictional Enfurecido name), above the LP640 in the Murcielago line | Murcielago |
| `2023_lamborghini_urus_performante.glb` | **new car**: Urus Performante, above `lambrini_urus` in its line (or replace the Urus's model if the old one is worse: pick the simplest that keeps owners' cars and note it) | Urus |
| `2012_ferrari_california.glb` | replaces `ferrara_california` (Rosso Rampante California) | California |
| `2013_ferrari_458_spider.glb` | **new car**: 458 Spider (fictional Rosso Rampante name), next to the 458 Italia | 458 |
| `2014_ferrari_458_speciale.glb` | **new car**: 458 Speciale, the top of the 458 line (the game already uses a 458 Speciale *cabin* as a donor for the 458 Italia, `ferrara_458s`: use the new model's cabin instead if it's better) | 458 |

- **Already done, don't redo:** the 9 Lamborghinis and 6 Bugattis from the last two jobs. The West Yokohama Gallardo stays skipped. Leave the old files in the folder.
- Fictional names only (Enfurecido / Rosso Rampante), no badges. Suggest prices, classes / PI and real wheelbases (`CarBuilder.REAL_WB`) for the new cars; note them.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Games/CityLegends/CLAUDE.md` (the new-model routine);
  - `City Legends/City Legends.md` (the Lamborghini and Bugatti import notes);
  - `City Legends/Prompts/Better car models and clean interiors.md` (Parts 1, 2, 2b, 3, 4; **no new sounds** until the owner sends IDs);
  - `City Legends/Prompts/Lamborghini imports.md` (same steps).
- **Licences:** check each model's licence. **Flag any "NC" (non-commercial) licence to the owner**: the game sells Robux items, so NC models are risky. Note the credit for CC-BY ones. Tell the owner if a model looks ripped from another game.

## Step 1: check every model (no converting yet)
For each model, render it (`render_car.py`: front / rear 3/4, side, the driver's seat, a **cluster close-up**, the **steering wheel close-up**) and list: triangles, textures and sizes, full interior or not, separate doors or not (Murcielago: **scissor doors**), logos / stickers, the licence.

### Cluster check: tell the owner about every bad one
- Check **every** car's cluster close-up.
- If a cluster is **blurry**, low-resolution, broken, a flat picture with nothing readable, or **missing**, **stop and tell the owner**: list each car with its close-up render and what's wrong.
- **The owner will send a photo of that car's real cluster.** Then **recreate it 1:1** from the photo: the same layout, numbers and marks, needles or screen bars, colours, fonts as close as possible, warning lights and backlight glow, at the exact size and place in the dash. Sharp (like the SVJ's and the LP700's redrawn screens), **no maker's logos or real names**, then make it **live**.
- Put the owner's photo next to a render of the new cluster for approval.
- Show the owner all close-ups (clusters + steering wheels) in one picture.

## Step 2: best cluster and wheel per family, shared inside it
- **Murcielago** (LP640, LP670-4 SV), **Urus** (the old Urus, Urus Performante), **458** (the old 458 Italia, 458 Spider, 458 Speciale), **California** (alone).
- Compare inside each family, pick the best cluster and steering wheel, and fit them to the others exactly (no floating, clipping or gaps), with the donor system. **Never share across families.**
- If all models in a family are bad, stop and tell the owner (see above).
- Show the comparison and your pick.

## Step 3: convert, without losing anything
The same routine and rules as the Lamborghini job:
- every part kept (only logos and stickers removed), checked with renders and part lists before / after;
- unique texture names and the PBR maps;
- **realistic live clusters** in each car's real look:
  - Murcielago: analog dials with live needles;
  - Urus: the digital screen made live (speed, RPM bar, gear, mode);
  - 458 and California: the big centre rev counter with its needle, plus the side screens / dials, live;
  - backlit at night;
  - no overlay over the model's own cluster;
- realistic interiors (Part 2): dark cabin, proper materials, a soft cabin light, no grey parts or holes;
- the quality checklist (Part 2b);
- doors: scissor doors on the Murcielagos if separate, normal doors on the others; if not separate, say so;
- sound: leave it.

### Realistic inside and out, no grey parts (owner, 2026-11-05)
- **No grey / white / untextured parts anywhere**, inside or outside: every part gets its real material and colour (paint, carbon, black plastic trim, chrome, rubber, glass, lights, leather, Alcantara, metal pedals, carpet). Check every part in the parts list and in close-up renders from all angles (wheel arches, under the bumpers, engine cover, door shuts, seats, dash, roof lining, boot). Use `CABIN_RECOLOUR` / textures from the real car's photos for anything that came in grey.
- **Exterior realistic:** glossy clear-coat paint (PBR), dark tinted glass you can still see the cabin through, real-looking light lenses (headlights, LEDs, tail lights), proper tyres with sidewalls, rims with depth, brake discs and calipers, carbon parts that look like carbon, no stretched or blurry textures.
- **Interior realistic:** dark realistic cabin in the car's real colours, leather with stitching, Alcantara, carbon trim, metal accents, no shiny plastic look, the cluster and screens glowing softly at night, nothing see-through or missing.
- Show the owner close-ups of each car's interior and exterior before packing.

## Step 4: put them in the game
- A replacement keeps the same id, name, price, level and class, so owners keep their car. New cars join their series in the right order. Remove an old model only after the new one is in and checked.
- Pack them for Import 3D in `imports/new_cars/` and tell the owner when to import. After the import, check each one in Play.

## Check before you say done
- In Play, for each car: outside day and night, the driver's seat, the cluster working (speed / RPM / gear match the HUD), the steering wheel turning, doors, Customs paint, tail lights, a phone-size screenshot.
- Before / after renders prove nothing was lost.
- Commit, push, save the place; note it in `City Legends/City Legends.md` (with credits and licences).

## When done, tell the owner (short)
- the cluster problems found (with pictures) and what you need from the owner;
- the cars with names, prices and classes;
- licence warnings;
- screenshots.
