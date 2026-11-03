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
