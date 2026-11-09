---
date: 2026-11-09
tags: [galaxy, progress, balance, sim, heists, crew, forge, jetpack, sat21]
status: sim done, numbers PROPOSED (nothing changed in Studio)
---
# Galaxy Incremental: Sat 21 balance sim (physics + human timing)

Owner (9 Nov): "calculate the balancing urself and also not just calculating in maths, in physics and how long it takes for the player to think and their brain and response time too".

- **Code:** `Calc/balance_sat21.py`. Run `py balance_sat21.py` from the Calc folder (~2 min, seeded, same result every run). `--fast` = smaller samples.
- **Built on:** [[2026-11-09 Galaxy Incremental - Sat 21 update built (creatures, phone mode, jetpack, crew heists)]], `kidsim.py` / `variants.py` (variant G), the bot timelines in [[2026-11-06 Galaxy Incremental phase 2 - REPORT]].
- **Methods:** Impatient kid simulation (minutes 0-5 check), Data first (RollsPerHour must be fixed from real ForgeRoll data later).
- It's a model, not real players. Check it with Heist_Grab / Heist_Tackle / Heist_Bank / CrewSupernova / ForgeRoll after the publish.

## What the sim does
1. **Physics:** the jump and the jetpack, step by step at 240 Hz. Gravity felt 95, Lift 60, rise cap 26, fuel 3 s. Then the map: 8 islands, bridges, plaza, the void gaps.
2. **Kids:** 3 types, each with reaction time, thinking time, attention, aiming and walking (table below).
3. **Heists:** a 2D sim, 10 steps a second. A comet lands. Kids notice the toast, decide, walk the bridges (or fly). Grab or hold. Carry at 0.7x. Chasers follow (straight at the carrier, or cutting him off). Tackle at 3.5. Scramble. Bank or burst.
4. **Crews:** how fast the Core fills; whether the crew can gather in 30 s; hours to the reward cap.
5. **Forge:** sky-comet catches, Essence and rolls per hour, rolls over ALL players, the real SECRET rate, what mutations do.
6. **Minutes 0-5:** kidsim with and without loose comets on a new player's island.

**Server size:** max 8 players (8 islands; Creator Hub Max Visitor Count 8). So I used 3 / 6 / 8, not 10-12.

