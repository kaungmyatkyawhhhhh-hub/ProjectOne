---
date: 2026-11-06
tags: [gymarc, monetization, supplements, bundles, prompt]
---
# GYM ARC - Prompt: OP Robux supplement + bundles (6 Nov)

> **Built 6 Nov (Studio, not published):** [[2026-11-06 GYM ARC Pump Shop update - Titan Serum, Monster Mix, Beast Formula, bundles, Titan Mode]]. Products are placeholders until the owner sends the ids.

Owner (6 Nov): "we need to add like a OP robux supplement but pricier and bundles".

Based on:
- [[2026-11-05 GYM ARC Supplements - why 0 sales and how to sell more]]
- the 5 Nov GAINS/STAMINA progress note
- [[2026-10-29 GYM ARC Prices - every coin and Robux item]]
- the 30-day revenue read (Auto Rep 9.6K, VIP 6.5K, DNA x3 4.7K, 2x EXP 4.5K; avg sale R$105)

Decisions (Claude):
- **OP = strongest, short, pricier.** It must clearly beat GAINS and still never be required to progress.
- **No luck** (paid random-item rule).
- **No fake timers or "was" prices**, and "BEST VALUE" only where it's true.
- **Nothing existing gets weaker.**

## The shelf after this
| Item | Effect | Price |
|---|---|---|
| GAINS (exists) | +60% EXP 30 min | 25 / x5 99 |
| STAMINA (exists) | full + 60% faster refill 30 min | 25 / x5 99 |
| **TITAN SERUM (new, OP)** | **x2.5 EXP + infinite stamina + x2 coins, 15 min**, golden aura on your character, "TITAN" tag over the head while active | **149** (x3 **399** = save 48) |
| **POWER HOUR bundle** | GAINS + STAMINA together (both 30 min) | **45** (save 5) |
| **GYM RAT PACK** | 5 GAINS + 5 STAMINA | **179** (save 19 vs two x5 packs) |
| **TITAN PACK** | 3 TITAN SERUM + 5 GAINS + 5 STAMINA | **549** (save 48 vs buying them separately) |

Notes:
- **TITAN SERUM with GAINS/Coach Dex boosts:** EXP multipliers add, not multiply. TITAN is capped so that TITAN + GAINS + a coin boost tops out at about x3.35 total. That's strong for 15 min but not run-breaking: a Growth Spurt is still minutes, not seconds. Claude Code checks it with the bot and reports how much faster a GS/alter gets with TITAN active.
- **Using a supplement again while it's active** adds time (TITAN up to 45 min, the others up to 60).
- **Packs go into the inventory as items**, used whenever the player wants. Nothing is wasted if they're offline.

