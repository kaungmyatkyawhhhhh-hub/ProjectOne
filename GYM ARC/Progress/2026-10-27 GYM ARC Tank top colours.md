---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Tank top colours in the clothing store (prompt 75)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 75 Tank top colours]]. Feature: [[GYM ARC - Wardrobe and Gear and Fits Store]].

- **Where:** the clothing store's left mirror (by the changing curtain): prompt "Customize / Tank top" (`TankTopPrompt` on `MirrorPanel.Mirror`; TownService sends "OpenTankTop").
- **Screen (`TankTopClient`):** a BLACK + GOLD panel on the right with 12 swatches: MINE (your own Roblox shirt; the white tank top without one), White (free), Black, Grey, Red, Orange, Pink, Purple, Blue, Teal, Green (1,000 each), Gold (1,500). Owned = no price; worn = a gold tick. Tap a swatch = try it on (8 s, the server shows it on you); the button: the price with a coin (red CTA) / WEAR (gold) / WEARING. You turn to face into the shop, the camera looks at you from the front (wider view), the HUD steps aside; the X or walking 10 studs away closes it.
- **Server (`CosmeticService` action "TankTop": Try / Stop / Buy / Wear):** only near the clothing store; ids and prices from `Config/Body.TankShop`; a buy spends coins through PlayerData once (`cosmetics.owned["Top_<id>"]`, so red / blue / gold / black bought in the old PUMP SHOP apparel are already owned) and wears it (`settings.top`).
- **Over your own shirt:** a tank top picked here (or tried on) is worn over the player's own Roblox shirt (`TopOverShirt` attribute from BodyService, read in `MuscleRig.StyleFrom`); MINE (settings.top = "Shirtless") brings the shirt back.
- New colours in `Config/Body.Tops`: TankGreen, TankTeal, TankPurple, TankPink, TankOrange, TankGrey.
- Tested on LuigiRED: try red (shows over the knit shirt), buy red (1,000 coins, saved, WEARING), MINE (own shirt back), close (camera, HUD and turning restored). The test save now owns the red tank top.
- Note: the shop is small next to a very big body, so the camera can't back far away there.
- (owner: "the proximityprompt is still showing even when in the customization screen") all world prompts are hidden on your screen while the TANK TOP screen is open (ProximityPromptService off, back as it was on close). Tested.- A SKINS tab (alter skins at the mirror) was tried and taken out again: owner, "the skins are not gonna be in the customization tab. its in the alters in inventory already". The mirror is tank tops only; the try-on code for skins was removed from CosmeticService / BodyService. The test save's worn skin is back on Granite (the test had switched it to Pumped).
