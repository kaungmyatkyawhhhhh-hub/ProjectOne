# MEGA BITE - UX pass 1 (HUD, popups, Store v2) - 10 Nov 2026

From the deep research [[2026-11-10 MEGA BITE - UX research report (HUD, popups, placeholder UI)]]. Owner asks: best UX on the interface, placement, every HUD + popup detail, stay away from placeholder UI; "if something fails, loop again until it's great".

## Done (P0 + key P1), all tested in Play, console clean
- **STORE + INDEX moved out of the thumbstick zone**: a row right under SIZE/EXP (80x70 each, 88 px apart). The floating stick also refuses to start within 24 px of any HUD button (MB_Swim `nearHudButton`).
- **CARRYING is contextual**: a small capsule hanging off the EXP counter, hidden at 0; full bag = red count + "BANK IT!" + 1 Hz pulse (not colour alone).
- **Scaling**: UIKit.AttachScale caps phones at 1.0 and tablets (short side > 500, Roblox's breakpoint) at 1.3. Overlap maths checked at 640x360, 844x390, 1024x768.
- **Fish outlines get a second cue** (MB_FishClient): can't-eat fish = red disc + padlock badge; exactly your size = white "=" badge; edible = outline only. (Studio's screen_capture doesn't draw BillboardGuis, so the badges are verified by state only; look on a phone.)
- **Predator warning has direction**: edge glow strongest on the predator's side; "!" bubble with an arrow tip on the screen edge pointing at it; 1.5 Hz pulse in wind-up; toast "RUN! <NAME>".
- **One window at a time** (ClientBus.SetWindow / WindowChanged / CloseWindows): Fish Index + Store close each other, tap the dim backdrop to close, 2nd tap on the HUD button closes, DART/ability + STORE/INDEX hide while a window is open (like TouchControlsEnabled = false), the stick stops, and windows auto-close when a predator starts hunting you.
- **Toasts**: one at a time, 1.5-2.6 s, size steps down to fit one line (floor 14, no TextScaled), same text within 4 s dropped, max 2 waiting, waiting > 3 s = stale and dropped, zone toasts for the zone you left are dropped (+8 stud hysteresis), DANGER cuts the current toast, nothing starts under a centre pop. Texts shortened ("NEW FISH: SHRIMP!").
- **Centre pops**: at 42% height (clear of HUD + shark), 0.18 s in, gone by ~1.4 s, toasts hidden under them.
- **No "You are a MINNOW!" toast at spawn** (only real evolutions).
- **DART label no longer touches READY** (UIKit round-button label box = text height).
- **STORE rebuilt in UI v2** (MB_StoreUI): the old MB_Shop mock-up had emoji icons, a fake gem balance (222), a fake "was R$299" sale and LIMITED/THIS WEEK badges = placeholder + dark-pattern tells. Now: sea-glass window like the Fish Index, the Megalodon skin as a spinning 3D model on a Legendary card, x2 EXP / VIP / Shark Radar rows with our own icons, green price pills, "No luck, no loot boxes" line. Buttons only toast "STORE opens at launch!" (no products exist yet). Old shop backed up: ServerStorage.MB_Shop_v1_mockup_backup.
- **Bug found + fixed**: FishSnap unreliable event went over the ~900 byte limit near big schools ("payload too large", fish freezing). MB_FishServer now sends chunks of 80 fish.

## Next (from the change list)
- P1: quest panel as a one-line chip that expands on progress; counter pop + "+X" floaters; evolve celebration (only after 2 s with no threat); minimap: predators/players as shapes.
- P2: Settings (colour-blind outlines, UI size, shake, vibration); token sweep (one stroke colour, 4/8 px grid); ReducedMotion / PreferredTextSize; Abyss skins need real art before they go back in the store.
- Phone test on a real device (badges, thumb reach, mis-taps).
