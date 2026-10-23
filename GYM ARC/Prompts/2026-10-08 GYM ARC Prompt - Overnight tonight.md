---
date: 2026-10-08
tags: [gymarc, prompt]
status: done
source: GYM_ARC_overnight_tonight.md
---
# 2026-10-08 GYM ARC Prompt - Overnight tonight

Back to [[00 GYM ARC Home|GYM ARC Home]]. Saved exactly as sent (original file: `GYM_ARC_overnight_tonight.md`).

OVERNIGHT RUN. I'm asleep, so don't ask me anything; make sensible choices and write them down. Work in order. After EACH task: test in Studio (play solo, and check phone size), check Output for errors, run the test suites, take screenshots into the screenshots folder, export changed scripts to src/, update PROGRESS.md and commit. If something is blocked, write why in PROGRESS.md and move on.
Rules: kids' game, mostly played on mobile. No emojis in the UI, no grunts, no real people, brands or copyrighted art. Monetization stays OFF. Keep it simple: no new menus, no new currencies, no new systems; reuse what already exists. Every new number goes in Config. Sounds: leave empty SoundId fields with a comment (I pick the IDs myself).

====================================================================
TASK 1. Forearms and Calves muscles (the cause is the 8 live EditableMesh limit; see "Limits" in PROGRESS.md)
Your character uses all 8 EditableMeshes, so there's nothing left for forearms and calves. Fix it in two parts:

A) Free up EditableMeshes. Merge every muscle mesh on the SAME body part into ONE EditableMesh:
   - UpperTorso: front torso + back + snatched upper torso = 1 mesh (keep the per-muscle growth, blend, highlight and flash by keeping per-vertex muscle ids)
   - LowerTorso: 1 mesh
   Your character should then use about 6 instead of 8. Write the new count in PROGRESS.md. Nothing may look different.

B) Forearms and Calves use STATIC stage meshes, so they need no EditableMesh:
   - C:\Users\kaung\Downloads\limb_stages\ has 28 OBJs: 4 meshes x 7 stages (g 0, 0.2, 0.4, 0.6, 0.8, 1.0 and mass monster). It also has stages.json, which lists the files and g values.
   - They are in part-local studs like muscle_v8, with the same UVs (classic Shirt/Pants template).
   - Import them as MeshParts (bulk import). Show the stage nearest to the displayed look g (after the Look Balance cap). When the stage changes, cross-fade the two stages over 0.3 s with Transparency.
   - Weld them to LowerArm/LowerLeg. They follow golden ratio and Growth Spurt rescaling by scaling with the part's size.
   - Clothing: use the same second-textured-part trick the other muscles use (or set TextureID from the Shirt/Pants template image if that works from a script). Long sleeves cover the forearms; shorts don't cover the calves.
   - The rep flash and the Stats hover highlight work on them too (Color/Highlight on the MeshPart is fine).
   - NPCs, mirrors and the statue also get them. Static MeshParts have no limit.
   - If you CAN'T import meshes from Studio yourself: wire everything to placeholder asset ids in Config/LimbStages, and write the exact upload steps for me in the morning report.
Screenshots: Forearms and Calves at 0, 50%, max and mass monster, front and back.

====================================================================
TASK 1B. SHOULDERS WIDEN WITH MUSCLE (like the hips)
Tall players currently start with wide shoulders. Change it so the shoulders start narrow and get wider and wider as the player grows, the same way the hips work.
- In C:\Users\kaung\Downloads\muscle_v8, manifest.json growth_spurt_width shoulders is now: skinny 0.4, maxed 1.15, mass monster 1.4. PROMPT.md has the UPDATE "shoulders widen with muscle when tall". Use factor = 1 + k*(s-1).
- Blend smoothly from skinny to maxed by overall muscle progress (every level, no jumps). Blend from maxed to monster during the transformation. Use the same blend code as the hips.
- UpperTorso width and the arm X positions use it. The arms stay attached by their inner edge, with no floating or gaps.
- The genetics Frame multiplier (Narrow 0.9, Average 1.0, Wide 1.1, V-Taper 1.2) stays on top.
- Shoulders must always stay wider than the hips.
- Compare with preview_shoulders.png.
Screenshots: a 7'0" player at level 0, halfway, max and mass monster, front view.