## The human numbers (assumptions)
| | grinder (PC, ~11-12) | chaos kid (PC, ~10-11) | mobile kid (phone, 8-9) |
|---|---|---|---|
| simple reaction time (median) | 0.33 s | 0.36 s | 0.48 s |
| choice time (Hick's law slope) | 0.18 s/bit | 0.20 s/bit | 0.25 s/bit |
| thinking "is it worth it, where do I go" | 1.0 s | 0.6 s | 2.0 s |
| attention lapse (chance / size) | 8% / 2-5 s | 12% / 1.5-4 s | 22% / 2-7 s |
| notices a toast (mean extra s / never) | 1.5 s / 8% | 2.5 s / 15% | 4.0 s / 30% |
| path length vs straight line | 1.08-1.18x | 1.15-1.32x | 1.25-1.45x |
| thumbstick speed | 100% | 100% | 90% |
| press the prompt | 0.15 s (E) | 0.15 s | 0.6 s (find + tap) |
| AFK / looking away | 8% | 5% | 22% |
| goes for others' comets | 55% | 85% | 35% |
| chases a carrier | 95% own / 60% others | 95% / 80% | 80% / 40% |
| cuts the carrier off (vs follows him) | 70% | 20% | 10% |
| uses the jetpack | 80% | 90% | 35% |
| carrier gets lost ("which bridge is mine?") | 2% | 8% | 15% (+3-10 s) |

Where the numbers come from (rules of thumb):
- **Reaction time:** adults ~0.25 s for a simple visual signal. Children are slower and the gap shrinks with age (Kail 1991: processing speed grows with age; an 8-year-old is roughly 1.5-2x an adult). So 0.35-0.5 s for 8-12.
- **Choice time:** Hick-Hyman law: time = a + b × log2(choices + 1). Kids have a steeper b.
- **Lapses:** kids' reaction times have a long slow tail (mind-wandering). Modelled as a chance of +2-7 s.
- **Noticing:** "notice by time t" = (1 − never) × (1 − e^(−t/τ)). Young kids skip text toasts a lot.
- **Aiming:** Fitts' law: time = a + b × log2(distance/size + 1), plus ~0.5 bit for a moving target. Mouse: a 0.15, b 0.14-0.16. Finger: a 0.30, b 0.18. Phone targets under ~9 mm lose many taps (Parhi et al. 2006): miss chance 30% vs 8-18% on PC.
- **Camera turn** to find an off-screen comet: PC 0.8 s, phone 1.8 s. 30% of 8-9-year-olds don't turn the camera at all.
- **Walking:** kids don't walk straight lines (1.15-1.45x).
- **Mix in a server:** 20% grinder, 30% chaos, 50% mobile. About half of Roblox kids play on phones.

## 1. Physics: jump and jetpack
| flight | apex (studs) | air time (s) | range at 24 (studs) |
|---|---|---|---|
| plain jump (v0 45.6) | 10.9 | 0.96 | 23 |
| jump + 2.5 s thrust (Studio measured +67) | 70.5 | 3.99 | 96 |
| jump + hold Space until empty (a kid) | 83.5 | 4.60 | 110 |
| jump + pulse to hover (best possible) | 12.5 | 5.89 | 141 |

- The sim gives 70 studs for 2.5 s; Studio measured 67. Close enough: the model is right.
- **Ceiling (plaza + 120) is never reached from the ground:** one tank tops out at ~83 up.

| gap | studs |
|---|---|
| void between adjacent islands (edge to edge) | 54 |
| island inner edge to the plaza rim | 38 |
| longest void on ANY straight line on the map | 76 |
| one jump covers | 23 |
| one tank covers | 110 |

**So the jetpack can fly ANY straight line on the map:** across the void between islands, and from an island to the plaza without a bridge. A plain jump can't cross anything.

| islands apart | walk (bridges) | fly straight | jetpack saves |
|---|---|---|---|
| 45° | 117 studs, 4.9 s | 80 studs, 3.7 s | 32% |
| 90° | 160, 6.7 s | 143, 6.4 s | 11% |
| 135° / 180° | 188-198, 7.8-8.3 s | same | 0-3% |

The shortcut only matters between neighbours. Everything else goes through the plaza anyway.

## 2. Heists
### Carry time with nobody chasing (grab hold → bank)
| thief | home 45° away | 90° | 180° (far way) |
|---|---|---|---|
| grinder | 10 s (p99 17) | 13 s (p99 21) | 16 s (p99 22) |
| chaos | 11 s (p99 20) | 14 s (p99 24) | 17 s (p99 26) |
| mobile | 15 s (p99 24) | 18 s (p99 28) | 22 s (p99 31) |

**CarryLimit:** a mobile kid going the far way needs 31 s at the 99th percentile (the worst 1 in 100). 45 s is 14 s more than anyone needs.

### Duels: the owner is awake and chases after the toast (current rules)
Steal success. "home" = the owner is on his island but not next to the comet; "far" = on another island.
| thief \ owner | grinder (plaza, 45° / 180°) | chaos (plaza) | mobile (plaza) |
|---|---|---|---|
| grinder | 36% / 10% | 49% / 16% | 96% / 64% |
| chaos | 19% / 9% | 29% / 9% | 89% / 57% |
| mobile | 15% / 10% | 12% / 10% | 77% / 52% |

- **A PC owner who notices is a real danger:** thieves bank only 10-50%. The far way is the hardest (5-20%).
- **A phone owner almost can't defend:** thieves bank 52-100%. Slow notice (4 s), slow thinking (2 s) and a 90% thumbstick lose the race.

### The tackle loop (the biggest bug found)
Now the tackler can't grab for 1.5 s, but the tackled thief can re-grab at once. On PC he re-grabs in ~1 s (0.35 react + 0.15 press + 0.5 hold). The tackler is still next to him, so he tackles again, and again.

| rules | thief banks | owner gets it back | tackles per heist | 3+ tackles | p95 length |
|---|---|---|---|---|---|
| now | 43% | 57% | **5.9** | 38% | 38 s |
| proposed (below) | 45% | 55% | 0.5 | 0% | 18 s |

- In whole servers now, 83% of tackled comets ping-pong between the same two kids. It only ends when someone gives up. On a phone (0.6 s press) you lose the re-grab race, so it isn't fair either.
- **Proposed:** the tackled carrier can't re-grab for 3 s. The tackler waits 1 s (was 1.5). ONE 40 s timer per comet (a re-grab doesn't restart it).
- **Chains still happen:** with 6-8 players, 34-43% of comets get tackled, and 44-51% of those have 2+ tackles by different kids.

