---
date: 2026-11-02
tags: [galaxy, map, art, quality]
status: discussing
---
# Galaxy Incremental - map design + quality (2 Nov)

Owner: "ok lets discuss the galaxy incremental map design and quality too".
Builds on [[2026-11-01 Supernova Incremental - Map plan]] (observatory hub, Supernova Core, 8 pads, look rules), [[2026-11-01 Research - Modeling like a professional (stylized low poly)]], the Regrowth lessons ([[2026-11-01 Regrowth Incremental - play log and how to play]]), Immortality worlds ([[2026-11-02 Research - Immortality Incremental and Regrowth, why players keep playing]]) and the approved UI (v12).
Concept render (Blender, by Claude): `Map\galaxy_map_concept_v1.png` (script `galaxy_map_concept.py`).

## Proposal
1. **A floating island hub in space** (Sector 1, Ember Belt): pale warm stone + brass floor, violet galaxy sky; compact (a short walk everywhere).
2. **Centre: the Supernova Core** on a brass altar with gyroscope rings; it pulses and BURSTS when anyone in the server goes Supernova (shared moment).
3. **8 player pads in a ring**: your star system floats above your pad and grows with every buy (rock -> star + planets + orbits). NEW from Regrowth: the PAD ITSELF also builds up (tycoon feeling): brass rim, pillars, a telescope, an orbit ring around the pad, banners, appear at milestones, so your place visibly grows, not just numbers.
4. **Boards are entrances, not readers** (Regrowth lesson: 3D boards were hard to read): the Upgrade board / Star Map are big framed screens showing the UI; walking up (or pressing E / tapping) opens the 2D v12 window.
5. **Locked things in view** (always a next goal): the Star Forge platform (lock, "SUPERNOVA 3"), the Black Hole gate (a brass ring with a violet void), and the NEXT SECTOR island floating across the void with a light bridge that lights up at the Ignition gate (Immortality worlds).
6. **Each sector = a new island** with its own colour and system (Comet Reach: icy blue, comets streaking; Nebula Gate: violet, the Black Hole; Ring Nebula: pink fusion island).

## Quality rules
- Same art as the icons: **low-poly faceted, glossy (clearcoat), bold colour blocks**; no realistic textures (owner rule from the planet icon).
- Warm ground vs cool sky (contrast); brass/gold = interactive; glow only on interactive or "ready" things.
- **Textures static, VFX animated**: Core pulse + rays, stardust motes flowing from your system up to your counter, comets streaking past (clickable), shockwave ring across the plaza on a Supernova, sparkles on ready pads.
- One reusable kit (~20 pieces: floor tiles, rim, pillar, ring, crystal cluster, board frame, lamp, bridge segment).
- Performance: others' systems simplified past ~60 studs, StreamingEnabled, few lights (Core + 1 per board), no glass, part budget per island, phone test (667x375).

## Concept v1 notes (what to fix in the real build)
- Pads too plain (no building-up pieces yet), horizon line visible (needs a full skydome), forge platform hidden behind the core from this angle (move it to the side), boards could be bigger.

## Concept v2 (owner, 2 Nov: "yes push the look further")
`Map\galaxy_map_concept_v2.png` (script `galaxy_map_concept_v2.py`). Added:
- **Pads that build up by tier** (tycoon feeling): bare stone (new player) -> brass rim -> 4 lamp pillars -> orbit ring -> banner in the player's colour -> telescope; the star system above grows (rock -> star + 1-6 planets with orbits), stardust motes rising, sparkles on the top pads. You can read everyone's progress from across the plaza.
- Core: three gyroscope rings, 16 spikes, a glowing SHOCKWAVE ring on the floor (the Supernova moment).
- Bigger boards (showing the v12 Upgrades + Tree windows) with a coloured beacon on top; crystal clusters framing them.
- Rim: 12 brass lamp posts; hanging crystals under the island.
- Star Forge moved to the right side (visible, blue rim, anvil with a padlock); Black Hole gate at the back left (brass ring, violet void, glowing disk).
- Next sector island (icy, locked) across the void with a light bridge; nebula clouds + star sphere + galaxy backdrop instead of a flat horizon.
Still to improve in the real build: comets streaking past (in the scene but out of this camera), the sky below the island, a spawn spot facing the Core.

