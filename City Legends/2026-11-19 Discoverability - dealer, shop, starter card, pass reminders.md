---
tags: [city-legends, monetization, store, mobile]
created: 2026-11-19
---
# City Legends: dealer and shop one tap away (19 Nov 2026)

Owner-approved, 19 Nov: "make the dealership and the store easy to find". Phone first (93% of players are on phones). Follows [[2026-11-18 Store live - passes and products]] and step 5 (measuring) of [[2026-11-18 Monetization and economy - plan]]. In Studio, saved, not published.

## What is new
- **HUD icon column:** DEALER and SHOP come first, then JOBS, then the old icons. Order: Dealer, Shop, Jobs, Menu, Cars, Goals, Market, Chauffeur, Despawn, House.
  - With 8 or 9 icons the column now wraps into a second column: 5 high on a phone (it stays above the steering), 6 on PC.
  - The DEALER icon is a showroom (a roof over a car). SHOP uses the cart icon.
- **DEALER** opens the dealer menu from anywhere, with no teleport.
  - BUY works anywhere. The server still checks the car, the level, the price and the cash, and charges once. Only the "you must stand in the showroom" rule is gone.
  - **TEST DRIVE works anywhere too.**
    - The test car comes out where your car is (or in front of you on foot, else on the nearest lane).
    - When the test ends, your own car comes back at the spot where the test started.
    - At the dealership, tests still start from the drive-out bay.
    - You can't start a test far from the dealership during a race or job.
  - The building's prompts open the same screen as before.
- **SHOP** opens the main menu on the STORE tab.
  - A small red "!" shows while the store has an item you haven't looked at yet. It is saved per player and goes away once you open the STORE tab. A new store item shows it again.
- **Starter Pack card:** a small card under the top bars, with the art, one line of what's in it, BUY (price from Roblox: R$ 49) and an X.
  - Shown by the server after your first finished race or job paycheck of a session.
  - Only after the first car is claimed, and it waits until no menu is open.
  - Never once bought. Never again after it was closed twice. At most once a session.
  - No timers, no "was" prices.
- **Pass reminders:**
  - Owners of 2x Cash see a small gold "2x" chip on the cash pill.
  - For players without Double Pay: a "2x with Double Pay ›" link under a job paycheck.
    - It stays 6 s and shows at most once every 10 minutes.
    - Tapping it opens Roblox's buy window.
    - The Starter Pack card removes it if both come at once.
- **Measuring:** AnalyticsService custom events `OfferSeen`, `OfferPrompted` and `OfferBought`.
  - Field 1 is the item (`starter`, `doublepay`, `cash2x`, `vip`, `garage`).
  - Field 2 is where it was offered (`store`, `card`, `paylink`).
  - In Studio they are also printed as `[Offers] ...` lines in the Output.
  - Read them in Creator Hub > Analytics > Custom events after 7 days: revenue per 1,000 players, and the prompt-to-buy % per place (K04).

## Code
- New: `src/server/Offers.lua` (the card's moments, the "!", the events; saved in `profile.Activities.offers`) and `src/client/OffersClient.lua` (the card, the link, the STORE tab's events).
- `UI.lua`:
  - the column grid
  - the DEALER and SHOP buttons, with `UI.onDealerButton` / `UI.onShopButton`
  - the `dealer` icon
  - the "!" (player attribute `StoreUnseen`) and the "2x" chip (attribute `Cash2x`)
- `Main.client.lua`: `openDealer` (shared by the prompts and the button), SHOP = the cash pill's +, the Offers start step.
- `MainMenu.lua`: the `MainMenu.onStore` hook (STORE tab shown, a buy window opened).
- `Main.server.lua`:
  - BuyCar without the distance check
  - TestDrive from anywhere (`testSpot`, `testHome`)
  - the Offers start
- Studio test hook (server player attribute, Studio only): `TestOfferReset = true` clears the card's saved state and this session's flag. With `TestPaycheckSeconds` and a post job (tea), the card comes after the first 5-second paycheck.

## Tests (Studio Play on `CityLegends_test`, 19 Nov; back on `CityLegends_v1`, checked on the Server, place saved)
- DEALER button opened the dealer menu about 6 km from the dealership (PC and phone size).
- Remote test drive (a car sold first on the test save):
  - the test car came out exactly where the player's car was (0 studs)
  - after it was driven 150 studs and the test ended, the player's own car came back at the start spot
- Remote buy: one charge ($29,500). A second buy said "Already owned". An unknown car was refused.
- The building path (`DealerOpen`) still opens the menu. The Legends Motors building has 6 prompts.
- SHOP opened the STORE tab. `StoreUnseen` went 5 -> 0 and the "!" went away. Five `OfferSeen store` events.
- Starter card: shown after the first tea-shop paycheck (PC and phone). Price R$ 49 from Roblox. X closed it.
  - First run: the Double Pay link and the card came 1.5 s apart in the same slot. Fixed: the card removes the link.
  - The link did not come again within 10 minutes.
- "2x" chip shows on the cash pill (the owner's account owns 2x Cash).
- No script errors from these changes.

![[2026-11-19 Discoverability - phone HUD (dealer, shop, 2x).jpg]]
![[2026-11-19 Discoverability - phone starter card.jpg]]
![[2026-11-19 Discoverability - phone dealer from HUD.jpg]]
![[2026-11-19 Discoverability - PC dealer from HUD.jpg]]
![[2026-11-19 Discoverability - PC remote test drive.jpg]]
![[2026-11-19 Discoverability - PC starter card after paycheck.jpg]]
![[2026-11-19 Discoverability - PC store from SHOP.jpg]]

## Not tested
- A real buy through Roblox's window from the card or the link (the MCP can't click it). `OfferBought` is logged from `PromptGamePassPurchaseFinished` / `PromptProductPurchaseFinished`, so it was not seen firing.
- The card after a finished race (the paycheck path was tested; both use the same server hook).
- A remote test drive started on foot.
- A real phone.
- Lune / luau-lsp (not on this PC). Every changed script compiled in Studio (`loadstring`).
