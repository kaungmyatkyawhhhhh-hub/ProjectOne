---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Personal Trainers

Back to [[00 GYM ARC Home|GYM ARC Home]].

A coach who follows you around, stands beside your machine and cheers you on. Built 13 Oct (new features run, task 7B) instead of pets; Plates the gym cat stays a gym NPC ([[GYM ARC - NPC Regulars and Gym Cat]]).

## How it works
- **Trainer Desks:** one at the front of each gym (starter gym left of the door between the smoothie cart and the shake machine, pro gym front left, just inside the beach gym gate). Press **Trainers** at the desk to hire.
- **Four coaches** (coins): Rookie Coach Sam +5% EXP (300), Cardio Coach Nia +10% stamina refill (450), Money Coach Lou +5% coins (600), Pump Coach Rex: the Pump meter fills 25% faster and PUMPED lasts 25% longer (800).
- **Trainers panel:** the **Trainers** tile in the side menu (equip / unequip anywhere). Hiring only works at a desk. One trainer follows you; the Extra Trainer pass would add a second and the perks stack (the pass is in the config but monetization is off).
- **Following:** a few studs behind you and to the side, walking with you, faster when you run. Feet always on the floor; never walks through walls; pops back beside you when far away or stuck.
- **On a machine:** stands at a free spot beside it, checked for room, so he is never inside your machine or the next one and doesn't block other players.
- **Cheering:** short lines in a bubble now and then during a set ("One more rep!", "Push it!", "Good form!"), claps and "Great set!" every 10 reps, "New record!" on a personal best.
- **Look and performance:** normal-size Roblox-style coaches with their own clothes, hair and a clipboard; plain parts only (no muscle meshes). Each player's game draws the trainers itself; other players' trainers farther than 90 studs aren't drawn.

## Where it lives
- `Config/Trainers` (coaches, prices, perks, follow distances, cheer lines and timing), `Server/TrainerService` (desks, hire / equip, perks, the trainer models), `TrainerClient` (panel and tile), `TrainerFollowClient` (following, spots, cheers, claps).
- Desks: builder `tools/builders/TrainerDesks` (`Feature_Trainers` folders). Saved per player in `data.trainers`.
- Studio test switches: `TestTrainers` ("RookieCoach,PumpCoach"), `TestTrainerSlots` (2).

## Known issues
- Tested solo only: how another player's trainer looks from your screen is not tested (needs two players).
- Another player's set count comes from the machine's rep counter, which can be off by a rep or two; your own is exact.

## Related
[[GYM ARC - Monetization]], [[GYM ARC - Machines]], [[GYM ARC - Bug - Trainer hair fell off]], [[GYM ARC - Bug - Trainer stood inside the next bench]], [[GYM ARC - Bug - Trainer desks built in the air]]

## Screenshots
![[GYM ARC/Screenshots/trainer_desk_starter.jpg]]
![[GYM ARC/Screenshots/trainers_panel_hire.jpg]]
![[GYM ARC/Screenshots/trainer_following.jpg]]
![[GYM ARC/Screenshots/trainers_cheering_bench.jpg]]

## UI v2 change (13 Oct)
- The Trainers window now shows four picture tiles with NO names anywhere: just the perk (+5% EXP, +10% Stamina, +5% Coins, +25% Pump) and the coin price (300, 450, 600, 800).
- Tap a tile to hire him (anywhere now; the Trainer Desk prompt opens the same window). Not enough coins: the tile shakes and a small "Not enough coins" note shows.
- Hired: TAP TO EQUIP. Following: green outline and FOLLOWING; tap again to stop.
- Bottom: "Following 1/1" and the gold 2ND SLOT button for the Extra Trainer pass (id 2032496303).
- The trainers who follow you now look like their pictures: red cap and red shirt, white headband and green shirt, gold visor and yellow shirt, black headphones and purple shirt. Their name tags are gone.
![[GYM ARC/Screenshots/ui_compare_v2_06_trainers_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_06_trainer_follower_red_cap.jpg]]

## Coaches window, final look (14 Oct)
The window is now titled COACHES: gold frame and "COACHING" on the coach with you, EQUIP on owned ones, gray with a lock and price on the rest, and the gold 2nd slot button. See [[2026-10-14 GYM ARC Final UI Black and Gold]].

## Trainers never collide with players (14 Oct)
Trainers don't bump into players any more: every trainer part is in a "Trainers" collision group that collides with nothing (the server registers it), and they can't be touched or hit by rays (so the camera never zooms in on them).

