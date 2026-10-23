---
date: 2026-10-04
tags: [gymarc, feature]
status: done
---
# GYM ARC - Seasons and Events

Back to [[00 GYM ARC Home|GYM ARC Home]].

Seasonal events with decorations, a coin bonus and a title, plus the rush hour that runs every 30 minutes.

## How it works
- **Seasons (same dates every year, UTC):**
  - **Halloween Gym:** 15 Oct - 2 Nov, title "Pumpkin Spice Swole"
  - **Winter Lifts:** 10 Dec - 6 Jan, title "Snow Plow", plus a winter-only Sled Pull machine
  - **Summer Shred:** 15 Jun - 31 Aug, title "Beach Ready"
- **During a season:** decorations in the starter gym, x1.25 coins, and the season's title for 200 reps during the event.
- **Rush hour:** every 30 minutes on the clock (same on every server) the gym is busy for 3 minutes: 2x coins per rep, shown as a pill.
- **Testing:** set the Workspace attribute `ForceSeason` (for example "Halloween") before pressing Play.

## Where it lives
- `Config/Seasons`, `Config/Economy` (RushHour)
- `Server/SeasonService`, `Server/RetentionService`, `RetentionClient`

## Known issues
- Halloween starts 15 Oct, two days from now; no season was running during the 8 Oct test, so the decor has not been checked since the rebuild.

## Related
[[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Titles]], [[GYM ARC - Machines]]
