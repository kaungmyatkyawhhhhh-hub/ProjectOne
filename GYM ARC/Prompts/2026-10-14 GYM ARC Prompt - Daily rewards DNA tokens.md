---
date: 2026-10-14
tags: [gymarc, prompt, feature]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: DNA tokens in the daily rewards (14 Oct)

```text
DAILY REWARDS: add DNA Tokens.
- Day 4 gives +1 DNA Token (keep the rest of day 4's reward if it has one, otherwise just the token).
- Day 7 gives +1 DNA Token on top of its current big reward.
- This is an allowed source of DNA tokens, along with growth spurts, 25k coins and the 99 Robux product. Update the comment/notes where the token sources are listed so it's not removed later.
- In the 7-day grid, show the DNA Token icon (Downloads\gym_arc_shop_icons\product_dna_token.png, uploaded to Myanmar Builders Club, find the ID with search_asset) with "+1" on days 4 and 7. On day 7, show it next to the main reward.
- Claiming shows the usual reward popup plus a "+1 DNA Token" toast, and the genetics button's token count updates right away.
- Server-side, saved, given once per claim. Rejoining or switching servers can't claim it twice.

Test: claim days 1-7 (fake the date in Studio): exactly +1 token on day 4 and +1 on day 7, and none on other days. Commit, update PROGRESS.md and Obsidian.
```
