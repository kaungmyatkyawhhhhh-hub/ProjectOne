---
date: 2026-11-09
tags: [megabite, art, style, ui, vfx, sound, chatgpt-style-block]
status: decided by Claude (owner 9 Nov: "what is the game style gonna be like")
---
# MEGA BITE: art style guide (9 Nov)

Built on: [[K06 Art, UI, VFX, sound and lighting]] (incl. "never looks like AI slop"), [[2026-11-09 MEGA BITE - Debate kids simulation]] (cartoon look fixed "too scary / not cute"; PvP kids still want it cool), [[2026-11-09 MEGA BITE - Map plan + kid simulations]] (ambient life, zone identity), [[2026-11-09 MEGA BITE - Notes - PvP fairness and Roblox rules]] (Mild rating: no blood, no wounds), the genre games kids play now (Be Fish, SharkBite 2, Fish It!: bright, stylised, simple shapes).

## The style in one line
**Bright, chunky "toy" cartoon: cute when you're small, epic when you're big.** Smooth stylised 3D with bold shapes and saturated colour, like a premium toy line, never realistic and never flat-cheap.

## 1. The sharks: cute → epic (one ladder for both the little sister and the PvP sweat)
> **Correction 9 Nov (owner: the round toy Reef Shark was "REALLY really bad"):** sharks keep a REAL, sleek shark silhouette (see [[2026-11-09 MEGA BITE - Shark art research (models, animation, assets)]]). The cartoon goes into the face (small beady eyes + brow), the wide toothy grin, the colours and the size. Only Minnow and Piranha (fish, not sharks) may be rounder and cuter. The table's shapes below are read this way.
| Evolution | Shape | Face | Colour |
|---|---|---|---|
| Minnow | round, tiny tail, big head | huge round eyes, small smile | sunny yellow |
| Piranha | round + big underbite | cheeky grin, 4 chunky teeth | orange-red |
| Barracuda | long and fast, pointy | narrow cool eyes | silver-blue stripes |
| Reef Shark | classic shark, rounder | friendly-tough | grey-blue + white belly |
| Hammerhead | the hammer is wide and readable | eyes on the hammer ends | olive-teal |
| Great White | big, heavy, wide jaw | confident, slightly narrowed eyes | slate + bright white belly |
| Megalodon | huge, chunky armour-like ridges | glowing eyes, giant (cartoon) teeth | deep navy + glowing cyan/ember accents |
- Each evolution has a **different silhouette** you can tell apart from far away (the quality-nerd rule: no look-alike models).
- Proportions: real species proportions (research note §2). Small fish may have big heads/eyes; every SHARK is sleek with small beady eyes and a toothy grin.
- **No blood, no wounds, no scars.** Eating = a cartoon gulp: the fish pops into bubbles + a funny "gulp" sound.
- Show-off without scars: size, the crown, a glowing outline for mutations, fossil marks after Fossilize, skin colours.

