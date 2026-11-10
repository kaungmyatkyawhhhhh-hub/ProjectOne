# Prompt: finish the 7 models that are already in imports: top quality, ask the owner about clusters

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works exactly like the earlier import prompts (`New imports - BMW M cars and GT3 RS (overnight).md`, `New imports - R8s, Bentayga, GT-Rs, and doors on every new model.md`): reuse their tools, routine, traps and notes (`Games/CityLegends/CLAUDE.md`: "New cars by Open Cloud", "Imports of 2026-11-08", `CarSwap`, `RimSwap`, `cluster_imports.py`, `tools/doors.py`, `CarLamps`)._

## What the owner wants (2026-11-10)
Do the 7 models that are already in `Games/CityLegends/imports/importing cars/` and still not in the game. "Make the interior very nice, **ask me if there's a problem with the clusters**, make the wheels good, and everything good quality."

## The 7 cars (all replacements: keep each id, name, price, level and class, so owners keep their car)
| # | File | Replaces the model of | Cluster |
|---|---|---|---|
| 1 | `2009_bmw_m5_e60.glb` | `bnw_m5_e60` ("Bavarica Werkz E60 V10") | check the model's own (step 1) |
| 2 | `2011_bmw_e92_m3_gts.glb` | `bnw_m3_e92` ("Bavarica Werkz E92 V8") | check the model's own |
| 3 | `2018_bmw_m4_coupe_f82_lci.glb` | `bnw_m4_f82` ("Bavarica Werkz F82") | check the model's own |
| 4 | `2022_bmw_m5_cs.glb` | `bnw_m5_f90` ("Bavarica Werkz F90") | check the model's own |
| 5 | `2019_porsche_911_991.2_gt3_rs_weissach_package.glb` | `porsha_gt3` ("Stuttgart 991.2 Track") | check the model's own |
| 6 | `2018_bentley_bentayga_v8.glb` | `bentlee_bentayga` ("Sovereign Highlands"; it can tow: fit its hitch) | **the owner's photo**: `Games/CityLegends/imports/refs/bentayga_cluster_owner.webp`, rebuild 1:1 (see the R8 / Bentayga prompt for the details), no logos |
| 7 | `2013_nissan_gt-r_black_edition_coupe.glb` | `nisun_gtr` ("Horizon R35") | the model's own (the owner said the GT-R cluster looks good): keep it, make it live |

