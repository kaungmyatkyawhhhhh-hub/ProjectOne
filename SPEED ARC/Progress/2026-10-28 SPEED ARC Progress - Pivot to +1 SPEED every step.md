---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - Pivot to "+1 SPEED every step"

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Feature: [[SPEED ARC - Wall Course and Steps]] · Before: [[2026-10-28 SPEED ARC Progress - Hub map redesign]]

## What the owner said
- "almost everything is overlapping ... it needs to be like the popular simulator games"
- "i feel like its the color scheme too"
- "this game feels like those race clicker games that were trendy last year and fell off this year"
- Sent the Roblox "Trending in Simulation" list (28 Oct): Steal a Brainrot, Bike For Egg, Climb For Animals Eggs, +1 Venom Evolution, +1 Money Per Click, Fling Things and People, Grow a Garden ...

## Decisions (owner)
| Question | Owner picked |
|---|---|
| Direction | **+1 Speed every step** |
| What SPEED is for | **Break through walls** (stages, each wall needs SPEED) |
| 3-minute races | **Keep as an event** |
| Tap training | **Gone. Treadmills = AFK steps** |
| Pets | **Coaches stay as they are** (pets/eggs maybe later) |
| Colours | **Bright candy** (world and UI) |
| Layout | **Big open spawn**, zones far apart, giant floating labels, fewer small props |

## What changed
- **Core:** StepService (steps from real running), WallService (the course, smash and pay, anti-skip), AFK treadmills, Go Pro = last wall, the tutorial and quests use steps and walls, the HUD goal shows the next wall, the Auto Train pass is now "Auto Run".
- **Hub v3:** a big open spawn plaza facing the wall course. Shops are 4 candy kiosks in a row (west), the portals are 5 big gates in a row (east), AFK treadmills (south-west), leaderboards (south-east), the race track behind the spawn (north). Each zone has a giant floating name. Benches, lamps, flower beds, signpost, fountain and arches are gone. 922 parts (was 1,726), 0 lights.
- **Candy palette:** `Config/Palette` keys keep their jobs but are bright now (deep indigo instead of black, royal-blue panels, sky blue, sunny yellow) plus Mint / Pink / Purple / Orange / Sky / Lime / Cream. The UI, the loading screen and the world all follow. Hub lighting: high midday sun, more colour.
- The start arch is the part build now (the imported arch mesh is dark steel).

## Tested (Studio, FreshPlayer)
- Walking gives SPEED (+3 a step popups with the New Runner boost). Wall 1 smashed (+157 coins first time). Wall 2 blocks you: "Need 420 SPEED. Keep running!".
- Treadmill: +20 SPEED in 4 s (2 steps a second).
- The tutorial ran through: first step, wall 1 at 35 s, the race, podium, the shoes step. No console errors.
- Studio FPS 15 (Studio-limited, as before). 58,317 instances.

## Screenshots
![[2026-10-28 v3 spawn.jpg]]
![[2026-10-28 v3 top.jpg]]
![[2026-10-28 v3 shops.jpg]]
![[2026-10-28 v3 portals.jpg]]
![[2026-10-28 v3 course wall 2.jpg]]

## Not done yet
1. **City Park and Big Stadium:** no wall course yet (Go Pro there still uses the old rule), and they still have the old dark colours. They need the same candy rebuild.
2. **Pacing:** the wall needs and step gains are first guesses. Needs a new pacing sim for steps.
3. **Owner, Creator Hub:** rename the "Auto Train" pass to "Auto Run" (same id). Its icon still says AUTO, which is fine.
4. The game name and page could say "+1 SPEED every step" (the trend uses "+1" titles). The owner decides.
5. The GDD still describes tap training. This note and the feature note are the source of truth for the loop now.
