---
date: 2026-10-23
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Trainer rarities, odds and the group gift

Prompt: [[2026-10-23 GYM ARC Prompt - Trainer rarities, odds and group gift]]. Game commit c97fbbc.

## Final odds (Config/Trainers, adds up to exactly 100%)

| Trainer | Rarity | Chance | BASE boost |
|---|---|---|---|
| Coach Sam | Common | 30% | +5% EXP |
| Coach Nia | Uncommon | 25% | +8% coins, +12% stamina regen |
| Coach Lou | Rare | 20% | +12% EXP, +8% max stamina |
| Coach Rex | Epic | 17% | +20% EXP and coins |
| Duke Ironside | Legendary | 5.75% | +35% EXP and coins, +9% progress |
| Volta | Legendary (was Mythic) | 1.5% | +35% EXP and coins, +9% progress (was +50% / +14%) |
| The Shadow | Mythic (was Secret) | 0.6% | +50% EXP and coins, +14% progress (was +65% / +18%) |
| Atlas | Secret (was Eternal) | 0.15% | +65% EXP and coins, +18% progress (was +75% / +25%) |

- **How the odds work:** each trainer has his own chance. A rarity's chance is its trainers' chances added up (Legendary 7.25%).
- **Eternal:** the rarity is gone (no trainer uses it).
- **How chances show:** always as percentages, with decimals where needed ("5.75%", "1.5%", "0.15%").
- **Pacing** (minutes of coins at the player's stage; the tests measure it):

  | First … or better | Rolls | Time |
  |---|---|---|
  | Epic | ~4 | ~6 min |
  | Legendary | ~12 | ~20 min |
  | Mythic (The Shadow) | ~134 | ~3.6 h |
  | Secret (Atlas) | ~674 | ~18 h |

## What changed
- **Pity:** "LEGENDARY GUARANTEED IN 100 ROLLS" (Legendary or better). Everyone's pity count is kept.
- **Auto Roll:** stops on Legendary or better.
- **Auto-delete:** the toggles are unchanged (Common / Uncommon duplicates).
- **Reveal:** follows the rarity. Volta plays Legendary, The Shadow Mythic, Atlas Secret.
- **Hidden:** "???" until owned applies only to Atlas. The Shadow shows his name and silhouette.
- **Server-wide message:** only for The Shadow and Atlas, as before.
- **Owners of Volta, The Shadow or Atlas:** they keep their trainers, levels and evolutions, but their boosts went down. So they get the "Trainer boosts were rebalanced" popup and gift (500 coins + 1 free roll) once more (`trainers.rebalance2`).
- **Group welcome gift** (new, `GroupGiftService`):
  - Who: members of group 33151111, the group that owns GYM ARC.
  - What: once (saved in `groupGift`), 1,000 coins, 1 free roll, the CREW MEMBER title (new, Rare, Social) and Coach Lou at BASE LV 1.
  - How it shows: a "WELCOME, CREW MEMBER!" toast, then the normal reveal ("NEW!" or a dupe). It waits until the player is really playing and the tutorial is over.
  - A brand-new player never also gets the old rebalance gift.
- **Studio test hooks:** `TestRollTrainer = "BlazeCoach"` forces a trainer; `TestGroupGift = true` acts as a group member.

## Tested (Studio 844x390)
- The Agency grid with the new rarities and chances.
- Force-rolled Volta (Legendary reveal), The Shadow (Mythic) and Atlas (Secret). The server message fired for The Shadow and Atlas, not for Volta.
- The group gift on a fresh save: +1,000 coins exactly, Coach Lou NEW! reveal, a free roll, the CREW MEMBER title.
- The trainer tests are updated and pass.

## Not tested live
- A real group account (Studio acted as a member).
- The second rebalance popup for an old save that owns Volta / The Shadow / Atlas: checked by reading the code. Studio's test hook adds trainers after the join check, so it can't trigger it.

![[GYM ARC/Screenshots/trainer_odds/01_agency_new_odds.jpg]]
![[GYM ARC/Screenshots/trainer_odds/02_roll_volta_legendary.jpg]]
![[GYM ARC/Screenshots/trainer_odds/03_roll_shadow_mythic.jpg]]
![[GYM ARC/Screenshots/trainer_odds/04_roll_atlas_secret.jpg]]
![[GYM ARC/Screenshots/trainer_odds/05_group_gift_coach_lou.jpg]]
