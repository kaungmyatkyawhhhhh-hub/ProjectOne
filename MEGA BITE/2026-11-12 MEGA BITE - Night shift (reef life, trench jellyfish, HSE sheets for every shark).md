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

## 4. More UI motion (owner 00:21 "ok do the ones on the list"), in `MB_UIMotion` section 3
Built from the polish bible's motion table, hooked onto the HUD pieces by name (MB_HUD unchanged):
- **NEXT UP card:**
  - A shine keeps sweeping along the lime quest fill (1 s Circular Out, then 1.6–2.6 s rest).
  - A glowing tip rides the fill's leading edge.
  - Every quest step floats a "+N" up from the end of the bar.
  - The "NEXT UP!" sticker bobs and sways (±2.2°, ±1.6 px). It pauses for 1.2 s while the HUD's own quest-done wiggle plays.
- **Quest done:** 9 gold 3D stars burst out of the card into the EXP counter.
- **Toasts:** every toast punches in (UIScale 0.55 → 1, 0.28 s Back Out). Reward toasts with EXP in them ("BANKED +120 EXP", "QUEST DONE! +25 EXP") send 4–9 stars from the words into the counter.
- **EXP number:** a light band sweeps across the digits every 3.5–5.5 s (a UIGradient resting at 86 % and peaking at white). It's skipped if the label already has a gradient.
- Checked in Play: the bar tip and shine, the sticker bob, the toast punch, 7 stars from a BANKED toast, 14 stars on QuestDone (card + toast), no errors.
- Test lesson: `require(ClientBus)` from an MCP script gets a SEPARATE module copy, so firing Bus events from a test does nothing. Fire the real server remote instead (`Remotes.Fx:FireClient(p, "Banked", 120)`).

## 5. Play-test results
- **Megalodon at bodyScale 2.1:** about 84 studs long (Evo 1 is about 7), reached with the Studio-only DevEvo key (`]`) through `Remotes.SwimAction`.
- **Tidal Roar v2:** pressing F plays the new sound (79495281571725) from the Megalodon's Spine0 via the RoarIn marker. It's loaded and in sync.
- **The 3x trench from swim height:** a lava-cracked floor, props and flora on the ground, the cliff wall in the distance.
  - From high up (y 160) the floor fades into the haze. Check on the phone whether the Megalodon's raised camera shows this, and if so lower Atmosphere Density in the trench mood.

## 6. Owner 00:34 + 00:45: transformation sound, and the 3D hero card in the Shop and the Fish Index
Owner 00:34: "there should be sfx when its transforming and also the shop gui dont have motion and animation and 3d effect on mouse cursor like tap reborn and also index ui needs those too". 00:45: switched this chat to Fable 5.2 ("u keep messing these things up") and pointed to the relay note. Research used: [[2026-11-12 Watch study - 3D pet card and egg hatch screen (owner recording 11 Nov)]].

**What I got wrong first (lesson):** I read "3d effect on mouse cursor" as a flat hover tilt on the list cards plus sparkles trailing the cursor. The owner meant the reference's Pets screen: ONE real 3D card that tilts toward the mouse. The sparkles were removed (nobody asked for them). Rule: when the owner names a reference effect, find it in the recording first; don't invent a nearby effect.

### Transformation sound
- Cause: the evolve sound was only played from the server's `Fx "Evolve"` event and from Fossilize. An evolve that the client sees as the `Evo` attribute changing (eating, the Studio DevEvo key) started the cutscene with no sound.
- Fix: the cutscene itself (`MB_HUD.cutscene`) now plays `Evolve` (v2, 94568801046813) when it starts, so the hit lands on the 1.1 s flash. The Fossilize and `Fx "Evolve"` copies were removed so it never plays twice. Other players' evolves play a quieter 3D copy from their shark.
- Checked in Play: the sound starts 0.13–0.17 s after the evolve.

