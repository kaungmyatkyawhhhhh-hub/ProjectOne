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

## LONG WINDOWS + ONE CHIP STYLE (9 Nov, owner: "shop UIs are supposed to be scrollable" + "the labels on the left are so ugly")
- **What went wrong:**
  - new STORE cards made the window grow to ~1300 tall, and the fit rule shrank all of it to x0.3 instead of scrolling;
  - the left chips (stretched art + coloured pills, each a different colour) didn't match the top HUD the owner likes;
  - LUMI's line bubble was sized in studs, so next to the camera it covered the HUD.
- **Rule for SHRINK:**
  - a window has a FIXED size; content that grows (cards, rows) scrolls inside it, never makes the window taller;
  - the fit rule is only for a fixed-size window on a small screen;
  - all HUD chips use ONE style, copied from the HUD part the owner likes (here the LVL plate);
  - a 3D text bubble near the player is a fixed pixel size (offset), never studs.

## BUTTONS vs ICONS on the HUD (9 Nov, owner: "simple like Pet Sim 99" + "boosts and rewards like buttons, players need to see them")
- **What went wrong:** first every left item became the same small framed tile with a label (too compact: "kids won't bother reading it"); then everything was an icon, so the things to PRESS (rewards, boosts) got lost.
- **Rule for SHRINK:**
  - something a player must PRESS (rewards, boosts, offers, events) is a BUTTON in the hotbar's look, with its name always shown and one small state badge;
  - something that's just INFO (active boosts) is a small plain icon, no frame, a label only for a timer, details on hover / tap;
  - calm: no flashing or bouncing on the side; only a badge changes (impatient kid: one clear thing to tap, nothing nagging);
  - make the size big enough for the longest name at 14 px, and never let labels spill into neighbours.

## QUALITY SCAN TELLS (9 Nov, owner: "scan the entire game ... the unappealing stuff and UIs, and fix them")
- **What we found:** a 1-px bright line at every window's edge (backdrop strips on half pixels); STAR FORGE icons empty the first time it opens; flat and glossy icons mixed; plain-box toasts; a bare coloured banner slab.
- **Rule for SHRINK:**
  - backdrops / strips are placed on whole pixels (or one full-screen frame);
  - preload every UI image at join;
  - one icon style (pick one set; replace the odd ones);
  - every pop-up and toast uses the kit plate, never a plain box;
  - decor parts get a material + an emblem, never a bare coloured block;
  - the left-side buttons are a vertical column; small icons sit on the hotbar-key diamond (owner).

## SIDE BUTTONS = THE MAIN BUTTON'S STYLE (9 Nov, owner: "make the left buttons like the supernova button style but in a different format")
- **What the owner wanted:** the side buttons should look like the game's best button (SUPERNOVA), not a new look (hotbar diamonds with a name under them weren't it).
- **Rule for SHRINK:** side / HUD action buttons reuse the main CTA button's parts (plate, lip, outline, heavy text + a state line) in their own compact shape, coloured by meaning (claim gold, buy green, info blue, event pink). Only the main CTA keeps the moving shine / glow.

## UI FAMILIES THAT DON'T MATCH + COLOURS (9 Nov, owner screenshot of Galaxy's HUD: "the ui's dont match and some are really good, some are really bad"; also "UI, colors that dont match, game physics, and lighting")
- **What the screenshot shows:** 7+ UI styles on one screen:
  - **good:** REWARDS / BOOSTS (chunky glossy gradient buttons with a big icon + a state line), the stardust counter (navy slanted plate, gold edge, big number), the LUMI portrait (gold ring), the in-world BLACK HOLE / STAR FORGE plaques;
  - **bad:** the tiny diamond tiles under BOOSTS (unreadable, a 3rd shape), the plain thin "EMBER BELT · GALAXY LIT 0%" pill, the floating "NEXT: ..." text with no plate, the orange IGNITION bar (a different colour language from the navy plates), the default-looking round chevron / red buttons on the LUMI panel, the tiny STEP 3/20 tag, the giant flat comic lightning arrow (a 4th art style, covers the corner), the hotbar's dark diamonds (another shape again);
  - **colours:** navy, purple, orange, blue, gold, green and pink all at full strength with no shared palette, so nothing reads as one game; the Core's bloom/glare runs behind the top HUD.