### Jetpack, portal, sensitivity
| case (owner on the plaza or far island) | thief banks |
|---|---|
| owner WITH jetpack | 49% |
| owner WITHOUT jetpack | 56% |
| portal allowed for carriers (7% use it) | 49% |
| portal blocked | 51% |

- **Jetpack for defenders:** thieves lose 7 points. It helps, but doesn't make defenders too strong. The 24 vs 16.8 speed gap is what decides chases.
- **Portal:** it barely changes the success rate. But a carrier who dives in has a 1 in 16 chance of an instant bank (own landing). The chaser just sees him vanish. It's a luck button in the middle of a chase. **Block it while carrying.**

| setting (proposed rules) | thief banks, all owners | thief banks, PC owners |
|---|---|---|
| TackleRange 2.5 | 61% | 47% |
| **TackleRange 3.5 (now)** | **47%** | **26%** |
| TackleRange 5 | 38% | 17% |
| CarrySpeed 0.6 | 35% | 11% |
| CarrySpeed 0.8 | 61% | 46% |

**Keep 3.5 and 0.7.** A chased carrier is in real danger (PC owners win ~3 in 4), and an unseen steal still works.

### Whole servers: what happens to each loose comet (current rules)
| players | owner grabs it | stolen + banked | nobody comes | median time |
|---|---|---|---|---|
| 3 | 68% | 19% | 13% | 10 s |
| 6 | 73% | 25% | 2% | 12 s |
| 8 | 76% | 24% | 0% | 13 s |

### Heist income vs normal play
"Normal" = passive income + sky comets (mid-game: a comet every ~35 s worth ~67 s of income).
| setting | players | grinder | chaos | mobile |
|---|---|---|---|---|
| **now: LooseEvery 60, Value 120** | 3 | **+53%** | **+57%** | +37% |
| | 6 | +26% | +33% | +21% |
| | 8 | +22% | +22% | +17% |
| **per island: 600/N s, Value 120** | 3 (180 s) | +18% | +19% | +12% |
| | 6 (100 s) | +16% | +20% | +13% |
| | 8 (75 s) | +18% | +18% | +14% |

| player | players | now | per island |
|---|---|---|---|
| active heister (always goes, always chases) | 3 / 6 / 8 | +67% / +39% / +35% | **+22% / +23% / +28%** |
| AFK-ish mobile kid (AFK 60%) | 3 / 6 / 8 | +34% / +9% / +8% | +11% / +5% / +6% |

- **Now, small servers pay far too much.** All comets go to 3 islands, so each owner gets one every 3 min and grabs it for 240 s of income. That's +140% of passive income for free.
- **Per island (600 s ÷ islands, 60-180 s)** keeps it at +12-20% for everyone and +22-28% for an active heister, at every server size. That's the 10-30% target.
- **Value 120 / owner x2: keep.** At 90 it drops to +9-15%, a bit low for "worth chasing".
- **Owners aren't punished:** a steal costs the owner nothing they had. An AFK-ish kid gets +5-11% from his own island, never more than playing.
- **Not counted:** time spent heisting means fewer sky comets caught. That's another reason not to go higher.

## 3. Crew Core + Crew Supernova
### Minutes to fill 10 points (active players)
| players | crew of 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| 4, now (60 s) | 38 | 22 | 15 | **12** |
| 4, per island (150 s) | 94 | 56 | 39 | 30 |
| 6, now | 62 | 32 | 22 | 17 |
| 6, per island (100 s) | 103 | 53 | 37 | 28 |
| 8, now | 70 | 34 | 22 | 20 |
| 8, per island (75 s) | 88 | 43 | **28** | **26** |

The target is every ~20-40 min for an active crew of 3-4, rarer solo. Per island hits it at every size: 26-39 min. Now, a full 4-player crew fills it in 12 min. **Keep Points 10.**