## Remake: real gym coaches (14 Oct)
- **Coach Sam** (+5% EXP): red tracksuit with white stripes, black joggers, a whistle, brown hair, a big grin. Stands with arms crossed.
- **Coach Nia** (+10% stamina): green tank and shorts, white headband, a water bottle, lavender updo. Hands on hips.
- **Coach Lou** (+5% coins): gold polo with a black collar, black pants, a black cap, a clipboard he reads.
- **Coach Rex** (+25% pump): the biggest; bald, purple stringer, black shorts, a leather lifting belt and wrist wraps. Arms crossed.
- Built like players: a real R15 body, Roblox's own free hair, a classic Roblox face, our own clothing images (no brands), and the game's muscle stages (Rex the most muscular).
- Always a little alive: breathing, a slow weight shift and his own stance. While you lift he faces you, claps or pumps a fist every 3 reps, and says a short line now and then (at most one bubble per 10 seconds).
- Other players' trainers far away (over 60 studs) stand still; past 90 studs they aren't drawn.
- Clothes no longer look torn: the separate skin layer of the muscle meshes poked through the clothing at the lats; it's hidden on trainers now.
- New portraits for the Trainers window (same camera for all four, dark background).

![[GYM ARC/Screenshots/trainers_portrait_exp.png]]
![[GYM ARC/Screenshots/trainers_portrait_stamina.png]]
![[GYM ARC/Screenshots/trainers_portrait_coins.png]]
![[GYM ARC/Screenshots/trainers_portrait_pump.png]]
![[GYM ARC/Screenshots/trainers_follow_exp.jpg]]
![[GYM ARC/Screenshots/trainers_lats_fixed_exp.jpg]]

### Skin fix (14 Oct, later)
Hiding the skin layer made the trainers look like floating clothes (no bare skin). Now each trainer's skin color is painted into his clothing images under the clothes, so arms, legs and necklines show skin and the clothes stay solid (no torn patches at the lats).

![[GYM ARC/Screenshots/trainers_skin_fixed_pump.jpg]]
![[GYM ARC/Screenshots/trainers_skin_fixed_stamina.jpg]]

## Walk and run (19 Oct, prompt 9)
Trainers slid without moving their legs: their animation tracks were loaded before the trainer was put in the world, so they never played. Now they load the first time he's shown, and his speed is measured from how far he moved each frame: idle under 0.5 studs/s, walk under 12, run above (Roblox's standard R15 idle / walk / run, 0.2 s crossfades); walk and run play at a speed matched to his pace so the feet don't skate. Far-away trainers still freeze. Facing: he faces where he walks and faces you while standing (unchanged). Client only.
![[GYM ARC/Screenshots/joints/straight_full_with_trainer.jpg]]

## Heights (19 Oct, prompt 11)
In the players' height system (Config/Trainers `heightInches`, 60 = 5'0"), by shop order: Rookie Coach (Coach Sam) 5'0", Cardio Coach (Coach Nia) 5'5", Money Coach (Coach Lou) 6'0", Pump Coach (Coach Rex) 6'6". TrainerService scales the whole rig when it builds the models (`NpcService.ApplyBody`, like the giant NPCs: same body and proportions, width scales unchanged, so the torso stays the same width). Feet stay on the floor (the client places him from his own hip height), the speech bubble sits on his head, and the walk / run playback already scales with his size. There is no 15-stud look-at on trainers (that's Coach Dex at the desk), so nothing to change there.
![[GYM ARC/Screenshots/trainers/heights_lineup.jpg]]

## Width grows with height (19 Oct, owner)
Every trainer's width and depth (shoulders, chest, back, arms, legs) scale by the same amount as his height, so the taller ones keep the same thick proportions (BodyShape.ApplyWidths, like the giant NPCs). On top: Coach Lou (6'0") the Wide frame's shoulders (1.05x), Coach Rex (6'6") the V-Taper frame (1.1x) plus a full-look shoulder bonus (1.1x): shoulders 1.26 and 1.57 of the 5'0" trainer. Config: `frame`, `shoulderBonus`.

## Trainer gone after a rejoin (bug fixed, 19 Oct)
On join the equipped list was cut to the slots known at that moment, before the Extra Trainer pass was checked, and that cut list was saved, so the second trainer was lost on every rejoin. Now the save keeps up to the most slots anyone can have and only the trainers that follow you are capped to your slots; the Coaches window shows only those as coaching. Not testable in Studio (needs a rejoin with the pass): please check in the live game.
