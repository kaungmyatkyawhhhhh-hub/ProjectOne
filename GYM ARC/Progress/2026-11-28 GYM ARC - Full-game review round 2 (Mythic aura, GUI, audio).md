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
