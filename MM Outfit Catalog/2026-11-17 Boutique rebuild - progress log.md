# Boutique rebuild: progress log

- **Started:** 2026-11-17
- **Owner's choice:** "Boutique only" (browse, try on and buy curated outfits; no runway mode).
- **Plan:** [[2026-11-17 Honest audit + rework plan (quality-nerd sim)]].
- **Full backup before the rebuild:** `ServerStorage.MapBackups.pre_Boutique_17Nov` (the whole OutfitShowcase map, all 21 scripts, Lighting).
- Nothing saved or published by Claude.

## Done (17 Nov)
1. **Tower cut:**
   - Floors 01–17 and the main staircase moved to `ServerStorage.MapBackups.CutTower_17Nov`, not deleted.
   - Floor 18 (part of the penthouse's lower level), the skyline and the building's outside walls stay.
   - The old stairwell hole on the lower level is sealed with a matching plank.
   - Lights: 223 → 68.
2. **R15 mannequins + layered clothing (`OutfitShowcaseServer`):**
   - Mannequins are built R15.
   - Layered types 64–72 are allowed (t-shirt, shirt, pants, jacket, sweater, shorts, shoes, dress), with inner→outer `Order`. The same goes for try-on.
   - Admin: saved outfits and **Add My Outfit** now keep 3D clothing (up to 14 items); before, they dropped it.
   - Backup: `ScriptBackups.pre_R15_17Nov`.
3. **Idle animations per outfit (owner: "animations in the outfits", "idle animations in the mannequin"):**
   - `Config.Outfits[].Idle` plus `Config.IdleStyles` (15 Roblox pack idles, all checked as AssetTypeId 24).
   - Midnight = Confident, Frost = Stylish, Sakura = Popstar.
   - The room mannequins play it, out of step (`PenthouseExhibitClient`); so does the viewer.
   - The admin editor has an "Idle animation · tap to change" picker. Add My Outfit copies your own idle: it builds a throwaway rig from your description and reads its Animate idle id.
   - **Trap:** an R15 rig from `CreateHumanoidModelFromDescription` contains Roblox's **Animate LocalScript**. Inside PlayerGui (the viewer's ViewportFrame) it RUNS, stops all tracks and plays the default idle. The server now deletes it.
4. **Slow lighting (owner: "the lighting takes long to load"):**
   - Measured: every Lighting value is constant from second 1 (no script dims anything). The room is black for about 12–14 s after joining in Studio, which is the engine's light warm-up.
   - Boutique models set to **Persistent** streaming.
   - New `ReplicatedFirst.MMLoadingScreen`: MM-branded, waits for the game + character + 9 s, max 20 s.
   - **The owner's step:** Studio → Explorer → Lighting → Properties → **Technology** → try **ShadowMap** (scripts can't read or write it), then rejoin and see if the warm-up is shorter.

![[Screenshots/2026-11-17 rebuild - R15 mannequins with idle styles.jpg]]
![[Screenshots/2026-11-17 rebuild - loading screen.jpg]]

## Next
- One palette + lighting grade.
- Rebuild the boutique floor: layout, real furniture kit, set pieces (runway, fitting-room mirrors, neon MM sign, rain café bar).
- NPC shoppers.
- Trim the HUD.
- Re-run `Calc/nerdsim.py` + screenshots on PC and phone.
- The outfits themselves: new outfits made with 3D layered clothing (Add My Outfit now supports it). The 3 current ones are still flat classic shirts and pants, just on R15 bodies.