- **Cause:** the HUD was built piece by piece over ~10 prompts and art batches (HUD art, 9 weak UIs, side chips, LUMI panel, rank tag...). Each piece got its own look; "one UI kit per game" was a rule but never a FILE: no palette tokens, no fixed set of component shapes, no check. New pieces copied the nearest piece, not the best one.
- **Rule for every game (MEGA BITE first):**
  1. **Design the whole HUD once, before features:** one full-screen mockup on a phone frame (every counter, button, tile, the tutorial panel, a toast) → the owner approves it → only then build. New features add pieces FROM that mockup.
  2. **Palette tokens in code** (`UIKit.Colors`): 8-10 named colours shared by UI AND world (signs, VFX, zone accents). Meaning colours (buy, claim, danger, locked, info) at ONE saturation/brightness. Nothing else allowed.
  3. **Max 3 component families:** COUNTER (plate + icon + big number), BUTTON (the best button's parts: plate, lip, ink outline, big icon, heavy text + a state line), TILE (square icon tile for hotbar / abilities / small HUD items, always with a label or a number). Every new piece is one of the three; no new shapes.
  4. **No floating text and no bare slabs:** every text sits on a kit plate.
  5. **Guide arrows live in the world** (adorned to the target), never a giant flat arrow on the screen.
  6. **A UIAudit script fails** any colour not in the tokens, any 4th shape, any text under 14 px, any plain-text label, any overlap, on 3 phone sizes.

## PHYSICS (9 Nov, owner: "game physics" was one of Galaxy's bad things)
- **What went wrong (known):** players fell through their island into the void on slow connections (teleport before streaming); the default Roblox walk/jump felt like any other game (the space movement prompt came after launch).
- **Rule for every game:** movement is designed and tested like a feature, before content: a movement spec (speeds, acceleration, turn rate, jump/swim feel) in config, a feel pass on a phone in the first build, streaming-safe teleports (RequestStreamAroundAsync + PauseOutsideLoadedArea + a void/out-of-bounds rescue), no clipping through walls or floors, server checks on speed. Ask the owner what felt wrong when a physics complaint isn't specific.

## LIGHTING (9 Nov, 2nd time: owner listed lighting again)
- **Seen in the screenshot:** the floor is near-white and flat, the sky near-black, the Core's bloom/glare blows out the top of the screen behind the HUD, the character is a dark shape: too much contrast, no mid-tones, no shape on the ground.
- **Rule (adds to the 7 Nov rule):** a lighting preset per zone in config, designed with the art style (key light direction, fill, Ambient ≥ ~110, a tinted shadow colour, Bloom threshold high so only real light sources glow); nothing bright sits behind the HUD; the ground has mid-tones (pattern, AO, colour variation), never a flat white slab; check on a phone at minimum AND maximum graphics with the HUD on.

## STUDIO TESTS WRITE THE REAL SAVE (9 Nov, Sat 21 update A, found by Claude)
- **What went wrong:** forced test pulls (a VOID core, a GOLDEN NEBULA WHALE x44 stardust) landed in the owner's real save. Studio Play with API access saves to the live DataStore (`GalaxySave1`). Removed with a cleanup switch and re-saved.
- **Rule (every game):**
  - any test that forces items, currency or rare results runs on a throwaway save (`TestFreshSave` = a new save that never saves);
  - every game has that switch from day one;
  - every counter that is global (serials, community goals) uses a separate `_Studio` store in Studio.

## 3D MODELS WITHOUT A REFERENCE STUDY (9 Nov, owner on the first Reef Shark: "it's really bad ... the one rn is REALLY really bad")
- **What felt bad:** a round blob "toy" shark: a fat body, big round goofy eyes with brows, a smile line, small fins: nothing like the sharks kids know from shark games.
- **Cause:** modelled straight from my own style guide ("chunky toy, big eyes, round fins") with NO reference study; I read "cartoon" as "round and cute" for every shark.
- **Fix:** looked at SharkBite 2 / Be a Shark / Hungry Shark World: rebuilt sleek (cone snout, crescent tail, swept fins, dark fin tips), small beady eyes + brow, a wide toothy grin with a real jaw bone. Owner research request → [[2026-11-09 MEGA BITE - Shark art research (models, animation, assets)]].
- **Rule (every game, every model):** the [[Reference study]] comes BEFORE the first polygon: 4-6 references of the real thing AND of top games that stylise it, written down as "what makes it read". Keep the real silhouette; put the cartoon into the face, teeth, colour and size. Show the owner a render early (v1), never after polishing.

## COMPACT ON PHONES (9 Nov, owner: "the ui are so compact in mobile screen")
- **What felt bad:** on a phone every window was shrunk to fit the screen's HEIGHT (x0.6), so the STAR FORGE drew 7.7 px text. It was readable on PC and tiny on a phone.
- **Cause:** a single fit rule, "the whole window must be visible", picked a scale from the height, and nobody measured the text after scaling.
- **Fix:** the phone layout. Windows are drawn at the screen's WIDTH and scroll up and down; a text floor of 14 px (a text that doesn't fit shrinks, never under 14); short phone versions of long lines; pop-up cards count as windows (the HUD steps back). Checked with UIAudit on SE, Android and 14 Pro: all clean.
- **Rule (every game):**
  - on a phone, never scale a window to its height: fit the width, scroll the rest;
  - no text under 14 px on the smallest phone (SE 667x375 and a 360-px-tall Android), measured after every scale;
  - every pop-up goes through the window manager (HUD steps back, Esc closes it);
  - run UIAudit on all 3 test devices before saying "the phone works".
