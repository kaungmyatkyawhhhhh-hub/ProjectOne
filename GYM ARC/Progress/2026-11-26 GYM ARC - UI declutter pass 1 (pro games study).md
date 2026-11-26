---
tags: [gym-arc, ui, declutter, progress]
date: 2026-11-26
build: Studio save v1938 (saved, NOT published)
---
# GYM ARC: UI declutter pass 1 (from the pro games study)

Owner: "compete with the professional games ... our game is too messy with bad UIs replicating things".
Study: [[Pro games - play study]] (Grow a Garden, Pet Simulator 99, Gym League, Arm Wrestle Simulator, Steal a Brainrot; 100 screenshots), [[Pro games - web research]] (25 sourced rules), [[GYM ARC - UI gap report and fix list]].

## Inventory (code)
78 ScreenGuis, 29 Kit windows, 4 top-bar pills, 10 menu tiles, 7 right-column items, ~230 popup calls.

## Before → after (established player, PC)
| Before | After |
|---|---|
| ![[GYM ARC now/03-hud.jpg]] | ![[GYM ARC now/05-hud-after-pass1.jpg]] |

| Fix | Rule | Where |
|---|---|---|
| The Quests window no longer opens by itself on join: everyone gets the one-tap "DAY N STREAK: +coins · CLAIM" card; it slides away after 12 s if ignored (the DAILY pill keeps its red dot) | never auto-open windows | DailyClient |
| The streak card showed raw `<font>` tags → RichText on (also the calendar footer) | - | DailyClient, AdventClient |
| Right column 4 cards → 2: the NEXT YOU card hides in alter mode (the goal card above already names the next goal); the Christmas goal is a normal one-at-a-time card (priority 30) | one goal on screen | ProgressClient, AdventClient |
| CODES button under the left menu removed (Settings already has the Codes row) | one entry per thing | CodesClient |

Checked in Play (PC): no window on join, the card reads right, 0 new errors. Not checked: phone size, a fresh player.

## Pass 2 (next): the pro patterns
1. Claim → "Next reward in 23:59" countdown on every claim button (Gym League detail).
2. Signs on locked machines/gyms: "Needs 5'2"" in the world instead of HUD text (Arm Wrestle, PS99).
3. One REWARDS hub: Daily streak + quests + Advent + Codes + Like reward as tabs of one window, one top-bar pill with one red dot.
4. Left footer: Invite and Plus one at a time (max one wide button).
5. A "Hide notifications" setting for non-key toasts (PS99).
6. Odds button on every random roll (trainer rolls, Run Cards) if any are missing.
7. Phone-size pass with the UI audit script.
