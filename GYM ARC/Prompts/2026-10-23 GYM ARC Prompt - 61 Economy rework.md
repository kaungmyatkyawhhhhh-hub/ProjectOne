---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 61 Economy rework

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Economy rework (owner, 23 Oct). Problems found in Config: fixed coin rewards become worthless late (day 7 login = under 1 min of coins at 7'0"), coin packs get worse the bigger you are, coin boosts can stack to ~20x, and there's little to spend coins on mid-game. Follow CLAUDE.md Speed rules. Never undo the owner's manual Studio changes. Every number in Config. Never lower a reward below what it pays today (old value = the floor).

0) ONE HELPER
- Economy.Minutes(spurts, minutes) = minutes x the BASE coins-per-minute at that stage (PumpShop.CoinsPerMinute: 57 / 110 / 152 / 200 / 220 / 222 / 328), rounded nicely (like PumpShop round()). Base rate = no passes, trainers, auras, rush hour or events, so boosts never change prices or reward sizes.
- Use it everywhere below. Show the real coin number in the UI (never "minutes").

1) REWARDS SCALE WITH THE PLAYER'S STAGE (max(old value, new value))
- Daily login (days 1-7): 2, 2, 3, 4, 5, 6, 15 minutes. DNA tokens on day 4 + 7 unchanged.
- Daily quests: 3 minutes each; all-done bonus 10 minutes.
- Coach quests: keep their order; reward = 1 min (first ones) up to 5 min (late ones), + their shakes.
- Posing shows: 1st 8 min, 2nd 5 min, 3rd 3 min, entering 1 min (each show tier keeps its unlock).
- Rivals: 5 / 8 / 12 minutes (+ titles unchanged). Legends: 3 minutes. Unlock guides: 1 minute.
- Offline coins: 2% of the stage rate per minute away, cap 8 h (was 0.5 a minute).
- Small stuff: re-rack plate 0.1 min, spotting payout 0.1 min, arm-wrestle win 0.5 min (loss 0.15 min), group daily chest 3 min.
- One-time gifts (group gift, rebalance gift, Starter Pack coins): Starter Pack = 60 minutes, group gift = 15 minutes, rebalance gift stays 500 (min) or 5 minutes.
- Update every reward text/toast so it shows the real number.

2) COIN PACKS SCALE WITH THE PLAYER'S STAGE
- Small (25 R$) = 20 minutes of coins, Medium (99 R$) = 120 minutes, Large (249 R$) = 360 minutes, each never less than today's 1,000 / 5,000 / 15,000.
- The amount is calculated on the SERVER at purchase time from the player's stage (in ProcessReceipt), and the Store card shows the exact number for that player before they buy ("+19,700 COINS").
- Write new Roblox product descriptions for me (no fixed number, e.g. "A big pile of coins. The bigger you are, the more you get.") and list them in the note.

3) CAP COIN BOOSTS
- Trainers: their total COINS boost is capped at +100% (other trainer kinds keep their caps).
- All coin multipliers together (2x Coins pass, VIP, trainers, auras, rush hour, events, group perk, boosts) are capped at x8 total, applied in ONE place (the coin payout function). Show it in Stats: "COIN BOOST x5.2" and "x8 (MAX)" when capped.
- EXP boosts are not changed by this prompt.

4) NEW COIN SINKS (cosmetic only, no stats). Sold in a new STYLE tab in the PUMP SHOP (tabs: SUPPLEMENTS · STYLE · DNA LAB) + a small TRAINER SNACKS section at the Agency desk.
- NAME TAG COLOURS: 8 solid colours (5,000-20,000 coins) + 4 gradients (60,000-120,000), shown on the overhead name. Preview before buying.
- TITLE COLOURS: same idea for the overhead title (prices ~same as name tags).
- AURA COLOUR VARIANTS: for each aura the player owns, 2 colour variants (e.g. Ember -> Blue Ember, Purple Ember) at 25,000 / 50,000. Same VFX, new colours. Equip in Inventory > Auras.
- ALTER COLOUR VARIANTS: for each alter the player owns, 2 tints of its skin (e.g. Pumped -> Crimson, Rose) at 40,000 / 80,000. Equip in Inventory > Alters.
- TRAINER XP SNACKS (consumable, scale with stage): Small Snack 3 min of coins = +1 level worth of trainer EXP at low levels; Medium 10 min; Large 30 min. Feed from MY TRAINERS (a FEED button on the detail card). Numbers in config; never skips evolutions (still needs 3 dupes). NO coin fee for evolving trainers (owner).
- All these cosmetics are bought once and kept forever; fixed prices (not scaled), so they're real long goals.

TEST: a save at Spurt 0, Spurt 3 and 7'0": check login, daily quest, posing show, offline and coin pack amounts (Studio test purchase), a heavily boosted save (coin boost shows x8 MAX), buying a name colour, an aura variant, an alter variant and feeding a snack. Put a before/after table of every reward and price at Spurt 0 / 3 / 7'0" in the progress note.
```
