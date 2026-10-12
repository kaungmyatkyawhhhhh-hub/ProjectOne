# Break A Bed: Limited Auras

#break-a-bed #monetization #auras

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): **limited-time auras** that boost **Strength and Walk Speed**, sold like the "Featured" egg in the simulator the owner likes. Auras come from an **Aura Crate** with a timer, chances shown on screen, and 1 / 3 / 10 buy buttons.

![[preview-aura-crate.png]]

## The Galaxy Aura Crate (first limited crate)
It's on sale for **7 days**. After that it's gone and a new themed crate replaces it (Lava, Ice, Candy…). Auras you already own stay forever.

| Aura | Chance | Strength boost | Walk Speed boost | Look (see [[Break A Bed/Effects/Effects|Effects]]) |
|---|---|---|---|---|
| Spark | 40% | x1.2 | +2 | white sparkles |
| Frost | 30% | x1.5 | +4 | cyan glow + a ring at the feet |
| Blaze | 18% | x2 | +6 | orange flames rising |
| Angel | 9% | x3 | +8 | white-gold wings + halo |
| Galaxy | 2.9% | x5 | +12 | purple/blue swirl + stars |
| **Infinity** | **0.1%** | **x10** | **+20** | rainbow swirl, wings, glow; a server announcement when someone gets it |

- **One aura equipped at a time.** Its boost multiplies with passes and boosts (x15 pass × Galaxy x5 = x75).
- Pictures for the crate menu and inventory: `aura-spark.png`, `aura-frost.png`, `aura-blaze.png`, `aura-angel.png`, `aura-galaxy.png`, `aura-infinity.png` (this folder).
- **Pity:** every 50 crates without Galaxy or better gives a guaranteed Galaxy (it shows "Galaxy in 37 crates"). This is fair and makes people buy more.
- Duplicates turn into **Aura Dust**. 10 dust = upgrade an aura to ★ (+10% of its boost), up to ★★★.

## Prices (developer products, create them under Myanmar Builders Club)
| Product | Price |
|---|---|
| AURA CRATE x1 | R$49 |
| AURA CRATE x3 | R$129 |
| AURA CRATE x10 | R$399 (red button, best value) |

The purple gift button next to each one buys it for another player in the server.

**Free ways to get crates** (so free players care too): 1 crate on day 7 of the daily reward, a 0.5% chance from the spin wheel, and the MEGA Free Gift.

## Where it shows up
- **Shop:** the **-- FEATURED --** section at the top, with a big card showing a "New!" tag, the crate name, "Limited Time!", a live countdown, the best aura big on the left, all auras with chances (the rarest in a rainbow-bordered slot), and the 3 buy buttons.
- **Opening animation:** the crate shakes, flashes and bursts with `fx-ring`, the slots roll past, and the aura reveal pops in with rays and its effect. Rare ones (Galaxy+) get a bigger flash, a sound and a server announcement.
- **Aura inventory:** a new **Auras** button (square, purple) on the right side of the main screen. It shows a grid of owned auras with their boosts and stars, plus an EQUIP button.
- The equipped aura shows on the player (others can see it) and replaces the level aura while equipped.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Put the crate (name, end time, auras, chances, boosts) in `GameConfig` so a new crate is easy to add each week.
2. The server rolls the auras (never the client), saves owned auras, dust, stars, pity and the equipped aura.
3. Use the usual purchase safety for the 3 products. Gifting uses `MarketplaceService:PromptProductPurchase` for the buyer, then gives the item to the chosen player on the server.
4. Build the Featured card like `preview-aura-crate.png` (FINAL STYLE in the [[Break A Bed/UI Kit/UI Kit|UI Kit]]), the opening animation and the inventory.
5. Build each aura's look with the particle images in [[Break A Bed/Effects/Effects|Effects]].
