# Flash TopUp - Buying psychology on the store page (6 Nov 2026)

Owner: "the products dont look intimidating" (= not tempting enough); use the psychology research.
Vault had game psychology only ([[2026-11-01 Supernova Incremental - UI, sound and psychology plan]], [[2026-11-05 GYM ARC Supplements - why 0 sales and how to sell more]]): colour = meaning, value shown with exact numbers, "BEST VALUE" only if true, banned fake timers / false scarcity / "BUY NOW!".
New research: [Cognitive Biases in Pricing (Monetizely)](https://www.getmonetizely.com/articles/cognitive-biases-in-pricing-how-customers-really-make-decisions)
- Anchoring: show a higher reference price next to the real one (can shift willingness to pay a lot).
- Center-stage + "Most Popular" badge: HubSpot saw +28% picks of the highlighted tier.
- Decoy: a nearby weaker option makes the target look better.
- Loss aversion: losses feel ~2x gains ("don't miss the bonus").
- Default effect: a pre-selected option gets chosen more.

## Applied on flashtopupmm.shop (commit after de2bc4b)
1. Honest anchor: crossed-out price = what the same diamonds/UC would cost at the smallest pack's rate; green "SAVE x%" tag (only if >= 5%).
2. Popular pack (78+8 / 60 UC style) gets a gold glowing border = centre of attention.
3. Popular pack is pre-selected, so the Buy bar is filled from the start.
4. Bonus amounts in green; tier colours = rarity ladder (blue, green, purple, orange, gold).
Not used (banned): fake countdowns, fake "x people bought", false scarcity.
Later: real "sold today" counter from orders; real customer proof gallery.
