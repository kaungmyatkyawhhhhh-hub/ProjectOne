---
date: 2026-10-28
tags: [gymarc, analytics]
---
# GYM ARC - Analytics events

Back to [[00 GYM ARC Home|GYM ARC Home]]. All server only (`ServerScriptService.Server.Analytics`). See them in Creator Hub > GYM ARC > Analytics.

## Funnels
- Onboarding funnel: steps 01-15 (joined ... first Growth Spurt done), once per player ever.
- `FirstGrowthSpurt` funnel: 13, 13a 25%, 13b 50%, 13c 75%, 14.

## Economy (LogEconomyEvent, prompt 88)
Currencies: `Coins`, `DnaTokens`. Logged in PlayerData AddCoins / SpendCoins / AddDnaTokens; the source is the reason given or the calling service. Gameplay earnings are summed and sent once a minute per player (and on leave). Admin gifts are never logged.
- **Gameplay** (sources, summed): Reps, Spotting, PosingComp, ArmWrestle, Strongman, Court, Rival, Legend, SpurtMilestone, Quest, Rerack, AlterTier (DNA), GrowthSpurt (DNA). Sink: GeneticsReroll (DNA).
- **TimedReward**: Daily, PlaytimeGift, GroupGift, LikeReward, Code, OfflineCoins, Guide, TrainerRebalance.
- **Onboarding**: TutorialGift, TutorialDone.
- **IAP**: StarterPack, coin packs and DNA packs (sku = product key), DnaToken.
- **Shop** (coin sinks): ProteinShake, Cosmetic, Meal, TrainerRoll, TrainerSnack, Aura, PumpShop, Style, CrewCreate, AlterSkin, DnaToken. A coin source from a shop service = `<sku>Refund`.

## Progression (LogProgressionCompleteEvent, prompt 88)
- `GrowthSpurts` (level = spurt count), `BodyAlters` (level = alter), `HallOfFame` (level = stars).

## Custom events
- Shop: `Shop_Opened`, `Offer_Shown_<offer>`, `Offer_Tapped_<offer>` (offers: Stamina, ShakeOut, AfterSpurt, FinishFaster, AutoRep, AutoRepChip, StarterPack, DnaNeed, StarterPackLimited, VipDeal), `Product_Bought_<key>` (value = Robux), `Product_Bought_Pass_<key>` (passes, prompt 88).
- Trainers: `TrainerRoll` (value = rarity index), `TrainerAutoRoll`, `TrainerEvolve`, `TrainerEvolveAll`, `TrainerRebalanceGift`.
- Codes: `Code_Redeemed_<CODE>`.
- Hall of Fame: `HallOfFame_Entered`, `HallOfFame_Confirm_Opened`, `HallOfFame_ButtonShown`.
- Other: `BodyAlter`, `FirstGrowthSpurt` (minutes), `GroupGift`, `PlaytimeGift`, `Profile_Opened`, `GroupJoined_InGame`, `LikeReward_Claimed`, `Guide_<shown|done|skip|timeout>_<id>`, `Locked_Tap_<tile>`.
