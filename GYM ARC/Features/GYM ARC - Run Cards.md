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

## Art (2 Nov, owner: "create icons or images for the cards")
- **Drawn by** `GYM ARC/Art/RunCards/make_runcards_art.py` (Python + Pillow, no outside images; 4 s to run; `python make_runcards_art.py Legs` redraws one picture).
  - A face per rarity (384x576): dark aged parchment, an ornate frame in the rarity colour, the art window, a name ribbon, a glowing gem.
  - The card back: a lattice and a gold dumbbell seal.
  - A picture per type (512x512): an engraved bone-and-gold emblem over a glowing seal in the type's colour. Chest, Shoulders, Back, Arms (a flexed arm), Legs, Core (six-pack), All (a star), Trainers (whistle + clipboard), Coins, Stamina (a bolt).
- **Uploaded:** to Roblox with Studio's image upload; ids in `Config/RunCards.Art` (plus where the window and banner sit on a face).
- **Loading:** every image is preloaded when the game starts.
- **Sheets:** `GYM ARC/Art/RunCards/_sheet_faces.jpg`, `_sheet_pictures.jpg`.

## The pick screen (2 Nov, owner: "make the card selection look like deepwoken's talent card selection as close as possible")
- **The screen:** the world blurs and darkens, with a gold serif "CHOOSE A CARD" between ornaments and "Alter 7 · Keep 1 of 3 · 6 more waiting" under it.
- **The deal:** 3 tall cards come face down from below (a whoosh each), then turn over one by one, with the flip sound and a chord by rarity. Epic and Legendary glow.
- **Choosing:** pointing at a card lifts it and lights its rim; tapping keeps it. The chosen card rises and shines, the others fall away, and the next hand is dealt.
- **REROLL** burns the hand (ember orange, fades) and deals 3 new ones.
- **Buttons:** ODDS, REROLL and LATER at the bottom. Tapping outside or Escape also closes it (the picks wait).
- **Card text** (Merriweather serif): the rarity at the top, the name on the ribbon, the bonus big, a line under it ("Chest EXP from every rep").
- The keep window and MY BUILD's legacy cards use the same cards (compact).
- **Sharp text:** the cards are plain frames, not CanvasGroups (the owner saw the text blurry: a CanvasGroup draws text into a texture), and they stand straight.
- **Under it:** a `Kit.Modal` with its panel hidden (one window at a time, the blur, Escape). The buttons are kit buttons.
- **Reduced Motion:** no deal or flip motion.
- **Screenshots:** `runcards/hand_hover.jpg`, `hand_after_reroll.jpg`, `hand_picked.jpg`, `keep_1_card_v2.jpg`.

![[GYM ARC/Screenshots/runcards/hand_hover.jpg]]

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
