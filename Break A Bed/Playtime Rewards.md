# Break A Bed: Playtime Rewards

#break-a-bed #rewards

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): a **Free Gifts** menu like popular simulators. It has 12 gifts that unlock the longer you play in one session, and leaving the game resets them. It uses our [[Break A Bed/UI Kit/UI Kit|UI Kit]] style. It **replaces** the old "playtime gift every 5 minutes".

![[UI Kit/preview-gifts.png]]

## The 12 gifts
Times count from when the player joins this session.

| # | Unlocks at | Gift | Card color |
|---|---|---|---|
| 1 | 1 min | Small Cash (5 breaks of your best bed) | slate |
| 2 | 3 min | +1 Spin | green |
| 3 | 5 min | x2 Strength, 5 min | purple |
| 4 | 7 min | Strength Pack (30 s of your best post) | cyan |
| 5 | 10 min | Medium Cash (20 breaks) | yellow |
| 6 | 15 min | +3 Spins | slate |
| 7 | 20 min | +1 Level | green |
| 8 | 25 min | x2 Cash, 10 min | cyan |
| 9 | 30 min | Big Cash (60 breaks) | pink |
| 10 | 45 min | Big Strength (3 min of your best post) | purple |
| 11 | 60 min | +5 Spins | cyan |
| 12 | 90 min | **MEGA Gift**: x3 Strength 15 min + Big Cash + 3 Spins | orange |

Cash and Strength grow with progress, so the gifts are useful at any point.

## How it works
- **Card states:**
  - **Waiting:** a dark green bar counts down (mm:ss, or h:mm:ss over an hour).
  - **Ready:** the bar turns bright green and says **CLAIM!**, and the card pulses and sparkles.
  - **Claimed:** the card is dimmed with a green check, and the bar says **CLAIMED**.
- Red text at the bottom says **"Leaving resets gifts!"** Gifts reset when the player leaves, because the timer is per session. That's what keeps players in the game longer.
- **SKIP ALL (R$49, developer product):** unlocks every gift right away for this session.
- **HUD button:** the green gift button on the right shows the time until the next gift. A red number badge shows how many gifts are ready to claim. It wiggles when one is ready.
- The server keeps the timer and checks the claims, so they can't be cheated. Claimed gifts are kept until the player leaves.
- The first time a gift becomes ready, a small toast says "Free gift ready!".

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Replace the old 5-minute playtime gift with this (keep the daily reward and spin wheel).
2. Put the gift list in `GameConfig` so the times and rewards are easy to change.
3. Add the SKIP ALL product to `GameConfig` (id 0 = "Coming soon"), with the usual purchase safety.
4. Build the menu with the [[Break A Bed/UI Kit/UI Kit|UI Kit]] images, the exact style values, and its animations and sounds.

## VFX upgrade (owner 2026-10-12: "make this screen better with VFX")

![[UI Kit/images/preview-gifts-vfx.png]]

Keep the layout, colors and sizes exactly as they are now. Only add these effects. All of them are UI effects (`UIGradient`, `UIStroke`, `ImageLabel`s with the [[Break A Bed/Effects/Effects|Effects]] pictures `fx-glow`, `fx-ring`, `fx-star4`), made on the client. No light rays behind the window.

**1. READY card (the one to claim). This is the main focus.**
- **Gold glow border:** a `UIStroke` (Color `#FFE14A`, Thickness 3) plus an `fx-glow` image behind the card, a little bigger than the card, gold, Transparency 0.4, pulsing 0.4 ↔ 0.7 every 1 s.
- **Icon halo:** a soft gold `fx-ring` behind the icon (Transparency 0.5), slowly turning (one turn every 6 s). The icon itself stays sharp, with nothing on top of it.
- **Sparkles:** 4–6 small white `fx-star4` twinkles around the icon. Each one grows 0 → 1 → 0 over 0.8 s at a random spot, one after another.
- **Shine sweep:** a white diagonal stripe (an `ImageLabel` with a `UIGradient` mask, Transparency 0.6) slides across the card every 2.5 s. The CLAIM! bar gets the same shine, half a second later.
- **CLAIM! bar:** bright green with a light green outer glow, slowly breathing (scale 1 ↔ 1.04 over 1 s).

**2. Next gift (the one counting down soonest):**
- Its timer bar **fills up** with a lighter green as time passes (a fill frame with Size X = time passed / total wait), so players see it's almost ready.
- A faint white ring behind its icon (Transparency 0.75), still.

**3. All cards:**
- A soft glow ring behind each icon in a lighter version of the card's color (Transparency 0.75), still. It makes the icons pop off the stud pattern.
- 1–2 tiny twinkles on the bigger rewards (Big Cash, x2 Strength, x2 Cash, +5 Spins), one every few seconds.
- **Hover (PC):** the card scales to 1.05, the stroke turns white, and a quick shine sweep plays. Bubble pop sound (the same one as the other buttons).

**4. MEGA Gift card:** an orange glow border (like the READY gold one, but orange `#FF9A1E` and always on), a warm glow ring behind the gift, 4–5 slow cream sparkles and a slow shine every 4 s, so it looks like the big prize even while locked.

**5. Header and buttons:**
- A pink glow behind the gift icon in the title bar, with 2 twinkles.
- **SKIP ALL:** a soft green outer glow and a shine sweep every 3 s (it's the paid button, so it should catch the eye).
- **Free Gift!:** a soft cyan outer glow, still.

**6. Background:** 10–14 tiny cream sparkles drifting slowly up in the gaps between cards (ZIndex under the cards, Transparency 0.3–0.6). Very subtle.

**7. Claiming a gift (the payoff):**
1. The card squashes (0.92) then pops (1.12 → 1) with Back Out.
2. A white flash over the card (Transparency 0 → 1 in 0.25 s) and an `fx-ring` shockwave growing from the icon (0.4 s).
3. 12–16 `fx-star4` sparkles burst out in the card's color plus white.
4. The reward icon flies to its counter (Cash to the Cash counter, Strength to the Strength counter, spins to the Spin button) along a curve, leaving a short trail of small sparkles. The counter pops when it arrives.
5. Then the card dims with the green check and the bar says CLAIMED.
6. The "Claim" sound plus a coin sound when the icon arrives.

**8. A gift becomes ready while the window is open:** its timer bar flashes white, turns into CLAIM! with a pop (0 → 1.15 → 1), and a small ring burst plays. Play a "ding".

**Rules:**
- No effect covers the icons or the text. Glows go **behind**, sparkles go **around**.
- At most ~40 effect images alive at once. Stop all the loops when the window closes.
- Low Graphics: keep the borders, bar fill and claim burst; turn off the shine sweeps, the twinkles and the background sparkles.

**For Claude Code:** add these effects to the existing Free Gifts window. Don't change its layout, sizes, colors or the gift list.
