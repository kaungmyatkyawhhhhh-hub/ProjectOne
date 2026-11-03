# Prompt: import the 6 new Bugattis (perfect clusters and interiors)

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## The models (pushed by the owner, 2026-11-03)
In `Games/CityLegends/imports/importing cars/`:
- **Veyron family** (main model + 2 high-spec trims):
  - `2009_bugatti_veyron_16.4.glb` (main);
  - `2012_bugatti_veyron_super_sport_-_patrol.glb` (Super Sport; "patrol" may mean a police livery: check, and remove police markings if it's not meant to be a police car);
  - `2013_bugatti_veyron_grand_sport_vitesse_wrc.glb` (Grand Sport Vitesse; "WRC" may be a special livery: check).
- **Chiron family** (main model + 2 high-spec trims):
  - `2016_bugatti_chiron.glb` (main);
  - `2021_bugatti_chiron_pur_sport.glb` (Pur Sport);
  - `2022_bugatti_chiron_super_sport.glb` (Super Sport).
- In the game they're fictional: the make is **Velocité Noir**, e.g. "Velocité Noir Veyrun 16.4", "Veyrun Super Sport", "Veyrun Grand Sport Vitesse", "Chiroun", "Chiroun Pur Sport", "Chiroun Super Sport" (show the owner the names). No real badges or names.
- References already in `imports/refs/` for the Veyron cluster and cockpit (`veyron_cluster_crop.png`, `veyron_cluster_lit_vitesse.jpg`, `veyron_cockpit_16-4.jpg`, `veyron_interior.jpg`).

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Games/CityLegends/CLAUDE.md` (the new-model routine);
  - `City Legends/City Legends.md`;
  - **`City Legends/Prompts/Better car models and clean interiors.md`** (Parts 1, 2, 2b, 3, 4: PBR kept, clean interior, the model's own cluster made live, the quality checklist, doors; no new sounds until the owner sends IDs);
  - the SVJ notes (how its own cluster was made live; the texture-naming bug in packs, now fixed).
- **Check each model's licence** (Sketchfab page / file info). Note the credit needed. Tell the owner if a model looks ripped from another game.

## Step 1: check all 6 first (no converting yet)
For each model, render it in Blender (`render_car.py`: front / rear 3/4, side, the driver's seat, a **cluster close-up**, the **steering wheel close-up**) and list:
- triangles, textures (and their sizes), whether the textures came in;
- full interior or not; separate doors or not; logos / badges / plates;
- **the cluster:** is it a real modelled cluster (needles as parts, or a sharp screen texture), blurry, missing, or just a flat picture?
- **the steering wheel:** good shape and texture, separate part, right size, logo on the hub?

## Step 2: pick the best cluster and wheel per family, and share it
- **Veyron family:** compare the 3 clusters and 3 steering wheels side by side (one image). Pick the **best cluster** and the **best steering wheel**, and **use them in all 3 Veyrons** (the real cars share the same cockpit design). Do it with the existing donor system (`STEER_DONOR`, the cabin / cluster donor tables, `CLUSTER_RECT` / `DashGauges` for screens, live needles for analog dials), fitted exactly to each car's dash so nothing floats, clips or leaves a gap.
- **Chiron family:** the same: pick the best cluster and steering wheel among the 3 Chirons and share them across all 3.
- **If all 3 cars in a family have a bad cluster or a bad steering wheel** (blurry, broken, missing, wrong), **stop and tell the owner** with the close-up renders. Don't fake one. The owner may send a better model or a photo to copy (like the SVJ, where a sharp photo was used to redraw the screen).
- Show the owner the comparison image and your pick before changing anything.

## Step 3: convert, without losing anything
For each car, follow the new-model routine (`paint_glb.py` logos out → `auto_car.py` → `cut_pieces.py` if needed → `render_car.py` → `pack_cars.py`), and:
- **Nothing lost:** every part of the body, interior, cluster, wheels, brakes, lights and badges-turned-plain stays (only logos removed). Compare the part list and a render before and after conversion: same parts, same textures, same colours. Textures keep **unique names** (the SVJ bug) and the PBR maps (colour, normal, roughness, metal).
- **The Veyron cluster:** real analog dials in the real layout (the big rev counter in the middle with its needle; speedometer and power gauge needles; the real colours and backlight at night). Make the needles **live** (speed, RPM, power use, fuel) from the model's own dials; no overlay drawn on top.
- **The Chiron cluster:** the real layout (the big analog speedometer in the middle up to 500 km/h with the needle, two small screens on the sides). Make the needle and side screens **live** (speed, gear, RPM, drive mode, fuel), matching the model's own look.
- **Interior realistic:** passes Part 2 of the car prompt (no grey parts, holes, flicker or stretched textures; leather, Alcantara, carbon, aluminium; seat belts, pedals, the gear selector, the middle console; soft dash glow at night).
- **The quality checklist** (Part 2b) for each car: stance, wheels, smooth paint, glass, all lights, Customs paint works, logos gone, LOD, collision box, flames from the real exhausts.
- **Doors:** if the doors are separate, make them open (normal doors on both); if not, say so.
- **Sound:** leave it (the owner will send IDs).

## Step 4: put them in the game
- The 2 main models replace the old Veyron / add the Chiron; the 4 high-spec trims sit above them in the same series (`Cars.Series`: Veyrun 16.4 → Super Sport → Grand Sport Vitesse; Chiroun → Pur Sport → Super Sport). The existing `bugotti_veyron` id stays for the 16.4 (players who own it keep it).
- Suggest prices, levels, top speeds and 0–60 to the owner (all High tier, the top of the game; e.g. Veyrun ~$5M up to Chiroun Super Sport as the most expensive car), real wheelbases in `CarBuilder.REAL_WB`.
- Pack them for one Import 3D (or two packs: Veyrons, Chirons) in `imports/new_cars/`, and tell the owner when to import. After the import: check each one in Play.

## Check before you say done
- In Play, for each of the 6: outside day and night, the driver's seat, the cluster working (speed / RPM / gear match the HUD), the steering wheel turning, doors, Customs paint, tail lights, a phone-size screenshot.
- Before / after renders prove nothing was lost.
- Commit, push, save the place; note it in `City Legends/City Legends.md` (with credits); clear `imports/importing cars/` once the cars are in.

## When done, tell the owner (short)
- which cluster and steering wheel you picked for each family (or that they're all bad, with pictures);
- the 6 cars with names, prices and levels;
- screenshots;
- what's still to do (sounds, anything missing).