## Done (17 Nov, part 2: the boutique floor). Owner: "dont ask me for any permissions. just do it"
- **Cleared** (into `ServerStorage.MapBackups.Removed_Boutique_17Nov`): the green "Fit check corner", the olive/salmon "Rain window lounge", the runway inlay lines, the banquette, the coffee table, the tailoring settle, and the small "MM / OUTFIT GALLERY" lettering.
- **Palette:** a dark polished floor (SmoothPlastic, Reflectance 0.12), a darker ceiling, hot-pink neon accents, brass feet and frames, and the walnut wall kept. Old colours are saved as attributes.
- **`Workspace.OutfitShowcase.Boutique` (Persistent):**
  - Runway: a glossy black strip with pink edge lights from the entrance to the mannequins.
  - **3 pink neon light arches** over the runway (matching the new thumbnails), with a soft pink light each.
  - Mannequin stage: a gloss floor and a neon line in front of the 3 mannequins; a **glowing "MM" sign** on the walnut wall.
  - **Clothing racks:** 2 garment racks and 2 hanging racks, from free Creator Store models.
  - **Velvet lounge:** a curved red velvet booth and 2 brass/black cocktail tables.
  - **Fitting rooms:** 2 booths with pink curtains, brass-framed mirrors and a "FITTING ROOMS" sign.
- **Malware caught:** the free rack and booth models had **hidden scripts inside their mesh parts** ("Runtime", "qTexture" — a known backdoor pattern). Every script in `ServerStorage.BoutiqueKit` was deleted before use. The deco chair (89361110794503) failed to insert.
- **NPC shoppers** (`ServerScriptService.BoutiqueShoppers`):
  - 3 shoppers browse the racks wearing catalog outfits, each with its own idle style (played on clients via the `MMBoutiqueShopper` tag), and change outfits every 50 s.
  - Anchored, no collisions or clicks.
- **Room banners off:** `PenthouseWayfinding` disabled ("Penthouse gallery" / "Floor 19" banners covered the top of the screen).
- **Windows:** the fog is dimmer and reacts to the room's light.
- **Tested in Play:** PC views from the entrance, the lounge side and the café side, plus the A06 phone. 0 console errors.

![[Screenshots/2026-11-17 boutique v2 - runway, arches, MM sign, shoppers.jpg]]
![[Screenshots/2026-11-17 boutique v2 - velvet lounge.jpg]]
![[Screenshots/2026-11-17 boutique v2 - cafe + fitting rooms.jpg]]

## Still to do
- **HUD trim:** on a phone, 8 dock buttons + Admin/Music crowd the top; target 4 + a menu.
- The "Most Purchases" board is unreadable: make a big readable "Fit of the day" board.
- The penthouse rooms behind the entrance (gallery, library, suite) still have the old block-out look.
- Lighting grade pass, and more mesh furniture (a cash wrap, plants in matching pots).
- New outfits with 3D layered clothing (the 3 current ones are flat classic clothes).
- Re-run the sim + a full phone audit.

## Done (17 Nov, part 3). Owner: "okay do it"
- **HUD trim (`ShowroomCollection`):**
  - One dock of 5: Featured, Random, Cart, Wishlist, **More**.
  - More opens a tray with Avatar, Codes, Emotes and Games.
  - Phone: one row top-right, so the left side is clear for the thumbstick.
  - Backup: `ScriptBackups.pre_HUDtrim_17Nov`.
- **Readable boards:** "Most Purchases" / "Most Robux Spent" boards are 9.4×6.8 studs (were 6.2×4.8), with text that fills each line, glowing (LightInfluence 0) and a brass frame.
- **Penthouse recolour:**
  - 110 parts remapped: beige dividers → plum-black, olive rugs/headboard → berry, olive cushions → pink, sofas → red velvet, orange wood → darker walnut.
  - Original colours are saved as `OrigColor` attributes.
  - A pink neon edge runs along the gallery runner.
