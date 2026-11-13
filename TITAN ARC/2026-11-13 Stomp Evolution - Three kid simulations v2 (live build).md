# Stomp Evolution - Three kid simulations v2 (live build, 13 Nov 2026)

What was tested: the live Studio build after city v2, the landmarks, the giant fixes, the 1 s evolve, the phone UI and upgrades on screen.
Code and results are in `Calc/`:
- `kid_1311.py` + `livekid2.py`
- `nerd_city_v2.py`
- `debate_1311.py`
- the `*_results.txt` files

These are models built on estimated scores. The real check is a friends test plus the onboarding funnel after launch.

## 1. Impatient kid (2,000 kids, median patience 11 s)
| version | 5 min stay | @7 s | @16 s | 1st evo | longest dead gap |
|---|---|---|---|---|---|
| A 12 Nov evening (3.2 s evolve) | 78% | 47% | 94% | 18.1 s | 61 s |
| **B LIVE now** (1 s evolve + landmarks as goals) | **87%** | 56% | 97% | 16.1 s | 59 s |
| C + "NEW!" smash index | 91% | 63% | 99% | | 54 s |
| D + playtime gifts at 1/3/5 min | 90% | 63% | 98% | | 52 s |
| E + golden props 1 in 80 | 92% | 69% | 98% | | 49 s |
| F + city event every ~90 s | **97%** | 81% | 100% | | 44 s |

- Every kid stays 100% through minute 3.
- The losses come in minutes 3-5: between the School (~150 s) and the Mall (~270 s) nothing new happens.
- Playtime gifts alone don't help. Keep them for retention, not for the first minutes.

## 2. Quality nerd (2,000 kids, 10-minute walk)
- **The live build is L5: 2.0 tells per 10 min, 99% likes, 30 wows.** That is under the goal of 3.
- The only tell left: districts that look the same.
- The district tint, haze and name sticker are already live (SE_Districts). With those, L6 scores 0.0 tells.
- Per-district music is the last piece.

## 3. Debate kids (3,000 friend groups, rivals = top games Nov 2026)
Rivals: Escape Tsunami For Brainrots, Grow a Garden 2, Brookhaven, Steal a Brainrot, Animal Hospital, Fish It!, 99 Nights, Blox Fruits, and genre games. They calibrate at 16-35% "everyone agrees". A dying game lands at 1%.

| version | agree | 1st pick | top objection |
|---|---|---|---|
| **L0 LIVE** | **34%** | 48% | "nobody plays it, it's dead" (1239), "there's no real fighting" (1160) |
| L1 + Sumo Ring (size brackets) + Rampage | 59% | 62% | "it's dead" |
| L2 + full servers (fill fullest first, NPC stompers) | 100% | 85% | none |
| L3 + smash index, golden 1/80, event 90 s | 100% | 89% | none |
| L4 + silly squeaky props, ragdoll pedestrians | 100% | 90% | none |
| L5 + visible weekly updates | 100% | 92% | none |
| L6 + launch push (marketing) | 100% | 94% | none |

- Robust to every score ±1: 100% agree.
- If the launch crowd is only 2-3/10, agreement drops to 59%. "It's dead" is a marketing and server-fill problem, not a design one.
- Looks, the first minute and phone support are no longer objections. They were the top three on 11 Nov.

## What to build next (all three sims agree)
1. **PvP: Sumo Ring with size brackets + Rampage.** This is the only design objection left.
2. **City event every ~90 s.** Biggest gain in the impatient sim (+10 points at 5 min).
3. **Smash index + golden 1/80.**
4. **Full servers / NPC stompers.**
5. **Per-district music.**
