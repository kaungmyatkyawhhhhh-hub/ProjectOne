---
date: 2026-11-11
tags: [megabite, ui, v6, build, motion]
status: built in Studio + checked in Play (Studio window ~976x584). Not published. Owner tests on the phone.
---
# MEGA BITE: UI v6 "modern" (11 Nov, 09:54 to ~11:00)

Owner: "check Roblox 2026-11-11 09-44-53.mp4 in downloads its the modern ui" -> "ok do steps 1-3 no rushing" -> "we also need like 1:1 motion effects too". Back to [[00 MEGA BITE Home]].
Reference breakdown + motion measurements: [[Roblox Playbook/Research notes/MEGA BITE/2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]]. Screenshots: `MEGA BITE/UI/v6/`.

## UI kit (UIKit, `K.V6`)
- `K.Slab` window: white paper body + faint drifting sparkle pattern (our own tile `rbxassetid://85128354788607`, `UI/v6/mb_pattern_tile.png`) on a solid blue copy offset down-left, navy outline, a huge outlined title (LuckiestGuy, white->ice gradient, navy ink) off the top-left corner with its icon, the red 3D X on the top-right corner. `win.Pop()` = the reference popup motion.
- `K.Btn3D` (lime / red / blue / gold / grey 3D pills on a darker lip, navy outline, shine line, press drops the face onto the lip), `K.CloseV6`, `K.Chip` ("0/3 owned"), `K.TitleText`, `K.Pattern`, `K.Tabs` (dark capsule, lime active pill), `K.SquareBtn` (the reference's labelled HUD square), `K.Backdrop(on, instant, key)` (blur 16 + hides the whole HUD while any window is up; keyed, so switching windows never drops it).
- Robux glyph `utf8.char(0xE002)` on prices (renders in every font).

## 1. Store v6 (`MB_StoreUI`, backup `ServerStorage.MB_StoreUI_v5_illustrated_backup`)
- FULL SCREEN on the blurred, darkened world: big "Shop" title, tab capsule Featured / Skins / Passes (taps scroll to the section, the tab follows the scroll), a Collection bar (owned / 7), the red X.
- FEATURED: a carousel banner per pass (gradient + drifting pattern, "FEATURED PASS" gold chip, big outlined title, one line, the pass art, lime price / gold OWNED, arrows + dots, turns every 5 s) + two side minis (Lantern, Ember skins).
- SKINS (5 cards) and PASSES (3 cards): white section panels with icon, title, "x/y owned" chip, grey hint; each product its own colour card (art, outlined name, darker stat pill, lime price pill / blue EQUIP / gold EQUIPPED or OWNED, a lime tick badge when owned).
- Honest as before: real Roblox prices, no fake "SAVE %" or "BEST DEAL" tags (we have no bundles), nothing that helps in a fight.
- Sizing: built in 844x390 phone units, scaled to the screen; 5 cards x 140 + gaps fit the phone's row.

## 2. Windows on the v6 slab
- Settings: rows as white strips with a light rim, dark labels, lime = chosen chip, light grey the rest.
- Fish Index: tiles like the reference's pet tiles: the rarity colour once caught (common blue, uncommon green, rare blue, epic purple, legendary gold), pale grey + dark silhouette + "Eat at: X" while unknown; "5/8 found" chip.
- Fossilize: dark text, one big gold "EXP x2 FOREVER", lime FOSSILIZE! + red NOT YET.

## 3. HUD
- NEXT UP card top-centre (white card, tilted yellow "NEXT UP!" sticker, quest scroll, the quest in bold blue, lime progress bar "2 / 5"); bumps on progress, sticker wiggle + glint on QUEST DONE; hidden in the Red Trench (the HP bar owns the top centre there). Toasts moved under it. The old quest chip under the minimap is gone.
- Left middle: labelled squares "Shop" (red) and "Index" (blue) + a small grey gear, like the reference's Shop / Trade pair.
- Right edge: a COMING NEXT column with padlocks: your next ability (icon + the shark that brings it), Fossilize (MEGALODON), and the Red Trench door (PVP). Tap = a short toast; locks wiggle.

## Motion 1:1 (measured from the recording at 30 fps)
| Moment | Reference | Built |
|---|---|---|
| Shop open | world dark + blurred at once, shop fades in over ~0.1 s ~2 frames later, tiny rise, no bounce | veil + blur instant, a veil-coloured cover clears in 0.12 s after 0.06 s, 10-unit rise |
| Shop close | a cut (1 frame) | instant |
| Tab tap | smooth scroll ~0.3 s ease-out, the lime pill jumps | 0.35 s Quint out scroll, pill jumps |
| Popup open (Pets, Gift, Giveaways) | card almost instantly at size (~0.12 s settle), white body first, content ~2 frames later | `win.Pop()`: 0.94 -> 1 in 0.12 s, a paper cover clears after 0.07 s |
| Pattern backgrounds | drift slowly diagonally | pattern tiles drift 9 units/s while the shop is open |
| Carousel | quick change | 0.2 s crossfade + 24-unit slide |
| (Recording artefact) | 2 black frames on some opens = the screen recorder, not design | not copied |

## Not done / next
- Phone test (owner): reachability of the left column vs the thumbstick, the NEXT UP card vs a long EXP number.
- The Pets-style tilted inspect card (Index: tap a fish -> a tilted rarity card that slides in from the right and rocks) is the next motion to copy.

## Owner feedback 10:22 + fixes
Owner: "these images look too unreal and fish index one is completely the other way around".
- **Skins: real renders now.** The ChatGPT skin paintings were swapped for photos of our actual in-game Reef Shark model in each skin texture: a Studio photo booth (the model upright, a flat green backdrop, post effects off), the same 3/4 front angle for all five, keyed in Python (green-difference alpha + despill), 512 px squares. Files `UI/v6/mb_skin_real_*.png`; IDs in `K.V6.SkinReal` (classic 101928013531840, coral 135107137182147, lantern 73808583319137, ghost 107217428233632, ember 116989946805937). The art pops a little out of the top of each card like the reference's pets. RULE: product images of things that exist in the game = renders of the real model, never paintings.
- **Fish Index: one fixed pose.** The tiles' cameras orbited each fish, so at any moment some showed their tail, back or belly. Now every fish is shown the same way: 3/4 front, nose to the right like the skins, facing you, with only a gentle sway.
- Booth notes: the Reef Shark model's rest pose is rolled 90 deg (dorsal toward -Z) and its head is at -X; a Neon backdrop tints the subject (use SmoothPlastic); pink skins need a green backdrop, not magenta; textures must be preloaded (ContentProvider) and given ~2 s before the capture.
