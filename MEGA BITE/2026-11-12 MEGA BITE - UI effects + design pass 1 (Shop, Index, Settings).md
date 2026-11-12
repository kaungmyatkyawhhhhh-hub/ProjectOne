---
tags: [mega-bite, ui, effects, shop, index, settings]
created: 2026-11-12
---
# MEGA BITE - UI effects + design pass 1: Shop, Index, Settings (12 Nov 2026)

Owner (12 Nov, 13:06): "ok now we need to improve our shop, index, settings ui effects & design".
Back to [[00 MEGA BITE Home]] · research: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]], [[2026-11-12 Watch study - 3D pet card and egg hatch screen (owner recording 11 Nov)]] · rules: [[K06 Art, UI, VFX, sound and lighting]] · sounds from the same day: [[2026-11-12 MEGA BITE - UI sound set v3 (Shop, Index, Settings)]]
Picture: `UI\MEGA_BITE_UI_effects_12Nov.jpg`.

## Gap audit (our three windows in Play next to the reference recording at 28 s and 37 s)
| Gap | Reference | Ours before |
|---|---|---|
| Things move | glints twinkle on banners, patterns drift, a pop on every tap | only the pattern drift, the art bob and the 3D card |
| Item fills its card | the pet fills the card and pokes past its edge | the shark was about two thirds of the card and sat left |
| No wasted space | cards fill each row | three 140-unit cards and an empty fourth column on a phone-width list |
| Clean window | nothing from the world on top | fish outlines and lock tags drew over the open window |
| Readable item | every item reads at a glance | Ghost on the card was a see-through blob |
| Index tiles | whole pet in the tile | long fish had their tails cut by the tile |
Not copied on purpose: the reference banner's ray pattern (our rule: never a spiky sunburst), and its SALE / BEST DEAL stickers (we have no sale; a fake one would be a lie to kids).

## What was built
**`ReplicatedStorage.MegaBite.UIFx`** (new module, tweens only, nothing runs while its window is closed, all off under Reduced Motion):
- `Sheen(gui, opts)`: a soft white band sweeps across now and then; `handle.on = false` pauses it.
- `Glints(parent, n, opts)`: 4-point glints twinkle at random spots in a region.
- `Burst(gui, opts)` / `BurstAt(screenGui, point, opts)`: glints fly out, optional plain ring and rising bubbles.
- `Pop(gui, k)`: squash and spring. `Wiggle(gui, deg)`: a "no" shake.

