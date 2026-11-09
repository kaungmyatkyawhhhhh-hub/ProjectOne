---
tags: [brain, knowledge, tech, performance, tools]
updated: 2026-11-09
---
# K07 Tech, performance and tools
Back to [[00 BRAIN]] · Sources: [[Playbook notes - Performance, data and security]], [[Playbook notes - Optimization deep dive]], [[Playbook notes - Game quality and QA]], [[Video editing tools (Claude workspace)]], [[2026-11-03 Blender MCP on the owner's PC vs cloud Blender]]

## Performance (cheap Android phones are most players)
- Targets ~1,000 draw calls, ~1M triangles, 16.7 ms/frame. Most lag is DRAWING the world: NPCs on screen, see-through parts, particles, SurfaceGuis, lights, shadows. No Glass. Lights only in your area. SurfaceGui MaxDistance always.
- Never loop over everything every frame; never rebuild a character often; fade only visible UI; preload during loading; soak-test 30-60 min for leaks.

## Data and security
- ProfileStore (session lock); save on leave/shutdown/purchase; a save version + forward-safe migration; never roll a place back past a version bump.
- Server decides everything; check every remote (types, isfinite, rate limits); grant products only in ProcessReceipt, save first, never twice.
- Protect leaderboards/statues with plausibility checks (but check the maths first: GYM ARC's ★84 player was legit thanks to the 2× pass + uncapped stars).
- Test switches only work in Studio; check none are on before publishing.

## Streaming
- StreamingEnabled + ModelStreamingMode Atomic made players fall through their island. Fix: RequestStreamAroundAsync before teleports, AddPersistentPlayer, StreamingIntegrityMode (PauseOutsideLoadedArea, set by hand in Studio).

## Our tool stack
- **Claude Code + Roblox Studio MCP**: Studio is the source of truth; pick the Studio by NAME (list_roblox_studios); one prompt = one goal + a report; the owner tests and publishes.
- **Cowork (this Claude)**: research, prompts, art processing, video, Creator Hub via Chrome, the vault. Night shift scheduled tasks.
- **Creator Hub APIs**: assets `apis.roblox.com/assets/user-auth/v1/assets` (multipart, groupId, csrf from the 403), thumbnails `publish.roblox.com/v1/games/{universeId}/thumbnail/image`.
- **Video**: ffmpeg, Remotion (local Chromium), HyperFrames (vendored GSAP), Whisper (faster-whisper, pass arrays), librosa, EarShot (rank/critique). Sounds: Freesound (CC0, via the owner's PC), Openverse.
- **Blender MCP** on the owner's PC (also used for big file transfers and blocked downloads).
- **Big files** over 400 MB: split on the PC, stage, join.
