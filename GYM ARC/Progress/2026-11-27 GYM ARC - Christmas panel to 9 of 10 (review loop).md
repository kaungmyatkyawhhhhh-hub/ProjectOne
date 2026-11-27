# GYM ARC: Christmas panel (Rewards + Calendar) taken to 9+/10

27 Nov 2026. Owner: "it look so bad. i thought u took tips from the popular games", "and everything else too, look in details", "keep looping like asking gemini and chatgpt until they say its perfect, above 9/10 rating".

## Scores (strict, vs Pet Sim 99 / Bee Swarm)

| Round | ChatGPT Rewards | ChatGPT Calendar | Gemini Rewards | Gemini Calendar |
|---|---|---|---|---|
| 1 | 6.5 | 5.5 | - | - |
| 2 | 8.4 | 7.8 | 7.5 | 7.2 |
| 3 | 8.8 | 8.6 | 8.2 | 7.9 |
| 4 | **9.0** | **9.2** | 8.6 | 8.8 |
| 5 | - | - | **9.0** | **9.1** |

ChatGPT, round 4, said to stop changing the design: more decoration would make it worse. The next things that matter are mobile use, how opening a gift feels, sounds and purchase feedback. Screenshots: [[Screenshots/xmas_panel/round3.jpg]], [[Screenshots/xmas_panel/round4.jpg]], [[Screenshots/xmas_panel/round5.jpg]].

## What changed (AdventClient, Config/Advent)

### Shop cards
- Each shop card shows a ChatGPT-polished cut-out icon. Ids are in Config/Advent.Shop.image; the art is in `Assets/xmas_art/*_cut.png`.
- Each item stands on a dark stage in its own colour (`bg`) with a soft glow behind it.
- Rarity chip in the corner. Legendary gets a star, a glow, a wider card, a ~14% shimmer and snow motes.

### Top of the window
- The pill at the top right shows "N CANDY CANES" on Rewards. On Calendar it shows "N READY!" or "NEXT IN 14h 22m".
- "ENDS IN N DAYS" between the tabs and the pill, from Advent.EndsAt.

### Calendar tiles
- Presents by rarity: `PRESENT_ART` Epic 77756202102001, Legendary 99986850900433, day 24 93487622925972.
- Epic and Legendary tiles get a faint fill in their colour.
- Ready tiles get a gold fill and a gold "OPEN!" pill.
- Day 24 always has a gold frame, a gold fill and a "FINAL GIFT" label.
- Claimed days are dimmed with a green check.
- Day numbers are 21 px.
- Footer: "x/24 OPENED · N PRESENTS TO OPEN!".

### Fixes
- An old bug: the "Sheen" name clash with Theme.Pulse errored every frame and blanked the footer.

## Kept on purpose
- The kit's gold price button. Both reviewers asked for an "UNLOCK" word; there is no room, and the kids' rule is a big icon plus a big word.
- The house italic font.
- No stat or boost tags: the skins are cosmetic, so a tag would be false.

## Not done
- Gemini's optional extras: a brighter "WEARING" text, and spacing for "ENDS IN" on narrow screens.
- The panel has a fixed width, so it was only checked at PC size.
- **Not checked on a phone.**
- **The place is not saved.** Save needs the owner's OK.
- The game-wide "VFX everywhere" pass from the owner's recording is still open.

Lessons are in the `roblox-ui-pro` skill (synced to Brain/Skills).
