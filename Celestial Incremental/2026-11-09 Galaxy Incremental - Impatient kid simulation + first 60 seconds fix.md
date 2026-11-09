---
date: 2026-11-09
tags: [galaxy, simulation, onboarding, first-minute, prompt, claude-code]
---
# Galaxy Incremental: impatient-kid simulation + the first 60 seconds fix (9 Nov)

Owner: "run an simulation as an impatient kid and keep improving the first 60 seconds until they stay engaged without getting bored of the game."
Code: `Calc\kidsim.py` + `Calc\variants.py` (Python, run `python variants.py`). Economy = the LIVE build read from Studio on 9 Nov (EconConfig, GameConfig.FirstSession, GalaxyEconService: tutorial, comets, pays). Related: [[2026-11-09 Galaxy Incremental - Prompt - Fix the 3-minute quit (first 10 minutes pacing)]] (already built in Studio).

## How the "kid" works
- Follows LUMI's arrow (the tutorial step), otherwise taps the cheapest green button. Reacts in 0.6-2.2 s; walking onto a pad takes 3-6 s more. Catches 45-90% of comets.
- A **boredom meter** fills 1/s when nothing happens (0.5/s with something to press, 0.7/s when the NEXT bar is about to fill, 1.4/s when nothing is within 30 s, x1.3 after 25 s with nothing NEW).
- Rewards empty it: a purchase (smaller each time the same thing is bought), something NEW (Moon, pad, +BODY, named tier: much more), comets, level-ups, tutorial steps, gifts, the Supernova. Rewards also wear off the more a kid has had.
- **Patience** (dead time before quitting) is random per kid, median 11 s. Tested at 7, 11 and 16 s.
- A model, not real players: use it to compare designs, then check the real onboarding funnel after the update.

## What it found in the LIVE build
- **0-10 s:** 0 stardust, 1 stardust/s. The only thing to press is the free FIRST LIGHT perk. The first real buy (pad 1, 15) comes at ~10-12 s.
- **10-33 s:** the tutorial needs Asteroid Lv 3 (18 + 32), and income is 1.5-3/s, so there's ~10 s of nothing between buys. **No comets at all during tutorial steps 1-5** (the server waits until step 6).
- **Result: ~15% of kids quit before 15 s and ~20% before 60 s** (patience 11 s). With very impatient kids (7 s) **over half are gone by 60 s**.
- After ~35 s everything speeds up (tutorial pays + the Moon + comets), so the live problem is really the **first 30 seconds**.

## The iterations (1,500 kids each, patience 11 s)
| Version | Change | Stay 30 s | Stay 60 s | Stay 3 min | Stay 5 min | Longest dead stretch in min 1 (median) |
|---|---|---|---|---|---|---|
| A | live | 85% | 80% | 80% | 77% | 10.2 s |
| B | + a 30 stardust WELCOME GIFT at 1.5 s | 85% | 85% | 85% | 80% | 9.6 s |
| C | B + pads 1-3 cost 5 / 25 / 80 (were 15 / 60 / 150) | 96% | 96% | 94% | 88% | 7.3 s |
| D | C + Asteroid levels 1-5 at half price | 100% | 100% | 97% | 88% | 6.8 s |
| E | D + comets from 8 s, every 15 s, also during the tutorial | 100% | 100% | 99% | 93% | 6.5 s |
| **F** | **E + the 2nd Asteroid (+BODY) costs 25 (was 50)** | **100%** | **100%** | **99%** | **95%** | **6.5 s** |
Sensitivity: very impatient kids (7 s): live 43% stay 60 s → F **100%** (88% at 5 min). Patient kids (16 s): 95% → 100%.
The Supernova lands at about the same time in A and F (the fix doesn't make the run shorter), so the later numbers stay as tuned.

## F: the first 30 seconds, second by second (sim)
- 1.5 s: WELCOME GIFT +30 (LUMI: "A gift to start your galaxy!")
- 2 s: FIRST LIGHT (free perk)
- 4-5 s: Asteroid Lv 2 and 3 → tutorial steps 1+2 done, reward pop
- 6.5 s: pad 1 STONE ISLAND (the island changes)
- 8 s: first COMET
- 9 s: the MOON flies in
- 10 s: a 2nd Asteroid joins the orbit
- 11-16 s: pads 2 and 3, more levels
- 23 s: the tutorial comets step, the PLANET at 25 s
- Something new happens about every 1-3 s for the first minute.

```text
GALAXY INCREMENTAL – THE FIRST 30 SECONDS (impatient-kid simulation, owner 9 Nov). Do NOT playtest and do NOT publish: the owner tests. Small number + tutorial changes only, no new systems.

The simulation (vault: "2026-11-09 Galaxy Incremental - Impatient kid simulation + first 60 seconds fix") found that the live build loses ~20% of kids in the first minute: 0 stardust at 1/s, the first buy at ~11 s, then ~10 s gaps until ~33 s, and NO comets during tutorial steps 1-5. Make these 5 changes (each as a config value in EconConfig / GameConfig.FirstSession, so they can be tuned):

1. WELCOME GIFT: a new save gets +30 stardust at ~1.5 s after spawning, with LUMI's line "A gift to start your galaxy!", a stardust burst on the counter and a coin sound. Once per account (save flag). FirstSession.WelcomeGift = 30.
2. PADS 1-3 cheaper: STONE ISLAND 5 (was 15), STAR TILES 25 (was 60), BRASS RIM 80 (was 150). Old saves keep their pads; nothing anyone owns changes.
3. EARLY ASTEROID LEVELS: the Asteroid's UPGRADE cost is x0.5 while its level is under 5 (Econ.Cost; FirstSession.EarlyAsteroid = { Levels = 5, Mult = 0.5 }). Every run (it's worth a few stardust after a Supernova, so it doesn't change the run times).
4. COMETS FROM 8 SECONDS: in run 1 the first comet comes ~8 s after spawning and then every 15 s (MinEvery stays 15), INCLUDING tutorial steps 1-5 (remove the "no comets during steps 1-5" wait in cometLoop). Keep step 6 "Tap 2 comets!" (most players will already have caught them, so it just completes). LUMI's first comet line: "Tap the comet!" with the guide arrow on it.
5. THE 2nd ASTEROID: the Asteroid's first +BODY (copy 2) costs 25 (was 50). Later copies unchanged. FirstSession.FirstCopy = 25.

Also check: the free FIRST LIGHT perk is pressable within 2 s of spawning (start XP 2), and the HUD NEXT goal points at something reachable in under 10 s for the first minute.

Keep saves safe. REPORT (short): the files changed, the new config values, and anything that didn't fit.
```
