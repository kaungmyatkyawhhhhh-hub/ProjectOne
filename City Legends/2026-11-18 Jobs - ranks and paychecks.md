---
tags: [city-legends, jobs, economy, build]
created: 2026-11-18
---
# City Legends: jobs with ranks and paychecks (built 18-19 Nov 2026)

Built from the approved proposal in [[2026-11-18 Research - Southwest Florida jobs]] and the 17 Nov targets in [[2026-11-17 Car economy and Skyfreight crate design]].

> **Changed 19 Nov:** jobs are taken from the main menu's JOBS tab anywhere (the kiosk opens it), posts have no daily cap (a "Still on shift?" check instead), field jobs get vehicles. See [[2026-11-19 Jobs SWFL - jobs menu, workplaces, vehicles, AFK posts]].

## What players get
- **Job Center** on Myanmar Plaza's forecourt (Kabar Aye Pagoda Road, by spawn). It's a lit board with a counter and a glass canopy (Legends Chauffeur style). Press **E** to open the JOB CENTER screen, which uses the GOALS screen's style. TAKE a job there; QUIT works anywhere (tap the job bar).
- **Job bar** under the level bar: job · rank title · R2/5, a gold fill toward the next rank, and "$X in 0:42" to the next paycheck. It says "Off duty" when you aren't working.
- **Active jobs** (a gold ring on the road + the minimap waypoint; stop in the ring):
  - Delivery: the old dispatch rings. On this job you also get rank pay and job XP.
  - Taxi: drive to the pickup, then the fare.
  - YBS Bus Driver: 7 real bus stops (street kit) in a loop: Myanmar Plaza, Inya Lake, 9 Mile, Tea Shop Corner, Kamayut Flats, Mayangone, Pyay Road.
  - Traffic Police: patrol points (hold still 3 s for the radar). Also a ticket when a real player speeds past you (no fine for them).
- **Posts** (stand in the gold ring):
  - Tea Shop (Shwe Lahpet Tea Shop, Inya Lake)
  - Fuel Station (Kabar Aye Fuel, the real Myawady station)
  - Dealership Staff (Legends Motors)
  - Mall Shop (Golden Thread Boutique, Myanmar Plaza)
- **5 ranks per job**, with Yangon titles (Spare Boy, Table Boy, Night Cabbie, Cadet ... YBS Legend, Tea House Owner). A promotion shows "PROMOTED: <title>" and the new paycheck.
- **Double Pay pass:** x2 on all job pay. Read from the `DoublePay` player attribute (set by the store module); the pass id is in `Config.Passes.DoublePay`.

## Numbers (Config.Jobs)
| | Rank 1 | Rank 5 |
|---|---|---|
| Active paycheck / min | $100 | $270 |
| Active total / min (tasks + paycheck, test model) | bus ~$645, police ~$750, taxi ~$730 | ~x2.7 (about $100k/h) |
| Post paycheck / min | $200 | $540 |
- Rank pay multiplier 1 / 1.3 / 1.65 / 2.1 / 2.7. XP to rank: 0 / 250 / 800 / 2,000 / 4,500.
- XP comes from duty (6 a minute) and tasks (bus stop 6, police check 8, fare 20, delivery 25, ticket 10). An active player reaches rank 2 in about 15 min and rank 5 in about 4 h. Posts are slower (about 6 days at the cap).
- Task pay = (base + per stud of the leg) x rank multiplier:
  - Bus: 50 + 0.12 per stud
  - Police: 80 + 0.15 per stud
  - Taxi: 100 + 0.22 per stud (the fare leg only)
  - Ticket: 250
- Posts: paid time is capped at 2 h a day (UTC).

## Anti-exploit
- The server decides all pay.
- Taking a job only works within 26 studs of the kiosk.
- A stop only counts when the car is within 30 studs and nearly stopped, and the leg took at least distance / 300 studs/s (no teleports).
- Active pay stops after 150 s with no task done.
- Posts are checked every second: within 12 studs of the post, and under the daily cap.
- Remote calls are limited to one per 0.2 s.
- Wanted players aren't on duty.
- Saved per job in `profile.Activities.jobs` (`cur`, `xp`, `day`, `post`); the save is cleaned when it loads.

## Goals
- New daily task: "Earn 5 job paychecks".
- New stats noted: `paychecks`, `promotions`, `jobtasks`.

## Test (Studio, test save CityLegends_test, 19 Nov)
- Took YBS Bus at the kiosk.
- Paychecks of $100 every 10 s (test hook).
- Promoted to Bus Driver, then Line Driver (test hook).
- Double Pay paycheck $260 (rank 2 x2).
- A bus stop paid $242 and the next stop came up.
- Tea Shop post: $200 paychecks, paid time left counting down.
- No script errors.
- `jobs_test` checks run inside Studio's Luau: all OK. Lune and luau-lsp aren't installed on this PC.
- Store switched back to CityLegends_v1 and checked on the Server. Place saved (not published).

![[2026-11-18 Jobs - HUD bar and Job Center kiosk.jpg]]
![[2026-11-18 Jobs - Job Center screen.jpg]]
![[2026-11-18 Jobs - promoted.jpg]]
![[2026-11-18 Jobs - bus stop target.jpg]]
![[2026-11-18 Jobs - tea shop paycheck.jpg]]

## Left to do
- Not checked yet:
  - a phone-size screenshot
  - a 2-player test (police tickets need a second player)
  - the post rings' spots by eye. The tea shop and dealership spots come from data and need a look in Play.
- Taxi uses its own fares. The existing Chauffeur is a hired driver for you, so it didn't fit as a taxi job.
- Speed cameras are still off (owner, 3 Nov), so police tickets come only from real players.
- The 2x Cash pass also multiplies job pay (store module), so 2x Cash + Double Pay = x4. The other store session says this is intended.
- `Config.lua` is 198,898 bytes, just under `pack_sync.py`'s 199,000 limit. The next big Config addition needs the packer limit raised, or the table moved to its own module.
- Store module synced into Studio by the store session (19 Nov): Jobs uses its 2x Cash / Premium share and the DoublePay attribute there now.
