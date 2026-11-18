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

## Hands = Roblox's own bundle hands (12 Nov, Stone v8)
- Don't model hands. Use the ROBLOX Boy hand meshes (bundle 109: left 8650495301, right 8650495280), cloned from CreateHumanoidModelFromDescription of the bundle outfit so attachments and OriginalSize come with them. Colour them with a flat TextureID on a white part (BodyColors repaints plain colours).
- Painted material beats noisy realism: smooth, top-lit, crisp light edge trim, few cracks.
- TextureID on Plastic for every piece; set every BodyColors field to white.
- InsertService:LoadAsset of a model asset returns Model > Model > parts: go one level down.

## Bundle hands + boots (12 Nov, Stone v9)
- A Roblox bundle hand mesh with a classic TextureID shows beige skin blotches. Colour it with a SurfaceAppearance ColorMap instead (TextureID empty).
- Boots like Korblox: a shin greave that tapers into a tall ankle cup, overlapping plates down the instep, a rounded toe, and a thin sole with a stone rim. No bucket cuff and no glowing sole slab.
- Before showing the owner a screenshot, make sure it is OUR model (place it alone or check its texture IDs). The v8 screenshot showed Korblox by mistake.
- A texture that fails its first fetch stays failed for the Studio session: re-upload a fresh copy.

## Textures that don't look plastic (12 Nov, Stone v10)
- Korblox textures are small (about 300 px); the look is painted: cloudy mottling, a fine crack web, dark plate outlines, carved glyph rows on borders, streaked crystals. Avoid smooth fills and bright edge rims.
- Give visible plates the texels: one map per limb and shrink hidden UV islands. Studio shows textures below 1024, so detail must be big enough to survive about 256 px.
- Patterns projected on the dominant axis must stay off curved faces (they turn into scribbles).
- Re-exports change the UVs: always ship the mesh and its maps together.

## Armour that isn't stiff (12 Nov, Stone v11)
- Judge in a walk pose, side by side with a catalog bundle.
- No straight drums with flat horizontal rims: taper limbs and angle the rims (elbow guard up at the back, knee guard peaked at the front, plates sweeping down on the outside).
- Never let the under-suit show at joints; plates overlap the joint.
- Spikes and crystals sweep back and out, never straight up.

## UI references = top Roblox games, watched (12 Nov, GYM ARC Advent calendar)
- What felt bad: references for an advent calendar came from a web image search, which turned up physical calendars, AI-looking "event app" website mockups and a Coin Master grid. Owner: "those designs are old", "they look like ai generated website interfaces", "in roblox, other games cant match top modern roblox ui's", "tap reborn ui's are insane".
- Cause: we judged modern UI from generic web images instead of from the top Roblox games in motion. We also missed that VFX, motion and sound are most of what makes those UIs feel "insane".
- Rule: for any UI, menu, pass, calendar or reveal, the reference is the top Roblox games, watched as video (frames + sound measured), with Tap Simulator REBORN as the current bar. Never use a web image search for UI references. Always study the motion and the sound, not just the static layout. A plain grid with "CLAIMED" text (Fisch 2025) is the dated look to avoid.

## Stomp Evolution v2 pass (12 Nov 2026, evening): new lessons while applying MEGA BITE's
- **Swapping body parts mid-step tips the character over.** Anchor the HumanoidRootPart during `ReplaceBodyPartR15` + `ScaleTo`, then unanchor and `ChangeState(GettingUp)`.
- **An armour swap takes ~2 s while meshes load.** Start the evolve cutscene first and time its flash to the swap finishing (a `FormId` attribute), not to a fixed delay.
- **`workspace.CurrentCamera.ViewportSize` is 1x1 for a moment when a LocalScript starts.** Wait for a real size before picking a phone/PC size class (the PC HUD came up in the small-phone layout).
- **Audio owned by the group is private to group experiences.** A user-owned place needs each sound granted to its universe (asset-permissions API, PATCH `subjectType = Universe`, action `Use`) or it stays silent.
- **Studio's `screen_capture` can lag the client by a second or two:** to check a short timed effect (a cutscene), sample its state from a client script, don't trust a single capture.
- **A welcome patch must be inside reach from the spawn point,** measured (spawn 2 studs too far = the first click did nothing).

## Stomp Evolution feel pass (13 Nov 2026, night)
- **A new module's local name can be shadowed further down the same script.** `local FX = require(StompFX)` near the top, but the client already had `local FX = Folder("ClientFx")` lower down, so every effect call hit the folder ("aura is not a valid member of Folder"). Rule: before adding a require, search the script for the name; give modules a unique name (`SFX`).
- **One bad effect call broke the evolve cutscene** (NumberRange with min > max). Rule: effects inside a cutscene or any flow that hides the HUD / disables controls run in `pcall`. An effect must never block a flow.
- **Music can be "listened to" by measurement** when nobody can hear it: fetch the track in the browser (assetdelivery), decode it with WebAudio, and measure tempo, major/minor, brightness and whether the energy stays up. This filters a store search down to tracks that fit the hype rule. The owner still has the final say by ear.
- **A power-up and an evolve arrive almost together:** a window that waits for "no cutscene" must also wait a moment for the cutscene to START, and the window's ScreenGui hides while the cutscene runs.
## An icon must show what the game IS (13 Nov, Galaxy icon v2)
- What felt bad: the split-face icon (bacon half turned into a living galaxy). Owner: "the first icon doesnt make sense".
- Cause: we copied the GYM ARC winner's transformation layout without checking that the transformation exists in Galaxy. In GYM ARC the player really does grow into a titan; in Galaxy he never becomes a galaxy. The grade passed, the meaning failed.
- Fix: bacon (white, amazed) looking up at what he grew: his little rock island with a huge blazing star system rising from it (`galaxy_icon_v2_C_starsystem`).
- Rule: before borrowing a winning composition, write the game's core loop in one line ("tiny rock → huge star system → supernova"). The icon's story must be THAT loop. A layout from another game is only a template for framing, light and contrast, never for the story.

## Read the game's OWN research before any art (13 Nov, Galaxy icon v2, 2nd correction)
- What felt bad: icon C (an amazed bacon under a violet star system). Owner: "this dont look good, i think u forgot the research".
- Cause: I only skimmed the recipe's template. I never opened the research notes behind it, which already held a written Galaxy icon spec (in "What the owner clicks" and the "Roblox front page icons" note): an awed/worried bacon face lit by a star swelling into Supernova, one huge "+1", a warm star glow on dark blue, the face big and breaking the frame. I invented a violet scheme with no emotion and no number.
- Fix: icon D was made exactly to that spec in one try (new ChatGPT chat "Create Roblox Icon", with the game's low-poly `render_system.png` attached for the style), then graded in code (face protected, gamma 1.25, vignette).
- Rule: before ANY icon or thumbnail, open every research note the recipe links to, plus the game's shot list, and search them for the game's name. Copy any spec written there into the prompt word for word. Never invent a colour scheme when the research already names one.

## Our UI is still below the top games (13 Nov, Stomp Evolution)
- What felt bad: owner, after the "Claude UI method" TikToks: "our ui is worse than the top game uis".
- Cause: our UI research looked at button packs (BuiltByBit) and a few gameplay pictures per game, never at every screen of the real top games side by side with ours. Bing image search for "<game> shop ui" mostly returns fan-made remakes and script ads, not the real game.
- Rule: before judging or redoing a game's UI, get REAL screens (HUD, shop, daily, inventory, popups) of ~20 top games: frames from gameplay videos or the owner's own screenshots, never Bing "shop ui" results. Put each of our screens next to the same screen from 3+ top games, write the gaps as numbers (text size, icon size, empty space, colours), then fix.

## Stretched studs on 9-sliced plates (13 Nov, Stomp Evolution)
- What felt bad: owner: "the stud texture that ur using rn is being stretched out".
- Cause: the button plates were ONE wide ChatGPT picture (studs + glass streaks baked into the middle). 9-slice only protects the corners; the middle stretches. On tall cards (1:1.3) and big windows the studs became tall rectangles.
- Fix: plates are built in code (lip, gradient face, outline, shine, gradient glass stripes), and the studs are ONE small tile image repeated with ScaleType.Tile at a fixed pixel size, centred to whole studs.
- Rule: any texture with a repeating pattern (studs, stripes, dots, bricks) is NEVER inside the stretched part of a 9-slice. Put the pattern in its own tile image (ScaleType.Tile, fixed TileSize) over a plain body. Check every plate at its tallest and widest real use before shipping.
- Also: UI ClipsDescendants does not clip rotated frames. Effects inside tilted stickers must be gradient masks, not clipped children.

## Stacked pop-ups and the phone window too low (13 Nov, Galaxy, overstimulated-kid sim)
- What felt bad: the sim + Play found Ignition 1 firing TUTORIAL COMPLETE, the Ignition cutscene, the path card, LUMI's gift Forge window and 6 big sounds inside 1 s, with the Supernova card left open over the path card; toasts replaced each other in under a second. Owner then: "fix the forge window and supernova card too" (the Forge ran off the bottom of a phone, the SUPERNOVA! pill sat on it, the card's last line was cut).
- Cause 1: every emitter was built alone, each "showing itself"; there was no single queue, so the first chain that fired 4 at once stacked them.
- Cause 2: `GuiService.TopbarInset` is in SCREEN pixels but a ScreenGui's `AbsolutePosition` is below the GUI inset (-58 for IgnoreGuiInset roots), so the top bar counted twice (116 px): every phone window was centred 29 px low with 58 px less room. The device emulator in UIAudit (`Kit.testDevice`) bypasses that code, so the audit never saw it.
- Cause 3: `Kit.phone()` was read ONCE when a script started, before the camera had the phone's size, so "hide on phones" code never ran.
- Fix: one NEWS queue (toasts + NEW cards + banners: one at a time, read time words/1.2 + 0.5 s, merge same kind, wait during cutscenes and kid-paced cards), cutscenes close open cards, cards in a fixed order, one big sound per second; WindowManager.safeArea measures the top bar in screen pixels; Kit.phone() checked every frame.
- Rules for every game:
  - Every message, card and popup goes through ONE queue from day one. Nothing replaces anything; nothing draws during a cutscene.
  - Never mix TopbarInset (screen px) with AbsolutePosition (inset px): convert with GuiService:GetGuiInset() first.
  - Never cache Kit.phone() / screen size at script start; read it when you lay out.
  - Test UI in Play at a real phone size, not only in the audit's fake device.

