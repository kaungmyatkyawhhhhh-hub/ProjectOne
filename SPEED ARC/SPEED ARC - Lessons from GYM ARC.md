---
date: 2026-10-28
tags: [speedarc, lessons]
status: living document
---
# SPEED ARC - Lessons from GYM ARC

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Everything GYM ARC learned the hard way (from its vault notes, 4-28 Oct). Build SPEED ARC so these never happen. Claude Code: read this before every big prompt and add new lessons at the bottom.

## 1. Saving and backups
- **GYM ARC lost a whole day of work** (8 Oct): the cloud place fell back to an old version and the local autosave was useless. Rule: after every task **File > Save to Roblox**, and once a day **File > Save to File** (a dated .rbxl backup).
- Keep the code in a repo / exported folder too, not only in Studio.
- Every big change to the world: back up the old version in ServerStorage first (`<Name>Backup_<date>`), and make it one Ctrl+Z step.
- Test on a test save (FreshPlayer-style switch). A test once started on the owner's real save because the "test data" switch was set too late: Studio tests must never start before the test switch is on.

## 2. Performance (GYM ARC ran at ~31 FPS on phones)
- **Most lag was DRAWING the world, not scripts.** Measure first: scripts ~2-3 ms, the rest was the map. Look at the sky = 59 FPS, look at the beach = 30.
- Biggest costs found, in order: NPCs on screen, see-through parts, particles, SurfaceGuis, lights, shadows.
- **Glass material is expensive**: GYM ARC had 1,000+ Glass parts and swapped them all to SmoothPlastic with the same colour/transparency. Don't use Glass at all.
- **Lights:** only the area you're in has its lights on (GYM ARC LightAreaClient). Decorative lights never cast shadows. Shadows from gym lights alone were 600-750 draw calls.
- **NPCs:** only draw NPCs of the area you're in + anyone within ~35 studs; hide everything past ~110 studs.
- **SurfaceGuis:** always set MaxDistance.
- **Never loop over everything every frame** (GYM ARC walked 132 machines every frame and 36,000 parts every 2 s = 11 ms hitches). Keep a short list of "active" things and only update those.
- **Never rebuild a character/mesh often:** body mesh rewrites on every level-up made frames take 65-90 ms. Change visuals only when they really change, with a minimum gap.
- **Windows (UI):** fading every descendant of a big window cost 34 ms per open. Fade only what's visible; update only the cards that changed.
- **Preload during the loading screen:** meshes, textures, sound effects, and build every window once behind the loading screen, so the first open doesn't freeze. Keep loading after a SKIP.
- **Streaming:** small radius; separate areas.
- **Server memory leaks:** players who left were re-added to tables by slow callbacks; caches grew forever; event connections were never disconnected. Always check "player still here?" after any wait, cap caches, Destroy characters after leaving, disconnect what you connect. Run a 30-60 min soak test.
- Studio FPS numbers on a PC swing a lot: compare A/B from a fixed camera, and test on a real phone (F9 Developer Console).

## 3. The first 15 minutes (most important for Roblox)
- GYM ARC funnel: of 6,829 new players only 26% reached the first big goal. Big drops: walking too far to the first station, "stamina ran low", unclear next step after the tutorial.
- What fixed it: start the player right next to the first station; a gold floor path + a GO TO button that **teleports**; a reward on the very first tap; the main goal visible from second one; a "GO TRAIN" button after the tutorial; a new-player boost (2x for 15 min); starting coins after the tutorial; milestone rewards at 25/50/75% of the first goal.
- Tutorial bugs that broke it midway: a step teleported you onto a desk where the prompt never showed; steps timed out while the player was busy; hints vanished after 4 s; popups (level up, new record) piled on top of the hints; an unlock guide covered the button the last hint told you to press. Test the tutorial as a new player after EVERY change.
- No genetics/reroll popup or shop push before the player has done anything.
- Target: first rebirth-like goal in ~5 min, all in-session fun within 15 min, then slower later.

## 4. Retention
- Daily streak: the UTC day changes in the afternoon in the US, so kids lost streaks without missing a real day: allow one missed day (grace).
- Unclaimed daily quests must be paid before the reset, not lost.
- A popup that can't show (player busy) must WAIT, not be skipped forever.
- Playtime gifts (3/8/15/25/40/60 min), friend boost, invite reward, favourite prompt after the first big goal, daily notifications (needs an Open Cloud key in Creator Hub > Secrets).
- Players who FINISH leave: plan the endless loop (rebirth/Hall of Fame, weekly boards, events, codes) before launch, not after.
- Leaderboards: old entries stayed forever; use a versioned store prefix so boards can be reset, and refill from active players.

## 5. Monetization
- **Fallback prices in the game must match Roblox's real prices** (GYM ARC showed 15 R$ while Roblox asked 49: looks like a trick to a kid).
- Products buried 2-3 tabs deep sold nothing: offer the right thing at the right moment (small card, never during a race/set, never in the tutorial, max once per X minutes).
- ProcessReceipt: grant + save BEFORE PurchaseGranted, never grant twice, one handler on the server.
- Best sellers in GYM ARC: Auto Rep (auto-play pass) and the reroll token. Make the "auto" pass the hero.
- No paid random rewards (rolls only with in-game coins). Starter Pack popups every 5 min may annoy kids: keep offers calm.
- Coin rewards and coin packs should scale with the player's stage ("minutes of coins"), or late players ignore them; cap total coin multipliers (GYM ARC reached ~20x).

