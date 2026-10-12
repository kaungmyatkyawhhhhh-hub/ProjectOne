# Break A Bed: Settings

#break-a-bed #ui

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): a Settings menu in the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style. It opens from a grey gear button (`icon-gear.png`) at the bottom-left of the screen.

![[UI Kit/preview-settings.png]]

## What's in it
| Setting | Type | Default | What it does |
|---|---|---|---|
| Music | slider 0–100% | 60% | Background music volume (replaces the 🔊 mute button, which can stay as a shortcut) |
| Sound Effects | slider 0–100% | **40%** (lowered 2026-10-12, was 85%) | Punches, breaks and UI sounds |
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

![[UI Kit/images/preview-settings-sliders.png]]

The menu was built with ON/OFF toggles for Music and Sound Effects. Replace those two toggles with **volume sliders** (all the other settings stay ON/OFF).
- **Look (updated 2026-10-12, owner: "make them fit the settings UI"):** see `preview-settings-sliders.png` above. The sliders are built from the **same studded FINAL STYLE pieces as the rest of the window** (`sim-btn-*` / `sim-square-*` look: studs, light inner rim, dark same-color outline). No round knobs or plain flat bars.
  - **The row:** the same dark studded row as the ON/OFF rows, same height, name on the left in the same white heavy font with the dark stroke.
  - **Track:** a dark studded box (`#1C1E24`, outline near-black), about 250 × 34 px, sitting where the ON/OFF buttons sit.
  - **Fill:** a studded **green** box (Music) or **cyan** box (Sound Effects), the same green/cyan as the buttons, from the left edge to the value. Use a 9-slice `sim-btn-green` / `sim-btn-cyan` (`ScaleType = Slice`) so the studs and corners don't stretch.
  - **Knob:** a small **yellow studded block** (`sim-square-yellow`, about 42 × 52), taller than the track, centered on the end of the fill.
  - **Value box:** a small dark studded box on the far right with the value in **yellow** (`#FFE20C`) with the dark stroke: "60%". At 0% it says "OFF" in grey.
- **Use:** drag the knob, or click/tap anywhere on the track to jump there. It must work with the mouse and touch (`InputBegan`/`InputChanged`/`InputEnded`, use the input position, clamp 0–100). Steps of 5%. The knob grows to 1.1 and gets a white outline while you hold it.
- **Live:** the volume changes while dragging. Sound Effects plays a short bubble pop every 10% while dragging, so players hear the level.
- **0% = off.** At 0% the value text shows "OFF" in grey. Defaults: Music 60%, Sound Effects **40%** (owner 2026-10-12: "50% lower by default"; half of the old 85%, rounded to the 5% step). **Existing players:** if their saved Sound Effects value is still exactly 85 (the old default, so they never changed it), set it to 40 once and save a flag `SfxDefaultV2 = true` so it never happens again. Players who picked their own value keep it.
- **How the volume works:** put all music in a `SoundGroup` "Music" and all other sounds in a `SoundGroup` "SFX" (set `Sound.SoundGroup`), and set `SoundGroup.Volume = slider / 100`. Keep each sound's own volume as it is.
- **The 🔊 mute button on the HUD** (if it's still there): tapping it mutes the music (slider to 0) and tapping again puts back the last value.
- **Saved:** save the numbers (0–100) with the player's data, only when the player lets go of the knob (not every frame). Old saves that have ON/OFF: ON = the default, OFF = 0.


## VFX and icons for the whole Settings window (owner 2026-10-12: "put more VFX in there, it looks bad")
The picture above (`preview-settings-sliders.png`) is the target. Keep the layout. Add:
- **Row icons:** each row gets a small colored studded square icon on the left (`set-music.png` green ♪, `set-sound.png` cyan speaker, `set-graphics.png` purple sparkle, `set-players.png` orange people, `set-damage.png` red "99", `set-shake.png` pink phone shake, `set-hud.png` blue eye; all in `UI Kit/images`, 128 × 128, shown at about 46 px). A soft glow in the same color sits behind each icon (`fx-glow`, Transparency 0.6).
- **Window glow:** a soft **cyan glow** around the whole window (`fx-glow` image 9-sliced or a big blurred frame behind it, Transparency 0.5), and the game behind the window is **dimmed** (a black frame, Transparency 0.55) so the glow shows.
- **Title bar:** the white diagonal shine stripes, a soft light-cyan glow behind the gear, and 3–4 twinkles (`fx-star4`) around the title. The gear turns slowly (one turn every 8 s).
- **Sliders:**
  - The fill has a glow in its color (green / cyan) around it, brightest at the knob end.
  - A white diagonal shine on the fill and the knob.
  - A gold glow behind the yellow knob and 2–3 small twinkles around it.
  - Faint tick lines on the empty part of the track (every 10%).
  - A soft yellow glow behind the "60%" text.
  - **While dragging:** the glow gets brighter, small sparkles fall off the knob, and the value text pops (1.15 → 1) at each 10%.
- **ON buttons** have a soft green glow and a shine. **OFF buttons** are a little darker, with no glow, so ON stands out. Flipping a toggle: a quick pop (0.9 → 1.1 → 1), a small `fx-ring` burst in the new color and the bubble pop sound.
- **CODES row:** a gold glow around it, a shine stripe sweeping across every 3 s, twinkles at the corners, and a green glow on REDEEM. A good code: a green flash, a sparkle burst and the reward toast. A bad code: the box shakes and flashes red.
- **Every button** (X, REDEEM, Replay Tutorial, toggles): a white diagonal shine, and on hover it grows to 1.05 and the shine slides across.
- **Rows:** a faint light line along the top edge of each row (Transparency 0.93) so they look like raised blocks.
- **Opening:** the window pops in (Back Out), then the rows slide in one after another (0.03 s apart).
- Low Graphics: keep the icons and glows, turn off the twinkles and the shine sweeps.

**Glow toned down (owner 2026-10-12: "too much glow").** The picture above is updated. Glow is now only:
- a **faint** cyan edge around the window (Transparency 0.85),
- a faint light behind the gear (Transparency 0.8),
- a thin glow on the slider fills (Transparency 0.75) and a small one behind the yellow knob (Transparency 0.8),
- a faint gold edge on the CODES row (Transparency 0.8).

**No glow** behind the row icons, the ON/OFF buttons, REDEEM, X, the title bar or the "60%" text. Keep the shines, twinkles, icons and animations. On drag, the slider glow only goes up a little (to Transparency 0.6).

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
