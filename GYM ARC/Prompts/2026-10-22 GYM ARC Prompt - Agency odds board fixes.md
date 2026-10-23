---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# Trainer Agency odds board fixes

Back to [[00 GYM ARC Home|GYM ARC Home]] - done: [[2026-10-22 GYM ARC GO TO teleport, quiet tutorial, odds, grunts]] - follows [[2026-10-21 GYM ARC Prompt - 27 Trainer Agency UI redesign]]

```text
Trainer Agency odds board fixes:
1. Both SECRET and ETERNAL are hidden until the player owns them. The Secret trainer (The Shadow) AND the Eternal trainer (Atlas) show as "???" with a black silhouette + rim light in their rarity colour. Right now Atlas shows his name; hide it. Once a player owns one, show its real name and art for that player.
2. Show every chance as a percentage, never "1/1000". Use the real odds:
   Common 50% · Uncommon 30% · Rare 12% · Epic 5% · Legendary 2% · Mythic 0.6% · Secret 0.15% · Eternal 0.035%
   Format: whole numbers without decimals (50%), small ones with up to 3 decimals and no trailing zeros (0.6%, 0.15%, 0.035%).
Apply the same to every place the odds or these trainers appear (Agency board, roll preview, Trainers tab locked tiles).
```
