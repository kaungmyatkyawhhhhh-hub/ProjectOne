---
date: 2026-10-21
tags: [gymarc, progress, playtest]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Playtest fixes

Prompt: [[2026-10-21 GYM ARC Prompt - 20 Playtest fixes]]. From [[2026-10-20 GYM ARC Playtest review]].

## What changed
1. **Tutorial shake blocker:** the DRINK SHAKE button sits left of the stamina bar (on and off machines, 44 px tall). The step says "Tap the shake!" with a bouncing gold arrow on it. After 15 s the shake is drunk for the player. Other steps that could get stuck (Open Stats, Open Muscles while on a machine) have "Tap STOP, then..." lines and finish after 40 s anyway. See [[GYM ARC - Tutorial]].
2. **Less waiting:** stamina pacing by Growth Spurt in `Config/Stamina.Pacing`. Running out = "RECOVERING 6s" on the machine (10 s from empty), then reps start again. See [[GYM ARC - Stamina and Treadmills]].
3. **What to train:** "Needs LEGS" on the Growth Spurt card and on a small card on machines; a tap opens "Train next" with GO buttons (glowing path); a hint when the machine doesn't help; red groups on the Body Map. See [[GYM ARC - Growth Spurts]].
4. **Rewards you can see:** NEW WEIGHT UNLOCKED (and you move up to it), QUEST DONE, NEW TITLE, LVL UP popups, queued. READY TO GROW popup over everything. See [[GYM ARC - Machine HUD]].
5. **Pacing:** first Growth Spurt goal level 15 -> 9 (~5 min in the simulator), spurt 2 58 -> 56 (keeps 15 min). Later goals unchanged.
6. **Store:** opens on Auras (most are earned by playing or coins); the menu's SHOP button too. Robux passes are the last tab.
7. **Found while testing, fixed:** windows (Quests, Store...) sat under the top bar's icons on phones, so their tabs and X didn't take taps; they now sit in the room under the top bar. The weight card didn't follow an automatic move up. GO could lead to a machine in the locked pro gym.

## Re-test (new save, phone layout 844x390)
| | Before (20 Oct) | After (21 Oct) |
|---|---|---|
| First rep | 1:05 after PLAY | 0:29 |
| First heavier weight | 14:28 (silent) | 0:33 (popup, moved up) |
| First quest done | 3:56 | 5:00 (Coach's quest) |
| Tutorial done | 8:10 | 3:16 |
| First Growth Spurt | 17:19 | ~6:40 (with my tool delays; simulator: 4.8 min) |
| Waiting with nothing to do | ~6.5 of 20 min | 10 s in the first 8 min (one recovery) |

![[GYM ARC/Screenshots/playtest_fixes/shake_arrow.jpg]]

## Needs the owner
- New popups and the READY popup use sounds already in the game (TierUnlocked, QuestComplete, TitleUnlocked, LevelUp). Swap any you don't like in Config/Sounds.
- Early weights now unlock every 5-10 s for the first minute (6 popups in 30 s). Fine, or should the first weight tiers need more levels?
- There are no dumbbell exercises in the game yet, so "Train next" only lists machines.
- Two meters still disagree: Physique % (32%) vs the Growth Spurt card (77%). Not in this prompt.
