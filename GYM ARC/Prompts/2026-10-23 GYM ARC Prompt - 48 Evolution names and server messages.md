---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 48 Evolution names and server messages

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Two owner changes. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Don't break saves.

1) EVOLUTION NAMES ARE NO LONGER HIDDEN
Remove the "???" undiscovered feature for trainer evolutions everywhere (it came from prompt 33).
- The EVOLVE button shows the real next stage: "EVOLVE > IRON-BORN", "EVOLVE > BEAST-MODE", etc., with the stage name in its tier colour (3 px dark stroke). At the last stage (LIMITLESS): "MAX STAGE" and the button is disabled.
- Next-stage previews (detail card, needs line, evolutions chart) show the real name and the normal background, not the dark glitching one. Remove the "COMBINE 3 TO DISCOVER" text.
- Remove the "first discovery" reveal. Keep the normal evolve animation (slots fly together, flash, name stamp, confetti).
- Remove the "seen stages" code, but leave old save fields alone.
- Trainers themselves still stay hidden until owned (black silhouette; Secret and Eternal "???"). This part is ONLY about evolution stages.

2) SERVER-WIDE MESSAGES: ONLY THE RAREST TRAINER ROLLS
- KEEP: when a player rolls the SECRET trainer (check the config, I think it's The Shadow) or the ETERNAL trainer (Atlas), everyone on the server sees it once, e.g. "Rong rolled ATLAS! (Eternal)" in that rarity's colour. Make it feel special: a short gold banner at the top for ~4 s, plus the chat line and a small sound.
- REMOVE every other server-wide message: other trainer rarities, evolutions / "X discovered COLOSSUS!", alters, growth spurts, titles, show winners, purchases, anything else. List what you removed in the note.
- Messages a player sees about themselves (their own popups, toasts, rewards) stay.
- Remove the old sending code and its config entries.

TEST (phone first):
- A trainer at BASE shows "EVOLVE > IRON-BORN"; one at LIMITLESS shows "MAX STAGE".
- With 2 test players: roll a Common and an Epic (the other player sees nothing), evolve a trainer (nothing), then force a Secret and an Eternal roll in Studio (the other player sees the banner + chat line).
Screenshots of each. Short progress note in the vault.
```
