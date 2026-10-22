---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 60 Auto Rep first, DNA Token pack, Starter Pack

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Monetization, owner 23 Oct. Real sales (last 30 days): Auto Rep 7 sales (best), DNA Token 7, 2x EXP 3. Build on what sells. Follow CLAUDE.md Speed rules. Mobile first. Keep the fairness rules: kids' game, no paid random rewards, no fake timers or "only X left", no popups during a set, free players can reach everything. All prices/IDs in Config.Monetization (0 = not set up yet: hide that item). At the end, list every NEW product with name, description, price and where to paste the ID, so I can create it on the Creator Hub.

1) AUTO REP FIRST
- Store > PASSES: Auto Rep is the hero card (left) for anyone who doesn't own it. (If owned, the hero shows the next pass they don't own, as in the Store restyle.)
- In the HUD, while on a machine and NOT owning Auto Rep: the REP button gets a small "AUTO" chip in its corner (quiet, graphite). Tapping the chip opens the Auto Rep card (picture, "Lifts for you while you're on a machine. Toggle it any time.", price, BUY). Owners see their normal AUTO toggle there instead.
- One soft offer per session: after a SET ENDS (never during one), if the player has done 150+ manual reps this session, show the small bottom card "Tired of tapping? AUTO REP lifts for you." with the price and an X. Not in the tutorial, not if they own it, auto-hides after 12 s. Log Offer_Shown_AutoRep / Offer_Tapped_AutoRep.

2) DNA TOKENS: A PACK + THE RIGHT MOMENT
- Keep the single DNA Token. Add a DNA TOKEN x3 developer product (suggested 249 R$ when the single is 99 R$; show "SAVE 16%" only if it's really cheaper per token).
- Show both side by side wherever DNA tokens are sold (Store > BOOSTS, Coach Dex SUPPLEMENTS, PUMP SHOP DNA LAB).
- Right moment: in the GENETICS screen, if the player has 0 DNA tokens and taps a reroll/upgrade that needs one, open a small card right there: "Need a DNA Token" with x1 and x3 and an X. Never pops up by itself.
- Explain clearly what a token does in one line on every card (from the genetics config), so kids know what they're buying.

3) STARTER PACK (one-time)
- New developer product STARTER PACK, suggested 49 R$, buyable ONCE per player (saved; hidden after buying).
- Contents (all guaranteed, nothing random; numbers in config): 5,000 coins, 3 Protein Shakes, 1 DNA Token, 30 min 2x EXP boost, and the exclusive cosmetic title "STARTER" (Rare style). Make sure the value is clearly bigger than the price (show "WORTH 199 R$" only if that's true by our own prices).
- When it shows: once, after the player's FIRST growth spurt celebration (bottom card, same style as the other offers, with an X). After that it lives in the Store as a pinned card at the top of BOOSTS and in the PASSES hero rotation, until bought. Truthful label "ONE-TIME OFFER" (it really can only be bought once). No countdown.
- Not shown in the tutorial or the first 5 minutes.
- On purchase: a reward popup that shows every item flying into the right place (coins to the counter, shakes to the hotbar, title to Inventory).

4) SAFETY + ANALYTICS
- All through the existing ProcessReceipt in MonetizationService (save before PurchaseGranted, never grant twice). Starter Pack: if somehow bought twice, the second grants coins equal to its value instead of a second title.
- Analytics: Offer_Shown/Tapped and Product_Bought for AutoRep, DNA_x3, StarterPack.

TEST (phone first): Store as a new player (Auto Rep hero), the AUTO chip on the REP button, the 150-rep offer after a set, Genetics with 0 tokens, the Starter Pack after the first growth spurt, a Studio test purchase of DNA x3 and the Starter Pack (and a second Starter Pack purchase attempt). Screenshots. Short progress note in the vault + update the Monetization note with the new product list.
```
