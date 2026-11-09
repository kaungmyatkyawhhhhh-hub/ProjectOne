# Prompt: realistic exhaust sounds for every supercar and hypercar, matched to its real engine

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first, plus `Games/CityLegends/CLAUDE.md` ("Measuring a sound", `Config.ExhaustBands`, `Config.ExhaustStart`, the exhaust ids in `Config`). Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **No errors:** if a car can't get a clean, good sound, keep its current one and note it._

## What the owner wants (2026-11-09)
"Insert realistic exhaust sounds for the supercars and find their actual engine; for example the Ferrari 458 will be a flat-plane crank V8, naturally aspirated."

This **replaces the old rule** "no new sounds until the owner sends IDs": for this job the owner asks you to find the sounds yourself.

## Where the sounds come from (safe sources only)
- **Roblox's Creator Store audio** (Toolbox → Audio, or `apis.roblox.com/toolbox-service/v1/marketplace/...` search, which the environment allows): sounds that are **public and usable in any experience**. Search by engine type and car (e.g. "V12 exhaust", "flat plane V8", "V10 rev", "W16", "flat six", "supercar exhaust").
- **Never** sounds ripped from other games (Forza, Gran Turismo, Assetto Corsa, GTA...) or copyrighted videos: check the title, description and uploader; skip anything that names a game or looks ripped.
- Keep a **credit list** (asset id, name, creator) in the notes.
- Each candidate: listen in Studio, measure it (`AudioPlayer:GetWaveformAsync`, FFT: the firing note must match the engine; a V12 fires at rpm / 10 Hz, a V8 at rpm / 15, a V10 at rpm / 12, a flat-6 at rpm / 20, a W16 at rpm / 7.5), and check it loops cleanly. Pick the best for each engine type.

## The cars and their real engines
Sound each car **by its real engine** (all names here are reference only, never shown in the game). Cars with the **same engine family share a sound set**, with small pitch / filter / volume differences per car.

| Game car (id) | Real car | Real engine | Power | Redline | Sound character |
|---|---|---|---|---|---|
| Rosso Rampante F131 (`ferrara_f430`) | Ferrari F430 | 4.3 **V8 NA, flat-plane crank** | ~483 hp | 8,500 | high, sharp, racing scream |
| Rosso Rampante F142 / Spider / Speciale (`ferrara_458`, `_458spider`, `_458speciale`) | Ferrari 458 Italia / Spider / Speciale | 4.5 **V8 NA, flat-plane crank** | 562 / 597 hp | 9,000 | very high-pitched shriek to 9,000; Speciale rawer |
| Rosso Rampante F149 Riviera (`ferrara_california`) | Ferrari California | 4.3 **V8 NA, flat-plane** (front-mid) | ~453 hp | 8,000 | the F430 sound, smoother and quieter |
| Rosso Rampante F141 (`ferrara_599`) | Ferrari 599 GTO | 6.0 **V12 NA** | ~661 hp | 8,250 | a smooth, rising V12 wail |
| Enfurecido L140 Leggera / Spyder (`lambrini_lp570`, `_lp560`) | Gallardo LP570-4 / LP560-4 | 5.2 **V10 NA** | ~562 / 552 hp | 8,500 | a hard-edged V10 howl |
| Enfurecido LB724 / Aero Spyder / VTZ / Rally (`lambrini_huracan`, `_performante`, `_sto`, `_sterrato`) | Huracán EVO / Performante / STO / Sterrato | 5.2 **V10 NA** | 602–640 hp | 8,500 | V10 howl with crackles; STO / Performante loudest |
| Precision Type 42 V10 / Lightweight (`audy_r8`, `audy_r8_lw`) | Audi R8 V10 / R8 GT (1st gen) | 5.2 **V10 NA** (same family as the Gallardo) | ~525 / 552 hp | 8,700 | V10 howl, a bit more muffled than the Lambo |
| Precision 4S V10 (+ the RWD one) (`audy_r8_4s` and the new 4S RWD id) | Audi R8 V10 plus / GT RWD (2nd gen) | 5.2 **V10 NA** | ~602–611 hp | 8,700 | sharper V10 |
| Enfurecido L147 Roadster / ZV (`lambrini_lp640`, `_lp670`) | Murciélago LP650-4 / LP670-4 SV | 6.5 **V12 NA** | ~631 / 661 hp | 8,000 | deep, raw old-school V12 |
| Enfurecido LB834 (`lambrini_lp700`) **only** | Aventador LP700-4 | 6.5 **V12 NA** | ~690 hp | 8,500 | screaming V12 with big shift cracks (single-clutch ISR gearbox: a hard bang on each shift) |
| Enfurecido LB744 (`lambrini_revuelto`) | Revuelto | 6.5 **V12 NA + 3 electric motors** (hybrid) | ~1,001 hp | 9,500 | V12 scream to 9,500 plus a soft electric whine at low speed |
| Enfurecido Classico 5000 (`lambrini_countach`) | Countach 5000 QV | 5.2 **V12 NA, carburettors** | ~449 hp | 7,000 | old-school V12 with intake roar, lots of character |
| Speedmark P11 Spider (`mclaran_12c`) | McLaren 12C Spider | 3.8 **V8 twin-turbo, flat-plane** | ~616 hp | 8,500 | rasp with turbo whoosh / flutter, less melodic |
| Tri-Star Silber C197 Wingdoor (`bentz_sls`) | Mercedes SLS AMG (Black Series model) | 6.2 **V8 NA, cross-plane crank** | ~622 hp | 8,000 | deep muscle-car thunder, loud crackles |
| Stuttgart 991.2 Track (`porsha_gt3`) | Porsche 911 GT3 RS (991.2) | 4.0 **flat-6 NA** | ~513 hp | 9,000 | metallic, rising flat-six howl to 9,000 |
| Stealth-Apex V10 Halo / Circuit (`lexis_lfa`, `_lfa_circuit`) | Lexus LFA / LFA Nürburgring | 4.8 **V10 NA** | ~553 / 562 hp | 9,000 | the famous high "F1-like" scream, very fast revs |
| Velocité Noir Origine (+ trims) (`bugotti_veyron` ...) | Bugatti Veyron 16.4 / Super Sport / GS Vitesse | 8.0 **W16, quad-turbo** | 1,001–1,184 hp | ~6,400 | deep, heavy rumble with huge turbo whoosh and wastegate chuffs |
| Velocité Noir Éclair / Pure / Super Sport (`bugotti_chiron`, `_pursport`, `_supersport`) | Bugatti Chiron / Pur Sport / Super Sport | 8.0 **W16, quad-turbo** | 1,479–1,578 hp | ~7,100 | like the Veyron, deeper and stronger |

