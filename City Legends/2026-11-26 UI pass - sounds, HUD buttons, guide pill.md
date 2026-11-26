---
tags: [city-legends, ui, hud, sound, mobile]
created: 2026-11-26
---
# UI pass: sounds, HUD buttons, guide pill (26 Nov 2026)

**Owner:** "study Modern Game GUI, no need to study if its already in the vault" → "also the tower defense simulator GUI Animation Motion VFX study" → "& Sound VFX too" → "we need to improve our city legends' too".

**Studies used:**
- [[2026-11-26 Research - Driving-game UI, sound and motion (gap study)]] (new).
- [[2026-11-26 Research - Modern lobby HUD, window motion and UI SFX (TDS)]].
- [[2026-11-11 Bible notes - modern_ui_design]].
- MEGA BITE [[2026-11-12 MEGA BITE - UI sound set v3 (Shop, Index, Settings)]], for the method.

Saved in Studio as version 2241. Not published.

## What was wrong (phone, 812 x 375)
- **Every UI sound was one Roblox built-in** (`volume_slider.ogg`, "tick"): buttons, tabs, menus, buys, rewards. A level-up was a plain explosion (`Audio.boom`), and a new car or a fitted part played the cut-up chime.
- **The guide pill sat at y 134 of 375, in the middle of the road**, while driving. The TDS study and the 2025-26 trend: keep the middle third clear.
- **CAM / LIGHTS / RADIO / ••• were 40 px buttons with 8-10 px words.** In Burmese the LIGHTS mode word (`common.auto` = အလိုအလျောက်) didn't fit. The rules from the study: 44 pt+ targets, 18 px+ text over gameplay.

![[2026-11-26 UI pass - phone HUD before.jpg]]

## What changed
1. **The "night drive" UI sound family** (`tools/ui_sounds/cl_ui.py`, all code-made, A minor pentatonic). Each sound is a car-switchgear double click plus a warm filtered-saw synth pluck (synthwave, for the night city). Every layer ends on a fade, so there is no click at the cut. Uploaded to group 33151111 (`imports/ui_sounds/`), ids in `ConfigSounds` `UI*`:

   | Key | When | Length | Loudness | Asset |
   |---|---|---|---|---|
   | `UIClick` (3 takes) | any kit button (`Audio.click`) | ~85 ms | peak -5 dB | 86747139108751, 125513135454735, 126667847847217 |
   | `UITab` | main menu tabs, pitched up a step per tab (`TAB_PITCH`) | 0.19 s | -18 LUFS | 115513551178968 |
   | `UIOpen` | main menu, garage, dealer, workshop | 0.73 s | -15.5 LUFS | 95577240285283 |
   | `UIClose` | main menu close (skipped if another window opens within 40 ms) | 0.37 s | -19.5 LUFS | 107719827280501 |
   | `UIConfirm` | workshop buy / fit (was the cut-up chime) | 0.61 s | -15 LUFS | 79545227579857 |
   | `UICash` | money-coloured pay popups: delivery, paycheck, heist, race cash (not cut-ups, which have `Audio.cutUp`) | 0.32 s | -17 LUFS | 133517145681997 |
   | `UILevelUp` | player level up (was `Audio.boom`), a new car bought | 1.28 s | -13.3 LUFS | 124355330848730 |
   | `UIError` | dealer "Not enough cash" (red message), workshop refusal | 0.29 s | -19 LUFS | 100566362650239 |

   `Audio.ui(name, pitch)`:
   - plays one sound per press: `Audio.click` waits 30 ms and stays silent if a UI sound came in (the MEGA BITE double-click lesson);
   - **ducks the music** (NFS Unbound's rule: the most important sound wins): to 35% for 1.3 s under LevelUp, to 60% for 0.6 s under Confirm, then a 0.5 s return;
   - falls back to the old built-ins if an id doesn't load (`Audio.preload` checks every id).

![[2026-11-26 UI pass - sound family spectrograms.png]]

2. **Guide pill:**
   - On a phone, while you drive (the level and job bars hide then), it moves to the top edge (`UI.topBarsHidden()`).
   - It is 420 wide on phones (470 touched the 2x chip and cash pill).
   - Stopped, or close to the target, it keeps its old slots.
3. **Small HUD buttons** are now 44 px with drawn icons, in the same frame-icon system as the side buttons (`UI` `icon` kinds `camera`, `headlight`, `radio`, `dots`):
   - no text, so they read the same in Burmese and English;
   - the lamp mode is one letter in the corner (A / L / H), and off is the red ring;
   - ••• turns into X when the car menu is open.

![[2026-11-26 UI pass - phone HUD after (driving).jpg]]
![[2026-11-26 UI pass - phone HUD after (stopped).jpg]]

## Not doubled (one problem, one fix)
- Cut-up sounds (`Audio.cutUp`) are unchanged. Cash plays only on money-coloured popups, so a cut-up never gets two sounds.
- Kit buttons keep their `Audio.click` hook. Screens add their own sound and the click steps aside.
- The menu's blur, scale-in motion and level-up flash were already there and were left as they were.

## Checked (Studio Play, phone preview, test store, put back on `CityLegends_v1`)
- All 10 ids load: no "did not load" warnings, and the logged Sounds carry the new ids.
- Menu close then garage open played Close then Open (0.15 s apart: the garage waits for GetData, so both play; acceptable).
- A pay popup played Cash.
- Pill at y 10 while driving at 26-70 mph, 11 px clear of the 2x chip. The English and Burmese guide lines fit at 420.
- Icons drawn correctly.

## Not checked
- **Claude can't hear**: whether the sounds feel right is the owner's call.
- A real level-up and a car purchase in Play (the code paths only).
- The sounds are new uploads: if Roblox's review rejects one, that sound falls back to the old built-in.
- A real phone.

## Ideas left for later (from the study, not built)
- Roads not driven yet tinted on the minimap (Forza's orange).
- Speed FOV / effects-strength slider.
- HUD element toggles.
- Card stagger on menu open (TDS 40 ms).
- A shine sweep on reward cards.