- Add all 7 to `CarFinish.NEW`. Backups of each old model first (`OldCarModels` / dated in `ServerStorage`), so any car can be put back.
- **Licence:** #1 is CC-BY (credit "Galaxy Car Showroom"); #2–#7 are **CC-BY-NC-SA (non-commercial)**: write the warning at the top of the notes.
- **No logos anywhere** (BMW roundel, M badges, Porsche crest and lettering, Bentley "B", Nissan / GT-R badges): body, wheels, calipers, steering wheel, seats, tyres, clusters.
- (The GT-R Nismo, `2017_nissan_gt-r_nismo.glb`, is a **new** car from the R8 / Bentayga prompt: if it isn't in the game yet, do it after these 7, the same way, as "Horizon R35 Track Edition".)

## Step 1: check every cluster, and ASK the owner about problems
For each of cars 1–5 (and 7), render the cluster close up (and the steering wheel) **before converting**:
- **Good** (sharp, readable, complete): keep it and make it live (speed, RPM, gear, odometer, fuel).
- **A problem** (missing, blurry, broken, a flat unreadable picture, half of it missing, wrong car's cluster): **stop and ask the owner.** Write a short message at the **top of the notes** and tell the owner in the reply: the car, a close-up render of its cluster, and what's wrong (one line). Put all the problem clusters in **one picture** so the owner can answer at once. The owner will send a photo of that car's real cluster; then rebuild it **1:1** from the photo (layout, numbers, needles, screens, colours, fonts, warning lights, glow, sharp, live, **no logos**) and put the photo next to your rebuild for approval.
- **While waiting for the owner's answer:** carry on with everything else on that car (exterior, interior, lights, wheels, doors) and with the other cars. Don't fake a cluster.

## Step 2: every car, top quality
### Interior: very nice (owner's main ask)
- The **real cabin colours and materials** of each car, rich and realistic: leather with visible grain and **stitching** (the BMW M-style tricolour stitching as plain colours; the Bentayga's quilted / diamond stitching), **Alcantara** (GT3 RS, GTS, CS), **carbon** trim, **wood veneer** (the Bentayga's burr walnut), brushed / polished metal, soft-touch plastics, carpet, roof lining.
- **Seats** with real shape and padding (the bucket seats in the GT3 RS / GTS / CS, the Bentayga's comfortable chairs), seat belts.
- **Dashboard and console:** every screen **lit and readable** at day and night (no blank grey screens), buttons and switches with depth and labels where real (our own text, no logos), air vents with slats, the gear selector, start button, cupholders, the clock in the Bentayga.
- **Steering wheel:** the right shape and size, real materials (leather / Alcantara, carbon), paddles where real, **no logo on the hub** (a plain plate if moulded), turns with the steering.
- Door cards, pedals, mirrors, sun visors, the roll cage where the model has one (GTS / GT3 RS).
- A soft cabin light at night; the cluster and screens glowing softly; **nothing grey, missing or see-through** from the driver's seat, the passenger seat or from outside through the windows.

### Exterior
- **No grey / white / untextured parts anywhere**: arches, under the bumpers, engine vents, door shuts, the boot, mirrors, grilles (the kidney grille shape stays, no logo), diffusers, wings.
- Glossy clear-coat paint with proper reflections in the real colours; Customs paint covers every body panel and nothing else.
- Carbon that looks like carbon (GTS / CS / GT3 RS roofs, wings, splitters), matte / gloss trim as on the real car, chrome only where real.
- Dark tinted glass you can see through; grilles and vents with real depth; no stretched / blurry textures, no z-fighting, no floating or clipping parts; clean panel gaps.

### Headlights and tail lights
- **Headlights:** real lenses over detailed housings (the BMW angel-eye rings / LED strips in their real shapes, the Porsche's round lamps, the Bentayga's round lamps with their detail, the GT-R's boomerang lights), glass that looks like glass; when on, they glow **in their proper place** with beams from the lamps (`CarLamps`).
- **Tail lights:** the real shapes with depth, dark red off, red glow on, **brighter when braking**, **white reverse lights** only in reverse, **indicators** on the right side; never a flat red sticker; nothing glowing through the body.

### Wheels (owner: "make the wheels good")
- To the standard of `A million times better wheels (new models).md`: concave rims with real depth, lug nuts (centre-lock on the GT3 RS), a plain centre cap (no logo), proper PBR finishes; real tyre profile, tread, our own sidewall text (no real tyre brands); drilled / ceramic discs and the right calipers (no brand lettering); the right size, stance and offset filling the arches; spinning and steering right; a dark arch liner behind.

### Doors
- Working doors like the others (`tools/doors.py`, the SVJ method): normal doors on all 7, **rear doors too** on the 4-door E60 M5, F90 M5 and the Bentayga; painted jambs, door thickness and inner panels, **no holes** (check with `cull` and mode `holes`); a `Config.Doors` switch per car. If a car's doors can't be perfect, leave its switch off and note it.

### Exhaust sounds (owner, 2026-11-10: "don't forget to add exhaust sounds for them if they don't have")
- Each of the 7 gets its real-engine exhaust set (`Config.lua`, "Supercar exhaust sounds", the `CARS` table), the same way as the supercars, if it has none yet.
- State on 2026-11-10: only `porsha_gt3` has one (FLAT6). Missing: `bnw_m5_e60` (V10), `bnw_m3_e92` (V8), `bnw_m4_f82` (twin-turbo straight-6), `bnw_m5_f90` (twin-turbo V8), `bentlee_bentayga` (twin-turbo V8), `nisun_gtr` (twin-turbo V6).
- Done as one job after the GT-R is in (it edits `Config.lua` too).

## No errors
- No console errors or warnings, no physics glitches, no visual errors. If something can't be done cleanly, **leave it out** (or keep that car on its old model) and write it at the top of the notes.

## Check every car before you say done
- Before / after renders: front 3/4, rear 3/4, side, top, the driver's seat, the cabin from the passenger side, close-ups of each light, a wheel, the cluster; the part list before / after (nothing lost).
- In Play: day and night, driving, the driver's seat, **the cluster matching the HUD** (speed / RPM / gear), all lights, doors, Customs paint, a phone-size screenshot; another player sees it right.
- Lune tests and `luau-lsp analyze` clean; FPS not worse.
- Save the place, commit, push after each car; note it in `City Legends/City Legends.md` (credits, licence warnings).

## When done, tell the owner (short)
- **the clusters with a problem** (one picture, with what's wrong) and what you need from the owner;
- each car: done / not done, with an interior and an exterior screenshot;
- licence warnings.