- **Aventador family (owner, 2026-11-09):** only the **LP700-4** (`lambrini_lp700`) gets a new sound. **Don't change** the ZV, ZVX or ZVX 63 (`lambrini_lp750`, `lambrini_svj`, `lambrini_svj63`): they keep their current sounds.
- Check each line against a reliable source before using it (engine, power, redline), and fix any mistake.
- Also give every car its **real redline and rev limiter**, real **power** and **gear count** in the driving data if they're off (and note it), so the sound and the revs match.
- Add any other supercar / hypercar in the game later the same way.

## How each sound must work
Use the game's existing sound system (the layers in `Config`: Start, Idle, Low, Mid, High, Launch, Crackle, Redline, Shift, Downshift, ShiftPop, Pops; `Config.ExhaustBands`: `reachDown`, `coast`, `shiftCut`, `loopRpm`, `idleReach`, `idleTop`, `noPops`; `Config.ExhaustStart`):
- **Start-up:** the real car's start (a bark and settle for V10 / V12, a quieter turbo start for the 12C / Bugattis).
- **Idle** steady and right for the engine.
- **On throttle:** smooth from idle to redline, pitch following the real revs, louder and harsher under load, no gaps or jumps between layers, no robotic looping.
- **Off throttle:** quieter overrun, **pops and crackles** where the real car has them (Lambos, Huracán STO, SLS, Aventador shifts), turbo flutter / blow-off on the 12C and Bugattis.
- **Shifts:** the cut and bang right for the gearbox (the Aventador's hard single-clutch shift, smooth dual-clutch on the 458 / Huracán / R8 / 12C / GT3 RS, a PDK-style blip on downshifts).
- **Redline / limiter:** a bounce at the real limiter.
- **Distance and position:** quieter and duller far away; louder outside behind the car, softer inside the cabin (first person), with tunnels / walls making it louder (reverb), if the system supports it.
- **Exhaust parts** from the upgrades (muffler delete, straight pipe, decat, pop / crackle tunes) still change the sound on top.

## Rules
- **No errors**, no missing-audio warnings, no sound that cuts out or stutters; works for other players hearing your car.
- **Performance:** only nearby cars play full engine sound; far cars use a cheap single layer or none.
- All ids and per-car settings in `Config` (one table per engine family + per-car tweaks), noted in `City Legends/City Legends.md` with old → new.
- Back up the old ids (in the notes / a Config comment) so any car can be put back.

## Check before you say done
- In Play, for every car: start, idle, rev in neutral, launch, full acceleration through the gears, lift-off, braking with downshifts, the limiter, from outside (chase cam) and inside; another player listening; a short recording or a description per car.
- Each engine family sounds clearly different (V8 flat-plane vs cross-plane, V10, V12, flat-6, W16).
- No console errors; Lune tests and `luau-lsp analyze` clean; FPS fine.
- Save the place, commit, push; note it (with the credit list).

## When done, tell the owner (short)
- the table of cars → engine → sound used (with credits);
- any car still on its old sound and why.
