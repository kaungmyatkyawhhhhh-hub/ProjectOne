# Fix pass: UI, lighting, sounds, and the TikTok 1:1 match

- **Date:** 2026-11-16
- **Place:** MM Outfit Catalog (placeId 76354528618741)
- **Skills used:** roblox-ui-pro, roblox-game-lighting, roblox-game-sounds
- Codex had built most of the game; these fixes go on top of its work.
- **Backups:** `ServerStorage.ScriptBackups.pre_UIfix_16Nov` (7 scripts, as they were before this pass) and `ServerStorage.LightingBackups.pre_contrast_16Nov`.
- Nothing saved or published by Claude.

![[Screenshots/2026-11-16 tiktok_vs_ours.jpg]]

## UI (roblox-ui-pro)
Before, on the phone (Galaxy A06): **17 errors, 9 warnings**.
- The side docks shrank to 32 px buttons with 11 px captions.
- "Random" sat on the jump button and the left dock was in the thumbstick zone.
- The Outfit ID panel covered the left dock.
- The viewer's Outfit actions / Wishlist buttons covered the outfit title.
- "Preview only" was clipped.
- The catalog Close button was 39 px; emote names were 13 px and prices 11 px.
- The ★ ♥ # icons were font glyphs at low contrast.
- Two font families (GothamSSm + BuilderSans), and ScreenGui had ResetOnSpawn on.

Fixes:
- **ShowroomCollection `layoutDock`:** every touch screen gets a 3-across grid at the top right and a row at the top left. Buttons are 48 px on phones and 60 px on tablets; captions are 14 px.
- **Icons:** drawn heart, # and Featured icons replace the glyphs.
- **Size fixes:** Close button 44 px; Search and Open buttons ≥ 44 px; emote name and price text 14 px.
- **Wardrobe:** Gotham → BuilderSans. On phones the Outfit ID panel sits in the top row and starts collapsed.
- **StarterGui.ScreenGui:** ResetOnSpawn off.
- **OutfitViewer:** Outfit actions / Wishlist moved to the bottom right (centred under the title in portrait). The column is at least 160 px wide; narrow cards say "Preview".

After: **0 errors, 0 warnings** on the lobby, Codes, Emotes and viewer, on all of these:

| Device | Viewport | Audit |
|---|---|---|
| Galaxy A06 | 705x338 | 0 / 0 |
| iPhone 17 Pro | 750x381 | 0 / 0 |
| iPad 10th gen | 1179x819 | 0 / 0 (after the tablet fix; dock clear of jump/thumbstick) |
| PC | 976x584 | 0 / 0 |
| Xbox One | 1919x1079 | 0 / 0, gamepad selection on Buy |

Fonts: BuilderSans everywhere, plus Oswald Bold for the viewer's "OUTFIT ID" title.

## Lighting (roblox-game-lighting)
- **Codex's dusk look stays.** The snapshot shows no risks. The ColorCorrection contrast went from 0.07 to 0.15, the bottom of the skill's 0.15–0.3 range.
- **Light warm-up found:** after a spawn or a camera jump, the world lights take 4–12 s to come in at low graphics quality (and about 10 s on PC for the far-away stage). That left the viewer showing a dark silhouette.
- **Fix: the viewer studio now renders in a ViewportFrame.** It lights instantly, looks the same on every device and ignores the lobby's lighting. Verified: lit at 0.5–0.8 s on PC and on the phone.
- **ViewportFrame gotcha:** see-through parts blend against the ViewportFrame's BackgroundColor3 even when its background is hidden. The default grey turned the glossy floor grey, so it's set to near-black now.
- **Not fixed:** the lobby light warm-up right after spawning on low quality (about 10 s). It's engine-side. A branded loading screen could cover it.

## Sounds (roblox-game-sounds)
- 12 of our own sounds, synthesised and uploaded to the group, all Approved. See [[Sound table - UI sounds]].
- The `Sounds` module (pooled, mute-aware) replaced the stock ping everywhere.

## TikTok 1:1 match (vs urban_shift "CODE: 726E69")
Matched against the reference:
- **Top text:** a bold condensed line, "OUTFIT ID: 03", which is our "CODE" (players type it into the Outfit ID box).
- **Backdrop:** dark slate grey-blue with a lighter band at the horizon and a soft glow behind the outfit.
- **Floor:** near-black and glossy, with a strong mirror reflection that fades toward the bottom of the frame.
- **Framing:** the outfit at about 45% of the frame height, opening on a 3/4 angle.
- **Motion:** a slow turntable and an instant cut in.

Differences that remain:
- The reference is a vertical 9:16 video; ours is a landscape game screen with the 20% item column.
- We keep a small subtitle (name · tagline · n/N) under the title.
- Studio lighting is kept neutral, so the clothes show their true colours.

## Noticed, not changed
- Codex made item cards in the viewer open the catalog item page instead of buying straight away. Kept as-is; the card plays a tap sound.