## 6. Assets, uploads and moderation
- **GYM ARC got a warning and a 1-day ban** for images: a muscle-body render and an old icon. Never upload realistic body/skin images. Keep icons cartoony and safe. Upload one at a time, stop at the first problem, and the owner approves every upload.
- **Upload assets to the GROUP that owns the game**, not a personal account: GYM ARC's alter textures were on the owner's account and never showed in the live game.
- Check pass/product icons on the Creator Hub too (the game's own icons don't change them).
- Some uploaded images fail to load (a normal map never loaded): check every asset actually loads in a real server.
- Scripts can't upload meshes: models come as .fbx/.glb from Blender for the owner to import; plan for that step. The 3D importer can flip X/Z: check orientation after import.

## 7. UI rules that worked
- One UI kit, two fonts, one colour table, a minimum text size; every window the same style.
- A fixed layout plan: top bar = coins/level/daily/settings; top centre = one toast lane (one toast at a time); bottom centre = main action/dialog; right = action controls; left = menu. Nothing in the middle of the screen.
- Never let a UI element overlap another on phones (STOP was hidden under boost icons; BEST EQUIP over the X). Check 667x375 and desktop.
- Images inside rounded frames need their own UICorner/CanvasGroup (square corners poked out).
- Scale icons once: an icon got the window's UIScale twice and was huge on big screens but fine in Studio. Test on a real big screen too.
- Text must never be cut off ("TAP TO...") or flicker between sizes (a TextScaled fight); use fixed sizes set once.
- Every button: press animation + click sound; every reward: coins fly to the counter and count up; level-up popups not on every rep (GYM ARC: once per 10 levels / 60 s).
- Locked things: visible but locked with a teaser line, never hidden; the main SHOP is never locked.

## 8. World building
- Check for holes, floating props (lamps, speakers), z-fighting overlapping faces, blank walls and invisible boundary walls with nothing in front (add fences/barriers so edges look intended).
- Don't merge unrelated props into one mesh (moving a light pole moved a container, benches and a tower too).
- Big buildings need a real street front; a black box behind other buildings reads as broken.
- Streaming can re-send parts: never MOVE built UI rows/parts at runtime (it duplicated leaderboard rows); copy or build on the client instead.

## 9. Working with Claude Code
- One prompt = one clear goal + a TEST list + a progress note. Ask for screenshots next to the reference.
- Prompt numbers clash when two places create them: check the vault before numbering.
- The owner's manual Studio changes are never undone.
- Keep one living design plan and update it when decisions change, so old prompts don't contradict new rules.

## 10. The owner's own process mistakes (owner, 28 Oct: "never make the same mistakes I made with GYM ARC")
- **Deciding the look too late.** GYM ARC's UI was redesigned many times (clean minimal -> chunky -> black + gold -> premium), and the whole game had to be redone each time. SPEED ARC: lock the art style, palette, fonts and UI kit in M1 with mockups, then build everything with them.
- **Adding then removing features.** Sneakers, 4 gear pieces x 4 levels, the Garage Gym, apparel, alter colour variants, the starter gym layout... were built and then cut. SPEED ARC: decide in the GDD first, keep systems SMALL (few items that each matter), add more only when players ask for it.
- **Too many systems at once.** Shops, gear, auras, alters, trainers, titles, styles, skins, boosts all competed. SPEED ARC: one main loop (train -> race -> shoes/coaches -> Go Pro) and a few clear collections.
- **No endgame at launch.** Players finished GYM ARC in a few hours and left; the Hall of Fame came later. SPEED ARC: Legend Laps planned from the start and shipped within the first updates.
- **The first 15 minutes came last.** GYM ARC fixed onboarding after launch when only 26% reached the first goal. SPEED ARC: the first 15 minutes (GDD 21) are part of M4 and tested with fresh players before launch.
- **Performance came last.** GYM ARC ran at ~31 FPS on phones before the lag passes. SPEED ARC: budgets from day one, checked after every prompt.
- **Pushy offers.** A Starter Pack popup every 5 minutes. SPEED ARC: calm offers only (GDD 20.3).
- **Moderation risk.** Realistic body images got the account warned and banned for a day. SPEED ARC: only cartoon, safe images; the owner approves each upload.
- **Only one copy of the game.** "Studio is the only copy" + a lost day of work. SPEED ARC: daily backup files and saved code.
- **Prompt chaos.** Duplicate prompt numbers, old prompts contradicting new decisions. SPEED ARC: one numbered prompt list, check the vault before numbering, keep the GDD updated.
- **Sound as an afterthought.** Screams/grunts/music were changed several times. SPEED ARC: sound designed with each feature (see the sound rule).

## New lessons (add below)
- **28 Oct (prompt 1):** the SPEED ARC place has no default PlayerModule. Never `WaitForChild("PlayerModule")` (it froze training); and hiding touch controls (`GuiService.TouchControlsEnabled`) also froze the camera on phones. Anchor the character on the server instead.
- **28 Oct:** a client that draws itself (race camera, runner positions) keeps its own position after the server moves it: always tell the client where it really is when a race ends.
- **28 Oct:** Studio FPS on this PC is limited by Studio itself (same FPS looking at the sky); judge performance by draw calls / triangles / CPU ms and a real phone (F9).
