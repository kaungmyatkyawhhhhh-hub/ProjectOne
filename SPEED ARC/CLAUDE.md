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
**Final (owner, 28 Oct): no more pivots.** "+1 SPEED every step" + the wall course + **LIVE RACES every 3 min** (our difference from other +1 games, and the star of the game). Run -> every step +1 SPEED -> smash walls for coins -> shoes / coaches / trails -> smash the last wall = Go Pro to the next world. The race card and the podium are the most exciting moments, and race wins give the best rewards. Treadmills = AFK steps. See [[SPEED ARC - Wall Course and Steps]], [[SPEED ARC - Races]]. Kids 8-14, mostly phones.

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
   - Palette (Config/Palette), **bright candy look since 28 Oct (owner)**: Speed Black #1C2A7A (deep indigo), Carbon #3557E8 (royal blue panels), Graphite #2A3FA8, Electric Blue #24A8FF, Bright Blue #6FDDFF, Deep Blue #1B3E9E, Gold #FFD23F, Deep Gold #FF9F1C, White #FFFFFF, Danger Red #FF4D6D (warnings/timers only), plus Mint #3DDC97, Pink #FF6FB5, Purple #9B5DE5, Orange #FF8A3D, Sky #4DB8FF, Lime #7ED957, Cream #FFF3DC. No black or dark-grey walls. Big open spaces, giant floating zone names, few small props. Tracks BLUE, lane lines white, start/finish gold.
4. **Sound is a core feature:** every action gets a designed, layered sound before it's done; pitch variation ±4-6%; pooled sounds; balanced volumes; all in Config/Sounds.
5. **First 15 minutes matter most:** first tap < 15 s, first race win ~1:30, nothing confusing, no stacked popups, no shop push early.
6. **Fair kids' game:** Robux never wins a race, no paid luck, calm offers only, no real brands/people, no emojis in the UI, safe cartoon images only, owner approves every upload (upload to the GROUP).
7. **Keep it small:** build only what the GDD says; no extra systems without asking. The look (UI kit, palette, fonts) is decided in M1: reuse it.
8. **Save:** File > Save to Roblox after each task; remind the owner to keep a dated backup (File > Save to File). Test on a test save (`FreshPlayer`), never the owner's real data. Back up big world changes in ServerStorage first.
9. **Config:** every number in `Shared/Config`. Rewards = minutes of coins at your league.
10. **Report:** short progress note + phone-size screenshots + FPS numbers. List anything needed from the owner (imports, IDs).

## Modelling like a human artist (owner, 28 Oct)
Every Blender mesh must look hand-made, not like stacked default cubes:
- **Round every edge:** Bevel modifier on everything (2-3 segments, width scaled to the object: ~0.03-0.08 studs on props, more on big shapes), Weighted Normal / Auto Smooth so flat faces stay flat and edges catch light. No razor-sharp default-cube edges anywhere.
- **Cutouts and detail cuts:** inset panels, grooves, panel lines, chamfered corners, recessed screens, holes in frames (e.g. the arch truss has real cut-out triangles, benches have slats with gaps, shop fronts have window frames and sills, treadmills have a recessed belt and side rails).
- **Natural look:** nothing perfectly straight or identical: tiny random rotation/scale on repeated props (trees, rocks, fans, cones), slightly uneven rocks and tree trunks, soft wear on corners, small asymmetry. Organic things (trees, rocks, bushes, hills) are sculpted / displaced shapes, never spheres or cubes.
- **Shading with vertex colours:** 2-3 tones per material (base, lighter edge highlight on bevels, darker ambient occlusion in corners and gaps), baked, so it reads well without real lights.
- **Silhouette first:** every object must be recognizable as a black shape. Add the details that change the outline (rails, handles, overhangs, trims), skip tiny details that cost triangles but don't show.
- **Still light:** keep triangle budgets (props ~200-2,000 tris, buildings ~3-8K), merge small parts into one mesh, reuse the shared kit. Detail comes from bevels, insets and colour, not from millions of triangles.
- Before handing over .fbx files: render a quick preview of each model (3/4 view) and look at it. If it looks blocky, plain or "AI generated", improve it first. Put the previews in `SPEED ARC\Screenshots\models\`.

## UI is designed art, not placeholders (owner, 28 Oct)
- Plain coded buttons (rectangle + gold gradient + UIStroke) are placeholders and NOT accepted.
- The UI kit is 9-slice PNG art: buttons with meaning-colours (green buy/go, blue normal, yellow claim, red close, grey locked) + pressed state, panels, tabs, tiles, pills, badges; 3D lip, inner highlight, soft shadow, navy outline, an icon on every main button.
- Mockup at 667x375 shown to the owner before applying. Once approved the kit is LOCKED: every new screen reuses it.
- No pink, purple, cream or pastels: bold sporty colours (prompt 12).

## Code
- Source of truth is on disk: `Games\SpeedArc\src\` (this vault). Studio gets it by the sync step in `Games\SpeedArc\README.md`. Edit the files, then sync; never edit only in Studio.
- Structure: `ReplicatedStorage/Shared/Config/*` (all numbers), `Shared/UIKit`, `Shared/Util/*`; `ServerScriptService/Server/Services/*Service`; `StarterPlayerScripts/Client/Controllers/*Controller`.
- Server is the authority: coins, speed, race positions. Clients only send taps (rate limited).

## Where the details are (open only when the prompt says)
- [[SPEED ARC - Game Design Document]] (sections 1-29), [[SPEED ARC - Design plan]]
- [[SPEED ARC - World, Map and Buildings]] · [[SPEED ARC - Lighting]] · [[SPEED ARC - Audio (SFX and Music)]] · [[SPEED ARC - VFX]] · [[SPEED ARC - Customization]] · [[SPEED ARC - Update Roadmap]]
- [[SPEED ARC - Lessons from GYM ARC]] (section 10 at each new milestone)