### The 30 s gather
Parts of the trip for a crewmate on the FAR island who does notice: notice 1-3 s (p90 7 s on phone), decide 1-3 s (p90 8 s on phone), walk 11-15 s. Total p90: 16 s grinder, 18 s chaos, **27 s mobile**.

| crew | 30 s (now) | 45 s | 60 s | 45 s + "whoever is in the ring counts (min 2)" |
|---|---|---|---|---|
| 2 mixed | 70% | 71% | 74% | 73% |
| 3 mixed | 59% | 63% | 64% | 95% |
| 4 mixed | 50% | 53% | 52% | **99%** |
| 4 mobile kids | 32% | 36% | 38% | 97% |

- **Time isn't the problem, AFK kids are.** "Every crewmate online" means one kid who looked away blocks the whole crew. More seconds barely help (50% → 52%).
- **Fix:** 45 s, and everyone in the ring when it ends gets the Crew Supernova (at least 2). If it fails, the Core stays full and they can try again.

### Reward: hours to the cap
| crew (8 players, per island) | min per Crew Supernova | hours to +40% (now) | the x2 10 min adds |
|---|---|---|---|
| solo | 88 | 29 | +11% |
| crew of 2 | 44 | 15 | +23% |
| crew of 3 | 30 | 10 | +33% |
| crew of 4 | 29 | 10 | +35% |

- +40% permanent = x1.4 income. The Supernova need grows x1.7 per Supernova, so x1.4 = about 0.6 of one Supernova (~6 min of progress). It can't break the economy.
- vs passes: the x2 pass is +100% and VIP +25%, both instantly. The free +40% takes ~10 hours of crew play. VIP still makes sense (instant, and it stacks).
- Kids want a big number ("x1.2 and I'm uninstalling"). **Keep +2% and cap 40%, and keep x2 for 10 min.**

## 4. Star Forge
### Sky comets (live 9 s)
| kid | caught | time to catch (p50 / p90) |
|---|---|---|
| grinder PC | 86% | 2.3 / 5.1 s |
| chaos PC | 77% | 2.8 / 5.8 s |
| mobile phone | 44% | 4.1 / 7.6 s |

Phones lose comets in 3 places: noticing (often muted, so no sound cue), turning the camera, and missing small taps.

### Rolls per hour after Ignition 1
Supernova Essence = 1 + floor(Supernovas/5), as given. Supernova times are from the bot (run 4), slowed down for slower kids. Daily: streak ~2.8 + quests + gifts at 10/20/60 min.
| CometsPerNext | kid | hour 1 | hours 2-3 | hours 4-10 | from comets |
|---|---|---|---|---|---|
| 25 | grinder / chaos / mobile | 56 / 53 / 47 | 46 / 44 / 43 | 58 / 53 / 45 | 4 / 3 / 2 |
| **10** | grinder / chaos / mobile | 62 / 58 / 49 | 53 / 48 / 45 | 64 / 58 / 47 | **10 / 8 / 4** |

- An active post-Ignition player rolls **45-65 an hour**, not the 15-25 guessed in the build note. Plus a ~41-48 Essence burst at Ignition.
- **CometsPerNext 10 (was 25):** +6 rolls/h for a grinder, +2 on a phone. Small; it gives comets a Forge job. **Keep 10.**

### Rolls over ALL players → the real SECRET rate
Lifetime playtime per player is lognormal (most kids leave early; a few play for hours).
| population | reach Ignition | rolls per player-hour | player-hours per SECRET with RollsPerHour 8 |
|---|---|---|---|
| today (3.5 min/DAU) | 2% | 21 (16 without the gift roll) | 744 |
| after the pacing fix (~25 min/DAU) | 26% | 53 | 301 |
| healthy, returning players | 40% | 71 | 225 |

