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
  - Taxi: the Apex Regent Sport in taxi yellow, plate "TAXI"
  - Traffic Police: the Apex Regent Sport in white and blue, plate "POLICE" (the same body as `Config.Police.CarId`)
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

## Test
(filled in below after the play test)