- **Tool:** never cut a UTF-8 string with `sub()` in a report (a cut through "·" made the Studio tool call hang). TextFits is only right a frame or two after a TextSize change.

## A BUTTON FOR WHAT A HELD KEY CAN DO (9 Nov, owner on the JETPACK button: "they don't need a button, it should just be when the jetpack activates from holding jump")
- **What felt bad:** a big JETPACK button with a fuel ring, on a phone screen that's already full, for a move kids already know (hold jump = fly higher).
- **Cause:** I built "a new feature = a new button" instead of reusing the input kids already press.
- **Fix:** hold jump for 0.3 s = the jetpack (a tap stays a normal jump). The fuel is a thin bar above the hotbar, shown only while it's in use.
- **Rule (every game):** a movement extra (double jump, glide, jetpack, sprint) goes on the input kids already use (hold or double-tap jump, hold run), not a new button. Its meter shows only while it's in use, in the lower middle, and in the kit's bar style.

## SMOKE AND SLIDES ONLY WHEN THEY'RE EARNED (10 Nov, City Legends, owner: "the cars are slipping too much when tcs is off", "tire smoke coming out for no reason when idle", "when doing launch control there is tire smoke")
- **What felt bad:** with traction control off every rear-drive car went sideways like a drift car; tyres smoked standing still; a clean launch-control start smoked.
- **Cause:** the tyre model measured slide from the slip angle, and at a crawl a few cm/s of side creep reads as a huge angle (smoke at idle). "TC off" was tuned as a drift mode for every car. Smoke followed the physics' wheelspin even on a launch the player meant to be clean.
- **Fix:** smoke from the slip angle only once the car really moves; TC off lets the rear go freely only on drift tyres (ordinary tyres: about Sport's slide, stability control stays at Sport); a launch-control start makes no smoke; smoke on the spot is a deliberate burnout (launch control, let go, press the brake again with the throttle down).
- **Rule (every game):** a big effect (smoke, sparks, a slide) must come from something the player chose (a part, a mode, a button combo), never from noise at rest. Check every effect at a standstill and at a crawl. The wildest physics belongs to the part that sells it (drift tyres), not to a settings switch.
## 3D MODELS: fins floating, see-through holes (MEGA BITE, 10 Nov 2026)
- **What felt bad (owner):** "most of the wings aren't attached to the body"; "the side fins ... like levitating"; Hammerhead "has gaps, when I look through them it's like inside the model and it becomes invisible".
- **Cause 1 (floating fins):** fins were built from the side silhouette MINUS the body, so every fin root stopped 1-3 px short of the body; the shark side fins started 70-85 px out to the side at belly height, where the body is only a few px wide, so they hung 40-60 px away from it. The fish side fins touched the body at one point only. Checked by eye from the side view, where it looked fine.
- **Cause 2 (see-through):** Roblox draws one side of each face only. The Hammerhead was built before the per-island normal fix and had 401 inward-facing faces (its bevelled cephalofoil fooled the simple test), and its MeshPart was not DoubleSided.
- **Rule:** before any model ships, run the two automatic checks, not just a side render: (1) every fin island must have vertices INSIDE the body (fincheck.py: inside-count > 0, measured per fin), roots sunk ~15-25 px; side fins start from the body's real width at that height (ray-cast), not a constant; (2) zero open edges and a 6-angle back-face render with no green, and MeshPart.DoubleSided = true. Look from BELOW and from the FRONT, never only the side.

## A HELP BOX ON TOP OF WHAT IT EXPLAINS (GYM ARC, 10 Nov 2026, owner's part 3: "Dialogs never cover what they explain")
- **What felt bad:** Coach Dex's box sat on the streak rewards and on the trainer reveal card; ~20 two-page dialogs in 16 min; a boss fell in ~8 taps with no win moment.
- **Cause:** each helper placed its box "just under the button it points at" (= on the window's content), and every new feature added its own 2-page speech. Bosses were tuned only for "can a new player win", never for "does it feel like a fight".
- **Rule (every game):**
  - a help box goes on the FAR side of the screen from what it points at; over a reveal / reward card: no box at all, only the pointer;
  - one short line per step; a tap anywhere on the box advances; never two help boxes at once;
  - a boss / PvP fight lasts 3-5 s with the bar swinging both ways, and always ends on a result card (title, reward, confetti, sound).
- **Testing (Roblox Studio MCP):** click UI by its instance path (screenshot pixels don't match the real viewport); `require` in execute_luau gives a separate copy of a module, so firing a UI bus from there proves nothing; test server logic through the real RemoteEvents.


## 11 Nov 2026 - 3D models: "its suppose to be 3d and not just pictures on a block" (Stomp Evolution, Stone set)
- **What felt bad:** the first Stone model was rounded boxes with the design sheet projected on as a picture; fists, body, legs and shoulders all looked flat. The next try wrapped thick blocks round the body: "they look fat cuz the bellys pushing outwards and the legs look like sticks when theyre blocky".
- **Cause:** used the sheet as the texture instead of as a reference, and built the armour on a made-up block body.
- **Fix:** rebuilt on the real avatar mesh from Studio (Bacon Hair), with every detail as geometry and the textures painted on the model. Note: [[2026-11-11 Stomp Evolution - Stone set model v3 (real 3D, on the Bacon Hair avatar)]].
- **Rule:** (1) a design sheet is never projected onto simple shapes as the final look: everything the player can see is modelled. (2) Armour and clothes are fitted on the real avatar mesh, thin and close to the body; the waist stays flat, nothing sticks out further than the chest plate. (3) Work in the owner's Blender so he can watch.

- **Added 17:18 (same model):** "the leg look fat now, why cant u just do like the models from roblox catalog". Cause: plates on a box leg, then a wider box. **Rule:** armour sets are built like Roblox catalog bundles: each body part is its own sculpted mesh whose width changes along its length (slim thigh, knee, greave that widens to the boot, a gap between the legs). Never fix a proportion by scaling a box; reshape the part. Look at the catalog references before changing a body shape.

## Stomp Evolution armour sets (12 Nov 2026)
- **Felt bad:** one big signature piece on one shoulder only (boulder, blade fin, chimneys, bolt, crystal cluster): "assymmetrical", "huge". **Cause:** my design kit asked for "one big signature shoulder + one smaller". **Rule:** every armour set is symmetric; both shoulders wear the same modest pauldron; the theme goes on chest, back, forearms, belt, knees and boots. See [[2026-11-12 Stomp Evolution - Stone set v4 in Studio + corrected sheets]].
- **Felt bad:** "9 fingers": finger columns on the front, the outer side and the back of each fist. **Rule:** a fist shows four knuckles on the front only; the sides and back are one plate; thumb on the inner side.
