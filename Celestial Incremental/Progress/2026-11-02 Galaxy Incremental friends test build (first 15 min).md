---
date: 2026-11-02
tags: [galaxy, progress, friends-test, economy, ui, tutorial]
status: built + tested in Studio, group images + saving checked; needs one more publish, then friends can test
---
# Galaxy Incremental - friends test build: the first 15 minutes (2 Nov, Claude Code)

For the **Sun 8 Nov friends-only test** ([[2026-11-02 Galaxy Incremental - Launch plan (test, alpha, full launch)]]).
- Place: "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.
- Numbers: [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]] (+ its new "Ring 1 prices: PROPOSED (calc)" section) and [[2026-11-02 Galaxy Incremental - Design additions (Regrowth + Immortality lessons)]].
- UI: the approved v12 (`UI\galaxy_ui_v12_animated.html`).

## Owner decisions (2 Nov)
- **Everything is in the Upgrades window for the friends test** (v12 tabs):
  - PLANETS = the bodies. Locked ones show an UNLOCK button = Lunar Pull / Planet Seed / Gas Giant.
  - STARDUST = First Light + Orbit Speed.
  - COMETS = Comet Lure.
  - FORGE + BLACK HOLE are greyed and show what opens them.
- **Ring-1 nodes live in ONE Config table** (`Econ.Ring1`). For the 14 Nov alpha the Constellation Tree (T) is built from the tree mock-up and reads the same table, with no data changes. Tutorial steps point at the Upgrades tabs for now.
- **Node costs:**
  - Unlock nodes = 10*8^k (80 / 640 / 5,120); First Light free.
  - Orbit Speed 55,000 and Comet Lure 80,000 = PROPOSED (calc). They were halved from the payback rule so ring 1 rebuys in ~2 min after Supernova 1 (best-choice time; ~3 min real). See the design note.
- **Tutorial:** counter "1/4".."4/4", 1 Essence per step, then a short TUTORIAL COMPLETE moment (no "more coming" text).

## Built (in the place)
- **`ReplicatedStorage.Galaxy.EconConfig`**: every number, from the design.
  - Body cost 10*8^k*1.15^owned; income 5^k*owned with x2 milestones at 25/50/100/200/300/400.
  - You start with 1 asteroid.
  - Ring 1 table; comets (every 45 s, 30 s with Lure, worth 30-60 s of income); Supernova need 1M (for `SupernovaReady` only).
  - Tutorial steps; number format K/M/B/T/Qa...; `DataVersion = 1`.
  - Shared income functions, so the window shows exactly what the server pays.
- **`ServerScriptService.GalaxyEconService`**:
  - **Saving:** DataStore `GalaxySave1` with a data version, forward-safe loading (a newer save is never overwritten), a session lock, autosave every 60 s + on leave + on shutdown. Studio uses separate `studio_u_` keys.
  - **Economy:** income every 0.5 s; buying bodies / nodes is checked on the server (types, unlocks, cost, 25 requests/s).
  - **Comets:** the server decides when each comet appears and pays it once, only if caught in time. Tested: a made-up id or the same id twice pays nothing.
  - **Tutorial:** steps pay Essence and are logged to the onboarding funnel (`LogOnboardingFunnelStepEvent`).
  - **Map attributes:** sets what the map reads: Bodies, BodyTiers, Supernovas, Rank, SupernovaReady, BestRunStardust, Tree_CometLure, CometsCaught.
- **`ReplicatedStorage.Galaxy.UIKit` + `UIAssets`**: the v12 pieces as builders.
  - Buttons: ink outline, gradient + white top line, static stripes, hard drop shadow.
  - Icons: still, each with its own glow pulsing.
  - Animated VFX on top: shine sweeps, motes in BUY, sparkles, header light sweep + embers, breathing window glow, pulsing selected outline. Can't-afford buttons have no VFX.
  - Reduced Motion stops the moving VFX.
  - All image ids are in `UIAssets` (one place).
- **`StarterPlayerScripts.GalaxyHUD`**:
  - **Top:** the Stardust counter (diamond badge, slanted plate, smooth count-up, "+x/s").
  - **Bottom:** the v6 hotbar. U opens Upgrades; F/T/E/Q are dimmed with a lock and say why ("STAR FORGE: opens at SUPERNOVA 3", "... not in this test").
  - **The UPGRADES window** (v12 layout):
    - header texture, Essence chip, close;
    - category list;
    - rows with LV, gradient title, a one-line description, the "now > after" chip and BUY / can't-afford / OWNED / UNLOCK / locked buttons;
    - hold-to-buy for bodies.
  - **Feedback on every buy:** sparkles on the row, the counter pops, "+x/s" floats up. A comet pays "+value".
  - **Tutorial:** the target glows + an arrow at once; the hint line ("n/4  text  +1 Essence") after 5 s idle and then until the step is done; +1 ESSENCE floats up.
  - Steps:
    1. Buy an asteroid.
    2. Get FIRST LIGHT (free).
    3. Get your first Moon (Lunar Pull, then buy one).
    4. Tap the comet: it crosses your view slowly, slows down for 0.5 s and has a ring on it.
  - Then TUTORIAL COMPLETE.
  - **Phones:** the window fits between the counter and the hint line, and the hotbar hides while it's open.
