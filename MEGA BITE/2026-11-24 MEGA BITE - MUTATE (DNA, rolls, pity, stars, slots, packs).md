---
tags: [mega-bite, build-log, ant-evolution, mutations, monetization, ui]
date: 2026-11-24
---
# 2026-11-24 MEGA BITE - MUTATE (DNA, rolls, pity, stars, slots, packs)

Owner, 24 Nov (MEGA BITE): "build Ant Evolution's MUTATE system ... copy Ant's system, using it as a reference, in MEGA BITE's v6 UI kit ... merge or replace MB_Cards ... research extra shark mutations ... decide the odds yourself".
Research: [[2026-11-24 Research - Ant Evolution (evolution + rebirth system) and Deepwoken-style slots]]. Follows [[2026-11-24 MEGA BITE - Ant Evolution core loop (top bar, EVOLVE button, PvP stage drop)]] (item 1 of its "Next" list).

- **Testing:** in Studio Play as a fresh player (`MB_FreshPlayer`, never saves), 0 script errors. The owner's real save was not read or written. Both workspace test switches were put back afterwards.
- **Not saved and not published:** the owner saves and publishes.
- **Backups:** in ServerStorage, `*_preMutate_24Nov` copies of GameConfig, MB_Data, MB_Cards (server), MB_CardsClient (client), MB_Rewards, MB_Evolutions and ClientBus.

## What it is
The 14 Nov "pick 1 of 3 cards at half-way" system is **replaced** (merged: same scripts, same effect hook). Mutations now come from rolls, like Ant.
- **Roll:** 1 token or 120 DNA. **x5:** 5 tokens or 600 DNA. Tokens are used first.
- **Pity:** an Epic or better by roll 25 at the latest, a Legendary or better by roll 100. Both bars are on screen ("in N rolls at most").
- **Stars:** a duplicate adds a star (max 5). Each star past the first adds +25% of the base bonus, so 5 stars = double. A duplicate of a 5-star pays 60 DNA back.
- **Slots:** 1 to start, +1 at Fossil II, +1 with the Mutation Slot pass (249 R$). Only equipped mutations work. A free slot takes the best new roll by itself.
- **Fair fight:** health and healing mutations are **off in the Red Trench** (rolls can be bought; the Trench rule is "nothing bought works here"). Tested: TOUGH SKIN 5★ = 140 HP outside, 100 in the Trench.

## Odds (decided from Ant + gacha norms)
| Rarity | Odds | Mutations |
|---|---|---|
| Common | 55% | 6 |
| Rare | 28% | 8 |
| Epic | 12% | 5 |
| Legendary | 4.5% | 4 |
| Mythic | 0.5% | 2 |
Tested over 380 rolls: 57.6 / 25 / 12.1 / 4.5 / 0.8%. Longest wait for Epic+ was 19, for Legendary+ 46. Forced pity tests: pity 24 → a guaranteed Legendary, pity 99 → a guaranteed Mythic.

