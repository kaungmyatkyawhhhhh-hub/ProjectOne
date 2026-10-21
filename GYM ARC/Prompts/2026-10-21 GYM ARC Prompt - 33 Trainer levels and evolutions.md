---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 33 Trainer levels + evolutions (replaces Golden)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text

TRAINER PORTRAITS (owner, 21 Oct): Downloads\gym_arc_trainer_portraits\ has transparent PNGs for all 8: 01_coach_sam ... 08_atlas (512 square, waist-up) and *_full.png (full body). Upload them and use these as the tile/detail/reveal art (crop to the visible pixels and fit the art area).
Add trainer LEVELS (earned by training) and 4 EVOLUTIONS made by combining duplicates, with crazy animated slot backgrounds that feel exciting. This REPLACES the "5 duplicates -> Golden" system from prompts 24/27 (remove Golden; migrate: anyone who made a Golden gets that trainer as IRON-BORN). Do this after prompt 27. Follow CLAUDE.md Speed rules. All numbers in one config module. Original names only.
Files (made by the planner) in C:\Users\kaung\Downloads\gym_arc_agency_ui\:
  trainer_evolutions_v5.png + trainers_inventory_v5.png = THE mockups (latest, with hex backgrounds; v2-v4 are old)
  evo_bgs\evo_base.png, evo_ironborn.png, evo_beastmode.png, evo_colossus.png, evo_limitless.png = slot backgrounds (512x512; ignore the older evo1-4 files). Upload them (or tell me to bulk import and list the files).

1) LEVELS (trainers level up by training the player)
- Every EQUIPPED trainer gains trainer XP from the player's reps (scaled by weight tier). Unequipped trainers don't level.
- Lv 1 -> 20 at every stage. Each level adds +1% to that trainer's boost (Lv 20 = +20%).
- Pace: Lv 20 in about 20-30 min of active training at BASE, a bit slower at higher stages. Measure and tune.
- Level up: a "COACH LOU LV 12!" popup with a ding and a quick glow on the follower.

2) EVOLUTIONS: COMBINE 3 OF THE SAME
| Stage | Boost | Made from |
| BASE       | x1  | rolled |
| IRON-BORN   | x2  | 3x the same trainer at BASE |
| BEAST-MODE | x4  | 3x the same trainer at IRON-BORN |
| COLOSSUS   | x8  | 3x the same trainer at BEAST-MODE |
| LIMITLESS  | x16 | 3x the same trainer at COLOSSUS (max) |
- So one LIMITLESS needs 81 base copies. That's the long-term chase (great for Commons/Uncommons, a huge flex for rare ones).
- No level requirement to combine. The new trainer keeps the HIGHEST level of the 3 used.
- Each owned copy is its own entry (own level). Auto-delete (prompt 24) must never delete a copy that could be combined unless the player chose that rarity.
- EVOLVE button in the Trainers screen detail card (replaces GOLDEN): "EVOLVE 2/3" with the 3 slots shown, greyed until 3 copies at the same stage exist. Also an "EVOLVE ALL" button that combines every possible set at once.
- The total trainer boost still respects the gains cap (prompt 24 decisions); raise the cap for alter tiers as decided, and show the "MAX BOOST" tag if capped.

3) CURIOSITY: HIDDEN EVOLUTIONS
- A player only sees the names of stages they've reached at least once (any trainer). The next stage shows as "???" with a dark, glitching version of its background and "COMBINE 3 TO DISCOVER". Each first discovery: a big reveal with the name stamp and a server message "Rong discovered COLOSSUS!".

