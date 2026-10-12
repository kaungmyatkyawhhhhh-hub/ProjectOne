# Break A Bed: Limited Auras

#break-a-bed #monetization #auras

Back to [[Break A Bed/Project Overview|Project Overview]].

**Status (2026-10-12): the Halloween crate is built and tested** (see [[Break A Bed/2026-10-12|2026-10-12]]). Still needed: the 3 product ids in `GameConfig.AuraCrate.Products`.

Owner's request (2026-10-12): **limited-time auras** that boost **Strength and Walk Speed**, sold like the "Featured" egg in the simulator the owner likes. Auras come from an **Aura Crate** with a timer, chances shown on screen, and 1 / 3 / 10 buy buttons.

![[preview-aura-crate-halloween.png]]

## 🎃 First crate = HALLOWEEN AURAS (changed 2026-10-12, owner's request)
The first limited crate is **Halloween** instead of Galaxy. It's on sale until **Nov 1** (end of Halloween), then it's gone. Galaxy can be a later crate.

![[preview-aura-crate-halloween.png]]

| Aura | Chance | Strength | Walk Speed | Look on the player |
|---|---|---|---|---|
| Ghost | 40% | x1.2 | +2 | little white ghosts floating around you |
| Bats | 30% | x1.5 | +4 | a swarm of bats circling with an orange glow |
| Web | 18% | x2 | +6 | a glowing spider web ring at your feet and a small spider on your back |
| Pumpkin | 9% | x3 | +8 | a glowing jack-o'-lantern head flame and orange fire trail |
| Cursed | 2.9% | x5 | +12 | green ghost-fire rising with a floating skull |
| **Reaper** | **0.1%** | **x10** | **+20** | a dark hooded aura with red eyes, a floating scythe and a red/purple glow; server announcement |

- Pictures (this folder): `aura-ghost.png`, `aura-bats.png`, `aura-web.png`, `aura-pumpkin.png`, `aura-cursed.png`, `aura-reaper.png`. Background: `bg-halloween.png` (night sky, big moon, bats, graveyard).
- **Card look:** an orange gradient border, the title "HALLOWEEN AURAS" in a yellow → orange gradient, "Limited Time! Ends Nov 1", a countdown to Nov 1, a big glowing pumpkin as the hero, the Reaper in the rainbow-bordered slot, and the **10-pack button is orange** instead of red.
- **During Halloween the shop title bar is orange** instead of green.
- Prices, pity, dust and the products are unchanged (AURA CRATE x1 R$49, x3 R$129, x10 R$399). Pity: guaranteed **Cursed** every 50 crates.
- The tables and pictures below describe the Galaxy crate, kept for later.

## Fix (owner 2026-10-12): Halloween card too big, and no animation
- **Shorter:** the Featured card was taking the whole shop tab. Make it about **45% of the shop window's height** (about 300 px tall at a 1000 px wide window), full width, so the next section (Starter Pack) is already visible under it.
  - Compact layout: title row ("HALLOWEEN AURAS", "Ends Nov 1", countdown) at the top; the **pumpkin hero smaller** (about 60% of the card height) on the left; the 6 aura slots in one row (the Reaper slot only a little bigger); the buy row at the bottom. No empty space.
- **No animation on this card:** no rotating bursts, no bobbing, no cycling rainbow border, no pulsing. Everything is still (the countdown still ticks). The rainbow border on the Reaper slot stays as a still gradient.
- It must also **never scale up/down** when the shop opens or scrolls (the 4th screenshot showed it shrinking).

## Fix (owner 2026-10-12): auras block the view, ground effects only show when jumping, low quality
**Rules for every aura (and the level/VIP auras in [[Break A Bed/Effects/Effects|Effects]]):**
1. **Never block your own view.**
   - Effects stay **around the body and below the head**, never in front of the face or above the head where the camera looks through.
   - **Your own aura is lighter on your screen:** on the local player's client, multiply particle Rate by 0.4 and add +0.3 Transparency to your own aura. Others see it fully.
   - Max particle size 1.5 studs near the body; no big glow balls on the torso.
   - Add a Settings toggle **"Show my aura"** (default ON) and keep "Other players' effects".
2. **Ground effects sit on the ground, always visible.**
   - Don't parent ground rings to the leg or the HumanoidRootPart center. Put them on an Attachment at **`RootPart.CFrame * (0, -(HipHeight + RootPart.Size.Y/2) + 0.1, 0)`**, flat (rotated 90°), and update it every frame with a **downward raycast** so it sits on the floor even while walking.
   - Use `Orientation = VelocityPerpendicular` or a flat `Decal`/`ImageLabel` on a SurfaceGui for rings, `LightEmission` 0.6, slightly transparent, `ZOffset` -1. They must show while standing still, not only when jumping.
