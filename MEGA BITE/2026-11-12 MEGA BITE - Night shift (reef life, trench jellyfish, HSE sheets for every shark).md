---
date: 2026-11-12
tags: [megabite, world, life, models, hse, night-shift]
status: built in Studio + checked in Play. Not published. HSE sheets waiting for the owner's OK.
---
# MEGA BITE night shift (11 Nov 23:26 → 12 Nov)

Owner 23:26: "ok sure lets do the changes now!!" (the life pass + the HSE models for the other creatures). Owner rule: after midnight Claude continues on autopilot.

## 1. World life: `StarterPlayerScripts.MB_ReefLife` (client only, no server cost)
Research: the polish bible says "behaviour is what makes the sea feel alive".
- **Ambient schools:** 16 bait-ball schools (9 reef, 7 trench), Sardine and Damsel meshes at 0.8–0.85x scale, 240 fish in total.
  - They use boids: cohesion, alignment, full separation inside the school, a goal that wheels slowly around the school's anchor, and a soft floor.
  - They burst away from any shark (FLEE_SPEED 30) and regroup afterwards.
  - Each fish has a tail wiggle that speeds up while fleeing.
  - They only update within 260 studs of the camera, using BulkMoveTo.
  - They are scenery: CanQuery and CanTouch are off. The edible fish are still the server's.
- **Kelp and sea fans sway:** all kelp (7°) and sea fans (3°) pivot from the base in a travelling current.
  - Plants within 170 studs update in thirds (round robin).
  - Plants register as they stream in and drop out when they stream out.
- **Trench jellyfish:** 16 jellies, scale 0.7–1.4, in 3 colour sets (violet/magenta, blue/teal, rose/amber), 22–55 studs above the trench floor.
  - The swim pulse: the bell squeezes (12% of a 2.6–3.6 s cycle), the jelly jets up about 1.7 studs, then relaxes and sinks.
  - The tentacles and arms lag and sway behind.
- **Streaming lesson:** with StreamingEnabled, terrain isn't on the client at startup. A raycast then misses (the first schools spawned under the sand), so every school or jelly finds its height only once the terrain near it has loaded.
- **ScaleTo lesson:** `Model:ScaleTo` is ABSOLUTE. Scale a clone by `m:ScaleTo(m:GetScale()*k)`. Otherwise an imported model goes back to its import size (the 850-stud jelly).
- Config hooks: `C.ReefLife` (Enabled, LiveRadius, PlantRadius, Species, ReefSchools, TrenchSchools, Speed, FleeSpeed, KelpDeg, FanDeg, Jellies, JellyColours). Everything defaults when it's not set.

## 2. Trench jellyfish model (our own, by code)
- Script `MEGA BITE/Art/Jellyfish/jelly.py` (bpy in the cloud workspace), with an FBX and a preview render.
- Parts and materials:
  - Bell: a scalloped double shell, 16 lobes, translucent SmoothPlastic 0.5.
  - Rim: a wavy neon frill.
  - Core: a four-leaf neon heart.
  - Arms: 4 ruffled oral-arm ribbons.
  - Tentacles: 16 thin wavy tubes.
  - The FBX is 5.6K triangles; every part is DoubleSided.
- Asset 115922963669452 (group 33151111) → `ReplicatedStorage.MegaBite.Creatures.Jelly`, with a 10-stud bell, the pivot at the bell and the PivotOffset cleared (the FBX import had a -90° pivot).
- Neon lesson: bright cyan Neon blooms into a white blob under our ColorCorrection. Keep neon to small parts in deep, saturated colours, with Transparency 0.25–0.35.

## 3. Hungry Shark-style sheets for every shark (waiting for the owner)
- How they were made: in ChatGPT, every sheet had TWO attachments.
  1. The approved Megalodon HSE sheet (`Art/HSE_refs/style_megalodon_hse.png`) as the style.
  2. That shark's own v1 sheet (`Art/HSE_refs/v1_<shark>.png`) for its identity.
- Sheets are in `Art/HSE_sheets/`; the review board is `MEGA_BITE_HSE_shark_sheets.jpg`.
- Shared prompt (one try worked for 4 of 5):
  > Create ONE image, 1536x1024. Flat solid MAGENTA #FF00FF background, no gradient, no shadow on it, no magenta or pink-purple anywhere in the art. A character turnaround sheet of ONE sea creature for a mobile game, orthographic views, in EXACTLY the same layout as the FIRST attached image: TOP ROW the side view (nose pointing right, gentle swimming pose, the whole body); BOTTOM LEFT the top view seen from directly above, the same length, directly under the side view, nose pointing right; BOTTOM RIGHT the front view facing the viewer with the mouth open. Wide empty magenta space around each view; no view touches another view or the image edge. STYLE: match the FIRST attached image exactly (that is our approved Megalodon): a smooth, muscular, semi-realistic cartoon body (NOT low-poly, NOT faceted), a big powerful head, a wide permanent toothy grin with big white triangular teeth, pink gums and a dark red mouth inside, ROUND glowing pupils (never slit eyes) under a heavy angry brow, a clean countershade line, subtle skin texture, a thin dark outline, soft studio light, premium mobile-game polish. IDENTITY: the SECOND attached image is the old version of THIS creature; keep its colours, body proportions, fin layout and personality, but redraw it in the new style. <identity line> NO text, NO letters, NO numbers anywhere, NO blood, NO wounds, NOT a photo.
- Identity lines:
  - **GW:** slate-grey with a slight blue tint, a jagged countershade line, one notch in the dorsal fin, NO glowing cracks or claw scars (only the Megalodon has those), "the Megalodon's younger cousin".
  - **Reef:** slimmer, slate-blue, black fin tips, a smaller and cheeky grin.
  - **Hammer:** teal, a wide flat T hammer with an eye at each tip, dots on the hammer.
  - **Barracuda:** a long torpedo, silver-blue, diagonal stripes, a needle-tooth underbite, a golden eye.
  - **Piranha:** deep and round, blue-grey back, red-orange belly and fins, an underbite.
- **Hammerhead first try failed the 3D-consistency check:** the side view drew the hammer as a long tube, and the top-view hammer was narrower than in the front view.
  - Fix prompt: "the hammer is a FLAT, WIDE T-shaped wing ... SIDE VIEW: seen edge-on, only slightly longer than a normal snout ... TOP VIEW: a clear wide T-bar exactly as wide as in the front view".
  - v2 passes (`mb_hse_hammer_v2.png`).
- Next once the owner says yes: build each in FishKit (as with `megah/cfg.py`), check it against its sheet, back up the v1 and install with `MB_InstallV2`.
