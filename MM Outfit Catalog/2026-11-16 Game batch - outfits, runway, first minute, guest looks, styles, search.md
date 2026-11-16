---
tags: [mm-outfit-catalog, build-log]
created: 2026-11-16
---
# Game batch (owner: "do 1-5 game rn")

- **Not saved or published by Claude.**
- **Backup:** `ServerStorage.ScriptBackups.pre_GameBatch_16Nov` (ShowroomCollection, OutfitShowcaseServer, OutfitViewer, PhotoBooth, PenthouseExhibitClient, Config).

## 1. 15 outfits (was 3)
- **12 new looks (IDs 04–15):** Midnight Emo, Soft Pink, Y2K Pop, Street Stripe, Preppy, Grunge, Baddie, Sporty, Kawaii, Techwear, Varsity, Denim Day.
- **Classic catalog items only**, all on sale: shirt + pants + one rigid hair, picked from numbered thumbnail sheets.
- They're for sale, so players can buy what they try (e.g. Kawaii: 3 items, 77 R$).
- Each has its own idle.
- The floor pads along the runway fill up automatically.
- **Featured:** a pink **NEW** tag for 7 days (`Added` date in Config), and the daily rotation shows new looks first.
- **Templates (owner's note):** these use existing catalog items, so nothing needs uploading. The 3 originals (Midnight, Frost, Sakura) still use MM's own 2D images.
  - When MM makes its own shirts or pants, start from Roblox's official **585×559 classic template**.
  - The last ones weren't on the template, so they couldn't be uploaded.

## 2. Runway show (REMOVED later on 16 Nov, owner: "remove the runway"; see the Map batch note, Sky Deck v2)
- **Start:** the pink start ring at the entry end of the runway, "Walk the runway" (E). One walker at a time.
- **During the show:**
  - A spotlight follows the walker.
  - Everyone within 45 studs gets a pink **Cheer** button (or H) that sends hearts.
  - The hearts float up over the walker's head (server limits: 4/s and 40 per fan per show).
- **End:** reaching the stage and posing for 3 s, after 25 s, or by stepping off the runway. The walker gets "Your walk got N hearts!".
- **Bug found:** BillboardGuis with AlwaysOnTop didn't draw at all in testing, and a BillboardGui inside a ScreenGui never renders.
- **Not done:** the start music sting needs our own sound (Fish Audio).

## 3. First 30 seconds
- **Spawn:** already faces the mannequin stage, with a View outfit prompt in reach.
- **Hint:** "Walk up to any mannequin to try its outfit on" once, after loading. It goes away when you open an outfit or any panel, or after 14 s.
- **Impatient-kid sim:** `Calc/kidsim_mm.py`. MM has no economy, so the sim models MM's steps.

| Version | stay 60 s (patience 7 / 11 / 16 s) |
|---|---|
| A live (9 s loading cover) | 6 / 30 / 64 % |
| + tip on the cover | 19 / 56 / 83 % |
| + cover 5 s | 59 / 89 / 98 % |
| + cover 3 s | 86 / 98 / 100 % |

- **Built:** the cover now lasts **4 s** (`LIGHT_WARMUP` 9 → 4) and shows a tip line.
- **Built:** a one-tap **Try it on** button in the viewer.
- **5-minute stay is 0 % in every version.** After all 15 outfits the model has nothing new left, which is what 4, the styles page and the runway are for.
- It's a model; the real check is the onboarding funnel after publishing.

## 4. Guest looks
- **Where:** the "Publish my look" stand in the penthouse, just through the entry gap on the left.
- **What it saves:** what you're wearing (classic shirt, pants and up to 6 rigid accessories), under a name you choose (3–24 letters, chat-filtered).
- **Limits:** a 2-minute cooldown, at most 2 looks per player, and the newest 24 overall. Shared across servers via DataStore `MMGuestLooks_v1`.
- **How it works:** guest looks become normal outfits (`G<n>`, code 1000+n), so the viewer, Try, Buy and worn-by all work. The viewer credits "by <name>".
- **The rack:** the 4 newest stand on the **GUEST LOOKS** rack next to the red carpet.
- **Tested:** a name that's too short is refused, publishing gives code 1001, and the cooldown works.

## 5. Styles page, worn-by on cards, search, shutter
- **Styles** (owner's reference picture):
  - Topic cards for Emo & Goth, Soft & Cute, Y2K & Baddie, Streetwear, Preppy & Classic, Grunge and Guest looks.
  - Each shows its lead look, a line and a count; tap it to see that style's looks, most worn first.
  - Open it from More → Styles or "All styles ›" on Featured. Edit `Config.Styles`.
- **"Worn by N"** pills on outfit cards (from 10 up).
- **Search** (More → Search):
  - Search the Roblox catalog by word and kind (Shirts, Pants, Hair, Hats, Neck), then Try or Buy any classic item that's on sale.
  - The server checks every item (classic only, never layered).
  - A try-on adds to Undo / My avatar.
- **The More tray** is now 2 columns (the 7 buttons reached the Admin button).
- **Shutter sound:** our own synthesized one is at `Audio/camera_shutter.wav`. Snap plays "camera_shutter", which stays silent until the owner uploads the file and adds the ID to `Sounds.Defs`.

## 6. Buy while trying emotes and animations (owner: "while trying on emotes or animations, put a buy button too")
- **Backup:** `ServerStorage.ScriptBackups.pre_EmoteBuy_16Nov` (ShowroomCollection, PhotoBooth, OutfitShowcaseServer, Config).
- **Emotes (More → Emotes → a catalog emote → Try Emote):** while it plays, **Buy N R$** (or **Get free**) sits right next to **Stop emote**.
  - Hidden for emotes you already own, and it goes away after you buy one.
  - It goes through the same server check as before (`BuyEmote`).
- **Animation packs (photo booth poses):** pick a pack pose and a brass **Get the Stylish pack · 300 R$** button shows above the controls. On phones it's shorter ("Stylish pack · 300 R$"), under Exit / Hide.
  - **Which packs:** only the 6 Roblox still sells, checked in the catalog on 16 Nov:
    - Stylish 83
    - Bubbly 39
    - Cartoony 56
    - Toy 43
    - Ninja 75
    - Superhero 81
  - These are `BundleId` in `Config.IdleStyles`.
  - Confident, Popstar, Princess, Cowboy, Sneaky and Patrol have no Roblox listing left (only UGC copies), so they get no button. MM never points players at a copy.
  - **Server:** new actions `BuyBundle` and `OwnsBundle`. Only BundleIds in Config can be prompted (a made-up ID gets "That pack isn't sold here"). Owned packs are hidden.
  - **Gotcha:** bundles are collectibles now. `GetProductInfo(…, Bundle)` has no `PriceInRobux`; the price comes from `AvatarEditorService:GetItemDetails` (`Price`, `IsPurchasable`, `Owned`).
- **Tested (Studio Play, PC + Galaxy A06):**
  - Salute (owned): no Buy.
  - A free emote: "Get free" beside Stop.
  - Stylish / Cartoony / Superhero show the pack button; Confident shows none.
  - `BuyBundle 83` opens the prompt server-side.
  - 0 console errors.
- **Not checked:**
  - Roblox's own purchase window (Studio's capture doesn't show it).
  - A real purchase, on purpose (no Robux spent).
