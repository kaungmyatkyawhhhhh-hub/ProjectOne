# Prompt: new starter car pick: 350Z, 330i and Audi TT

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
The free starter pick (`Config.Menu.StarterChoices`) becomes:
| Slot | Car | Id | Top speed | Feel text |
|---|---|---|---|---|
| 1 | Horizon 350Z (Z33 after the rename) | `nisun_350z` | 155 | "Grippy sports car" |
| 2 | Bavarica Werkz 330i (G20 Sport after the rename) | `bnw_330i_g20` | 155 | "Quick, comfy sedan" |
| 3 | **Audi TT** (new car, see below) | new id, e.g. `audy_tt` | about 155 | "Small, light, all-wheel drive" |

Why: the Camaro (top 184) was standing in for the A45 S and was far too fast for a free car.

## Changes
1. **Starter pick** = the 3 cars above. The Chasor, the A45 S and the Camaro leave the pick; they stay in the game as normal cars you can buy (the A45 S is still waiting for its model, `Cars.Pending`).
2. **Bring the 330i back:** remove `bnw_330i_g20` from `Cars.RETIRED`, and move it to the **Starter** tier with a Starter price (about $40K, in line with the 540i $42K and the 350Z $38K). Keep its id, so players who own it keep it. Check its model, cluster and wheel still work.
3. **Audi TT (new car):** the owner will put the model in `Games/CityLegends/imports/importing cars/`. Then do the normal new-model routine (`Better car models and clean interiors.md`, Part 3; licence check, logos out, live cluster, clean interior):
   - fictional name with the Precision brand and the **chassis code** of the model's generation: Mk1 = "Precision 8N", Mk2 = "Precision 8J", Mk3 = "Precision 8S" (check which generation the model is);
   - a **normal TT, not the TT RS** (top speed about 155, 0–60 about 5.3 s); Starter tier, price about $40K; real wheelbase in `CarBuilder.REAL_WB`;
   - it's a new model, so it also gets the new-model looks (the lighting / car look and small design change prompts) if those are done.
4. **Until the TT model is in:** slot 3 uses the **540i** (`bnw_540i`, top 155, "Fast and comfy") as its stand-in (`fallback`), not the Camaro. When the TT is in, the TT takes the slot.
5. New players who already picked a starter keep their car.

## Check before you say done
- A new player sees the 3 picks (with the 540i in slot 3 until the TT arrives), can pick each one, and gets it in the garage; phone-size screenshot of the pick screen.
- The 330i shows in the dealer under Starter; old owners still have it.
- Lune tests and `luau-lsp analyze` clean; save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- done, the pick screen screenshot, and that the TT model is still needed (if it is).
