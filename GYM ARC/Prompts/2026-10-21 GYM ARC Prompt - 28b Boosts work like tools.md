---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 28b Boosts work like tools (owner's answers to prompt 28)

Back to [[00 GYM ARC Home|GYM ARC Home]] - follows [[2026-10-21 GYM ARC Prompt - 28 UI cleanup]] - done: [[2026-10-21 GYM ARC UI cleanup]]

```text
1. Change to decision 1: boosts work like tools.
- Tap the boost slot = the item goes into the character's hand (shake bottle visible). Tap the slot again = put it away.
- While holding it, tap/click (normal Tool activate) = play a drinking animation (~1 s). The item is used and the effect applies at the END of the animation.
- During the animation: a 1 s cooldown, so further taps do nothing. Show it as a radial sweep on the slot.
- If the player puts it away or gets interrupted mid-drink, nothing is used.
- Check the cooldown on the server too, so it can't be spammed with exploits.
- Make it the same for every drinkable boost (shake, coconut water, pre-workout, etc.).
- Mobile: make sure tapping to drink doesn't fight with the camera, and the slot is easy to hit.

2. No: if the player unequips an item, it stays unequipped (save it), also after rejoining. Only auto-fill an EMPTY slot the first time a player gets a new item type.

3. Odds only in the window. In prompt 27, "odds board" means the odds grid inside the Agency window. No odds text on the board in the world.
```
