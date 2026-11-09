---
date: 2026-11-07
tags: [lessons, galaxy, shrink, game-feel, sound, vfx, lighting]
---
# Lessons: Galaxy Incremental → +1 SHRINK (game feel)

Owner (7 Nov): "ill spot out unsatisfying things in galaxy incremental so we dont make the same mistake for +1 shrink. the sound vfx, the onscreen-vfx, lighting".

How this note works:
1. The owner spots something that feels bad and sends a screenshot or clip with one line on what feels off.
2. Claude finds the cause, writes the Galaxy fix prompt, and adds a **rule** here.
3. +1 SHRINK is built from these rules from day one. Every SHRINK prompt links to this note.

Format per entry: **What felt bad** / **Cause** / **Galaxy fix** / **Rule for SHRINK**

## Already learned (GYM ARC + Galaxy, Oct-Nov)
- **Black boxes behind particles.** Cause: ChatGPT textures on black, an `_add` texture used without LightEmission 1, and faint background noise left in `_alpha`.
  - Rule: every texture gets a noise-floored `_alpha`; `_add` is only used with LightEmission 1; checked on light AND dark backgrounds before upload.
  - 7 Nov: it happened AGAIN in Galaxy (sparkle particles with dark squares on the light floor). So the rule needs a code check, not just a habit: a script lists every ParticleEmitter/Beam/Trail texture id and fails any that isn't in the approved `_alpha` list, or that is an `_add` texture without LightEmission 1.
- **Auras/VFX "too much".** Cause: no per-tier budget, so everything got every layer.
  - Rule: a tier budget from day one (low = 1-2 layers, top = all). The character is always readable and the face is never covered. Others' effects run at half rate.
- **"Seamless" textures with seams.** Cause: ChatGPT can't really tile.
  - Rule: Claude always quilts and checks 2x2 at full size before shipping.
- **Placeholder sounds** (Black Hole = old sounds pitched down).
  - Rule: every big moment gets its own sound picked from the Creator Store before the feature counts as done.
- **Ugly / empty UI** (plain text boards, "[X]" checkboxes, an empty info panel, tiny phone text).
  - Rule: no UI ships with text-only lists, placeholder glyphs or empty states; phone text is at least 14 px; art slots are planned with the feature, not after.

## BOARDS / IN-WORLD UI
- 7 Nov, Star Forge board (owner screenshot):
  - **What felt bad:** a thick orange box frame around art that already has its own gold frame (two frames), a white/grey strip showing between them, a ledge part cutting into the bottom-right corner of the board, and a sparkle hanging outside the art.
  - **Cause:** the board part was built with a frame first and the framed art was dropped onto a SurfaceGui later. Nobody matched the screen part to the image's ratio, and nobody checked what else sits in front of the face.
  - **Galaxy fix:** prompt "Star Forge board double frame" (7 Nov).
  - **Rule for SHRINK:** the framed art IS the board: one plain, dark, borderless screen part at exactly the art's ratio, with the art filling it edge to edge. The only physical parts are a back plate and a post, and both stay hidden behind the art. Nothing may sit in front of a board's face (MapAudit OVERLAP + a front raycast check).

- 7 Nov, island gold ring (owner screenshot): "the golden ring is colliding with the boards".
  - **What felt bad:** the gold orbit ring around the island cuts straight through the Constellation Tree and INFO boards (and their titles).
  - **Cause:** the ring was sized for the island, and the boards were placed at the edge later (BoardPlacer), at the same height band as the ring. MapAudit's OVERLAP check compares bounding boxes, and a ring's box covers the whole island, so ring-shaped/hollow parts were likely skipped or ignored. Nobody checked them against the boards.
  - **Galaxy fix:** prompt "Galaxy - gold ring through boards" (7 Nov).
  - **Rule for SHRINK:**
    - decorative rings, rails and orbits get their own height or radius band that boards never use (e.g. a ring below the board bottoms or wider than the board ring);
    - MapAudit checks ring/hollow meshes with real geometry (GetPartsInPart / raycasts along the ring), not bounding boxes;
    - every board's face must have a clear view (front raycast grid).

