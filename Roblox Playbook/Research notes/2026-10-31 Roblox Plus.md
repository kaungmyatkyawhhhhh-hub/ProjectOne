# Roblox Plus for developers (researched 31 Oct 2026)

- Roblox Plus replaced Premium (launched 30 Apr 2026, $4.99/month).
- **Detect:** `Player.HasRobloxSubscription` (boolean). Watch it on the server with `GetPropertyChangedSignal` before giving rewards. `MarketplaceService:GetRobloxSubscriptionDetailsAsync(player)` gives IsSubscribed, StartTime, IsOriginExperience (subscribed through this game).
- **Don't use MembershipType:** it returns Premium for Plus subscribers "for backwards compatibility" (Roblox staff on the DevForum); use HasRobloxSubscription.
- **Prompt:** `MarketplaceService:PromptRobloxSubscriptionPurchase(player)` (Roblox's sample calls it on the server, debounced 5 s). `PromptRobloxSubscriptionPurchaseFinished(player, didTryPurchasing)` fires when it closes; then wait for HasRobloxSubscription to change.
- **Payouts:** 250 Robux a month for a new subscriber's first 3 paid months (max 750), ONLY when they subscribe through the game's own prompt; 60-day hold. Plus discounts (10%, 20% from month 3) are paid by Roblox, so earnings per purchase stay the same. Paid private server time and Robux transfers also pay.
- **Prices:** hard-coded prices show Plus players the wrong price; use GetProductInfoAsync / GetDeveloperProductsAsync for live prices.
- **Perks:** the docs don't limit creator perks; their samples give an exclusive area / a skin.
- **GYM ARC (31 Oct):** +20% EXP, +10% coins, +15% stamina refill (Config/Plus); a "PLUS +20% EXP" button for non-Plus players; a Plus tile in the bottom-left boosts row.

Sources: https://create.roblox.com/docs/production/monetization/roblox-plus , https://devforum.roblox.com/t/playermembershiptype-returns-premium-for-roblox-plus-subscribers/4607269 , https://playtoearn.com/news/roblox-plus-launches-april-30-at-499-monthly-replacing-premium-with-discount-first-model