## "NEW" moments every run (13 Nov, Galaxy)
- What felt bad: owner: "the star thing overstimulates me like NEW GAS GIANT or something and NEW {something}".
- Cause: the NEW moment fired whenever a body went from 0 to 1, and a prestige (Supernova) puts every body back to 0, so the same "NEW" played every run; named tiers (every 10 levels) had the same big moment. "New" meant "new this run", not "new to the player".
- Fix: the big moment only for a body new to the player; re-buys = their chime; tier ups = one small merged toast.
- Rule for every game with a reset / prestige / rebirth: a "NEW" celebration is for things the PLAYER has never had, never for things the reset took away. Repeats get a sound or a small toast, never a card or cutscene.
## A logo left inside an imported car (13 Nov, City Legends, owner's correction)
- What felt bad: the owner had said "remove all logos" for every imported car model, then saw the maker's round "EB" mark on the panel between the Veyron's seats ("why did i see this?").
- Cause 1: the logo checks looked at the outside, the steering hub and the driver's view forward. Nobody looked BACK from the dash, so the rear wall between the seats was never seen.
- Cause 2: that mark is not a badge part or a picture: it is moulded into one big cabin part (`Body_MOTOSO`), so the part-name sweep ("badge", "logo", "emblem") and the picture repaint both missed it.
- Cause 3: the first imports (3 to 8 Nov) were checked under a lower bar than the last 7, and were never checked again when the bar went up.
- Rules for every game with imported models:
  - "No logos" is checked with a FIXED list of views on every model, not by where logos usually are: outside front, rear, both sides, wheels, calipers, engine bay; inside from the driver's eye forward, from the dash looking BACK (rear wall, between the seats, headrests, parcel shelf), both door cards, sills, the hub, the pedals, the centre console from above, the headlining.
  - A logo can be a part, a picture, a normal picture (pressed in) or moulded geometry inside a big part. Check all four.
  - When the bar goes up, every older model is checked again under the new bar the same day. A rule that only the newest work follows is not a rule.
## Yangon's street lamps came out amber (14 Nov, City Legends, owner's correction)
- What felt bad: the owner saw the new Yangon street lamps and said "yangon lights are white, not dimmed lights".
- Cause: the lamps were copied from Monaco's (warm amber, sodium-style) to save time. Nobody checked what street lights in the REAL place look like, though the map is a real city that players from that city will know.
- Fix: white LED heads and light, a little brighter (head 236, 244, 255; SpotLight 232, 240, 255, brightness 7), applied to all 678 lamps and to the lamp kit.
- Rules for every game set in a real place:
  - Light colour is part of the reference study: street lights, shop signs and window light differ by city. Check the real place's photos at night before reusing another map's lights.
  - Copying a piece from another map is fine for its shape; its colours and materials must still match the new place.
## The Yangon map doesn't look like Yangon (14 Nov, City Legends, owner's correction)
- What felt bad: the owner put the game's top view next to Google Maps: "it dont look like the google maps one". The buildings are not accurate (real tall round towers came out as short squares), Inya Lake has no banks or park, and the industrial road is one lane each way where the real one has two.
- Cause: the map was built from road centre lines (OSM) and a generic building generator (plots along every road, made-up walk-ups, shophouses and villas). Nobody looked at the real place from above or in 3D before building, and no real building outlines or heights were used.
- Fix: a reference study first (Google Earth 3D, satellite), then real building outlines and heights, real lane counts, and the lake's banks and park.
- Rules for every map of a real place:
  - Before building, study the real place in Google Earth 3D (every district and landmark) and write down what makes it recognisable: landmark shapes and heights, building rhythm, park and water edges, road widths.
  - Use real data where it exists (building outlines and levels, lane counts) instead of generating stand-ins.
  - Check the result side by side with the satellite view from the same angle before calling a step done.

## In-game Yangon is too clean and empty (14 Nov, City Legends, owner's correction)
- What felt bad: after the batch 0.5 accuracy pass the owner said "the ingame yangon is too clean compared to real life yangon because in real life its compact and in game theres like barely any compared to real life".
- Cause: only the buildings drawn in OpenStreetMap were built (OSM misses most of Yangon's small buildings, sheds, shophouse infill and compound buildings), plots that touched a road were dropped or pushed back, and nothing else was placed: no walls, no clutter, no street life. The 1.6 studs a metre ground scale with car-scale roads also leaves more open grass between buildings than in the real city. "Real data" was treated as complete when it is only a floor.
- Fix: fill every block to the real density (count the real buildings per block on the satellite view and build to that, filling OSM's gaps with buildings of the area's own type), and add the lived-in layer: compound walls and gates, shop signs and awnings, roof water tanks, power poles and wires, parked cars and motorbikes, stalls and umbrellas, bus stops.
- Rules for every map of a real place:
  - Real data is a floor, not the answer: compare the built density with the satellite picture block by block, and fill what the data misses.
  - A real city is never clean: plan the clutter layer (walls, signs, wires, parked vehicles, stalls) as part of every district, not as a later polish.
  - Judge the density from the street, at a player's eye height, as well as from above.
## Yangon's overhead bridges are too low, and Fusan Basketball Court is missing (14 Nov, City Legends, owner's correction)
- What felt bad: "i think the overhead bridges are too low and also wheres the fusan basketball court, u need to add EVERY single detail".
- Cause:
  - The flyover decks were designed for road grades, not for the clearance under them, and nobody measured the gap from the road below to the deck's underside against a real flyover (about 5.5-6 m, which at the game's car scale of 3 studs a metre is about 17-18 studs).
  - Named real places were not treated as places. Fusan Basketball Court is in OSM (a big grey metal-roofed hall on Kabar Aye Pagoda Road); the generator saw only "a building, 3 floors" and made it a plain walk-up block with no name. Sports pitches, courts, pools and the like were not built at all.
- Fix: raise the decks to real clearance; every named OSM building and place gets its real kind (hall, court, pool, pagoda, school, market ...) and its name as plain text; every pitch, court, pool, playground and track is built with its markings, fences and goals.
- Rules for every map of a real place:
  - Measure clearances (bridges, flyovers, footbridges, tunnels) against the real ones, at the game's vehicle scale, and check them from a driver's eye.
  - Every named place in the data is a landmark to someone: list them all, give each its real kind and look, and check the list is empty of "plain boxes" before calling a district done.
  - "Every detail" means every feature type the data has (courts, pitches, pools, walls, gates, pagodas, bus stops, footbridges), not just roads and buildings.
## Generated batch roads, generic buildings and a map that doesn't load (14 Nov, City Legends, owner's correction)
- What felt bad (owner):
  - Roads from batch 1 on: "so bad and its like broken where some parts are not there, road turns aggressively, road is invisible, road is floating, road intersecting each other, overhead and normal road mixing, road markings wrong, road different color with the batch 0.5 road colors, roads inaccurate to real life ... basically every detail of roads". Batch 0.5's roads (built with the hand-designed part road tool) are alright.
  - "the map system is broken, sometimes some part of the map doesnt load, the new batch maps are not there".
  - Buildings: "nothing like the ones in real life ... myanmar plaza and all the other buildings look different in real life. in game its just some blocks with windows ... the sport centers are missing and places are missing ... placeholder buildings ... all the buildings need to be reworked. we can use blender".
- Cause:
  - The batch roads came from a new generator that turned raw OSM lines straight into meshes (no smoothing, no designed junctions, raw bridge tags, its own widths and colours) and was judged only by its own numeric checks, not by driving it and looking. The batch 0.5 road tool's look and rules were not reused.
  - Every 256-stud cell of buildings and roads became its own unique mesh asset: 15,537 unique meshes in the place. Roblox throttles that many downloads (HTTP 429 / 503 / 504 in Play), so parts of the map never load.
  - "Real outlines extruded with a facade picture" is not a real building: real Yangon buildings have their own shapes, roofs, colours and details; landmarks need hand-made models from photos.
  - Speed over quality: three batches were pushed through before one batch was accepted by the owner.
- Fix: park the batches out of the Workspace; rebuild with (1) a building KIT made in Blender from photos (a few hundred real Yangon building models, each uploaded once and reused, so few unique assets), (2) hand-made models from photos for every named / known place (malls, towers, hotels, markets, sports centres, pagodas), (3) roads built like batch 0.5's (designed centre lines, the same widths, colours, kerbs and markings), (4) one batch at a time, accepted by the owner before the next.
- Rules for every map:
  - Count unique mesh assets: reuse meshes (a kit), never one unique mesh per map cell.
  - A new system must match the look the owner already accepted (same colours, widths, markings) and be judged by driving it in Play and looking, not by its own numbers.
  - One district at a time to the owner's bar; never bulk-build the next before the first is accepted.
  - Known places are modelled from photos, not generated.
- (Same day, terrain) Owner: "the terrains and everything is wrong too, in real life theres hills and stuff, i think u need to try to find yangon terrain map or something". Cause: the ground came from SRTM 30 m run through a 3x3 minimum filter and a wide Gaussian blur (to take out roofs and trees), which flattened Yangon's real ridges (the Shwedagon - Bahan - Kaba Aye ridge, the slopes down to the Hlaing River and Pazundaung), and nobody compared it with a topographic map. Rule: the ground of a real place is checked against a topographic map (contours, hill shading) and photos of its slopes before roads go on it; use the best open elevation model (Copernicus GLO-30 or better) with the lightest filtering that removes buildings, and keep every hill a local would know.
- (14 Nov 2026, City Legends Yangon, Myanmar Centre pilot) Owner: "make myanmar plaza 3d, not with textures and decals, make interior of myanmar plaza too and also sedona". What felt bad: the first landmark version was a box massing with its windows, bands and names painted on one picture atlas: it looked right in a still picture but flat up close, and the inside was empty. Cause: the atlas route was carried over from the generated buildings for speed. Fix: real geometry (bands that stand out of a recessed glass skin, real mullion fins, 3D letters, canopies on struts) with Roblox materials per part, and the public interior a player can walk into (from photos of it: atrium, galleries, escalators, shops). Rules: a named landmark is built in real geometry, not a painted facade; pictures only where the real thing is a screen or a billboard; a building people go into in real life (a mall, a station, a hotel lobby) gets its inside too; buildings without an inside get opaque lobby glass, never see-through glass onto nothing. Also: in this map Roblox's Granite, Marble and ClayRoofTiles materials render near-black and full-white Neon blooms; check every material in a Studio screenshot before calling it done.