====================================================================
TASK 1C. LOOK BALANCE CAP: ONLY INSIDE EACH MUSCLE GROUP (replaces the current rules)
The current cap is too extreme. Replace ALL the current rules in Config/LookBalance with this simpler one:
- Muscles are only compared with the other muscles in their OWN group. Use the game's existing 6 groups (Chest, Back, Shoulders, Arms, Legs, Core), with the same member lists the genetics and stats already use, e.g.:
  - Chest: Upper Chest + Mid Chest
  - Shoulders: Front, Side and Rear Delts
  - Arms: Biceps, Triceps and Forearms
  - Legs: Quads, Hamstrings, Glutes and Calves
  - etc.
- Delete the cross-group rules: no Chest vs Back, no Traps vs Shoulders, no upper body vs legs. Training only Chest grows Chest fully; Back doesn't hold it back.
- The rule is measured in real bulge size (studs the muscle sticks out from the skin, from the mesh data at its current look):
    cap_studs = max(groupmate_studs + MAX_GAP, groupmate_studs * MAX_RATIO)
  with MAX_GAP = 0.15 studs and MAX_RATIO = 1.5, both in Config so I can tune them. "groupmate" is the SMALLEST other muscle in the same group.
  Examples:
  - Upper Chest can stick out at most 0.15 studs more than Mid Chest (or 1.5x Mid Chest once both are big), and Mid Chest the same vs Upper Chest.
  - Biceps vs Triceps the same way.
  - Front Delts vs Side Delts vs Rear Delts the same way.
- Convert cap_studs back to a look value for that muscle, then DISPLAYED = smooth-min(RAW, cap). The minimum is the base shell.
- Keep the lock icon, the held-back bar, the hint (name the groupmate, e.g. "Train Mid Chest to unlock") and the rep flash when a cap lifts. Show the one-time toast only when a muscle is held back by more than 0.05 studs.
- Update tests/lookbalance for the new math.
Screenshots: only Upper Chest maxed (capped at Mid Chest + 0.15 studs), then both chest muscles maxed, and only Biceps maxed.

====================================================================
TASK 2. TRENDY GYM FITS
- Add 6 tops to the existing clothing store and wardrobe:
  - oversized pump cover
  - stringer tank top
  - compression shirt
  - cropped hoodie
  - plain gym tee
  - sleeveless hoodie
  A few colors each (3-4: e.g. black, grey, white, one accent color). No logos or brand names; plain designs or a small "GYM ARC" print is fine.
- Cosmetic only. Bought with coins and worn from the existing Wardrobe button, using the same buy flow as the current gear. Put the prices in Config.
- They must be CLASSIC Shirts (2D, 585x559 template), NOT layered 3D clothing. The muscle meshes use the Shirt texture, and layered clothing hides the muscles. Each top must look right on the muscles:
  - Tank top, stringer and sleeveless hoodie: bare arms and delts (transparent sleeve areas), so the arm muscles show skin.
  - Compression shirt: tight, follows every muscle.
  - Pump cover, tee and hoodies: cover the torso and arms.
  - Cropped hoodie: abs visible below the crop line.
- If you can't upload new Shirt images from Studio yourself:
  - draw the templates as PNGs in a folder called clothing_templates/ (one per top and color, named clearly)
  - wire everything up with placeholder ids in Config
  - write the exact steps for me in the morning report: where to upload, and where to paste each id
- Test every top at level 0, max and mass monster: no skin poking through the wrong places, no stretched or missing texture on any muscle.
Screenshots: all 6 tops on a maxed character, front and back.

