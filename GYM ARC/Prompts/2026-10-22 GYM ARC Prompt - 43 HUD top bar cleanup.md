---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 43 HUD top bar cleanup

Back to [[00 GYM ARC Home|GYM ARC Home]]

(Pasted with the request to do prompt 42; saved here, not run yet: waiting for the owner's go.)

```text
HUD top bar cleanup:
1. The Roblox top bar holds ONLY the coins: a TopbarPlus-style icon next to the Roblox buttons (coin glyph + number, e.g. "184,250"), styled to match Roblox's top bar (dark rounded pill). Count-up tween when coins change. Nothing else custom in the top bar.
2. Remove the height, LVL, Daily, Quests and settings pills from the top bar.
3. Height + LVL: one small chunky dark pill directly UNDER the left nav (same width as the nav column): "LVL 27 · 6'4"" in white stroked text, thin gold outline. Tap = opens Stats.
4. Quests: tapping the right-side "Today's Quest" card opens the Quests menu (Daily tab). Daily streak: when today's reward can be claimed, a small "DAILY REWARD" card appears in the same right-side card stack (gold outline, "!" chip), tap = opens the Streak tab; it disappears after claiming.
5. Settings: a small gear button at the bottom of the left nav (same tile style, smaller), opens Settings.
6. Check on phone (667x375) that nothing overlaps the Roblox top bar buttons, the chat button or the safe area.
```