### `MegaBite.HeroCard` (new ModuleScript): the 3D hero card
`HeroCard.new({name, leftOf = <2D panel>, hFrac, cy})`, then `:Open()`, `:Show(spec)`, `:Close()`.
`spec = {id, top, bot, glow, title, pill, rows, model, texture, transparency, silhouette, clips, art, button = {text, style, onTap}}`.
- **The card:** a rounded slab of real Parts (two blocks + four corner cylinders, 2 x 3 x 0.07 studs, navy) held in front of the camera every frame. It is opaque so depth of field keeps it sharp.
- **Its faces:** SurfaceGuis in PlayerGui at 200 pixels per stud (a 400 x 600 canvas), LightInfluence 0. Front: the item's gradient, pattern, a soft light behind the model, the name, a pill, stat rows and a `K.Btn3D`. Back: "MEGA BITE" (seen during the spin).
- **Placement:** the card fills the free region to the right of the 2D panel (`leftOf`), as tall as fits. It rests PARALLEL to the screen.
- **Tilt:** toward the mouse, up to 12° yaw and 8° pitch, on a spring (k 170, c 16). Phones have no mouse, so it sways slowly (±5°). Reduce Motion: no tilt, no spin.
- **Spin:** picking another item turns the card one full turn in 0.5 s; the content swaps at the half-way point, when the back faces you.
- **The model:** the real model, 0.62 studs in front of the card, 3/4 view with the nose to the left, swaying. Sharks play their own Swim clip (BonePlayer); fish wag their tail bones. It may stick out past the card.
- **Passes (no model):** the pass picture floats on its own plate in front of the card, so it parallaxes when the card tilts.
- **Behind the card:** a soft round glow in the item's colour (never a sunburst), then a dark tint plane (06122B at 0.42) square to the camera, then the world blurred by the existing DepthOfField effect (focus = the card's distance, radius 2.4, far 0.8). Its old values are restored on close. The 2D blur (`MB_UIBlur`) is set to 0 while the card is up.
- **The button:** pressed through an invisible 2D proxy button laid exactly over the 3D button each frame (reliable on phones).
- Test hook: `workspace:SetAttribute("MB_HeroSlowMo", 0.1)` slows the card to watch the spin.

### Fish Index
- The panel moved to the left (510 wide); the right side is the hero card of the fish you tap. The selected tile gets a gold edge.
- Tiles are now a picture and a name; the details (zone, EXP, "Eat at") moved onto the hero card.
- A fish you haven't found shows a grey card, a dark silhouette, "???" and "Eat at: X".
- On phones the title slides to the right of Roblox's own top-left buttons (`GuiService.TopbarInset`) and shrinks to end before the red X.

### Shop
- The list moved to the left; `HERO_COL = 262` units on the right are kept for the hero card.
- A skin is shown on YOUR current shark (the real model in that skin's texture). The card's button buys, equips or says EQUIPPED / OWNED.
- Tapping a list card now SELECTS it for the hero card; its own price pill still buys or equips in one tap.
- The top bar (title, tabs, Collection, X) became its own full-width frame above both the list and the card, and starts to the right of Roblox's top-left buttons.
- When the list is narrow, the two side minis and the Collection bar fold away (both repeat what the Skins section shows).
- The dark veil ScreenGui is now fully transparent; the tint is the plane behind the card.

### Bug found and fixed: the Shop's tabs blew up into one giant lime bar
- Cause: `MB_UIMotion` (11 Nov 20:45) put a shine frame inside every button. Inside a button that lays out its own children (the tabs: UIListLayout + AutomaticSize) the frame joined the layout and the button grew without end. It only showed after the first 4 s rescan, so my earlier quick tests missed it.
- Fix: buttons with their own layout or AutomaticSize, and buttons that sit inside someone else's layout, are left exactly as built.
- Lesson: when testing a window, wait past every timed rescan (5 s+) before judging it.

### Lessons from building the card
- A card that FACES THE EYE off-centre gets stretched by the wide view (it came out about 30 % too big and cut off). Parallel to the screen projects as a true rectangle.
- A part floating in front of an off-centre card must slide toward the screen centre (by offset x depth / distance) or it drifts outward.
- A yaw toward the screen centre swings the outer edge toward the viewer and makes it grow (about 45 px at 12° on PC, 32 px at 8° on the phone emulator): leave margin for it.
- A ScreenGui veil darkens a 3D card too; the tint has to be a plane behind the card.
- `PointLight` 1.1 at 2 studs blew the model out to white under our bloom; 0.3 is right.
- `ScreenGui.Face` on a SurfaceGui is the NormalId property: use `FindFirstChild("Face")` for a child named Face.
- MCP mouse clicks don't reach GUI buttons in Studio's phone emulator; real screen clicks do.
- `require(ClientBus)` or a module from an MCP script is a separate copy: test through the real buttons.

### Checked
- PC (976 x 584): Index and Shop open, tilt follows the mouse, the spin turns 360° and swaps the content at the back, the card's EQUIP button equipped Coral through the proxy, close restores the DepthOfField values and the HUD.
- Phone emulator (iPhone 17 Pro, 750 x 381): both windows fit; the card is 74 % of the screen height; text on the card is 14.1 px (pill, rows), 16.9 px (button), 23.5 px (title).
- Screenshots: `hero_card_shop_pc.jpg`, `hero_card_index_pc.jpg`, `hero_card_index_phone.jpg`.
- Not checked: a real phone (depth of field cost on a cheap phone; the fallback is the tint alone), and buying an unowned item from the card (the Studio account owns everything).
- Watch: Studio's output printed "No asset content representation found" for some of our images during these runs (kit glow, star, streak, a few skin textures), with one HTTP 502. The images still showed, and a re-check loaded all of them. It looks like a Roblox-side hiccup, not our assets.
