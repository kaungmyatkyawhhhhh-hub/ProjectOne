---
tags: [mm-outfit-catalog, build-log]
created: 2026-11-16
plan: "[[2026-11-16 CAC lessons - MM build list]]"
---
# Built: Photo Booth (build list item 5)

- **What it is:** MM's own take on the Photo Studio idea from [[2026-11-16 Teardown - Catalog Avatar Creator (played, every button)]]. It's a real room in the world, not just a panel.
- **Status:** not saved or published by Claude. File > Save, then publish, is the owner's step.
- **Backup:** `ServerStorage.ScriptBackups.pre_PhotoBooth_16Nov` (ShowroomCollection). Everything else is new.

## Where and how you get in
- **Where:** the empty nook behind the boutique entry wall, by the penthouse window (left of the Private Suite).
- **Workspace model `OutfitShowcase.Photo Booth`:**
  - A 17.5-stud backdrop with brass trim and a neon **PHOTO BOOTH** sign.
  - Side wings and a curved floor sweep, for a seamless studio look.
  - A brass "stand here" ring with a prompt: **E: Take photos**.
  - A ring light (the key SpotLight) and a softbox (fill light).
- **Two ways in:**
  - Walk up and press E.
  - **More → Photo**: a new button with a drawn camera icon. It takes you straight there.

![[Screenshots/2026-11-16 photo booth set in the penthouse nook.jpg]]
![[Screenshots/2026-11-16 More tray with Photo button (PC).jpg]]

## Inside the booth (`StarterPlayerScripts.PhotoBooth`)
- **Backdrops (6, our own):**
  - Studio, City night (skyline + moon), Rain (bokeh + falling rain), Runway (the boutique's neon arches + MM), Sakura (falling petals), Golden hour.
  - All drawn with UI shapes plus our existing glow image; nothing to upload.
  - Shared module: `ReplicatedStorage.OutfitShowcase.PhotoBoothThemes`.
  - The backdrop change is local: other players keep seeing the default.
- **Poses:** Stand, Wave, Cheer, Point, Laugh, Dance 1–3, plus the pack idles (Confident, Stylish, Popstar, Princess, Bubbly…). R15 avatars only; R6 players get a toast.
- **Camera:**
  - **Turn** with < > or by dragging.
  - **Full / Half / Face** framing. The camera fits your body in the space the controls leave free.
- **Snap:**
  - Hides the UI, takes a real screenshot (CaptureService), then flashes.
  - The card offers **Save** (Roblox's save-to-device prompt), **Share** (Roblox's share prompt) and **Again**.
  - Photos carry a small brass **"MM Outfit Catalog"** watermark: free marketing whenever a kid posts one.
- **Hide UI:** clean frame plus the watermark; tap anywhere to bring the buttons back.
- **While you're in the booth:** other players are hidden for you only, the HUD/chat/player list are hidden, and your controls are frozen. **Exit** restores everything.
- **Phone (short landscape):** the controls move to a side panel, so the whole outfit stays visible.

![[Screenshots/2026-11-16 photo booth - City night + Wave (PC).jpg]]
![[Screenshots/2026-11-16 photo booth - Pose tab, Half framing (PC).jpg]]
![[Screenshots/2026-11-16 photo booth - Runway, UI hidden, watermark (PC).jpg]]
![[Screenshots/2026-11-16 photo booth - Rain, side panel (phone A06).jpg]]
![[Screenshots/2026-11-16 photo booth - Golden hour (phone A06).jpg]]

## Problems found while testing (fixed)
| Problem | Fix |
|---|---|
| Full framing cut off the head and feet: the bottom panel hides about 20% of the screen | Framing now fits the body into the free space |
| Backing the camera up put it in the Private Suite doorway (door edge in shot) | Camera capped at 12.5 studs; the lens widens instead, plus side wings so wide phones never see past the backdrop |
| Softbox in the shot | Moved it and the ring light out of frame |
| ↺ ↻ arrows drew as boxes (not in Builder Sans) | Plain < > |
| Stacked-circle glows showed rings | Replaced with our existing radial glow image |
| The camera only sees the lower ~55% of the backdrop, so the moon / MM logo / sakura branches were off-frame | Scenes are now drawn into that band |
| The flash washed out the photo | It now fires after the capture |
| Bottom panel hid the legs on A06 | Side panel on short phones |
| First row of backdrop chips cut off in the side panel | Rows align top |

## Tested (Studio Play, PC 976×584 + Galaxy A06 705×338)
- **Entry:** More → Photo (real clicks); walking up and pressing E.
- **Inside:** Pose tab → Cheer, Half framing (real clicks); all 6 backdrops render.
- **Snap:** the photo card appears with the watermark in the photo.
- **Exit:** restores the camera (Custom, FOV 70), HUD, prompt, auto-rotate, default backdrop and floor colour; walking works afterwards.
- 0 console errors.

## Not tested / owner steps
- **Save and Share:** not pressed. They open Roblox's own prompts and are the player's choice; they work in the live game on phones.
- **No shutter sound yet:** Snap reuses `ui_open`. Rule: no placeholder sounds, so a real shutter sound should be made with Fish Audio (roblox-game-sounds skill) and uploaded by the owner.
- **No signage from the boutique to the nook:** the More → Photo button is the main way in.
