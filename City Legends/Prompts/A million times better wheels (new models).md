# Prompt: a million times better wheels (new models) AND a million times better driving and feel

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Do it properly and with **no errors** (the owner's standing rule)._

## What the owner wants (2026-11-08)
"A million times better looking car wheels for all newly imported cars." Then: "add a million times better driving and feeling to this prompt, also make it better."

**Two parts, in this order:** Part 1 the wheels (new models only), Part 2 the driving and feel (every car). Read `Realistic car physics.md` and `Camera and car movement like the video.md` and their notes first: build on what's there, don't start over.

## No errors: sacrifice a feature instead (owner, 2026-11-08: "I don't want any errors, but if it has to sacrifice, it's fine")
- **The result must have no errors:** no console errors or warnings, no physics glitches (flips, jitter, sinking, flinging), no visual errors (holes, grey parts, floating / clipping wheels, z-fighting), no broken saves, no FPS drop.
- **If something can't be done without errors, sacrifice it:** drop or simplify that feature or detail (e.g. skip the brake glow, use a simpler tyre tread, leave a car on its old wheels, keep the old camera bit, turn an option off) rather than ship anything broken.
- Write every sacrifice at the **top of the notes**: what was dropped, why, and what it would take to add it later.

# PART 1: the wheels

## Which cars
**Only the newly imported models** (`CarFinish.NEW`: the SVJ / SVJ 63, the Bugattis, the Lamborghinis, the new Ferraris, the LFAs, the Maybachs, the Countach, the Focus RS, and every car added by the import prompts, e.g. the 12C Spider, SLS, SL65, 599, DBX, Continental, 350Z, 330i when they're in). **Old models stay exactly as they are.**

If `Small design changes on famous new cars.md` has made **our own wheel library** (Furia 7, Saetta Y5, Corsa 10, Centro 6 CL...), build those designs to this standard; otherwise improve each car's own wheels (logos removed).

## Look at the cars first
Render every new car's four wheels close up (side, 3/4, low angle, day and night, still and spinning) and list what's wrong per car: flat or blurry rims, grey parts, no depth, missing brakes, cheap tyres, wrong size or position, logos, triangles showing. Fix the worst first.

## What "a million times better" means
### Rims
- **Real depth:** a concave face (the spokes curve in towards the hub, deeper on the rear wheels of supercars), spokes with real thickness and soft bevelled edges that catch the light, a visible **barrel** behind the spokes (darker, with a soft shadow inside).
- **Details:** **lug nuts / bolts** (or a **centre-lock nut** on cars that have one), a **centre cap** with our own small mark or blank (no maker logos), the **valve stem**, the fine machined ring on the lip.
- **Materials (PBR, `SurfaceAppearance`):** gloss black, satin black, gunmetal, silver paint, polished / machined faces, brushed aluminium, chrome, forged carbon: each with the right roughness and metalness so they reflect the sky and street lights properly. A polished **lip** where the design has one.
- **Ambient shading:** baked soft shadow (AO) in the barrel and between the spokes so they don't look flat.

### Tyres
- A real **tyre profile**: rounded shoulders, a slight sidewall bulge, the right sidewall height for the car (thin on supercars, taller on SUVs).
- **Sidewall:** matte black rubber with a faint texture and our own simple sidewall lettering style (size code like "275/35 R20" and a fictional tyre brand, or blank; **never real brands** like Pirelli or Michelin).
- **Tread:** a real tread pattern on the contact face (normal map), slightly lighter worn rubber where it touches the road.
- Rubber that is **dark and matte**, never shiny plastic or grey.

### Brakes (behind the spokes)
- **Discs:** drilled or slotted where the real car has them; **carbon-ceramic** grey discs on cars that have them; a darker hat in the middle; a slight blue / gold heat tint at the edge.
- **Calipers:** the right size and shape (6–10 piston on supercars), in the car's real caliper colour (yellow, red, black, grey...), with **no brand lettering**; Customs caliper colours if Customs has them.
- The hub and a dark backing plate, so you never see through to the sky.

### Fit and position
- Each wheel at the **right size, position, offset and stance**: filling the arch like the real car, centred in the arch, not sticking out or sunk in; right ride height; front / rear sizes different where the real car is staggered.
- **Steering** turns the front wheels on the right axis; the wheels **spin** at the right speed for the car's speed, the right way.
- A dark **wheel-arch liner** behind the wheel (no see-through arches).

### Wheels and tyres that feel connected to the road
- **Tyre width and type matter:** wider / stickier tyres (and the Part Shop's tyre parts) give more grip in the physics too, so what you see matches how it drives.
- **Tyre smoke and skid marks** come from the real contact patch of each tyre (not the middle of the car), the right width for that tyre.
- **Suspension travel shows:** the wheels move up and down in the arches over bumps and kerbs, and the body leans over them (never wheels through the arch or floating under it).

### In motion
- At speed, the spokes get a **soft motion blur** (a blurred spinning disc that fades in, like real cameras), not a strobe / wagon-wheel effect.
- Brakes glowing faintly orange after very hard braking from high speed (subtle, short) if it looks good.
- The damage system's **curb rash** and **dirt** still show on the new rims (if those systems exist).

## Rules
- **Logos off** everywhere on the wheels, tyres and calipers.
- Shared meshes and textures per design (one rim mesh used on many cars), textures 512–1024 px, LODs (simpler wheels for far-away and traffic cars), so **FPS doesn't drop**.
- Nothing lost: every car keeps its other parts; before / after part lists.
- **No errors:** no floating, wobbling or clipping wheels, no gaps between rim and tyre, no z-fighting, no flipped faces, no grey parts, no console errors.
- Back up each car's current model (dated, in `ServerStorage`) before replacing its wheels, so it can be reverted.
- Import the new packs yourself (permission given); if you truly can't, leave them ready and write the steps at the top of the notes.


# PART 2: a million times better driving and feel (every car)
Driving is how the game plays, so this part is for **every car** (old and new models). The per-car numbers below matter most on the new models; the old ones just use their real data.

## 1. Measure first
- Drive 6 different cars (a starter hatch / coupe, a sports sedan, an SUV, a supercar, a hypercar, an old JDM car) on: the harbour street, the Grand Hairpin, the Riviera Highway, the Summit Pass, kerbs, a jump and a car park. Record (and keep) short clips / frame grabs.
- Note what feels wrong: floaty, twitchy, too grippy, slides like ice, no weight, bouncy, steering too fast / slow, braking too short / long, cars feeling the same, camera too stiff or too shaky.
- Measure each car's **0–60 / 0–100**, **top speed** and **60–0 braking distance** in the game and compare with the real car.

## 2. Each car feels like itself
Per-car data in one table (`Config` / `CarStats`; real numbers, close enough): weight, **weight distribution**, drive type (FWD / RWD / AWD and the AWD split), power and **torque curve**, redline, **gear ratios** and number of gears, tyre width front / rear, brake strength, suspension stiffness, **downforce** (supercars and winged cars), drag.
- **Targets:** 0–60, top speed and braking within about **±5%** of the real car.
- **FWD** (Focus RS is AWD; Golf-type cars FWD): a little understeer when pushed, torque steer on hard launches (gentle).
- **RWD:** the rear can step out with too much throttle in a corner (power oversteer), catchable.
- **AWD:** planted and fast out of corners, a little understeer at the limit; the Focus RS-style rear-biased AWD can drift.
- **Heavy cars** (Maybachs, Rolls, SUVs) feel heavy: softer, slower to turn, more body roll; **light cars** (Countach, 350Z, Lotus-style) feel nimble.
- **Supercars / hypercars:** more grip with speed (downforce), very stable at high speed, brutal acceleration, big brakes.

## 3. Tyres and grip
- A proper **tyre grip curve:** grip builds with slip, peaks, then falls off **smoothly** (no sudden ice); the slide is easy to catch with countersteer.
- **Load sensitivity:** weight moving to the outside / front / rear changes each tyre's grip (braking into a corner tucks the nose in, lifting mid-corner rotates the car a little).
- **Surfaces:** asphalt best; **kerbs** slightly less grip and a shake; cobbles / paint lines a little less; **wet roads** (when it rains) clearly less grip and longer braking; grass / gravel much less.
- **Tyre sounds** from the actual slip: a soft squeal near the limit, louder in a slide, a screech when locking up; none in a straight line at normal speed.

## 4. Weight transfer, suspension and body movement
- The body **pitches** forward under braking and squats under hard acceleration, **rolls** in corners (more on soft / heavy cars, little on supercars), and settles smoothly (good damping: no bouncing, no pogo).
- Bumps, road joins and kerbs are felt (a small shake / camera nudge) but never launch the car.
- Jumps land with a believable compression and a short settle.

## 5. Steering, throttle, brakes, gears
- **Steering:** speed-sensitive (quick at low speed for parking, calmer at high speed), self-centres, smooth on keyboard (ramped input, not on / off) and on phones (a good tilt / touch steering curve); a little **countersteer help** on keyboard and phones so slides are catchable (off for "Pro" in the settings).
- **Throttle:** smooth ramp on keyboard; traction depends on the car (big power can spin the wheels from a stop).
- **Brakes:** strong but progressive; **ABS** (on by default) stops lock-ups; a **handbrake** (Space or the existing key) locks the rear for turns / drifts.
- **Driver aids** in the settings: **Traction control** and **Stability** On / Sport / Off (Sport allows small slides), ABS On / Off. Default On for new players.
- **Gears:** realistic shift times for each gearbox (fast dual-clutch, slower old autos), the rev drop and a **throttle blip on downshifts**, **launch control** from the Tune tab; **manual mode** (shift keys / paddles on phone) in the settings; the cluster and HUD show the gear.
- **Engine braking** when lifting; a small rev limiter bounce at the redline.

## 6. Feel: camera, sound and the senses
- **Camera:** smooth follow with a little lag; slightly wider FOV with speed; leans a touch into corners; a subtle high-speed shake and road rumble; looks into the corner a little; the cockpit view moves with the body (pitch / roll), never seasick. Keep everything from `Camera and car movement like the video.md` and make it smoother.
- **Sense of speed:** the speed lines / edge blur at high speed (from the lighting prompt), wind noise rising with speed, tyre roar on rough roads.
- **Sound feel:** engine pitch follows real revs, load (louder on throttle, softer on lift), pops / crackles on lift-off for tuned cars (from the ECU tunes); **no new engine sound IDs** (the owner sends those).
- **Phones:** a short **vibration** on hard hits, kerbs and gear shifts (if the device supports it); a G-force / speed readout stays readable.

## 7. Stability and fairness
- No physics glitches: no flips from small bumps, no sliding sideways for no reason, no jitter at high speed (network ownership on the driver), no sinking into roads.
- The same car feels the same for every player (server-checked numbers, client-side feel).
- Traffic and police cars use simpler, cheaper physics (they don't need the full model) so FPS stays smooth.
- Races stay fair: the class / PI system still matches the new feel (re-check PI per car after the tuning).

## 8. Test like a driver
- For each of the 6 test cars: the same routes as step 1, before and after, with clips; the measured 0–60 / top speed / braking vs the real car (a table in the notes).
- Every car in the game: a quick drive (launch, corner, brake, kerb, jump) to catch any car that feels broken.
- FPS at the 3 usual spots: not worse.

# Checks for both parts

## Check before you say done
- **One picture per car:** before / after of a wheel close up (side and 3/4), day and night.
- In Play, per car: driving, steering, braking, at speed (motion blur), parked; PC and phone size; another player sees the same.
- The driving tables and clips from Part 2, step 8.
- FPS at the 3 usual spots with lots of traffic: not worse.
- Lune tests and `luau-lsp analyze` clean; no errors. Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the before / after wheel pictures;
- the driving feel: what changed, the 0–60 / top speed / braking table, the new settings (traction, stability, ABS, manual gears, countersteer help);
- a short clip or frame grabs of the 6 test cars before / after;
- any car that still needs work and why.
