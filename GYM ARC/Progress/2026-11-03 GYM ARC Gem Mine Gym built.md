---
date: 2026-11-03
tags: [gymarc, progress, gem, gym]
status: built and tested in Studio, not published, locked until the GEM event
---
# GYM ARC - Gem Mine Gym built (3 Nov, Claude Code)

Prompt: [[2026-11-03 GYM ARC Prompt - Gem Mine Gym]]. Event: [[2026-11-01 GYM ARC GEM update launch event (7 Nov)]]. System: [[GYM ARC - Live Update Events]].

## Where and what
- `Workspace.Town.GemMineGym` on the east block beside the basketball court (x 122..188, z 95..143). The 7 apartment buildings and 25 trees/bushes that stood there are in `ServerStorage.RemovedForGemMine_3Nov` (with a copy of the terrain before: `GemMineTerrainBefore_3Nov`). The main street sidewalk, the back sidewalk, the court walkway (x < 118.6) and the east edge are kept clear.
- **Outside:** a rock hill made of terrain (Rock / Slate / Basalt) with a cave mouth; a timber mine frame (posts, lintel, braces, 2 lanterns), plank walkway, a cart track (rails + sleepers) running into the cave, a mine cart full of gems; gem crystals on the face and along the roof edge; the sign GEM MINE GYM (timber board, purple-to-blue gem text) + a hanging ALTER 15+ plate.
- **Crystals:** the free Creator Store meshes "Crystal Cluster" (833341965) and "Quartz Crystal Cluster" (447264636) by XenoSynthesis (no scripts), textures removed, in Ice / Foil / Glacier with purple and blue colours (Neon looked flat). Templates: `ServerStorage.GemMineAssets`.
- **Inside:** crystal-cave walls (terrain rock over the part walls), 4 timber support frames with 8 hanging mine lamps, crystals along the walls, hanging from the ceiling, and a big gem formation on the back wall. 8 real lights in total (4 lamps, 4 crystals), no shadows. No Glass, nothing half transparent. 667 parts with the machines.
- **Machines (13):** copies of the Golden Era Gym's (Powerlifting heaviest tiers): 2 benches, incline, 2 squat racks, monolift, press, deadlift, row, pull-up, crunch, 2 dumbbell spots. `Club = "GemMine"`: **x1.30 gains**, **gem plates** (amethyst body, sapphire rim, platinum hub; checked in Play).

## Rules (Config/GemMine)
- Locked until the GEM event has launched (`LiveEvents.Unlocked("GemMine")`), then open from **Alter 15**, or for anyone with a Hall of Fame star.
- Locked on your screen: the door is shut, an iron gate + "UNLOCKS AT ALTER 15" plate show, walking up gives the toast (before the update: "Opens SAT 15:00 UTC with the GEM update"). Anyone inside without access is put back on the street (MembersService guard).
- Open: arrow + marker GEM MINE GYM until the first visit (GemMineVisit). Reaching Alter 15 after the update: "GEM MINE GYM UNLOCKED".
- Studio switches: Workspace `TestGemMineOpen` / `TestGemMineLocked`.

## The launch cover
- `GemMineGym.LaunchCover` (attribute LaunchEvent = "Gem"): canvas tarp sheets in the mouth (they block the way in), 2 striped barriers, the countdown board. The board reads **GEM UPDATE / OPENS SAT 15:00 UTC** + the clock (the clock shows once the event is switched on).
- Tested in Play with `TestLaunchIn` = 15 s: at 0 the cover came off and went to `ReplicatedStorage.LaunchCovers.Gem`, no errors.
- Changed for this (Hall of Fame unchanged): `Config/LiveEvents` (Gem entry: `building`, `bannerDate`, `gatherText`; `LiveEvents.Building`, `LiveEvents.WhenText`), `LiveEventService` (the cover is looked up on the event's own building; `TestLaunchIn` and the admin `launch` command now act on the NEXT event, not always the first), `LiveEventClient`, `LaunchCinematic` (a cutscene can name its building).
- New title **Gem Rush** (Config/Titles) for being online at the opening (the event's reward named it; it didn't exist).

## Music (owner: "the golden era gym dont have its own music")
- Golden Era Gym: Funk in Your Life (b), Disco Dancing Party, You Wah Funky 1, Funk You Up D (APM, 70s funk / disco).
- Gem Mine Gym: Defender Of Men, Quest For Peace, Fight For What is Dear (Perc) (APM, heroic cinematic).
- Picked by name and album, not heard: swap freely in `Config/Sounds.AreaMusic`. Their volume isn't measured yet (MusicGain).

## Other code
- `Config/Town.GemMineGym` (no skating), `Config/GymLighting` (GemMine: lights only near it, a cool purple grade inside), `Shared/GoTo` target "GemMine", `SettingsClient` music areas GoldenEra + GemMine, `MachineService`, `MembersService`.

## Not done / left
- The Gem launch **cutscene** (`LaunchCutscenes.Gem`) doesn't exist yet: at 0 players get the "THE GEM UPDATE IS HERE" toast but no camera fly-in.
- `Config/LiveEvents` Gem is still `enabled = false` (no countdown card anywhere) until the update is ready: switch on in Config or Creator Hub `Launch_Gem_Enabled`.
- Not tested: sitting on a Gem Mine machine in Play (the fresh test player can't be put on any club machine by the test hook, Golden Era too). Test with a real Alter 15 save.
- The 7 apartments are gone from the east block; put back = move them from ServerStorage into `Workspace.Town.Buildings`.
