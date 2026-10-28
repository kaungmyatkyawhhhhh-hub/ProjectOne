---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M1, areas + hurdles M3)
---
# SPEED ARC - Races

## Races are the star (owner, 28 Oct)
- **LIVE RACE card** (top right, the 15 s join window, replaces the toast and the plain JOIN button): a blinking LIVE pill, the race type, the countdown (red in the last 3 s), the heads of the real players who joined ("BE THE FIRST TO JOIN!" / "3 RUNNERS IN"), the prize ("WIN +720 COINS + 2x SPEED" at your league), and the gold JOIN button ("JOINED!" once you're in). It stays hidden during the tutorial until its podium (the tutorial has its own race card). The server puts the joined user ids on `RaceState.<Area>` attribute `Joined`.
- **The podium** (full screen after every race): 2nd / 1st / 3rd blocks rise, headshots of real players (NPCs show an initial), YOU marked in gold, the title by place, "LAP RACE - 6 RUNNERS - 1 REAL PLAYER", the 4th-8th list, the medal, the time, coins counting up then flying to the counter, the 2x SPEED boost, NEW PB!, first race today, confetti (twice for a win), fanfare, CONTINUE.
- **Rewards:** 1st 10 min of coins, 2nd 6, 3rd 4, finish 2 (+50% first race of the day). Top 3: **2x SPEED per step** for 120 / 60 / 30 s of play (`Race.WinBoostSeconds`, `data.Boost.Race`, shown on the boost badge). Repeat wall smashes pay 5% (`Course.RepeatSmashMult`), so racing well is the best way to earn.
- Tested in Studio: the card (empty and with my head), a 6-runner Lap Race to the podium (2ND PLACE, +720 coins, 2x SPEED 1:00, the badge counting down).

![[2026-10-28 race live card.jpg]]
![[2026-10-28 race live card joined.jpg]]
![[2026-10-28 race podium.jpg]]


Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- **Every 3 minutes** (first one 45 s after a server starts) a race on the School Track for everyone in the server.
- **JOIN:** a 15 s window with the LIVE RACE card (above), a gold ring at the start, and JOIN NOW on the arch and stand screens. If nobody joins, no race. Players who don't join keep training.
- **Runners:** up to 8 players. NPC runners (Dash, Milo, Zara, Kofi, Rina, Theo, Ivy, Bo: original names with name tags) fill up to 4, at 0.7-1.15 x the joined players' middle speed, and use boosts too.
- **Start:** everyone lines up in lanes, 3-2-1 beeps, starting gun + crowd on GO.
- **Running:** the server moves every runner (clients only send BOOST taps). Pace = 22 x (1 + 0.6 x clamp(log2(MPH / league middle), -0.6, 1.5)) studs a second.
  - **BOOST:** tap = +25% for 0.8 s, 3 charges, 1 back every 2.5 s.
  - **Slipstream:** within 6 studs behind someone = +5%.
  - Low side camera, wider view while boosting. Live position bar with avatar heads and your place. FINAL STRETCH at 80%. A crowd burst when places change.
- **Race types (take turns):** Sprint = 1 lap (~18 s at the league middle); Lap Race = 1.5 laps from the back straight (~27 s). Races stop at 45 s and anyone still running is placed by distance.
- **Results:** card with your place, medal (top 3), time, NEW PB!, coins counting up and the standings; fanfare and confetti for a win. Coins = minutes of coins at your league: 1st 6, 2nd 4, 3rd 3, plus 1.5 for finishing; first race of the day +50%. Medals, races, wins and best times are saved.
- **After:** you go back to where you were, back on your training spot if you were training.

## Areas and hurdles (M3)
- Every area runs its own race: Hub at 0 s, City Park +60 s, Big Stadium +120 s in the 3 min cycle. Only players in that area see its JOIN button and ticks.
- Pace middles per league (Config `LeagueMid`): 2,800 / 1.28M / 550M MPH, so races stay ~18 s / ~27 s in every league.
- Private races (M4): the tutorial race and RACE THEM run on the outside lanes with their own countdown.
- Racing in a lower league's area pays 25% (`LowerLeagueRewardMult`).
- **Hurdles** (League 3+, Stadium): see [[SPEED ARC - Big Stadium]]. Wins count toward Go Pro ([[SPEED ARC - Leagues and Go Pro]]).

## Studio test switches
`TestRaceNow` = true (or an area id like "Park") starts the JOIN window now; `TestRaceType` = "Hurdles" forces a type; `TestRaceInterval` = seconds between races.

## Where it lives
`Server/Services/RaceService`, `Client/Controllers/RaceController`, `Shared/Util/TrackPath` (lane positions), `Config/Race`.

## Tested (28 Oct)
Lap Race at 0 MPH: 38.3 s, photo finish. Sprint at 0 MPH: 25.7 s. Sprint at 101 MPH (phone size): 14.0 s, 1st.

## Related
[[SPEED ARC - Training]], [[SPEED ARC - Sound]], [[SPEED ARC - UI Kit and HUD]]
