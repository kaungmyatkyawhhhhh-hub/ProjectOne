---
tags: [city-legends, jobs, economy, build]
created: 2026-11-19
---
# City Legends: jobs like Southwest Florida (19 Nov 2026)

> Owner, 19 Nov: "u should make jobs like in roblox southwest florida". Later the same day (owner approved): "make the POST jobs proper AFK jobs, like Southwest Florida".

Builds on [[2026-11-18 Jobs - ranks and paychecks]] (ranks, paychecks, Double Pay, anti-exploit: all kept) and [[2026-11-18 Research - Southwest Florida jobs]].

## What changed for players
- **JOBS tab in the main menu** (CAMPAIGN / CARS / HOUSES / **JOBS** / STORE). It also opens from:
  - the new **JOBS icon** (a briefcase) in the HUD icon column, PC and phone
  - the job bar under the level bar
  - the Job Center kiosk at Myanmar Plaza (kept as a second way in: E now opens the JOBS tab)
- The tab shows all 8 jobs as tiles: name, rank (R2/5 + title), pay per paycheck (x2 with Double Pay), the workplace and one line on what you do. Tap a tile: **TAKE JOB**, or **QUIT** on your own job. Works **from anywhere** (no need to walk to the kiosk).
- Taking a post job closes the menu and the gold ring + minimap waypoint point to the workplace. Taking a field job keeps the menu open with a **GET <VEHICLE>** button on the tile.
- **The job over your head and over your car** ("YBS Bus Driver · R2", gold). The driver doesn't see the one on their own car. Player attribute `JobTag` holds it too.
- **Job vehicles (field jobs):** existing cars re-painted, fictional livery, no logos:
  - YBS: the Apex Grand Lounge van in white and red, plate "YBS 36" (no bus model exists yet: shortcut)
  - Taxi: the Apex JZX100 Tourer (Chaser, no badges) in taxi yellow, plate "TAXI"
  - Traffic Police: the Apex JZX100 Tourer in white, plate "POLICE"
  - (First try was the Apex Regent Sport, the police NPC body: its model has no Customs paint parts, so it stayed white, and it still shows its maker's badge and "CROWN" / "Athlete" letters. Rule: a job vehicle's car must have `Body_Paint*` parts.)
  - It spawns in front of you (or swaps in where your car is). It sits in your own car slot, so only you drive it. On quit or a job change it goes, and your own car comes back if you were driving.
- **Posts are AFK jobs now:**
  - The 2 h/day cap is gone. You are paid every paycheck while you stand at your post, with no input.
  - After 2 h in a row at the post: a small **"Still on shift? [KEEP WORKING]"** card under the job bar. No tap in 5 min: off duty until you tap it (walking off the post resets the count).
  - The bar says "ON DUTY · $200 in 0:42", or "Go to your post", or "Off duty: keep working?".
  - A **serve prompt** at each post (E, hold 0.6 s): Serve tea / Fill a tank / Help a buyer / Serve a shopper. Tip $40 x rank pay x Double Pay, +5 job XP, once every 20 s, only on duty. At the fuel post a real player's car stopped within 40 studs is the customer: double tip, and their tank is filled free.
- **Auto-rejoin before Roblox's 20-minute idle kick** (design of 17 Nov). **Not officially approved by Roblox: watch moderation.**
  - Only for a player on duty at a post. The client reports `Players.LocalPlayer.Idled`; the server decides at 18 idle minutes (Idled fires about every 2 min, so 18 is the last report before 20).
  - The server saves, then `TeleportService:TeleportAsync` to this same server (`TeleportOptions.ServerInstanceId = game.JobId`), 3 tries, the last one to any server. Teleport data: job, shift seconds, time, car id.
  - On arrival: only the job already on the save counts (teleport data passes through the client). The player is stood at their post, on duty, with the shift count carried over; no start menu.
  - The car is not brought back: getting into a car takes you off your feet. It comes from the garage as usual.

