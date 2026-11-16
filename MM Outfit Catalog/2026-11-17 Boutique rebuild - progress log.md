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
