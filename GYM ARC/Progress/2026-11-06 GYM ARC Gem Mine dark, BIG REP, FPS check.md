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
