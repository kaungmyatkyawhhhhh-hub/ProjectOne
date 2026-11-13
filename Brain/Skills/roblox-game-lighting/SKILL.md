---
name: roblox-game-lighting
description: "Use for ANY Roblox lighting or 'make my game look better' work: setting up Lighting, Atmosphere, Bloom, SunRays, ColorCorrection, DepthOfField, sky, time of day, biome/zone moods, underwater or night looks, retro player outlines (Highlight) and random surface textures. Gives tested presets with exact numbers (incl. the Develuper 'look 10x better' stylized day), a backup-first apply script, a read-only lighting audit, and a Studio MCP loop that screenshots the look on phone and PC before calling it done. Use it even when the user only says 'the game looks flat', 'make it prettier', 'it's too dark', or 'add a sunset'."
---

# Roblox Game Lighting

Lighting is the cheapest big win in a Roblox game: five objects under `Lighting` decide whether a map looks like a default baseplate or a finished game. Three jobs, in order: **readable** (players can see the path, enemies and pickups on a cheap phone), **mood** (it feels like this game's place and time), **crafted** (contrast, depth and colour that look chosen, not default). Never trade readability for mood.

Reference files (read when the step needs them):

| File | Read when |
|---|---|
| `references/presets.md` | Picking or tuning a look. Exact values for: Develuper stylized day, golden hour, overcast, night, horror, neon/sci-fi, underwater reef (MEGA BITE's live look), cartoon/kid simulator. |
| `references/lighting-api.md` | Writing any lighting code: every property that matters, its default, its useful range and what it really does. Checked live in Studio (Nov 2026). |
| `references/look-check.md` | Before saying a look is done, or when the user says it looks flat, washed out, too dark, too blurry or "default". |
| `scripts/lighting_snapshot.luau` | Always first: read-only dump of the current lighting + a list of risks. Paste its output into the change log so the old look can come back. |
| `scripts/apply_preset.luau` | Applying a preset. Backs the current look up to `ServerStorage.LightingBackups` first, then applies; `RESTORE` mode brings a backup back. |
| `scripts/random_textures.luau` | Big flat map areas look copy-pasted: puts a random texture from a small set on every face and nudges each part's colour. Has an undo mode. |
| `scripts/retro_highlight.luau` | The "retro / Block Tales" look: an outline Highlight on every character that does not show through walls. A LocalScript to install. |

## 1. Read the game first

- **Snapshot.** Run `scripts/lighting_snapshot.luau` in the Edit datamodel. It lists the Lighting properties, every post effect (incl. ones under the Camera), sky, light count and shadow casters, and flags risks.
- **Find who else changes lighting at runtime.** `script_grep` for `Lighting`, `Atmosphere`, `ColorCorrection`, `ClockTime`, `Bloom`, `TweenService:Create(.*Lighting`. Many games have a zone/biome mood script, a day-night cycle, a cutscene grade, or a hit flash that tweens ColorCorrection. Editing the Lighting service alone is wasted if a script overwrites it on spawn, and it can break those scripts (they often cache the start values). Change the script's base table instead, or both together.
- **See it.** Start Play, `screen_capture` from the player's real camera in 2–3 typical spots (spawn, the busiest area, the darkest area). Edit-mode camera views lie: no runtime moods, no character.
- **Note the owner's rules** in the game's notes (e.g. "lighting never dark", a palette, an art style guide). They win over any preset.

## 2. Plan the look in one paragraph

- **Time and place:** e.g. "late morning, clean tropical island", "midnight graveyard, moonlit", "shallow reef, sun from above".
- **Key colour pair:** the light colour (OutdoorAmbient / sun / Atmosphere.Color) and the shadow colour (Ambient). Warm light + cool shadow, or cool light + warm shadow. Never both grey.
- **Where the eye goes:** the bright, saturated, contrasting thing should be the thing players need (path, goal, enemy, shop). The background is calmer, hazier, less saturated.
- **Zones:** if the game has biomes or areas, decide each zone's tint and fog *as a change from one base*, so the transitions stay coherent.
- **Device budget:** kids play on cheap phones. Plan for shadows and post effects that still read when the phone drops quality.

## 3. Apply it (backup first)

1. Pick the closest preset in `references/presets.md`, copy it into `scripts/apply_preset.luau`'s `PRESETS` table (or use the built-in ones), set `PRESET` and `TAG`, run it in the Edit datamodel. The script backs up the current look first (`ServerStorage.LightingBackups.<TAG>`); `MODE = "RESTORE"` brings it back.
2. Tune **in this order** (the Develuper order, which matches how much each step changes the picture):
   1. `LightingStyle` (Realistic = crisp shadows, Soft = gentle, cartoon) + `Technology` (Properties panel only, see below)
   2. `Brightness`, `Ambient` (shadow tone), `OutdoorAmbient` (lit-side tone), `ClockTime`, `GeographicLatitude` (sun angle)
   3. `Atmosphere`: Density 0.3–0.4, Offset 0, a little light Glare, a little darker Haze: depth without grey fog
   4. `Bloom` (bright things pop) and a touch of `SunRays` (strongest at sunrise/sunset)
   5. A `Sky` that matches the time (the toolbox is fine)
   6. **`ColorCorrection` last and most important:** contrast up (0.15–0.3), saturation to taste (0.1–0.5), a soft tint. "Contrast is what makes your game look sharp and clean."
3. If a runtime script owns some values (zone moods, day-night), change its base table so the new look survives Play, and keep a backup of the script (`<Name>_pre<Change>_<date>` in ServerStorage).
4. Extras, only when they fit the art style:
   - **Retro outlines** on characters: `scripts/retro_highlight.luau` (Highlight, `DepthMode = Occluded`, fill off). Max 31 Highlights render at once; fine for players, not for every NPC.
   - **Random textures + tone variation** on big flat map areas: `scripts/random_textures.luau`. Best on blocky Parts. On low-poly MeshPart art the textures barely show, so keep only the tone nudge there.
   - **Studs material variant** on the baseplate for a classic stylized look (MaterialVariant on Plastic, or a Studs `Texture` at ~0.78 transparency, StudsPerTile 8).

`Lighting.Technology` cannot be read or written by the Studio plugin (no capability). Set it by hand in the Properties panel and say so in the report. **Future** = the best lights and shadows from point/spot lights; **ShadowMap** = sun shadows only, cheaper. Phones may drop to lower quality on their own.

## 4. Verify in Studio (the loop)

When the Roblox Studio MCP is connected, do this before calling a look done:

1. Start Play. Screenshot the same 2–3 spots as step 1 (before vs after, same camera).
2. Run `scripts/lighting_snapshot.luau` in the **Client** datamodel during Play: the runtime look can differ from Edit because of mood scripts.
3. Device matrix: switch the Device Simulator mid-Play (`StudioDeviceSimulatorService:SetDeviceAsync("samsung_galaxy_a06")`, `"iphone_17_pro"`, then `StopSimulationAsync()` for PC). Check: UI still readable over the brighter/darker world, the darkest area is still playable, bloom does not wash out white UI-adjacent things (neon signs, white sand).
4. `references/look-check.md` against the screenshots. Fix the top problems.
5. Check the console for errors, stop Play, reset the device, and say "Studio reset to default viewport."

Do not save the place, publish, or spend Robux without the owner's OK. Play sessions are fine.

## 5. Report

- The look in one line, the preset used, and every value changed (old → new), or the backup name.
- Before/after screenshots (PC and a phone).
- What is not done: `Technology` set by hand?, night/day cycle checked?, real phone not checked, toolbox sky picked or still default.
- Save the change log + screenshots to the game's notes (the vault) like any other change.

## Do / don't

- **Do** keep the Atmosphere Offset at 0 and the Density ≤ 0.45 on land maps: higher turns the horizon into a grey wall and hides the world you built.
- **Do** raise contrast before saturation. Saturation > 0.5 looks cheap fast, especially on green grass and red parts.
- **Do** give shadows a colour (blue-ish `Ambient` for day, purple-blue for night). Black shadows look unfinished.
- **Do** keep night readable: Brightness ≥ 1, Ambient no darker than ~(40,45,70), and real light sources (PointLights, neon) where players walk. "Dark" mood comes from contrast and colour, not from not seeing.
- **Don't** stack two ColorCorrections or two Blooms that fight. Name yours (`<Game>_ColorCorrection`) so runtime scripts find the right one.
- **Don't** leave `DepthOfField` strong on a gameplay camera: it blurs enemies and pickups at range. Keep FarIntensity ≤ 0.2 or use it only in menus/cutscenes.
- **Don't** use Bloom Threshold < 1 with Intensity > 0.6: everything white glows (sand, UI-coloured parts, snow).
- **Don't** set `ExposureCompensation` to fix a dark map: fix Ambient/Brightness. Exposure moves everything, including what was already right.
- **Don't** turn `GlobalShadows` off to "brighten" a map. It removes all depth. Raise Ambient instead.
- **Don't** apply a land preset underwater. Underwater looks come from Atmosphere colour/decay and a tinted ColorCorrection, not sun rays and sky (see the reef preset). Tested: the stylized-day preset on MEGA BITE's reef turned the water pale and milky, and the depth was gone.
- **Don't** swap lighting objects for new ones at runtime (Destroy + Clone). Mood scripts hold references to the old Atmosphere/ColorCorrection and keep tweening a dead object. Change properties on the existing objects; `apply_preset.luau` restore does this.

## Tested (14 Nov 2026, MEGA BITE in Play)
- `lighting_snapshot`: read the full look, the 4 runtime scripts that touch lighting, 49 lights / 555 Neon parts, and 0 risks.
- `apply_preset` stylized_day: applied with a backup of 18 properties + 6 objects. Restore put every value back on the same objects and removed an added extra effect.
- `random_textures`: 528 parts / 3,168 textures, the video's 4 IDs load, and UNDO restored all 528 colours.
- `retro_highlight`: an Occluded outline on the player's fish, visible in the screenshot.