- **Map wiring:**
  - Your island + star system grow as you buy: island tiers at 5/25/75 bodies, one planet per body tier, the planet of a new tier flies in.
  - NEW: an **asteroid belt**, one small rock per body owned (max 20), so every buy shows.
  - Comets now come from the server (the map no longer makes its own).
- **New art (P&L style, Blender):**
  - icons: asteroid, moon, gas giant, Essence, lock (`UI\galaxy_icons_extra.py`);
  - UI textures: stripes, 9-slice glow, soft icon glow, sparkle, mote, counter plate, tutorial arrow (`UI\make_ui_textures.py`).
- **Code copy:** `Celestial Incremental\Code\friends-test\`.

## Tested (Studio, one player)
- **Whole tutorial by real clicks:**
  - U, then the PLANETS asteroid BUY (step 1, +1 Essence);
  - the arrow moved to STARDUST, then FIRST LIGHT FREE (step 2);
  - PLANETS, then UNLOCK Moon 80, then buy the Moon (step 3); the window closed itself;
  - the tutorial comet crossed the view and a real click caught it (+46 s of income, step 4);
  - TUTORIAL COMPLETE, Essence 4.
- **Comets:** the first regular comet came 20 s after the tutorial. A made-up id or a repeated id pays nothing.
- **Island growth:** 9 bodies = island tier 1, rank NEW STAR, 9 belt rocks, 2 planets.
- **Locked bits:** the FORGE tab shows the locked panel; the F key shows its toast.
- **Phone 667x375:** a Studio-only switch (Workspace attribute `TestPhone`) lays the HUD out in a 667x375 frame. Screenshots `phone_667x375_hud.png` / `phone_667x375_upgrades.png`.
- No errors from the game (only a Studio plugin's 429s).
- Screenshots: `Progress\screens\2026-11-02-friends-test\` (10 + 2 phone).

## Not done / to check
- **SAVING NOT TESTED:** the place has "Studio access to API services" off, so Studio runs with saving OFF (the console says so). Test it before Sunday (step 2 below).
- **2 real players:** not run (Studio here only runs solo).
- **FPS:** not measured this time (Studio was capped at ~15 FPS by itself earlier today).
- **No sound:** the built-in Roblox sounds are only footsteps/falls; sounds are in the alpha scope ("core sounds/VFX").
- **On phones the row descriptions are very small** (~7 pt). Friends' feedback will tell.
- **Pace:** checked by maths only. The design's calc puts 1M earned (SupernovaReady) at ~10 min best-choice, sooner with First Light and comets. The Supernova itself is not in this build (alpha), so a fast friend can reach "ready" with no button to press.
- **Offline earnings, daily streak, quests, the Guide book:** not in this build (not in the friends-test scope).

## Owner steps before friends can play
1. **Upload the 20 UI images to P&L Studios XP** (`Downloads\galaxy_ui_upload\`: 12 `icon_*`, 8 `ui_*`). Drop the decals in Workspace (as with the sky) or send me the ids. I swap them into `UIAssets`.
   - The UI uses test copies under your user account right now. Those may not load for other players in a group game.
2. **Saving:**
   - Game Settings > Security > "Enable Studio Access to API Services" on.
   - Then Play, buy a few things, stop, Play again: you should keep them. Or test it in the private game after publishing.
3. **Publish + keep it private:**
   - File > Publish to Roblox (the group's place).
   - Leave the experience **Private** in Creator Hub. For friends who aren't in the group, give the testers a group role that can play the private experience (check Creator Hub > Permissions). Don't make it Public.
4. After 1-3: friends can test.

## Owner steps done (2 Nov, later)
- **Group images:** the owner uploaded the 20 images to P&L Studios XP.
  - The ids are in `UIAssets`; the decals were moved to `ServerStorage.UIUploads`.
  - All 20 load in Play.
  - Group ownership was confirmed for icon_stardust + ui_mote; the rest of the same batch couldn't be checked (Roblox's 429 limit).
- **Saving works:** Studio API access is on.
  - Test: bought an asteroid + First Light, stopped, played again.
  - Came back with 2 asteroids, First Light, tutorial step 2, Essence 2, and the Stardust earned before stopping. Loaded at once (the lock was released on shutdown).
  - Studio test saves use `studio_u_` keys, never the real ones.
- **Republish needed:** the image swap happened after the owner's publish, so File > Publish to Roblox once more. Then friends can test.
