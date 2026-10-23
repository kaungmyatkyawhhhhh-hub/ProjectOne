---
date: 2026-10-22
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Daily streak redesign (prompt 42)

Prompt: [[2026-10-22 GYM ARC Prompt - 42 Daily streak redesign]]. Code commit 38a03ae (DailyClient only; rewards and streak logic unchanged).

## Done
- 7 day tiles across the full width (equal Scale widths, small Scale gap, centred); day 7 1.25x wider and 25% taller.
- Tiles: dark hex, dark outline + thin muted inner line; muted gold coin, gold stroked reward (normal days ~15% smaller).
- Day 2 / day 5 bonus items: gold line icon on a dark gold-edged circle + gold "+1" (no blue / red tiles).
- Days 4 and 7: gold edge + glow (day 7 stronger), a big DNA token with no dark square (cut-out uploaded: Downloads\gym_arc_ui_dna\dna_token_cutout.png, rbxassetid://88290636191617), gold "+1" pill, bigger "300" on day 7.
- Today: thin white ring, lifted 6 px, white TODAY tag above with room so it never touches the title.
- Claimed: dimmed + green check. Days ahead: coin and bonus icon dimmed the same.
- One grey line: "Days 4 and 7 give a DNA token. Miss a day and it starts over."; green CLAIM DAY X, then the dark COME BACK TOMORROW; "STREAK RECORD: X DAYS" (the best streak was already saved as `daily.best`).
- The window shrinks to fit the Streak tab (ends 40 px under the record line) and grows back for Daily / Goals.

## Tested (temporary saves)
- 667x375 day 1 and day 4 (TestLoginDay = 4: days 1-3 claimed, record 3 days), 1920x1080 day 1, claiming day 1 (COME BACK TOMORROW, record 1 day), Daily tab back to full size.
- Note: the window is the kit's fixed 620-wide panel scaled to the screen, so tiles are ~150 px on a 1920 screen, not 200.

![[GYM ARC/Screenshots/streak42/day1_phone_667.jpg]]
![[GYM ARC/Screenshots/streak42/day4_phone_667.jpg]]
![[GYM ARC/Screenshots/streak42/day1_pc_1920.jpg]]
![[GYM ARC/Screenshots/streak42/claimed_come_back_tomorrow.jpg]]
