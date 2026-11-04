---
date: 2026-11-04
tags: [gymarc, plates, weights, leaderboards, prompt, final]
---
# GYM ARC - Prompt: PLATE TIERS, FINAL (part 9 of the 7 Nov GEM update)

Replaces every earlier plate prompt ([[2026-11-04 GYM ARC Prompt - Plate tiers (14 Nov)]]).
Owner decisions (4 Nov, final look = concept v3): with the 7 Nov update; heavier weights on top of the Gem Mine; bought once, used on every machine; names by material (not lb); numbers shown on plates; swap one plate at a time, heaviest inside; thin calibrated plates, more per bar; tiers bigger each time; Ruby/Diamond style (gem core) for all tiers; steel competition look for standard plates; shop in the Gem Mine.
Concept art (APPROVED 4 Nov): `Assets\plates\gymarc_plates_concept_v3.png`.
Gates chosen 4 Nov: 400 / 435 / 470 / 500 / 535 / 565. Text style on every plate: white with a thin dark outline ("use the ruby's text design"). Build + report: [[2026-11-04 GYM ARC Plate tiers - numbers and stacks report]].

```text
GYM ARC – PART 9 of the 7 Nov GEM update: PLATE TIERS (FINAL – replaces every earlier plate prompt)
Why: players max out weights, have nothing to compete on, and want heavier weights on top of the Gem Mine's.
Concept art (APPROVED): vault GYM ARC\Assets\plates\gymarc_plates_concept_v3.png

0. PRIORITY: GEM update parts 1-8 first. If time is short, ship in this order: (a) tiers + strength gate + Plate Forge shop + heavier weights, (b) coins per tier, (c) PR leaderboards + profile, (d) plate looks/numbers polish + PR moment, (e) meet ranked by PR. Numbers report first (prices, gates vs real data), then build the same day. Tell me by Fri 6 Nov 18:00 UTC which of (a)-(e) will make it. Don't publish.

1. TIERS (bought once with fixed coins, used on EVERY machine): STANDARD (free, owned = today's plates) → BRONZE 50,000 → SILVER 100,000 → GOLD 200,000 → PLATINUM 400,000 → RUBY 800,000 → DIAMOND 1,600,000 (owner 4 Nov: x2 option after Claude Code's data check).

2. STEPS: every bar shows 8 thin plates per side. Each tier = 8 steps: swap one plate at a time, heaviest inside (1 Bronze + 7 Standard … 8 Bronze, then 1 Silver + 7 Bronze …). 6 tiers = 48 new weights above the Gem Mine's top.

3. WEIGHT NUMBERS (every bar must add up exactly): on each machine, tier k has a whole-lb plate value v_k = round((top x (1 + 0.1k) - bar) / 16) (top = that machine's current top weight, Gem copies use the Gem top; k = 0 STANDARD … 6 DIAMOND). Step s shows s plates of v_k + (8 - s) of v_(k-1) per side; shown weight = bar + 2 x that sum (real sum, ~+1.25% a step, +10% a tier). Below the plate tiers nothing changes (existing weights keep their numbers and real plates).

4. STRENGTH GATE: each step needs the machine's main muscle (machine.muscles[1]) at an internal level: tier gates = the ones the owner picked in your Gates question (recommended 400 / 435 / 470 / 500 / 535 / 565, Diamond = the ★10 goal), spread evenly over each tier's 8 steps. Players never see levels: "Needs <Main muscle> <EXP> exp" like today. Owned-but-too-weak = greyed with that line. Lopsided builds lift different tiers on different machines (wanted). Re-applies after Growth Spurts / Alters like today.

5. COINS per rep: +9% of that machine's top-tier coins per full tier (spread per step). Boost cap x4 unchanged. EXP unchanged.

6. LOOKS (match the approved concept v3: thin calibrated competition plates, low-poly, clean – no rivets / notches / hexagons / gem bezels):
   - Shape for every plate: thin disc, raised outer band + slightly recessed face, chrome hub, coloured edge stripe around the rim, "M WEIGHTS" above the hub, number below.
   - STANDARD plates: polished steel. Main sizes 45, 55, 65, 75 lb (65/75 new) + thin change plates 5, 10, 25, 35. Edge stripe by size: 5 chrome, 10 green, 25 yellow, 35 orange, 45 blue, 55 red, 65 black, 75 teal. Diameter by size; change plates thin and small.
   - STACK RULE (barbells, existing weights, visual only – numbers unchanged), per side L = (weight - bar)/2, heaviest inside, max 8 main + up to 2 change plates outside:
     · FILL (L < 8x45): as many 45s as fit, leftover as 1-2 change plates (Gem bench 735 = 45x7 + 25 + 5).
     · SWAP (L ≥ 8x45): 8 main plates, upgrade one at a time 45→55→65→75 (inner first); 5 lb leftover = one 5 lb change plate (875 = 55x5 + 45x3 + 5).
   - TIER plates (each tier's plate bigger in diameter than the last, still thin; the whole plate is the material): BRONZE warm brushed bronze · SILVER bright polished silver · GOLD brushed gold · PLATINUM cool blue-grey platinum · RUBY gunmetal rim + glowing deep-red crystal face · DIAMOND platinum rim + clear faceted crystal face, soft glow. Edge stripe in the tier colour. Glow only on Ruby + Diamond (sparkle only up close).
   - Tiers continue the same 8-slot swap from each machine's Gem top stack (Bronze replaces one plate at a time, then Silver…); tier plates show their own per-machine value (rounded to 5) so every bar adds up exactly.
   - BRAND: "M WEIGHTS" decal on every plate (dark version on light plates, white on dark/ruby: vault GYM ARC\Assets\plates\mweights_dark.png / mweights_white.png; I upload them to Myanmar Builders Club and send you the ids). No other brand names.
   - Numbers: composed from 10 digit decals (0-9), outer face only, only on bars within ~40 studs; pool decals. Send me the 10 digit PNGs to upload.
   - Dumbbells / cable / bodyweight machines: no bar stack; number on the head/stack in the tier/stripe colour.
   - Weight change = plates slide on with a clank (~0.4 s, never blocks reps); new heaviest weight = "NEW PR: <weight>" pop (skippable, ≤1.5 s).

7. SHOP – THE PLATE FORGE in the Gem Mine: a blacksmith corner on the main floor right after the descent (by the dumbbell-rack wall, clear of Flint's stage and the Onyx Throne): anvil, glowing furnace, a rack showing all 7 plates (locked = dark silhouettes), an NPC smith opening the shop window (same UI kit). Also a PLATES tab in the main shop. Cards: STANDARD first marked OWNED, next tier highlighted, price, "Heavier weights on every machine".

8. COMPETE: leaderboards BEST BENCH, BEST SQUAT, BEST DEADLIFT, TOTAL (sum), written on every new PR (not only on gain). Board in the Powerlifting Gym + leaderboard tab with "players near you". Profile card shows the 3 PRs + Total. Powerlifting MEET ranked by real PR on the meet lift.

9. Never lower anyone's weight, best lift or coins; current best lifts become starting PRs.

Test: buy tiers; strong on one muscle / weak on another; plates add up on Gem bench, Gem squat, Gem curl, starter bench, a dumbbell; PR boards update; meet picks the heavier lifter; phone FPS in a full Gem Mine with every bar at 8 Diamond per side (before/after numbers). Progress note + screenshots. Don't publish.
```

