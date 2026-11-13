# 2026-11-13 MEGA BITE - Hunters, lighthouse lamp, kill feed, biome sounds, tier rooms (start)

Owner 10:24: "start kill feed with portraits, tier rooms in the Shop/Index, landmark uses (lighthouse lamp), biome sounds, hunters for big sharks."
Research used: [[2026-11-13 Video watch - HSE all sharks + Astaroth (NextGen Gaming)]] ("For MEGA BITE", items 1, 3, 4, 6; mechanics and layout only).
Nothing is published. Studio only. Tested in Studio Play with one player on PC unless it says otherwise.

## 1. Hunters for big sharks (built, tested once)
- From the Great White up, red hunters come ONLY for you in the Open Sea: first after 75 s as a big shark there, then about every 3.5 min.
  Great White: 1 Red Hunter (the Great White model x1.5, red). Megalodon: 2 Red Titans (the Megalodon model x1.5, red).
- They hunt only their mark (never smaller sharks), follow it anywhere in the Open Sea, leave after 55 s or when the mark reaches the reef.
- You can beat one in about 10 bites: EXP on every bite, about 2,500 (Red Hunter) / 7,200 (Red Titan) in all before boosts.
- Damage 300 / 450 a hit (never more than 45% of your HP). The first test used 420 / 620: a Great White that stood still was
  chomped in about 10 s (other predators helped), so it was lowered. The lower numbers are NOT re-tested.
- Where: `GameConfig.Predators.Hunt`, types `RedHunter` / `RedTitan`; `MB_PredatorServer` (pool + "THE HUNT" loop);
  `MB_PredatorClient` (tpl + toast); templates `MegaBite.Creatures.RedHunter / RedTitan` (red SurfaceAppearance).
  Backups `*_preHunters_13Nov`. Test hook: `ServerStorage.MB_PredDev:Invoke("hunt")`.
- Not done: a model of their own (the research's kid-friendly idea was a harpoon submarine; that needs a design sheet first).

## 2. Kelp Lighthouse lamp (built, tested)
- Swim inside the tower (door or the broken hole): the lamp lights for 60 s, you get EXP (3% of your evolution's span),
  a golden fish appears 140-230 studs away and the lamp's gold beam points at it for everyone. The lamp goes out when the fish is
  eaten or leaves, then rests 4 min. When it is ready the lamp breathes and gold stars drift out of the door.
- Where: `GameConfig.LandmarkUses.Lighthouse`; server `MB_LandmarkUses` (attributes LampUntil / LampReadyAt / LampTarget on
  the Lighthouse model); client `MB_LandmarkUses`; `MB_FishServer` got `_G.MB_GoldenAt(x, z, y)`.
- Tested: lit on entering, +106 EXP (x2 boost), golden fish spawned, beam on. The beam was faint from 150 studs, so it was made
  wider and less see-through; that change is not re-checked by eye.
- The other four landmarks have no use yet.

## 3. Kill feed with portraits (built, layout tested with sample rows)
- `StarterPlayerScripts.MB_KillFeed`: a row per Red Trench kill, top-left under Roblox's own buttons: [portrait] NAME ATE NAME
  [portrait]. Gold = you ate, coral = you were eaten. Up to 4 rows, 6 s each. Player portraits = their Roblox headshot; a sea
  creature of the Trench (no account) = its first letter on a coloured round tile. Hidden while a window is open.
- `MB_PvPServer` now sends the eaters' user ids with "PvPEaten" (backup `MB_PvPServer_preKillFeed_13Nov`).
- Not tested with a real Trench kill (needs 2 players or a Trench fight); the first headshot can take a second to load.
- Not done: the big gold words for the eater (the PvP reward pop already exists).

## 4. Biome sounds (made, waiting for Roblox's review)
- Four seamless 12 s loops, our own synth (`MEGA BITE\Audio\biomes\biome_sfx.py`): AmbKelp 82819656154882 (N),
  AmbRuins 85305714102375 (E), AmbBones 113734425326839 (S), AmbGlow 108497907949793 (W). About -24 LUFS, energy in 250-4000 Hz.
- `StarterPlayerScripts.MB_BiomeSound` fades them in outside the reef and cross-fades at biome borders. It only plays a loop
  that is in `MB_Sounds.List`: add each as `{ids = {id}, vol = 0.22, loop = true}` when Approved. Not heard in game yet.
- WhaleSong 118006360788733 and KrakenRise 118505351629475 are Approved and in `MB_Sounds.List` now.

## 5. Tier rooms in the Shop/Index (checked, not built)
- Live check: the Index is a FISH Index only (12 tiles by rarity + a hero card). There is no shark page, so there is nothing
  to recolour yet.
- Plan: a SHARKS tab in the Index. All 7 evolutions on one page in three tier rows (REEF: Minnow, Clownfish, Barracuda /
  OPEN SEA: Reef Shark, Hammerhead / APEX: Great White, Megalodon); owned = full colour, next = its EXP need, later ones =
  silhouettes with the need; the window colour follows the chosen shark's tier (teal / blue / gold, always bright); the hero
  card shows the shark. Needs `MB_Index` (tabs) and `HeroCard` (a shark view).

## 6. Fish Index tiles (owner 10:48: "make these colors better and the pictures brighter and look better and more vfx") - done
- `StarterPlayerScripts.MB_Index` (backup `ServerStorage.MB_Index_preTileFx_13Nov`).
- Colours: three-stop glossy gradients, light at the top. Common = sky blue, Rare = deep royal blue (they looked the same
  before), Uncommon green, Epic purple, Legendary gold.
- Pictures: brighter viewport light (ambient 170 -> about 235), every fish fills its tile (camera distance per fish instead of
  one distance for all), a soft white light behind the fish (the kit's own glow image), a gentle bob.
- VFX (only while the Index is open): 3 bubbles rise in every found tile; twinkles blink at new spots, more for rarer fish
  (Uncommon 1, Rare 2, Epic 3, Legendary 5); the old foil sheen stays. No rays.
- Seen in Studio Play at 1220 x 730. Not checked on a phone. The fish pictures take a few seconds to appear the first time.
