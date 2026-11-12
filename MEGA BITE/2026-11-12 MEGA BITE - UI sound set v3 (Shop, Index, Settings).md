---
tags: [mega-bite, sound, ui, sfx]
created: 2026-11-12
---
# MEGA BITE - UI sound set v3: Shop, Index and Settings (12 Nov 2026)

Owner (12 Nov, 12:16): "the shop and index and settings sfx should be better".
Back to [[00 MEGA BITE Home]] · rules: [[K06 Art, UI, VFX, sound and lighting]] · research: [[Playbook notes - Sound and music]] · reference: [[2026-11-12 Watch study - 3D pet card and egg hatch screen (owner recording 11 Nov)]]

## What was wrong (read from the live scripts)
- ONE sample (`UIClick`, a Freesound click) played for 15 different actions: Shop tabs, banner arrows, picking a skin, picking a pass, Equip, Buy, close, picking a fish in the Index, closing the Index, every Settings choice, closing Settings.
- ONE sound (`UIOpen`) for opening all three windows.
- Nothing for the 3D card spinning, nothing for Equip, no close sound of its own, no hover.
- **Every button clicked twice.** `MB_SoundsClient` hooks EVERY GuiButton and plays `UIClick` on it, and the window scripts played `UIClick` again for the same press. Found in the first Play test: a click sat on top of every new sound.

## Research used
1. **Vault, UI sound vocabulary** ([[Playbook notes - Sound and music]]): one family in one key; tap = short and dry; open = rising whoosh; close = falling; confirm = two notes rising; toggle = two pitches; hover on PC only; avoid harsh 2-5 kHz; UI sounds in the key of the music.
2. **K06 SFX recipe:** transient + body + tail; identity in 1-5 kHz (phone speakers); about -16 to -19 LUFS; peaks under -1 dB.
3. **The owner's reference recording, its sound this time** (`Roblox 2026-11-11 09-44-53.mp4`, Pets window, 12.7-24 s, spectrogram in `Audio\ui3\reference_pets_window_12-24s_spectrogram.png`):
   - window open = an airy noise whoosh of about 0.9 s, then a rising chime run of about 0.7 s;
   - tile taps = bright pops of about 90 ms with many harmonics, a different pitch each time;
   - plain clicks = dry ticks of 20-60 ms;
   - its music sits on F# / C#, and its UI notes fit that key.
4. **Our own key:** the Bank, Buy and Size-up bells are C6-E6-G6 (measured from `Audio\set2`), and the game has no music yet, so the UI family is in C major pentatonic.

## The family: "glass bubble"
One voice for everything: a short pluck (sine + soft FM + 2nd and 4th partials) whose pitch starts a little low and rises in 25 ms, like a bubble. Layers per sound: a few ms of band-passed noise (the transient), the pluck (the body), an airy band-pass whoosh where something moves, a quiet sparkle or bubble where something is won. All code: `Audio\ui3\ui3.py` (run `python3 ui3.py out`). No recordings, no AI audio.

| Sound (`MB_Sounds`) | When | What it is | Length | Asset id |
|---|---|---|---|---|
| `UIClick` (2 takes live) | small buttons, Buy | dry pop on C6 / E6 (a third take on D6 is uploaded but was still in review) | 0.2 s | 108382158708247, 136141808986542; pending 78767617213752 (old 125500194205274) |
| `UISelect` | tap a skin, pass or fish (the 3D card spins) | pop, a whoosh that peaks as the card is edge-on, a soft G6 landing chime | 0.9 s | 96514211604453 |
| `UITab` | Shop tabs | one crisp C6; the code plays Featured / Skins / Passes as C, D, E | 0.27 s | 82805371158794 |
| `UIOpenShop` | Shop button | up-whoosh into G5-C6-E6-G6 with sparkle | 0.94 s | 114285962529579 |
| `UIOpenIndex` | Index button | a fluttering page-turn swish, then A5-E6 | 0.66 s | 94075330508966 |
| `UIOpenSettings` | gear button | small dry pop, then G5-D6 ticks | 0.35 s | 78180105049794 |
| `UIClose` | X or outside, all three windows | C6-G5 falling under a falling whoosh | 0.36 s | 113791090324331 |
| `UIEquip` | Equip (card pill, mini card, 3D card button) | soft "thup", C6-G6 rising, shimmer, a bubble rising | 0.65 s | 135694564651626 |
| `UISwitch` | a Settings choice | a pill snapping in on E6; options further right play E, G, A, C | 0.22 s | 96649177207040 |
| `UISwipe` | featured banner arrows | quick swish with a tiny pop | 0.28 s | 87880719822828 |
| `UIHover` | mouse over a Shop card, Index tile or Settings pill (PC only) | a very quiet A6 tick | 0.08 s | 83442630743083 |

Unchanged: `BuySuccess`, `UIError`, `UIPop`, `UIOpen` (still used by the Fossilize window).

## Wiring (all old scripts are in ServerStorage as `MB_<name>_preUISfx_12Nov`)
- `MB_Sounds`: the new entries; `S.PlayAt(name, speed)` (pitch steps for tabs and choices); `S.Hover()` (mouse only, at most 14 a second).
- `MB_HUD`: the Shop / Index / gear buttons play their own open sound.
- `MB_StoreUI`: tabs, arrows, pick (inside `heroPick`, so tapping the card that is already shown plays the plain click: the card does not spin), Equip in three places, close, hover.
- `MB_Index`: pick (same rule), close, hover.
- `MB_Settings`: choices, close, hover.
- `MB_SoundsClient` + `S.Tap()`: the blanket click now waits 30 ms and stays silent when the button's own script already played a UI sound, so each press makes exactly one sound.
- The new `UIClick` also plays wherever the old one did in the HUD (Fossilize window, Trench button), so the whole UI is one family.

## How it was checked, and what was not
- Measured each file: loudness -16.5 to -19.3 LUFS (hover -23.5), true peak under -1.5 dB, most energy in 1-5 kHz, no click where a layer ends (found one in the first render: every layer now ends on an 8 ms fade). Spectrograms: `Audio\ui3\ui3_spectrograms.png`.
- **Played in Studio (Play) with a logger on every Sound:** all 12 new assets load with the right lengths. Shop: open -> `UIOpenShop`; tabs -> `UITab` at 1.12 and 1.26; a new card -> `UISelect`; the same card again -> `UIClick`; X -> `UIClose`. Index: `UIOpenIndex`, `UISelect` x2, `UIClick` for the same tile, `UIClose`. Settings: `UIOpenSettings`, `UISwitch` at 1.00 / 1.19 / 1.34, `UIClose`. One sound per press, no script errors. The owner's settings were put back (Shake ON, UI size 2). Equip, Buy, the banner arrows and hover were not pressed in the test (Equip and Buy would change the save).
- **Claude cannot hear.** Whether they feel right is the owner's call: `Audio\ui3\MEGA BITE - UI sounds before and after (12 Nov).mp4` plays the old click and open first, then every new sound with its name on screen.

## Lessons
- Log what actually plays before trusting the wiring: a `Played` hook on every Sound showed the hidden second click at once.
- Do not put a new audio id into a list while it is still "Reviewing" (the same rule as images): the third click take waits in a comment.
- Count the call sites of a sound before judging it: "the sfx are bad" was really "one sample does 15 jobs".
- A reference recording has sound too. Its spectrogram shows what a modern UI does (whoosh + chime run on open, harmonic pops on taps) without anyone having to describe it.
- Very short sounds (under 0.3 s) cannot be levelled with a loudness meter; match their peaks instead.
- End every synthesized layer on a short fade, or the cut makes its own click.
