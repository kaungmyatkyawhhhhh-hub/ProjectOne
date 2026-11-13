---
date: 2026-11-14
tags: [mega-bite, ui, change-log]
---
# MEGA BITE: depth on every title (Develuper UI lesson)

This applies the lesson from [[2026-11-14 Watch study - Develuper tutorials (UI, lighting, VFX, animation) + Dodge or Die story]]: every element needs **identity and depth**.

## What was already there (no change needed)
The v6 kit already did most of the video's recipe:
- `Btn3D`: a tall darker lip, a glossy top, a **thin light rim just inside the outline** (the "edge highlight"), and a **drop-shadow copy under the words**.
- `SquareBtn` (HUD buttons) and `Slab` (windows): inner light rims.

## What changed
`ReplicatedStorage.MegaBite.UIKit` → `K.TitleText` now gives every title **depth text**. A darker copy of the words sits a few pixels under the white-to-ice title, the same depth our 3D buttons have. Before, titles had only the outline and gradient.
- **Depth size:** about text size × 0.08 (22 → 2 px, 40 → 3, 50 → 4, the 84 px MEGA BITE logo → 7). `props.Depth = 0` turns it off for a title.
- **Colour:** the title's ice blue mixed 62% toward the kit's navy.
- **How it works:** a child always draws over its parent, so the label itself is the darker copy and a child `Face` draws the real title. Callers didn't change. `Text`, `TextSize`, `TextTransparency`, `Font` and so on, set on the label, are forwarded to the face, and `TextFits` still works (HeroCard's shrink-to-fit loop).
- **Where it shows:** the Shop title, its section heads, the featured banner title and skin names; the Fish Index, Settings, World Map and Fossilize window titles; the reveal name; the x2 EXP offer; the HeroCard title and the MEGA BITE logo.
- **Backup:** `ServerStorage.UIKit_preTitleDepth_14Nov`.

## Checked (14 Nov, Play on a simulated iPhone 17 Pro)
- All 19 titles were built with depth, with 0 problems: the face was present, in sync with the label, and the text fit.
- Changing a title's text, size or transparency updates the face one frame later (the game uses deferred signals).
- No script errors. Screenshots of the Shop and Fish Index show the depth on every title.
- **Not checked:** the open animations through the real buttons (I turned the windows on directly because clicks don't land on the simulated phone). Not tested on a real device.
- **The place is not saved or published.** The owner saves.

## Still open (from the roblox-ui-pro audit, 14 Nov)
- The `MB_Crew` chip is 30 px tall, too small to tap (the minimum is 44).
- The RightCol labels (CLOWNFISH / FOSSILIZE / PVP) are 13.6 px; the minimum is 14.
- On phones, the Trench (PVP) button sits where the jump button is, and Settings sits in the thumbstick area.
- The HUD uses 12 different corner sizes.
