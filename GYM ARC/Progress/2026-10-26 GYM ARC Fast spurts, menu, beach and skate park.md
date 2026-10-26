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
- **Beach gym calisthenics work:** the decorative dip bars are now a real **Dips** station and the monkey bars a real **Hanging Leg Raise** station (copies of the Pro Gym's machines, beach style, attribute Gym = Beach so they open with the beach gym at Spurt 1). Tested: 3 dips = chest EXP 29 -> 389 and a triceps level; 3 leg raises = Abs 213 -> 219. The two beach pull-up bars already worked. Then the rest (owner: "you haven't done the parabar, lowbar, rings, wall bars"): every piece works, the equipment looks the same (invisible stations whose hand points sit on the real bars: `RingDips`, `BarDips`, `WallLegRaise`, `PushUps` in BeachGym):
  - **Rings:** (owner, 27 Oct: "not dips, an L-sit muscle-up") NEW **L-Sit Muscle-Up** machine (lats, triceps, abs; pose `MuscleUp`): legs out in an L the whole time, from support on top of the rings down through the transition to a dead hang and back. The rings were raised 1.1 studs (shorter straps) so the head stays under the beam. (owner: "the rings can move too") the rings swing with the lifter (up to ~0.9 studs) and sway gently when nobody is on them (client only, near the camera). Tested: hands stay on the rings, the L legs never touch the mat. **Low bar:** (owner, 27 Oct: "a planche push-up, not dips") NEW **Planche Push-Up** machine (front delts, chest, triceps, abs; pose `PlanchePushUp`, station `LowBarPlanche`): the body flat in a planche over the bar, shoulders out past the hands, feet off the floor, elbows back; the torso stays 0.3 clear of the bar at the bottom. **Wall bars:** hanging leg raises, back to the wall (Hanging Leg Raise).
  - **Parallettes:** NEW **Push-Ups** machine (chest, triceps, front delts; `Config/Machines` beach entry, pose `PushUp`: placed like a dip, the client tips the body into a plank with the feet on the floor, elbows bend each rep).
  - Tested by numbers (screenshots were down): hands on the bars / rings (0.00-0.02 studs off), push-up feet on the mat, every station gives EXP. The old decor parts: ServerStorage.BeachCaliDecor_26Oct.
- **AUTO TRAIN** words centred on the button (the icon at the left). **REP** in the premium heavy italic. **ALTER label** in the username font (Theme.Fonts.Heading).
- "Hide others' trainers" already exists: Settings > Others' Trainers (On / Off).
- Studio crashed once during a play test (nothing lost but the two new stations, put back).

## 27 Oct, more calisthenics
- **Muscle-up redone from the owner's notes:** rests in the dead hang; a rep = explosive curved pull (leaning back ~10 deg) -> transition (leaning ~35 deg forward over the rings, elbows flip back, rings in to the sternum) -> press to lockout on top (hips near the rings), then back down. The lifter faces the ocean now. Rings swing with the body's back-and-forth.
- **Machine labels** of the ring and wall-bar stations float above the frame (an invisible `SignTop` part in the station), not under the beam.
- **Weights on the body, not the stand** (owner): every bodyweight exercise (dips, hanging leg raise, muscle-up, push-ups; Pro gym ones too) carries added plates on a dip belt at the hips during a set (`follow = "Hips"`); between sets they rest on a small plate post on the mat beside each beach station. **Planche push-ups:** the plates lie flat on the upper back (new follow `BackFlat`).
- **Pacing:** the new stations made Spurts 3 and 5 ~1.5 min early in the sim; spurt goals re-tuned to 8 / 33 / 58 / 73 / 99 / 124 (4 / 5 / 8 / 12 / 15 / 17 min with the new player boost + trainers).
- **Muscle-up feel** (owner: transition too fast, leans too far forward on the push): a muscle-up rep takes 1.7x the usual time (new pose setting `repScale`, MachineClient startRep), the transition is ~a third of the rep (up half 0.66 s: pull 0.25, transition, press 0.29), the forward lean peaks at 24 deg (was 38) and ends nearly upright. The pull now moves in a C from the side (owner): the chest bows ~1.3 studs back behind the rings on the way up, comes back under them at ring height, then goes over them in the transition.
- **Aura toasts on every join (fixed):** the pass flags (Aura Pack / VIP) are set again on every join and each fired "aura unlocked"; now the toast shows only the first time (remembered in the save, `auras.notified`, AuraService). The next join may show each one a last time.
- **Owner, 27 Oct:** no more code backups to ClaudeOne / GitHub (Studio is the only copy); notes only in this vault.
