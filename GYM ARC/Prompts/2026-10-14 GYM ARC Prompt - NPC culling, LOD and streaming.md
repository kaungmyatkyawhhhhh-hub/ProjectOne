---
date: 2026-10-14
tags: [gymarc, prompt, performance]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: NPC culling, LOD and instance streaming (14 Oct)

```text
PERFORMANCE: Culling & LOD for NPCs + Instance Streaming. Mobile is the target. Save this prompt to Obsidian first. Measure BEFORE you change anything (MicroProfiler / Stats: FPS, memory, ping, instance count, draw calls) on a phone emulator with ~10 NPCs and a few players, and write the numbers in PROGRESS.md.

1. DISTANCE CULLING (one NPC manager, not a loop per NPC)
   - One central NPC manager (client-side for visuals, server for logic) that updates NPCs in tiers by distance from the local camera:
     - Near (< 40 studs): full update. AI every frame or 0.1s, all animations, aura VFX, name tags.
     - Mid (40-100): AI every 0.5s, only the main animation (idle/lift), no aura particles, no facial or extra layers.
     - Far (> 100) or off-screen: AI every 2s or paused, animations stopped (freeze on idle pose), no VFX, no billboards.
   - Off-screen check with Camera:WorldToViewportPoint + a small margin, so NPCs behind the camera are treated as far.
   - Server-side NPCs (trainers following players, rival, gym NPCs): only simulate pathfinding/AI when a player is within 120 studs. Otherwise park them. Set network ownership correctly (server or nearest player), and anchor parked NPCs.
   - Trainers that follow a player keep updating for THAT player (never freeze your own trainer).
   - Spread updates over frames (round-robin, max N NPCs per frame) so there are no FPS spikes.

2. LOD (simplified models)
   - For each NPC type, make a low-detail version: no accessories (or merged into one mesh), the lowest muscle stage mesh or a simple R15 body, no aura layers, no clothing layers.
   - Swap to it at > 60 studs, and back at < 50 (a hysteresis gap so it doesn't flicker). Swap by toggling visibility / Parent, not by cloning every time (keep a cache).
   - Set MeshPart.RenderFidelity = Automatic and CollisionFidelity = Box on all decorative meshes. CastShadow = false on small props and NPC accessories.
   - Aura VFX: fewer particles (Rate scaled down) on mid, off on far. Reduce the max total aura emitters on mobile.
   - Do NOT LOD the local player or anyone you're arm wrestling, posing against or spotting.

3. INSTANCE STREAMING
   - Workspace.StreamingEnabled = true. StreamingTargetRadius ~ 256, StreamingMinRadius ~ 64, StreamOutBehavior = Opportunistic, StreamingIntegrityMode = PauseOutsideLoadedArea.
   - ModelStreamingMode:
     - Persistent: anything the client must always have (spawn area, the player's plot/home, the lobby, UI-linked world objects).
     - Atomic: each machine model, the arm wrestling table, posing stage, smoothie bar, NPC models (load as one piece, never half).
     - Default for decoration.
   - Before every teleport (Pro Gym, zones, competitions), call player:RequestStreamAroundAsync(targetPosition) on the server first, so players don't fall through or teleport loop.
   - AUDIT EVERY CLIENT SCRIPT: no workspace.X.Y direct paths for streamed parts. Use WaitForChild with a timeout, ChildAdded/DescendantAdded, or CollectionService tags (GetInstanceAddedSignal/RemovedSignal) for machines, signs, ProximityPrompts and NPCs. Handle parts disappearing (StreamOut) without errors.
   - Server scripts are unaffected, but anything the server sends to the client as an Instance reference may be nil on the client. Handle that.

4. TEST
   - Walk the whole map on a phone emulator (and a real phone if possible): every machine, the arm wrestling table, posing, Pro Gym teleport, smoothie bar, trainers, genetics stage. Everything still works, no errors in output, no missing prompts.
   - Join with low graphics quality too.
   - Measure again (same scene as before) and put before/after numbers in PROGRESS.md.
   - If anything breaks because of streaming and can't be fixed cleanly, tell me what and why instead of turning streaming off silently.

Commit after each step (culling, LOD, streaming), update PROGRESS.md and Obsidian.
```
