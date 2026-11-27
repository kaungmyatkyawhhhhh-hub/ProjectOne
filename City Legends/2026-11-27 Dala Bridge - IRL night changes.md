# Dala Bridge: IRL night changes (27 Nov 2026)

The owner approved the change list in [[2026-11-27 Clip catalogue - Yangon-Dala cable-stayed bridge at night (0808)]] ("ok do the changes"). All 11 points are built.

**Where it is:**
- The bridge is still **not live**. It lives in `ServerStorage.DalaBridge_WIP_21Nov` in Studio "City Legends (placeId 121430381830562)".
- The old 21 Nov WIP is kept as `ServerStorage.DalaBridge_WIP_21Nov_backup27Nov`.
- Saved as place version **2295**. Not published.

**How it was made:** the builder `Games/CityLegends/tools/yangon/DalaBridge.luau` was changed, then the bridge was rebuilt from it. To rebuild:
1. Put the builder in `ServerStorage.ClaudeTools.DalaBridge`.
2. Run `require(ClaudeTools.DalaBridge:Clone()).build()`. It builds in `Workspace.Yangon1to1.Landmarks.DalaBridge`: 4,073 instances, ~45 s.
3. Move the result to ServerStorage.

The builder came in through Open Cloud Model 75423836549929. Its checksum matches `pack_tools.py`.

## Before / after next to the real clip
![[refs_2026-11-27_dala_build/Compare - side view at night.jpg]]
![[refs_2026-11-27_dala_build/Compare - on the deck by the pylon.jpg]]
![[refs_2026-11-27_dala_build/Compare - deck edge and railing.jpg]]
![[refs_2026-11-27_dala_build/Compare - Dala gantry.jpg]]
![[refs_2026-11-27_dala_build/Compare - toll plaza.jpg]]

Other shots are in `refs_2026-11-27_dala_build/`: a day side view and a grazing close-up of the kerb at mid span.

**About the shots:** they are Edit screenshots. For the night ones, the game's own night switch was copied by hand: tagged lamps and neon turned on, and the clock set to 21:00. The real game does this in `WorldFx`. The lamps' SpotLights are managed by distance in Play, so the deck reads darker in Edit than it will in Play.

## What was done (the 11 points)
| # | Point | Done | Built as |
|---|---|---|---|
| 1 | Lower pylon legs in a V to one footing | yes | `LowerLeg` from ±1.4 m at the water up to the deck edges. The pile cap is now 9 × 12 m instead of 30 × 20 m. The two legs do not touch: 0.2 m gap at the bottom. |
| 2 | Pale deck | yes | Deck and toll apron colour 178,174,166 (Asphalt material). It was 58,58,62. |
| 3 | Real edge on the cable-stayed part | yes | From the road out:<br>• `Kerb` 0.5 m high<br>• `GuardRail` ×2 (silver, at 0.65 / 0.95 m) on `GuardPost`s every 4 m<br>• `AnchorStrip` (replaces the walkway)<br>• outer railing: `RailTop`, `RailFoot`, `RailPost` every 3 m, and `RailBars`, a see-through infill carrying a tiled vertical-bar texture<br><br>The bar texture is `imports/sync/dala_rail_bars.png`: Decal 131639002789551, image rbxassetid://128299204776548. The approaches keep the concrete parapet and get a tall frosted `Screen` (Glass, 2.4 m) instead of the low railing (p2 0:31, p1 0:59). |
| 4 | Bell anchor caps | yes | Per stay (112): `CapBell` (0.85 m) and `CapBody` (0.55 m) along the cable, a yellow `Reflector` disc facing the road, and an `Uplight` (night only) on the strip. |
| 5 | Yellow edge line | already there | The builder already had a yellow edge line 1.0 m inside each barrier. It was kept, because the deck width (26.5 m) is from a source and its lanes fill the rest. **Check with sharper frames**: the clip suggests about 2 m. |
| 6 | Lit window at the top of the slot | yes | `TopLight` (night only) under the cap, 0.1 m clear of both shafts. |
| 7 | Lamps on the anchor strip | yes | On the cable-stayed part the poles stand on the strip, 12.2 m out, with an `Arm` and head over the road. The head ends 9.8 m out, clear of the stays. There are no lamps within 6 m of a pylon. Spacing is unchanged (35 m); 137 lamps in all. The uplights are the per-cap `Uplight`s. |
| 8 | 50 km/h signs and plaques | yes | At each pylon, 7 m before it, in both directions (4 signs): a red/white striped post with a 0.7 m disc. A bronze `Plaque` on the inner face of each leg at deck height. Its text is unreadable in the clip, so it has a rim only. |
| 9 | Dala end | yes | **Gantry** 50 m before the toll, a steel truss with 3 green signs:<br>• "ဒလမြို့နယ် / Dala Township ↰"<br>• "Sat Ein Tann Beach ↑": English only, the Burmese line is unreadable (**check with sharper frames**)<br>• "တွံတေးမြို့နယ် / Twante Township ↱"<br><br>Also on the gantry: a "5.5 m" height-limit disc. After it:<br>• a yellow diamond hump sign 15 m on<br>• a yellow / black rumble band across each direction's lanes, 20 m before the canopy<br><br>**Toll:**<br>• 32 round down-lights (was 12)<br>• green ↓ / red X lane lights on both canopy edges: green on that direction's lanes<br>• yellow sill rail and corner posts on every booth<br>• red water-filled barriers at the island noses<br><br>The Burmese board stays "မြန်မာ-ကိုရီးယား ချစ်ကြည်ရေး(ဒလ)တံတား": no kinzi, and its ending matches the clip. |
| 10 | Yangon ramp | yes | The ramps already had concrete barriers, a yellow line on the left and single-arm white lamps. Added: a white edge line on the right of both ramps (p2 0:05). |
| 11 | Pylon lighting | yes | The violet wash moved from the outer faces to the **inner faces** of the legs only. The pylon night colour is 124,122,116. The old 164,157,142 made each pylon one white glare at night, so the shape could not be seen. |

