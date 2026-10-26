---
date: 2026-10-27
tags: [gymarc, prompt]
status: todo
---
# 67 Optimization pass

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Optimization pass (owner, 27 Oct). Live numbers: players' FPS 31 (down 10%), server memory 543 MB (up 218%). Known: ~24,000 parts, 421 lights, 681 SurfaceGuis, StreamingTargetRadius 256. Goal: smooth on phones WITHOUT making the game look worse. Follow CLAUDE.md Speed rules. Never undo the owner's manual Studio changes. Back up before big changes; File > Save to Roblox after each step (Studio is the only copy).

STEP 0: MEASURE FIRST (write the numbers in the note; repeat at the end)
- Phone emulator (667x375, graphics quality 1-3) + desktop, in 4 spots: Starter Gym, town plaza, Pro Gym (city view), Powerlifting Gym/Strongman Yard. For each: FPS, client memory (Dev Console > Memory: total + Graphics/Physics/Script/Sounds/Instances), Instance count, Render/Physics ms in the MicroProfiler.
- Server: memory and heartbeat with 1 player and with 4 test players, then a 30-60 min soak test (bots/test players training) to see if memory keeps climbing (a leak) or stays flat.
- List the 10 biggest costs you find, then fix them in this order (biggest win first).

STEP 1: STREAMING (biggest win)
- StreamingTargetRadius 256 -> 160 (try 128 too; pick the lowest that doesn't show pop-in on the main paths). Keep StreamingMinRadius small. ModelStreamingMode: big buildings Atomic so they appear whole; nothing Persistent unless it must be (list any).
- Make sure gyms, the city backdrop, the yard and the Pump Shop interior only load when near (already partly done; check all).

STEP 2: LIGHTS AND SURFACE GUIS
- 421 lights: every decorative light Shadows = false; lights inside closed buildings disabled when the player is outside (client-side by zone); a cap of ~40 active lights near the camera on low graphics (turn off the farthest ones, fade in/out). Neon parts instead of lights where a glow is enough.
- 681 SurfaceGuis: set MaxDistance on all of them (signs ~60-80 studs, small labels ~30); static signs that never change -> Decals/textures; disable SurfaceGuis in zones the player isn't in.

STEP 3: PARTS AND PHYSICS
- Every prop/decoration: Anchored, CanCollide false, CanTouch false, CanQuery false (unless it needs a prompt/raycast), CastShadow false for small props.
- Mesh props: CollisionFidelity Box (or Hull), RenderFidelity Automatic.
- Merge static decorations made of many parts into single meshes (like the city/plants/tubs done in Blender): list the 10 biggest part-count models and convert the worst ones (owner imports the files).
- No unanchored parts anywhere except things that must move (list them).

STEP 4: CHARACTERS (muscles, trainers, NPCs)
- Other players' muscles: far players (>60 studs) use the stage meshes, very far (>150) a simple body; update their muscle sizes at most every 0.5 s, only when changed.
- Trainers following players: update position at a low rate when far, hide others' trainers beyond ~80 studs (there's already a setting to hide them).
- NPC gym-goers: culled when far (check it works), animations paused off-screen.
- Auras/particles: other players' auras LOD (already exists: check), hard cap on total particles per client on low graphics, pause emitters off-screen.

STEP 5: SCRIPTS AND MEMORY
- Search for RenderStepped/Heartbeat/while-true loops that update UI or values every frame: throttle to only-when-changed or 5-10x a second.
- Anything created per rep (sounds, number popups, effects): pooled or destroyed with Debris; check nothing piles up after 500 reps.
- RemoteEvents fired every rep: batch/throttle; never send data the client doesn't show.
- Server: check every per-player table is cleaned on PlayerRemoving (the 26 Oct fixes) and nothing grows forever (caches capped). Re-run the soak test: memory must stay flat.

STEP 6: QUALITY LEVELS
- A "Graphics: Auto / Low / High" setting (Auto by device + FPS). Low = fewer lights, no shadows, fewer particles, smaller stream radius, no far city detail. Default Auto. Never change how the game plays, only how much it draws.

TARGETS: 45+ FPS on the phone emulator at quality 1-3 in all 4 spots (60 on desktop), client memory well under 1 GB on phones, server memory flat in the soak test, no visible pop-in on the main paths.
REPORT: before/after table for every spot and the server, what changed, and anything you need from me (Blender imports, settings). Progress note + update "GYM ARC - Performance" in the vault.
```