```text
GYM ARC – OP SUPPLEMENT (TITAN SERUM) + BUNDLES. Quality over speed. Don't publish.

READ FIRST:
- GYM ARC\Monetization\2026-11-06 GYM ARC Prompt - OP supplement + bundles.md (this note, the table is the spec)
- GYM ARC\Progress\2026-11-05 GYM ARC Supplements Gains + Stamina, alter tints removed.md (how GAINS/STAMINA were built)
- GYM ARC\2026-10-29 GYM ARC Prices - every coin and Robux item.md

1. TITAN SERUM (new boost in Config/Boosts):
- Effect:
  - x2.5 EXP (EXP boosts ADD with GAINS / Coach Dex);
  - infinite stamina (no stamina drain);
  - x2 coins from reps.
- 15 min. Using it again adds 15 min, max 45. Counts on Auto Rep too.
- Visual: gold aura on the character (8-15 particles, off past ~60 studs, phone fewer), a "TITAN" tag under the name plate, a gold timer tile in the boost row.
- Art: a new tub icon, gold and dark red, glowing "T" emblem. Give me the ChatGPT prompt for the icon; don't make the art yourself.
- Bot check: time for one Growth Spurt and one alter with and without TITAN (+ GAINS + best coin boost). Report the speed-up.

2. BUNDLES (developer products; ProcessReceipt only, save first, never twice):
- POWER HOUR 45: starts GAINS + STAMINA now.
- GYM RAT PACK 179: adds 5 GAINS + 5 STAMINA to the inventory.
- TITAN SERUM x1 149, x3 399: x1 starts now, x3 goes to the inventory.
- TITAN PACK 549: 3 TITAN + 5 GAINS + 5 STAMINA to the inventory.
- Inventory items are used from the boost row or the inventory. Owned counts show on the tiles.

3. SHOP LAYOUT (Pump Shop + the "Boosts" window from the HUD slot):
- Top: TITAN SERUM as the big featured card (gold frame, aura preview, exact numbers).
- Then GAINS and STAMINA (x1 / x5).
- Then a BUNDLES row with the "SAVE n R$" tag. Compute n from the real Roblox prices like the x5 tag does.
- "BEST VALUE" only on the pack with the lowest R$ per minute of boost. Compute it, don't hard-code it.
- Exact numbers on every card. No timers, no "was" prices.

4. MOMENTS (reuse the "See boost" system; max once per 5 min overall, never in the tutorial, never after a fail):
- Right after a Growth Spurt or an alter: "Go TITAN for the next one?" card → TITAN SERUM.
- Stamina out: STAMINA (as now). If they already bought STAMINA 3+ times, show POWER HOUR instead.
- Analytics per placement as before (Offer_Shown/Tapped/Bought_<p>).

5. PRODUCTS:
- Create these in the Creator Dashboard with the owner's OK (Claude in Chrome can do it): TITAN x1 149, TITAN x3 399, POWER HOUR 45, GYM RAT PACK 179, TITAN PACK 549.
- Managed pricing: same setting as the GAINS/STAMINA products.
- Put the IDs in Config/Monetization.
- Until then: PLACEHOLDER, cards hidden.

6. TEST + REPORT (stop after):
- PC + phone screenshots: shop, featured TITAN card, bundles row, the inventory, TITAN active (aura + tag + timer).
- Receipt tests (fake receipts, double-send).
- The bot speed-up numbers.
- Analytics events firing.
```

## ADD-ON (6 Nov): TITAN MODE transformation (owner: "that's gonna get people to purchase")
Rule: the theme stays fictional mad-science (glowing vials). No real drug names, no pills, no needles/injections (Roblox rules on real drugs + our kids audience).

```text
GYM ARC – TITAN MODE (add to the TITAN SERUM work). Don't publish.

1. FIRST-USE MOMENT (every activation, ~2.5 s, skippable after 0.5 s; Reduced Motion = no shake/flash):
- The character drinks a glowing gold vial: a quick tool animation (or the vial floats up, if no anim).
- Wind-up 0.6 s: crouch-flex pose, gold energy pulled in (stardust-style motes), camera FOV pulls in slightly.
- Impact:
  - bodybuilder double-bicep flex;
  - gold shockwave ring on the floor;
  - light rays;
  - small camera shake;
  - big "TITAN MODE" banner (Display font, gold, thick outline) + a deep "boom" and a choir hit.
- Others nearby see the shockwave and hear it softly: server-wide visibility = social proof.
- Server chat line: "<name> entered TITAN MODE!". Limit to once per player per 10 min so it doesn't spam.

2. LOOK WHILE ACTIVE (15 min):
- Muscles +10% scale on top of the current physique (visual only, reverts at the end), smooth tween.
- Glowing gold veins texture/decals on the arms + torso (one subtle pulsing material, not neon everywhere).
- Eyes glow red-gold.
- Light steam/heat wisps rising off the shoulders (few particles, off past ~60 studs, fewer on phones).
- Gold aura + "TITAN" tag (already in the prompt).
- Reps:
  - each rep pops a bigger gold number;
  - every 10th rep a small gold burst.
- Last 30 s: the glow flickers + a soft "power down" sound, then a shrink-back tween. No sudden pop.

3. SELLING IT HONESTLY:
- The TITAN SERUM shop card plays a looping 3 s preview of the transformation (a ViewportFrame with the player's own avatar flexing in TITAN MODE). This is the main sales tool.
- The post-Growth-Spurt / post-alter offer card uses the same preview.
- Exact numbers stay on the card (x2.5 EXP, infinite stamina, x2 coins, 15 min). No fake timers.

4. VFX: use our own textures (no stock Roblox), same budget rules as the rest of GYM ARC. Ask me for ChatGPT texture prompts if you need new ones (gold vein texture, steam wisp, gold shockwave).

TEST + REPORT:
- A 10 s clip of activation (PC + phone).
- The look while active (front + back).
- The shop card preview.
- The power-down.
- FPS with 5 players in TITAN MODE.
```