====================================================================
TASK 3. TREADMILL
- Add 2 treadmills to the starter gym using the existing machine system (same HUD, tap to run). Use a simple clean model: a moving belt texture that scrolls while running and handrails. No brand names.
- Running does NOT use stamina. Stamina keeps refilling normally while you run, so it's something useful to do between sets.
- It gives a small amount of leg EXP (Quads, with Hamstrings and Calves as small secondaries) and normal coins. Use the same EXP flow as the other machines, but less EXP per second than a real leg machine, so it never beats lifting.
- Simple running animation that stays on the belt, with no sliding off.
- Track total distance run (saved). Add a "Cardio King" title using the existing titles system, unlocked at a total distance set in Config (default 10 km in-game).
- No new stats, no cardio meter, nothing else new.
Screenshot: a player running on the treadmill.

====================================================================
TASK 4. MAP: MORE DECORATIONS, BETTER BUILDS, OPTIMIZE
Do this LAST, after tasks 1-3 are committed. Keep the existing layout, machine positions, NPC paths and spawn points. Don't move anything gameplay depends on.

A) Optimize FIRST, so the decorations have room:
   - Measure before: total part count, instance count, draw calls, and client FPS + memory in Studio's phone emulator, at spawn and in the town. Write the numbers down.
   - Merge static decoration parts that sit close together and share a material into single parts or unions/MeshParts where it's safe. Set Anchored, CanCollide false, CanTouch false, CanQuery false and CastShadow false on small decorations nobody walks on.
   - Turn on StreamingEnabled if it's off (Persistent models for anything scripts need at start, like Gym.Entrance and the starter gym). Check that nothing breaks when parts stream out.
   - Lights: at most 1 shadow-casting light per room. Shrink the Range of the others and turn their Shadows off. Use Neon or SurfaceLights instead of PointLights where it looks the same.
   - Remove hidden or duplicate parts, empty models, unused scripts and any decoration under the floor or inside walls.
   - Use RenderFidelity Automatic and CollisionFidelity Box on decorative MeshParts.
   - Measure after with the same tests. The goal is a steady 60 FPS on the Studio phone emulator.
B) Better builds (real gym feel, clean, not cluttered, not "AI-looking"):
   - Starter gym: rubber floor tiles with seams, mirrors on one wall, a water fountain, a towel rack, a chalk bowl, wall clocks, motivational signs with simple text (no real brands or people), a whiteboard with a fake workout plan, plants, a front desk with a sign-in sheet, lockers and benches near the door.
   - Pro gym: darker and more premium. Wood platform areas, chrome racks, wall-mounted TVs showing simple gym graphics, a smoothie bar counter, LED strip lighting along the ceiling edges.
   - Beach gym: palm trees, sand, a lifeguard tower, towels, umbrellas, a volleyball net, a surfboard rack, boardwalk planks.
   - Town: street lamps, benches, trash cans, bushes, crosswalk lines, shop signs and window displays, a few parked cars (generic shapes, no brands), a bus stop, and a fountain in the plaza.
   - Fix ugly builds: z-fighting, gaps, floating parts, stretched textures, too-bright or too-flat colors. Exteriors get trim, roof edges and window frames, not plain boxes.
C) Rules:
   - Use simple parts, or clean low-poly free Toolbox models only after checking them for scripts and viruses. No logos or brand names.
   - Every new decoration goes in a Decor folder per area, so I can delete it easily.
   - Re-measure FPS after decorating. If it drops below 60 on the phone emulator, cut decorations until it's back.
Screenshots: before and after of the starter gym, pro gym, beach gym and town plaza, plus the FPS/part numbers before and after.

====================================================================
WHEN DONE: write a short morning report at the top of PROGRESS.md:
- forearms and calves: the EditableMesh count before and after, and whether the stage meshes are in (or which upload steps I need to do)
- the fits and treadmill: what got done, plus any upload steps I need to do
- anything you couldn't do and why
- map: part count and FPS before vs after
- "TRY FIRST": the 3 things I should test first when I open the game
- the list of screenshot file names