3. **Quality:** fewer, cleaner particles look better than many messy ones.
   - Each aura = **1 ground ring + 1 body effect + 1 small detail**, max about 25 particles alive at once.
   - Smooth curves: Size and Transparency use NumberSequences that fade in and out (never pop), and colors use 2–3 keypoints.
   - Use the aura's own picture style: ghosts are small, cute and translucent (Transparency 0.3) and orbit at waist height; bats are small and circle around the shoulders, not the face; the web is a flat glowing ring on the ground; pumpkin is a soft orange flame trail behind the feet plus a small pumpkin floating at the hip; cursed is green flames rising from the ground ring; the Reaper is a dark mist ring on the ground, a small scythe floating behind the back and a faint red glow.
   - A `Trail` (thin, fading) from the feet looks clean and doesn't block anything.
   - Optional upgrade: a good **aura pack from the Creator Store** (made by known VFX creators) recolored to our themes usually looks much better than code-made particles.
4. Test in first person and third person, while standing, walking and jumping, on PC and on a phone, with the camera zoomed in close.

## Target quality: like Sol's RNG auras (owner 2026-10-12)
The owner wants auras at the level of **Sol's RNG** (made in its style, never copying its assets). What makes those look high quality:
- **Layers, not particle spam:** each aura is 4–6 clean layers built around the body, every layer with one job:
  1. **Ground piece:** a flat glowing ring or rune decal on the floor (rules above), slowly turning.
  2. **Body outline:** a `Highlight` on the character (FillTransparency 0.9, OutlineTransparency 0.2, the aura color) so the player glows softly without anything covering them.
  3. **Orbiting pieces:** small **mesh parts** (crystals, bats, ghost shapes, flames, skulls) orbiting at waist/shoulder height on a ring of Attachments, smooth tweened rotation, Neon or glass material, a little `PointLight`.
  4. **Beams:** curved `Beam`s (CurveSize0/1) from the feet spiraling up the body, a flowing texture (`TextureSpeed` 1–2), fading at the ends. These give the "energy flowing" look.
  5. **Trails:** thin fading `Trail`s from the hands or feet, which only show when moving.
  6. **One detail:** wings, a halo, a scythe or a crown, attached behind or above the body (never in front of the face).
- **Flipbook textures:** use ParticleEmitter `FlipbookLayout` (Grid4x4/8x8) for flames, smoke and electricity, so they animate like real fire instead of static blobs.
- **Color discipline:** each aura uses **2 main colors + white highlights** only, with smooth ColorSequence gradients.
- **Rarity = more layers:** Ghost (common) has 2 layers; Bats 3; Web 3; Pumpkin 4; Cursed 5; Reaper 6 plus a camera-safe pulse when equipped.
- **Equip moment:** a short reveal on equip/roll (a flash ring on the ground + a quick spiral beam), like Sol's roll reveal. Rare ones get a full-screen tint for 0.5 s and a sound.
- **Performance:** parts are `CanCollide`/`CanQuery`/`CanTouch` false and Massless; the effects for other players are only built within 60 studs; Low Graphics removes beams and halves the particles.
- **Honest note:** Sol's RNG auras are made by professional VFX artists with custom textures and meshes. Claude Code can get close by building the layers above. To truly match them, buy or commission a few good VFX packs (Creator Store VFX by known creators, or a VFX artist on a dev Discord/Talent Hub) and recolor them into our themes.

## Starter code: `AuraLayers.luau` (this folder)
A ready ModuleScript that builds each aura from the 6 layers (ground ring kept on the floor by a raycast, Highlight glow, orbiting pieces at waist height, spiral beams, feet trails, one detail behind/above the body), lighter for your own character, nothing in front of the face. Claude Code: put it in ReplicatedStorage, fill `Textures` with the fx image ids, call `Apply`/`Remove` from the client for every character, and polish (swap the simple orbit parts for real mesh pieces where possible, add flipbook flames, the full equip reveal, the "Show my aura" setting and the 60-stud distance limit).

## The Galaxy Aura Crate (later crate)
It's on sale for **7 days**. After that it's gone and a new themed crate replaces it (Lava, Ice, Candy…). Auras you already own stay forever.

| Aura | Chance | Strength boost | Walk Speed boost | Look (see [[Break A Bed/Effects/Effects|Effects]]) |
|---|---|---|---|---|
| Spark | 40% | x1.2 | +2 | white sparkles |
| Frost | 30% | x1.5 | +4 | cyan glow + a ring at the feet |
| Blaze | 18% | x2 | +6 | orange flames rising |
| Angel | 9% | x3 | +8 | white-gold wings + halo |
| Galaxy | 2.9% | x5 | +12 | purple/blue swirl + stars |
| **Infinity** | **0.1%** | **x10** | **+20** | rainbow swirl, wings, glow; a server announcement when someone gets it |

