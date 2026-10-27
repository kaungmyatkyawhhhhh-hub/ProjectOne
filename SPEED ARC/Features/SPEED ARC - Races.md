---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M1)
---
# SPEED ARC - Races

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- **Every 3 minutes** (first one 45 s after a server starts) a race on the School Track for everyone in the server.
- **JOIN:** a 10 s window with a pulsing gold JOIN RACE button, a toast, a gold ring at the start, and JOIN NOW on the arch and stand screens. If nobody joins, no race. Players who don't join keep training.
- **Runners:** up to 8 players. NPC runners (Dash, Milo, Zara, Kofi, Rina, Theo, Ivy, Bo: original names with name tags) fill up to 4, at 0.7-1.15 x the joined players' middle speed, and use boosts too.
- **Start:** everyone lines up in lanes, 3-2-1 beeps, starting gun + crowd on GO.
- **Running:** the server moves every runner (clients only send BOOST taps). Pace = 22 x (1 + 0.6 x clamp(log2(MPH / 80), -0.6, 1.5)) studs a second.
  - **BOOST:** tap = +25% for 0.8 s, 3 charges, 1 back every 2.5 s.
  - **Slipstream:** within 6 studs behind someone = +5%.
  - Low side camera, wider view while boosting. Live position bar with avatar heads and your place. FINAL STRETCH at 80%. A crowd burst when places change.
- **Race types (take turns):** Sprint = 1 lap (~18 s at 80 MPH); Lap Race = 1.5 laps from the back straight (~27 s). Races stop at 45 s and anyone still running is placed by distance.
- **Results:** card with your place, medal (top 3), time, NEW PB!, coins counting up and the standings; fanfare and confetti for a win. Coins = minutes of coins at your league: 1st 6, 2nd 4, 3rd 3, plus 1.5 for finishing; first race of the day +50%. Medals, races, wins and best times are saved.
- **After:** you go back to where you were, back on your training spot if you were training.

## Studio test switches
`TestRaceNow` = true starts the JOIN window now; `TestRaceInterval` = seconds between races.

## Where it lives
`Server/Services/RaceService`, `Client/Controllers/RaceController`, `Shared/Util/TrackPath` (lane positions), `Config/Race`.

## Tested (28 Oct)
Lap Race at 0 MPH: 38.3 s, photo finish. Sprint at 0 MPH: 25.7 s. Sprint at 101 MPH (phone size): 14.0 s, 1st.

## Related
[[SPEED ARC - Training]], [[SPEED ARC - Sound]], [[SPEED ARC - UI Kit and HUD]]
