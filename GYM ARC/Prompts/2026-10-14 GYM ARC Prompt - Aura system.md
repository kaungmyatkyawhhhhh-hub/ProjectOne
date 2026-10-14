---
date: 2026-10-14
tags: [gymarc, prompt, feature, monetization]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: aura system (14 Oct)

```text
AURA SYSTEM (new). Save to Obsidian first. Players may already own the Aura Pack pass (2033954299), so it must unlock real auras.

1. WHAT AN AURA IS
   - A cosmetic effect around the character built from layers: ParticleEmitters + Beams + one soft PointLight, on Attachments in the HumanoidRootPart/UpperTorso. Scale every layer with the character's size (tiny new player to 7'0" mass monster).
   - 3 layers per aura:
     1) inner glow (soft particles close to the body)
     2) outer flames/energy rising up
     3) sparks/rings burst
   - IDLE (walking around): layer 1 only, subtle.
   - LIFTING: layers build up with the PUMP bar: layer 2 at 50% pump, layer 3 at 100% pump. A one-time burst + short scream sound on a new personal record.
   - No Highlight instances (Roblox limits them). No emojis or brand names.

2. AURA LIST (Config.Auras, each with name, colors, rarity, how to unlock)
   Free (earned):
   - Ember (orange): level 10
   - Frost (light blue): level 25
   - Storm (electric white/blue): level 50
   - Golden (gold): reach 7'0"
   - Titan (red + gold): beat every achievement
   Aura Pack pass (all 5 unlocked by owning 2033954299):
   - Inferno (red/orange flames)
   - Blood Moon (deep red + black smoke, matches the game icon)
   - Void (purple/black)
   - Neon (pink/cyan)
   - Galaxy (dark blue with stars)
   VIP pass (2032988308): Royal (gold + white, exclusive)
   Coins: Toxic (green) 50,000 coins, Shadow (black/grey) 150,000 coins.

3. AURAS PANEL (final black + gold kit)
   - Add an "Auras" tab to the Titles panel (cosmetics together), plus the Store's Auras tab linking to it.
   - Grid of aura tiles: preview icon, name, rarity tag, state (EQUIP / EQUIPPED gold stamp / locked with how to unlock / coin price / "AURA PACK" button that prompts the pass).
   - A live preview of your character with the aura at full power on the left.
   - "Aura: Off" option to turn yours off.

4. RULES
   - Owned auras, equipped aura and coin purchases are saved server-side. Pass ownership is checked on join (UserOwnsGamePassAsync) and on PromptGamePassPurchaseFinished, so buying the pass unlocks them instantly.
   - Other players see your aura (replicate only the equipped aura ID; each client builds the effect locally).
   - Settings toggle: "Show other players' auras" (default on, auto off on low graphics).
   - Performance: follow the culling/LOD rules. Other players' auras beyond 40 studs = off, mid distance = layer 1 only. Cap total particles on mobile.

5. TEST
   - Unlock checks for each type (level, height, pass, VIP, coins), equip/unequip, idle vs lifting vs max pump vs PR burst, small vs max size.
   - 10 players with auras on a phone emulator: FPS still fine.
   - Screenshot every aura at full power into screenshots/auras/.

Commit after each part, update PROGRESS.md and Obsidian.
```

Follow-up message:

```text
Aura icons: Downloads\gym_arc_aura_icons\aura_<name>.png (ember, frost, storm, golden, titan, inferno, blood_moon, void, neon, galaxy, royal, toxic, shadow). Upload all 13 to Myanmar Builders Club, find the IDs with search_asset by exact name, and put them in Config.Auras[name].Icon. Use them on the aura tiles in the Auras panel and the Store's Auras tab.
```
