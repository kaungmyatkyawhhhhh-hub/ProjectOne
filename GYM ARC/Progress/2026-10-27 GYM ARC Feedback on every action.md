---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Feedback on every action (prompt 72)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 72 Feedback on every action]].

- **Reps:** the REP punch now plays on every rep (auto reps too). Heavy (tier 7+) and BIG reps shake the bar for 0.35 s after lockout (tested: ~3.6 degrees at tier 12). Clanks and plate knocks were already there. [[GYM ARC - Machine HUD]]
- **Coins:** every gain flies to the counter and the number counts up as they land (`Kit.CoinFly`, `TopBarClient`). A reward (25+ coins off a machine, or well above the usual rep coins) = a burst of 5-10 coins from the screen's middle; rep coins = one coin from your character, at most every 0.5 s (tested on the bench: 486 coins in 8 s, never more than one coin in the air). Claim buttons keep their own burst (the counter waits for it). Spending just counts down.
- **Level ups and PRs:** LVL UP already only every 10 LVLs / 60 s and the machine level flash once per 30 s; the PR banner is now once per 20 s at most.
- **Buttons:** `ButtonFeedbackClient` gives every GuiButton not made by `Theme.Button` the same press (shrink while held, bounce back) and click; full-screen tap catchers, the top bar and buttons with another UIScale are left alone. `Audio` plays one click per tap even if two scripts ask. 8 buttons left unbound in play (top bar / NoPress).