### 2026-11-16 - City Legends: a real place must be at real scale, under a measured light (owner correction)
- **What felt bad:**
  - "the materials, textures, looks, colors, designs, lighting is not same as the real life myanmar plaza"
  - then "the scaling measurements must be 1:1 accurate too"
- **Cause:**
  - The Yangon map's ground plan was at 1.6 studs per metre while cars and players are at 3, and floors were player height. Buildings came out too tall and thin, and players and cars twice too big.
  - The day light was Monaco's, so every white rendered pale blue.
  - Colours were picked by eye, and textured materials render much darker than their colour.
- **Fix:**
  - Owner chose "Everything at player scale": the whole Yangon map is rebuilt at about 3 studs per metre.
  - Yangon's daylight was warmed.
  - Colours were measured from photos and calibrated to the game's light.
- **Rule:** for any real place, lock one scale for map, buildings, cars and players first; measure the game's light; then set colours from photo measurements. Method: [[Brain/Methods/Real-world look match]].


### 2026-11-16 - City Legends: white read as cream twice (owner correction: "why are u wrong at this, learn from ur mistakes")
- **What felt bad:**
  - "myanmar plaza walls are white and not yellow"
  - then the towers' bands: "i think these are white too, and not yellow"
- **Cause:**
  - I set the colours from late-afternoon and dusk photos. Low sun turns white panels and white stone beige or cream.
  - I trusted those numbers over the midday photos, which showed the same panels near-white.
  - A slightly warm white-balance check (a kerb) did not catch it.
- **Fix:** tower A, tower B and the crown went white, then the podium bands and the mall's insides.
- **Rule:**
  1. Take a surface's colour from the most neutral-light photo you have: midday or overcast, never sunset or dusk.
  2. When photos disagree (beige at dusk, white at noon), it is white. Paint and cladding are almost always lighter and more neutral than evening photos show.
  3. Before building, list the main colours as words ("white panels, dark glass") and check them against what people would say about the building.
  4. If the owner names a colour, theirs wins.

## 2026-11-17 MM Outfit Catalog: owner corrections
- **"There are still 3 of them looking."**
  - What felt bad: only the nearest mannequin turned, but the other two kept their rest pose, which faces straight out at the player, so all three still seemed to stare.
  - Cause: Claude checked the turn ANGLES (0° vs 17°), not what it LOOKS like from the player's camera.
  - Fix: the non-watchers turn 40° away.
  - Rule: **judge "looks at you" effects by a screenshot from the player's view, not by numbers.**
- **"The outfit loader overstimulates me."**
  - Cause: Claude guessed "outfit UI" meant the Outfit ID box and removed that; the owner meant the full-screen viewer.
  - Rule: **when a UI name is ambiguous, screenshot the candidates** (or open the one the player sees most) before changing anything.
  - Calm rules that fixed it: one green per screen, no glow rings or shine, normal-weight title instead of a shouting condensed one, sentence case, one-time hints.
- **"I can't see the rain from inside."**
  - Cause: Roblox **Glass material doesn't draw particles behind it**.
  - Rule: windows that must show rain, snow or VFX outside use SmoothPlastic with Transparency 0.85+ and Reflectance 0.1–0.15.

## City Legends 1:1 Yangon: "the old map vibe was better, this feels dirty" (16 Nov 2026)
- **What felt bad:** the owner said "this vibe feels dirty and the trees are so ugly and unattractive. the grass patches look bad too, the first version grass looked better", and also "still no inya lake border walls (i thought u researched them....???".
- **Cause:**
  - We chased photo-real grime: dirt, earth and gravel patches, and stained textures. We put the new low-poly trees in place without comparing them to the old kit.
  - The researched lake edge (the Pyay Road bund wall and railing) was never put in any agent's brief, so nobody built it.
- **Fix:** go back to the clean grass of the first version; use trees that look at least as good as the old map's kit; build the Inya bund.
- **Rule:**
  1. Real-world accuracy means real shapes, sizes and places, but the look stays clean and attractive. Never add grime or dirt that makes the game look dirty.
  2. Before replacing any look (trees, grass, materials) everywhere, show a side by side with the current one and keep the better one.
  3. Every researched feature must appear in a build brief, with a check that it got built.

## City Legends 1:1 Yangon: "why are the buildings just blocks, even the old one was BETTER" (16 Nov 2026)
- **What felt bad:** after the light-buildings pass, far views and Studio's Edit view showed plain boxes; the facade detail only came within 1,000 studs in Play.
- **Cause:** we judged the light pass by part counts and Play close-ups. Nobody looked at it the way the owner does: from far away and in Studio Edit.
- **Fix:** the shells wear a window-grid material (looks like a building from any distance), and a local Studio plugin builds the real detail round the Studio camera.
- **Rule:**
  1. A performance trick (LOD, streaming, stand-ins) must still look like the game from far away AND in Studio Edit. Check both views before reporting.
  2. Never let a stand-in be a plain coloured box: give it at least the right texture (windows, floors) for what it stands for.

## City Legends 1:1 Yangon: "so many more mistakes on the roads" (17 Nov 2026)
- **What felt bad:** the owner found broken roads everywhere:
  - median spikes
  - flyover ramps built as earth banks with jagged walls, and decks ending in mid-air
  - streets ending in grass with a line painted on beyond the end
  - kerb shards in junctions
  - grey concrete blobs on the grass
- **Cause:** the agents checked a few hand-picked spots in Edit screenshots and declared the roads done. Nothing scanned every junction, road end and deck.
- **Rule:** generated road networks get an automated QA pass over **every** junction, road end, median end and deck before anything is shown to the owner:
  - lines outside asphalt, kerbs inside a carriageway, decks with gaps, overlaps with buildings
  - plus a contact sheet of the worst spots
  - "Looks right in 3 screenshots" is not done.

