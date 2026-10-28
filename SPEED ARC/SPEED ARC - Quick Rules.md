---
date: 2026-10-28
tags: [speedarc, rules]
status: living document
---
# SPEED ARC - Quick Rules (READ THIS ONLY, then only what the prompt names)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How to read (stay fast)
- Every session: read THIS note (and CLAUDE.md, which holds the same rules). Do NOT read the whole vault.
- Then read ONLY the notes/sections the prompt names (e.g. "GDD section 8"). Use search inside a note instead of reading it all.
- Big milestone prompts may name more; small fixes need nothing else.
- Never read the GYM ARC folder unless a prompt says to copy a specific system.

## The game
SPEED ARC: Roblox running simulator. **Since 28 Oct: "+1 SPEED every step".** Run -> every step +1 SPEED -> smash walls on the wall course for coins -> shoes / coaches / trails -> smash the last wall = Go Pro to the next world -> Legend Laps (endless). Treadmills = AFK steps, races every 3 min = an event. No tap training. Bright candy colours. Source of truth for the loop: [[SPEED ARC - Wall Course and Steps]]. Kids 8-14, mostly phones.

## Must-follow rules
1. **Separate game.** Never touch the GYM ARC place or the GYM ARC vault folder. Notes go in SPEED ARC\Progress and SPEED ARC\Features.
2. **Light:** 60 FPS target on cheap phones. < 3,000 parts and < 20 lights per area, only your area's lights on, no Glass, no prop shadows, no per-frame loops over everything, pool effects/sounds, SurfaceGui MaxDistance.
3. **Premium look, not cheap / not "AI slop":** stylized low-poly Blender meshes (bevelled, vertex colours, baked shading), palette black + blue + gold (blue tracks, gold winners), tuned sky/Atmosphere/colour grading.
4. **Sound is a core feature:** every action gets a designed, layered sound before it's done; pitch variation; pooled sounds; balanced volumes.
5. **First 15 minutes matter most:** first step < 15 s, wall 1 smashed < 45 s, first race win ~1:30, nothing confusing, no popups stacked, no shop push early.
6. **Fair kids' game:** Robux never wins a race, no paid luck, calm offers only, no real brands/people, safe cartoon images only, owner approves every upload (upload to the GROUP).
7. **Keep it small:** build only what the GDD says; no extra systems without asking. Decide the look once (UI kit in M1) and reuse it.
8. **Save:** File > Save to Roblox after each task; remind the owner to keep a dated backup file. Test on a test save, never the owner's real data.
9. **Config:** every number in Config. Rewards = minutes of coins at your league.
10. **Report:** short progress note + screenshots (phone size) + FPS numbers. List anything you need from the owner (imports, IDs).

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

## Where the details are (open only when the prompt says)
- [[SPEED ARC - Game Design Document]] (numbers, systems, sections 1-29)
- [[SPEED ARC - World, Map and Buildings]] · [[SPEED ARC - Lighting]] · [[SPEED ARC - Audio (SFX and Music)]] · [[SPEED ARC - VFX]] · [[SPEED ARC - Customization]] · [[SPEED ARC - Update Roadmap]]
- [[SPEED ARC - Lessons from GYM ARC]] (read sections named by the prompt; section 10 at each new milestone)
