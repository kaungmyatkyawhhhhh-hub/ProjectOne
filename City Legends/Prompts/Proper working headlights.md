# Prompt: proper working headlights and tail lights, in their proper place (newly imported cars only)

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
"Make proper working headlights." Headlights that look and work like real ones: the car's own light units glow, real beams light the road ahead at night, and you can switch between modes.

## ONLY the newly imported models (owner, 2026-11-06: "only do it in newly imported cars and not old model imports")
- **Yes:** the cars converted with the new-model routine: the Aventador SVJ / SVJ 63, the 6 Bugattis, the 9 Lamborghinis from `Lamborghini imports.md`, the cars from `New imports - Murcielago, Urus Performante, Ferraris.md`, the new starter car (Focus RS) and every car imported from now on. (The game's list is `CarFinish.NEW`; check it against the import notes.)
- **No:** every older model. Their headlights, tail lights, indicators and the way L works on them stay **exactly as they are now**. Don't move, add or remove anything on them, and make sure the new code doesn't change them (test 3 old cars before / after: they must look and work the same).
- Everything below (the light map, glowing units, real beams, modes, haze, glare, the proper-place checklist) is for the new models only. Traffic and police cars get it only when they use a new model.

## RULE: every light works IN ITS PROPER PLACE (owner, 2026-11-06: "the headlight and taillight NEEDS to work in its proper place")
This is the most important part. On **every newly imported car** (and traffic / police when they use a new model):
- **Headlights** glow and shine **from the car's own headlight units**: the exact lamps on the front of the model, left and right. Never from the middle of the bonnet, the grille, inside the car, the roof, under the car, or floating in front of it.
- **Tail lights** glow **on the car's own tail-light units** at the back: running lights when the lights are on, **brighter when braking**, and the **reverse light** (white) only when reversing. Never on the boot lid, the bumper, the number plate or floating behind.
- **Indicators / blinkers** flash on the car's own indicator spots (front corners, mirrors or side, rear), left and right the right way round.
- The glow must **match the shape of each light unit** (the lens / LED strip / round lamps), not a square block stuck on top. No light poking through the body, no glow showing from the wrong side, no flicker or z-fighting.
- How:
  - map every new-model car's light parts (headlight, DRL, tail, brake, reverse, indicators, left / right) in data (`HeadlightMap` with the tail-light map), found from the model's own parts and checked by eye;
  - fix any car where the existing tail lights (`client/TailLights.lua`) sit in the wrong place too;
  - where a model has no separate lamp part, fit a thin glowing insert shaped to the unit, just behind the lens.
- **Check every new-model car one by one** at night from the front, back and both sides (a close-up of each corner). Keep a checklist in the notes: car, headlights ✓, tail / brake ✓, reverse ✓, indicators ✓. **No car is "done" until all four are in the right place.**

## What we have now (check it first)
- The F engine start turns on the dash and headlights; L toggles the lights while running.
- Lights are synced to every player (`CarSignals` remote → `Lights` attribute; others see them).
- Reach is 80 studs; Customs headlight colour (white / warm / ice, `Config.Customs.Headlights`).
- Files that handle lights today: `client/TailLights.lua`, `client/WorldFx.lua`, `shared/CarBuilder.lua`, `shared/CarMesh.lua`, `server/Customs.lua`, `client/CustomsClient.lua`.
- **First:** drive 5 different cars at night (an old model, a new-model routine car, an SUV, a hypercar, a traffic car) and list what's wrong: which cars have no glow on their light units, beams coming from the wrong place, lights through the bonnet, no light on the road, flicker, cost.

## What "proper" means
### 1. The light units glow (the model's own headlights)
- Find each car's **real headlight parts** (lens, projector, DRL strip) on every new model (not the old ones). Store their positions per car (a `HeadlightMap` in data, like the tail-light map) so the light comes from the right spot.
- When the lights are on: the projector / bulb part glows (Neon material or a bright emissive colour on that part only, the Customs headlight colour), the lens looks lit, and the **DRL strip** glows softly whenever the engine runs.
- When off: the units look like glass and chrome, not grey or black holes.
- If a car's model has no separate light part, add a small glowing insert shaped to fit behind the lens, so it never looks painted on.

### 2. Real beams on the road
- **Two SpotLights per car**, one per side, at the real headlight positions, aimed slightly down and outward, Customs colour, **shadows on for the player's own car**.
- **Low beam** (default): about 60–80 studs, a wide pool with a sharp-ish top edge (it doesn't light up the sky).
- **High beam**: about 140–160 studs, brighter, narrower, aimed a little higher.
- The road ahead, kerbs, walls, signs and other cars visibly light up at night; beams follow the car and the suspension (pitch on braking / bumps).
- A **soft beam haze** in fog and rain (a faint light cone with Beams / particles, cheap, only for the nearby cars).
- A small **glare / lens flare** sprite on the lights of cars **facing you** (other players, traffic, police), stronger with high beam.

### 3. Modes and controls
- **Auto** (default): DRLs when the engine runs; low beam turns on at dusk, off after sunrise (by `DayCycle`); also on in tunnels.
- **L:** cycle Auto → Low → High → Off. **Hold L** or a quick double-tap: **flash high beam** (pass). Touch: a headlight button on the driving HUD with the same cycle (icon shows the mode).
- A small HUD icon: green = low, blue = high.
- Synced to everyone like today (the `Lights` attribute gets the mode).

### 4. Everyone else's cars
- **Traffic, police and parked cars** at night: low beams and tail lights on (traffic AI turns them on at dusk). Police light bars stay as they are.
- **Performance:** only the player's car and the **nearest ~6 cars** get real SpotLights; further cars get just the glowing units and a glare sprite (no light). Shadows only for the player's car. Turn beams off for cars behind the camera. Graphics settings: Low = own car beams only, no haze; Ultra = more cars with beams.

### 5. Customs
- The headlight colour option (white / warm / ice) changes the units' glow and the beams.
- **New (owner's existing Customs area):** "Headlight tint" stays as now; don't add other new options.

## Check before you say done
- At night, in Play, on PC and phone-size (667 × 375):
  - 10 cars (old models, new-model routine cars, SUV, hypercar, traffic): units glow in the right spot, beams light the road, low / high / flash / auto all work;
  - another player sees your mode;
  - the harbour street, the Grand Hairpin and a tunnel at night;
  - fog and rain haze.
- Day: DRLs on, no beam light, nothing looks odd.
- Before / after screenshots at night from behind the car and from the front (facing another car).
- The per-car light checklist (headlights, tail / brake, reverse, indicators in their proper place) is complete for **every new-model** car (and 3 old cars are proven unchanged), with close-ups of any car that needed fixing.
- FPS not worse at the 3 usual spots (night, lots of traffic); no errors; Lune tests and `luau-lsp analyze` clean.
- Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the screenshots;
- the controls (L / hold L / the button);
- any car whose light units couldn't be found (with a close-up).
