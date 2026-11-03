# Prompt: speedometer style setting (digital or analogue)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## Reference
`Games/CityLegends/imports/refs/ui/speedometer_digital_analogue.png` (owner, 2026-11-03): a racing game's two HUD speedometer styles, bottom-right of the screen. **In both, the speed is a big digital number. Only the rev counter (tachometer) changes shape:**
- **Digital:** a big italic speed number ("046" with the leading zeros dimmed), "KM/H" next to it, the **gear** in a small box to the left, and a **flat horizontal rev bar** underneath that fills left to right, with the redline part in pink / red. A small "LC" (launch control) light.
- **Analogue:** an **arc dial** (0–9 ×1000 RPM, thin white ticks and numbers, the redline section in pink / red) with a **needle**, the **gear in a circle** in the middle, "KM/H", and the same **big digital speed number** under it (leading zeros dimmed). "LC" in the dial.

Make **our own version** in City Legends' HUD style (clean, thin lines, semi-transparent, readable on phones). Don't copy that game's exact art or font.

## What to build
1. Two HUD speedometer styles, bottom-right while driving (outside cameras; the in-car view keeps the car's own working cluster):
   - **Digital:** big speed number with dimmed leading zeros, KM/H or MPH, gear box, flat rev bar with a redline zone.
   - **Analogue:** arc rev dial with needle and redline zone, gear in the centre circle, big speed number underneath.
2. **Both show the same live data:**
   - speed (matching the game's real speed exactly);
   - RPM (matching the engine and gearbox, each car's own redline from its stats);
   - gear (1–7, N, R; "M" marker in manual);
   - the redline zone flashing at the limiter;
   - LC light when launch control is active (only if the game has it; otherwise leave it out).
3. **Smooth:** the bar / needle move smoothly, with no jitter; the number updates every frame without flicker. Units follow the existing km/h / mph setting.
4. **Setting:** in the main menu's **SETTINGS** page (`MainMenu.lua`), add **"Speedometer: Digital / Analogue"**. Saved per player through `PlayerData.setSettings` (validated on the server). The default is **Analogue** (or whatever the owner picks). It switches instantly, even while driving.
5. Replace the current HUD speedometer / rev counter with these two (don't show both the old and new).
6. **Phone:** sized and placed so it doesn't cover touch controls; readable at 667 × 375.
7. No logos, no neon. White with a pink / red redline, like the reference, or the game's accent colour.

## Check before you say done
- Drive several cars (different redlines and gearboxes, automatic and manual): speed, RPM, gear and redline are right in both styles.
- Switch the setting while driving; rejoin and it's remembered.
- PC and phone-size screenshots of both styles, next to the reference.
- No console errors; `luau-lsp analyze` clean.
- Save, commit, push, and note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- screenshots of both styles;
- where the setting is.