## WINDOWS / INPUT
- 7 Nov, UPGRADES window (owner): "when i select the frame, it keep exiting". Clicking or tapping inside the window closes it.
  - **Likely causes:**
    1. A "click outside to close" check that reads the wrong frame's bounds, or ignores gameProcessedEvent.
    2. A full-screen close backdrop that sits above the window (ZIndex).
    3. The click passes through the UI to the board's ClickDetector / ProximityPrompt behind it, which toggles the window shut.
    4. A distance auto-close that measures from the camera.
  - **Rule for SHRINK:** one WindowManager for every window:
    - closes only via X, Esc/B, or the dim backdrop, which sits BEHIND the window;
    - windows are Active, so they sink input;
    - world clicks are ignored while a window is open;
    - distance auto-close only past 25 studs from the board, measured from the character.

## PHONE LAYOUT (launch day, owner phone screenshot 7 Nov)
- **What felt bad:** on a phone in landscape, everything overlaps:
  - Roblox's own menu buttons cover the LVL chip;
  - the stardust bar sits on top of the island name;
  - the 2x event banner covers the middle of the screen;
  - the pad labels ("UNLOCK / UPGRADE / LOCKED") and the island title are giant and stack on each other;
  - the LUMI panel's parts overlap each other (LUMI / STEP, HIDE / SKIP, +1 / +BONUS);
  - the hotbar cuts into the LUMI panel;
  - the INVITE button is clipped;
  - small text is unreadable.
- **Cause:**
  - The HUD was laid out and checked on PC. Phone checks were single screenshots, not an overlap audit.
  - Fixed pixel offsets inside panels that get scaled down.
  - World BillboardGuis sized in pixels (the same size on screen at any distance).
  - No safe-area insets for Roblox's top-left buttons.
- **Rule for SHRINK:**
  - every ScreenGui uses ScreenInsets = CoreUISafeInsets;
  - layouts are built with UIListLayout / UIPadding / AutomaticSize (no hand-placed offsets inside a panel);
  - a phone layout (short screen) is designed on purpose: fewer, smaller, collapsed elements, not the PC layout shrunk;
  - world labels are sized in studs, with a MaxDistance, and only the nearest few show;
  - the centre of the screen stays free (the character + the world);
  - a UIAudit script fails on any two visible HUD elements overlapping, any text under 14 px, or anything outside the safe area, on 4 device sizes (smallest phone first);
  - phone screenshots are part of every report.

## EVENT POPUPS (GYM ARC posing show, owner 7 Nov: "this annoying posing show thing shows up")
- **What felt bad:** every 5 minutes a big WINNER banner + a RESULTS panel covered the centre of the screen for players who never joined, even when an NPC won.
- **Rule (every game):** big centre-screen UI only for players who TOOK PART. Everyone else gets at most a small corner toast (3 s, nearby or friends only, never for NPC results). Repeating events (every few minutes) must be skippable with zero interruption. Results live in the WORLD (a scoreboard by the stage) rather than on everyone's screen. Every event UI auto-closes and is tap-to-close.

## UI CORNERS
- 7 Nov, Tree + Info windows (owner): "u see the edges, its not round and theres like a layer poking out".
  - **Cause:** stacked layers where only some have a UICorner. ClipsDescendants doesn't clip to rounded corners. Inner layers used the same radius as the outer one.
  - **Rule for SHRINK:**
    - one UiKit.Round helper for every visible layer;
    - inner radius = outer radius - inset;
    - shadows/glows use the same rounded shape;
    - UIStroke only on the outer layer;
    - zoom-check all 4 corners of each window before shipping.

