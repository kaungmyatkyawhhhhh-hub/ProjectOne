---
date: 2026-11-02
tags: [gymarc, feature, runcards]
status: built and tested in Studio, locked until the GEM update (7 Nov)
---
# GYM ARC - Run Cards

Back to [[GYM ARC - Features index|Features index]]. Prompt 105. Part of the GEM update ([[2026-11-01 GYM ARC GEM update launch event (7 Nov)]]).

Every Body Alter gives a **card pick**: keep 1 of 3 cards. Cards stack for this run. Entering the Hall of Fame clears them, and you keep 1 as a **legacy card** forever.

## How it works
- **Pick:** 3 cards per pick, each card's rarity rolled on its own: Common 60%, Rare 28%, Epic 10%, Legendary 2%. You get one free reroll per pick.
  - Epic and Legendary cards of a type only come once you hold 2 cards of that type.
- **Cards and values (Common / Rare / Epic / Legendary):**
  | Card | Does | Values |
  |---|---|---|
  | Chest, Shoulders, Back, Arms, Legs, Core | EXP for that muscle group | +12% / 20% / 35% / 60% |
  | All muscles | EXP for every muscle | +5% / 8% / 14% / 25% |
  | Trainer power | your trainers' bonus | +10% / 18% / 30% / 50% |
  | Coins per rep | coins from every rep | +8% / 14% / 24% / 40% |
  | Stamina | max stamina | +10% / 16% / 26% / 45% |
- Same cards stack. The EXP cards add to the other bonuses (genetics still multiplies). Cards never count in shows, the Strongman Showdown or arm wrestling.
- **Picks waiting:** a RUN CARDS card in the right column ("N card picks are waiting. Tap to pick!"). It's hidden during the tutorial. The pick window opens by itself right after an alter's transformation.
- **MY BUILD** (button on the Physique body card): the total per type, how many cards (and legacy cards) give it, and the legacy cards.
- **Legacy cards:** at the Hall of Fame YES you pick 1 card to keep (the best one is picked already). Up to 3 legacy cards are on at once; tap one in MY BUILD to switch it on or off.
- **Old players:** on the first join with this build, a save gets 1 pick per alter already reached (save version 2).
- **When it's on:** from the GEM event (Config/LiveEvents "Gem", unlocks RunCards). Creator Hub switch `RunCards_Enabled`. Studio: `TestRunCards`.

## Screenshots
`GYM ARC/Screenshots/runcards/`: pick.jpg, reroll_used.jpg, odds.jpg, tracker.jpg, my_build.jpg, keep_1_card.jpg, my_build_legacy.jpg (PC size; the Studio window can't be resized to a phone from here).

## Where it lives
- `Config/RunCards` (types, values, odds, Card / Total / ExpFor / MakeOffer / On).
- `Server/RunCardService`: remote "RunCards" (Open / Pick / Reroll / Legacy). `Grant` is called from the alter action; `NewLife` from HallOfFameService.Enter.
- `RunCardsClient`: the pick window, the tracker, MY BUILD, the keep window.
- Hooks: Gains.PerRep (EXP), MachineService (coins), TrainerService (trainer power), PlayerData.RefreshMaxStamina (stamina). DataMigrations step 1 (the catch-up picks).
- Analytics: RunCard_Picked, RunCard_Reroll, LegacyCard_Kept (card id as a custom field).

## Studio test switches
- `TestRunCards` = true: on in Studio before the event.
- `TestAlter` + `TestDataVersion` = 1 (FreshPlayer): the catch-up picks.
- `TestKeepCard` (set on the client during Play): opens the keep window.
- `TestNewLife` = a card id (on the server during Play): a new life keeping that card, like the Hall of Fame.

## Related
[[GYM ARC - Hall of Fame]], [[GYM ARC - Body Alters]], [[GYM ARC - Live Update Events]], [[GYM ARC - Player Data and Saving]]
