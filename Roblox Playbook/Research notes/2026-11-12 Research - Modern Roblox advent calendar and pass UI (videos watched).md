---
tags: [research, ui, vfx, advent-calendar, christmas, gymarc, reference-study]
created: 2026-11-12
---
# Research: modern Roblox advent calendar and pass UI (videos watched)
Date watched: 12 Nov 2026 · Method: frames pulled from YouTube in the built-in browser. Sound was NOT measured in this pass.
Purpose: GYM ARC Christmas update, Advent calendar screen ([[2026-11-12 GYM ARC - Christmas update decision (Advent calendar, 5 Dec)]]). Method: [[Brain/Methods/Reference study]]. Related: [[2026-11-12 Watch study - 3D pet card and egg hatch screen (owner recording 11 Nov)]] (how the card/hatch is built), sound: [[2026-11-12 Research - Tap Simulator REBORN secret reveal sound breakdown (measured)]].

## Tap Simulator REBORN (the quality bar the owner picked)
Videos: AlphaGG "ULTIMATE GUIDE to Tap Simulator REBORN" https://www.youtube.com/watch?v=WOM-wOfxDiE · RussoPlays "I GOT THE RAREST SECRET PET IN WORLD 2" https://www.youtube.com/watch?v=AKcz1uOBYg0

**Static look**
- Panels: chunky rounded rectangles with a thick dark outline and a drop shadow, filled with saturated two-colour gradients (pink to purple, yellow to orange, blue to cyan) and a faint pattern of stars or sparkles inside.
- Font: a very heavy rounded display font, white fill, thick black stroke and a small drop shadow. Section titles ("Shop", "Pets") sit half outside the panel edge.
- Buttons: green "Apply"/price and red "Unequip/Delete" pills with a black outline and a darker bottom edge that reads as 3D.
- Item art: 3D-rendered icons (gift boxes, coin piles, a token vault) that overflow their tile, so they pop out of the card.
- Hero card: the selected pet card is tilted, with a rainbow holographic gradient, a glowing outline and a corner ribbon ("RAINBOW"). Small rarity pills ("Secret II", "Limited") and a MAX progress bar.
- Badges: "MOST POPULAR" tag, a "+2,700 / +300 bonus" callout, progress chips at the top ("Open 2,500 eggs!").
- HUD: floating gain popups ("+3.58SX") and big stroked currency numbers.

**Reveal motion (egg hatch, about 2.5 s, something new every ~0.3 s)**
1. Eggs fill the screen. Crack lines glow in rarity colours (orange, purple, green).
2. White flash.
3. An explosion of neon shards and speed streaks (green, magenta, yellow) behind the items.
4. Pets pop out with a scale bounce. The names float above them in their rarity colour.
5. Sparkle stars and a soft smoke puff, then the pets fly to the player.

## Rivals Christmas Season 2 (polished but flat)
Video: https://www.youtube.com/watch?v=6KoXMgZzMpU
- The pass is a two-row horizontal track: a free row (white) and a premium row (gold), with 3D-rendered rewards and level numbers underneath.
- Urgency line: "Season 2 ends in 6m 18s".
- Purchases stack as toast notifications at the top.

## Fisch Fischmas 2025 Advent Calendar (what NOT to do)
Video: https://www.youtube.com/watch?v=KQfOpSJT55w
- A plain 6x5 grid on a dark see-through panel with small icons and green "CLAIMED" text. Day 31 is a wide tile at the bottom. There's no motion worth copying. It looks dated next to Tap REBORN.

## Other 2025 Roblox advent calendars (from articles)
- Opened from an object in the world (a Christmas tree or an elf NPC): Fisch, Steal a Brainrot, Grow a Garden.
- Each day is tied to a task or hunt: Dress to Impress, Grow a Garden.
- Missed days can be restored with Robux: Grow a Garden, Fisch.
- Hidden rewards plus streak bonuses: Steal a Brainrot.

## Applied to GYM ARC (decision)
- Build the calendar in the Tap REBORN style: chunky outlined gradient panels, heavy stroked font, 3D rendered presents that pop out of their tiles, holographic big-day tiles.
- The claim follows the reveal recipe above: the present shakes with rarity light leaking from its seams, a white flash, a ribbon/snow/shard burst with streaks (NO sunburst ring), the reward pops with a bounce, the name slams in, coins fly to the HUD.
- Every step gets its own layered sound (still to be measured from the videos and synthesized).
