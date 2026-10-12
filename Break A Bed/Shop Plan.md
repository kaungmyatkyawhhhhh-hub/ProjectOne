# Break A Bed: Shop Plan (cheap products)

#break-a-bed #monetization

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's decision (2026-10-12): **keep game pass prices as they are now** and add **lots of cheap developer products**, like timed x2, x3 and x5 Strength boosts. Cheap buys (R$9–R$49) get many more players to pay at least once, and players who buy once usually buy again.

## Game passes: no price change
- Strength tiers stay the same: x2 R$19 → x3 R$39 → x5 R$79 → x7 R$149 → x10 R$249 → x15 R$399.
- Auto Punch, x2 Cash, VIP, Fast Walk and Break Spam keep their current prices.

## New and changed developer products
**Prices set on 2026-10-12** (owner: cheap, but each one above R$5–6). Sales data so far: R$537 total, R$501 from passes and only R$36 from products. Everything is now **R$9–R$49** (owner: at least more than R$5–6, so each sale is worth it), so buying is an easy impulse. Players buy more often, and the boosts stack up.

### Timed boosts (10 minutes; buying again adds 10 more minutes)
| Product | Price |
|---|---|
| x2 Strength | R$9 |
| x3 Strength | R$15 |
| x5 Strength | R$25 |
| x10 Strength | R$49 |
| x2 Cash | R$9 |
| x3 Cash | R$15 |
| x5 Cash | R$25 |
| Fast Punch (punches 1.5x faster) | R$10 |
| **Server x2 Strength** (whole server, 15 min, buyer's name announced in chat) | R$49 |

- Only the highest active Strength boost counts, and the same goes for Cash. Boosts multiply with passes, so a x15 pass player with a x5 boost gets x75.
- The existing 15-minute x2 Strength / x2 Cash products become the new x2 ones.
- Active boosts show as small icons with timers under the top bar.

### Instant packs
| Product | Price |
|---|---|
| Small Cash (10 breaks of your best bed) | R$9 |
| Medium Cash (40 breaks) | R$15 |
| Big Cash (150 breaks) | R$30 |
| Huge Cash (500 breaks) | R$49 |
| Small Strength (1 minute of your best post at full speed) | R$9 |
| Medium Strength (5 minutes) | R$15 |
| Big Strength (20 minutes) | R$30 |
| +1 Level | R$9 |
| +3 Levels | R$20 |
| +9 Levels | R$49 |
| +1 Spin | R$9 |
| +3 Spins | R$15 |
| +10 Spins | R$39 |

- Cash and Strength packs grow with your progress, so they're worth buying at any point.
- Show a **"BEST VALUE"** tag on the biggest pack of each row and a **"POPULAR"** tag on the middle one.

### Impulse buys (shown at the right moment)
- **"Need more Strength?"** When the bed prompt says "Need X Strength", show a small button: *x3 Strength 10 min, R$15*.
- **Instant Break: R$9.** Breaks the bed you're stuck on once, paying its Cash and marking it completed. It's shown on the same "Need X Strength" prompt.
- **Starter Pack: R$19, one time only.** x3 Strength 30 min + Medium Cash + 3 Spins. It pops up once, after the player's first bed break (not on join), with a "70% OFF" tag.
- **Boost ran out:** when a boost ends, a small toast offers "Buy again, R$X".

## Where it goes in the shop
- **BOOSTS tab:** all timed boosts, with the Server boost as the yellow featured card.
- **CASH tab:** Cash, Strength and Level packs, with the Starter Pack as the featured card until it's bought.
- **PASSES tab:** unchanged.
- **FREE tab:** daily reward, spin wheel and the new Free Gifts ([[Break A Bed/Playtime Rewards|Playtime Rewards]]).
- Everything uses the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Add every product above to `GameConfig` (ids start at 0, so they show "Coming soon").
2. Follow the existing purchase safety: give the item only after Roblox confirms the purchase and the save has loaded, give each purchase once, and save active boost time.
3. Make a list of the product names and prices for the owner to create on the Creator Dashboard, then put the ids in `GameConfig`.

**Why these prices:** Roblox keeps 30% and rounds the owner's share down (R$1 earns 0). The lowest price is R$9 (earns 6). Prices like R$10, R$15, R$20, R$30 and R$40 waste the least in rounding.

## Creator Dashboard checklist (updated 2026-10-12 from the owner's screenshots)
Everything below is in the group **Myanmar Builders Club**. "Managed pricing" (Roblox picking prices by itself) was **on** for all of them.

### Game passes on Roblox now (keep prices)
| Pass | Id | Price |
|---|---|---|
| 2x Strength | 2025698622 | R$19 |
| 3x Strength | 2026640792 | R$39 |
| 5x Strength | 2025938789 | R$79 |
| 7x Strength | 2026100810 | R$149 |
| 10x Strength | 2026352775 | R$249 |
| 15x Strength | 2026046797 | R$399 |
| VIP | 2026130800 | R$199 |
| Fast Walk | 2025878796 | R$49 |
| Break Spam | 2026844790 | R$79 |
| x2 Cash | 2026892819 | R$99 |
| Auto Punch | 2027108793 | R$149 |
| ~~3x Strength (old)~~ | 2025644838 | offsale, not used. `GameConfig` must use 2026640792 |

### Developer products on Roblox now → new price (keep their names and ids)
| Product | Id | Now | New |
|---|---|---|---|
| +1 Level | 3717759760 | R$8 | R$9 |
| +3 Levels | 3717759985 | R$19 | R$20 |
| +9 Levels | 3717760165 | R$49 | R$49 (no change) |
| x2 STRENGTH (becomes 10 min) | 3717919099 | R$29 | R$9 |
| x2 CASH (becomes 10 min) | 3717918907 | R$29 | R$9 |
| +3 SPINS | 3717918726 | R$25 | R$15 |
| +10 SPINS | 3717918786 | R$69 | R$39 |
| CASH PILE (= Medium Cash, 40 breaks) | 3717917664 | R$19 | R$15 |
| CASH BAG (= Big Cash, 150 breaks) | 3717918038 | R$49 | R$30 |
| CASH VAULT (= Huge Cash, 500 breaks) | 3717918420 | R$129 | R$49 |

To set these prices, turn **Managed pricing off** for each product, or Roblox may change them back.

### Names and pictures for the existing products and passes
All names in capitals so the shop looks tidy. Renaming keeps the same id. Pictures are in `Break A Bed/Product Icons/`.

| Type | Name | Picture |
|---|---|---|
| Product | +1 LEVEL | `plus1-level.png` |
| Product | +3 LEVELS | `plus3-levels.png` |
| Product | +9 LEVELS | `plus9-levels.png` |
| Product | x2 STRENGTH (10 MIN) | `x2-strength-10min.png` |
| Product | x2 CASH (10 MIN) | `x2-cash-10min.png` |
| Product | +3 SPINS | `plus3-spins.png` |
| Product | +10 SPINS | `plus10-spins.png` |
| Product | CASH PILE | `cash-pile.png` |
| Product | CASH BAG | `cash-bag.png` |
| Product | CASH VAULT | `cash-vault.png` |
| Pass | 2x STRENGTH | `pass-2x-strength.png` |
| Pass | 3x STRENGTH | `pass-3x-strength.png` |
| Pass | 5x STRENGTH | `pass-5x-strength.png` |
| Pass | 7x STRENGTH | `pass-7x-strength.png` |
| Pass | 10x STRENGTH | `pass-10x-strength.png` |
| Pass | 15x STRENGTH | `pass-15x-strength.png` |
| Pass | VIP | `pass-vip.png` |
| Pass | FAST WALK | `pass-fast-walk.png` |
| Pass | BREAK SPAM | `pass-break-spam.png` |
| Pass | x2 CASH | `pass-x2-cash.png` |
| Pass | AUTO PUNCH | `pass-auto-punch.png` |

![[Product Icons/_old-products.png]]

![[Product Icons/_game-passes.png]]

### Create these 15 new developer products
Pictures for each (512 × 512) are in `Break A Bed/Product Icons/`, named after the product (for example `x3-strength-10min.png`).

![[Product Icons/_all-products.png]]

x3 Strength R$15 · x5 Strength R$25 · x10 Strength R$49 · x3 Cash R$15 · x5 Cash R$25 · Fast Punch R$10 · Server x2 Strength R$49 · Small Cash R$9 · Small Strength R$9 · Medium Strength R$15 · Big Strength R$30 · +1 Spin R$9 · Instant Break R$9 · Starter Pack R$19 · Skip All Gifts R$49

Total after this: **25 developer products + 11 game passes**. Claude Code must change what the reused products give (10-minute boosts, Cash packs = 40/150/500 breaks).

## Steps for the owner
1. Paste to Claude Code: *"Read my vault note Break A Bed/Shop Plan.md and add all of it to the game."*
2. Go to **create.roblox.com → Break a Bed → Monetization → Developer Products** and create each product with its name and price.
3. Copy each product's id and give the list to Claude Code.
