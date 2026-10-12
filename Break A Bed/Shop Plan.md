# Break A Bed: Shop Plan (cheap products)

#break-a-bed #monetization

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's decision (2026-10-12): **keep game pass prices as they are now** and add **lots of cheap developer products**, like timed x2, x3 and x5 Strength boosts. Cheap buys (R$1–R$49) get many more players to pay at least once, and players who buy once usually buy again.

## Game passes: no price change
- Strength tiers stay the same: x2 R$8 → x3 R$12 → x5 R$20 → x7 R$50 → x10 R$75 → x15 R$100.
- Auto Punch, x2 Cash, VIP, Fast Walk and Break Spam keep their current prices.

## New and changed developer products
**Prices lowered again on 2026-10-12** (owner: "products are too expensive"). Sales data so far: R$537 total, R$501 from passes and only R$36 from products. Everything is now **R$1–R$49**, so buying is an easy impulse. Players buy more often, and the boosts stack up.

### Timed boosts (10 minutes; buying again adds 10 more minutes)
| Product | Price |
|---|---|
| x2 Strength | R$3 |
| x3 Strength | R$7 |
| x5 Strength | R$15 |
| x10 Strength | R$29 |
| x2 Cash | R$3 |
| x3 Cash | R$7 |
| x5 Cash | R$15 |
| Fast Punch (punches 1.5x faster) | R$5 |
| **Server x2 Strength** (whole server, 15 min, buyer's name announced in chat) | R$49 |

- Only the highest active Strength boost counts, and the same goes for Cash. Boosts multiply with passes, so a x15 pass player with a x5 boost gets x75.
- The existing 15-minute x2 Strength / x2 Cash products become the new x2 ones.
- Active boosts show as small icons with timers under the top bar.

### Instant packs
| Product | Price |
|---|---|
| Tiny Cash (3 breaks of your best bed) | R$1 |
| Small Cash (10 breaks) | R$3 |
| Medium Cash (40 breaks) | R$9 |
| Big Cash (150 breaks) | R$25 |
| Huge Cash (500 breaks) | R$49 |
| Tiny Strength (20 s of your best post at full speed) | R$1 |
| Small Strength (1 minute) | R$3 |
| Medium Strength (5 minutes) | R$9 |
| Big Strength (20 minutes) | R$25 |
| +1 Level | R$5 |
| +3 Levels | R$12 |
| +9 Levels | R$29 |
| +1 Spin | R$2 |
| +3 Spins | R$5 |
| +10 Spins | R$15 |

- Cash and Strength packs grow with your progress, so they're worth buying at any point.
- Show a **"BEST VALUE"** tag on the biggest pack of each row and a **"POPULAR"** tag on the middle one.

### Impulse buys (shown at the right moment)
- **"Need more Strength?"** When the bed prompt says "Need X Strength", show a small button: *x3 Strength 10 min, R$7*.
- **Instant Break: R$2.** Breaks the bed you're stuck on once, paying its Cash and marking it completed. It's shown on the same "Need X Strength" prompt.
- **Starter Pack: R$9, one time only.** x3 Strength 30 min + Medium Cash + 3 Spins. It pops up once, after the player's first bed break (not on join), with a "70% OFF" tag.
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

## Creator Dashboard checklist (2026-10-12)
**Game passes:** nothing new, no price changes (11 passes: Strength x2, x3, x5, x7, x10, x15, Auto Punch, x2 Cash, VIP, Fast Walk, Break Spam).

**Change these 10 existing developer products:**
| Old product | New name | New price |
|---|---|---|
| +1 Level | +1 Level | R$5 |
| +3 Levels | +3 Levels | R$12 |
| +9 Levels | +9 Levels | R$29 |
| x2 Strength boost (15 min) | x2 Strength (10 min) | R$3 |
| x2 Cash boost (15 min) | x2 Cash (10 min) | R$3 |
| +3 Spins | +3 Spins | R$5 |
| +10 Spins | +10 Spins | R$15 |
| Cash pack 1 (30 breaks) | Medium Cash | R$9 |
| Cash pack 2 (120 breaks) | Big Cash | R$25 |
| Cash pack 3 (400 breaks) | Huge Cash | R$49 |

**Create these 17 new developer products:**
x3 Strength R$7 · x5 Strength R$15 · x10 Strength R$29 · x3 Cash R$7 · x5 Cash R$15 · Fast Punch R$5 · Server x2 Strength R$49 · Tiny Cash R$1 · Small Cash R$3 · Tiny Strength R$1 · Small Strength R$3 · Medium Strength R$9 · Big Strength R$25 · +1 Spin R$2 · Instant Break R$2 · Starter Pack R$9 · Skip All Gifts R$49

Total after this: **27 developer products + 11 game passes**. The reused products keep their ids, but Claude Code must change what they give (10-minute boosts, Cash packs = 40/150/500 breaks).

## Steps for the owner
1. Paste to Claude Code: *"Read my vault note Break A Bed/Shop Plan.md and add all of it to the game."*
2. Go to **create.roblox.com → Break a Bed → Monetization → Developer Products** and create each product with its name and price.
3. Copy each product's id and give the list to Claude Code.
