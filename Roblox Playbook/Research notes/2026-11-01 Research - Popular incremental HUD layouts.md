---
date: 2026-11-01
tags: [research, ui, hud, incremental, supernova]
---
# Popular incremental HUD layouts (what the top games actually put on screen)

Owner (1 Nov night): "we need to make our ui like the popular games". From my live play notes ([[2026-11-01 Celestial Incremental - 10 incrementals played]]) + [[Playbook notes - UI deep dive]] (common simulator patterns; no published teardown exists, so this is from playing them).

## Game by game
| Game | Top | Left | Bottom | Right | Upgrades live... |
|---|---|---|---|---|---|
| Noob Incremental (4.4K) | the goal as the title "0/5T Oofs" (centre) | small prism counter + timer | 4 icon buttons (Shop, Tree, Inventory, Quests), red badge | leaderboards in the world | world boards (Buy / Max) + Tree screen |
| Immortality (2.2K, 98%) | Qi + "/sec"; tutorial line with portrait + SKIP | 6-button menu | big AUTOCLICK button | ACTIVE BOOSTS box (weather timer) | world boards + realm board |
| Tower (1.2K) | "Floor 0" + Auto Run toggle | - | 6 square icon buttons; counter bottom-left | - | wall boards |
| Resource | - | icon menu; diamonds with "+" | "0% Cash" boost chip | - | plaza boards |
| Grass Incr. Simulator | level / XP bar + one hint line | counters + shop basket with "!" | friend boost chip (bottom-left); one product button | - | world board |
| Faith | one quest line | currency + shop basket | XP bar; boost chips bottom-left | "2x Event" pill only during events | church wall boards |
| Circle Grinding | "Upgrade your Circle 0/50" + "Steps 0/723" | money, diamonds, Index, Settings, Shop | - | - | wall boards |

## The 7 shared rules
1. **Top centre = the ONE goal** (Noob's title is the prestige goal; Circle's "0/723"). Nothing else stacked there.
2. **Currencies small, top-left / left, with a "+"** that opens the shop.
3. **Small square icon buttons** in ONE row (bottom) or ONE column (left), icon + 1 word, red badge when something's new. 4-6 buttons.
4. **Upgrades live in the world** (boards next to the action) or in one full screen (the Tree). The HUD itself stays tiny.
5. **One guide line** (hint / quest) + an arrow or beam in the world; never a big box.
6. **Boosts = small chips** (bottom-left or one box top-right); event pills appear only while the event runs.
7. **The world fills the screen**: the HUD covers maybe 15% of it.
Look: chunky outlined icon buttons, one display font with dark outlines, saturated gradient fills, red dots, a strong own identity (Tower's pixel font + torches).

## Supernova Incremental, following them
| Zone | What |
|---|---|
| Top centre | the goal only: "SUPERNOVA · 64%" thin bar (title-style like Noob) |
| Top-left (below Roblox's buttons) | Stardust pill with "+0.8/s" and a "+" to the shop; Shards / Dark Matter pills appear when unlocked |
| Bottom centre | ONE row of square icon buttons: SYSTEM (buy bodies, the main action, big), TREE, FORGE (once unlocked), QUESTS, SHOP, MORE; red dots (updated 1 Nov night with the full design) |
| Bottom-left | boost chip "x1.1" (tap = list) |
| Top-right (below the player list) | event pill only while an event runs |
| Above the button row | one hint line in the tutorial / when stuck |
| World | your star system + an UPGRADE board on the island (like Noob's boards) for the quick buys; the Tree is the full screen |
| Pop moment | SUPERNOVA button replaces the hint line when ready, glowing gold |

## "Don't make it look AI" (owner, 1 Nov night: "in the popular games they dont look ai")
From [[Roblox Playbook - Game craft deep dive]] ("the slop look comes from default frames and fonts, mismatched assets and no juice; a style guide + UI kit + reference board prevent it") and [[Playbook notes - Top games art study (Oct 2026)]] (premium = made by a person with one clear style).
### Signs our current HUD reads as AI-made (owner's screenshot)
- every element the same rounded navy pill with a glossy gradient; one display font on everything, even sentences
- generic glow on everything (UI and world), candy green / blue / yellow tiles with no reason
- explanatory sentences on the HUD ("(whole server)", "Keep collecting!")
- icons generated in one pass (the 24 PNG icon set) with no theme of their own
- big centred badges; symmetric stacks; nothing that says "space observatory"
### What the popular games do instead
- a theme MOTIF in the UI itself (Tower: pixel font + torch light; Faith: stained-glass boards; Noob: chunky hex tree): the UI looks like it belongs to that world
- restraint: small HUD, one accent colour, glow only on the thing to press now
- short words / numbers only; sentences live in windows
- hand-made icons in one consistent style; currency icon used everywhere
### Plan
1. Reference board: real HUD screenshots of 8 top games (Noob, Immortality, Tower, Matrix, Resource, Faith, GIS, Pet Sim 99) to copy density and proportions, not art.
2. Our motif: an astronomer's star chart - dark ink-blue panels, thin gold chart-line borders with small corner stars, brass buttons; numbers in the display font, words in the body font.
3. Icons: owner (1 Nov night): "i dont want to hire an artist. ur the artist". Claude draws them by hand as vectors (SVG paths / Figma vectors placed point by point from the style guide, like a designer), NEVER an image-generation model (standing no-AI-art rule). Rules: one grid (64 px, 4 px stroke in the dark ink colour), 3 flat colour steps + one highlight per icon (no airbrushed gradients, no glow), chunky simple silhouettes readable at 32 px, every icon from the same shape language (round ends, star-chart corner star), one at a time, checked at phone size next to the reference board.
4. Mock up the HUD + one window first (Figma or Studio), compare side by side with the board, only then build the rest.
