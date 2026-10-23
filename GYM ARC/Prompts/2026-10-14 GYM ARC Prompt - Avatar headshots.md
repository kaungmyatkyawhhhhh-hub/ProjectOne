---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Prompt - Avatar headshots

Saved exactly as sent:

```text
MAIN MENU PLAYER CARD: replace the placeholder person icon with the player's REAL Roblox avatar headshot.
- Use Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150).
- Show it as a simple circle (UICorner 1,0), 34px, with a plain dark background behind it (#1D191B) and a thin 1px border (white at 88% transparency). No gold ring, no gradient, no glow, no generic person icon.
- While it loads, show just the plain dark circle (no icon). If it fails, keep the plain dark circle with the first letter of the player's name in light gray.
- Use the same headshot style anywhere else a player picture appears (leaderboards, posing vote, spotting popup, crew).
```
