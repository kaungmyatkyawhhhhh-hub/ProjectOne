# Prompt: real car prices (new = dealer price, old = used-market price) and harder (but fair) cash

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Read the Roblox Playbook rules first (`Roblox Playbook/Roblox Playbook - Rules for every game.md`), especially the money and retention rules._

## What the owner wants (2026-11-07)
"Make the cars' price their actual current price at a dealership, and the used market price for old cars. Also make the cash harder to get since the car prices change, but not too hard to the point players quit."

## Part 1: real prices for every car
### The rule
- **Cars still sold new** (the model / generation is on sale today): the **current base dealer price (MSRP)** of that exact trim, in **US dollars**.
- **Cars no longer sold** (old generations, discontinued models): the **current average used-market price** in the US, for a good-condition example with normal miles.
- **Collector cars** (e.g. the LFA, Countach, Veyron, SLS Black Series-type rare models, R34, early Supra MK4): their **real current market value**, which can be far above the original price. Use auction results / collector valuation guides.
- **Hypercars still sold** (Chiron family / Revuelto etc.): the real current price; if not sold any more, the current market value.
- Round to a clean number (e.g. $28,400 → $28,500; $1,183,000 → $1,180,000).

### How to research
- Use recent, reliable sources: the maker's US site / price lists for new cars; big used-car valuation guides and current listings for used; auction results and collector valuation guides for collector cars. Use 2026 prices where you can.
- For each car write the **source and date** in a price table in `City Legends/City Legends.md`: game name (and id), the real model and trim it is, new or used, price, source. If sources disagree, take the middle.
- Sanity check (rough, from memory; trust your research over these): a new Camry is around $28–30K; a new G-Class G63 is around $180K+; an LFA sells for roughly $900K–$1.2M; a Countach 5000 QV for roughly $500K+; a Chiron for $3M+.

### Apply it (easy to change later)
- All prices stay in `Games/CityLegends/src/shared/Cars.lua` (`Price`), plus a `PriceSource = "new" | "used" | "collector"` field per car so the dealer can show a small tag ("NEW", "USED", "COLLECTOR").
- **Keep the free starters free** (the starter pick). Their dealer price (for buying a second one) is their real price.
- **Trims, the Customs price multipliers, the part prices (`Config.partCash` / `CashRef`), the brand discount, the Legends spin's car prizes (`carMax` / `carCash`), the car stock market, the garage sell-back value, the hotel / tower / house prices that are tied to car prices**: check every place that reads a car's price and make sure they still make sense (**part and engine-swap prices follow real aftermarket prices, not the car's price**: see `Better upgrade area and part shop.md` ("Part prices"); the owner, 2026-11-07: "make the part shop cheaper since a B58 is like over a million". Set `CashMax` to about 1.5 at most; then all part and swap prices × 1.75, `Config.Economy.PartPriceMult`).
- The **Tier** (Starter / Mid / High) stays as it is (it drives traffic, rewards and Customs), unless a car's new price makes it clearly wrong: list those, move them, and note it.
- **Old saves:** players keep every car and all their cash. Nothing is taken away. Sell-back values use the new prices.

## Part 2: harder cash, but fair (don't make players quit)
### First, measure (before changing anything)
- In Play, measure the **cash per hour** of each way to earn: driving / cut-ups, races, drift, jumps, speed traps, stunts, delivery jobs, chauffeur, the bank heist, duels, the daily streak, Legends Rewards timers (5 / 15 / 30 / 60 min), level-ups, the spin wheel, penthouse / hotel income. Write the table in the notes.
- Then work out how long a normal player needs for each step **at the new prices**.

### Targets (tune earn rates to hit these)
| Goal | Target play time (normal player, not grinding) |
|---|---|
| First paid upgrade (a cheap part) | under 10 minutes |
| First car bought with cash (a cheap Starter, about $25–35K) | about 30–60 minutes |
| A good Mid car (about $100K) | about 3–5 hours |
| A top Mid car ($200–300K) | about 8–12 hours |
| First High car (about $400–600K) | about 15–25 hours |
| A $1M+ car | about 35–60 hours |
| The top hypercars ($3M+) | about 100–150 hours (a long-term dream, with the rare spin / reward chances as shortcuts) |

### Rules so players don't quit
- **Early game stays fast and rewarding:** the free starter, quick first upgrades, the first hour full of small wins (Legends Path goals, first race, first job pay well for their time).
- **Always something in reach:** at every point a player should have a car, part or upgrade they can afford within about 1 hour of play.
- **Variety pays better than grinding one thing:** each activity has a fair rate; daily tasks and the daily streak give a real boost; online-time rewards stay.
- **Better cars earn a little more** (higher speeds = bigger cut-up and race payouts), so progress speeds up a bit as you go; keep it gentle.
- **No pay-to-win pressure:** Robux items stay optional (the store's cash packs and 2x Cash: flag to the owner if their values should change with the new prices; don't change Robux prices yourself).
- **Everything in `Config`** (one `Config.Economy` block with the main multipliers), so the owner can tune it fast. Note every old → new value.

## Check before you say done
- The price table (every car, source, date) and the before / after earn-rate table in `City Legends/City Legends.md`.
- A simulated progression (a small Lune script that "plays" a normal player's mix of activities) shows the targets above are met within about ±25%.
- In Play: the dealer shows real prices with NEW / USED / COLLECTOR tags; buying, selling, parts, Customs, spin prizes and the market all still work; old saves load with all cars and cash.
- Lune tests (`tools/carlevels_test.luau`, `market_test`, the new progression test) and `luau-lsp analyze` clean; no errors.
- Save the place, commit, push.

## When done, tell the owner (short)
- the price list (top 10 biggest changes) and where the full table is;
- the new time-to-car targets and how they were met;
- anything the owner should decide (Robux pack values, tier moves).
