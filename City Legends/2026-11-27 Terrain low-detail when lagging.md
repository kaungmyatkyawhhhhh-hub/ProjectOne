# 2026-11-27 Terrain low-detail when lagging

Owner (27 Nov): "the annoying thing is that when ur lagging, the terrain is in like the roblox optimizing state and not the normal terrain state".

## Cause (measured in Studio Play, 28 Nov, v2417)
- **The blurry ground is Roblox's own automatic graphics quality.** On "Automatic", the Roblox client lowers its quality level when the frame rate falls. It raises it again only slowly, which is why the look stays.
  - Below about level 13 of 21, terrain gets a low-resolution, blotchy texture. Sun shadows go too, so the ground looks flat and a little more yellow.
  - Grass measured on the same view (normal / auto-low): lit grass 92,72,40 / 90,73,28. The brightness is about the same, but the low look has less blue.
- **Game scripts can't read or set that level.** A LocalScript is refused `settings()` ("lacking capability Plugin"). `UserGameSettings.SavedQualityLevel` only says "Automatic" or the level the player picked in the Roblox menu.
- **Our own low-end mode is NOT the cause.** Forced on at quality 21, the terrain textures stay sharp. Only the shadows go (picture 5).
- **Bug found:** a workspace attribute `TestLowEnd` (false) is saved in the place. `LowEnd.autoWatch` returned early on it in the LIVE game, not only in Studio. So Auto never checked the FPS:
  - phones that started in low-end stayed there for the whole session;
  - slow PCs never dropped to the lighter load, so they stayed slow and Roblox kept the low look.

## Pictures (same camera, grass field by Myanmar Plaza)
![[2026-11-27 Terrain low-detail - 1 normal (quality 21).jpg]]
![[2026-11-27 Terrain low-detail - 2 Roblox auto quality 15.jpg]]
![[2026-11-27 Terrain low-detail - 3 Roblox auto quality 12.jpg]]
![[2026-11-27 Terrain low-detail - 4 Roblox auto quality 3 (lag look).jpg]]
![[2026-11-27 Terrain low-detail - 5 our low-end mode at quality 21.jpg]]

## What makes it lag (client, Studio PC, quality 21, 4096 streaming radius)
| Item | Number |
|---|---|
| Draw calls (Batches) | 2,395-2,591 |
| Indices drawn | 8.2-9.3 M (about 2.7-3.1 M triangles) |
| **Terrain alone** (every part hidden) | **1,685 batches, 2.44 M indices**: 70% of the draw calls |
| Global shadows | about 90 batches, 1.4 ms render CPU (14.8 -> 13.4 ms) |
| Render CPU per frame | 11.5-14.9 ms (the main cost) |
| Scripts (Heartbeat) | 1.3 ms; physics 0.2 ms |
| Client parts streamed | 47,039 (12,536 MeshParts, 19,884 casting shadows) |
| Lights | 473, 62 on, 0 with shadows |
| Beams / Textures / Surface+Billboard GUIs | 386 / 4,777 / 213 |

Main cost: rendering, not scripts. Terrain is the biggest share, because the 4096 streaming radius (owner's choice, 27 Nov) brings in far terrain. Next are the ~3 M triangles of parts and the shadow pass. The FPS was capped at 60 on this PC at this spot. The owner's lag comes on weaker PCs, phones, and while streaming at speed.

## Changed
- `client/LowEnd.lua`:
  - Auto now checks every minute: 25 s of frames, low-end on under 28 fps, off again at 55+ (phones also need under 1,800 MB). It stops after 3 drops into low-end, so a device that keeps flipping stays low-end.
  - The workspace `TestLowEnd` hook is Studio-only, as in `decide()`.
  - Lighter load when lagging means a higher frame rate, so Roblox raises its quality and the sharp terrain comes back.
- `client/Main.client.lua`: the terrain's own MaterialVariants are preloaded behind the loading screen (`ContentProvider:PreloadAsync`). These are the MaterialService base overrides (Asphalt RivAsphalt, Concrete RivConcrete2, Slate, Limestone), so the ground never shows stand-in colours while they load.
- Copied into Studio, saved v2417 (store name back to `CityLegends_v1`).

## Not changed / engine limits
- **Roblox's own quality level:**
  - The game can't pin it, read it, or change how fast it recovers. A player can avoid it by setting Graphics Quality to manual (Roblox menu > Settings).
  - The low-quality terrain texture is Roblox's built-in one for default Grass. The grass has no MaterialVariant (the owner chose plain Grass on 16 Nov), so there is no texture of ours to resize.
  - A MaterialColor change would tint the normal look too, so it was left alone.
- Grass colour, roads, lamps and shadows are untouched. The Low graphics preset is unchanged: DayCycle re-applies ambient every frame, and Ambient Low barely changes the ground.
- Not tested on a phone or on a slow PC. The re-check loop was not watched over minutes: it needs a session under 28 fps.

## Next ideas (owner's call)
- The terrain draw calls are the biggest lever. Options:
  - a smaller streaming radius on phones / low-end;
  - fewer terrain materials under roads, where nobody sees them (today's Asphalt / Concrete beds add material changes per chunk);
  - plain parts for far ground.
- Fewer shadow casters: 19,884 parts cast shadows. Small props, kerbs and road pieces could have `CastShadow` off.