## DECIDED: personal islands in a ring (owner, 2 Nov: "so players are gonna have their own island?" -> "what is a better option")
Options: (A) one shared island with 8 pads (v2 concept) vs (B) a central shared Core island + 8 small PERSONAL floating islands around it, linked by light bridges.
Decision: **B**. Reasons:
1. The game's main hook is "my place visibly grows" (Regrowth's strongest hook, our Revamp 2 core: the star system earns and grows by itself). A pad has no room to grow; an island does (bare rock -> floor -> rim -> pillars -> telescope -> crystal garden -> star system above, more pieces per sector).
2. Social stays: the Core, boards, Forge, Black Hole gate and leaderboards are on the shared centre island; everyone's island is in view around it, and the Supernova shockwave crosses all of them.
3. Ownership: a whole island with your name and colour feels like YOUR place (tycoon plots are the Roblox standard for this).
4. Performance is manageable: others' islands simplified past ~60 studs, StreamingEnabled, the same ~20-piece kit, your own island at full detail.
Next: concept v3 render of this layout.

## Check against incrementals specifically (owner, 2 Nov: "what is better choice for an incremental")
From [[2026-11-01 Celestial Incremental - 10 incrementals played]]: most top incrementals use ONE compact shared world (Immortality, Noob, Tower, Grass Cutting Inc., Faith, GIS); the tycoon-style ones give each player a plot (Regrowth, Dropper Incremental). Lessons that matter more than hub vs plot: (1) nothing far to walk (Noob's big world = minutes lost), (2) progress SHOWN on/above the player (Immortality realm over the head, GIS blade on the character), (3) locked areas visible from day 1, (4) buying through boards/menus near you.
Final answer: **personal islands, kept small and close, and you never have to walk**: spawn ON your own island; every window (Upgrades, Forge, Tree, Store) opens from the hotbar anywhere (walking to the centre is optional, for the Core moment, leaderboards and seeing others); bridges short (~10-15 studs). Your realm/rank over your head too. This keeps Regrowth's "my place grows" hook (our core) without the big-world walking problem.

## Concept v3: personal islands (owner, 2 Nov: "ok sure")
`Map\galaxy_map_concept_v3.png` (script `galaxy_map_concept_v3.py`).
- Centre island (smaller, ~22 studs across in the concept): Supernova Core, Upgrade + Tree boards, Star Forge (right), Black Hole gate (back), light bridge to the locked next-sector island.
- 8 personal islands in a ring, each linked to the centre by a short arched light bridge, at slightly different heights.
- Island tiers shown (new player -> veteran): a lone rock with a rock above it -> stone disc -> brass rim -> 6 lamp pillars -> crystal garden + green patch -> banner in your colour + outer brass ring -> telescope + brass dais; the star system above grows to 6 planets; a floating name plate in your colour.
- The Supernova shockwave ring sweeps across ALL islands (shared moment); comets streak past.
Fix in the real build: a bridge also for the bare-rock (tier 0) island, name plates with the player's name and rank, the next-sector island bridge clearer.

## Review of Claude Code's build day 1 (2 Nov; [[2026-11-02 Galaxy Incremental map build day 1]], screens `Map\screens\2026-11-02\`)
Works: layout = concept v3, island tiers 0-6, name plates with rank, every island has a bridge, shockwave across all islands, Sector 2 gate + IGNITION sign + lighting bridge, comets, 60 FPS / 1,172 parts.
Gaps vs the concept (~60% there):
1. **Sky**: the skybox images never loaded -> flat navy + Roblox's light-blue default sky band at the horizon. Biggest quality hit. Cause: uploaded under the owner's user account, not P&L Studios XP. Fix: owner uploads `Map\images\sky_*.png` to the group, ids into MapConfig.Sky.
2. **Stand-in parts** (kit not imported): rings and pillars are blocky plain parts. Fix: owner imports `Downloads\galaxy_kit.fbx` (26 pieces) into P&L Studios XP with the 3D importer into `ReplicatedStorage.GalaxyKit`.
3. **Materials / light**: brass reads as flat orange plastic, stone is pinkish, a heavy blue tint; less contrast than the concept. Fix: brass = Metal-like (gold #D9A441, a little reflectance), warm cream stone, ColorCorrection (slight warm), Atmosphere density lower, a violet rim light from behind.
4. **Bare-rock island**: the rock is a huge boulder, bigger than the finished islands. Should be a small asteroid (about half an island) so growing feels like growing.
5. **Rank text**: tiers 0-3 show "STARDUST" as the rank. Use real ranks (e.g. NEW STAR -> RISING STAR -> SUPERNOVA n).
6. **Banners** are plain tall boxes: should be cloth banners (kit Banner mesh) on a pole.
7. Not done yet: phone view, 8 real players FPS, the v12 UI in this place.

## Review of pass 2 (2 Nov, screens `Map\screens\2026-11-02-pass2\`): ~80% of the concept
Fixed: galaxy skybox shows (Up/Dn faces still to re-upload), kit meshes in, ranks NEW STAR / RISING STAR / SUPERNOVA n, small tier-0 asteroid, cloth banner, phone view taken, side-by-side with the concept.
Still to do:
1. **Islands look like flat discs**: the concept's rocky cone underside + hanging crystals are what make them read as FLOATING islands. Add the kit IslandUnder (rock cone, ~1x the radius deep) + 2-3 hanging crystals under every island tier >= 1 and the centre.
2. **Flat empty island tops**: add an inlay pattern (brass ring + wedge tiles in a second stone tone, like the concept's floor) so tops aren't blank.
3. **Sky shapes**: the far nebula pieces read as hard dark triangles: remove them or make them big soft ones; the skybox already does the job.
4. **Light beam** under each star system is too thick and white up close (phone view): thinner, violet, fade to transparent at the bottom.
5. Colours: stone a bit less peach (cream #E8DCC8), brass a bit deeper gold (#C9902E) so it's not orange.
6. Re-upload sky Up/Dn faces to P&L Studios XP.

## Review of pass 3 (2 Nov, screens `Map\screens\2026-11-02-pass3\`): ~90%, good enough for the friends test
Fixed: rocky undersides + hanging crystals (they read as floating islands now), brass inlay + tile wedges on the tops, thin violet beams, cream stone / deeper gold brass, sky OK.
Small polish for later (not blocking): the centre's bloom/glow is a bit blown out (the Core + boards wash into one yellow blob from far: lower Bloom intensity or the Core's light range); the Sector 2 bridge reads as a ladder from above (solid deck with brass edges).
Next: the game itself (economy, Upgrades window in the v12 style, tutorial steps 1-4) for the 8 Nov friends test.

## Studio check by Claude (2 Nov night, place 111654682859982, Edit mode, read-only)
OK: centre floor now 94 studs across (enlarged; note MapConfig.Centre.Radius still says 27.5 - stale), both boards double-sided + 3 ClickDetectors + prompt, leaderboard wall double-sided, Sector 2 signs double-sided, no Highlights/SelectionBoxes, sky ids set (Up/Dn/Ft/Bk), StreamingEnabled, 308 parts in the map, no errors in the output.
To fix:
1. STAR FORGE + BLACK HOLE signs: their text faces INWARD (toward the Core) = CORRECT for the bigger plaza (owner, 2 Nov: "arent star forge and black hole signs suppose to face inwards?" - yes, players stand in the plaza). Keep inward; optionally add the same text on the back for players arriving from the nearest bridge. Make them 2x bigger (7.4 wide is small).
2. Star Forge: the padlock floats ~5.6 studs above the anvil, not attached; put it on the anvil's front face.
3. Black Hole void: reads as a flat black disc with one thin white arc; the swirl needs to be visible (2-3 spiral arms, violet/pink, slowly turning) + a soft inner glow.
4. Small text everywhere (IGNITION checklist, arch "SECTOR 2: COMET REACH", leaderboard title): readable from ~30 studs.
5. MapConfig.Centre.Radius = 27.5 doesn't match the 94-stud floor: update the config so code and map agree.
6. Bridges at edit time are dark navy ribbons leading to nothing (islands only exist at runtime). Check in play: an UNCLAIMED slot must still show a bare rock (or hide its bridge), never a bridge into space.
7. Plaza is big and empty between zones now: small details (benches, a star-chart floor inlay, crystal clusters by the rim) - low priority.
Screens: `Map\studio_check_back.jpg`, `Map\studio_check_sector.jpg`.