## City Legends 1:1 Yangon: grey "concrete blobs" on the grass (17 Nov 2026, owner's screenshots)
- **What felt bad:** irregular grey patches all over the grass (yards, beside streets, open lots), like spills.
- **Cause:** `green_1to1.py` painted terrain Concrete on OSM paved / commercial areas and on noise-edged "forecourts"; smooth terrain blends any painted patch into a soft blob.
- **Fix:** every non-grass land voxel in P1-P3 repainted to plain Grass (`YangonGreen1to1.unblob`; road beds, water / mud edges and P3's quay and piers kept); the tool paints no terrain concrete any more. Note: [[City Legends/2026-11-17 Concrete blobs on the grass removed (P1-P3)]].
- **Rule:** never show a paved surface by painting terrain. Paved ground is a part or mesh slab with straight edges at the right height; terrain stays one clean material.

## City Legends 1:1 roads: "in google maps its entirely different" (17 Nov 2026)
- **Cause:** the 1:1 rebuild skipped a step from the owner's 13 Nov plan: a street plan picture (our roads over the real map and satellite) that the owner approves **before** building.
- **Rule:** every district's road network gets an overlay picture plus an automatic mismatch check against OSM and satellite, approved by the owner before it is built.

## 2026-11-17 City Legends: a QA check that only counts what you kept hides what you dropped
- **What happened:** the road plan overlay said "0 missing OSM roads", but the owner compared one junction with openstreetmap.org and found every slip road (`*_link`) missing. roads05 drops links on purpose, and the check only counted the roads roads05 keeps.
- **Rule:** a "missing" check must compare against the full source (every drivable OSM way), never against your own filtered list. Show close-up crops of big junctions next to the source map before asking for approval.

## 2026-11-17 City Legends: a QA check must copy the builder's own rule, not approximate it
- **What happened:** the roads05 junction QA said 25 "mouth_edge" failures; a Python copy of YangonRoads' real mouth edge walk found 1,621 joins the Studio builder would fail. The QA tested "does the edge touch the bigger road's polygon", but the builder walks only ONE road's edge, so every junction where the bigger road itself ends at the node (L corners, T junctions on a road split in two pieces) failed in Studio and passed in QA.
- **Rule:** before trusting a pre-Studio check, port the exact rule the builder runs (same inputs, same edge, same limits) and confirm it against one Studio build. Fix the data so that check is 0 (chain pieces meeting end to end into one road), not the check.

## 2026-11-17 City Legends: a slow script is usually one global operation inside a loop
- **What happened:** roads05_paint ran over 30 min on 12 districts and was killed. Each dashed lane line was cut by a union of every junction box in the city, rebuilt for each dash. An STRtree of the box pieces (cut each line only by the pieces it touches) brought it to 73 s.
- **Rule:** when a job gets slow as the map grows, look for a whole-map geometry (union, difference, scan of all samples) inside a per-item loop; index it once and query locally.

## 2026-11-17 City Legends: "first to last" spans hide gaps; and a test must not write into the real place
- **What happened (1):** roads05 made a flyover deck from a road's FIRST raised sample to its LAST. Lay Daungkan Road has two real bridges 12 km apart, so one 12 km deck covered every ground junction between them, and the slip roads at Waizayandar ended on nothing (the 15-20 stud gaps of the J5 Studio test). Kabar Aye's two flyovers were merged the same way.
- **What happened (2):** YangonRoads stored each round corner's angle on the ring using the CURRENT roundabout's centre. With several roundabouts in the data that was often another ring, so the ring's kerb ran on under the corner (the loose kerbs on Sule roundabout).
- **What happened (3):** the earlier junction tests wrote grass terrain (verge, cut ends) at ground level into the main place, outside the built map (76,583 voxels found and removed at Pyay x University Ave and the slip triangle).
- **Rule:** split any "from first to last" run where the gap is long (one deck per raised run); set the shared state (current ring, current road) right before every calculation that reads it; a Studio test on the real place runs a copy of the builder whose terrain writes go nowhere (`workspace.Terrain:Fill...` swapped for a no-op), and leaves nothing behind.

### City Legends roads05 J8 (17 Nov 2026): roads that pass a roundabout, and continuations
- **What happened (1):** Lane #4701 (a slip road by Roundabout 1) runs 2-3 m off the ring in OSM without joining it. Its inner kerb lay inside the ring's own kerb / pavement band, so the builder cut it piece by piece where the band's circle crossed it: a sawtooth kerb.
- **What happened (2):** Lower Pazundaung Road carries on from Upper Pazundaung Road #3's end but was 18 studs narrower and 14 off-centre, so part of the host's end line had no road on the far side: grass in the Y.
- **Fix:** `roads05_fix.ring_clear` pushes a passing road out (tapered) until its inner kerb clears the ring's pavement; `butt_match` starts a single continuation on its host's full end cross-section and tapers back over 40 studs.
- **Rule:** any road that runs beside another surface's kerb / pavement band without joining it needs the full band between them (or it must join); a road that carries on from another's end must start on that end's exact width and centre.

### City Legends roads05 J9 (18 Nov 2026): roundabout points, islands, ring heights
- **What happened:** the "kerb points" at every Hanthawaddy arm came from ONE bad stretch of ring: two one-way arms overlapped at the ring, so one stretch's end angle was before its start, and the code added a full turn: the ring's kerb ran 352 degrees over every arm. The scrub step deleted most of it, leaving only the points. Three passes looked at the corner radius instead.
- **Rule:** before tuning a shape, list the actual parts at the fault (folder = which builder made it). Here the parts at the point belonged to the ring, not the corner, and that pointed straight at the ring's stretch list.
- **What happened (2):** Sule's arms reached the flat ring up to 5 studs higher or lower (the height data round the pagoda). Steps showed only as dark slivers from above. Rule: compare the arm heights with the ring's height for every roundabout (a 10-line check) before any visual test.
- **What happened (3):** traffic islands were left as bare ground because nothing builds "the inside of a hole". The fix paves exactly what the kerb bands and corners leave open. It doesn't draw a slab under them, so nothing overlaps.

### City Legends roads05 J10 (18 Nov 2026): one global constant ate a street's pavement
- **What happened:** a 9-stud pavement gap on a slip road at Pyay x University Ave, and a small hole at an island tip, came from two zone tests that were too big, not from the band builder. The corner zone reached 26.7 studs from its centre across a narrow street onto its far kerb, and the "past the corner, this road owns its band" test used the main roads' 7.5-stud pavement for a 4-stud street, so it deleted 3.5 studs of the other road's band that the street never replaced.
- **Rule:** when a piece is missing, ask each zone test at that point (`sideZone`, `inCorner`, `ownedBy`) which one said "not yours" before touching the builder. A zone must stop at the kerb line it rounds, and any width in a zone test must be that road's own width, never the global default.
- **What happened (2):** an island vertex lying between a corner's tangent point and its corner point was treated as a straight vertex, so the fill's outline folded back over the corner pavement (a square hole). A vertex closer to P than the tangent length belongs to the corner.

### City Legends roads05 J11 (18 Nov 2026): "the wider half" and overlapping helpers
- **What happened:** four different marks (a missing kerb at Sule, a sawtooth pavement break at the slip triangle, a 72-stud blind spot at Bahan, a corner kerb deleted as "scrap") came from one habit: every width test used `halfAt` = the WIDER half of the road. Roads in the 1:1 data are often lopsided (Maha Bandula #2 is 39.6 studs on one side and 21 on the other, Bahan Road 76 on one side after absorbing its second carriageway).
- **Rule:** any "is this spot on that road" test uses the half on the spot's own side (s[7] left / s[8] right), and any distance cut-off must grow with the road's own width.
- **What happened (2):** two round corners of one short slip lane (one at each end) both claimed the same stretch of kerb, so two kerbs ran side by side; and "past the corner this road owns its band" reached 60 studs on into the lane's other junction. **Rule:** a helper zone made for one junction must stop at the road's next junction (its other mouth span) and at any bigger road's carriageway; when two helpers of one road side overlap, shorten the looser one rather than dropping it (dropping the merge corner left pavement teeth).
- **What happened (3):** island marks came from each road's pavement band paving its own strip of the island at its own height. **Rule:** a small enclosed area gets ONE surface owner (the island fill), and every band is told to stay out of it.
- **What happened (4):** a "hole" in the Bahan test was the test box: the slip's mouth belonged to a sample just outside the 520-stud box, so nobody laid it. Before fixing a missing piece at a test's edge, check which cell owns it.

### City Legends roads05 J12 (18 Nov 2026): chords vs true width, and "shorter" is not "safer"
- **What happened:** the Bahan kerb notch had two causes, and the first guess made it worse. Capping a shallow merge corner's radius (r 101 -> 30) opened a 30-stud kerb gap: in a shallow merge both straight kerbs are cut out round P anyway, and only the long arc covered that stretch. The real fault was the scrub: the big road's built edge runs in straight chords between samples, but the scrub measured "on the carriageway" with the road's true width (Kan Yeiktha is 68 studs wide and bends), so the arc's last kerb pieces, sitting exactly on the built edge, counted as "1 stud on the road" and were deleted. Its pavement also took its height from cut samples next to the ring (4 studs low).
- **Rule:** when two tests disagree about where an edge is (the built chord vs the ideal curve), the pieces placed against the BUILT edge must be judged by the built edge (a corner's own pieces are exempt from the scrub against its own big road). Never take a height from a cut sample: use the nearest built one plus the data's change of height.
- **Rule:** before shrinking or dropping a helper piece (a corner, a fill), check what covers that area without it. Test the change in the shot first, then keep it.
- **What happened (2):** Sule's "seam" was a crease: a cross street 30 studs off the ring kept its old height, the builder's junction height held Maha Bandula 0.7 above the ring until 4 studs from its edge. **Rule:** level a roundabout's surroundings flat out past the nearest junction (ring_level's RING_FLAT 40), not only the arms' own samples.
- **What happened (3):** a "fix" that ran street ends on to an OSM-joined road (34 ends) lowered no QA count (the ends met the road side-on, so no mouth formed) and added 2 rows: reverted. **Rule:** check a data fix's effect on the QA counts before keeping it; an OSM join beside the road (shallow merge) needs a merge taper, not a run-on.

### City Legends roads05 J13 (18 Nov 2026): read a QA row before fixing it, and keep height edits position-only
- **What happened:** 49 "OSM join" mouth rows looked like 49 open joins. About half were the QA's own blind spots: a 6-sample stub whose OTHER end is its mouth on a road was flagged "runs past" that road; a T on a smaller road's sharp bend looked like a 7.9-stud gap because the bend's quads fold; a far kerb counted as "on" a street whose data runs past the kerb, though the builder stops that street at the near edge (its mouth). The rest were real: ends 1-12 studs beside a road (a bend onto its centre line fixed them) and run-past ends (cut back to the crossing).
- **Rule:** for every QA row, first ask "what does the BUILDER lay here?" A QA test drawn on the data (quads, centre lines) must skip what the builder never builds (a mouth's run-on, a road's own mouth end), or it sends you fixing ghosts.
- **Rule:** classify against OSM with only the ways we build (`roads05.keep_way`): an end joined in OSM only to a driveway / private way is a dead end on our map.
- **What happened (2):** easing roads to a roundabout's height by scaling each sample's gap made a road that climbs away from the ring 6.5-10% steep at the ramp's end. A per-road "fade the step" fixed the grade but broke junctions: two roads meeting at one sample got different heights. **Rule:** any height edit near a junction must be a function of position (or must pin shared samples), so roads that share a sample still share its height; spread the change evenly between pinned samples along each road for the least extra grade.
- **What happened (3):** a deck regrade capped at 7.8% lowered some flyovers under 5 m over the road they cross, and short decks whose feet differ by 50 studs cannot be under 8% at all. **Rule:** regrade only where it is no worse than before and keeps the old clearance (or 4.5 m); a deck that still needs more is a deck-length problem (roads05.py), list it, do not force it.

### City Legends roads05 J14 (18 Nov 2026): a QA rule must test what the owner sees, not the data's shortcut
- **What happened:** the first `carriageway_too_narrow` count (570) was mostly false: a chained road holds one-way AND two-way OSM pieces under one record, so the road-level `oneway` flag called every one-way piece "two-way, too narrow". The first `paint_off_centre` (100) measured a curved line's centroid, which lies off the line. **Rule:** a rule reads each sample / each item on its own terms (a sample is one-way when its lanes fill its width; a line's position is a point ON it), and the taper between two pieces is left out.
- **What happened (2):** smoothing a deck's profile with its end samples pinned undid `deck_regrade` (deck_grade 7 -> 26, all at the pinned ends). **Rule:** one step owns each quantity (the profile belongs to deck_regrade); a later smoothing pass touches only what it owns (the plan line).
- **What happened (3):** a deck rule (keep a deck only over a road / railway / water) first tested only the run where the profile is 6+ studs up: real bridges at Yangon Central and Hledan were dropped because the railway lies under the ramp, not the run. **Rule:** test a structure's whole reach (run + ramps), and when the owner says "never drop X", make the drop test conservative and LIST what it drops for him.
- **Rule (owner, 18 Nov):** a simple bridge (the whole road over a railway / river, no ground lanes beside it) carries its road's own width, lanes and median; a flyover (deck + ground side lanes) keeps its real deck width and is never widened to the ground road.

### City Legends roads05 J15 (18 Nov 2026): order steps by what they read, and check a smoothing's end padding
- **What happened:** deck_grade went 7 -> 24 in J14 although no profile changed: `deck_regrade` ran BEFORE the plan smoothing, and the smoothing padded each end by repeating the end point, which pulled the samples next to it together (shorter spacing, same heights = steeper). **Rule:** a step that measures along a line (grade = rise / run) runs AFTER every step that moves the line; pad a moving average by point reflection (2 x end - neighbours), which keeps the end exact and the spacing even. A short ease back to the original near the ends is itself a kink (deck_wobble rose).
- **What happened (2):** Shwedagon Pagoda Road was 22.5 / 43.5 studs a side: OSM tags one carriageway `lanes=4` (the whole road's count) and the other `lanes=2`; and absorb chose the "bigger" road by "ends on" rank, so the primary went INTO a service lane. **Rule:** a dual carriageway's sides take the smaller count when one is twice the other or more; when two roads are merged, the bigger is decided by OSM class first, rank only between equals.
- **Rule:** a deck too short for 8% at its clearance grows along its own road (longer ramps) only where no other road joins or crosses; otherwise it is listed, never forced through a junction.

### City Legends roads05 J16 (18 Nov 2026): one bridge in named pieces is still one bridge
- **What happened:** Thaketa Bridge, Lanmadaw Rd and Sule Pagoda Rd came out 10-18 studs too low: OSM cuts one structure into named ways (Thaketa Bridge -> Set Yone St, Lanmadaw Rd -> Myoma Kyaung St, Sule Pagoda Rd -> Gyophyu / Alan Pya Pagoda Rd), each became its own deck, and every deck's two ends were pinned to the GROUND as feet: the bridge dipped to the road at each joint, right beside the railway it crosses. The QA's deck_foot even demanded it. **Rule:** deck ends that meet are a joint, not a foot: regrade the chain as one deck (feet only at its outer ends, a fork's branch held at the chain's joint height, chainage with no sideways jump across a fork), and say so in the QA (deck_foot skips joints).
- **Rule:** clearance is a hard need, not a "keep the old top" wish: 4.5 m over any OSM railway=rail, 3 m over water, tested by its own QA rule (deck_clear) against the ground under the deck; a deck too short for it grows its free feet along its road (longer ramps), and only when a junction blocks that does it get steeper (then the least grade that clears, never the old top's grade).
- **Rule:** a fix that only closes the gap to the QA threshold (fair a deck until its wobble is under 0.15) is fine when the move is small and measured (here <= ~3 studs plan); check it did not undo another rule (deck_clear, deck_grade) in the same run.
- **What happened (2):** absorb took the two ends of Bogyoke Aung San Road's second carriageway (on the road) but kept its middle (0-1 stud beside it), and the widening's ease ran onto that middle: QA overlap. **Rule:** a stretch just beside the road between two absorbed stretches goes too. Tried and dropped: absorbing any lane with a quarter of its area on a road (kerb_cross 17 -> 23: the cut pieces ended alongside the road). **Rule:** run the full QA after a rule that cuts roads into pieces; a cut that leaves ends alongside a road is worse than the overlap it removed.

### City Legends roads05 J16 Studio test (18 Nov 2026): a test tool must pin its data and paint only on what it built
- **What happened:** the first paint pass hung lines in the air: paint polygons that cross the test box edge (the builder stops at the box), deck paint whose deck was not built (`buildDecks` builds a deck only in the cell that holds its middle sample), and deck paint named after the DECK (not its road), so its height came from nothing. Meanwhile the geometry and paint agents wrote new roads.json / paint.json mid-test (476 vs 479 roads in the subset).
- **Rule:** clip test paint to the box, look heights up by road OR deck OR ring name, ray each vertex onto the surface nearest its data height and leave out any triangle with a vertex more than 6 studs off (count it: that count is a QA signal). Copy the network being tested into the test's own folder before the first upload, so parallel agents cannot change it under you; name the commit in the note.
- **Rule:** a spot's box must reach the middle of every deck you want to see (or the deck is silently missing and its ground cut shows as an empty square). Driver cameras go on the middle of the right-hand carriageway (past the median), never on the data centre line.
- **Rule:** MCP calls that start a build come back "Target is not reachable" while Studio is busy; start the build in one call (task.spawn), poll in short calls, never repeat the start.

### City Legends roads05 J17 paint (17 Nov 2026): check your own "every approach" rule against photos, and measure a curve by its true ends
- **What happened (1):** J15 put stop lines and turn arrows on every main-road approach "for a marked look". Photos of Yangon from 2018-2021 (Commons) show them only at signalled junctions; unsignalled corners have the yellow zebra and nothing else. 912 approaches were painted, 494 are real.
- **Rule:** a "paint it everywhere" choice is a guess until 2+ dated photos back it. Key a marking to the data that decides it in real life (here OSM traffic signals near the box: roads.json `junctions`), and write the check into the research note.
- **What happened (2):** dash_jog flagged 76 rows, most on bends: the QA took a dash's ends from its minimum rectangle, which on a curved dash sits a sagitta off the line. Taking each end from the dash's flat cap (end point = cap middle, tangent = square to the cap) cut it to 24 with no paint change.
- **Rule:** before "fixing" a QA row, look at it top-down; if the paint looks right, fix the measurement and say so (a QA that cries wolf hides the real rows).
- **What happened (3):** solid yellow blobs on Kabar Aye Pagoda Road: a kerb line that crossed itself buffered into a ring, and the paint list keeps only a polygon's outside, so the hole was painted solid. Also a ramp 70 studs over U Htaung Bo Road counted as a "mouth" and wiped its kerb line.
- **Rule:** remove self-crossings before buffering a line, drop any "line" polygon fatter than 1.6x its width, and never treat two roads as joined where they are more than a storey apart in height.

### 2026-11-18 City Legends roads05 J17 geometry: clean-up from the built surface, not from the data
- **What happened:** kerb stubs and buried kerb lines in junction boxes (Kun Chan x Gyophyu) survived every data rule (kerbsim, scrub's "on another road's carriageway"): they lay on their OWN road, on cut samples or under a mouth slab, which the data tests skip. A raycast check of the built parts (asphalt all round a piece, 8 probes, looking through kerbs and pavers) found and removed 892 pieces at that spot and nothing legit.
- **Rule:** for "stray piece" bugs, the last clean-up pass should test what was actually built (raycasts on the built parts), not re-derive it from the data that made the mistake.
- **What happened (2):** the owner's "jagged corner pavement" steps were 4-stud terrain voxels of the corner's grass, laid right at the pavement's back edge at centre-line heights (higher than the built edge). A no-terrain Studio test cannot show it.
- **Rule:** grass beside a part surface starts under the part (4 studs in) at the part's own heights; check terrain-edge bugs in the real build, not in a no-terrain test.

### 2026-11-18 City Legends roads05 J18 geometry: a new data field must be checked where the builder READS it
- **What happened:** the new `cornerR` field was in roads.json, but the Studio corners did not change: `YangonRoads.load` builds each road object from a fixed list of named fields, so any new field is silently dropped. Found only because the Studio log prints each corner's radius.
- **Rule:** when adding a data field for the builder, grep the loader for how records are copied, and prove it in Studio with a printed value (log line), not by "the data has it".
- **What happened (2):** Bahan Road #2 merged into Bahan Road edge to edge (no overlap area), so the doubled-road absorb never paired it; the merge pass also lost its curved end (cos 0.89 < 0.9) and left #2's ring end as a gap until the merge rule took a looser angle.
- **Rule:** a "merge" (a one-way converging onto the road it ends on) is its own case: pair by "my end lies on you", absorb the gore under 2 kerbs + 2, and run a second pass for slips that ended on the absorbed road.
- **What happened (3):** the Sule Shangri-La corners the owner drew are where two roads CROSS; the builder rounds corners only where a road ENDS on another (mouths). A bigger radius setting cannot reach them.
- **Rule:** before tuning a builder number for an owner ref, check which builder path draws that spot.

### 2026-11-18 City Legends roads05 J19 (geometry: width_wobble, crossing corners, seams, pavements)
- **What happened:** two J18 passes (drop fold-back samples, cut a road's flare to the deck at a deck joint) each changed widths after the width-taper pass, so QA width_wobble went 0 -> 14.
- **Rule:** any pass that edits widths or deletes samples runs BEFORE the taper pass, or the taper runs again after it; a cut at one sample is a taper walked outward, never a one-sample step.
- **What happened (2):** the "seam lines" across the Kun Chan box were not cracks: both crossing roads laid full carriageway through the box at heights 0.05 apart (crossing lines, z-fight). A raycast grid with a second-difference test told steps, slopes and cracks apart; a plain neighbour difference counted slopes as steps.
- **Rule:** at a crossing only the bigger road lays the box; the smaller road's arms are built as mouths cut on the bigger road's kerb line. Measure a seam in Studio (grid of rays, jump beyond the local slope) before changing builder code.
- **What happened (3, owner "pavements not smoothly connected"):** a per-record setting (downtown pavement width) made a road change pavement width in one step wherever OSM splits the road into two records (Kun Chan Road 28.7 next to 7.5).
- **Rule:** any per-record width must match across continuation joints (take the narrower so no pavement runs under a building); QA `pave_width_jump` / `pave_step` watch it.

### 2026-11-18 City Legends roads05 J20 (geometry: forks, crossing kerbs, corner arcs in the road, flyover crest)
- **What happened:** Lane #3414 lay on Kun Chan Road #3 for ~40 studs: both "carried on" from Kun Chan Road's widened end, 25-31 studs off its end sample, so the fork test (joint within 3 studs) never saw them, and the alignment tie went to the record listed first.
- **Rule:** a fork is every record joining one host end within that end's half width + 3; the widest record carries on, a record lying inside it is trimmed back and starts as a mouth on it. Break ties toward the wider road.
- **What happened (2):** QA kerb_cross counted 10 kerbs at crossings that the builder already removes (J19 made crossing arms mouths), so the count looked stuck at 12.
- **Rule:** when the builder learns a new junction type, teach the QA's builder simulation the same day, or the QA reports work that is already done.
- **What happened (3, owner "random pavements in the middle" by Yangon Central):** a crossing corner's arc landed on another road's asphalt and was built as a floating quarter-ring of kerb and pavement; the stray clean-up probed from a WedgePart's box centre, which lies on the triangle's long side, so curved pieces escaped it.
- **Rule:** before building any corner, test its whole kerb arc and pavement against every carriageway and gore, and drop it if any point is on asphalt (QA corner_in_road). Clean-up probes start at a triangle's centroid, never at a wedge's box centre.
- **What happened (4):** the Pinlon Road Flyover's water clearance was asked at every deck sample inside the OSM river area, which runs up to the east foot, so no ramp could give it and the deck kept OSM's profile (peak 200 studs before the creek).
- **Rule:** a water or rail AREA asks for its clearance at the middle of the deck's run over it (the channel), and the crest goes there; the feet stand on the banks.

### 2026-11-18 City Legends roads05 J21 (geometry: QA artefacts, dropped corners, faired ramps)
- **Mistake:** J20 named "thin pavement wedges 0.29-0.41 under their neighbours" a builder fault. Probing the parts showed every such wedge's top is flat at the right height: the QA ray had run down a WedgePart's vertical slanted face and hit it part way down. **Rule:** before fixing a fault a ray grid reports, look at the hit itself (part, normal, all three corners). A hit whose normal is not up is a graze, cast again a hair off. With that, Kun Chan pave_step 64 -> 17, road_step 50 -> 13.
- **Mistake:** a ray-grid QA over a test cell counted the cell's own clipped edges and the subset's cut deck ends as kerb gaps (most of 50-200 per spot). **Rule:** a built-surface QA skips a margin at the test box (20 studs) and a deck's open end; count only what a player could meet.
- **Rule:** dropping a corner whose arc lies on another road leaves two square kerb ends: try the same corner tighter first (shorter tangent) and drop it only if no tight arc clears (Kun Chan box: 15 tightened, 6 still dropped network-wide in the pack).
- **Rule:** any step that moves a deck's plan after its regrade (fairing, unfold, joint tapers) changes the spacing and so the grade (7.8% became 8.1%): re-check the grade after the LAST plan change, not after the regrade.
- **Rule:** a fork record trimmed back so it now ENDS inside its sibling must be re-ranked, or it outranks the road it ends on and no mouth is built (Lane #679 on Bo Min Gaung Street).

### 2026-11-18 City Legends roads05 J22 (geometry: roundabout kerb gaps, island fills, mouth steps)
- **Mistake:** Roundabout 4's 48 "box holes" were nearly all QA rays on whole-stud grid points running exactly down the shared edge of two touching wedges (a jitter of 0.002 hit). **Rule:** a ray-grid QA casts a miss again a few thousandths off before calling it a hole; then look at what is left with a 0.5-stud character map of the parts (folder letter, `#` kerb, lower case pavement): it shows which road owns each side of a gap at once.
- **Mistake:** a test "is this spot in that road's band" used the road's WIDER half (`halfAt` = max of left / right). On a divided road with an absorbed slip (Sule Pagoda Road 64 / 33 at Roundabout 4) a lane 30 studs off its narrow side was "owned" by it and lost 40 studs of kerb and pavement. **Rule:** every inside / beside test uses the half on the spot's own side (`sideHalf`), never the max.
- **Mistake:** an island fill triangulated from a few outline corners interpolated heights across 100-stud sides between roads at different heights and stood up to 1 stud over the kerbs (buried them: kerb_gap). **Rule:** cut fill outlines into short pieces (4 studs) with each point on the built edge's height (interpolated along the edge segments, not snapped to the nearest sample).
- **Mistake:** downtown pavements were widened to the OSM building line straight across another road (Lane #7793 walk 24.6 over 32nd Street): scrub then cut the band to teeth. **Rule:** another ground carriageway on the way to the building line is a building line too (1 stud before it).
- **Rule:** a road whose end lies on a bigger road takes the host's height there, with the step faded along it (3%, 20-120 studs): a merge 1 stud higher than the host's edge made a 40% crease in the mouth slab (deck feet).

### 2026-11-18 City Legends roads05 J23 (geometry: QA side faces, cut / lone samples, round caps, island kerbs)
- **Mistake:** J22's "retry a missed ray a hair off" took whatever it hit, often the 4.7-stud vertical side face at a pavement's outer edge: deck spots' pave_step went 5 -> 35 and looked like "pavements 4.7 lower". **Rule:** a QA retry keeps only a hit whose normal points up; a cell that only finds side faces is an edge, no fault either way (univ_kabaraye pave_step 35 -> 1, road_step 28 -> 17).
- **Mistake:** a distance-to-road helper fell back to "distance to sample i" when every segment round i was cut, so a deck's cut ground samples (and one lone uncut sample between two deck cuts, 45 wide) still counted as road: side lanes under the flyover lost their inner kerb, a junction box lost a kerb in a 45-stud circle. **Rule:** a cut sample, or an uncut sample with cut segments on both sides, is no road: the builder lays segments, not samples.
- **Mistake:** the same helper gave every road end a round cap of its half. Roads are BUILT square at their first / last sample; the cap took the kerbs of the road a fork splits from (Bahan, Kan Yeiktha). **Rule:** every geometric test must use the shape the builder lays (square ends), in the builder and in its Python twin (kerbsim) alike.
- **Rule:** a "smaller road crosses my band" test that clips the smaller road at my centre line needs a margin: a T ending 0.1 past my centre took my FAR kerb in a circle of its half.
- **Rule:** an island outline side with no band kerb next to it (a split's gore along a road END line) gets its own kerb, and the fill moves in off it. Islands are computed AFTER the last plan change (taper, unfold, deck joints, mouth_level, kiss_clear), never before.
- **Rule:** a mouth_level-style height fix must skip continuation joints (moving one side of a joint made seam_step / pave_step 3) and must keep a record's far end at its height (shorten the fade to the record).
- **Mistake (18 Nov, MEGA BITE Livyatan T6):** the glowing runes on the armour were flat decals hugging the skin; the owner: "these details should be modelled instead of just slapping on a texture". Cause: the 3D skill allowed decals for markings. **Rule:** runes, glyphs and glow markings on 3D models are modelled raised solid inlays (closed, outward, gated like any part); only truly flat paint may be a decal. Written into **roblox-3d-model-from-sheet**.

### 2026-11-18 City Legends roads05 J24 (geometry: tracing a "regression" to its real cause)
- **Mistake:** the J23 note called deck_run pave_step 0 -> 23 a builder regression. Reverting each J23 builder change in Studio (square ends, the T clip, cut samples) left it at 23 every time: the step was always there, and J23's QA change (side faces = edge) made it countable. **Rule:** before hunting a "regression", revert the suspects one at a time in a test copy (patch the module source in Studio, `require` a clone) and re-measure; a count that does not move points at the QA.
- **Rule:** find which code made a bad part by wrapping `Roads.triangle` in the test copy and logging `debug.traceback` for triangles whose centre falls in the fault box. Here it was the corner "chip" (`buildCorners`), not the road's own pavement band I had patched first.
- **Mistake:** snapping pavement vertices to a neighbour's height by raycast (any reach) moved the step instead of removing it (23 -> 24 / 26 / 32): a fix that touches only some vertices of a piece set makes new steps against the pieces it did not touch. **Rule:** a corner on a sloping street needs ONE height rule for every pavement piece there (straight bands, arc pavement, chip, taper), not a patch on one of them.
- **Mistake (18 Nov, MEGA BITE Livyatan T6):** the eye area was a soft dark smudge with a white blown-out lens; the owner: "eye area is inaccurate". Cause: socket and brow made by smoothly pushing vertices in an ellipse, eye glow 7 with bright lights, and no close-up check of the eye against the card. **Rule:** cut the socket/brow lines into the mesh before pushing, keep glow saturated, and always compare an eye close-up with the reference crops. In **roblox-3d-model-from-sheet**.

### 2026-11-18 City Legends roads05 J25 (geometry: matching an owner picture to the data)
- **Mistake:** I looked for the owner's "dead end" in the data's dead-end list and the main place's old bake first; it was the Studio TEST box (sule_shangrila, half 220) cutting Sule Pagoda Road where its full-width flyover ramp starts 13 studs inside the box edge. **Rule:** when an owner picture shows our yellow zebras and red-white kerbs on a crop, compare it with our own latest test shots (the vault `... test - <spot> - overview.jpg`) BEFORE searching the network; a road "ending in grass" at a test box edge is the box, and the fix is a spot that covers the continuation, not a data change.
- **Rule:** a dead-end QA must test the end's whole cross-section (left kerb .. right kerb) against other carriageways, decks and rings, and treat ends outside / within 12 studs of the districts' outline as the map edge: the centre-point test flagged 9 "dual dead ends" that were splits, merges and map edges (true count 0).
- **Rule:** lane lines follow the lane count, not the road's class: a street with 2+ lanes a direction gets lane dividers and its centre line (paint QA `lanes_unmarked` = 0); only yellow kerb lines, boxes, zebras and stops stay main-road only.

### 2026-11-18 City Legends roads05 J26 (geometry: heights where pieces from different roads meet)
- **Rule:** where pieces of two roads meet, every shared vertex must get its height from ONE function of (x, z) (here: each road's kept edge height at the point's foot, blended by the corner's arc share), never from the piece's own end heights. Then neighbours agree whatever order they are built in. J24's per-piece snaps failed because only some pieces used them.
- **Mistake:** ending a crossing arm at the last uncut sample before a deck made the mouth fail ("an edge never meets"), because that cross-section still lay on the other road. **Rule:** stop the arm at the first cut sample (the deck foot), and always re-run the spot and read the log for MOUTH FAILED before counting faults.
- **Rule:** a road that "owns" the strip past its corner may take another road's kerb only where its own carriageway or kerb is. Elsewhere the other kerb stays and the owner's pavement stops at it (no overlap).
- **Rule (speed):** to try builder changes in Studio, apply small text patches to the stored module Source and re-require it, instead of re-packing and re-uploading (about 5 s, not 2 min).

### 2026-11-18 City Legends roads05 J27 (geometry: "is this point on that road?")
- **Rule:** a road's "is it on me" test must use its width AT that sample and on that side, not its nominal half: junction flares make a side 2-3x the half (Hledan 44 vs 21, Bahan 78 vs 22.5), and a mouth's edge there was never pinned (0.5-1.1 steps).
- **Mistake:** widening the reach without widening the nearest-sample search: the search found nothing within 2 cells, the default "sample 1" won, and a lane took a height 1 stud off. **Rule:** any reach change must change every search that depends on it; a default index must never stand in for "not found".
- **Rule:** when several bigger roads qualify, take the one the point lies deepest in (distance past its edge), not the nearest centre line.
- **Rule (measuring):** the same build gives 1-3 different counts per spot from run to run; judge a change by its traced clusters, not by +1s.

### 2026-11-18 City Legends roads05 J28 (geometry: one surface per spot, repeatable counts)
- **Mistake:** a road's cross-section was one straight line from edge to edge even where its middle lay on a different road than its edges (Insein Road's start over three roads): a 0.2-0.4 step along the whole join. **Rule:** where a cross-section lies on bigger roads, its inner points take those roads' heights too, not only its two edges.
- **Mistake:** pinning those inner points EXACTLY to the bigger road's height put two faces in one plane (flicker) and changed what smaller roads pinned to. **Rule:** a hidden piece sits a fixed hair (0.06) under the face that owns the spot, and the height other roads read is the face that shows, not the hidden one.
- **Mistake:** smoothing a flyover deck's plan line but leaving its road's cut stretch on the old line: everything built from the road's edge by the ramp foot (a crossing mouth) stood 1-1.5 studs off the ramp wall (slit, no kerb). **Rule:** when one object is moved, every object that shares its line moves with it in the same pass.
- **Rule (measuring, owner "0 everywhere"):** a check that picks "the first hit" among faces in one plane gives a different count each run. Make the check deterministic (all faces within 0.01 of the top, a fixed priority), then a count that changes means the build changed.

### 2026-11-18 City Legends roads05 J29 (builder: deck feet, island kerbs)
- **Mistake:** 45 "deck foot" kerb gaps at one test spot were the test's own fault: the spot built a flyover only when the deck's MIDDLE lay in the box, so the ground roads at its foot met nothing. **Rule:** before fixing a cluster of faults, check that the thing next to it is really built in the test; a test cell builds every piece that touches it.
- **Mistake:** side lanes at a flyover's foot were placed with their edge exactly on the deck's edge, forgetting their own deck-side walk and kerb: kerbs buried under the deck slab. **Rule:** when two pieces butt, count every band each one brings (carriageway, kerb, walk) at the ends as well as in the middle.
- **Mistake:** one ray at the middle of a 4-stud island side decided "this side has a kerb", so a kerb that covered only the middle left the nose bare. **Rule:** test an edge along its whole length at the check's own spacing (0.5) and fill only the open runs.
- **Tried + dropped:** leaving out a smaller road's strips "under a bigger road" using a reach test on the data made holes where the bigger road ENDS (the data reach runs past its end line). **Rule:** "is it covered?" must ask the built faces (or respect end lines), not a distance to a centre line.

### 2026-11-18 City Legends roads05 J30 (builder: pavement slots, state leak)
- **Mistake:** a zone that tells one road "stop your pavement here" was drawn from the OTHER road's centre line plus a nominal width (and the wider side's walk), or 0.3 inside a corner's pavement "to be safe". The other road's real pavement edge is its built quads, so a 0.3-0.5 stud slot ran between the two pavements (pave_gap). **Rule:** where two pieces must butt, both must use the SAME edge: the built edge (the same edge points and offsets the builder lays, the same chords for an arc), never a distance with a safety margin.
- **Mistake:** a "fresh state per build" check only looked at the tool's own tables; the leak (a test spot's build depended on the spot built before it) was in the road module the tool requires. **Rule:** to find a state leak, bisect by reloading one module at a time before the build (fresh tool + data, then fresh road module only) and compare part hashes; reset at the level the experiment proves.
- **Trap (Studio):** a ModuleScript's Source over 200,000 characters cannot be set from a script ("max length 200000"). YangonRoads was at 199,8xx: old diagnostic code (qaBuilt, replaced by the runner's T.qa) was removed to make room. Check the length before every patch.

### 2026-11-18 City Legends roads05 J31 (builder: kerb rules at merges and corners)
- **Mistake:** two kerb rules were written from the fault table alone ("kerb_gap at junction corners") and run on all spots: one (my kerb stays in a bigger road's kerb band where that road's kerb is not built) moved pyay_univ 1 box_hole + 1 kerb_gap to 0 but added 1 kerb_gap + 1 pave_step at univ_kabaraye's three-pavement island; the other (the same for a corner owner) changed nothing at the spots it was aimed at. **Rule:** before writing a builder rule for a fault group, look at one close-up of it first (a 1-minute top-down capture of the built spot): the double_junction "corner" faults turned out to be pavement wedges past a gore NOSE where two links merge, not a missing corner kerb, so neither rule could reach them.
- **Trap (test kit):** `_G.BF = T.faults` keeps a REFERENCE, not a copy: the next run overwrote the baseline fault lists. Copy the lists (or dump them to disk) before re-running.
- **Trap (patching Studio from the repo):** the repo file is CRLF, Studio's Source is LF; checksums and find/replace hunks must strip CR first, and a Python-written Luau patch must be written with newline="\n".

### 2026-11-18 City Legends roads05 J32 (builder: gore pavements are corner tapers and chips)
- **Mistake (J31's hypothesis, kept for one more pass):** the double_junction gore faults were blamed on the straight pavement "running past the kerb nose". A ray map of the built spot (one character per 0.5 stud: road / kerb / pavement, upper case for the other road) plus the triangle corners of the piece under a fault cell showed the pavement was NOT the straight strip at all: the straight strip's zone there was already "drop". The pieces were the round corner's extras: the J20 taper (a short arc keeps the wider 7.5 walk and tapers the straight back to 4 over 20 studs, laid with no zone) and the J17 chip (the tip pavement of a corner whose radius is under the walk). In a narrow gore both reach over the next road's carriageway. **Rule:** before fixing a fault cell, find which builder laid the part under it (test the straight strip's own zone at that spot: if the zone says "drop" and a piece is there, it came from another builder). Every piece a builder lays outside `Roads.build`'s zone (tapers, chips, fills) must be cut by the same "other road's carriageway + kerb" test.
- **Rule (corner geometry):** a sharp corner (theta under 60 degrees) is a gore nose, not a street corner: the back edges of the two pavements overlap inside the wedge, so there is no L-notch to fill, and the chip only spills. slip_triangle kerb_gap 25 -> 15 from that alone.
- **Trap (test kit):** `Roads.debugEdges` only holds the last roads built (the decks), so it cannot be read after a cell; probe zones with `Y.sideZone(name, pos, what)` right after the cell's build, before the next one starts.

### 2026-11-18 City Legends roads05 J33 (data must use the builder's own geometry)
- **Mistake (data vs builder):** `roads05_fix.islands` made each traffic-island hole from `roads05_qa.quads()`, which drops a quad that folds into a bow-tie on a sharp bend. `Roads.build` never lays that bow-tie: on a bend tighter than the half width the inner edge point WAITS at its last point. So the island hole ran under real asphalt (bahan_ring, Kan Yeiktha Road s1-s2): the builder scrubbed the island triangles on the road and left a 2-4 stud spike and an unkerbed side. **Rule:** any data step that predicts what the builder covers must copy the builder's own edge rules (here the edge wait), not a simplified quad. `built_quads()` in roads05_fix does that now.
- **Rule (outlines):** two islands either side of a road end can touch at one corner; the union's hole then comes out as ONE outline pinched to a 0-width neck. Open each hole by 0.5 (mitre) and keep each side as its own island.
- **Mistake (mouth host):** a mouth's bigger-road edge (B) stopped at the bigger road's END, even where another road carries on from that end (a Y: Lower Pazundaung starts on Upper Pazundaung's end). The mouth's far edge then snapped across and left a 4-8 stud gore with nothing built. **Rule:** B goes on along the continuation's edge on the same side (`contsOf` in YangonRoads.buildMouth; the continuation's edges must be kept for it).
- **Trap (distance in samples):** `butt_match` skipped a joint when "a median within s[:8]": 8 samples is 65 studs, the median started 57 studs on, past the 40-stud morph. Write such windows in studs.

### 2026-11-18 City Legends roads05 J34 (a corner's zone must stop at its own road's centre line)
- **Mistake (ring corners):** `YangonRoads.inCorner` skipped the corner-polygon test for ring corners and kept only the wedge (0 .. rout from O, between O->TA and O->TB). On a narrow arm (Lane #3357, 10.5 wide, r 5.7, rout 21.7) the north corner's wedge reached across the lane to the SOUTH kerb, so that 13-stud straight kerb and its pavement were dropped with nothing in their place. Found by probing `Y.sideZone` / `Y.inCorner` along the missing kerb, then removing one corner at a time from `Y.cornerGrid` until `inCorner` said false. **Rule:** every zone a corner claims must stay on its own side of its road's centre line (`armNear`: the point's distance from O along O->TA is at most |O TA| + the arm's half). roundabout4 kerb_gap 38 -> 25, pave_gap 21 -> 14 (Lane #3357 and Lane #115), nothing else moved.
- **Mistake (one QA pass is not enough):** `osm_joins` ran once, early; later steps (chain, mouths) left two OSM joins short again. A second pass after `fork_trim` did not catch them (it only cut back two overshooting ends elsewhere, Lane #35 and Tha Yat Taw 4 Street): Lane #544's real cause is the chain joining Dhobi Street 3 #2 through a ~140 degree U-turn node (the J8 trap again), so its link to Lane #544 never exists. **Rule:** when a QA row survives a fix step that "should" catch it, run that step's test on the FINAL data first: if it fires there, something later moved the geometry; find what, don't add another pass.
- **Rule (mouth run-on):** test the end's CENTRE too, not only its two edge points: on a concave bend of the bigger road both edges can lie on it while the centre is 1-2 studs off (Lane #5161 on Lane #5162).
- **Rule (map edge):** a road end 1-3 studs off the districts' outline is a map-edge end (Insein Road 1.36): flag it, or QA counts it as a short mouth.

### 2026-11-18 City Legends roads05 J35 (find the exact drop step before fixing; a road that ends under another deck)
- **Mistake (guessed drop step):** J34 wrote that the Pazundaung Y corner was "not noCorner". Logging every `continue` in `findCorners` (a Studio copy with a logger before each `continue`, filtered to that one road) showed it WAS noCorner: the big road's kerb window stopped at its sample 1 and the kerb ran on along its continuation. **Rule:** when a piece goes missing, instrument every exit of the function for that one road before believing a count-based guess.
- **Mistake (fix that lowers one count but raises another):** building that corner from the continuation's kerb added 26 kerb gaps (some 200 studs away). Kept the rule "keep only fixes that lower the totals" and reverted. **Rule:** measure the whole spot, not just the target cell.
- **Rule (bridge end under another deck):** an OSM bridge that starts at ground UNDER another flyover is not a ground road there: cut it back to that deck's footprint edge and let the real ground road (OSM, layer 0) own the carriageway. When cutting samples off a road's start, shift EVERY index list of that road (cut, its own deck from/to), not just one.
- **Rule (chain U-turns):** do not chain two ends through a turn sharper than ~100 deg when another road's end sits within ~15 studs of that node: that node is a real junction, and chaining hides OSM's short link (Lane #544).
- **Rule (Studio 200k Source limit):** split a self-contained section (the checks) into a helper ModuleScript that receives `M` plus the file locals it uses; prove it with a byte-identical build (parts hash) on 3 spots before any other change.

### 2026-11-18 City Legends roads05 J36 (a kerb must stand over every asphalt next to it; fix-ups must not climb)
- **Rule (kerb over every asphalt):** after all surfaces are built, probe round every kerb piece: any asphalt (its own road's, or a ramp foot's) within ~0.33 under the kerb top makes the kerb look flush, so raise that kerb piece to stand clear. Probe from the asphalt patches too: at a nose, tiny kerb slivers hide the patch from the kerb's own probes.
- **Mistake (patch that climbs):** a repair patch took the MIDDLE height of the surfaces round it, and those included patches laid a moment before, so one patch went 1.7 studs UP (a spike). **Rule:** a repair piece that replaces something may only move down, never up.
- **Rule (check the checker on a curve):** a paint check that projects dashes on the stop line's normal splits one lane line into two on a curving approach. Before changing the paint, prove whether the check or the paint is wrong, and revert a check change that raises other counts.

### 2026-11-18 City Legends roads05 J37 (one closing pass beats many per-builder fixes for edge faults)
- **Rule (seal the last edge, by the built faces):** kerb gaps came from five different builders (corners, island noses, mouths, island outlines, side zones). One pass after everything is built (`YangonRoads.kerbSeal`) read the real top triangle of every pavement / kerb part, walked each edge and probed just outside it: lower asphalt there gets a kerb, an open slot (nothing, then asphalt within 2) gets filled. kerb_gap 161 -> about half in one change. Fix the class where it is visible, not each builder that can make it.
- **Rule (a new kerb has two floors):** 0.1 over its pavement is not enough where the pavement sits low: the kerb must also be at least CURB_UP + 0.1 over the asphalt it stands on, or the check calls it buried (pyay_univ / univ_kabaraye +1 each until the floor went in).
- **Rule (re-probe before each new piece):** collect the runs first, then probe again right before laying each one and stop its width at whatever starts first, so new pieces never lie on each other (coplanar tops flicker).

### 2026-11-18 City Legends road rebuild P1 + P2 (J37 roads05 into the game, one district at a time)
- **Rule (getting big data out of Studio):** an MCP result is cut at 100,000 characters, one page per call. Squeeze it first: `EncodingService:CompressBuffer(buffer, Enum.CompressionAlgorithm.Zstd, 19)` + `Base64Encode` halved the call count (P1: 9 cells, ~260 pages -> ~130 calls); Python reads it with `zstandard` (`tools/yangon/city/roads05_grab.py`). Pad the last slice with dense text (a copy of the data after the end mark): a short or `#`-padded result comes back inline / as a preview and eats context.
- **Mistake (old files in the session folder):** the tool-results folder of a reused session already held 280 OLD page files from a 16 Nov rebuild with the same names. **Rule:** only read result files written after this run's first page (mtime filter), never "every page in the folder".
- **Rule (swap whole cells, never half of one):** district edges do not fall on the 1536-stud mesh cells. Rebuild every 3072 build cell that covers the district's mesh cells, build from a data subset that includes the neighbouring district, and replace the old cells whole (`R05_ONLY` = the cells being swapped). The cells' neighbour strip is rebuilt with them.
- **Rule (lanes only where the game has roads):** a roads subset keeps whole roads within 600 studs of its districts; lanes on that data run onto grass past the district edge. Cut each road to its run inside the districts first (`roads05_lanesubset.py`), then `roads05_lanes.py --install`.
- **Rule (what stood on the old road):** a road that moved leaves trees standing on the new carriageway (147 far-tree / bank-tree parts in P1). After a swap, ray down from every green part to the new `RoadBox` "R" boxes and take the ones on asphalt out. The client kit data (street props, kit trees) was made from the old road layout too: rebuild it from the new roads.
- **Trap:** `CollisionFidelity = Box` on the placed road MeshParts did not stick from a script, in ServerStorage or in Workspace (892 road meshes, old ones too, stay Default). They are CanCollide / CanQuery off, so it costs memory only.
- **Trap:** Studio's `ClaudeTools.YangonRoadMeshes.LOOK` lacked `LZ` (ochre zebras, J14): the zebra meshes would have been skipped. Check the placer's LOOK against the bake's kinds before placing.
- **Trap:** Open Cloud calls go through Studio: while a long build runs, `open_cloud_invoke` answers "Target is not reachable". Do the uploads between builds.
- **Trap (18 Nov, P3):** Studio's `HttpService` refuses 127.0.0.1 and localhost from `execute_luau` ("not in the Assistant HTTP allowlist"), so a local POST server can't take the pages: MCP results (99k each) stay the only way out. Budget the context: a dense downtown cell is 15-21 calls; P3 was ~200 calls.
- **Rule (props after a road move):** decode the client kit data in Studio and ray-test each record against the new collision boxes (RoadBox "R"); drop hits. Count first, apply after. Compound-wall records carry invisible WCOL collision: 563 of them stood on the new P1 / P2 carriageways (an invisible wall in the road for players).
- **Rule (a drive meeting a raised plate):** build the ramp on the drive's side from triangles (pairs of wedges), low end 0.06 over the road, high end on the plate edge where each drive edge crosses it. A single wedge can't meet an edge the drive hits at an angle.
- **Finding (lane gaps):** NPC cars are moved kinematically along lane heights, so a lane point with no collision box under it can't make an NPC drop; only player cars can feel it.

### 2026-11-18 City Legends road rebuild P3 (downtown swapped; agent 3)
- **Rule (page export, cheaper):** keep each MCP result one slice of 99k (two slices in one result were cut at 100k and lost the second). Hand a long run of slice calls to a helper subagent: its results land in the same session tool-results folder, and only its short report comes back. 64 slices cost the main context one report instead of 64 notices.
- **Trap (a short last slice):** a result under the size limit comes back inline instead of to a file: pad the last slice with `#` to about 98k so it lands in a file too.
- **Trap (driving tests):** the player's car is simulated by the client's own physics; a server or client `PivotTo` is overwritten the next frame. Move it with the Studio hook `TestTeleport` (a CFrame: set nil first, then the CFrame), let it stream in from a spot high over the target, then ray down for the road and teleport again. The engine needs `TestEngine` true (or F) before `TestThrottle` moves anything.
- **Trap (a crash at Play start):** under memory load the server's `Chauffeur.init` hit "Script timeout" in `ChauffeurRoute.graph` (`Config.laneWidth`) and the server Main stopped: no car spawned. Read the Output after every Play start; stop and start again (the second start was clean).
- **Rule (a ramp from thin triangles):** triangles 1 stud thick beside a raised plate show their underside as a dark band hanging beside the plate wall. Give each triangle a body down to the ground (here 5 studs, grown downward, top face unchanged), so the ramp side reads as a solid wall.
- **Trap (Edit shots):** a camera inside a building's shell shows its window-frame kit floating in the sky (shells are one-sided from inside). Move the camera out before judging a shot. The Edit preview plugin's folder is destroyed when it is unparented: never take it out of the camera to clean a shot.
- **Rule (repo copies of client data):** after any in-place edit of `YgnKit.Data_*`, hash every tile in Studio and in the repo rbxmx (`h = (h*31 + byte) % 2147483647`) and write the changed tiles back. The repo copies of Data_P1, Data_P2 and Data_P2G were already stale before the prop filter (nearly every tile differed), so the whole folders were written back from the place.
- **Rule (checking a verge pass):** test the result, not the counts. Ray down 0.5 inside every pavement box edge and use that edge's own top: the box centre's top gives false hits on sloped boxes (695 hits fell to 199). Most of what was left was the builder's road-bed terrain (asphalt / rock) coming up through junction meshes, not grass: carve it over the R and P boxes, not over the verge.

### 2026-11-19 City Legends traffic: owner's own cars as light traffic copies + rare racers
- **Rule (traffic from the game's own cars):** when the owner says "use the cars I made", make a light copy of each car once in Studio: exterior parts only, no cabin, seats, plates or scripts, glass opaque and dark, plain colours by role. Never use the full player model in traffic. 22-61 parts a car instead of 5 doubled the traffic part count (362 -> 675-743 for 28 cars), while mesh memory stayed the same (meshes are shared with the player cars).
- **Trap (pivots):** a template whose `WorldPivot` carries a half turn drives backwards once code does `PivotTo(CFrame.new())`. Give every template a plain pivot at its box middle.
- **Trap (kit cars):** the look of a Roblox-built car is often a `SpecialMesh` child of a plain Part. Clearing a part's children leaves red boxes. RenderFidelity `Performance` crumples their shells even close up: use `Automatic`.
- **Trap (badges):** Roblox-built cars carry badges as flat textured parts (drop them by shape: thin, small, textured) and also baked into big chrome meshes (they need `MarkPatch` covers). Converted cars rely on CarSkin's runtime BrandMarks covers, which a traffic copy made outside CarSkin doesn't get. Check every traffic copy close up, front and rear.
- **Rule (fast NPCs):** an NPC going 3-4x traffic speed needs its braking planned over several lane pieces ahead (bends from the curve radius, lights, turns), a lookahead in seconds rather than studs, and a lane-change gate on room to brake in the target lane, not just "clear beside me". The first version rear-ended slow cars right after cutting in.
- **Trap (short lane pieces):** "near the end of my piece" is always true on lanes cut into short pieces. Test the distance to the next real junction (a turn piece or a light) instead.
