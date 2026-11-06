# Prompt: new starter car pick: 350Z, 330i and Golf GTI Clubsport Mk7

> **Out of date (2026-11-06):** merged into Part 2 of `Better upgrade area and part shop.md`, and the Golf was replaced by the Ford Focus RS. Do it from there, not from here.

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
The free starter pick (`Config.Menu.StarterChoices`) becomes:
| Slot | Car | Id | Top speed | Feel text |
|---|---|---|---|---|
| 1 | Horizon 350Z (Z33 after the rename) | `nisun_350z` | 155 | "Grippy sports car" |
| 2 | Bavarica Werkz 330i (G20 Sport after the rename) | `bnw_330i_g20` | 155 | "Quick, comfy sedan" |
| 3 | **VW Golf GTI Clubsport Mk7** (new car, see below) | new id, e.g. `wolfs_golf_gti_cs` | 155 | "Hot hatch, front-wheel drive" |

Why: the Camaro (top 184) was standing in for the A45 S and was far too fast for a free car.

## Changes
1. **Starter pick** = the 3 cars above. The Chasor, the A45 S and the Camaro leave the pick; they stay in the game as normal cars you can buy (the A45 S is still waiting for its model, `Cars.Pending`).
2. **Bring the 330i back:** remove `bnw_330i_g20` from `Cars.RETIRED`, and move it to the **Starter** tier with a Starter price (about $40K, in line with the 540i $42K and the 350Z $38K). Keep its id, so players who own it keep it. Check its model, cluster and wheel still work.
3. **Golf GTI Clubsport Mk7 (new car; owner, 2026-11-06: replaces the Audi TT idea):** the owner will put the model in `Games/CityLegends/imports/importing cars/`. Then do the normal new-model routine (`Better car models and clean interiors.md`, Part 3; licence check, logos out, live cluster, clean interior):
   - **new fictional brand "Wolfsburg"** (Volkswagen; a city name like "Stuttgart" for Porsche): add it to `Cars.Makes`; no VW logo anywhere (cover the badges front, rear, wheel caps and steering wheel);
   - name by **chassis code** (Golf Mk7 = 5G): **"Wolfsburg 5G Club"**. Never use "Golf", "GTI" or "Clubsport" (VW's names), and remove the GTI / Clubsport lettering and the red grille-stripe badge text from the model (the plain red stripe can stay);
   - stats like the real car: about 265–290 hp, front-wheel drive, 0–60 about 5.8 s, top speed 155; Starter tier, price about $40K; real wheelbase 2.63 m in `CarBuilder.REAL_WB`;
   - it's a new model, so it also gets the new-model looks (the lighting / car look and small design change prompts) if those are done.
4. **Until the Golf model is in:** slot 3 uses the **540i** (`bnw_540i`, top 155, "Fast and comfy") as its stand-in (`fallback`), not the Camaro. When the Golf is in, the Golf takes the slot.
5. New players who already picked a starter keep their car.

## Check before you say done
- A new player sees the 3 picks (with the 540i in slot 3 until the Golf arrives), can pick each one, and gets it in the garage; phone-size screenshot of the pick screen.
- The 330i shows in the dealer under Starter; old owners still have it.
- Lune tests and `luau-lsp analyze` clean; save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- done, the pick screen screenshot, and that the Golf model is still needed (if it is).
