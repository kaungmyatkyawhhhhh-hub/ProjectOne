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
