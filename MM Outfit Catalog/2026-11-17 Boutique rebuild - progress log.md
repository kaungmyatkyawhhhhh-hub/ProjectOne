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
