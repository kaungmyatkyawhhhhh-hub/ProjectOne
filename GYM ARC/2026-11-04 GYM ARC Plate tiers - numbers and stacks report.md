---
date: 2026-11-04
tags: [gymarc, plates, weights, report]
---
# GYM ARC - Plate tiers: numbers and stacks report (4 Nov)

For [[2026-11-04 GYM ARC Prompt - Plate tiers FINAL (7 Nov part 9)]]. Everything here is in Studio (not published). All numbers come from `Config/PlateTiers` (one module) and `Config/Machines`.

## 1. Data check (real saves, read-only, top 50 of the Strongest board)
- **Gates:** with the first gates (360-435), 24 of 49 top players already had chest at 435+ (median 411, p75 562, p90 894). The ★10 alter goal is level 565, ★15 is 880.
- **Coins:** the Gem top pays 30 coins a rep, at up to 1.35 reps a second. That's 2,430 coins a minute with no boost, 9,720 at the x4 cap and 19,440 with the 2x pass. 38 of 49 could buy a 25k tier on the spot; 22 had 175k+.
- **Owner picked:** prices x2 (50k to 1.6M) and gates 400 / 435 / 470 / 500 / 535 / 565.
- Bronze at 50k takes 21 min with no boost, 5 min at x4 and 2.6 min with the 2x pass. The whole set (3.15M) takes 5.4 h at x4.

## 2. The rules as built
- **Steps:** 6 tiers × 8 steps = 48 new weights on every machine (not the treadmill). Step s of tier k = s plates of v_k (inside) + (8 − s) of v_(k−1), per side.
- **Plate value v_k** = (top × (1 + 0.1k) − bar) / 16, rounded to 5. (A one-stack machine divides by 8; a dumbbell has bar 0.)
  - v_0 (STANDARD) is rounded UP, so step 1 is always over the top weight.
  - Each v_k is at least 5 over the one before.
