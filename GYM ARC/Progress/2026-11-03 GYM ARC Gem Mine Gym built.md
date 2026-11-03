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

## Exterior pass + interior redo (3 Nov, later) - [[2026-11-03 GYM ARC Prompt - Gem Mine exterior and interior redo]]
The first version (shell, crystals, signs, cover) is kept in `ServerStorage.RemovedForGemMine_3Nov.GemMineGym_v1`.

**Outside**
- The rock is now an irregular mountain (terrain): a wide base with rounded corners, uneven peaks (highest ~37 a little behind the middle), sloping down to the street and to the back; the green hill shows behind it from the street.
- Cave mouth 18 wide, ~17 high: two timber posts (iron bands) + a beam, braces, 2 hanging lanterns, GEM MINE GYM standing on the beam, ALTER 15+ hanging under it. Rails run from the sidewalk onto the deck (buffer stop), one cart full of gems at the mouth.
- 10 big Neon crystal clusters (purple / blue / pink, up to 14 studs) on the peaks, the front corners and beside the mouth; small crystals, ~60 rubble stones along the base and on the last ~0.8 studs of the sidewalk (walkway clear); 6 glowing cracks.
- A purple glow out of the mouth onto the street (1 PointLight + 1 SpotLight). No other lights outside.

**Inside (dug down)**
- From the mouth: a timber deck at street level, then 28 wide stairs (12 studs) on timber trestles down to the cavern floor; handrail with 5 lanterns (2 lit).
- The cavern: x 104..200, z 94..160 (96 x 66), floor at -22 (the terrain surface; 22 below the street). Ceiling 18 under the town (rock at -8..-4 under the roads, the pavement above untouched) and a dome up to +16 inside the mountain (~38 high) with 16 crystal stalactites. Checked: no holes to the street/sky, the stairs have 6+ studs headroom, nothing underground was in the way (no parts below the roads).
- Layout: Flint's spot in the middle (a raised rock platform, gold ring, steps toward the stairs, a 22-stud glowing crystal + 2 smaller, a few sparkles); machines in rows along the back (5), east (3 + crunch) and west (2) walls, 2 dumbbell spots under the deck; a mine-cart track loops round the middle (4 carts full of gems).
- Gem equipment: frames dark metal with the gold trim kept, pads deep purple; plates are gems by weight (MachineService: 45+ lb amethyst, 25-35 sapphire, lighter pink tourmaline; smooth body, glowing rim, gold hub). Signature crystal machines: Monolift, Deadlift, Squat1 (crystal pillars + a glowing gem trim, attribute CrystalMachine).
- Light: the office lamps are gone; 5 PointLights inside big crystals + 2 lanterns. 9 lights in the whole gym, 1 particle emitter, 1,122 parts, no Glass.
- Flint's table: `ReplicatedStorage.StoryTables.BullyTable_Flint` (a copy of Vince's) placed on the platform; it appears when Flint is added to the storyline (chapter 7, not built yet).
- Code: the guard Zone is the cavern under the streets only (y -25..-6, so people on the back street are never moved); music area = the mouth + deck and the cavern; GymLighting uses the same Zone.
- Tested in Play: a test character walked deck -> stairs -> floor -> platform -> back row -> back up; the cavern streams in (13 machines on the client); gem plate colours; no errors.

## Headroom for tall players (3 Nov, owner: "theres gonna be tall guys coming in there so make the roof clearance higher")
- Target: 14+ studs of headroom wherever people walk (the bullies are up to ~10 ft = ~9.7 studs; 7'0" = 6.75 studs).
- Cavern floor lowered 4 studs (now -26; everything on it moved down): 16+ studs everywhere on the floor (checked on a 3-stud grid), up to ~42 under the dome. Stalactites that came below 14 were shortened or removed (12).
- Stairs rebuilt longer (32 steps, deck 0.5 -> floor -26) and the tunnel over them cut higher: 14-17 studs over the walking width; a plank wall-rail on the rock side keeps people off the last strip by the wall (lower there). Rock wedge under the low end of the stairs (no low gap to walk into).
- Deck: ~14-15 studs; the ALTER 15+ plate is now on the beam's face (nothing hangs low), the lanterns hang higher.
- Checked: no holes to the street/sky (rays from above never reach the cavern), the mountain's front is closed beside the mouth. Tested in Play with a 10.4-stud dummy and a normal one: deck -> stairs -> floor -> platform -> back / east walls -> back up to the deck. No errors.
