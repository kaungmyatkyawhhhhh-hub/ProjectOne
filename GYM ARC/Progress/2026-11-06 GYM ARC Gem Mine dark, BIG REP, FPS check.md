---
date: 2026-11-06
tags: [gymarc, progress, bugs, performance]
---
# GYM ARC - Gem Mine too dark, BIG REP sometimes missing, FPS check (6 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]]. In Studio only, **not published**.

## 1. "The gem mine is very dark in game" (fixed)
- **Cause:** GymLightsClient (each gym's lights on only where they can be seen + the gym's colour grade) measured each gym's box **once**, the first time it found the gym. The world streams in: the Gem Mine's underground `Zone` wasn't loaded yet, so its box came from the few parts that were (the cave mouth). Inside the mine you were never "inside" it: all its lights stayed off (chandeliers, giant crystal, lanterns) and its look never came. Seen live in the owner's session: 2 of 20 lights on.
- **Fix (GymLightsClient):** a gym with a Zone takes the Zone as soon as it streams in; a gym measured from its parts is measured again every 10 s. Also: a light comes back to its state when first seen (not to whatever it was at the moment the gym went off), lights that should be on are re-checked every 3 s (never ones another script switches, e.g. the Plate Forge), each pass is in a pcall (an error can't stop it for the session), the colour grade is re-made if something removed it. Lighting attribute `GymInside` = the gym you're in (for tests).
- **Tested** (temporary data): from the Pro Gym into the mine: inside = GemMine, its look fades in, 12 of 20 lights on (the server's 11 + the forge's plate glows). Screenshot below.

## 2. "The big rep sometimes don't work" (fixed, not yet tried on a machine)
- **Cause:** the server rolls BIG REP one rep ahead and sends it with the rep's result; the client put it on whichever rep started after that answer arrived. With fast reps (Auto Rep, TITAN / MONSTER rep speed, Pre-Workout) or lag, the next rep often started first: the BIG landed one rep late (a BIG shown on a normal rep, the real BIG shown normal, x3 paid silently). Also the server dropped a rep without a word when two arrived bunched together (network jitter) inside the cooldown: a shown BIG REP that never counted.
- **Fix:** the client numbers its reps (`Lift` sends the number) and the server's result says which rep it was (`seq`). The server's answer wins: the rep still going gets its true BIG / not-BIG before its lockout; the next rep that already started takes the BIG if it's the one the server counts; a BIG confirmed after its rep's lockout shows late ("BIG REP!" in gold + the boom). The server's cooldown keeps half for jitter (the sustained rate stays capped by Guard.Allow).
- Compiles; not played on a machine yet: the owner should try a few sets with Auto Rep on.

## 3. "I am lagging like crazy": where the FPS goes (measured in the owner's live Studio session, in the Gem Mine)
- ~19-21 fps: a frame is ~51 ms, of which **render CPU ~43 ms**; GPU 1.4 ms; scripts (Heartbeat) ~3 ms; physics 1.8 ms. So it's not scripts or the GPU: it's the CPU work of drawing the scene.
- Turned off one at a time (the frame's render CPU): all UI -3 ms, particles 0, 443 billboards / surface guis 0, shadows -2 ms, post effects + atmosphere -5 ms, other gyms' lights (57, left on by the bug above) -2 ms.
- Only 172 of ~21,600 visible parts move per frame (trainers, an NPC, the mine's crystals): fine.
- **The cost is the amount of world loaded:** ~21,600 visible parts streamed in, ~20,000 of them within 400 studs (the whole town above the mine too), 142,000 instances, drawn at Studio's quality 10. Biggest: Town 13,833 parts (BeachGym 2,209, GemMineGym 2,043, GoldenEra 1,708, PumpShop 1,173, Buildings 1,012, EdgeMarkers 912, VipGym 835), PowerliftingGym 2,716, ProGym 2,650, Gym 2,114, Backdrops 1,388. 23,167 parts in the place.
- Studio playtests add their own load (the server and the client in one program, Studio's memory at 3.2 GB): a real phone check in the Roblox player is the true number.
- Ideas, not done (owner's call): a smaller streaming radius (Workspace StreamingTargetRadius; scripts can't read it), merge / simplify the biggest builds (EdgeMarkers, Backdrops), keep the post effects off on low graphics.

![[GYM ARC/Screenshots/2026-11-06_gem_mine_lit.jpg]]

## 4. Later 6 Nov: "simplify the heaviest decoration" (tried, measured, put back)
- The heaviest pure decoration: **Town.EdgeMarkers**, 912 single parts (fence posts + ropes, buoys + ropes, striped barriers; no collisions, no scripts, no tags). Backdrops (1,388) is already handled: BackdropClient shows it only near the Pro Gym.
- Merged EdgeMarkers by area (80 studs) + material: **912 -> 55 objects**, looking identical (before / after screenshots matched). Also the safe parts of the street decor (no collision, lights, prompts, tags or script names; same parent only): Beach 722 -> 681, Plaza 230 -> 222, PocketPark 41 -> 27; Street, SkatePark, Greenery, SportsCourt had nothing safe enough (their decor is many small separate models: one tree, one bench, one lamp).
- **Measured (A/B, the original 912 parts swapped back in): no difference** in render CPU (21-23 ms both ways, noise). Roblox already draws many identical simple parts cheaply; and the merged pieces were worse in two ways: 54k triangles, and too big for the phone LOD (WorldLodClient hides small decor far away on phones, part by part).
- So it was **put back**: EdgeMarkers, Beach and Plaza restored from the backups (exactly as before). PocketPark keeps 4 merged pieces (its two round trees: 18 parts -> 4; no backup survived the first try and Studio can't split them from a script; they look the same and stay under the LOD size).
- **Conclusion:** the part count of the decoration isn't what costs the frames. The real lever is how much of the map is streamed in at once (Workspace StreamingTargetRadius, set in Studio's Properties) and quality on phones.

## 5. Later 6 Nov: owner "StreamingTargetRadius is 160 already" - what loads, and the Studio floor
- Why 160 doesn't shrink the world: the big buildings are **Atomic** (ProGym 2,650, PowerliftingGym 2,716, BeachGym 2,209, GoldenEra 1,708, PumpShop 1,173, VipGym 835, MembersGym, Sauna, ClothingStore, HallOfFame, 38 Town.Buildings; set 2 Nov against the holes) and StreamOutBehavior is **LowMemory** (set 28 Oct against the reload spikes). An Atomic gym loads whole once any of it is in range and stays. The town is compact: right after spawning, **22,366 parts** are loaded (24,000 after visiting every gym). Both settings were right for those bugs; keep them.
- Measured in Studio (render CPU per frame, the plaza):
  - everything loaded: ~22-25 ms;
  - every far gym hidden (Pro, Powerlifting, Beach, Golden Era, Gem Mine, Starter, backdrops: 13,700 parts): 19 ms (-4 ms);
  - **the whole map hidden (only you + terrain): 16.5 ms** = the floor in this Studio;
  - the 2 LIMITLESS trainers (Atlas + Solaris), the aura + alter look, the Gem Mine's 13 lights or its particles: no measurable change.
- So in Studio most of the frame is Studio / engine overhead; the map adds ~6-8 ms. The owner's 43-52 ms session (long-running Studio, 3.2 GB memory, the console spamming "being generated") couldn't be reproduced (22 ms in the same spot). The true number is the live game in the Roblox player (and a phone).
- (One test above ran on the owner's real save by mistake: Studio started without the temporary-data switch. Only teleports and hiding things on the client; no rep was counted, nothing given or changed.)