- **Strength gate:** the tier's gate is spread over its 8 steps, starting from the Gem top's 346. Bronze runs 353, 360 … 400; Diamond runs 539 … 565.
- **Coins a rep:** the top weight's coins × (1 + 9% × (tier − 1 + step / 8)). EXP stays the top weight's.
- **Standard stacks (visual only, the numbers didn't change):**
  - FILL: 45s, with the leftover as 1-2 change plates.
  - SWAP: 8 main plates; 45 → 55 → 65 → 75 one plate at a time, inner plates first; a 5 lb leftover is one 5 lb plate.
  - Checked by script: **all 753 barbell weights add up exactly, none over 8 main + 2 change.** All 48 steps on every machine rise and add up exactly.

## 3. Plate values per machine (v_0 STANDARD … v_6 DIAMOND, lb per plate)
**Replaced by section 6 (fix pass, same day): no step over 3%, whole-lb plates where 5s jumped too far.**

| Machine (top weight) | v_0 | BRONZE | SILVER | GOLD | PLAT | RUBY | DIAMOND | Step 1 → Diamond 8 |
|---|---|---|---|---|---|---|---|---|
| Starter bench (315) | 20 | 25 | 30 | 35 | 40 | 45 | 50 | 375 → 845 |
| Starter squat / deadlift, Pro bench (455) | 30 | 35 | 40 | 45 | 50 | 55 | 60 | 535 → 1005 |
| Comp bench (595) | 35 | 40 | 45 | 50 | 55 | 60 | 65 | 615 → 1085 |
| Pro squat / deadlift (665) | 40 | 45 | 50 | 55 | 60 | 65 | 70 | 695 → 1165 |
| **Gem bench (735)** | 45 | 50 | 55 | 60 | 65 | 70 | 75 | 775 → 1245 |
| Comp squat / deadlift / block pull (875) | 55 | 60 | 65 | 70 | 75 | 80 | 85 | 935 → 1405 |
| **Gem squat / deadlift (1085)** | 65 | 70 | 80 | 85 | 90 | 100 | 105 | 1095 → 1725 |

Each step adds 2 × (v_k − v_(k−1)): +10 lb a step on most bars, +20 on the Gem squat's Silver and Ruby steps. Examples:
- Gem bench Bronze: 775 · 785 · 795 · 805 · 815 · 825 · 835 · 845.
- Gem bench Diamond 8: 45 + 2 × (8 × 75) = 1245.

**Note for the owner:** rounding plates to 5 makes the FIRST Bronze step jump on light machines:
- starter bench 315 → 375 (+19%)
- comp squat 875 → 935 (+7%)
- Gem bench 735 → 775 (+5%)

After that each step is the small swap. Without rounding to 5 the numbers would be odd (16.9 lb plates). Say if you want the light machines handled differently.

## 4. Standard stacks (per side, heaviest inside)
Every bench copy uses the bench ladder up to its own top. Every squat / deadlift / hip thrust copy uses the squat ladder.
- **Bench ladder (to the Gem top 735):** 45 bar · 65: 10 · 95: 25 · 115: 35 · 135: 45 · 155: 45+10 · 185: 45+25 · 205: 45+35 · 225: 45×2 · 255: 45×2+10+5 · 275: 45×2+25 · 315: 45×3 · 335: 45×3+10 · 355: 45×3+10×2 · 375: 45×3+25+5 · 395: 45×3+35+5 · 415: 45×4+5 · 435: 45×4+10+5 · 455: 45×4+25 · 475: 45×4+35 · 495: 45×5 · 515: 45×5+10 · 535: 45×5+10×2 · 555: 45×5+25+5 · 575: 45×5+35+5 · 595: 45×6+5 · 615: 45×6+10+5 · 635: 45×6+25 · 655: 45×6+35 · 675: 45×7 · 695: 45×7+10 · 715: 45×7+10×2 · **735: 45×7+25+5**
- **Squat ladder (to the Gem top 1085):** 45 bar · 95: 25 · 135: 45 · 165: 45+10+5 · 185: 45+25 · 225: 45×2 · 255: 45×2+10+5 · 275: 45×2+25 · 315: 45×3 · 365: 45×3+25 · 405: 45×4 · 455: 45×4+25 · 485: 45×4+35+5 · 515: 45×5+10 · 545: 45×5+25 · 575: 45×5+35+5 · 605: 45×6+10 · 635: 45×6+25 · 665: 45×6+35+5 · 695: 45×7+10 · 725: 45×7+25 · 755: 45×7+35+5 · 785: 55+45×7 · 815: 55×2+45×6+5 · 845: 55×4+45×4 · **875: 55×5+45×3+5** · 905: 55×7+45 · 935: 55×8+5 · 965: 65×2+55×6 · 995: 65×3+55×5+5 · 1025: 65×5+55×3 · 1055: 65×6+55×2+5 · **1085: 65×8**
- The 75 lb plate never shows on today's weights: the heaviest bar (1085) is 8 × 65. The tier plates take over from there.

## 5. In-game checks (Studio, temp save, 4 Nov)
- **Gem bench:**
  - 735 shows 45×7 + 25 + 5.
  - + shows 775 "Needs BRONZE plates: Plate Forge (Gem Mine)" / "BRONZE PLATES 1 / 8".
  - After buying Bronze + Silver with a strong chest, BEST WEIGHT = Silver 8 = 925.
- **Gem squat, weak legs (quads 405):** BEST = Silver 1 = 1185 = 45 + 2 × (80 + 7 × 70). Silver 2 needs 409. So different tiers on different machines works.
- **Gem curl (stack):** Platinum 3 = 495. The stack turns platinum blue-grey with "495" on the pinned block.
- **Gem dumbbell curl:** Platinum 3 = 590 per dumbbell (2 × 295). The heads turn platinum with the number on each end.
- **Buying:** coins went down by exactly 50k + 100k (analytics "Shop:PlateTier").
  - A double tap bought two tiers. Fixed: the bought card stays picked (now OWNED) and the button rests 0.8 s.
  - The server still only sells the next tier.
- **Parts per bar:**
  - Today's Gem 735 restacked: 56 parts.
  - A full 8 Diamond bar: 34 parts (inner plates are just their edge).
  - Numbers show only within 40 studs, at most 96 at once.
  - Studio PC FPS by the bench: 36.
  - **Not tested on a phone.**
- **Screenshots:** `Downloads\gem_update_import\screens_4Nov_plates\` (Gem bench 735, Bronze 1 / 4 / 8, Silver 8, Gold 8, Ruby 8, Diamond 8, Gem squat, Gem curl stack, dumbbells, the Plate Forge, the Forge shop).

## 6. FIX PASS + OPTIMIZATION (4 Nov, later; owner's briefs in [[2026-11-04 GYM ARC Prompt - Plate tiers FINAL (7 Nov part 9)]])
### Step size: no step over 3% of the machine's top weight
- **Barbells** use 5 lb plates only where every step then stays within 3%. Otherwise they use whole-lb plates. Only the 1085 squat / deadlift keeps 5s.
- v_0 is the smallest plate that still puts step 1 above the top weight.
- **Dumbbells and one-stack machines** (cable, bodyweight, strongman) show no plate stack. Each of their steps is top x (1 + 1.25% x n), in whole lb, always at least 1 lb up.
- Checked by script on all 30 machine types: the biggest step is **2.2%** (squat rack 455), every step goes up, and every barbell still adds up exactly.

| Machine (top) | Step 1 | Diamond 8 | Biggest step | Plates v0 ... v6 |
|---|---|---|---|---|
| Starter bench (315) | 321 | 509 | 1.9% | 17/19/21/23/25/27/29 |
| Starter squat / Pro bench (455) | 465 | 733 | 2.2% | 26/28/31/34/37/40/43 |
| Comp bench (595) | 597 | 957 | 1.3% | 34/38/42/46/49/53/57 |
| Pro squat (665) | 677 | 1069 | 1.8% | 39/43/47/51/55/60/64 |
| **Gem bench (735)** | 743 | **1181** | 1.4% | 43/48/52/57/62/66/71 |
| Comp squat (875) | 887 | 1405 | 1.4% | 52/57/63/68/74/79/85 |
| Gem squat (1085) | 1095 | 1725 | 1.8% | 65/70/80/85/90/100/105 |
| Gem dumbbells (290 each) | 294 | 464 | 1.4% | (+1.25% a step) |
| Lightest dumbbell / stack (100) | 101 | 160 | 2.0% | (+1.25% a step) |

Diamond 8 on the Gem bench is now 1181 (was 1245).

### Looks
- **Thinner plates:** 0.1 thick (was 0.14), with a 0.035 gap (was 0.015). The 8 plates read as separate plates, not one drum.
- **Materials:** SmoothPlastic with a little Reflectance. The knitted Metal and Glass are gone from plates.
  - Inner plates are their tier colour. Only the outer plate gets the band, face and hub (and the standard stripe on its rim).
  - Ruby: gunmetal plates with a glowing red Neon face. Diamond: platinum plates with an icy-blue Neon face.
  - Gold is now yellow, not orange; Platinum is blue-grey, apart from Silver.
  - Bright colours read darker in the Gem Mine's warm, dark light, and Reflectance darkens them more, so it is kept low.
- **Dark line through "M WEIGHTS":** this was the clamp's dark handle. The clamp is removed.
- **Stacks and dumbbells:**
  - The tier's bright colour is on the stack blocks and dumbbell heads.
  - Every number is white with a dark outline.
  - The stack's number is taller than the thin block (0.62) and never hangs below the stack. On the front of the cable stack the pin covers the middle digit; the back reads clean.
- **Numbers:** the 10 digit images load at the start, so a digit seen for the first time no longer shows late ("48" had shown as "4").

### Performance (Studio PC, the Gem Mine, every bar at Diamond 8, same camera)
| | Before | After |
|---|---|---|
| Plate parts in the Gem Mine | 415 (built by the server, sent to every player) | 272 (built by each player's own game) |
| Plate parts in the whole game | 5,579 on the server, replicated | 492 on this client (near: real plates; up to 320 studs: 1 cylinder a side) |
| Gem bench, Diamond 8 | 34 | 24 (22 visible) |
| Gem bench, standard 735 | 56 | 42 (38 visible); about 30 once the plate mesh is in |
| Draw calls (this view) | 435 | 437 |
| Triangles (this view) | 177.5k | 175.3k |
| Render CPU (this view) | 21.7 ms | 22.6 ms |

- **FPS can't be measured here.** Studio caps its own rendering while its window isn't focused: 15 FPS even looking at empty sky with 0 draw calls, and 15 to 41 FPS for the same scene minutes apart.
- **Plates aren't the cost.** With every plate in the game removed, FPS and render time didn't change. Draw calls barely move because Roblox already batches identical plate parts.
- **Real gains:** about 5,000 fewer replicated parts, fewer parts per bar, and nothing built for bars far away.
- **Phone FPS:** still to measure on a real phone.

### How it works now
- **Server** (`MachineService`): only sets the machine's Tier and PlateRest (where the racked bar sits). It still builds the weight stacks' number tags and the held dumbbells.
- **Client** (`PlateClient`):
  - Within 60 studs it builds the real plates (`PlateLook.Specs`); up to 320 studs, one cylinder a side in the tier colour.
  - Parts are pooled. Every part is Anchored, with no collide, touch or query, Massless, and no shadow except the outer plate's.
  - `MachineClient` carries them with the bar during a rep.
- **Mesh** (`PlateLook`): uses the plate mesh (`GymAssets.PlateMesh`) once it's imported (IMPORT_LIST "PLATE MESH"), else one cylinder per plate.
- **Studio test switch:** Workspace attribute `TestPlateStep` = n (0 = the top weight, 1-48) loads every idle bar with that step.
- **Screens:** `Downloads\gem_update_import\screens_4Nov_plates_fix\` (01-14 as before, plus 08b Platinum 8 and 12a/12b the stack front and back).

### The plate mesh (owner imported it, 4 Nov)
- **Imported:** `gymarc_plate.obj` as rbxassetid://112165957173612. The axis came in right (thin along X, face +X).
  - The template is `ReplicatedStorage.GymAssets.PlateMesh`: RenderFidelity Performance, CollisionFidelity Box, no collide / touch / query.
  - The imported original is kept in `ServerStorage._Imports`.
- **Measured: a mesh on every plate is heavier.** A mesh plate is 1,120 triangles. With every plate a mesh, the same Gem Mine view went from 175k to 305k triangles and from 437 to 519 draw calls. Those two numbers were from different sessions, so the draw calls carry some session noise.
- **Built: the mesh only on the OUTER plate per side**, where the raised band, recess and hub show. Inner plates show only their rim and stay one cylinder each, with the gap between plates.
- **A/B in one session (same camera, every bar Diamond 8):**

  | | Draw calls | Triangles | Mesh plates |
  |---|---|---|---|
  | Outer-plate mesh | 519 | 222.9k | 23 |
  | No mesh (cylinders) | 518 | 210.3k | 0 |

  So the mesh on the outer plates costs +1 draw call and +6% triangles.
- **A Diamond 8 bar is now 22 parts (20 visible), close to the ~18 target.** Per side: 7 cylinders, the mesh plate, the glow inset, the sleeve and the invisible number face.
- The standard plate's blue/red/teal edge stripe is now a ring a little wider than the mesh rim, so it shows all the way round.
- **Mesh screens:** `screens_4Nov_plates_fix` 15-17 (17 = every plate a mesh, Ruby 8, before the switch to outer-only).

## 7. PLATE GATES IN EXP (owner, 4 Nov, final)
### The briefs
- **Brief 1:** level gates 400 / 470 / 535 / 600 / 700 / 800. Not built.
  - For a ★10 with 2 Heracles at the Gem bench top, 565 -> 800 is **6 reps (0.1 min)**. Even ★0 with 2 Voltas needs only 42 reps.
  - The cause: one rep there gives 7-9M EXP, and level gaps are about 1.1K raw EXP.
- **Brief 2:** EXP gates 25M ... 1.6B. Replaced before it was finished: a ★1 with 2 Voltas reaches 1.6B in ~1.8 h of lifting one muscle.
- **Final (built):** the CURRENT EXP of the machine's main muscle.
  - Tier gates: **BRONZE 250M · SILVER 800M · GOLD 2.5B · PLATINUM 8B · RUBY 30B · DIAMOND 100B**.
  - Each tier is spread over its 8 steps geometrically. Bronze starts from the Gem Mine top's 12.4M.
  - Shown as "Needs <Muscle> <EXP> exp".

### Checks from real saves (top 50 of the Strongest board + the owner, read-only)
| | p90 | max |
|---|---|---|
| CURRENT EXP, one muscle (all pooled) | 67.2M | 365M |
| CURRENT EXP, each player's strongest muscle | 116M | 365M |
| LIFETIME EXP per muscle (the top bar's lifetime / 18) | 74.8B | 188B |

- The current body total is 273M (p50), 919M (p90) and 4.9B (max).
- The owner: strongest muscle 269M current, about 387M lifetime per muscle; Alter 18, ★4.
- **An Alter keeps 25% of every muscle's EXP (removes 75%). A Growth Spurt and entering the Hall of Fame reset the muscles to 0.**
- **The #1 player is nowhere near 100B on current EXP** (the max in the top 50 is 365M), so there is no flag.
- **Lifetime EXP would be wrong for this:** the top is already 188B a muscle, so a lifetime gate would give out Diamond on day 1.

**Can anyone reach Ruby in one run on current EXP?** Pure lifting, one muscle, Gem bench top, from 0:

| Setup | Bronze | Silver | Gold | Platinum | Ruby | Diamond |
|---|---|---|---|---|---|---|
| ★1, 2 Voltas, Alter 7 | 7 min | 38 min | 3 h | 20 h | 143 h | 867 h |
| ★10, 2 Heracles, Alter 20 | 1 min | 5 min | 26 min | 3 h | 18 h | 111 h |
| Owner's maxed setup | 0 min | 2 min | 11 min | 66 min | 8 h | 49 h |

- Yes, but only by grinding one muscle without altering (an alter drops a Ruby 30B to 7.5B = Gold).
- The time grows faster than the EXP because of diminishing returns (EXP a rep ~ 1 / level).
- So current EXP is kept, not lifetime.
- For scale: one muscle at the Alter 15 goal is 77.6M, and at the Alter 20 goal 219M.

### Built
- **`PlateTiers.GateExp(k, s)`:** geometric from the tier before.
- **`PlateTiers.Gate(k, s)`:** the whole muscle level that first has that EXP. Every machine compares levels, so the "Needs" number shown is exactly what's checked: e.g. "Needs Mid Chest 334,624,118 exp" for Silver 2.
- **Step gates:**

  | Tier | Steps 1 → 8 |
  |---|---|
  | Bronze | 18.1M → 26.2M → 38.2M → 55.7M → 81.1M → 118M → 171M → 250M |
  | Silver | 289M → 800M |
  | Gold | 922M → 2.5B |
  | Platinum | 2.9B → 8B |
  | Ruby | 9.4B → 30B |
  | Diamond | 34.9B → 100B |

- **Tested in Play (temp save, all tiers owned, chest 300M EXP):**
  - The server put the Gem bench on Silver 1 (821 lb).
  - Asking for Silver 2 was refused.
  - The panel shows "Needs Mid Chest 334,624,118 exp".
- **Open question for the owner:** Bronze 1-6 (18M-118M) sit below the ~170M a muscle that Gem-alter players have, so they get those steps at once. Starting Bronze from ~170M instead would make every Bronze step a real goal.

### Brief 4 (owner, 4 Nov): Bronze 250M · Silver 450M · Gold 800M · Platinum 1.5B · Ruby 2.7B · Diamond 5B. Report only, NOT built.
- Target: Bronze under 30 min, Diamond about 15-30 h of focused training, from Alter 20 (220M a muscle).
- Model: ★10 with 2 Heracles (BASE LV 20), Alter 20, the Gem bench top, one muscle, one rep every 1.05 s. No PUMPED, BIG REP, Muscle of the Day or Run Cards.
- **EXP an hour on one muscle:** 12.5B at 220M, 5.9B at 1B, 3.6B at 2.7B, 2.7B at 5B, 1.1B at 30B (diminishing returns).

| Gates, from 220M | Bronze | Silver | Gold | Platinum | Ruby | Diamond |
|---|---|---|---|---|---|---|
| Brief 4, ★10 | 0 min | 1 min | 4 min | 12 min | 29 min | **74 min** |
| Brief 4, owner maxed | 0 min | 1 min | 2 min | 5 min | 13 min | 33 min |

- **Way off.** Diamond needs about 26B for 15 h, 34B for 22 h, or 42B for 30 h (★10).
- **Proposed:** the same ×2.61 a tier from Bronze 250M to Diamond 30B: **250M · 650M · 1.7B · 4.4B · 11.5B · 30B**.

  | Proposal, from 220M | Bronze | Silver | Gold | Platinum | Ruby | Diamond |
  |---|---|---|---|---|---|---|
  | ★10 | 0 min | 3 min | 14 min | 62 min | 4.4 h | 18.3 h |
  | Owner maxed | 0 min | 1 min | 6 min | 27 min | 1.9 h | 8.0 h |

- **Also proposed:** start the Bronze steps from 220M (the Alter 20 goal), not the Gem top's 12.4M, so every step comes after Alter 20.
- Studio still has the brief-3 gates (250M ... 100B) until the owner picks.

### Brief 5 (owner, 4 Nov): back to 250M · 800M · 2.5B · 8B · 30B · 100B (already in Studio since brief 3)
Hours of pure lifting from Alter 20 (220M a muscle). One muscle, Gem bench top, Alter 20, Pro gear, one rep every 1.05 s; no PUMPED, BIG REP, Muscle of the Day or Run Cards.

| Player | Bronze 250M | Silver 800M | Gold 2.5B | Platinum 8B | Ruby 30B | Diamond 100B | EXP/h at 220M / 30B |
|---|---|---|---|---|---|---|---|
| ★0, 2 Voltas | 1 min | 33 min | 3.5 h | 20.1 h | 145.8 h | 886 h | 1.6B / 137M |
| ★3, 2 Bronze Titans | 0 min | 9 min | 57 min | 5.6 h | 40.5 h | 246 h | 5.6B / 494M |
| ★5, 2 Bronze Titans | 0 min | 8 min | 48 min | 4.6 h | 33.7 h | 205 h | 6.8B / 593M |
| ★10, 2 Heracles | 0 min | 4 min | 26 min | 2.5 h | 18.3 h | 111 h | 12.5B / 1.1B |

- **★0 reaches Silver in 33 min**, inside the 2 h check.
- **★10 Diamond is ~111 h, not ~25 h.** EXP a rep falls as the muscle grows (diminishing returns ~1/level), so a ★10 earns 12.5B/h at 220M but only 1.1B/h at 30B. The average from 220M to 100B is ~0.9B/h, not 4B/h.
- Diamond at ~25 h for a ★10 would be ~37B. Waiting for the owner's call; the gates in Studio stay 250M ... 100B.

