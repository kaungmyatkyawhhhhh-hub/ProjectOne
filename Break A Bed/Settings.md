# Break A Bed: Settings

#break-a-bed #ui

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): a Settings menu in the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style. It opens from a grey gear button (`icon-gear.png`) at the bottom-left of the screen.

![[UI Kit/preview-settings.png]]

## What's in it
| Setting | Type | Default | What it does |
|---|---|---|---|
| Music | slider 0–100% | 60% | Background music volume (replaces the 🔊 mute button, which can stay as a shortcut) |
| Sound Effects | slider 0–100% | 85% | Punches, breaks and UI sounds |
| Low Graphics | ON/OFF | OFF (ON by default on low-end phones) | Fewer particles, no confetti or light rays, fewer moving map pieces. Helps phones run smoothly |
| Other Players' Effects | ON/OFF | ON | Shows or hides other players' punch and break effects (lag fix in busy servers) |
| Damage Numbers | ON/OFF | ON | The "+70 💪" and damage pop-ups |
| Screen Shake | ON/OFF | ON | Camera shake and screen flash on breaks and critical hits |
| Hide HUD | ON/OFF | OFF | Hides all UI except a small "show HUD" button. Useful for screenshots, thumbnails and trailers |
| **CODES** | text box + REDEEM | – | Type a code for free rewards (below) |
| Replay Tutorial | button | – | Plays the [[Break A Bed/New Player Guide\|New Player Guide]] again |

- Settings save with the player's data, so they're the same on every server and device.
- The Low Graphics default is picked from the device (`UserGameSettings().SavedQualityLevel` is low, or it's a small phone screen).

## Fix (owner 2026-10-12): Music and Sound Effects must be sliders, not ON/OFF

![[UI Kit/images/preview-volume-sliders.png]]

The menu was built with ON/OFF toggles for Music and Sound Effects. Replace those two toggles with **volume sliders** (all the other settings stay ON/OFF).
- **Look:** a slate row with the name on the left and the value in yellow on the right ("60%"). Under it, a dark rounded track with a dark stroke, a colored fill (Music **green**, Sound Effects **cyan**) with a lighter shine line on top, and a round white knob with a dark outline and a colored dot in the middle.
- **Use:** drag the knob, or click/tap anywhere on the track to jump there. It must work with the mouse and touch (`InputBegan`/`InputChanged`/`InputEnded`, use the input position, clamp 0–100). Steps of 5%. The knob grows to 1.15 while you hold it.
- **Live:** the volume changes while dragging. Sound Effects plays a short bubble pop every 10% while dragging, so players hear the level.
- **0% = off.** At 0% the value text shows "OFF" in grey. Defaults: Music 60%, Sound Effects 85%.
- **How the volume works:** put all music in a `SoundGroup` "Music" and all other sounds in a `SoundGroup` "SFX" (set `Sound.SoundGroup`), and set `SoundGroup.Volume = slider / 100`. Keep each sound's own volume as it is.
- **The 🔊 mute button on the HUD** (if it's still there): tapping it mutes the music (slider to 0) and tapping again puts back the last value.
- **Saved:** save the numbers (0–100) with the player's data, only when the player lets go of the knob (not every frame). Old saves that have ON/OFF: ON = the default, OFF = 0.

## Codes
Codes are a cheap way to get players to join the group, like the game and come back for new codes.

- Each code gives a reward once per player (saved). An expired or wrong code shakes the box and shows "Invalid code".
- Codes live in `GameConfig` (code → reward, optional end date) so new ones are easy to add.
- **Starting codes:**
  - `RELEASE`: x2 Strength 15 min (into the Boost Inventory)
  - `BREAKABED`: Medium Cash
  - `MYANMAR`: 3 Spins (only for members of the group Myanmar Builders Club; others see "Join the group to use this code!")
  - `1KLIKES`: Big Cash + x2 Cash 15 min, added when the game reaches 1,000 likes
- Post new codes in the game description and the group, and add a new one with every update ("New code every update!" in the description).

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Build the menu with the UI Kit images, style values, animations and sounds.
2. Hook each setting into the existing systems (music, sounds, effects pooling, damage pop-ups, camera shake, HUD).
3. Save settings and redeemed codes in the player's save. Check codes on the server.
