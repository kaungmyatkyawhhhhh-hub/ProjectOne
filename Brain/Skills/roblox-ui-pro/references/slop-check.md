# Slop check: does this UI look hand-made?

Run this on real screenshots (phone first), not on the code. A kid decides in about a second whether a game "looks cheap". The owner's rule: if the game looks like an AI slop game, it gets disliked.

"Slop" is not a style. Thick outlines, chunky buttons and juicy effects are *correct* in a kid simulator. Slop is **defaults, inconsistency, noise and emptiness**.

## Cheap tells (each one costs; fix the biggest first)

**Defaults nobody chose**
- Default `LegacyArial`/`SourceSans` text, default grey `(163,162,165)` frames, `BorderSizePixel` borders, Roblox's stock blue buttons.
- Emoji or plain-text symbols where an icon belongs (★, ✓, 🔒, "X" drawn in a font is OK only as a stopgap).
- Placeholder copy: "Item Name", "Description here", "Button", lorem ipsum, "Coming soon" on half the tabs.

**Inconsistency**
- More than 2 fonts, more than 3 corner radii, more than 2 stroke weights, a dozen text sizes (the audit counts these).
- The same thing styled two ways: two different coin icons, two greens for "buy", rarity colours that differ between shop and index.
- Buttons with the same importance looking different, or different importance looking the same; two primary buttons side by side.
- Icons from different families (one glossy 3D, one flat line icon).

**Noise**
- Effects stacked everywhere: glow + gradient + stroke + shadow + transparency + sheen on every surface.
- Everything moving all the time; a sheen on every tile instead of the one thing to buy.
- Several popups at once; a notification on top of a reward on top of an offer.
- Banned in MEGA BITE: spiky sunbursts. Generally overused: rainbow gradients, purple-blue glassmorphism, neon outlines on everything.

**Emptiness and imbalance**
- Huge plate with a little content in one corner; empty grid area with no "more coming" or scroll cue.
- Giant title, tiny body; a header taller than the content.
- An empty state that's just a blank box.

**Flatness**
- Flat buttons and plates: a single colour, no darker base, no gradient, no inner highlight. They look like placeholders next to any popular simulator.
- Display text with no outline and no depth floating on a plate.
- Price buttons that aren't the buy colour (green) or have no currency icon. Kids hunt for the green button with the coin on it.
- In a shop, every item the same size, with no hero item first and biggest.

**Broken polish**
- Text cut off, wrapping mid-word, or sitting on the plate's edge.
- Icons stretched (no `UIAspectRatioConstraint`), blurry (art too small), or blank (image failed to load).
- Misaligned baselines in a row; uneven gaps between identical items.
- Hover/press that does nothing, or a press that moves the layout.

## Wow moments (what hand-made UI has)

- Real art from the game's world in the UI: the game's creatures/items as icons, a frame that matches the world's theme.
- One clear focal point per screen (the deal, the reward, the next goal) with a little motion on it.
- Juice where it matters: a satisfying press, a counter that ticks up, a burst on a rare item, a sound on every tap.
- States that feel designed: owned/equipped/locked look good, the empty inventory says what to do and has art.
- The HUD stays small and calm during play, so the world is the star.

## The final test

Ask, looking at the phone screenshot:
1. What do I see first? Is that the thing that matters?
2. Can I tap everything with a thumb without hitting the jump button?
3. Could this exact screen be pasted into ten other games unchanged? If yes, it needs the game's art and language.
4. Did decoration replace layout anywhere?
5. Is anything here for me (the developer), not the player? Remove it.

Then hand it to the `quality-nerd-kid-sim` skill for the tells-per-10-minutes score, and to `overstimulated-kid-sim` if several things can pop at once.