## 2. The world
- **Safe Reef:** turquoise water, sun rays, pink/orange coral, sand, friendly fish schools. The happiest place in the game.
- **Open Sea:** deeper blue, light shafts, kelp forests, the big set pieces (shipwreck, sunken statue, whale skeleton, coral arch).
- **Red Trench:** dark blue-violet with glowing red/ember vents; scary only here (and it's opt-in).
- Always bright enough to see (Ambient high, WaterTransparency ~0.2): mood goes into colour, not darkness.
- Everything moves a little: kelp sways, bubbles rise, schools scatter. One kit of ~14 meshes, dense around set pieces.

## 3. UI
- One UI kit: chunky rounded panels, **deep navy plate + a thick dark ink outline + a coloured edge + a shine line** (the house style), ocean accents (turquoise, coral, gold for rewards).
- Font pair: one bold rounded display font for numbers and titles, one clean font for small text; numbers huge (SIZE, EXP).
- Colour = meaning: green eat/buy, white same size, red danger, gold rewards, grey locked.
- Our own icons (ChatGPT pipeline), never default Roblox icons.

## 4. Effects and sound
- Bubbles everywhere, water splashes for BREACH, a ring of light on every evolve, each ability with its own colour (DART white, FRENZY orange, TORPEDO blue, SHARK SENSE green, HAMMER RAM yellow, BREACH white-foam, TIDAL ROAR cyan).
- Music upbeat and bright (115-140 BPM) in the reef and Open Sea; a drum loop in the Red Trench; a big sting on evolves.
- Sounds: chunky bites, a funny gulp, a "ding" for every bank.

## 5. Thumbnails and icon
- Rendered from OUR shark models in Blender (owner's pipeline): one big hero, a bright clean face, strong contrast, one glowing focal point.
- Icon idea: the Megalodon's open cartoon jaw about to swallow a tiny smiling Minnow (cute + epic in one image).
- Never Hungry Shark's look (no realistic sharks on a photo-real sea).

## STYLE BLOCK (paste into every ChatGPT art prompt for MEGA BITE)
```text
STYLE: MEGA BITE, a Roblox shark game. Bright, chunky stylised 3D "premium toy" cartoon, smooth shading with soft rim light, bold readable silhouettes, saturated ocean colours (turquoise, coral pink, sunny yellow, deep navy, gold accents). Real sleek shark silhouettes (cone snout, crescent tail, swept fins), small beady eyes with a brow, a wide grin with big triangle teeth. Cute only for the small fish, cool and epic for the sharks. NO realism, NO blood, NO wounds or scars, NO text, NO watermark, NO photo backgrounds, not slimy, not glossy-plastic AI look, clean edges.
```

## 6. Rules from Galaxy's mistakes (owner 9 Nov: "UI, colors that dont match, game physics, and lighting")
Full lesson: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (UI families, physics, lighting 9 Nov).

### UI: one kit, designed first
- **Step 1 of the build, before any feature:** one full HUD mockup on a phone frame (SIZE + EXP counters, CARRYING bag, NEXT bar, DART + ability buttons, quest panel, a toast, the minimap/compass, the Store button). The owner approves it; every later piece comes from it.
- **Palette tokens (`UIKit.Colors`), used by the UI AND the world:**
| Token | Colour | Used for |
|---|---|---|
| Navy (plate) | #12233F | every panel / counter plate |
| Ink (outline) | #0A1424 | every outline, 3 px at phone size |
| Turquoise | #2EC4D6 | info, the Safe Reef accent, DART |
| Kelp green | #3DDC84 | eat / buy / bank |
| Sunny gold | #FFC93C | rewards, claim, the crown, shiny fish |
| Coral | #FF6F61 | events (bait ball, Feeding Frenzy), FRENZY |
| Danger red | #FF4D5E | predators, Red Trench, warnings |
| Locked grey | #8A97A8 | locked items, disabled |
| Foam white | #F5FAFF | text, highlights |
- **3 component families only:** COUNTER (navy plate + icon + big number: SIZE, EXP, CARRYING), BUTTON (chunky plate with lip, ink outline, big icon, heavy text + a state line, coloured by meaning: like Galaxy's REWARDS/BOOSTS, the owner's favourite), TILE (rounded square icon tile with a label or number: abilities, quests, index). No 4th shape, no floating text, no screen arrows (guide currents and world markers instead).
- UIAudit on 3 phone sizes before every publish.

### Physics: swimming is the game
- A **custom swim controller** designed and tuned before content: auto-forward on phones, a thumbstick, speed by evolution (small = fast and twitchy, big = faster top speed but wider turns), a DART burst, smooth acceleration, a little momentum and glide, bounce off rocks (never stuck, never through them), a soft push-back current at the borders.
- Server checks on speed and position; streaming-safe respawns at vents (RequestStreamAroundAsync + PauseOutsideLoadedArea).
- A **feel pass on a phone in the first build** (it's in the Launch gate now).

### Lighting: bright water, mood in colour
- A preset per zone in `MapConfig.Lighting` (key light from above like sun through water, turquoise fill, Ambient ≥ ~110, Bloom threshold high so only vents, abilities and shiny fish glow).
- Nothing bright behind the HUD (the sun glare stays out of the top of the screen).
- The sea floor has mid-tones: sand ripples, coral colour, caustic light patterns. Never a flat white or flat blue slab.
- Checked on a phone at minimum and maximum graphics with the HUD on.
