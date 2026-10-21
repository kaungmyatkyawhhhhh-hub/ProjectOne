---
date: 2026-10-22
tags: [gymarc, prompt]
status: todo
---
# 42 Daily Streak redesign

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Redesign the Daily Streak tab (Quests > STREAK). Match the mockup: C:\Users\kaung\Downloads\gym_arc_ui_style_match\real\quests_streak.png (current look: C:\Users\kaung\Downloads\gym_arc_ui_current\quests_streak.png). Follow CLAUDE.md Speed rules. Mobile first. Use the prompt 37 components (ChunkyButton, pills, hex tile style) if they exist.

1) LAYOUT
- The 7 day tiles fill the FULL panel width with the same left/right margins as the "DAILY STREAK DAY X" title. Scale sizing: UIListLayout, horizontally centred, equal Scale widths with a small Scale gap. Desktop ~200 px per tile, smaller on phones; always centred, always full width.
- Day 7 is the big one: ~1.25x the width and ~25% taller than the others (centred on the same row).
- Under the row: ONE line of description, centred, half the old size, grey: "Days 4 and 7 give a DNA token. Miss a day and it starts over."
- Under that: the green chunky "CLAIM DAY X" button (unchanged size). After claiming it turns into the dark "COME BACK TOMORROW" button.
- Under the button: "STREAK RECORD: X DAYS" (small, grey-white stroked). Save the player's best streak.
- The panel shrinks to fit: it ends 40 px under the STREAK RECORD line. No empty space.

2) DAY TILES
- All tiles: dark hex background, dark outline + thin muted inner line.
- Coins: muted gold coin icon, reward number in gold stroked chunky text.
- Normal days (1, 2, 3, 5, 6): coin and number ~15% smaller than now.
- NO blue or red boost icons. Bonus rewards (day 2 Coconut Water, day 5 Creatine) are a small gold line icon on a dark circle with a gold outline, plus a gold "+1".
- Days 4 and 7 only: gold outline with a gold glow, a LARGE DNA token icon (transparent, no dark square behind it), and a gold "+1" pill. Day 7 has the larger token, a bigger "300" and a stronger glow.
- TODAY: the current day's tile gets a thin white ring, is lifted 6 px, and has a small white "TODAY" tag fully ABOVE it with 6 px clearance (add space above the row so it never touches the title).
- Claimed days: dimmed + a green check in the corner.
- Days not reached yet: coin AND bonus icons dimmed the same amount (they must match).

3) DON'T CHANGE
- The rewards, amounts and streak logic stay the same. Only the look and layout change.

TEST: screenshots at 1920x1080 and 667x375, on day 1 (nothing claimed) and on day 4 (days 1-3 claimed). Short progress note in the vault.
```
