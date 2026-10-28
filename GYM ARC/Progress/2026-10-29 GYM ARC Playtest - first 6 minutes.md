---
date: 2026-10-29
tags: [gymarc, playtest, retention, onboarding]
status: findings + fixes planned
---
# Playtest: the first 6 minutes as a new player (29 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC The whole game plan (research loop)]] · Fixes go into [[2026-10-29 GYM ARC Prompt - 106 First 3 minutes]] (addendum below) and [[2026-10-29 GYM ARC Prompt - 91 Future You and Progression Road]]

Claude played GYM ARC in Studio as a brand-new player (FreshPlayer, phone layout, touch), menu → tutorial → first Growth Spurt, and judged every screen against the research ([[Playbook notes - Whole-game research (Oct 2026)]]).

**Result:** first Growth Spurt at about **6 minutes** (research target ~2 min; Roblox counts quits under 60 s and at 61-180 s against us). The game itself works (no errors), the first rep reward, the 25/50/75% milestones, the Train-next window, GO TO teleports and the gold transformation with the height counting up are good. The problems are **interruptions, clutter and too much at once**.

## What's wrong (worst first)
| # | What I saw | Why it hurts (research) | Fix |
|---|---|---|---|
| 1 | The tutorial stops you **at 50% and again at 83%** of the first Growth Spurt ("TAP STOP" → squat rack → open Stats → walk to Coach Dex → tap the card → skate) | Goal gradient: people speed up near a reward; we pull them away right before it. Half our players leave before the first spurt | 106: 4 steps, no forced STOP, never interrupt while the bar is filling |
| 2 | While lifting, the **Growth Spurt bar is hidden** (right column collapses on a machine) | The one goal isn't visible during the one action | 106: a slim Growth Spurt bar on the machine HUD |
| 3 | On the bench the camera shows plates and legs, **not your body** | The fantasy is watching muscles grow | 106: machine camera frames the lifter's upper body |
| 4 | Minute one: top band + GO TO button + a 2-page Coach Dex dialog at the same time | Kids skip text (NN/g); "show, don't tell" (Roblox docs) | 106: one line max, no 2-page dialogs |
| 5 | **6 locked tiles** on the left from the first second | Clutter in minute one | 106: hide a locked tile until its unlock is the next step |
| 6 | "Stats" shows giant numbers floating over the world (Strength 3,797,252; Chest 1,475,247; Core 0) over the GO TO button and dialog | Meaningless to an 8-year-old; covers the UI | 106: Stats tip after Spurt 1 only; show 6 group bars, not raw numbers |
| 7 | Right after the tutorial: **Quests window + a free trainer roll + Coach Dex + playtime toast** at once | Popup pile-up | 106: one thing per minute, after the first spurt |
| 8 | At READY TO GROW: 6 messages at once (NEW PERSONAL RECORD, 1 rep to unlock +5 lb, NEW WEIGHT UNLOCKED, Personal best!, TAP TO GROW card, the popup) and **3 TAP TO GROW buttons** | The best moment is noisy | 106: when READY, silence every other toast; one TAP TO GROW |
| 9 | The transformation is framed with a machine sign ("Abs 63%"), a huge "E OCCUPY" prompt and the trainer in the shot | The "moment of joy" looks messy | 106: hide signs, prompts, trainers and tags during it |
| 10 | After Spurt 1, **NEW badges on 5 tiles + 2 red dots** (Inventory, Genetics, Poses, Crew, Trainers, Stats, Muscles) + DEAL + Daily + quest + INVITE + CODES + FREE 1,000 + a Coach Dex dialog | The plan says 3-4 things per step | 91 unlock map (Beach Gym, Trainers, Inventory at Spurt 1; the rest later) |
| 11 | No "Next: BEACH GYM" moment after Spurt 1 (the card says "tap for your physique") | Always show the next goal | 106 item 6 |
| 12 | Today's quest for a 5-minute-old player: "Run 1 km on the treadmill" | Pulls away from the growth goal | 106: first-session quests point at the Growth Spurt |
| 13 | The **SKIP pill stays** on screen after the tutorial ended | Bug | 106 |
| 14 | DEAL on the Shop and FREE 1,000 / INVITE / CODES appear right after the tutorial, before the first spurt | No offers before the first reward (Playbook) | 106: after Spurt 1, one at a time |
| 15 | Funnel step "02. Genetics kept" fires although there is no genetics screen any more | Fake funnel data | 106: Onboarding_v2 funnel |
| 16 | **Coach Dex is a shirtless orange muscle body** behind the desk, clipping into it | The account was hit once over a muscle-body image; kids' game | Clothe Coach Dex (tank top), fix the clipping (small Studio fix) |
| 17 | Your own title tag ("Crew Member") sits on top of the machine's OCCUPY prompt | Covers the button you need | 106: hide your own tag near machines |
| 18 | Menu tagline is "No days off." / "Everyone starts tiny."; the hook "grow taller" isn't said; the flyover camera passes through a brick wall | First screen must sell the hook | Menu line "Lift to grow taller." + fix the flyover path |
| 19 | After the spurt the muscles reset, so you look **smaller** right after growing | Loss aversion (same as the alter problem) | 96's "never look smaller" floor also for Growth Spurts |
| 20 | 7,193 GUI objects and ~22,000 streamed parts on the client in the starter gym | Phones (2-4 GB RAM) | 100/108: build panels when first opened; test on a cheap Android |
| 21 | A free trainer roll arrives before Spurt 1 (trainers open at Spurt 1 in the plan) | Too much before the first goal | 91 unlock map |

## Screenshots
![[GYM ARC/Screenshots/2026-10-29 Playtest/01 Menu.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/02 First second - three texts and six locks.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/03 On the bench - body hidden, no spurt bar.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/04 Tap STOP interrupts at 50 percent.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/05 Stats numbers over the screen.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/06 Coach Dex shirtless and clipping.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/07 Trainer roll over quests popup pile.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/08 HUD flood after tutorial.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/09 Ready to grow - six messages.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/10 Transformation with sign and prompt.jpg]]
![[GYM ARC/Screenshots/2026-10-29 Playtest/11 After spurt 1 - everything unlocks.jpg]]

## Not playtested yet
Alters (8-9 wall), Strongman Yard, posing shows, the Hall of Fame ceremony on a phone, a real low-end phone, 10+ players in one server.