- **RollsPerHour 8 is far too low.** Most player-hours come from the few kids who play for hours, and they roll 45-65 an hour. So a SECRET comes every **225-750 player-hours**, 3-9x more often than the 2,000 target.
- **RollsPerHour 50** (odds 1/100,000 = 0.001%) → ~1 per 1,900 player-hours after the pacing fix (4,700 today, 1,400 when healthy). Then fix it from data: ForgeRoll events ÷ player-hours.
- If the real Supernova Essence is 2 + floor(n/5) (the old code's NovaBonus 1 + base 1), rolls are ~10/h higher → use 60.

### Mutations: what one lucky pull does
Forge Stardust factor (best 3 Stardust cores; bonuses add): median 2.7 at 1 h after Ignition, 4.1 at 3 h, 7.2 at 10 h, 9.6 at 30 h.
"Skipped" = how many Supernovas the extra income is worth (need x1.7 each) × minutes per Supernova at that point.
| pull | bonus | 1 h after Ignition | 3 h | 10 h |
|---|---|---|---|---|
| GOLDEN Epic Stardust | +2.2 | x1.6 = 6 min | x1.3 = 5 min | 1 min |
| RAINBOW Epic Stardust | +4.5 | x2.5 = 11 min | x1.8 = 11 min | 7 min |
| VOID Common Stardust | +2.0 | x1.5 = 5 min | x1.2 = 4 min | 0 |
| VOID Rare Stardust | +8.0 | x3.7 = 16 min | x2.7 = 19 min | 14 min |
| **VOID Epic Stardust** | **+15** | **x6.3 = 23 min** | x4.4 = 28 min | x2.8 = 23 min |
| VOID Legendary Stardust | +30 | x11.9 = 30 min | x8.0 = 39 min | 36 min |
| SECRET Nebula Whale (30) | +29 | x11.5 = 30 min | x7.8 = 39 min | 35 min |
| GOLDEN SECRET | +43.5 | x16.8 = 35 min | x11.3 = 46 min | 43 min |

| how long until (hours after Ignition) | grinder | mobile |
|---|---|---|
| any GOLDEN | 23 min | 27 min |
| any RAINBOW | 4 h | 4 h |
| any VOID | 38 h | 44 h |
| a VOID **Stardust** | 229 h | 266 h |
| a VOID Epic+ Stardust | ~4,600 h | ~5,300 h |

- **A Void feels like a big jump, not hours skipped.** Even a Void Epic Stardust (x6 income right after Ignition) is ~25 min of progress. A Void Legendary or a SECRET is 30-40 min. The income jump is huge, but the next Supernovas need x1.7 each, so it's soon caught up.
- Most real Voids will be a Common or Uncommon of a random kind: worth about a Legendary. That's the right size.
- **Keep Golden 1.5 / Rainbow 3 / Void 10 and SECRET mult 30.**
- **The exception is LUMI's gift roll** (a brand-new kid's first roll, ~minute 3). If the gift core works before Ignition, then 1 in 16,000 new kids gets a SECRET (x30 income in run 1), and 1 in 12,000 a Void Stardust (x3). That breaks the tuned first minutes. **The gift roll should not roll SECRET or VOID.**

## 5. Minutes 0-5 (kidsim variant G)
| version | new kid gets one in 5 min | stay 60 s | stay 3 min | stay 5 min |
|---|---|---|---|---|
| G (no loose comets on new islands) | 0% | 100% | 99.3% | 94.9% |
| G + loose comets, 6 players | 57% | 100% | 99.4% | 94.1% |
| G + loose comets, 3 players | 81% | 100% | 99.4% | 95.3% |

- The update doesn't change the first-minute buttons or timers. Stay % doesn't move.
- **But** if loose comets land on a new player's island (now only "can't be robbed" is stated), 57-81% of new kids grab one in minutes 0-5. It's worth **5.5x everything they've earned so far** (p90: 50x). That's a big unplanned jump in the pacing we tuned.
- **Fix:** loose comets land only on islands whose owner has 1+ Supernova (and count only those islands in LooseEvery). If the code already does this, nothing to change.
- (kidsim's economy runs faster than the real game, so I didn't use its Supernova times.)

