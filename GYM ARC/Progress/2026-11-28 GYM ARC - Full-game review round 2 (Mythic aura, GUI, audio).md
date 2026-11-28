---
tags: [gym-arc, review-loop, ui, audio, vfx, christmas-update]
date: 2026-11-28
---
# Full-game review, round 2: Mythic aura, every GUI screen, sound and music

Follows [[2026-11-28 GYM ARC - Full-game review round 1 (map, texts, VFX)]]. Owner: "if its below 9, keep doing", "review everything u havent", "we are revamping the entire game for the quality of life".
Saved **v2089** (pre-save steps done, not published).

## Scores so far
- **Map round 2 (Gemini):** 7.5 overall (was about 6.5). ChatGPT's map re-score is still to come.
- **UI round 1 (ChatGPT, 14 screens):**
  - UI overall 7.4; veteran HUD 6.2.
  - Motion (rated from a description) 8.2; audio (rated from the action -> sound table) 8.0.
  - Music fit: 8.5-9 per area; Winter Yard Christmas jazz 9.0.
- **UI round 1 (Gemini, first 10 screens):** menu 7.5-8, settings 6.5, veteran HUD 5-5.5, store 7. The rest of its reply was cut off by its message limit.

## Fixed (all saved in v2089)
- **Mythic aura (AuraVFX + AuraPrestige):** the owner's 6 Nov limits still hold (no face cover, no ground ring).
  - Mythic now gets a violet `MythicRim` Highlight (outline only) and tiny star twinkles on the body outline.
  - The prestige orbs get a soft star glow; they read as flat balls before.
  - The tier-5 PrestigeLight went 2 / range 18 -> 0.9 / range 11: it washed the body out white.
  - Why it was left alone before: I took the 6 Nov "too much" rule as "don't touch auras at all". Wrong: the rule limits density and face cover, it doesn't say the top tier must look weak.
- **Winter Yard music:** `AreaMusic.WinterYard` = APM Winter Holidays 9046740461, Jingle Bells (jazz) 1839945406 and Christmas Tree 1838667764.
  - SettingsClient picks it inside x -18..96, z -175..-90, only while `Gym.StarterGym.Xmas` exists.
  - Checked in Play: 9046740461 plays in the yard.
- **Christmas sounds:** new `XmasBells` (ProSoundEffects sleigh bells 9114826043) on the advent gift opening and on the Mega Gift Lift burst. Before, both only used the Hall of Fame sounds.
- **Rep sound:** a light `PlateKnock` (x0.55) layered under `RepTick`. ChatGPT: "too weak for the core gym action".
- **Mega Gift Lift banner:** it sat over every open window. It now hides while `Kit.ModalOpen()` and comes back when the window closes.
- **Settings:** removed the lone "SETTINGS" tab that repeated the title; height 262 -> 296.
- **The Shadow (trainer):** his art upload 85156645624080 renders blank, so it now uses his icon.
- **Lifting HUD:** "REP x0" now shows just "REP" until the first rep.

## Not changed on purpose
- **Left menu clutter** (both reviewers' top UI item): the tile layout is the owner's own (14 Oct "at most 8 tiles", 23 Oct chrome reset, 23 Nov locked tiles hidden). Needs the owner's call before a redesign.
- **Studio-only "flaws":**
  - Emote icons and Premium Pack art popping in late: Studio skipped the loading screen, which preloads them.
  - Genetics camera framing: I had teleported the character.
  - The top-down lift camera: my screenshot camera.
- **Reduce Motion ON:** this test account's saved setting, not the default.

## Still open (next rounds)
- Unique art per aura in the Inventory: every aura is the same orb icon recoloured. Needs new art (ChatGPT sheet).
- Gemini's UI part 2 and the final ranking (message limit). ChatGPT map round 2.
- Map items:
  - the Gem Mine ceiling texture and neon slabs;
  - the plaza cable and the "Strongest lifter" pedestal;
  - the Pump Shop topiary;
  - a grey building corner by the lift;
  - Skatepark identity.
- Phone-size passes of every window.

## Testing tip
`execute_luau` in the Client runs in its own Lua VM: `require(UIBus).OpenX:Fire()` from there reaches nothing. Open windows by clicking their buttons with `user_mouse_input` and an `instance_path` (for example `LocalPlayer.PlayerGui.MainHud.Root.MenuBar.Store`; close with `<Gui>.Root.Group.Panel.Close`).

## Round 3 (saved v2093, then v2094)
**Scores:**
- ChatGPT MAP-2 7.5 -> **MAP-3 7.8**: Hall of Fame 9.0, Pump Shop 8.7, street front 8.4, Starter Gym 8.0.
- ChatGPT VFX/audio, rated from the description (not seen in motion): GrowthFX 7.5, PumpGlow 7.0, FrostFX 7.5, rep sound 8.5, overall audio 8.4. UI is still 7.4.
- Gemini UI part 2: motion 8.
  - Area music: 7-8.5. Winter Yard 8.5; it wants a snow/wind ambience bed.
  - Its 4 screenshots were dropped when its message limit hit, so U11-U14 are still unrated by Gemini.

**Fixed, map (old values kept in attributes ending `R3`):**
- **Hall of Fame:** title band 1.9 -> 2.3 studs, padding 0.17 keeps the letter size. All warm lights x0.75.
- **Pump Shop:**
  - The 4 neon sign-frame parts -> Metal gold 218,176,68.
  - Interior lights x1.15.
- **Starter street front:**
  - GymSign, SignBox and SignFrame x1.3, raised 0.35.
  - Text now uses the HoF font, colour and gradient (it was dark red on black).
  - Doormat 6x3 with a gold metal edge.
- **Starter Gym:**
  - The pendant in front of the CHRISTMAS STRONGMAN banner gets `XmasHide`.
  - 120 of 360 bulbs hidden with their lights; the rest are x0.75 size.
  - Fills x0.8.
  - The 4 white plates -> steel 175,190,205.
  - Banner cloth -> 175,32,45 Fabric.
- **Other map:** yard glint particles -25% size; PedestalTrim gold -> 188,153,77.

**Fixed, VFX (overexposure, ChatGPT UI fix #1):**
- **GrowthFX:** body fill 0.08 -> 0.38; the pulses go 0.2 -> 0.38 (they were 0 -> 0.12); light 3 -> 1.6.
- **PumpGlow:** rep fill 0.66 -> 0.72, big rep 0.45 -> 0.56.
- **FrostFX:** Gather light 2.5 -> 1.6.

**Fixed, sounds:**
- **Trainer equip:** `Select` plus a soft `PlateKnock` (TrainersPanel); unequip is a lower click.
- **Stamina recovered:** a rising `QuestComplete` chime (HudBottom).

**Kept on purpose:**
- The plaza cable "crossing the HoF star" is the plaza string lights in front of a low camera; raising one end would detach it from its poles.
- Gemini's "add pitch variation to clicks" and "add a denied sound": both already exist.

**Next:**
- Gem Mine low-poly remodel and town foliage to low-poly (both reviewers' top item).
- The veteran HUD (needs the owner's call).
- Watch the new VFX in Play.
- Gemini UI part 2 again with its images.
