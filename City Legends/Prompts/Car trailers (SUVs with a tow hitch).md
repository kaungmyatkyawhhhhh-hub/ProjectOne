# Prompt: car trailers, towed only by SUVs / cars with a tow hitch

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Toolbox models are allowed for small props (scripts removed, no logos, credited)._

## What the owner wants (2026-11-07)
"Add car trailers. I will import the model for the car trailer. Only SUVs or cars that have a trailer hitch can carry trailers."

## The trailer model
- **The owner imports the trailer model.** Look for it in `Games/CityLegends/imports/importing cars/` (or `imports/trailers/`), e.g. a file with "trailer" in its name. If it isn't there yet, build and test everything with a simple stand-in trailer (a flatbed car-transporter shape: deck, two ramps, mudguards, lights, a drawbar with a coupler) and swap in the owner's model when it arrives. Write at the top of the notes: "Waiting on the trailer model".
- When it's in: the new-model routine (`Better car models and clean interiors.md`, Part 3): licence check (flag NC / ripped), logos off, realistic materials, **no grey parts**, working tail / brake / indicator lights in their proper place (they follow the towing car's lights), the number plate spot, ramps as separate parts if possible.

## Which cars can tow
Only cars with a **tow hitch**: SUVs whose real car can tow a car on a trailer (about 2,500 kg or more). Put it in data: `TowCapacity` (kg, the real figure, close enough) per car in `Config`, and a car can tow only if trailer + load ≤ its capacity.
- **Can tow** (check each real figure):
  - Apex J200 / J300 (Land Cruisers), Stealth-Apex J310 (LX);
  - Tri-Star Silber W463 V8 (G63), Rocket W463 800, C167 3.0 (GLE), X167 Royale (GLS);
  - Bavarica Werkz G06 Sport (X6), G07 (X7);
  - Sovereign Highlands (Bentayga), Ecstasy Grandeur (Cullinan, check its class), Enfurecido Brava (Urus);
  - Dream-Build Volt Titan (U8), British Vanguard Highland (DBX), Trident Motors Maestrale GTS (Levante);
  - and any future SUV / pickup with a hitch.
- **Can't tow:** every sports car, supercar, sedan, coupe and hatch; the Orient Voltra (EV6, too light to tow a car) and the Apex Grand Lounge (Alphard, no hitch).
- Each towing car gets a small, realistic **hitch** (receiver and tow ball) at the rear centre, under the bumper, in the right place on its own model, so the trailer couples there exactly. Hidden or very small when no trailer is attached (like a real removable hitch), visible when towing.
- In the dealer and garage, a small **"TOWS"** tag (with the capacity) on cars that can tow.

## Getting and using a trailer
- **Buy** the trailer at Legends Motors (a "Trailers" section), a realistic price for a car-transporter trailer (research it), saved like a car. It lives in the garage list.
- **Spawn it** with a towing car from the garage: it appears **already hitched** behind the car. You can also spawn it alone at a parking spot, then **reverse up to it** and press the interact key (or tap HITCH) when the hitch is close to the coupler to attach. Unhitch the same way.
- **Load a car:**
  - drive one of your own cars up the ramps onto the deck, stop in the marked spot, press interact / tap STRAP: it's strapped down (welded), the driver gets out; or
  - from the trailer's menu, **load a car from your garage** straight onto it.
- **Unload:** stand by the trailer and press interact / tap UNLOAD: the ramps go down and the car rolls off (or appears next to the trailer if there's no room).
- Only **your own cars** go on your trailer (no taking other players' cars).

## Driving with a trailer (feel real, stay fun)
- Real **physics coupling** at the hitch (a ball-socket joint with sensible limits), wheels on the trailer, the right weight (trailer + car on it).
- The towing car is **slower to speed up**, **brakes longer**, turns wider; a top speed limit while towing (about 80 mph / 130 km/h, Config). A small "TOWING" icon on the HUD.
- **Sway** at high speed or on sharp moves (gentle, recoverable); **jackknife** only in silly moves (hard braking while turning fast).
- **Reversing** works (the trailer turns the opposite way, like real life); a **rear camera / reversing view** while reversing with a trailer helps.
- The trailer's **lights** copy the car's: tail, brake, indicators, reverse.
- Traffic avoids the trailer, and the lane checker / traffic AI never get stuck behind a parked one forever (traffic goes round it).
- **Damage:** the trailer and the car on it can get scrapes like other cars (if the damage system exists); towing adds a little wear (if the wear system exists).
- Not allowed in races / time trials / police chases (unhitch first); allowed on jobs and free roam.
- Fuel: towing uses more fuel (if the fuel system exists).

## Saves and safety
- Server-side: hitching, loading and unloading are checked by the server (distance, ownership, the tow capacity).
- Saved: owned trailers. If the player leaves while towing, the trailer and loaded car go back to the garage.
- No physics glitches: no flinging, no cars falling through the deck, no trailer stuck in the ground; test at low and high speed, up and down hills, on the Grand Hairpin, over kerbs and through the tunnels.

## Check before you say done
- In Play (PC and phone 667 × 375):
  - every towing car hitches the trailer at its own hitch; a non-towing car can't (a clear message: "This car can't tow");
  - load and unload a car (drive-on and from the garage);
  - drive with it: speed, braking, sway, reversing, lights, the hairpin and hills;
  - another player sees it all; rejoin keeps the trailer.
- Screenshots: 3 towing cars with the trailer and a car on it (day and night), the hitch close up, the "TOWS" tag.
- FPS fine with several trailers around; no errors; Lune tests and `luau-lsp analyze` clean.
- Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the cars that can tow (with capacities);
- how to hitch, load and unload (keys / buttons);
- screenshots;
- whether the owner's trailer model is in or still needed.