## GUIDE ARROWS / TUTORIAL MARKERS
- 7 Nov, "STAR DAIS" arrow (owner screenshot): the arrow + label float beside the dais, pointing at empty floor.
  - **Cause:** the marker sits at a hand-typed world position or offset (or an off-centre model pivot), not on the target itself. When the target moved, the arrow stayed behind.
  - **Rule for SHRINK:** every guide marker is a BillboardGui ADORNED to the target part (or the model's bounding-box centre), placed at the target's top + 3 studs and pointing down at it. There are never hard-coded positions. The tutorial check screenshots each marker from the spawn.

## BUILD ONLY WHAT WAS ASKED (7 Nov)
- The owner asked for "step on the buttons". Claude wrote a prompt for NEW floor pads in front of the BODIES board, but the owner meant the EXISTING tycoon buy pad (STAR DAIS), which was click-only. Result: unwanted pads ("we dont need that buttons") and the real one still not pressable.
- **Rule:** when the owner names a thing ("the buttons", "the board"), first match it to what already exists in the game (the most tycoon-like / most visible one). Fix THAT, and add nothing new unless he asks. If two things could match, name both in the prompt, change the existing one, and never build extras.
- **Placeholder-looking HUD** (left chips + LUMI panel = plain dark boxes with gold borders) is the same "no placeholder UI" rule. Every HUD element gets real art in the style of the best piece the owner likes (the hotbar), planned with the feature.

## SOUND
- 7 Nov (owner): "music should have more hype, rn it feels depressing".
  - **Cause:** slow, minor-key ambient space pads chosen for "mood". Kids' simulators need energy, and the music bed sets the whole game's feel.
  - **Galaxy fix:** prompt "Galaxy - hype music" (7 Nov).
  - **Rule for SHRINK:**
    - the main loop music is upbeat: 115-140 BPM, a major key or bright, with a clear beat (electronic/synth-pop, from the licensed Roblox partners APM / Monstercat in the Creator Store);
    - a playlist of 3-5 tracks with crossfades, no single loop;
    - dark/slow music only for short special moments (the Black Hole), never as the default;
    - the music bus is about 0.4, under SFX, and ducks under stingers;
    - UI sounds stay in the music's key.

## VFX (world)
(owner's notes go here)

## ON-SCREEN VFX (UI pops, flashes, shakes, numbers)
(owner's notes go here)

## LIGHTING
- 7 Nov (owner): "the lighting is still bad, i dont like how its mostly dark".
  - **Cause:** a space theme taken literally: dark sky, low Ambient/OutdoorAmbient, night ClockTime, and no fill light. Islands and boards end up in shadow.
  - **Galaxy fix:** prompt "Galaxy - bright lighting + step-on buttons" (7 Nov).
  - **Rule for SHRINK:**
    - the PLAY SPACE is always well lit, whatever the theme; mood goes in the sky, never on the ground;
    - Ambient/OutdoorAmbient are never darker than about 110;
    - check exposure from the spawn on a phone at minimum graphics;
    - nothing the player uses sits in shadow.

## INTERACTION
- 7 Nov (owner): "players should be able to step on the buttons".
  - **Rule for SHRINK:** every buy/upgrade button is a tycoon-style floor pad the player walks onto (Touched, server-checked, with a debounce). Clicking or tapping stays as a backup. Pads follow the map rules: 6+ studs apart, at path edges, with the price readable from 20 studs.

## LAUNCH GATE (9 Nov: why Galaxy got 5 likes / 8 dislikes)
- **What went wrong:** launch weekend was broken on phones (overlapping HUD, windows off the screen, the jump button on the buy buttons) and some players fell through their island into the void. Then a dead first 30 s (0 stardust, 1/s, no comets) and a ~10-minute wall at minute 3. A boring game makes kids leave; a BROKEN game makes them dislike.
- **Rule for every launch (+1 SHRINK first):** nothing goes public until:
  1. someone other than the owner plays it on a real PHONE on a fresh account for 10 minutes;
  2. a 2-player test (2 devices) with streaming on;
  3. the impatient-kid sim (`Celestial Incremental\Calc\kidsim.py`, adapted to the game) keeps 100% past 60 s;
  4. the first 30 s have something to do every ~3 s;
  5. the like prompt only appears after the first big moment.

## TAPS ON PHONES (9 Nov, owner: "in mobile, the buttons only works when its held, not when pressed")
- **What felt bad:** a normal tap on a BUY button did nothing; only a hold bought.
- **Cause:** a list's "was this a drag?" check fired on a 6-pixel move in the window's own units, which a scaled-down phone window turns into 3-4 real pixels. A finger wobbles that much on every tap. The list's elastic bounce also counted as a drag.
- **Rule for SHRINK:**
  - a press only becomes a drag after **12 real screen pixels on touch** (6 with a mouse), measured on the screen, not in the scaled UI;
  - lists only bounce when they can actually scroll;
  - invisible layers (effect layers, icon holders) never take input;
  - test a quick TAP, not a hold, on the emulator.

## WINDOWS ON PHONES (9 Nov, owner phone screenshots of UPGRADES)
- **What felt bad:** the window ran off the bottom; the jump button sat on a buy button; labels ran out of their buttons.
- **Cause:** windows were the PC window shrunk to the screen's width, with scrolling for the rest.
- **Rule for SHRINK:**
  - one fit rule for every window: scale = min(1, 0.92 x safe width / its width, 0.86 x safe height / its height), centred in the safe area under Roblox's buttons;
  - the main windows get a phone layout drawn at full size;
  - Roblox's jump button and thumbstick hide while a window is open;
  - labels shrink to fit (min 14 px).

## STUDIO TEST SETTINGS (9 Nov, owner: "whys there a 1.5 second delay in studio")
- **What felt bad:** every buy and tap took 3 s in Studio.
- **Cause:** a slow-connection test left Studio's Network > Incoming Replication Lag at 1.5 s. It's a Studio-wide setting, not saved in the place, so it slowed every later test in every game.
- **Rule (every game):** a test that changes a Studio setting puts it back in the same session and says so. If Studio feels laggy, check Incoming Replication Lag first.

## "DEAD" ASSETS THAT AREN'T (9 Nov, the 4 music tracks)
- **What we thought:** 4 tracks were "moderated or gone".
- **Cause:** the music player waited only 10 s, then crossed the track off for the session. On a slow phone, while the map streams in, a 2-3 MB track takes longer.
- **Rule:** a load timeout is not "gone". Wait ~30 s, retry later, and only give up after 3 failed loads. Check the asset (GetProductInfo / a load test) before replacing it.

## SHARED COUNTERS (9 Nov, the Great Star)
- **What went wrong:** the first test counted a save's 35 existing Supernovas as 35 new points.
- **Cause:** it watched the player's Supernovas attribute, which jumps from 0 to the saved total when the save loads.
- **Rule:** count events where they happen (the server function that does the Supernova), never by watching an attribute change. Size shared goals to the real player count (the owner set 25 / 75 / 150 / 300 / 500 for ~25 DAU).

## PHONE CHECK = 3 PHONES + EVERY WINDOW (9 Nov, the 14 Nov launch gate)
- **What went wrong:** windows that passed on one phone failed on another (the 360-px Android shrank UPGRADES to 13.4 px; the notched 14 Pro pushed a HUD icon into the shards counter). Old windows that were never re-checked (DAILY) had 45 texts under 14 px. A new row made DAILY smaller still.
- **Rule for SHRINK:**
  - run UIAudit on SE 667x375, Android 800x360 and 14 Pro 852x393;
  - open EVERY window, not only the HUD (Studio `TestOpenWindow`);
  - when a row is added to a window, re-check it on the smallest phone;
  - a window that's tall on PC fits the width and scrolls on phones;
  - decorations (glows, shine bands) are marked AllowOverlap so the audit only reports real problems.

## POP-UPS AND GROWING COLUMNS (9 Nov, owner: "the boosts labels need to be better" + "the bottom wasn't showing")
- **What went wrong:**
  - the BOOSTS list was a plain black box of text lines: the only placeholder left next to the designed HUD;
  - the launch gate's phone audit never opened it (it opens on a tap, not as a window);
  - on phones the left chip column ran off the bottom of the screen once PARTY and STARTER joined it, so the BOOSTS chip wasn't on screen at all.
- **Rule for SHRINK:**
  - the phone check also opens every pop-up that opens on a tap (lists, tooltips, menus), not only the windows;
  - every pop-up uses the kit's look (dark plate, ink outline, coloured edge, shine line, icon, value pill), never plain text lines;
  - when a chip joins a column, re-check the column's bottom on the smallest phone. If it doesn't fit, move the less-used chips into a panel (on phones FRIENDS / GROUP / PREMIUM now live in the BOOSTS panel, as cards with their own button);
  - a scrolled-out row isn't "covering" anything: UIAudit's TEXTHIT now only counts the parts that show.
