---
date: 2026-10-26
tags: [gymarc, progress, pacing, menu, world, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-26 GYM ARC Fast spurts, menu, beach and skate park

Owner's requests in chat after [[2026-10-26 GYM ARC Full test pass with screenshots]]. Shots 34-45 in `Screenshots/test_2026-10-26`.

## Pacing (owner: "growth spurts fast so players get hooked, alters are the real progression")
- **Growth Spurts: about 1 hour for all six** for a player with the 2x NEW PLAYER BOOST who rolls trainers: 4 / 5 / 8 / 12 / 14 / 17 min (was 5 / 10 / 18 / 28 / 38 / 38 without boosts). Goals 9 / 30 / 53 / 68 / 90 / 119 (were 9 / 35 / 68 / 113 / 163 / 197). `Config/GrowthSpurts`, tuned with `lune run tests/pacing tunespurts 4,5,8,12,15,17`.
- The pacing sim's players now have the new player boost and roll trainers (like real players), so its normal check matches these targets.
- **Alters re-tuned** for players who reach Alter 1 with less muscle: still ~27.5 min each with trainers, 14 ~45 min, 15 ~60 min. `Alters.Goals` 218 / 389 / 464 / 519 / 547 / 577 / 621 / 651 / 667 / 688 / 708 / 745 / 769 / 932 / 1070 (were 237 ... 1072).
- **LVL: not changed** (owner: "keep it as that").

## Trainers
- **Shrunk with the 4-inch spurts** (owner: "Atlas becomes 7'0""): every trainer x84/90. Sam 4'8", Nia 5'1", Lou 5'7", Rex 6'1", Duke 6'4", Volta 6'5", The Shadow 6'8", Atlas 7'0" (`Config/Trainers`).
- **See through your own trainer** (owner): when he's between the camera and you (or right at the camera) he fades to 75% see-through (34).
- **Bug fixed:** sometimes your trainer never showed for a whole session (the Trainers attribute changed while the models were still loading and the change was missed). Now it listens first.

## Main menu and loading screen
- Menu camera moves at a **steady speed** and cuts while still moving (owner: "each clip slows down and stops").
- Statue shot **lower**, aimed at the statue's chest (35). **Starter gym window shot removed** (kept in ServerStorage.MenuShotsRemoved).
- **Cinematic lighting while the menu flies** (37): more contrast and colour, warm tint, stronger glow and sun rays; fades out on PLAY (the game's own lighting is never changed).
- Loading screen plates **all red** (four shades).

## Item bar
- Smaller slots with **1 px outlines**, small gaps; on phones never under 44 px (the first try came out tiny on phones with big gaps; fixed) (38).

## World
- **Pro Gym city** is now in `Workspace.Backdrops` in Studio (visible and editable); at game start the server moves it into ReplicatedStorage.Backdrops, so phones still only draw it near the Pro Gym. The far city stays in ReplicatedStorage.
- (Later the same day the owner asked to keep the old beach gym and skate park: the Upgrade models were removed and every part restored from the backups.)
- **Beach gym** (39 before, 40-42 after, since removed): timber edging + gold lines on the mats, 8 tiki torches, festoon lights round the flag poles, a big BEACH GYM board on the arch, 2 surfboard racks, 4 umbrellas with loungers.
- **Skate park** (43 before, 44-45 after): each ramp's sides painted (teal / orange / violet / red), a dark plaza with a white outline and coloured corners, bulbs along the fence, two strings of lights between the floodlights, a SKATE PARK arch over the entrance.
- Both are one `Upgrade` model each (delete to undo), built by `tools/builders/BeachSkateUpgrade` (also in ServerStorage._Builders). Nothing added collides. The whole builds before are in ServerStorage `BeachGymBackup_26Oct` / `SkateParkBackup_26Oct`.

## To test
- Phone: item bar size, menu lighting, see-through trainer.
- New player: Growth Spurts should feel quick (about an hour to Spurt 6).
- Skate on the park (the ramps are unchanged apart from colour).

## Later the same day
- **Trainer missing all session (fixed for good):** the server builds the trainer models after the game starts; an early join cloned before the model existed and never retried. Now it waits for the model and retries anyone left without a trainer once a second (tested by hiding the model: he came back 0.2 s after it arrived).
- **Loading screen / menu:** no prompts over them (the progress mirror prompt showed through); the menu camera also streams the ground it looks at (the beach gym looked like it floated).
- **ALTER label over heads:** no yellow outline, fully round, a shine sweeps across.
- **Alter skins for coins** (Coach Dex's ALTERS tab): every skin 25M (Pumped) .. 12B (Gold), tap twice to buy, wear only (the gains, the ALTER label and the posing divisions stay real alters). `Alters.SkinPrices`, `PlayerData.BuyAlterSkin`, `data.alter.bought`. Tested with a fresh test player (30M: Pumped bought, 600M refused, a second buy refused).
- **Shops keep their scroll** after a buy (PUMP SHOP and Coach Dex). **BEST tag** bigger and readable.
- **Beach gym:** the dumbbell spots no longer touch the bench presses (benches moved 3.5 studs back). Hex pattern on the mats tried and removed (owner: not beachy); then the owner imported the wave pattern (`tools/beach_mat_pattern.py`, group image 137669721730615): sand-coloured waves on the weights mats, teal on the calisthenics mat (Texture `MatPattern`, 16 x 8 studs a tile). Owner: "looks even worse": removed. Then (owner: "some texture or material, it looks too plain") every mat is speckled rubber gym flooring (Material Asphalt): weights mats dark grey #34363B, the calisthenics mat warm brown #4A3A2E.
- **Night lights:** beach gym 15 lamp posts with warm lanterns; skate park brighter floodlights + 4 lamp poles (`tools/builders/NightLamps`, NightLight tag: on at dusk only, no shadows).
- **Pump Shop:** shelf tubs look like their item art (Mass Gainer dark + yellow band + arrow, Pre-Workout purple band + bolt, Whey white + teal band, BCAA white + green band + plus); the clothes mannequins removed (ServerStorage.PumpShopRemoved_26Oct); **Mo** the shopkeeper is now placed in Studio (PumpShopService uses him).
- **Powerlifting Gym lock sign** on its own board in front of the shutter slats.
- **Alter skin showcase** (Studio only): check the Workspace attribute `TestAlterShowcase` and press Play: 16 max bodies (Natural + every skin) on a platform outside the map, you're taken there.

## Calisthenics and small UI (27 Oct)
- **Beach gym calisthenics work:** the decorative dip bars are now a real **Dips** station and the monkey bars a real **Hanging Leg Raise** station (copies of the Pro Gym's machines, beach style, attribute Gym = Beach so they open with the beach gym at Spurt 1). Tested: 3 dips = chest EXP 29 -> 389 and a triceps level; 3 leg raises = Abs 213 -> 219. The two beach pull-up bars already worked. The rings stay decoration. The old decor parts: ServerStorage.BeachCaliDecor_26Oct.
- **AUTO TRAIN** words centred on the button (the icon at the left). **REP** in the premium heavy italic. **ALTER label** in the username font (Theme.Fonts.Heading).
- "Hide others' trainers" already exists: Settings > Others' Trainers (On / Off).
- Studio crashed once during a play test (nothing lost but the two new stations, put back).
