---
date: 2026-11-06
tags: [galaxy, ui, art, prompts, chatgpt]
---
# Galaxy Incremental - ChatGPT UI art for the 9 weak UIs (6 Nov)

Owner: "lets do art". Source: Claude Code's list of UIs that don't look good (Phase 2 / 3.1 report).

Style is the same as our windows (galaxy_windows_overview.png) and the phase 2 icons:
- dark screens, a coloured glowing header per window, bold italic white text with a black outline (the text is added in game, never baked in);
- icons are chunky glossy Roblox-simulator icons with a thick dark outline, gold / violet / cyan.

| # | UI | Fix | Art |
|---|---|---|---|
| 1 | Forge reveal card | a card frame per rarity | U1 card frames |
| 2 | TOP SUPERNOVAS wall + PLAYERS NEAR YOU | board plaque, row plates, top-3 medals | U2 leaderboard set |
| 3 | Ignition sign checkboxes | done / not done icons | U3 icons |
| 4 | UPGRADES on phone | layout only | - |
| 5 | DAILY not-ready buttons | progress "3/5" + a small locked/clock icon | U3 icons |
| 6 | TREE info empty | LUMI pointing (we have it) + "Tap a node" | - |
| 7 | STATS window | one icon per stat row | U3 icons |
| 8 | BLACK HOLE keep / lose | keep shield + reset swirl icons | U3 icons |
| 9 | Locked island boards | locked sign plaque with a padlock | U2 + U3 |

Backgrounds:
- frames and boards use flat magenta (#FF00FF), because they have dark insides that a black-background cut would eat;
- icons use black, the same as the phase 2 icons (that worked).
Claude cuts everything, 9-slices the frames and writes the Claude Code prompt.

## U1 - Forge reveal card frames
```text
Create ONE image, 1536x1024, a flat solid MAGENTA background (#FF00FF, no gradient, no shadow on it). A 4x2 grid of 8 separate vertical game CARD FRAMES, each centred in its own cell with magenta space between them, no overlap, no text, no numbers, no letters anywhere. Each card is a portrait 2:3 frame for a Roblox simulator reveal card: a thick ornate glossy frame with a small empty banner slot at the bottom, and an EMPTY very dark navy-violet starry inner window (the item is placed on top in game). Stylised glossy mobile-game UI (like Pet Simulator / Sol's RNG cards), thick dark outline, clean shapes, NOT a photo, no magenta anywhere in the art.
Card 1 COMMON: grey stone-silver frame. Card 2 UNCOMMON: green emerald frame. Card 3 RARE: blue sapphire frame. Card 4 EPIC: purple amethyst frame with small crystal spikes. Card 5 LEGENDARY: gold frame with sun rays at the top. Card 6 MYTHIC: crimson-pink frame with small flames. Card 7 CELESTIAL: white-gold frame with rainbow-cyan glow and a small star crown. Card 8: the BACK of a card, violet with a gold star-forge anvil emblem in the middle.
```

## U2 - leaderboard set + locked sign
```text
Create ONE image, 1536x1024, a flat solid MAGENTA background (#FF00FF, no gradient). Separate Roblox game UI pieces, each with magenta space around it, no overlap, no text, no numbers, no letters anywhere. Stylised glossy mobile-game UI, thick dark outline, NOT a photo, no magenta in the art.
TOP: one wide empty LEADERBOARD PLAQUE, landscape 2:1, dark navy-violet screen inside a thick brass-gold frame with a small glowing star crest on top centre and a blank title banner across the top edge.
MIDDLE ROW: three ROW PLATES (long thin horizontal bars, 8:1): a GOLD one, a SILVER one, a BRONZE one, each with an empty round slot on the left end.
BOTTOM ROW, left to right: a gold 1st-place MEDAL with a star (blank centre, no number), a silver 2nd-place medal (blank), a bronze 3rd-place medal (blank), and a LOCKED SIGN: a dark violet plaque crossed by two iron chains with a big shiny gold padlock in the middle.
```

## U3 - icon sheet (16 icons)
```text
Create ONE square image, 2048x2048, pure black background (#000000), an exact 4x4 grid of 16 separate game ICONS, each centred in its own cell with wide empty black space, no overlap, no text, no numbers, no letters. Chunky glossy Roblox simulator icon style, thick dark outline, bright gold / violet / cyan colours, small sparkles, same style for all 16, NOT a photo.
Row 1: 1. a big green glowing CHECKMARK in a round gold badge (done)  2. an EMPTY round gold badge with a dark inside (not done)  3. a small gold PADLOCK (locked)  4. a gold STOPWATCH (wait / cooldown)
Row 2: 5. a cyan SHIELD with a star (keep)  6. a red-orange circular RESET ARROWS swirl (lose / reset)  7. a glowing violet-black DARK MATTER orb with a ring  8. a purple glowing ESSENCE crystal
Row 3: 9. a bright SUPERNOVA star burst  10. a COMET with a cyan tail  11. a glowing blue STAR SHARD crystal  12. a glowing STAR CORE gem in a small gold setting
Row 4: 13. a gold TROPHY with a star  14. a CLOCK with a small moon (playtime)  15. a PLANET with a ring (bodies)  16. a gold STAR ANVIL (forge rolls)
```
