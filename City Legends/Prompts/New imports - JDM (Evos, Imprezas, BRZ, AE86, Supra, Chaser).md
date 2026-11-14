# Prompt: import the 10 new JDM cars: sounds, quality, doors, clusters, no bugs

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Works exactly like the earlier import prompts (e.g. `Finish the 7 waiting imports (E60, E92, F82, F90, GT3 RS, Bentayga, GT-R).md`): reuse their tools, routine, traps and notes (`Games/CityLegends/CLAUDE.md`: "New cars by Open Cloud", `CarSwap`, `RimSwap`, `cluster_imports.py`, `tools/doors.py`, `CarLamps`). Sounds like `Realistic exhaust sounds for the supercars (real engines).md`._

## What the owner wants (2026-11-14)
"I pushed new cars, add them to the game. I want everything working properly: sounds, quality and more, and **no bugs at all**. Check which cars' clusters are bad or which don't come with clusters." Then: "**Don't forget to add the door opening.**"

## The 10 files, in `Games/CityLegends/imports/importing cars/` (folders `Missubibi/`, `Toyota/`, `subaru/`)
| # | File | In the game | Real engine (reference) | Sound character |
|---|---|---|---|---|
| 1 | `Toyota/1994_toyota_supra_sz-r_mk_iv.glb` | **replaces the model of `toyoka_supra_mk4`** ("Apex JZA80"): keep id, name, price, level, class | 3.0 **I6 NA** (2JZ-GE), the SZ-R | smooth straight-six, silky to redline |
| 2 | `Toyota/toyota_chaser_tourer_v_jzx100.glb` | **replaces the model of `toyoka_chaser`** ("Apex JZX100 Tourer") | 2.5 **I6 turbo** (1JZ-GTE) | straight-six with turbo whistle and blow-off |
| 3 | `Toyota/1985_toyota_sprinter_trueno_ae86.glb` | **new car: "Apex AE86"** (the 3-door hatch), Starter tier | 1.6 **I4 NA, high-rev** (4A-GE), RWD | light, raspy, revs high |
| 4 | `Missubibi/1999_mitsubishi_lancer_evo_vi_gsr.glb` | **new car: "Ronin CP9A"** | 2.0 **I4 turbo** (4G63T), AWD | boosty turbo four, wastegate chatter |
| 5 | `Missubibi/1999_mitsubishi_lancer_evolution_6_tommi_makinen.glb` | **new car: "Ronin CP9A Champion"** (the rally champion's special; never a real person's name), above #4 | 2.0 I4 turbo (4G63T), AWD | like #4, louder, rally pops |
| 6 | `Missubibi/2006_mitsubishi_lancer_evolution_ix_mr.glb` | **new car: "Ronin CT9A"** | 2.0 I4 turbo (4G63T, MIVEC), AWD | like #4, a bit sharper |
| 7 | `Missubibi/2015_mitsubishi_lancer_evolution_final_edition.glb` | **new car: "Ronin CZ4A Final"** | 2.0 **I4 turbo** (4B11T), AWD, ~303 hp | deeper, smoother turbo four |
| 8 | `subaru/1998_subaru_impreza_22b_sti.glb` | **new car: "Pleiad GC8 Wide"** (the wide-body 2-door), collector price | 2.2 **flat-4 turbo** (EJ22), AWD | the boxer burble (unequal-length rumble), turbo |
| 9 | `subaru/2006_subaru_impreza_wrx_sti.glb` | **new car: "Pleiad GDB"** | 2.5 **flat-4 turbo** (EJ257), AWD | boxer burble, turbo spool |
| 10 | `subaru/2013_subaru_brz.glb` | **new car: "Pleiad ZC6"** (the light RWD coupe), Starter / Mid | 2.0 **flat-4 NA** (FA20), RWD | thrummy boxer, NA |

