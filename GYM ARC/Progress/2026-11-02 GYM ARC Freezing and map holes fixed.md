---
date: 2026-11-02
tags: [gymarc, progress, performance, streaming]
status: fixed in the Edit place and tested in Studio; not published; owner sets 2 streaming values, then publishes and checks live
---
# GYM ARC - freezing while moving + map holes fixed (2 Nov, Claude Code)

**Sources:**
- Prompt: [[2026-11-02 GYM ARC Prompt - Fix freezing and map holes]].
- Bug: [[2026-11-02 GYM ARC Bug - freezing while moving and map holes]].
- Feature: [[GYM ARC - Performance]].

Screenshot after the fix: `GYM ARC/Screenshots/freeze/progym_after_fix_2nov.jpg` (the Pro Gym from the street: whole, 0 pieces hidden).

## Causes found
1. **ProGymClient error** (`:45 attempt to index nil with 'Position'`):
   - The Pro Gym glass door (`ProGym.GlassWall.GlassDoor`) was no longer Atomic, although the script was written for an Atomic door.
   - So the door streamed in piece by piece. When its Blocker part wasn't there yet, `verify` re-ran `setup` every 0.25 s and errored each time.
   - It made no connections, so it wasn't the memory leak, but it was 4 errors a second.
2. **Map holes from WorldLodClient:**
   - Streaming parks a part that leaves your area (Parent nil) and later brings the SAME part back.
   - A part the LOD had hidden kept LocalTransparencyModifier 1 while away, and the LOD forgot it.
   - So it came back invisible for good.
   - This happened on any device the LOD was active on (phones, and PCs that LowEnd had flagged as slow).
   - The LOD also covered the gyms (Gym, ProGym, PowerliftingGym), so gym walls and props were among the pieces it could hide.
3. **Same bug in LightAreaClient:** a light that streamed out while set to Range 0 came back with 0 saved as "its own range", so it was dark for good.
4. **Hitches:**
   - WorldLodClient checked 1,500 parts every frame. It was the most expensive game script while moving: 726 ms of CPU in a 14 s route.
   - GymLightsClient re-scanned every gym's whole model (and its bounding box) every 5 s. The Pro Gym alone has ~2,650 parts, so that was a hitch every 5 s.
5. **Buildings streamed in piece by piece:** only Sauna, VipGym, MembersGym and the machines were Atomic.
6. **Memory:**
   - In Studio, client memory was flat over 3 laps of the town after the first load: workspace ~83.6k instances, PlayerGui 18.7k, Lua heap steady.
   - So I found no script leak.
   - The live climb (1416 → 1625 MB) matches the town streaming in as you visit new areas. Default streaming only releases content when memory runs low.
   - Needs the live check below to confirm it levels off.

## Fixes (Edit place)
- **ProGymClient:** `setup` returns false (no error) until the Blocker is there; the door is looked up again next frame. GlassDoor set to **Atomic** again.
- **WorldLodClient:**
  - Off on PC / console (does nothing, tracks nothing). Phones / tablets only (`LowEnd.IsMobile`).
  - It only ever hides **outdoor decor**: Town Street, Plaza, Greenery, Beach, SportsCourt, SkatePark, PocketPark, EdgeMarkers, Runway, plus the Backdrops.
  - It never hides gyms, shops, buildings, roofs, or anything within 80 studs of the camera.
  - Remembers every part it hid (weak table) and shows it again when it streams back in.
  - 200 parts per frame (was 1,500).
- **LightAreaClient:** each light's own range is remembered (weak table), so a light that streams back in gets its real range back.
- **GymLightsClient:** collects a gym's lights once, then listens for lights streaming in (DescendantAdded). No more 5-second full re-scans.
  - Checked: inside the Pro Gym it showed 126 of 126 lights on and the Starter Gym 0 of 57 (the switching still works).
- **Streaming modes:**
  - Atomic on 46 models: ProGym, PowerliftingGym, GlassDoor, Town GoldenEraGym, BeachGym, PumpShop, ClothingStore, HallOfFame, and all 38 `Town.Buildings` models.
  - `Town.GymRoofs` (169 loose roof parts by the spawn) changed from a Folder into a **Persistent** Model. No script referenced it.
- **Client scripts scanned** (227 LocalScripts / client modules):
  - No other script indexes streamed world parts directly.
  - The only other hits are UI or the player's own clones.

## Measured in Studio (same route: spawn → Starter Gym → Pro Gym → VIP → Hall of Fame → Pump Shop → Golden Era, at skate speed 40 studs/s, LOD forced on with TestLodTier 1)

| | Before | After |
|---|---|---|
| Frames over 33 ms (first 15 s) | 163 | 11 |
| Worst frame | 246 ms | 81 ms |
| WorldLodClient CPU | 726 ms / 14 s | 129 ms / 15 s |
| GymLightsClient CPU | 145 ms / 14 s | not in the top 12 |
| Console errors | 0 in Studio (the error needs real lag) | 0 |
| Building parts hidden by the LOD | possible after streaming | 0 (checked) |

- Studio runs the server, the client and the editor in one process, so its frame times are noisy: a later 91 s run still had 185 ms spikes at 40 FPS average.
- The real check is live (below). Top client costs now: MuscleRig, GuidePath, TutorialClient (tutorial on a fresh save), TrainerFollowClient. None is a periodic full scan.

## Owner to-do (scripts can't set these)
1. Workspace > Properties: **StreamingTargetRadius 160**, **StreamingMinRadius 64**, StreamingIntegrityMode Default.
2. Save and **publish**.
3. Live check on PC: skate the same route (spawn → Pro Gym → town loop) with Shift+F5 + Ctrl+F6.
   - Max frame should be under 33 ms.
   - Memory should level off after the first lap.
   - No `ProGymClient` errors in F9.
   - No holes at the gym you screenshotted.
