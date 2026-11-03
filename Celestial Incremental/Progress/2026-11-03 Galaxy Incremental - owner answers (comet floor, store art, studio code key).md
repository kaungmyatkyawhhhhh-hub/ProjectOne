---
date: 2026-11-03
tags: [galaxy, comets, codes, store, badge, progress]
status: built and tested in Studio; not published, not saved (File > Save is yours)
---
# Galaxy Incremental - owner answers to the overnight questions (3 Nov, Claude Code)

From the open questions in [[2026-11-03 Galaxy Incremental - Overnight summary]].

## 1. x2 COMETS: kept "twice as many comets" + a 15 s floor
- **Owner:** keep twice as many comets (more active play). Add a floor so comets never spawn faster than one every 15 s.
- **Built:**
  - `EconConfig.Comet.MinEvery = 15`.
  - `GalaxyEconService.cometEvery` is never under 15 s, and `spawnComet` refuses a comet within 15 s of the last one, whatever moved the timer (potion, Comet Lure buy).
  - The tutorial comet (step 4) now comes back every 15.5 s instead of 12 s if it's missed.
- **Today's numbers:** a comet every 45 s, 30 s with Comet Lure, 22.5 s with the potion, 15 s with both. So the floor changes nothing now. It only stops later upgrades from stacking under 15 s.
- **Tested (Studio Play):**
  - I set the config to a comet every 3 s for the test (put back afterwards).
  - The client saw comets at 13.3 s, 28.5 s and 43.6 s: 15.2 s and 15.1 s apart.

## 2. Store art (Blender, the icon style)
- **The files:** `Downloads\galaxy_store_art\`, with copies in `Icons\rendered\store\`.
  - `pass_x2_stardust.png`: 512x512, transparent. One bold glowing gold 4-point star (the stardust star) with its orange twin behind it. The twin is the "x2", with no text.
  - `badge_alpha_player.png`: 512x512, transparent. A round gold medal with a violet face, the gold 4-point star and 3 small sparkles.
- **Both fit the circle:**
  - The badge's outer rim is about 230 px from the centre.
  - The pass's star tips are 206-216 px from the centre.
  - Roblox's round crop is 256 px.
- **Script:** `UI\galaxy_store_art.py`. To run it: `blender -b --python galaxy_store_art.py -- <out dir> [pass|badge]`.
- **For the owner to upload** (P&L Studios XP > Galaxy Incremental):
  - the game pass "x2 Stardust" image = `pass_x2_stardust.png`;
  - the badge "Alpha Player" image = `badge_alpha_player.png`.
  - Then put the 2 ids in `GameConfig`.

## 3. Tiny phone captions
- Left as they are for the alpha.
- Added to the 21 Nov update in [[2026-11-02 Galaxy Incremental - Launch plan (test, alpha, full launch)]]: "phone-only layout for UPGRADES + the tree window (captions 14 px min)". It must be done before the 28 Nov full launch.

## 4. Studio can never touch the live code list
- **`GalaxyCodeService`:** `LIST_KEY = "studio_list"` in Studio and `"list"` on live servers, the same idea as the `studio_u_` saves. Every code read, the 5-min refresh and every console command (add / disable / enable / remove) use it.
- **Tested (Studio Play, Server):**
  - The real `list` before: `[]` (empty).
  - Console `add ZZSTUDIOTEST`: the write went to `studio_list`, and the real `list` stayed `[]`.
  - Console `remove ZZSTUDIOTEST`: the real `list` is still `[]`.
  - Left behind in `studio_list`: only a `removed` marker for ZZSTUDIOTEST (Studio-only data).
- **The owner's console on a LIVE server (F9 > Server)** still changes the real list. That's how live codes are added without publishing.

## Code
- **Changed:**
  - `ReplicatedStorage.Galaxy.EconConfig`: `Comet.MinEvery`
  - `ServerScriptService.GalaxyEconService`: the floor in `cometEvery`, `spawnComet` and the tutorial comet
  - `ServerScriptService.GalaxyCodeService`: `LIST_KEY`
- **Vault copies:** `Code\friends-test\`. Checked identical to Studio (length + checksum).
- No errors in Output.
