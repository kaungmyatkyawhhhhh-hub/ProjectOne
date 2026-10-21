---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 37 UI style match (A chunky / B premium)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Make the UI consistent. Follow CLAUDE.md Speed rules. Mobile first (fits 667x375). Never undo the owner's manual Studio changes. Reuse the existing components, don't rebuild screens.

Two styles:
- A = chunky "reward" style, the same as the trainer tiles and the trainer card: hex-mesh fill, 4 px outline + 2 px dark inner ring + soft glow, LuckiestGuy text with dark stroke, chunky buttons with a white top highlight and a thick darker bottom edge (like EQUIP / UNEQUIP / EVOLVE).
- B = Black + Gold premium kit (panels, tabs, coin counter, HUD). Stays as it is.
Rule: things you OWN, EARN or PRESS to get a reward are A. Frames, panels, tabs are B.
Make the A pieces reusable Kit components (Tile, ChunkyButton, RankBadge, ChunkyBar, StrokedNumber) and use them everywhere below.

DO FIRST (spend screens):
1) STORE
- Every pass becomes an A tile: hex mesh in its own color, 4 px outline, big 3D icon, name in stroked chunky text, price as a chunky pill.
- The Auto Rep hero card stays large, with a gold A frame.
- Keep the B panel, tabs and coin counter.
2) AGENCY ROLL
- ROLL = chunky red stroked button with a glow (same build as EQUIP). X3 and AUTO = outlined grey chunky buttons (same as UNEQUIP style but grey).

THEN:
3) PHYSIQUE
- The S/A/B/C chips become small outlined rank badges with a glow (S gold, A purple, B blue, C grey).
- Muscle bars get the trainer card EXP-bar look (outline, top highlight, glow).
- The "71% AESTHETIC" number becomes a big chunky stroked number.
- Panel, tabs and the body render stay B.
4) QUESTS
- CLAIM = the green chunky button. The reward = stroked gold "+1,500".
- The "ALL 3 BONUS" card becomes an A reward tile.
- Quest rows and the panel stay B.
5) HUD
- TAP TO GROW = chunky gold A button with a glow and a slow pulse (the main reward button in the game).
- Left nav icons: a small colored glow behind any icon that has a notification.
- Everything else stays.
6) GAMEPLAY
- REP x9 stays the big red B button.
- The floating "+4.4K CHEST EXP" text becomes stroked chunky text (readable over brick and any background).
7) TITLE / LOADING
- Stay B. Only PLAY becomes the big chunky A button.

Test on a phone size. Screenshots: Store and Agency (after 1-2), then one combined screenshot of the rest. Short progress note in the vault.
```
