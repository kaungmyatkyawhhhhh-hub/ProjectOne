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
