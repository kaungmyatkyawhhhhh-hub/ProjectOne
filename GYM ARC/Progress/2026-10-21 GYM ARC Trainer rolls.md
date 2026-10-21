---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Trainer rolls

Prompt: [[2026-10-21 GYM ARC Prompt - 24 Trainer rolls]]. Feature note: [[GYM ARC - Personal Trainers]] (section "Trainer rolls").

## Done
- 8 trainers in 8 rarities (Common 50% to Eternal 0.05%), the 4 coaches as Common to Epic, 4 new rare ones with auras. Coins only, odds shown everywhere, pity (Epic every 100 rolls).
- The Trainer Agency window, Auto Roll, auto-delete, Roll x3 from Growth Spurt 2, the roll animation (rarer = bigger), server-wide announcements, odds boards over the 3 desks.
- Inventory > Trainers: slots (1 / 2 at spurt 2 / 3 at the first alter / +1 pass), duplicates in several slots, Golden from 5 (1.5x). Boosts capped at +400%.
- Old saves keep their coaches.

## Measured (`lune run tests/trainers`)
Price = 1.6 min of coins at your stage. All coins into rolls, with pity: first Epic or better ~20 min, Legendary ~53 min, Mythic ~2.7 h, Secret ~10.8 h, Eternal ~54 h. 400,000 simulated rolls match the odds.

## Tested in Studio (a fresh test player with 200,000 test coins: nothing saved)
- 200 server rolls: Common 54%, Uncommon 26.5%, Rare 10.5%, Epic 4%, Legendary 2%, Mythic 2.5% (lucky), Secret 1; 90 coins each; the pity resets on Epic or better.
- The reveals for Common, Legendary (at 667 x 375), Secret (screen goes dark) and Eternal (flash, stars); the Agency at 667 x 375.
- Golden: 5 Coach Sam -> Golden Coach Sam (+7.5% EXP, gold glow while following).
- Slots: Golden Sam in slot 1; with the pass 2 slots, two Coach Blaze in both (x2.4 EXP). 3 slots (first alter) only in the tests (no alter on a fresh player).
- Followers: Aeon (crown, cape) and Blaze follow with their muscles.

![[GYM ARC/Screenshots/trainer_rolls/agency.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/agency_phone.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/pull_common.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/pull_legendary_phone.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/pull_eternal.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/inventory_trainers.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/followers_eternal_mythic.jpg]]

## Needs the owner
- Pacing: one price can't hit every target with these odds. At 1.6 min a roll Epic (~20 min) and Legendary (~53 min) are on target, Mythic (~2.7 h) and Secret (~11 h) are a bit faster than the 3-4 h / 15 h you asked. A higher price (2 min) gives Mythic 3.4 h / Secret 13.5 h but Epic 24 min. Which do you prefer?
- The old Cardio Coach (stamina refill) and Pump Coach (pump) perks are gone (replaced by the new table). OK?
- The gains boost still goes through the game's overall gains cap (Config.Gains), so very high trainer boosts can hit that cap.
- The 3 Agency boards stand behind the old desks (the desks weren't changed). Check they look right in each gym.