## The 25 mutations
The first 10 are the old cards (same ids, so old saves convert). The 15 new ones are real shark biology; the window shows the fact.
- **Common:** Big Appetite, Hunter, Treasure Nose, Quest Star, **Lateral Line** (sharks feel fish moving), **Countershading** (dark back, pale belly).
- **Rare:** Tough Skin, Quick Heal, Gold Fever, Long Rush, Lucky Eye, **Electro Sense** (ampullae of Lorenzini), **Conveyor Teeth** (sharks regrow teeth all their lives), **Tiger Stomach** (tiger sharks eat almost anything).
- **Epic:** **Hammer Eyes** (hammerhead vision), **Mako Blood** (warm muscles), **Greenland Heart** (~400-year life), **Bull Grit** (bull sharks swim up rivers), **Thresher Tail** (tail whip stuns fish).
- **Legendary:** Golden Glow (now +15% all EXP + the gold outline), **Lantern Glow** (lanternsharks glow), **Goblin Jaw** (slingshot jaw), **Whale Gulp** (the biggest fish).
- **Mythic:** **Megalodon Blood**, **Ancient Fossil** (sharks are older than trees).
- Every effect uses the old card fields (fish / predator / chest / quest EXP, health, heal delay, Gold Rush fill and time, shiny chance, all EXP), so **no gameplay script changed**. All go through `C.CardVal`, which now reads the equipped mutations with their stars.
- **Own icons (added later on 24 Nov, ChatGPT art pipeline):** one 5×3 sheet, made in one try with the 14 Nov card sheet attached as the style reference. Files are in `UI/card_icons/`: the prompt (`prompt_mutations_24Nov.md`), the sheet, the cutter (`cut_mutation_icons.py`), 15 `mb_icon_Mut*.png` at 256² and `preview_mutations_24Nov.png`.
  - **Keying lesson:** soft glows (the lanternshark, the tooth's ring) are see-through over magenta, so the usual 3 px fringe fix left a lilac or pink halo. The fix: in the glow icons' cells only, alpha = 1 − min(R,B)/255 on magenta-tinted pixels, then un-mix. Run globally, it broke the goblin shark's pink-peach skin.
  - **Uploaded to group 33151111** as `K.Icons.Mut<Id>`, and each mutation's `icon` points at its own. Checked in Studio Play: all 25 icons load in COLLECTION.

| Icon | Asset id | Moderation |
|---|---|---|
| MutLateralLine | 103184664360710 | Approved |
| MutCountershade | 87338219799770 | Approved |
| MutElectro | 111559581174316 | Approved |
| MutToothBelt | 75793241989620 | Approved |
| MutTiger | 77617968595385 | Approved |
| MutHammer | 81529350190550 | Approved |
| MutMako | 96037388443289 | Reviewing (shows in Studio) |
| MutGreenland | 87882981514897 | Approved |
| MutBull | 87814284448698 | Approved |
| MutThresher | 115555643003001 | Reviewing |
| MutLantern | 111985489510881 | Approved |
| MutGoblin | 118574452460047 | Approved |
| MutWhale | 117410553876447 | Approved |
| MutMegalodon | 74154255225817 | Approved |
| MutAncient | 102502032486709 | Approved |

  Backups: `UIKit_preMutIcons_24Nov`, `GameConfig_preMutIcons_24Nov`.

## DNA (per slot) and free rolls
- **DNA income** (MB_Cards server, a 1 s tick on the stats): per fish 1 + evolution ÷ 3; predator 10; chest 30; evolving 40 × the new stage; Fossilize 1,500 × the new tier (Ant gives 2,000 / 4,000 per rebirth). Tested: 10 fish + 1 chest = +40, Fossil I = +1,500.
- **Free rolls (tokens, account-wide):**
  - daily streak days 2, 4, 6 = +1 roll each, day 7 = +3;
  - playtime gifts at 15 min and 40 min = +1 each;
  - daily quests: medium +1, hard +1, all 3 done +2.
  - Tested: the 15-min gift paid 1 token.

## Roll packs and the slot pass (Robux)
- **Packs (developer products):** 35 R$ = 3 rolls, 149 R$ = 15 (POPULAR), 399 R$ = 45 (BEST VALUE). They give tokens; tokens are account-wide so a deleted slot never loses paid rolls.
- **Paid random items rule** (K04, owner 18 Nov): the exact odds are always on the ROLL tab, and the PACKS tab says every roll uses them. `PolicyService.ArePaidRandomItemsRestricted` hides the packs (fails closed on live servers; free rolls still work there).
- **Receipts:** `ProcessReceipt` grants tokens, remembers the last 20 receipt ids (`MutReceipts`, never paid twice), and returns PurchaseGranted only after MB_Data saved.
- **TODO owner:** create the 3 developer products and the 249 R$ "Mutation Slot" game pass, then paste the ids into `GameConfig.Mutate.Packs[i].id` and `GameConfig.Mutate.SlotPass`. Until then the buttons read **SOON**. Nothing was put on sale (no publishing).

## UI (`StarterPlayerScripts.MB_Cards`, v6 kit)
- **HUD:** a pink **MUTATE** square in the left column under EVOLVE (where the CARD badge was). Red number = free rolls waiting ("!" when you have 120+ DNA).
- **Window** (v6 slab, like MB_Evolutions): title "Mutate", a SLOTS n / n chip, tabs **ROLL / COLLECTION / PACKS**.
  - ROLL: DNA and token pills, your slots (locked ones say FOSSIL II or SLOT PASS), the 2 pity bars, 1 or 5 result cards that flip (sheen for Epic+, a burst for Legendary+), the odds chips, ROLL and ROLL x5.
  - COLLECTION: all 25 by rarity, ??? until found, stars, a ✓ on equipped ones; tap = details + fact + EQUIP / UNEQUIP.
  - PACKS: the 3 pack cards and the slot pass.
- **Bugs found in the test and fixed:** long names broke mid-word ("COUNTERSHADIN G"), so names now shrink to fit. Slot words were ~11 px, so they're now two lines at 14–15 px. Icons were blank on first open, so they're preloaded now. The slot-pass slot showed a price for a pass that doesn't exist yet; it says "soon" now.
- **Studio test hook:** player attribute `MutTest` = roll | collection | packs | close | roll1 | roll5 (client) and migrate (server).

## Saves (MB_Data fields)
- **Per slot:** `DNA`, `Muts` ("id:stars,..."), `MutEq`, `MutPityE`, `MutPityL`.
- **Account** (`C.Slots.Account`): `MutTokens`, `MutReceipts`.
- **Old saves:** owned cards become 1★ mutations and the best ones are equipped, as many as the slots allow. The old `Cards` / `CardOffer` are then cleared. Tested: Appetite + Glow + Tough at Fossil II → Glow and Tough equipped.
- **Heads-up:** old players had every card active at once. Now only 1–2 are equipped, which is a nerf for them (the cards were free). **Owner decision (24 Nov): no compensation.**

## Not done / open
- Phone layout not checked on a device. The window is 700×430 with the same AttachScale as Evolutions.
- The products / pass ids (see TODO).
- Store window: no MUTATE packs section in MB_StoreUI yet (they live in the MUTATE window).
- Not tested: a real Robux purchase (needs the products made).