- **One aura equipped at a time.** Its boost multiplies with passes and boosts (x15 pass × Galaxy x5 = x75).
- Pictures (redrawn 2026-10-12 with glow): `aura-spark.png`, `aura-frost.png`, `aura-blaze.png`, `aura-angel.png`, `aura-galaxy.png`, `aura-infinity.png` (this folder).
- **Pity:** every 50 crates without Galaxy or better gives a guaranteed Galaxy (it shows "Galaxy in 37 crates"). This is fair and makes people buy more.
- Duplicates turn into **Aura Dust**. 10 dust = upgrade an aura to ★ (+10% of its boost), up to ★★★.

## Prices (developer products, create them under Myanmar Builders Club)
Product pictures (Halloween): `Product Icons/aura-crate-x1.png`, `aura-crate-x3.png`, `aura-crate-x10.png`.

![[Product Icons/_aura-crates.png]]

| Product | Price |
|---|---|
| AURA CRATE x1 | R$49 |
| AURA CRATE x3 | R$129 |
| AURA CRATE x10 | R$399 (red button, best value) |

**Created 2026-10-12 (ids for `GameConfig`):** AURA CRATE x1 = `3718171240`, AURA CRATE x3 = `3718171318`, AURA CRATE x10 = `3718171374`.

The purple gift button next to each one buys it for another player in the server.

**Free ways to get crates** (so free players care too): 1 crate on day 7 of the daily reward, a 0.5% chance from the spin wheel, and the MEGA Free Gift.

## How the Featured card must look (match `preview-aura-crate.png` closely)
- **Painted background**, not a flat color: `bg-galaxy.png` (deep purple space, nebula clouds, stars, a faint galaxy on the right). Each new crate gets its own scene.
- **Gold-orange gradient border** (6 px) around the card.
- **Hero aura** big on the left (about 40% of the card height), sticking out past the left edge, with a soft colored light burst behind it. It turns slowly.
- **Title** "GALAXY AURAS": yellow → orange gradient text with a thick dark stroke and shadow. "Limited Time!" in white under it, the countdown in white on the right, and a red "New!" tag.
- **Slots get bigger with rarity**, bottom-aligned in a row. Each has a dark border, a rarity-colored radial background (grey, blue, orange, gold, purple, pink) and a light burst behind the aura (`burst-<rarity>.png`). The chance % is big **italic** text bottom-right (white for common to epic, gold for legendary and up).
- **The rarest slot** is the biggest, has an **animated rainbow border** and an italic gold "INFINITY" label on top.
- **Buy row:** purple gift button + green price button for 1 and 3. The **10-pack is red** with a rainbow strip, and the old price is crossed out above it ("490").
- **Glow:** the card uses a light bloom (Roblox `Bloom` + `LightEmission` on the burst images), **not** big white blobs. Keep the aura shapes readable.
- Animate: bursts rotate slowly (one turn every 20 s), the rainbow border cycles, auras bob 3 px, and the stars twinkle.

## Where it shows up
- **Shop:** the **-- FEATURED --** section at the top, with a big card showing a "New!" tag, the crate name, "Limited Time!", a live countdown, the best aura big on the left, all auras with chances (the rarest in a rainbow-bordered slot), and the 3 buy buttons.
- **Opening animation:** the crate shakes, flashes and bursts with `fx-ring`, the slots roll past, and the aura reveal pops in with rays and its effect. Rare ones (Galaxy+) get a bigger flash, a sound and a server announcement.
- **Aura inventory:** a new **Auras** button (square, purple) on the right side of the main screen. It shows a grid of owned auras with their boosts and stars, plus an EQUIP button.
- The equipped aura shows on the player (others can see it) and replaces the level aura while equipped.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Put the crate (name, end time, auras, chances, boosts) in `GameConfig` so a new crate is easy to add each week.
2. The server rolls the auras (never the client), saves owned auras, dust, stars, pity and the equipped aura.
3. Use the usual purchase safety for the 3 products. Gifting uses `MarketplaceService:PromptProductPurchase` for the buyer, then gives the item to the chosen player on the server.
4. Build the Featured card like `preview-aura-crate.png` (FINAL STYLE in the [[Break A Bed/UI Kit/UI Kit|UI Kit]]), the opening animation and the inventory.
5. Build each aura's look with the particle images in [[Break A Bed/Effects/Effects|Effects]].