- **Two new fictional brands** (add to `Cars.Makes`, garage / dealer brand lists): **"Ronin"** for the Mitsubishis and **"Pleiad"** for the Subarus (Subaru's name means the Pleiades star cluster). Never "Mitsubishi", "Lancer", "Evo", "Subaru", "Impreza", "WRX", "STI", "BRZ", "GSR", "Tommi Mäkinen", "Toyota", "Supra", "Sprinter Trueno" or "Chaser" in any name or on the car. (If the owner later picks other brand names, rename them then.)
- New cars: real prices (`Real car prices and harder cash.md`: old = used / collector value; the 22B, the Champion edition, the AE86 and the Supra are collector cars now), class / PI from real numbers, real wheelbases in `CarBuilder.REAL_WB`, drive types (AWD Evos / Imprezas, RWD AE86 / BRZ / Supra / Chaser), gear counts. Series: "RONIN CP9A" (#4, #5), "RONIN CT9A", "RONIN CZ4A", "PLEIAD GC8", "PLEIAD GDB", "PLEIAD ZC6", "APEX AE86". Note them all.
- Add all 10 to `CarFinish.NEW` and the new-model systems (lamps, doors). **No wheel swap and no extra design changes** for these cars (owner, 2026-11-14).
- Their engines are already engine swaps (4G63, 4B11, EJ25, 1JZ, 2JZ...): the Workshop should know each car's stock engine.
- **Licence warnings** at the top of the notes: #1, #3–#10 are Ddiaz Design **CC-BY-NC-SA (non-commercial)**. #2 is **CC-BY** by "GT Cars: Hyperspeed": the uploader's name looks like a game's name, so it **may be ripped from a game**: check its part names and write what you find.
- **No logos anywhere:** no Mitsubishi diamonds, "LANCER" / "Evolution" lettering, Ralliart, Subaru stars, STI / WRX / "22B" badges, Toyota emblems, "TRUENO", tyre brands (Advan, Bridgestone...), BBS / Prodrive / Recaro / Momo / Nardi / Enkei logos on wheels, seats, steering wheels, stickers and clusters (all in these models' textures and meshes: **remove** them, never cover them; see the owner's rule below).

## Wheels and logos: the owner's rule (2026-11-14)
- **Don't make our own wheels.** Keep **each model's own wheels and rims** (saves time). Only take the names and logos off them (centre caps, rim lettering, tyre sidewall text, caliper lettering) and make sure they look good (no grey parts, proper materials). No wheel library swap, no `RimSwap`, for these cars.
- **REMOVE names, badges and logos, never cover them.** No plates, patches, stickers or blank discs put over a badge. Instead:
  - **in the textures:** paint the logo or lettering out so the spot looks like the material around it (paint, carbon, plastic, rubber, leather) (`tools/paint_glb.py`);
  - **raised letters / badge shapes in the mesh:** cut them out and close the hole in the part's own surface so it's smooth, in the right paint or material (`tools/retext.py` `drop` + `fill`, `tools/details.py`); a badge that's its own loose piece is deleted;
  - **steering wheel hubs:** remove the moulded badge (cut the piece, fill the surface) instead of a plate (`HUB_PLATES` is not used for these cars).
- Check close up from every angle: no logo, no letters, no plate, no hole where a badge was.

## Clusters (checked from each model's textures, 2026-11-14: confirm with close-up renders)
| Car | What the model has | Verdict |
|---|---|---|
| AE86 | its own dashboard picture (512 px, the dials fill it) | **OK**: keep it, make it live |
| Evo VI Champion (#5) | its own dials in a 1024 px interior picture, plus needle parts | **OK**: keep it, make it live (use its needle parts) |
| 22B (#8) | its own white-face dials in a 1024 px picture, plus needle parts | **OK**: keep it, make it live |
| Evo VI GSR (#4) | dials in a 512 px picture, small; needle parts exist | **Probably blurry**: rebuild sharp from a photo (the Champion's cluster is a different design: don't share unless the real cars share it) |
| Evo IX MR (#6) | dials small in a 512 px interior picture | **Blurry**: rebuild from a photo |
| Evo X Final (#7) | dials in a 512 px picture, small | **Blurry**: rebuild from a photo |
| BRZ (#10) | dials small in a 512 px interior picture | **Blurry**: rebuild from a photo |
| Supra (#1) | dials tiny in a 512 px interior picture | **Bad**: rebuild from a photo |
| Impreza GDB (#9) | the whole interior in one **256 px** picture | **Bad**: rebuild from a photo |
| Chaser JZX100 (#2) | **no cluster picture at all** (only the steering wheel) | **Missing**: build it from a photo |

- **For every car marked blurry / bad / missing:** use the owner's photo if one is in `Games/CityLegends/imports/refs/` (named after the car); if not, **search the web for a clear photo of that car's real cluster** (free-to-use sources where possible; save it in `imports/refs/` with a `.txt` of the source) and **rebuild it 1:1**: layout, numbers, needles, screens, colours, fonts as close as possible, warning lights, glow, sharp, live, **no logos**. Put each photo next to your rebuild in one picture for the owner.
- If a render shows a cluster better or worse than the table says, trust the render and note it.

## Doors (owner: "don't forget the door opening")
Working doors on **all 10** (`tools/doors.py`, the SVJ method, a `Config.Doors` switch per car): normal doors; **rear doors too** on the 4-door Evos (#4–#7), the GDB (#9) and the Chaser (#2); the AE86 is a 3-door hatch (two doors, plus the hatch only if it's a separate part); the Supra, 22B and BRZ are 2-doors. Painted door jambs, door thickness and inner panels, **no holes** (check with `cull` and mode `holes`). If a car's doors can't be made perfect, leave its switch off and note it.

## Exhaust sounds
- Find sounds in the **Roblox Creator Store** (public, usable in any experience; never sounds ripped from other games), credited, matched to each engine (measure the firing note: an I4 fires at rpm / 30 Hz, an I6 at rpm / 20, a flat-4 at rpm / 30 with the boxer's uneven beat).
- Share sets inside an engine family (the 4G63 Evos, the boxer turbo Imprezas), with small per-car changes.
- Start-up, idle (the boxer's lumpy idle), rising revs to the real redline (the AE86 and BRZ rev high), turbo spool, whistle, blow-off and wastegate chatter on the turbo cars, pops / anti-lag-style crackles on the rally cars (#5, #8) when lifting off, the limiter bounce; quieter in the cabin and far away. The Workshop's exhaust parts still change it.
- All ids and settings in `Config`.

## Quality (no bugs, no grey parts)
- **Exterior:** no grey / untextured parts (arches, under the bumpers, engine bays, door shuts, boots, mirrors, grilles, wings, the rally lights / mudflaps where real); glossy paint with real reflections; dark glass you can see through; grilles and vents with depth; clean panel gaps; no floating / clipping / z-fighting / stretched textures.
- **Headlights / tail lights:** real lenses and housings (the AE86's pop-up headlights: keep them up or working if the model allows, note it; the Evo / Impreza lamps); tail lights glow, brighter when braking, white reverse, indicators, all **in their proper place**.
- **Interior:** real materials (cloth / leather / Alcantara, the bucket seats, carbon, metal), lit and readable screens and dials, a proper steering wheel (no logo on the hub), pedals, belts, door cards, a roll cage where the model has one; nothing grey or see-through.
- **Wheels:** **the model's own wheels and rims** (see the owner's rule above), logos removed, materials and tyres looking good (depth, proper finishes, tyres with sidewalls); no wheel swap.

## No bugs at all
- No console errors or warnings (server and client, 2 players, PC and phone size), no physics glitches, no visual errors, saves and rejoin fine, the dealer / garage / Workshop / Customs / races all working with the new cars and brands.
- If anything can't be done cleanly, **leave it out** (or keep that detail simpler, or the car's doors switched off) and write it at the top of the notes.

## Check every car before you say done
- Before / after renders (front 3/4, rear 3/4, side, top, the driver's seat, close-ups of each light, a wheel, the cluster); the part list (nothing lost).
- In Play: day and night, driving, the cluster matching the HUD, all lights, doors, Customs paint, the sound (start, idle, revs, acceleration, lift-off, shifts, limiter), a phone-size screenshot.
- Lune tests and `luau-lsp analyze` clean; FPS fine. Save the place, commit, push after each car; note it in `City Legends/City Legends.md` (names, prices, classes, credits, licence warnings).

## When done, tell the owner (short)
- the 10 cars with names, prices and classes, and screenshots;
- each cluster: kept / rebuilt from which photo;
- the sounds used (credits);
- doors: working / switched off;
- licence warnings (and what you found about the Chaser's source).
