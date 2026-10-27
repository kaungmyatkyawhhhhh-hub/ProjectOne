# SPEED ARC - rules for Claude (read this every session)

This folder is ONLY for SPEED ARC, a Roblox running simulator. It holds the same rules as [[SPEED ARC - Quick Rules]], so later sessions only need this file plus the notes the prompt names.

## Studio
- Two Studios may be open. Only ever work in the Studio named "SPEED ARC" (placeId 134701616695802).
- Call `list_roblox_studios` before the first Studio edit each session and pick SPEED ARC by name. If it has no name, stop and ask.
- Never open, change or publish the GYM ARC place (placeId 80031260599632). Never write in the vault's GYM ARC folder.

## How to read (stay fast)
- Every session: read THIS file. Do NOT read the whole vault.
- Then read ONLY the notes/sections the prompt names (e.g. "GDD section 8"). Search inside a note instead of reading it all.
- Never read the GYM ARC folder unless a prompt says to copy a specific system.

## The game
Train (tap) -> race every 3 min -> coins -> shoes / coaches / trails -> Go Pro to the next league -> Legend Laps (endless). Kids 8-14, mostly phones.

## Must-follow rules
1. **Separate game.** Notes go in `SPEED ARC\Progress\` (one per prompt) and `SPEED ARC\Features\` (one per system, kept up to date). Screenshots in `SPEED ARC\Screenshots\`.
2. **Light:** 60 FPS target on cheap phones (30 floor at graphics quality 1).
   - < 3,000 parts and < 20 lights per area; only your area's lights on; decorative lights never cast shadows.
   - No Glass material (SmoothPlastic + transparency instead). No prop shadows (CastShadow off on decoration).
   - No per-frame loops over everything: keep a short list of active things.
   - Pool effects, number popups and sounds (no new Instance per tap).
   - SurfaceGui MaxDistance always set. Particles < 300 on screen. Client memory < 600 MB.
   - After any `task.wait`/yield, check the player is still here. Disconnect what you connect. Cap caches.
   - Check FPS + memory + part count after every prompt.
3. **Premium look, not cheap / not "AI slop":** one stylized low-poly style. Blender meshes (bevelled, vertex colours, baked soft shading) for everything important; scripts + .fbx go to `Downloads\speed_arc_models\<area>\` for the owner to import. Tuned sky / Atmosphere / ColorCorrection / Bloom, Neon instead of many lights. No default plastic look, no free models.
   - Palette (Config/Palette): Speed Black #0B0D12, Carbon #171A22, Graphite #2A2F3A, Electric Blue #1E7BFF, Bright Blue #4FC3FF, Deep Blue #0E3A8A, Gold #FFC83D, Deep Gold #E09A12, White #F4F6FA, Danger Red #FF4A4A (warnings/timers only). Tracks BLUE, lane lines white, start/finish gold.
4. **Sound is a core feature:** every action gets a designed, layered sound before it's done; pitch variation ±4-6%; pooled sounds; balanced volumes; all in Config/Sounds.
5. **First 15 minutes matter most:** first tap < 15 s, first race win ~1:30, nothing confusing, no stacked popups, no shop push early.
6. **Fair kids' game:** Robux never wins a race, no paid luck, calm offers only, no real brands/people, no emojis in the UI, safe cartoon images only, owner approves every upload (upload to the GROUP).
7. **Keep it small:** build only what the GDD says; no extra systems without asking. The look (UI kit, palette, fonts) is decided in M1: reuse it.
8. **Save:** File > Save to Roblox after each task; remind the owner to keep a dated backup (File > Save to File). Test on a test save (`FreshPlayer`), never the owner's real data. Back up big world changes in ServerStorage first.
9. **Config:** every number in `Shared/Config`. Rewards = minutes of coins at your league.
10. **Report:** short progress note + phone-size screenshots + FPS numbers. List anything needed from the owner (imports, IDs).

## Code
- Source of truth is on disk: `Games\SpeedArc\src\` (this vault). Studio gets it by the sync step in `Games\SpeedArc\README.md`. Edit the files, then sync; never edit only in Studio.
- Structure: `ReplicatedStorage/Shared/Config/*` (all numbers), `Shared/UIKit`, `Shared/Util/*`; `ServerScriptService/Server/Services/*Service`; `StarterPlayerScripts/Client/Controllers/*Controller`.
- Server is the authority: coins, speed, race positions. Clients only send taps (rate limited).

## Where the details are (open only when the prompt says)
- [[SPEED ARC - Game Design Document]] (sections 1-29), [[SPEED ARC - Design plan]]
- [[SPEED ARC - World, Map and Buildings]] · [[SPEED ARC - Lighting]] · [[SPEED ARC - Audio (SFX and Music)]] · [[SPEED ARC - VFX]] · [[SPEED ARC - Customization]] · [[SPEED ARC - Update Roadmap]]
- [[SPEED ARC - Lessons from GYM ARC]] (section 10 at each new milestone)
