# Break A Bed: Shop Plan (cheap products)

#break-a-bed #monetization

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's decision (2026-10-12): **keep game pass prices as they are now** and add **lots of cheap developer products**, like timed x2, x3 and x5 Strength boosts. Cheap buys (R$5–R$39) get many more players to pay at least once, and players who buy once usually buy again.

## Game passes: no price change
- Strength tiers stay the same: x2 R$8 → x3 R$12 → x5 R$20 → x7 R$50 → x10 R$75 → x15 R$100.
- Auto Punch, x2 Cash, VIP, Fast Walk and Break Spam keep their current prices.

## New and changed developer products

### Timed boosts (10 minutes; buying again adds 10 more minutes)
| Product | Price |
|---|---|
| x2 Strength | R$9 |
| x3 Strength | R$19 |
| x5 Strength | R$39 |
| x10 Strength | R$79 |
| x2 Cash | R$9 |
| x3 Cash | R$19 |
| x5 Cash | R$39 |
| Fast Punch (punches 1.5x faster) | R$15 |
| **Server x2 Strength** (whole server, 15 min, buyer's name announced in chat) | R$99 |

- Only the highest active Strength boost counts, and the same goes for Cash. Boosts multiply with passes, so a x15 pass player with a x5 boost gets x75.
- The existing 15-minute x2 Strength / x2 Cash products become the new x2 ones.
- Active boosts show as small icons with timers under the top bar.

### Instant packs
| Product | Price |
|---|---|
| Small Cash (10 breaks of your best bed) | R$5 |
| Medium Cash (40 breaks) | R$15 |
| Big Cash (150 breaks) | R$39 |
| Huge Cash (500 breaks) | R$99 |
| Small Strength (1 minute of your best post at full speed) | R$5 |
| Medium Strength (5 minutes) | R$15 |
| Big Strength (20 minutes) | R$39 |
| +1 Level | R$9 (was R$19) |
| +3 Levels | R$25 (was R$49) |
| +9 Levels | R$59 (was R$129) |
| +1 Spin | R$5 |
| +3 Spins | R$12 |
| +10 Spins | R$35 |

Cash and Strength packs grow with your progress, so they're worth buying at any point.

### Impulse buys (shown at the right moment)
- **"Need more Strength?"** When the bed prompt says "Need X Strength", show a small button: *x3 Strength 10 min, R$19*.
- **Instant Break: R$5.** Breaks the bed you're stuck on once, paying its Cash and marking it completed. It's shown on the same "Need X Strength" prompt.
- **Starter Pack: R$19, one time only.** x3 Strength 30 min + Medium Cash + 3 Spins. It pops up once, after the player's first bed break (not on join), with a "70% OFF" tag.
- **Boost ran out:** when a boost ends, a small toast offers "Buy again, R$X".

## Where it goes in the shop
- **BOOSTS tab:** all timed boosts, with the Server boost as the yellow featured card.
- **CASH tab:** Cash, Strength and Level packs, with the Starter Pack as the featured card until it's bought.
- **PASSES tab:** unchanged.
- **FREE tab:** daily reward, spin wheel and the new Free Gifts ([[Break A Bed/Playtime Rewards|Playtime Rewards]]).
- Everything uses the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style.

## For Claude Code (in `Cashgrab`)
1. Add every product above to `GameConfig` (ids start at 0, so they show "Coming soon").
2. Follow the existing purchase safety: give the item only after Roblox confirms the purchase and the save has loaded, give each purchase once, and save active boost time.
3. Make a list of the product names and prices for the owner to create on the Creator Dashboard, then put the ids in `GameConfig`.

## Steps for the owner
1. Paste to Claude Code: *"Read my vault note Break A Bed/Shop Plan.md and add all of it to the game."*
2. Go to **create.roblox.com → Break a Bed → Monetization → Developer Products** and create each product with its name and price.
3. Copy each product's id and give the list to Claude Code.
