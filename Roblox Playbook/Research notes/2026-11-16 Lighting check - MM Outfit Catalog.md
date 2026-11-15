# Lighting check: MM Outfit Catalog (after Codex's edits)

- **Date:** 2026-11-16
- **Place:** "MM Outfit Catalog" (placeId 76354528618741)
- **Skill:** roblox-game-lighting
- **Related:** [[2026-11-14 PLAYBOOK - TikTok-style outfit viewer system]]

Codex rebuilt the place on 14–16 Nov: After Hours tower, penthouse gallery, catalog admin, wardrobe and rain. It also retuned the lighting. Claude changed **nothing** in Edit this time; this is a verify-only pass.

## Current look (Edit snapshot, set by Codex)
- **Lighting:** Realistic, Brightness 2, Ambient (145,132,147), OutdoorAmbient (116,127,157), ClockTime 19.2 (dusk), Latitude 25, ShadowSoftness 0.42, EnvDiffuse 0.6, EnvSpecular 0.28, Exposure +0.18
- **Atmosphere:** Density 0.24, Offset 0, Color (194,201,228), Decay (150,95,110), Haze 0.75
- **Bloom:** 0.14 / 28 / 1.65
- **SunRays:** off
- **Showcase_ColorCorrection:** Brightness 0.015, Contrast 0.07, Saturation −0.06, Tint (255,247,247)
- **Lights and Neon:** 223 lights (0 casting shadows), 3,168 Neon parts. Snapshot risks: none.
- **Scripts that touch Lighting:** only `OutfitViewer`.

## Results
| Check | PC | Phone (Galaxy A06) |
|---|---|---|
| Penthouse lobby | warm dusk interior, readable, outfits lit | **too dark**: near-black floor, dim outfits |
| Viewer: clothes true colour | yes | yes |
| Viewer turns off grade/bloom/sunrays/haze, neutral ambient | yes | yes |
| Close restores everything | yes (values, effects, camera, walk speed) | yes |

![[2026-11-16 MM Outfit Catalog - mm_lobby_pc.jpg]]
![[2026-11-16 MM Outfit Catalog - mm_lobby_phone.jpg]]

## Findings
- **Phone darkness isn't Ambient.** A live preview at Ambient (170,158,172) barely changed the phone view. Likely cause: phone quality drops many of the 223 local lights, so the light pools never land. Fix options, needing the owner's OK because it's Codex's design:
  - fewer, stronger lights over the gallery and walkways;
  - lighter floor and wall base colours;
  - a few big soft lights in place of many small ones.
- **LightingStyle can't be written by game scripts** (capability PluginOrOpenCloud). The viewer must not try; doing so stranded players on a black screen. The viewer now pcall-wraps every lighting write. Under Codex's Realistic setup the viewer still shows true colours.
- **UI bugs in Codex's viewer additions** (not lighting):
  - the "Outfit actions" / "Wishlist" buttons cover the outfit title on PC and phone;
  - "Preview only" is clipped in the narrow phone cards;
  - in the phone lobby, the Outfit ID panel overlaps the Avatar / Wishlist / Codes buttons.

## Not done
- Technology (Future/ShadowMap): not readable from the plugin, so not checked.
- No real-phone test.
- Backup from the old Place1 session: `ServerStorage.LightingBackups` has 1 entry (it holds that place's pre-golden-hour look).