- **4 new outfits with 3D layered clothing** (Config base outfits 04–07; Roblox's own free official items, found with `AvatarEditorService:SearchCatalog`, creator Roblox, best-selling):

  | ID | Outfit | Pieces | Idle |
  |---|---|---|---|
  | 04 | LEATHER NIGHT | Leather Jacket Black, Basic Tee Gray, Cargo Pants Black, white hair | Confident |
  | 05 | SOFT TRENCH | Trench Coat White, Knit Sweater Beige, Textured Leather Pants White, pink hair | Stylish |
  | 06 | ZIP SEASON | Zip Hoodie Black, Casual Sweats Gray, black hair, chain | Patrol |
  | 07 | RUFFLE BLOOM | Tie-Front Top White, Long Ruffle Skirt White, pink hair | Princess |

  Exhibit pads 04–07 came back on their own, so 7 mannequins now line the runway.
- **Fixes found on the way:**
  - The viewer always listed empty "Shirt/Pants · Preview" rows; they now only show when the outfit has classic clothes.
  - **`rbxthumb` Asset thumbnails at 150×150 never load for layered items; 420×420 does.** All item thumbnails switched to 420.
  - The web catalog API rate-limits after one search (429); the in-game `AvatarEditorService:SearchCatalog` works.

![[Screenshots/2026-11-17 boutique v3 - 7 mannequins, layered outfits.jpg]]
![[Screenshots/2026-11-17 viewer - Leather Night layered items.jpg]]
![[Screenshots/2026-11-17 HUD trimmed (phone A06).jpg]]

## Sim re-score (Calc/nerdsim.py, "current build")
| | Tells / 10 min | Wows | Like |
|---|---|---|---|
| Before the rebuild | 77 | 1.6 | 0% |
| **Now** | **33** | **5.9** | **~25%** |

Top tells left: blocky furniture (the penthouse rooms still use block furniture, only recoloured), some empty views, and the 3 original flat-clothing outfits.

## Next
- Replace the penthouse block furniture with mesh furniture (check every free model for hidden scripts).
- Remake Midnight / Frost / Sakura with layered clothing (or retire them).
- A lighting grade pass.
- Try Lighting.Technology = ShadowMap (the owner's setting) for the warm-up.

## Done (17 Nov, part 4). Owner: "okay fix all these"
- **The 3 originals remade in 3D layered clothing.** Their flat 2D templates were dropped; the old Config is in `ScriptBackups.pre_R15_17Nov.Config_pre_layeredOriginals_17Nov`.
  - **Midnight Track:** Leather Jacket Black, Roblox T-Shirt Black, Cargo Pants Black, its spiky hair and chain.
  - **Frost:** Striped T-Shirt White, High Waisted Baggy Denim Jeans (75 R$), white hair and chain.
  - **Sakura:** Off-Shoulder Jacket Pink (70 R$), Roblox T-Shirt White, Textured Leather Pants White, pink hair.
  - Outfit 04 became **MOTO BROWN** (Leather Jacket Brown, Striped Tee Black, Motorcycle Pants Brown) so it doesn't copy Midnight. Soft Trench now has black sweats and black hair (varied).
  - **All 7 outfits now use 2–3 layered pieces each.**
- **Penthouse furniture** (`Workspace.OutfitShowcase.Penthouse furniture`, Persistent):
  - Free Creator Store meshes: Modern Sofa 139213143125999 (deep red velvet) in the gallery and the library, scaled to fit; Marble/brass round table 100122443617746 ×2; Modern Bed 15035064675 in the suite.
  - **Both the sofa and the table had hidden scripts (2 each), deleted.**
  - The old block sofas, tables, cushions and piping, the bed parts, the old settee, the pedestal and the cantilever table went to `Removed_Boutique_17Nov`.
  - The bedroom back wall is toned from hot magenta to plum.
- **Lighting grade:**
  - Bloom 0.14/28/1.65 → **0.42/22/1.15**, so the neon and lit windows glow.
  - ColorCorrection: Contrast 0.15 → 0.12, Saturation −0.06 → 0.04, Brightness 0.02.
  - Old values are stored in the `Lighting` attribute `Grade17Nov`; the full lighting backup is in `MapBackups.pre_Boutique_17Nov.Lighting`.
- **Lighting.Technology → ShadowMap:** scripts can't set it, so desktop control was asked for and the owner declined. **The owner does it by hand** (steps in chat): Explorer → Lighting → Properties → Technology → ShadowMap.
- **Tested:** Play on PC, 0 errors.

![[Screenshots/2026-11-17 boutique v4 - all 7 outfits layered, graded.jpg]]
![[Screenshots/2026-11-17 penthouse - library mesh sofa + marble table.jpg]]
![[Screenshots/2026-11-17 penthouse - suite mesh bed.jpg]]

## Left after part 4
- Lower level (media salon, games room) furniture is still block-built (rarely visited).
- The Floor 19 Furniture meshes (café, bookcase, media console) are the owner's earlier meshes and were kept.
