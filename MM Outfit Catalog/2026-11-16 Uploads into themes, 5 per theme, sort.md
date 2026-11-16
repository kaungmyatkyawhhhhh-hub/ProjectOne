---
tags: [mm-outfit-catalog, build-log, ugc]
created: 2026-11-16
---
# Uploads go into the themes, 5 looks per theme, sort
**Owner, 16 Nov:**
- "people can upload their outfit to the themes and not seperated by guest theme. they can select outfit theme when uploading. up to 5 uploads a day as a normal visitor. as a outfit creator infinite uploads a day."
- "we start off with 5 outfits to each theme"
- "people upload and there will be more outfits to the point we dont need to upload anymore. also add a sort: POPULAR, NEWEST, MOST EXPENSIVE, CHEAPEST"

Not saved or published by Claude.

**Backups:**
- `ScriptBackups.pre_ThemeUploads_16Nov` (Config, GuestLooksServer / Client, ShowroomCollection, OutfitShowcaseServer, SkyDeckServer, ShowroomGallery, ClosetClient).
- `MapBackups.pre_ThemeUploads_16Nov` (the old Guest looks booth, floor-19 bays and pads before 30, the 4 clothing racks).

## Themes (Config.Styles, each with a Key)
- **6 themes, 5 MM looks each, every outfit in one theme only:**

  | Theme | Looks |
  |---|---|
  | emo | Midnight, Emo, Techwear, Neon Star, Stage Night |
  | soft | Soft Pink, Kawaii, Sakura, **Coquette Bow**, **Pink Set** |
  | y2k | Y2K, Baddie, Pink Galaxy, Ice Galaxy, **Red Y2K** |
  | street | Street, Varsity, Sporty, Racer Club, Frost |
  | preppy | Preppy, Denim, **School Classic**, **Black Blazer**, **White Sweater** |
  | grunge | Grunge, Urban Camo, **Flannel**, **Red Hoodie** (Korblox), **Pink Grunge** |

- The 9 new looks (outfits 22–30) are past-week bestselling classic catalog pieces with no brand copies (same method as [[2026-11-16 Drip looks from the catalog - picks]]). **30 outfits in total.**
- **The "Guest looks" theme is gone.** `Config.StyleOutfits` returns the theme's MM looks, then the uploads that picked that theme (newest first). Uploads carry `Style` (key) and `AddedAt`.

## Uploads (GuestLooksServer + the publish card)
- **Card:** name your look, then pick a **theme** (6 chips in the theme colours). It shows "N of 5 uploads left today" or "Outfit Creator · unlimited uploads", and scales to fit phones.
- **Limits:**
  - **5 uploads per UTC day** for visitors, shared across servers (DataStore `MMGuestDaily_v1`, key `u<userId>`).
  - **Unlimited** for the admin roles "Outfit Creator" and "Admin" (`MMStaffRole`; the owner is Admin).
  - A 20 s spam guard for everyone.
  - The old "2 looks per player" cap is gone. Each theme keeps its newest **40** uploads.
- **Server:** checks the theme key, the classic-only pieces and the name filter as before. A new "Quota" action returns uploads left.
- **Tested in Studio Play:**
  - No theme → "Pick a theme".
  - An upload into Grunge appears on the Grunge page right after the 5 MM looks.
  - The quota goes 5 → 4.
  - A second upload within 20 s is refused.
  - The "Outfit Creator" role shows unlimited.

## Where uploads show
- **Theme pages:** inside their theme.
- **Rooftop podiums:** each theme's podium ranks MM looks and uploads together by most worn.
- **New uploads podium:** the 7th rooftop podium (was "Guest looks") shows the **3 newest uploads** from any theme. Its Browse prompt opens all themes. When empty it shows silhouettes and "BE ONE OF THE FIRST 3 UP HERE".
- **Penthouse rack:** still shows the 4 newest.
- **Spawn floor:** shows the 30 MM outfits only. Uploads don't need spots, so the catalog can keep growing.

## Sort on every theme page
- **POPULAR · NEWEST · MOST EXPENSIVE · CHEAPEST** chips above the looks. The last choice is remembered while playing.
- **Data:**
  - Popular = worn count.
  - Newest = upload time, or the MM outfit's Added date.
  - Price = new server action "Prices": the R$ total of an outfit's buyable pieces. Body parts never count; item info is cached.
  - Ties keep the theme's own order.
- **Tested:** Soft & Cute by price came out 77 / 77 / 77 / 75 / 65, and reversed for Cheapest.
- Phone cards now clear the 16 px edge fade.

## Spawn floor: 30 roomy spots
- Stage 3, wings 12 inner + 10 outer (~7 studs apart), and 5 in the middle where the clothing racks stood (the racks are in the backup).
- All 30 outfits stand on the spawn floor. Nothing blocks a pad.

## Also fixed
- ClosetClient connected the Sky Deck podium handler **inside** `schedule()`, so it was re-connected on every closet refresh and one tap fired several times. Moved out.

![[Screenshots/2026-11-16 publish card theme picker PC.jpg]]
![[Screenshots/2026-11-16 publish card phone.jpg]]
![[Screenshots/2026-11-16 theme page sort phone.jpg]]
