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
