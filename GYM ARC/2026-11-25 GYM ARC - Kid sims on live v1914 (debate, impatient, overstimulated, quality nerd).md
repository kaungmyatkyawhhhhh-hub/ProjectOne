---
tags: [gym-arc, sims, onboarding, christmas]
date: 2026-11-25
build: v1914
---
# GYM ARC: kid sims on live v1914 (debate, impatient, overstimulated, quality nerd)

Owner asked (25 Nov, after midnight, autopilot): run the 4 kid sims on the game now. Done on the LIVE build: a Studio play-through as a new player (UI logged every 0.5 s + screenshots), then 4 Python models in `GYM ARC\Calc\`. Nothing in the game was changed, saved or published. The fixes go into [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]] as **Phase 2b**.

These are models with estimated weights, not real kids. The real check is the onboarding funnel and the 3-minute bounce in Creator Hub after the update (now: 15.2% leave < 60 s, 22.6% leave at 61-180 s).

## What a new player really sees (v1914, measured)
| Time | What happens |
|---|---|
| 0-18 s | intro cutscene, no control |
| 18-31 s | auto-walk to the Flat Bench |
| ~32 s | first rep |
| 36-90 s | tutorial bands (legs, core, back); NEW PERSONAL RECORD banner lands on the same top strip (~81 s) |
| 89 s | INVITE FRIENDS card appears and stays |
| ~96 s | GROWTH SPURT READY |
| 102-108 s | GROW transform |
| 109-114 s | Benny story shot |
| 114 s+ | left column opens at once: DEAL, STATS !, MUSCLES !, POSES NEW, DAILY !, later FREE 1,000, INVITE +10%, PLUS +20% |
| **~118 s → ?** | **STALL:** the BeatBenny step walks you to his table, nothing opens, Benny is hidden behind your own body, the band line blinks 3 s of every 12 s. It waited 40-120 s until E was pressed |

## 1. Impatient kid (`impatientkid_gymarc.py`)
Calibrated to the live funnel (calib.py), median patience 11 s. Stay %:
| Version | 15s | 30s | 60s | 2m | 3m | 5m |
|---|---|---|---|---|---|---|
| A live | 98 | 90 | 90 | 79 | 54 | 54 |
| B intro 8 s | 100 | 100 | 100 | 78 | 54 | 54 |
| C + Benny card opens by itself | 100 | 100 | 100 | 86 | 85 | 84 |
| D + GROW right when READY | 100 | 100 | 100 | 99 | 96 | 92 |
| E + Christmas free gift | 100 | 100 | 100 | 99 | 97 | 92 |
- Sensitivity: at 7 s patience the live build keeps only 28% past 3 min. How fast kids find Benny's E prompt decides the 3-minute number (0.05/s → 26%, 0.30/s → 74%), so **the Benny stall is the main cause of the 1-3 minute bounce**.

## 2. Overstimulated kid (`overstim_gymarc.py`)
Every element from the play-through with its time, screen strip, weight, KEY or not, and word count. Ages 7-12, 3-3.5 attention slots, reading 1.5-3 words/s.
| Version (cumulative) | Overload s / 10 min | KEY missed (7 y) | Collisions |
|---|---|---|---|
| A live | 370 | 50% of 18 | 1 (CORE band x PERSONAL RECORD) |
| B PERSONAL RECORD as a side toast | 370 | 50% | 0 |
| C INVITE card only after Growth Spurt 2 | 290 | 50% | 0 |
| D calm HUD before Growth Spurt 2 (no offer tiles, no red badges) | 15 | 50% | 0 |
| E Benny card opens by itself, ≤ 15 words | 7 | 58% of 15 | 0 |
| F intro 8 s | 7 | 58% | 0 |
| G KEY lines stay words/1.5 + 0.5 s | 10 | 55% | 1 |
| H one queue per screen strip | 7 | 42% | 0 |
| **I side HUD hides under a centre card; Benny story 7.5 s** | **0** | **28%** | **0** |
- Live: the most-missed KEY messages are the coach's welcome line (gone before read), Benny's card (opens while the screen is overloaded), the BeatBenny line (blinks off before a kid reads it).
- What's left in I: only the slowest 7-year-olds (~1 word/s) miss the short tutorial lines. Next step if needed: icons/arrows instead of words, or min time at 1 word/s.
- Goal (0% missed) not fully reached; overload goal (< 5 s) reached.

## 3. Quality-nerd kid (`qualitynerd_gymarc.py`)
Route of minute 0-10: spawn gym → bench → Benny's table → beach (75%) → Hall of Fame plaza (55%) → ProGym (40%). A look every 2 s; a still tell counts once per visit.
| Version (cumulative) | Tells / 10 min | Wows | Like % | Top tell |
|---|---|---|---|---|
| A live | 8.7 | 3.5 | 0 | trainer ghost over the camera |
| B Benny: camera to his face + card opens | 6.7 | 3.4 | 8 | trainer ghost |
| C plaza black box → gold trophy centrepiece | 6.0 | 3.9 | 17 | trainer ghost |
| D blank screens → leaderboards / posters | 5.1 | 4.3 | 47 | trainer ghost |
| E trainers fade when between camera and player | 2.7 | 4.3 | 99 | same prop again |
| F real palm leaves, sign on a post | 1.2 | 4.3 | 100 | same prop again |
| G Christmas dressing | 1.2 | 5.8 | 100 | same prop again |
| **H 3 plate/rack variants** | **0.4** | **5.8** | **100** | - |
- Wows already there: the GROW transform, the Benny story shot, the beach, the Hall of Fame statues, the ProGym city view.
- Like % jumps all-or-nothing (as the method warns); trust the tells column.

## 4. Debate kids (`debatekids_gymarc_v1914.py`)
3,000 friend groups of 3-5, our game + 3 random rivals.
| Version (cumulative) | Everyone agrees | 1st pick |
|---|---|---|
| V0 live | 4% | 7% |
| V1 first-3-minute fixes | 8% | 15% |
| V2 calm offers | 18% | 31% |
| V3 lag pass | 35% | 45% |
| V4 play together | 35% | 47% |
| V5 ranked PvP | 60% | 64% |
| V6 Christmas | 60% | 69% |
| V7 + marketing crowd 4 | 100% | 94% |
- Robustness (±1 on every score): worst 57%. The crowd score is the edge: it needs **crowd 5** for margin. At crowd 2-3 it stays ~60%: "nobody plays it, it's dead" is a marketing problem (ads + Christmas), not design.
- Design objections that remain after Christmas: lag on cheap phones, no real play-together, no ranked PvP. These are for after Christmas.

## What to build (Claude Code)
The full prompt is **Phase 2b** in the Christmas brief. In short:
1. Benny's card opens by itself at his table, the camera shows his face, the line stays on, ≤ 15 words (`BennyAutoOpenDelay = 0.6`, `BennyCamFocus = true`).
2. GROW ≤ 1.5 s after READY (`GrowReadyGap = 1.5`).
3. Intro 18 s → 8 s (`IntroCutsceneLength = 8`).
4. Calm HUD until Growth Spurt 2 (`CalmHudUntilSpurt = 2`); INVITE card after GS2, never on a machine.
5. One queue per screen strip; PERSONAL RECORD/notifications as side toasts during the tutorial; KEY lines ≥ words/1.5 + 0.5 s; side HUD hides under a centre card.
6. Benny story shot 7.5 s; the FREE GIFT waits in the same queue.
7. The 6 cheap-looking spots: trainer fade, plaza trophy, live screens, palm meshes, sign post, prop variants.
- Re-run the impatient sim after: spacing things out added no dead time (the queue moves lines by seconds, not tens of seconds).

## Files
- `GYM ARC\Calc\impatientkid_gymarc.py` + `_results.txt`, `calib.py`
- `GYM ARC\Calc\overstim_gymarc.py` + `_results.txt`
- `GYM ARC\Calc\qualitynerd_gymarc.py` + `_results.txt`
- `GYM ARC\Calc\debatekids_gymarc_v1914.py` + `_results.txt`
