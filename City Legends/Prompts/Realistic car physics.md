# Prompt: realistic car physics (the car feels heavy and planted at speed)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-03)
"Realistic car physics, like the car gets heavy when going fast and stuff." Cars should feel like real cars: **weight, momentum and grip**, not like toys. Fast cars feel **planted and heavy** at high speed; every car has its own weight and character.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md` (driving feel notes);
  - `City Legends/Research - Driving games.md` (Midnight Racing: Tokyo's driving is the owner's favourite).
- Read the driving code: `src/client/Driving.lua`, `Config.DrivingFeel` (YawResponse, SlipPeak, SlideGrip, Downforce, SteerSlowdown, PowerOversteer, Suspension...), `Cars.lua` / `CarStats.lua` (top speed, 0–60, handling, weight, drive type), `CarBuilder` (hitbox, mass).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup.
- **Measure before you change:** for 4 test cars (a light hatch, a sedan, a big SUV, a hypercar), write down 0–100 km/h time, top speed, braking distance 100–0, and how they corner. Keep these as the "before".

## What to make realistic
1. **Real weight per car:** each car gets its real kerb weight (kg) in its stats (e.g. hatch ~1,300, sedan ~1,700, big SUV ~2,500, hypercar ~1,500–1,900). Weight affects acceleration, braking, cornering and how it reacts to bumps and crashes.
2. **Heavy and planted at speed:**
   - **aero downforce grows with speed²**: supercars and hypercars grip much more at high speed, so they feel glued to the road; normal cars get only a little;
   - **steering gets heavier / slower at speed** (smaller steering angle and slower response the faster you go), so you can't flick the car around at 250 km/h;
   - the car **resists sudden direction changes** at speed (momentum / yaw inertia), with no instant snapping;
   - **high-speed stability:** small bumps don't throw it around; the body settles.
3. **Weight transfer:**
   - **braking** shifts weight forward: the nose dives, the front grips more, and the rear goes light (can step out if you brake hard mid-corner);
   - **accelerating** shifts weight back: the rear squats, RWD cars put power down better, and FWD cars can spin the fronts;
   - **cornering** shifts weight to the outside: body roll, the inside wheels go light.
   - Use the existing per-class springs (`Suspension`) so the body visibly moves.
4. **Tyres and grip:**
   - grip depends on load (weight on each wheel) and slip angle: a peak grip, then sliding (`SlipPeak` / `SlideGrip`);
   - **understeer** when you enter too fast (the front washes wide), **oversteer** with too much power in RWD cars;
   - **drive type matters:** AWD is stable on launch, RWD is lively, FWD understeers;
   - **wet roads** (rain) cut grip by about 20–30%.
5. **Engine and gearbox:**
   - acceleration follows a torque curve and the gears (strong pull in low gears, slower in high gears near top speed, no linear "slider" speed);
   - **engine braking** when you lift off (more in low gears);
   - **air drag** grows with speed², so reaching top speed takes time (the last 20 km/h are slow);
   - rolling resistance: the car coasts down naturally.
6. **Brakes:**
   - real stopping distances by weight and tyres (a heavy SUV stops later than a light sports car);
   - **ABS** feel on most cars;
   - locking brakes without ABS on old cars (optional, only if it already exists).
7. **Launch:** wheelspin on powerful RWD cars if you floor it from a stop, little on AWD.
8. **Bumps, kerbs and jumps:**
   - the suspension absorbs them; the car lands with weight (compresses, then settles);
   - heavy cars feel solid, light cars bounce more.
9. **Collisions:** heavier cars push lighter ones (traffic included), and the speed lost depends on the hit, with no bouncing like rubber.

## Keep it fun and fair
- **Realistic but still easy to drive on a phone and keyboard:** a bit of help stays (light assist so the car doesn't spin too easily on keyboard / touch, steering assist on phone). Put the strength of the assists in `Config` and in **Settings ("Driving assists: Off / Low / Normal")**.
- The **cut-up / near-miss money** must still work: cars still weave through traffic at speed (just with weight).
- Each car's real top speed and 0–60 from `Cars.lua` stay about right (within ~10%).
- Everything that runs every frame stays light (no extra cost on phones). The physics stays where it is now (client-driven with the server checks); the server's speed / cash checks still pass.
- All numbers go in `Config.DrivingFeel` with short comments, so the owner can tweak them.

## Check before you say done
- The same 4 test cars: 0–100, top speed, braking 100–0, a fast corner, a high-speed lane change, a hard brake mid-corner, a launch, a kerb hit, a jump, a crash into traffic, wet vs dry. Write before / after numbers in a table.
- Drive at 250+ km/h in a hypercar: it feels planted and heavy; at 60 km/h it still turns sharply.
- Phone-size and keyboard tests: still easy to control with the assists on.
- Cut-ups / near misses, races, police chases and the chauffeur still work.
- No console errors; Lune tests and `luau-lsp analyze` clean.
- Commit, push, save the place; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what changed in how cars drive;
- the before / after table;
- which `Config` numbers to change to make it more or less heavy;
- where the assists setting is.
