# Prompt: import the new Lamborghini models (perfect clusters and interiors)

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works the same way as `Six Bugatti imports.md` (done 2026-11-03)._

## The models
- The owner puts the new Lamborghini models (`.glb`) in **`Games/CityLegends/imports/importing cars/`**. List what's there first and tell the owner which game car each one replaces.
- **Already done, don't redo:** the Aventador **SVJ** and **SVJ 63** (`lambrini_svj`, `lambrini_svj63`, converted 2026-11-02 with their own live cluster).
- The Lamborghinis in the game now (make **Enfurecido**, fictional names):
  - **Aventador family:** `lambrini_lp700` (Aventador LP700-4), `lambrini_lp750` (Aventador SV LP750-4), and the SVJ / SVJ 63 (done);
  - **Murcielago:** `lambrini_lp640` (Murcielago LP640);
  - **Gallardo:** `lambrini_lp570` (Gallardo LP570-4 SL);
  - **Urus:** `lambrini_urus`;
  - **Countach:** `lambrini_countach` (LP400S);
  - plus any new Lamborghini the owner adds (it gets a fictional Enfurecido name and joins the right family).
- References already in `imports/refs/` for the Aventador clusters and cockpits (`aventador_lp700_cluster_*`, `aventador_sv_cluster_*`, `aventador_sv_cockpit.jpg`, `aventador_lp700_dash.jpg`, `aventador_lp700_cockpit_lit.jpg`) and `gallardo_cluster.jpg`.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Games/CityLegends/CLAUDE.md` (the new-model routine);
  - `City Legends/City Legends.md`;
  - **`City Legends/Prompts/Better car models and clean interiors.md`** (Parts 1, 2, 2b, 3, 4: PBR kept, clean interior, the model's own cluster made live, the quality checklist, doors; **no new sounds** until the owner sends IDs);
  - the SVJ and Bugatti notes (how their own clusters were made live and shared inside a family).
- **Check each model's licence** (Sketchfab page / file info). Note the credit needed. Tell the owner if a model looks ripped from another game.

## Step 1: check every model first (no converting yet)
For each model, render it in Blender (`render_car.py`: front / rear 3/4, side, the driver's seat, a **cluster close-up**, the **steering wheel close-up**) and list:
- triangles, textures (and their sizes), whether the textures came in;
- full interior or not; **separate doors or not** (Lamborghinis have **scissor doors** on the Aventador, Murcielago and Countach: make them open upward if they're separate); logos / badges / plates;
- **the cluster:** real modelled needles, a sharp screen texture, blurry, missing, or a flat picture?
- **the steering wheel:** good shape and texture, separate part, right size, logo on the hub?
Show the owner the close-ups.

## Step 2: pick the best cluster and wheel per family, and share it
- **Only share inside the same family** (the same real cockpit design):
  - **Aventador family** (LP700, SV LP750, and the SVJ / SVJ 63 already done): they share the Aventador's digital cluster style. If a new LP700 or SV model has a worse cluster than the SVJ's working one, use the **best** one for the family (the SVJ's is already live and sharp).
  - **Murcielago**, **Gallardo**, **Urus** and **Countach** are **different cockpits**: never put an Aventador cluster or wheel in them, or the other way round.
- If there are several models of the same family, compare their clusters and steering wheels side by side, pick the best, and fit it to the others exactly (no floating, clipping or gaps), with the donor system (`STEER_DONOR`, cabin / cluster donors, `CLUSTER_RECT` / `DashGauges` for screens, live needles for analog dials).
- **If all models in a family have a bad cluster or a bad steering wheel, stop and tell the owner** with the close-up renders. Don't fake one. The owner may send a better model or a photo to copy.
- Show the owner the comparison image and your pick before changing anything.

## Step 3: convert, without losing anything
For each car, the new-model routine (`paint_glb.py` logos out → `auto_car.py` → `cut_pieces.py` if needed → `render_car.py` → `pack_cars.py`), and:
- **Nothing lost:** every part of the body, interior, cluster, wheels, brakes, lights stays (only logos removed). Compare the part list and a render before and after conversion. Textures keep **unique names** and the PBR maps (colour, normal, roughness, metal).
- **Clusters live, in the real look of each car:**
  - Aventador: the digital cluster (the rev band / arc, speed, gear, drive modes STRADA / SPORT / CORSA, our own words), like the SVJ's;
  - Murcielago / Gallardo / Countach: their analog dials with **live needles** (speed, RPM, plus small gauges) in the real layout and colours, backlit at night;
  - Urus: its digital screen made live (speed, RPM bar, gear, mode).
  - No overlay drawn on top of the model's own cluster.
- **Interior realistic:** passes Part 2 of the car prompt (no grey parts, holes, flicker or stretched textures; leather, Alcantara, carbon; the hexagon details, the start-button cover, the paddles; soft dash glow at night).
- **The quality checklist** (Part 2b) for each car.
- **Doors:** scissor doors open upward (Aventador, Murcielago, Countach), normal doors (Gallardo, Urus), if they're separate; if not, say so.
- **Sound:** leave it (the owner will send IDs).

## Step 4: put them in the game
- Each new model **replaces** the old model of the same car (keep the same id, name, price, level, class), so owners keep their car and nothing breaks: garage, dealer, market, Customs paint, saves, tail lights, the Aventador line's order (LP700 → SV LP750 → SVJ → SVJ 63).
- A **new** Lamborghini (not in the game yet) gets a fictional Enfurecido name and joins the right series; suggest its price / class / PI to the owner, and the real wheelbase in `CarBuilder.REAL_WB`.
- Remove an old model only after the new one is in and checked.
- Pack them for one Import 3D in `imports/new_cars/` and tell the owner when to import. After the import, check each one in Play.

## Check before you say done
- In Play, for each car: outside day and night, the driver's seat, the cluster working (speed / RPM / gear match the HUD), the steering wheel turning, doors, Customs paint, tail lights, a phone-size screenshot.
- Before / after renders prove nothing was lost.
- Commit, push, save the place; note it in `City Legends/City Legends.md` (with credits); clear `imports/importing cars/` once the cars are in.

## When done, tell the owner (short)
- which cluster and steering wheel you picked per family (or that they're all bad, with pictures);
- the cars with names, prices and classes;
- screenshots;
- what's still to do (sounds, anything missing).
