---
date: 2026-11-01
tags: [gymarc, progress, monetization, ui]
---
# GYM ARC - small offer bars, out-of-coins everywhere, potential statue shirt (1 Nov, later)

Owner feedback: refill prompt bad; out of coins + refill should be small (sketch: one line "Out of coins? buy more" + 3 small buttons); out of coins must show above screens and on ANY failed coin buy; potential guy shirtless, no face; arm wrestling prompt "everywhere".

## Done
- New Shared/UI/MiniOffer: small bar at the bottom centre, gold title, a row of small buttons, X; DisplayOrder 75 (over windows 25-30, trainer roll 52-60, toasts 50); slides up; auto hides.
- CoinOffer rebuilt on MiniOffer: "OUT OF COINS? BUY MORE" + 3 packs "+coins · R$ price". Cooldown 120 s -> 10 s. Triggers: any toast/message whose title OR sub says "not enough coins" / "out of coins" / "need N coins" (Notify), and server PlayerData.SpendCoins refusing -> PlayerEvent "NotEnoughCoins" (TutorialExtrasClient listens). Not in tutorial / runway / menu.
- Stamina refill offer now the same small bar: "OUT OF STAMINA?" + "INSTANT REFILL · R$ 5".
- Potential statue: Top "Shirtless" -> PlayerTop (Tank) / their own shirt, like the live player (PublishData only does it for Player instances).

## Findings
- No face: the owner's own Roblox avatar is faceless (the Roblox headshot has no face; a fresh rig from the avatar has none either). Not a game bug; adding a decal would double faces on dynamic heads that have one.
- Arm wrestling: could not reproduce "prompt everywhere" (prompts only on the 4 stools, 4.5 studs; label above the table; the panel closes on stand up). Asked owner for a screenshot.