## Code
- `src/shared/JobsData.lua` (new; Config.lua is at the 199k sync limit): what each job does, `Vehicles`, `Serve`, tips, `ShiftCheck` 2 h, `ShiftAnswer` 5 min, `RejoinIdle` 18 min, `RejoinTries`, `RejoinMaxAge`.
- `server/Jobs.lua`: take / quit from anywhere, `vehicle`, `keep`, `idle` handlers, `dropJobCar`, `tags`, the shift check in the post tick, `serve` + `buildServePrompts`, `restore` on PlayerAdded from `GetJoinData().TeleportData`.
- `server/Main.server.lua` `spawnFor`: `opts.job` / `opts.look` (job vehicle: Customs livery + `JobCar` attribute; spawned with `stolen` for the no-wear / no-parts skips).
- `client/MainMenu.lua`: the JOBS tab (`buildJobs`), tab width fits 5 tabs on the phone canvas, `MainMenu.show(<any tab>)`.
- `client/JobsClient.lua`: the old JOB CENTER screen is gone; `open` (-> `UI.onJobsButton`), `getState`, `call`; the shift card; `Idled` report.
- `client/UI.lua`: JOBS side button (LayoutOrder -1, icon "jobs"), `UI.onJobsButton`.
- `client/Main.client.lua`: `UI.onJobsButton` (menu on JOBS), `rejoinedAtPost` (attribute `JobRejoined`).
- `shared/JobRules.lua` / `Config.Jobs`: `postLeft`, `PostCapSeconds`, `CenterRange` removed.
- Studio test hooks (Studio only, server player attributes): `TestShiftSeconds` (shorter shift check), `TestRejoin` (the idle rejoin without the teleport: save + teleport data + restore).

## Test (Studio, test save CityLegends_test, 19 Nov)
- JOBS tab on PC (1354x801) and at phone size (`PreviewPhone`): 5 tabs fit between Q / E, all 8 tiles readable. The first build cut the pay off the rank line; pay now has its own green line.
- Took YBS Bus from the tab's remote, then GET YBS VAN: the van spawned with plate "YBS 36", `JobCar` "bus", the tag "YBS Bus Driver · R3" over it; drove 55 studs in 3.5 s; the bar said ON DUTY.
- Changed to Traffic Police while driving the van: the van went and my own car came back; GET PATROL CAR spawned it. Got out: "Traffic Police · R1" over my head.
- Taxi: yellow Chaser, plate TAXI, "Taxi · R1" over my head.
- Tea Shop post: on duty at the post, paychecks every 6 s (test hook), the "Still on shift?" card after 10 s (test hook), KEEP WORKING cleared it, Serve tea paid a $160 tip (rank 1 x Double Pay x 2x Cash).
- Idle rejoin (Studio hook `TestRejoin`): saved, rebuilt the character at the post, on duty, start menu shut, HUD up. An idle report of 300 s was refused (needs 18 min). Quit: job gone, tag gone.
- No script errors (Output: only the usual texture-pack and EditableMesh budget messages).
- Store switched back to `CityLegends_v1` and read on the Server in Play. Place saved (Team Create), not published.
- Not tested: the live teleport (Studio has no TeleportService), a second player (tickets, the fuel post's real-car customer, seeing someone else's tag), a real phone.

![[2026-11-19 Jobs SWFL - JOBS tab phone.jpg]]
![[2026-11-19 Jobs SWFL - JOBS tab PC (first build).jpg]]
![[2026-11-19 Jobs SWFL - YBS van on duty.jpg]]
![[2026-11-19 Jobs SWFL - taxi and overhead tag.jpg]]
![[2026-11-19 Jobs SWFL - overhead tag and patrol car.jpg]]
![[2026-11-19 Jobs SWFL - tea shop post on duty.jpg]]
![[2026-11-19 Jobs SWFL - post still on shift card.jpg]]
![[2026-11-19 Jobs SWFL - phone HUD JOBS icon (before the column wrap).jpg]]

## Left to do
- **The YBS van (Apex Grand Lounge) shows its real maker's badge on the tailgate**, and the Apex Regent Sport (`toyoka_crown`, also the police NPC car) shows a badge and "CROWN" / "Athlete" letters. These are the existing car models, not new. They need BrandMarks covers, or another van for YBS. **Fixed 19 Nov:** [[2026-11-19 Badge removal - van and Regent Sport]]. A real bus body is still missing.
- No radar gun, cones or taser for police (the patrol points' 3-second "radar" stop and the speeder tickets stay). No police-gear gamepass.
- No team colour in the player list: Teams were not used (they change spawns and the player list); the job is a player attribute plus the overhead tag.
- The tea shop post stands on the pavement in front of a shop, not inside a tea shop building (no tea shop interior exists). The real tea set prop nearest to it is 86 studs north by the "Tea Shop Corner" stop.
- The 24-stud gold post ring is big on screen.
- At phone size the HUD's icon column (now 6+ icons) ran into the steering buttons. Fixed the same night by the discoverability job (in Studio, saved): a grid, phone column 1 Dealer, Shop, Jobs, Menu, Cars; column 2 Goals, Chauffeur, House. Not re-shot here.
- No fast travel to a workplace (the gold waypoint only).