**Shop**
- Cards fill the row on every screen (`fitGrid`: columns = what fits, width = the row divided evenly).
- A sheen crosses every button that does something (lime buy, blue equip, the banner button); the flat OWNED / EQUIPPED chips stay still.
- Glints twinkle around the featured banner's art.
- Picking a new card pops a few glints off it; equipping a skin fires a ring + glints + bubbles on its card and around the 3D card.
- 3D card (`HeroCard`): the model is bigger (`ModelLen` 1.7 -> 1.8, `ChunkyLen` 1.25 -> 1.35; 2.0 put the Tuna's tail off the screen), moved 0.1 stud toward the card's middle, and a see-through skin is capped at 0.25 transparency on the card so Ghost's ribs show.

**Index**
- Found fish tiles catch a sheen in turn (a foil card); locked ones do not.
- Picking a found fish pops glints; tapping a locked one shakes its padlock.
- Tile camera distance 2.05 -> 2.35: the whole fish is inside every tile.

**Settings**
- The chosen pill pops and carries a sheen; the row's own icon hops and shakes when its setting changes.

**All three**
- `MB_FishClient`: no fish outlines or lock tags while any window is open.

Old scripts: `ServerStorage.MB_<name>_preUIFx_12Nov` (StoreUI, HeroCard, FishClient, Index, Settings).

## Checked in Play
- Shop: the grid fills, art loads, sheens run (11), banner glints (5), a forced burst shows the ring, glints and bubbles; the Megalodon in Lantern and Ghost reads on the card.
- Index: 8 tile sheens, whole fish in all tiles, the Tuna fits the card and the screen.
- Settings: the icon of the changed row got its pop (found by position), the owner's settings were put back.
- No script errors.
- Not checked: a real equip (it would change the save: the burst was fired by hand), a phone, Reduced Motion.

## Pass 2 (12 Nov, 14:00, owner: "ok next step")
Picture: `UI\MEGA_BITE_UI_pass2_12Nov.jpg`. Old scripts: `ServerStorage.MB_<name>_preUIPass2_12Nov` (UIFx, Settings, Index).
- **Settings:** every choice pill is a 3D button now (a darker lip under it, the pill sinks onto it when pressed; lime lip when chosen, blue-grey when not); unchosen text darker (#5D7397) so it reads on a phone; the window ends 10 units under the last row (measured at run time, it had an empty strip).
- **Index:** the "7/8 found" pill is a progress bar (navy track, lime fill with a sheen, "7/8 FOUND" on it); a new fish fills it with a spring, a pop and a few glints.
- **New UI glint** `mb_ui_glint_white.png`, asset **94289337313940** (`UI\fx\`, drawn in code: two tapered beams + a soft core, a 4-point star, not a ray ring). Replaces the VFX-sheet star (109154755081516) in `UIFx`, which read small and yellowish. Burst glints bigger (about 22-40 px) and stay bright for most of their flight.
- Checked in Play: Settings layout and pills, the Index bar (7/8, fill 0.875), the new glint in a burst on the Shop. No script errors. Not checked: a real new fish filling the bar, a phone.
- Note: `ContentProvider:PreloadAsync` reported "Failure" for the new glint while an ImageLabel with it loaded fine (the same unreliable result as on 12 Nov morning).

## Pass 3 (12 Nov, afternoon, owner: "do the featured side banners and phone test" + "turn on the top bar ... the ui is going over the top bar, next to the roblox menu")
Old scripts: `ServerStorage.MB_StoreUI_preSideMinis_12Nov`, `MB_StoreUI_preTopFit_12Nov`, `HeroCard_preTopFit_12Nov`, `MB_Index_prePhoneFit_12Nov`.
- **Featured side banners:** on a narrow list (W < 760 units, which is every phone) the Lantern and Ember minis sit side by side UNDER the big banner (was: hidden). Wide screens keep them stacked on the right of the banner.
- **Under Roblox's top bar:** the Shop now starts below Roblox's own buttons (GuiService.TopbarInset): the height is fitted to the screen minus that bar, and the title/tabs/Collection/X row and the list start just under it. The open animation now uses the same offset (it had reset the list 30 px up, under the tabs). The Index and Settings already did this.
- **3D card fits the gap:** `HeroCard` takes `below = <top bar>`; the card is sized and centred between the bottom of the top bar and the bottom of the list (was: 70% of the screen height at 55%, which on a phone rose into the Collection bar and the X).
- **Index line:** "Index complete! ..." ran under the FOUND bar on phones. It now stops before the bar, shrinks to fit (10-15 px) and reads "Index complete! More fish coming soon."
- **Phone test (Studio device emulator, Play):**
  - iPhone 17 Pro (750 x 381 pt view): HUD, Shop, Index, Settings fit; nothing under Roblox's buttons; card clear of the top bar. All fixed issues above found here.
  - Galaxy S25 Ultra (the narrowest listed, 780 x 360): Shop fits, card clear.
  - iPad Air (1180 x 820): Shop fits; the card is sized by the free column, so it is smaller with space around it.
  - Desktop after the changes: card lines up with the list.
  - Small text on phones: the mini/stat lines are about 9-10 pt at the 0.7 phone scale; readable, and Settings > UI size > Big makes it larger.
  - The emulator was put back to "Current device".
- Not checked: a real device, portrait, Reduced Motion.

## Still open after pass 3
1. Shop: the skin pictures always show the Reef Shark; showing the player's CURRENT shark needs 7 x 5 renders (35 images).
2. A test on a real phone (the emulator does not show touch feel or real text sharpness).

## Still open after pass 2
1. Shop: the skin pictures always show the Reef Shark; showing the player's CURRENT shark in each skin needs 7 x 5 renders (35 images).
2. Shop: the featured side minis are hidden at phone width.
3. A phone test of all of it.

## Pass 1 list (kept for history)
1. Settings: an empty strip under the last row; the unchosen pills are flat grey next to the 3D buttons elsewhere.
2. Index: the "7/8 FOUND" pill could be a progress bar toward the next page reward, like the reference's Collection bar.
3. Shop: the featured side minis are hidden at phone width; the skins grid could show the player's CURRENT shark in each skin instead of the Reef Shark pictures.
4. The star sprite is small and yellowish at burst size: a cleaner white 4-point glint drawn for UI would read better.
5. A phone test of all of it.
