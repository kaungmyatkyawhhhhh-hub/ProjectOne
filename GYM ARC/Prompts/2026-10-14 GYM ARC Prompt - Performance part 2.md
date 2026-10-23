---
date: 2026-10-14
tags: [gymarc, prompt, performance]
status: done (phone / 10-player numbers: owner)
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: performance part 2, optimize everything else (14 Oct)

```text
PERFORMANCE PART 2: optimize everything else. Mobile first. Save this prompt to Obsidian.
Rule: MEASURE FIRST. Use MicroProfiler, Developer Console (Memory, Scripts, Network tabs) and Stats on a phone emulator with 10+ players simulated. Make a top-10 list of the biggest costs in PROGRESS.md, fix them in that order, and re-measure after each fix. Don't change anything that doesn't show up as a cost.

1. MAP / RENDERING
   - Count parts. Merge static decoration (walls, floor tiles, trim, posters, plates on racks) into fewer MeshParts or unions where it's safe. Target: as few draw calls as possible in the main gym.
   - Every static part: Anchored = true. Decorative parts: CanCollide = false, CanTouch = false, CanQuery = false.
   - CastShadow = false on small props, plates, dumbbells, wall decor, signs.
   - Reuse the same meshes and textures (same MeshId/TextureID = drawn together). Remove duplicate textures and downscale textures to 512 or 256 where nobody looks closely.
   - Lights: limit how many PointLights/SpotLights have Shadows = true (ideally 0-2). Remove lights nobody can see.
   - Lighting: check Technology (Future is expensive on phones; use ShadowMap or Voxel if it looks almost the same). Keep post effects (Bloom, ColorCorrection, SunRays, DepthOfField) few and light.
   - Delete hidden/unused stuff in Workspace (old parts, duplicate models, debug parts). Move unused things to ServerStorage.

2. EFFECTS / AURAS / VFX
   - Particle budget: cap the total particles on screen. Lower Rate and Lifetime on mobile. Turn off aura layers for other players beyond 40 studs.
   - Use one ParticleEmitter with more particles instead of many emitters where possible.
   - Pump/rep popups and number effects: pool and reuse them (no Instance.new every rep). Destroy anything temporary.
   - Auto quality: read UserSettings().GameSettings.SavedQualityLevel / the device's graphics level, and scale VFX down on low settings. Add a "Low Effects" toggle in Settings.

3. SCRIPTS
   - Find every while true / Heartbeat / RenderStepped loop. Remove ones that don't need to run every frame (use events or a 0.2-1s timer instead).
   - One central loop per system instead of one script per machine/NPC/part (e.g. one MachineManager with CollectionService tags, not a Script inside every machine).
   - Memory leaks: disconnect connections when players leave, machines stream out, or UI closes. Use a Maid/Janitor-style cleanup. Check memory goes back down after a player rejoins 5 times.
   - Cache FindFirstChild/WaitForChild results, don't look things up every frame.
   - Muscle stage mesh swaps: only swap when the stage actually changes, never every rep.

4. NETWORK
   - Throttle and batch RemoteEvents. Reps must not fire a remote every tap at full speed with no limit (the server should rate-limit; this also stops exploiters). Batch stat updates (e.g. send once per 0.25-0.5s).
   - Only send changed values. Use UnreliableRemoteEvent for cosmetic stuff (pump popups, aura pulses, effects).
   - Don't replicate big tables every update. Use attributes or small deltas.
   - Auto Rep for many players at once: run it on a shared server tick, not a loop per player.
   - Leaderboards: update every 60s, not constantly.

5. UI
   - Don't update hidden GUIs. Stop their loops while closed.
   - Build panels once and show/hide them (don't destroy and rebuild on every open).
   - Number labels (coins, strength) only update text when the value changes.
   - Remove unused ScreenGuis and images. Use one image per icon set where possible.

6. SOUND
   - Music: one Sound streaming, not several playing at volume 0. Grunts/screams/rep sounds: pool them, cap how many play at once (e.g. max 6 nearby), and only play them for players within ~50 studs.

7. SERVER / DATA
   - DataStore: save on leave + every 3-5 minutes + BindToClose, never on every rep. Use UpdateAsync, handle throttling with retries.
   - Watch server memory and heartbeat with a full server (Developer Console > Server). No server script > a few % of the frame.

8. TEST + REPORT
   - Before/after table in PROGRESS.md: client FPS (phone emulator), client memory, server heartbeat, network in/out KB/s, part count, draw calls.
   - Play the full loop (spawn, lift, auto rep, arm wrestle, posing, Pro Gym teleport, shop, genetics) after every step: nothing broken, no errors in Output.
   - Tell me anything you decided NOT to change and why.

Commit after each section, update PROGRESS.md and Obsidian.
```
