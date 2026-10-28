---
date: 2026-10-29
tags: [gymarc, prompt, economy]
status: todo (14 Nov, with 91)
---
# 103 Fixed coin values (no more "minutes of coins")

Back to [[00 GYM ARC Home|GYM ARC Home]] · Table: [[2026-10-29 GYM ARC Prices - every coin and Robux item]] (section "FIXED coin values")

```text
GYM ARC: every coin price and reward becomes ONE FIXED NUMBER that never changes with the player's stage (owner: scaling numbers confuse players). Follow CLAUDE.md and the Playbook rules. Only the GYM ARC Studio. Read Config/Economy (Economy.Minutes, Rewards), Config/PumpShop, Config/Trainers (roll price), Config/Monetization (coin packs), Config/Genetics/DNA (weekly price rise) first. Never undo my manual Studio changes. Nobody loses coins or items.

1) Replace every "minutes of coins at your stage" price and reward with the fixed numbers in the table (trainer roll 150, snacks 150/500/1,500, Coach Dex boosts, gear 750/4,000/25,000/70,000/200,000, DNA token 25,000 flat with the weekly rise removed, login 100-1,500, daily quests 300/1,000, shows by division, showdown, arm wrestling, legends 500, spotting 50 (RE-RACK STAYS AS IT IS: the owner's 27 Oct formula 5 + 1 per LVL up to LVL 400 is already a fixed number per level, don't change it), spurt milestones, group gift 1,000). Coin packs are done in prompt 95 (2,000 / 9,000 / 25,000).
1b) ALSO FIXED: code rewards that use `minutes` (Config/Codes) and Playtime Gifts (Config/Playtime) become fixed coin numbers too (pick numbers that match today's value at Spurt 3 and show me).
2) EARNING still grows: rep coins by weight tier, gym bonuses, (prompt 96) +5% per alter, +10% per star. Offline coins show as one number.
3) Show me a before/after table at Spurt 0, Spurt 3, 6'0" and Alter 8 (how many minutes each price takes) so we can spot anything too cheap/expensive, then wait for my OK before publishing.
4) Remove Economy.Minutes-based scaling code paths only after nothing uses them; keep the old helper if something still needs it.
TEST: tests/pacing coins, a fresh save and an alter save buy/earn each item once, numbers match the table everywhere (shop, Coach Dex, Agency, popups, notes). Progress note + Economy note.
```
