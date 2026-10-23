---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
source: GYM_ARC_monetization_hype.md
---
# 2026-10-13 GYM ARC Prompt - Monetization and hype

Back to [[00 GYM ARC Home|GYM ARC Home]]. Saved exactly as sent (original file: `GYM_ARC_monetization_hype.md`).

RULE CHANGES (these replace the old rules from now on):
- Monetization is now ON (game passes + developer products). Grunts/screams are now allowed.
- Everything else stays: kids' game, mostly mobile, no emojis in the UI, no real people or brands, every number in Config, I pick all sound/music IDs (leave empty SoundId fields with a comment).
Work in order. After EACH task: play-test solo and with 2 players, phone size, Output errors, tests, screenshots, export to src/, update PROGRESS.md, commit.

====================================================================
TASK 1. REMOVE THE WARDROBE (for now)
- Hide the Wardrobe button and its UI for all players. Don't delete the code or the clothing data; put it behind Config.Features.Wardrobe = false so I can turn it back on later.
- Players keep whatever outfit they have on now. Any clothing shop items/prompts in the world are hidden too while the flag is off.
- Nothing else may break (saving, clothing on muscles, NPC outfits).

====================================================================
TASK 2. MUSIC: HARDTEKK
- Replace the current chill background music with a hardtekk-style playlist slot: Config.Music.Tracks = { -- paste IDs here }. Leave it empty with a comment; I add the IDs.
- Keep a music on/off toggle in Settings (add one if there isn't one). Volume in Config (default 0.35).
- Optional per-area tracks: Config.Music.Areas = { Town = {}, StarterGym = {}, ProGym = {}, BeachGym = {} }. If an area list is empty, use the main list. Cross-fade 1.5 s when switching.

====================================================================
TASK 3. LIFT SCREAMS (hype screams like a tower defense commander ability)
- When a player does a heavy rep, plays a scream sound from their character (3D sound, so nearby players hear it too, not across the map).
- Triggers (all in Config):
  - Heavy rep: when the lift is at least 85% of the player's max, chance per rep Config.Screams.HeavyChance (default 0.35)
  - Last rep of a set: always
  - Hitting a new personal record: always, plus a big one
  - Arm wrestling win / posing competition win: always
- Sound slots: Config.Screams.Normal = {}, Config.Screams.Big = {} (I add several IDs to each; pick one at random, never the same twice in a row).
- Cooldown per player Config.Screams.Cooldown (default 2.5 s) so it never spams.
- A "Screams" toggle in Settings (on by default) that mutes OTHER players' screams for that player only.
- Small camera shake for the screaming player only (Config, off on low graphics).

====================================================================
TASK 4. LIFT AURA WITH LAYERS
- While a player is lifting, they get an aura made of stacked layers (ParticleEmitters + a soft glow), built in the order below. More layers turn on as the set gets harder or the player gets stronger:
  - Layer 1 (any lift): soft heat haze rising off the body, low opacity
  - Layer 2 (rep 5+ in the set or lift >= 70% of max): flame-like wisps rising from shoulders and back
  - Layer 3 (lift >= 85% of max): bright outline glow (Highlight or Neon shell) that pulses on each rep
  - Layer 4 (personal record or mass monster): sparks/electric arcs around the arms + a burst on rep complete
- Aura color: default red/orange. Add Config.Aura.Colors with a few colors (red, blue, purple, gold, green) for the shop later (Task 5).
- Rules:
  - The aura follows the body at every size (skinny to mass monster, every height up to 7'0"), attached to the right parts so it never floats.
  - It fades out 1 s after the set ends.
  - Performance: max particle counts in Config; other players' auras use fewer particles; turn off layers 3-4 for other players when FPS drops below 45 or when there are more than 8 players nearby. Keep 60 FPS on the phone emulator with 4 players lifting.
  - It must not hide the muscles or the red training highlight.
Screenshots: each layer level on a small and a mass monster player, front and back.

====================================================================
TASK 5. MONETIZATION
I create the passes and products on the Creator Hub myself. You wire everything to placeholder IDs in Config.Monetization (0 = not set up yet; hide that item in the shop until it has an ID). At the end, list every pass/product with its suggested name, description and price so I can create them.

Game passes (one-time):
- 2x EXP: double training EXP forever
- 2x Coins: double coins forever
- VIP: VIP chat tag, a VIP title, access to a small VIP lounge in the pro gym (cosmetic area with a mirror and a smoothie cart), +1 daily quest reroll
- Aura Pack: unlocks all aura colors from Task 4
- Auto Rep: holding the rep button keeps repping at normal speed (only while the player is on a machine and not AFK; still uses stamina)
- Extra Pet Slot: follow with 2 pets at once

Developer products (repeatable):
- Coin packs (small, medium, large)
- Shake bundles: give 3 of a shake from the smoothie bar
- Instant stamina refill
- Skip Growth Spurt cooldown (if there is a cooldown; never goes past 7'0")

Shop UI:
- A "Shop" button on the HUD with tabs: Passes, Coins, Boosts, Auras. Big cards, price in Robux, owned items show "OWNED". Clean, readable on phone, no emojis.
- Prompt purchases with MarketplaceService. Handle ProcessReceipt correctly (save the purchase BEFORE returning PurchaseGranted, never grant twice, handle the player leaving mid-purchase). Check passes with UserOwnsGamePassAsync on join and on PromptGamePassPurchaseFinished.

Fairness rules (it's a kids' game):
- No loot boxes or random paid rewards.
- No fake timers, no "only 2 left", no pop-ups that interrupt training. Show the shop only when the player opens it, plus at most one small, skippable offer after a personal record (Config, can be turned off).
- Free players can still reach every gym, max size, max height and every title by playing. Paid items make it faster or cooler-looking, not exclusive power.
- Test purchases in Studio (test purchases are free there) and write what you tested.
Screenshots: each shop tab, the purchase prompt, the VIP lounge, the OWNED state.

====================================================================
WHEN DONE: short report at the top of PROGRESS.md:
- the full list of passes/products I need to create (name, description, suggested Robux price), and exactly where to paste each ID
- every empty SoundId / music field I need to fill
- FPS before vs after the aura
- "TRY FIRST": the 3 things to test first
- screenshot file names
