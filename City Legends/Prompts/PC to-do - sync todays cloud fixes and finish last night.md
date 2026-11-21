# Prompt: sync today's cloud fixes into Studio and finish last night's open items

_For Claude Code on the PC (Studio MCP, Blender). Owner: caveman mode, no questions (owner: "never ask me any questions again": say what you will and won't do). No errors: sacrifice a feature instead of shipping it broken. Read `City Legends/2026-11-21 Night run - P8, code sync, minimap, lamps.md` first (the last three sections were written by the cloud session on 21 Nov, daytime)._

## 1. Sync the cloud's code (repo -> Studio), then Play-test
- `src/shared/RivieraTraffic.lua`: traffic dead ends fixed (1:1 dead pieces 1,972 -> 526; the 526 left are lane-2 merge tails by design). Check: traffic drives Maha Bandula Road #3, Zoological Garden Road, Gyophyu Road, Kun Chan Road, Bo Min Gaung Street and through Roundabouts 1, 2, 4 and Hanthawaddy.
- `src/shared/ExhaustTips.lua` (NEW ModuleScript in Shared) + `src/client/Driving.lua`: exhaust flames + smoke on the 20 supercars and lambrini_lp700 / lp750 / svj / svj63 / revuelto only. For each of those 25 cars: rear view, rev at a standstill, a hard upshift, lift off at high revs: the flames and smoke must come out of the real pipes. If a car's tips are off, fix its row in `ExhaustTips.lua` (share of the skin's length from its middle / lowest / rear-most point) and note it. Other cars: no flames.
- Usual sync method (pack_sync / QuickSync, checksum each script against git first). Store back on `CityLegends_v1` after any test. Owner saves.

## 2. Last night's open items (in this order)
1. P8: the U Chit Maung x Banyar Dala deck dip (60.6 -> 29.9 at about 39940, 32800): builder fix + re-bake of cell 26x21.
2. Lamps: real lamp shapes on the 458 Speciale, Huracán, Sterrato, California, LFA; apply the tail shells on bentz_sls (asset 118050194412654), ferrara_599, mclaran_12c, nisun_350z.
3. Traffic reach: only 82.7% of the 1:1 network is one connected part (`lanes1to1_test` wants 90%): find the areas cars can enter but not leave (lane generator `roads05_lanes.py` / links) and fix.
4. `world_test` fails ("Instance has been destroyed" in CityBuilder.build, line 298): fix the test or the builder.
5. Real-Yangon look, then the Dala Bridge LAST (survey notes in the night-run file).

## 3. GT-R Nismo
`Horizon R35 Zenith` (`nisun_gtr_nismo`) still borrows the 2013 Black Edition body. Import `imports/importing cars/2017_nissan_gt-r_nismo.glb` as its own model (the usual new-model routine: logos removed not covered, its own wheels and steering wheel, doors, lamps in place, no grey parts, live cluster), take `Model = "nisun_gtr"` off its Cars.lua line, add it to `CarFinish.NEW`. Licence warning to the owner (Ddiaz Design: check it).

## Tell the owner when done (short)
What was synced, the flame check per car (any tips moved), which open items are done, what's left.