## Owner 4 Nov (later): PLATES FIX PASS + OPTIMIZATION (done the same day, report section 6)
```text
PLATES - FIX PASS (owner + Claude review of screens_4Nov_plates). Match concept v3. 1. THIN PLATES: each plate clearly thinner with a small gap / darker edge line, raised outer band visible, so you can count the plates. 2. MATERIALS: no rough/knitted texture; SmoothPlastic or Metal with Reflectance: STANDARD polished steel, BRONZE warm brushed bronze, SILVER bright cool silver, GOLD yellow gold (not orange), PLATINUM blue-grey, RUBY gunmetal rim + glowing translucent red face, DIAMOND platinum rim + icy-blue translucent face with a soft glow. Gold vs Bronze and Platinum vs Silver clearly different, also on the Forge rack. 3. Remove the dark line from the hub up through "M WEIGHTS". 4. CABLE STACK + DUMBBELLS: tier colour clearly visible; numbers white with dark outline, readable from the normal camera. 5. STEP SIZE: no single step may add more than 3% of that machine's top weight; where rounding plates to 5 breaks that, use whole-lb values. 6. PERFORMANCE (must, before publish): cut parts; details only on the outer plate per side; measure before/after FPS on the phone frame in a full Gem Mine. Screenshots of the same 14 shots after the fix. Don't publish.

PLATES - OPTIMIZATION (must before publish; keep the concept v3 look). 1. MESHES: ONE thin plate MeshPart per plate (band + recessed face + hub in the mesh), same MeshId for all plates; tier = Color + Material; only the OUTER plate per side gets stripe, M WEIGHTS + number, and a small Neon inset on Ruby/Diamond; no Glass. Target ~18 parts per loaded bar (was 56). 2. CLIENT-SIDE PLATES: server only sets weight/stack attributes; each client builds plates within ~60 studs, beyond that ONE cylinder per side in the tier colour; pool parts. 3. SETTINGS: Anchored, CanCollide/CanTouch/CanQuery false, Massless, CastShadow false (inner), RenderFidelity Performance, CollisionFidelity Box. 4. MEASURE before/after with every bar at 8 Diamond: FPS phone + PC, part count, draw calls. Target 60 FPS PC, 30+ mid phone. Don't publish.
```
Results and numbers: [[2026-11-04 GYM ARC Plate tiers - numbers and stacks report]] section 6.

## Owner 4 Nov: PLATE GATES (final, replaces the level gates 400-565)
- **Brief:** EXP on the machine's main muscle: BRONZE 250M · SILVER 800M · GOLD 2.5B · PLATINUM 8B · RUBY 30B · DIAMOND 100B. Each tier's gate is spread over its 8 steps geometrically. Shown as "Needs <Muscle> <EXP> exp".
- **The owner's reasoning:** players reaching the Gem alters have ~3B total, about 170M a muscle, so Bronze starts just above that.
- Two earlier versions (levels 400-800, then 25M-1.6B) were replaced the same day.
- **Built.** The checks and numbers are in the report, section 7.

## Owner 4 Nov: PLATES - 13 PER SIDE (built the same day, report section 9)
```text
PLATES - 13 PER SIDE. STACK RULE: max 13 main plates per side (+ up to 2 thin change plates). FILL with 45s up to 13x45, then SWAP 45->55->65->75 one at a time, inner first. Existing weights visual only (numbers unchanged). TIERS: each tier = 13 steps (78 new weights). Each tier still +10% total (~0.8% a step). Per-machine plate values whole lb (round to 5 where the 3% rule allows). Prices and tier gates unchanged; each tier's gate spread geometrically over 13 steps. Re-check: every bar adds up exactly, nothing over 13+2 per side, tris per bar (~1.1k), phone-frame FPS in a full Gem Mine. Send me the new step table for the Gem bench and starter bench. Don't publish.
```