## Flicker / overlap check
- **Automatic check:** an Edit script compared every pair of nearby block parts for same-facing faces less than 0.05 studs apart whose areas overlap.
- **What it found and fixed** in the new parts:
  - Railing rails were as thick as their posts. Rails are now 0.28 and posts 0.4 (0.06 a side), and the post tops sit 0.1 over the top rail.
  - The rumble band was 0.02 over the plaza's deck surface. It now sits at paint height, 0.1.
  - The booth corner posts were 0.05 from the sill rail. They are now 0.42 wide.
  - The lower leg and the leg shared faces where they join. The lower leg is now 0.3 thinner.
  - Gantry web members met with equal faces. They now alternate in thickness (0.39 / 0.27).
  - The anchor strip / walkway's outer face lay in the steel box's side face. The strip is now 0.16 narrower on the outside.
  - Neighbouring pieces overlap where the bridge bends. Every second piece of kerb, guard rail, strip and railing is now 0.07 up and in (as `AltRaised` on the roads).
- **What is left in the check** is end faces inside the next piece at a joint (not visible), plus the old builder's own Barrier / Asphalt / Girder / Line joints, which were not changed here.
- **Visual check:** a grazing close-up along the kerb and guard rail at mid span showed no stripes.

## Not done / check later
- **Lane count and centre barrier on the deck:** unchanged (2 + 2 with a median, from the old builder's longer video). Check with the sharper windscreen frames requested in the watch INDEX.
- **Deck lamp row at night:** the real deck-edge lamp row is much brighter in side view. Ours shows faint dots at that distance. Night brightness in Play was not checked.
- **Toll:** no yellow / black island stripes and no red-white hoop barriers. The booths are opaque white boxes with yellow frames, because see-through glass would show an empty inside.
- **Unrelated, still open:** the 21 Nov list in `build/city_1to1/rebuild_progress.json` (dala_bridge). That covers the old generic deck still running under the bridge (seen in the side shots), the bend fillers, the lanes, and the Dala end land. The bridge stays out of Workspace until those are done.

## Evening update: no neon, lit like the real one (owner, 27 Nov; built, saved v2342, still in ServerStorage)
The owner said: "why are the things neon in dala bridge? irl its not neon, the lighting is just really good and nice and bright irl", and "the lighting is not the same".

![[refs_2026-11-27_dala_build/Compare - v2 side view at night (no neon).jpg]]
![[refs_2026-11-27_dala_build/Compare - v2 on the deck (no neon).jpg]]
![[refs_2026-11-27_dala_build/Dala v2 pylon close (no neon).jpg]]

**What the bridge does at night now** (builder `tools/yangon/DalaBridge.luau`, rebuilt, 4,799 instances):
- **Pylons are not Neon any more.**
  - Every face of the legs, heads and beams shows floodlit concrete at full brightness: SurfaceGui `NightLit`, LightInfluence 0, a tiled concrete picture with formwork lines.
  - There is no Neon bloom, the grain shows, and it reads from the banks (`MaxDistance` 4000).
  - The inner faces of the legs use the lilac picture (night clip p2 0:43 / 0:47).
  - Images: `imports/sync/dala_pylon_lit.png` = 110669942445834, `dala_pylon_lilac.png` = 110183071369087.
- **Deck lamps** light like the new street lamps:
  - a white PointLight hung 14 studs under each head (`Config.NightLamps` values)
  - the `LampHalo` glow sprite with `MaxDistance` 3000, so the lamp row shows from the banks like in the clip
- **Cables:** a dim night glow on the stays only (140,138,130). The clip's cable fans read pale cream. This is the only Neon left on the bridge apart from the small lamp-type pieces (lamp heads, slot window, under-beam lights, anchor uplights).

**Tried and dropped:** real floodlights (64 SpotLights up the pylons). Roblox drew them as spotty ovals up close and not at all from the bank.

**Needs the street-lamp work in Studio:** the night switch for `LampHalo` (BillboardGui sprites, and now SurfaceGuis too: `IsA("LayerCollector")`) is in `src/client/WorldFx.lua`. That file is the street-lamp session's uncommitted work: my two-word change is in the working copy, but neither is in Studio yet. Until it is synced, the sprites and pylon night faces stay off in Play.

**The same day's NPC fix** ([[2026-11-27 Far NPCs - smoother]]) is now in Studio too:
- `YangonStreetLife`: my one change applied by find/replace.
- `Traffic`: another session had already synced the whole file, my change included.