## Recommendations
| setting | now | recommended | why |
|---|---|---|---|
| `EconConfig.Heist.LooseEvery` | 60 s for the server | **600 ÷ eligible islands, min 60, max 180** (8 → 75 s, 6 → 100, 4 → 150, 3 → 180) | each island gets one about every 10 min. Heists = +12-28% on top at every server size (now +53-57% with 3 players). The Core fills in 26-39 min |
| where loose comets land | any owned island | **only islands whose owner has 1+ Supernova** | keeps minutes 0-5 as tuned (a loose comet = 5.5x all a new kid has earned) |
| `Heist.Value` / `OwnerGrabBonus` | 120 s / x2 | keep | with the per-island rate it's +22-28% for active heisters, +5-11% for AFK-ish kids |
| `Heist.MaxLoose` / `LooseLife` | 4 / 180 s | keep | rarely more than 1 alive at once (0-13% unclaimed) |
| `Heist.CarryLimit` | 45 s, restarts on every grab | **40 s, one timer per comet** (a re-grab doesn't restart it) | a mobile kid going the far way needs 31 s (p99); one timer ends endless tackle loops |
| `Heist.TackleImmunity` (tackler can't grab) | 1.5 s | **1.0 s** | with the new lock below, the tackler wins a clean 1-vs-1 |
| NEW: tackled carrier can't re-grab | 0 s | **3 s** | fixes the ping-pong: 5.9 → 0.5 tackles per duel; chains with 3+ kids stay (44-51% of tackled comets) |
| `Heist.TackleRange` | 3.5 | keep | PC owners win back ~3 in 4; 2.5 → thieves 61%, 5 → 38% |
| `Heist.CarrySpeed` | 0.7 | keep | 0.6 → steals almost never work; 0.8 → chases rarely catch |
| `Heist.PickupHold` / `StealShield` | 0.5 s / 10 s | keep | the shield almost never triggers at 75-180 s spacing; harmless |
| Black Hole portal while carrying | allowed | **blocked** (a carrier walks over it like floor) | 1 in 16 = instant bank by luck, and the chaser loses him; success barely changes (49% vs 51%) |
| `Heist.Core.Points` | 10 | keep | 26-39 min for crews of 3-4 with the per-island rate; solo ~90 min |
| `Heist.Core.GatherSeconds` | 30 s, every crewmate online | **45 s, whoever is in the ring counts (min 2); the Core stays full if it fails** | AFK kids block it now: a crew of 4 makes it only 50% of the time. With the change: 99% |
| `Heist.Reward.PermanentPer` / `PermanentCap` | 0.02 / 0.40 | keep | +40% = ~6 min of progress; ~10 h of crew play to the cap (solo ~29 h) |
| `Heist.Reward.BoostX` / `BoostMinutes` | 2 / 10 | keep | +33-35% income while in an active crew of 3-4 |
| `ForgeFeed.CometsPerNext` | 10 | keep | +6 rolls/h grinder, +2 phone: small |
| `Forge.Secret.RollsPerHour` | 8 | **50** (odds 1/100,000) | real rolls are 21 (today) to 53-71 per player-hour. At 8, a SECRET comes every 225-750 player-hours, not 2,000. Fix again from ForgeRoll data |
| `Forge.Secret` mult | 30 | keep | ~30-40 min of progress: a big jump, not hours |
| `Forge.Mutations` powers | Golden 1.5 / Rainbow 3 / Void 10 | keep | a Void Epic Stardust (1 per ~5,000 h) = ~25 min of progress; most Voids are Common/Uncommon, worth about a Legendary |
| LUMI's gift roll | can roll SECRET / VOID | **no SECRET, no VOID** | a SECRET in minute 3 = x30 income in run 1 |
| `GameConfig.Jetpack` Fuel / Lift / MaxRise / RefillGrounded | 3 / 60 / 26 / 1.5 | keep | one tank = 110 studs across, 83 up. It crosses every gap (longest 76), saves 32% only between neighbours, and only takes 7 points off thieves |
| `Jetpack.CeilingAbovePlaza` | 120 | keep | unreachable from the ground (apex 83); only matters from high spots |

## Other findings (not asked, owner's call)
- **Phone owners can't defend** (thieves bank 88% vs them). In the sim, a "CHASE!" arrow on the "X IS TAKING YOUR COMET!" toast, pointing at the carrier, brings it to 71%.

## Limits
- The kid numbers are rules of thumb, not measured on our players. Phones and AFK matter most.
- Crewmates body-blocking chasers isn't modelled, so crews protect carriers a bit better than shown.
- Supernova timing after minute 90 is extrapolated (+10-14 min a run). The Black Hole (faster runs, more Essence) isn't in it.
- After the publish, check: Heist_Grab : Heist_Bank (steal success ~20-25% of comets), tackles per grab (~1, not 5+), CrewSupernova per crew-hour, and ForgeRoll ÷ player-hours (→ RollsPerHour).
