---
date: 2026-10-27
tags: [gymarc, progress, world, strongman, models]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-27 GYM ARC Strongman Yard and Blender models

## Strongman Yard (prompt 63)
- Built and tested: see [[GYM ARC - Strongman Yard]]. 7 station types (10 stations), the Strongman Showdown every 15 minutes with a live scoreboard, rewards and the YARD KING title, 2 NPC strongmen, guide entry, sounds.
- Fixes found in the test: the keg toss arc now clears the bar; the street gate's lock sign text fits.

## Level-up popups (owner: "the lvl up notification is annoying, it keeps showing up every rep")
- The top-bar **LVL UP** popup now shows only when LVL reaches a new multiple of 10, and at most once a minute (`TopBarClient`, LVL_POPUP_STEP 10, LVL_POPUP_GAP 60).
- The muscle level flash + ding on the machine shows at most once every 30 seconds (`MachineClient`, LEVEL_FLASH_EVERY).

## Blender models (owner: "model in blender for the atlas stone and the yoke / farmer frame", "model the shrub, plants too")
- Script `gymarc_models.py` (Blender 5.2, run in the background) builds 6 low-poly models with vertex colours, 1 Blender unit = 1 stud:
  - **AtlasStone** (radius 1, dark granite with chalk on the sides; scale per station), **Yoke** (red frame, steel crossbar, bumpers), **FarmersFrames** (two red frames, steel grips, bumpers).
  - **Shrub** (3.8 x 2.4 x 3.2 like the town bushes), **Flowers** (a clump of 7 stems), **PottedPlant** (clay pot, arching leaves).
- Files: `C:\Users\kaung\Downloads\gym_arc_models\<Name>.fbx` (+ `.blend` to edit). Previews: `Screenshots/test_2026-10-27/blender_*_preview.png`.
- **Imported and swapped in (27 Oct):** the owner imported the 6 files; the meshes live in `ServerStorage.ModelMeshes` (white tint shows the vertex colours; the stone tinted #B5B7BA).
  - Yard: the 3 atlas stones, the yoke and the farmer's frames are now one mesh each in their station's Rides folder. The builder `StrongmanStations` uses the meshes when they are there. Old parts: `ServerStorage.StrongmanPropsBackup_27Oct`.
  - Town: all 46 bushes, 49 flower clumps and 9 potted plants are meshes (same places and footprints, random turn). Old models: `ServerStorage.PlantsBackup_27Oct` (each keeps a FromPath attribute).
- **Part 2: trucks and the city** (owner: "model the trucks too, and the city"), script `gymarc_truck_city.py`:
  - **PickupTruck.fbx**: TruckPaint (white: takes each truck's colour), TruckTrim (tyres, chrome, grille, lights), TruckGlass.
  - **CityBuildings.fbx**: 3 styles for the Pro Gym valley city (250 box buildings now): Low (storefront, cornice, water tank), Mid (office, setback top), Tall (glass tower, two setbacks, crown). Each is Body + WinLit (glows at night: gets the NightColor attribute) + WinDark (named "Windows": goes dark at night), so BackdropClient's night lights keep working.
  - **Imported and swapped in:** both yard trucks are the mesh truck (paint keeps teal / red; builder uses it too). All 250 city buildings: style by the height above the ground (84 Low, 92 Mid, 74 Tall), stretched to the old footprint, wall + window colours kept, lit windows keep NightColor, beacons kept. The city went from 3,143 to 1,388 parts. Old buildings: `ServerStorage.CityBackup_27Oct`; old truck parts in `StrongmanPropsBackup_27Oct`.
  - Small known look issue: on short wide buildings the rooftop water tank gets squashed.
- **Part 3: Pump Shop** (owner: "model ALL the tubs in the pump shop too and all the belt pieces"), script `gymarc_pumpshop.py` -> **PumpShopModels.fbx**: TubBody (rounded base, shoulder, neck), TubLid (ribbed), ChampionBelt (leather loop, gold piping, 14 gem side plates, oval front plate with a star), LiftBelt + LiftBuckle (folded over the hook, stitching, holes, prong). **Imported and swapped in:** all 161 tubs and 163 lids are meshes (each keeps its colour, Product attribute, band and symbol plate; any lid / tub turned the same way as before); the championship belt is one mesh (tint #FFD27A, still tilted on its cushion); the 3 lifting belts + buckles on the gear wall (colours kept). Old parts: `ServerStorage.PumpShopBackup_27Oct` (348 parts, each with a FromPath attribute).
- Screenshots: `Screenshots/test_2026-10-27/mesh_01..04` (Pump Shop belts + tubs, championship belt, city, trucks).
- **Tub pictures** (owner: "most of the pump shop tubs don't have images like from the item picture"): every tub now matches its item picture (band, lid, symbol), the display tubs got products, a Whey drop symbol was made, the counter glass is plastic so the symbols show. See [[GYM ARC - Pump Shop]].
- All Blender templates: `ServerStorage.ModelMeshes` (truck / city / lift buckle pieces carry an Offset attribute for placing).
- Scripts kept in `Downloads\gym_arc_models\scripts`.

## Starter Pack popup
- Every 15 minutes of play and at most 3 a session (was every 5 minutes); the SHOP DEAL tag stays. See [[GYM ARC - Monetization]].

## Also 27 Oct
- **Powerlifting door** stayed shut after walking away and back (streaming); fixed, see [[GYM ARC - Powerlifting Gym]].
- **Your body looks like Atlas's:** your own muscles use the same stage meshes as Atlas and everyone else (no live meshes, faster on phones). See [[GYM ARC - Muscles and Bodies]].
- **VIP 30% OFF pass** id 2052738798 wired in. See [[GYM ARC - Monetization]].

## Owner rule
- From 27 Oct no code export / commits to ClaudeOne: Studio is the only copy, notes only in this vault.