4) CRAZY SLOT BACKGROUNDS (dopamine, like the mockup)
- BASE: the rarity radial background with light rays (prompt 27 style).
- IRON-BORN: molten metal with glowing orange cracks; animate: sparks rising, the cracks pulse.
- BEAST-MODE: toxic green energy swirl + claw slashes; animate: the swirl rotates slowly, the slashes flash.
- COLOSSUS: dark blue storm; animate: lightning flickers every 1-2 s with a bright flash.
- LIMITLESS: rainbow galaxy spiral + stars; animate: the spiral rotates and the colors shift, stars twinkle.
- Animate with UIGradient rotation/offset, ImageLabel rotation, and a 2-3 frame flicker (cheap; animate only slots that are visible on screen, pause when the panel is closed).
- TILE IS FINAL (owner, 21 Oct): match trainers_inventory_v5.png / trainer_evolutions_v5.png / agency_final.png exactly. The character art is scaled to fill the tile (about 105% of the tile width or 70% of its height, whichever is smaller, head near the top). On BEAST-MODE and LIMITLESS the hex mesh is drawn again on top of the VFX (~35% opacity) so it reads through the effects.
- AGENCY TILES use the same tile in RARITY colors (Common grey, Uncommon green, Rare blue, Epic purple, Legendary gold, Mythic pink-red, Secret grey-purple, Eternal pale gold; hex + glow, no tier VFX): trainer name -> art -> rarity name -> chance ("50%", "1/167"). Not-yet-owned trainers show as a pure black silhouette with the rim light; Secret also hides its name ("???"). Owned ones get the gold check badge.
- ONE TRAINER TILE everywhere (Trainers inventory, Agency, Evolutions, roll results), match the v5 mockups:
  - BACKGROUND (owner, 21 Oct): a dark base in the tier hue (navy BASE, deep rust IRON-BORN, dark forest BEAST-MODE, deep storm blue COLOSSUS, deep purple LIMITLESS) with a thin-line hexagon grid (gym-mat hex mesh) across the whole tile at ~40% opacity in a lighter tint of that color, and a soft radial glow behind the character's head fading to the dark base at the edges. Use Downloads\gym_arc_agency_ui\evo_bgs\hex_base.png, hex_ironborn.png, hex_beastmode.png, hex_colossus.png, hex_limitless.png (512, ready-made). The pattern is visible but never brighter than the character. The tier VFX (fire, green energy, lightning, rainbow; evo_*.png + animation) is layered ON TOP of the hex pattern (only its bright parts, additive), not instead of it. BASE has no VFX.
  - OUTLINE: a 4 px solid border in the tier's bright color, 20 px rounded corners, a 2 px near-black inner ring just inside it, and a soft outer glow in the same tier color (~25 px blur, 55% opacity). The bottom strip sits flush inside the border with the same rounded corners (clip the tile content to the rounded rect).
  - All five tiles are identical except color and VFX.
  - The trainer art at 100% opacity, big (fills most of the tile), with a soft tier-colored rim light behind it. No text or effects over the face.
  - STACK (owner, 21 Oct, latest; top to bottom, all floating over the textured hex/VFX background, NO bottom strip/colored band): trainer name in white chunky text (no pill) -> the character -> the tier name in the tier color with a 3 px dark stroke and glow (BASE plain white) -> "LV 20" (everywhere, also the evolutions chart, which shows LV 1; no "EVO n · xN" text anywhere) in white chunky text, 3 px dark stroke + short drop edge, about the same size as the tier name. The tile border is the only frame.
  - Border: 4 px in the tier color. EQUIPPED (owner, latest): the border ALWAYS stays the tier color (border color means tier only). Equipped is shown by a thicker gold outer glow (gently pulsing) around the tile plus the GOLD circle check badge on the right side under the name. Every tile also has a 2 px near-black ring just inside the border. AGENCY tiles: a small dark chance badge ("5%", "1 in 167") top-left with a thin rarity-colored outline.
  - Tile text font: LuckiestGuy (or FredokaOne) with a 2-3 px dark UIStroke on EVERY word. No italic/clean sans inside tiles. Panel headers, buttons, pills and HUD keep the clean kit italic sans (premium frame, loud contents).
  - Equipped = small gold check badge on the right side, under the name.
- TRAINERS INVENTORY: a dense 4-column grid of these tiles, nearly touching, every slot on the page full (no empty "?" slots, no "+38 more slots"). Paging below: PREV / PAGE 1 / 4 / NEXT (12 tiles per page). Sort: highest tier first, then level. DETAIL PANEL (right side, see trainers_inventory_v5.png). Top: the trainer tile drawn large, SQUARE and exactly as wide as the EXP bar and stats panel below it (left and right edges aligned), with its glow centred evenly on all four sides. Below it, everything in Luckiest Guy with dark strokes, matching the tile borders/glows/corner radius:
  - Everything below the tile looks cut from the same sheet as the grid tiles: same outline weight (4 px + 2 px inner dark ring), same text stroke (3 px dark + short drop edge), same glow.
  - EXP BAR: 40 px tall, full width, 4 px outline (light blue) + thin inner dark ring, rounded ends, dark track with a visible hex mesh, bright blue gradient fill with a top highlight, blue outer glow. "7.2K / 10K EXP" ~22 px chunky stroked white, centred. "LV 18" and "LV 19" as small outlined dark pills at each end (not faded).
  - STATS: a sub-panel framed like a tile (4 px neutral dark-grey outline + inner ring, hex mesh at the same opacity as the tiles, slight glow). Three lines, left-aligned: a 36 px round icon badge with a dark outline (blue bolt EXP, gold coin COINS, green arrow PROGRESS) + ONE chunky stroked text ~28 px in the stat color: "+120% EXP", "+60% COINS", "+40% PROGRESS".
  - NEEDS LINE: "NEEDS 3x BEAST-MODE · 2/3" chunky stroked white ~20-22 px, with three 44 px square mini tiles on the right (tier background + trainer art, green tier border + inner ring), the missing one dimmed.
  - BUTTONS: ONE ROW, two equal-width buttons, 72 px tall, 14 px gap: left EQUIP (green gradient, 3 px dark outline, thick darker bottom edge, top highlight, green glow, "EQUIP" ~36 px stroked white; becomes red UNEQUIP when equipped); right the EVOLVE preview (next tier's hex + VFX texture, the next tier name ~30 px in dark letters with a bright tier-color stroke + glow, "LV 1" under it, same outline/bottom edge/highlight, glow in the next tier's color; grey "MAX EVO" when maxed). No small grey buttons.
- EVOLUTIONS CHART (where all 5 stages are shown): the same tile five times, escalating color only, tiles nearly touching, small glowing chevrons tinted the next tier color, captions FROM ROLLS / 3x BASE / ... under them, kit header on the dark backdrop.
- Higher stages = crazier: more particles, faster motion, stronger glow. The backgrounds animate as described above (cracks pulse + fire flicker, swirl rotates, lightning flashes + rain, galaxy rotates + ring hue-shifts).
- The follower in the world: +3% size per stage, the aura takes the stage color (LIMITLESS cycles rainbow), and a small stage tag above its head. Keep prompt 29 limits.
- Evolve moment: the 3 slots fly together, shake, white flash, the new slot slams in with its background and name stamp, a big satisfying sound (prompt 22 style), confetti in the stage color.

Test: combine up to LIMITLESS with test copies, EVOLVE ALL, the hidden "???" stage, the boost math vs the cap, the follower, and a phone screenshot of the Trainers screen. Short progress note in the vault.
```
