---
date: 2026-11-09
tags: [galaxy, progress, onboarding, social, liveops]
status: in Studio, NOT published. Short Play runs only to check startup (no script errors).
---
# Galaxy Incremental: the first 30 seconds fix + the 4 dead-game features (9 Nov, Claude Code)

Prompts:
- [[2026-11-09 Galaxy Incremental - Impatient kid simulation + first 60 seconds fix]]
- [[2026-11-09 Galaxy Incremental - Prompt - Dead game method features (party, island stars, Great Star, LUMI pet)]]

# A. THE FIRST 30 SECONDS (the sim's version F)
**Re-run of `Calc/variants.py`:** live A = 80% stay 60 s / 77% stay 5 min → F = **100% / 95%**. The sim matches the note.

| change | value (config) |
|---|---|
| WELCOME GIFT | +30 stardust at 1.5 s, once per account (new saves only; old saves are marked done). A toast "LUMI: A gift to start your galaxy! +30", coin sound, counter pop + sparkles. `GameConfig.FirstSession.WelcomeGift / WelcomeAt` |
| Pads 1-3 | **5 / 25 / 80** (were 15 / 60 / 150). Pads you have stay. `EconConfig.Pads` |
| Early Asteroid levels | UPGRADE **x0.5** while the Asteroid's level is under 5, every run. `FirstSession.EarlyAsteroid` |
| Comets from 8 s | Run 1: the first comet ~8 s after joining, then **every 15 s** (`Econ.Comet.RunOneEvery` 15, was 20), **during tutorial steps 1-5 too** (the old \"no comets in steps 1-5\" wait is gone). Until 2 are caught they're the slow, ringed tutorial comets. The very first one also shows "LUMI: Tap the comet!" and a bobbing arrow. Step 6 "Tap 2 comets!" then just completes. `FirstSession.FirstComet` |
| The 2nd Asteroid | The Asteroid's first +BODY costs **25** (was 50); later copies as before. `FirstSession.FirstCopy` |
| Checked | FIRST LIGHT can be pressed at once (start XP 2 = its cost). NEXT shows the tutorial's buy, all under 10 s away in the sim. |

# B. THE 4 DEAD-GAME FEATURES (ship with the Sat 14 Nov update, owner 9 Nov)
## 1. Monthly PARTY (`GameConfig.Parties`)
- **First party:** `Starfall2026`, "STARFALL PARTY", 27 Nov 12:00 UTC, 10 days. Add next month's party to the same table.
- **Quests:** catch 15 comets, go Supernova 3 times, visit 3 islands (stand on another player's island). Counted from when the party starts for you.
- **Reward:** the **STARFALL TRAIL**, kept forever, earnable only during the party, never sold. The trail picker shows it as "STARFALL PARTY 2026".
- **Decorations (GalaxySocialService):**
  - falling stars over the plaza;
  - the rim lamps in party colours (put back after);
  - the party's name floating over the Core.
- **Music:** `Sounds.PartyTrack` (Get Going B), looped while a party runs and no 2x event is on.
- **On screen:** a **PARTY chip** in the left column ("PARTY 6d 3h", the real time left); tap = the **PARTY window** (3 quest bars + the reward).
- **Analytics:** Party_Joined, Party_QuestDone, Party_ItemEarned.
- **Not built:** a party board on the plaza. A new board needs the map rules (layout table, MapAudit, screenshots), and the chip + window show the same.
- **Studio:** `Workspace.TestParty = true` runs it now.

## 2. ISLAND STARS (`GameConfig.IslandStars`)
- **The pad:** a gold **LEAVE A STAR ★** pad on every stone island, beside the path from the bridge (island-local -22, 8).
  - Step on it, or click / tap it.
  - Hidden on your own island.
- **Rules:**
  - 1 star per visitor per island per UTC day (in the visitor's save).
  - The owner gets a toast, and **+1% stardust per star today (max +10%)**.
  - The island's name tag shows "★ n" (all-time stars).
- **TOP ISLANDS THIS WEEK:** an OrderedDataStore per week (Mon 00:00 UTC). It's the leaderboard wall's 2nd page: 12 s each with TOP SUPERNOVAS, skipped while empty.
- **Badge** "STAR ISLAND" at 50 stars (id 219812428263214; +3 Essence in game).

## 3. THE GREAT STAR (`GameConfig.GreatStar`)
- **The count:**
  - Every Supernova in any server = 1 point.
  - Each server adds its points with **one UpdateAsync every 30 s** (DataStore `GalaxyGreatStar`, key `w<week>`). With nothing to add, it reads with GetAsync instead. That's about 2 requests a minute a server, far under the limits.
  - A closing server writes its last points.
- **Stages:** **25 / 75 / 150 / 300 / 500** (owner 9 Nov, for ~25 DAU; the night shift suggests new numbers every Monday).
- **A new stage, in every server within 30 s:**
  - fireworks round the Core, a sound and a toast;
  - **x2 STARDUST for everyone online for 10 min**;
  - the Core's star (orb + spikes + lights) grows x1.12 per stage, drawn on each screen.
  - A server that starts mid-week doesn't celebrate old stages.
- **Gifts:** everyone who added a point that week claims at the **Core's altar** (the prompt shows only when you have a gift). Stages 1-4 = 10 min of income; stage 5 = 2 Essence.
- **Display:** a floating panel over the Core: points / next, stage n/5, a bar, "YOU ADDED n THIS WEEK · n GIFTS TO CLAIM". It sits on the Core (the plaza centre's one landmark), not on a new board.
- The STAR SURGE stays as it was.
- **Fixed in the test run:** the first version counted a save's loaded Supernova total as new points. It now counts only real Supernovas (`Shared.onSupernova` from doSupernova). Your Studio test save got 35 points in the Studio-only store; the weekly reset clears them.

## 4. LUMI PET (`GameConfig.LumiPet`)
- **The pet:** LUMI floats beside every player who has it on.
  - A 2.5-stud billboard with a soft glow.
  - Follows on a spring and bobs.
- **Reactions:** a buy = happy; a new body / pad = excited; a Supernova = proud. Others' pets react to their own players too.
- **Nothing to buy for 20 s:** thinking, then pointing + "Next: <the cheapest thing> · <price>".
- **Tap your LUMI:** one of 20 friendly lines.
- **Settings:** a new row with **LUMI PET ON / OFF** and **TRAIL** (wear a trail you own, or none).
- **Others' pets:** only within 60 studs, and none on low graphics (quality 1-3).
- **Later:** outfits as fixed-price cosmetics (not built).

## Files (Studio)
- **New:** `ServerScriptService.GalaxySocialService`, `StarterPlayerScripts.GalaxySocial`.
- **Changed:**
  - `ReplicatedStorage.Galaxy`: GameConfig, EconConfig, Sounds, UIKit (event music can take another track), PlazaBoardsUI (`setTitle`).
  - `ServerScriptService`: GalaxyEconService, GalaxyGrowthService.
  - `StarterPlayerScripts`: GalaxyMapClient (first-comet arrow, ★ on the name tag, the wall's 2 pages), GalaxyHUD (welcome gift, party window in the side list), GalaxyLive (party music), GalaxySettings.

## Owner
1. **Test on a new save:** gift at 1.5 s, pad 1 for 5, a comet at ~8 s with the arrow.
2. **Test with 2 players:** star an island; check the TOP ISLANDS page; see each other's LUMI.
3. ~~Tune the Great Star stages~~ done: 25 / 75 / 150 / 300 / 500 (below).
4. STAR ISLAND badge: created 9 Nov, id 219812428263214, in `GameConfig.Badges.StarIsland`.
5. File > Save; **publish Sat 14 Nov** with everything else (the party starts by itself 27 Nov).

## Decisions (owner, 9 Nov)
1. **Great Star stages = 25 / 75 / 150 / 300 / 500** (set in Studio's GameConfig). At ~25 DAU, 500 would never be reached and a goal nobody hits feels dead. Raise roughly x10 per x10 players (back to 500 / 1.5K / 3K / 6K / 10K at ~500 DAU). The night shift checks the weekly points on Mondays and suggests the next numbers.
2. **Publish everything together on Sat 14 Nov** (after the owner's test): the first-30-seconds fix is the most important change and shouldn't wait a week. Island stars, LUMI and the Great Star arrive a week early; the party starts by itself on 27 Nov.
3. **No plaza party board**: the PARTY chip + window already show the quests; a new board would need a map pass for little gain.
4. **STAR ISLAND badge: created 9 Nov (id 219812428263214, in GameConfig).** The +3 Essence reward already works without it; saves that earned it get the Roblox badge on their next join once the id is in GameConfig.
5. Checked: no Test switches are on in Workspace (safe to publish).

# C. LAUNCH GATE PASS for Sat 14 Nov (9 Nov, Claude Code; owner: "do all the things we need to do")
Phone UI audit with `Tools/UIAudit` on 3 emulated phones (Studio TestDevice):
- SE 667x375;
- Android 800x360;
- iPhone 14 Pro 852x393 (notch).

Checked: the HUD, the RETURN screen, STORE, SETTINGS, DAILY, PARTY (test party on), the like panel, UPGRADES (BODIES / PERKS / BLACK HOLE).
**Result: CLEAN on all 3** (no overlap, nothing past the safe area or under Roblox's buttons, no text under 14 px, nothing clipped). Short toasts and the cutscene frame are brief pop-ups and were left out.

**Fixed to get there:**
- **SUPERNOVA button:** it sat on top of every open window on phones; it now steps aside while a window is open. Its "+294K SHARDS" line was 12 px and clipped; now ~15 px and it shrinks to fit.
- **DAILY window:** 45 texts were 8-13 px (it never had a phone layout; the new WEEKLY GOAL row made it smaller still). On phones it now fits the width and scrolls, like STORE / STATS, with 17+ design px texts. Day 7 reads "+5 +TRAIL" on phones (the 1 h warp is in the line under the tiles).
- **PARTY window:** texts 12 px → 20 design px.
- **SETTINGS:** button labels 13 px → 21 design px.
- **STORE:**
  - short card lines on phones (`short` in GameConfig.Products);
  - the offer shows "46:15:13 LEFT".
- **UPGRADES phone layout:** 272 tall (was 284), so it's drawn 1:1 on the 360-px Android too (it was 0.96 → 13.4 px).
- **Windows:** centred 8 px lower in the safe area, so the title icon clears Roblox's buttons.
- **Glows and shine bands** are marked as decoration (`AllowOverlap`).
- **The Supernova bar's star:** smaller (24 px, x0.6-1.0), inside the counter: on the 14 Pro it reached into the shards counter / NEXT.
- **UIAudit itself:** it now only judges the part of a thing that can SHOW (scrolling lists and clipping frames cut the rest). Before, a long list's off-screen rows counted as "past the safe area". Text checks still cover every row. Updated in the place, `Roblox Playbook/Tools/UIAudit.lua` and `Celestial Incremental/Code/tools/UIAudit.lua`.
- **Studio-only test switch:** `Workspace.TestOpenWindow` = "E" / "Q" / "J" / "Y" / "L" opens that window (for these audits).

After the tests: Workspace has no attributes left; Studio's replication lag is 0.

**Launch gate status:**

| check | status |
|---|---|
| Impatient kid sim 100% past 60 s | ✅ |
| Something every ~3 s in the first 30 s | ✅ (sim) |
| Phone UI audit (3 phones) | ✅ CLEAN |
| Like prompt only after the first big moment, no reward | ✅ |
| No Test switches; StreamingIntegrityMode = PauseOutsideLoadedArea | ✅ |
| Someone else plays 10 min on a real phone, fresh account | ❌ **owner** |
| 2-player test (Test > Clients and Servers, 2 players): stars, LUMI, party visits, pads | ❌ **owner** (my Studio tool runs 1 player) |
| File > Save, title without [ALPHA] | ❌ **owner**, before publishing |

# D. BOOSTS PANEL + PHONE COLUMN (9 Nov, owner: "the boosts labels need to be better" + "is the mobile screen fixed")
**The "bottom not showing" windows:** fixed on 8-9 Nov (the fit rule + phone layouts drawn 1:1). UPGRADES is 600x272 on phones, so it fits even the 360-px-tall Android. Section C's audit was CLEAN on 3 phones.

**Found today:**
- On phones the left chip column ran off the bottom once PARTY + STARTER joined it: the BOOSTS chip was off screen.
- The BOOSTS list (it opens on a tap) was never audited. It was a plain black box of text lines.

**Fixed (GalaxyPotions, GalaxyGrowth, GalaxySocial):**
1. **The BOOSTS panel** is a kit panel now:
   - a header: the BOOSTS icon + title + the total in a gold pill;
   - one card per boost, like the potion cards: dark plate, ink outline, an edge in the boost's colour, a shine line, its icon, its name, a line under it (real time left / "forever" / why) and a value pill in its colour;
   - it lists every boost: event, Great Star, Star Surge, x2 STARDUST (any source), x2 COMETS, x2 PASS, VIP, Premium, friends, group, island stars.
2. **Placement:** right of the whole chip column, its bottom level with the BOOSTS chip. It never covers the counter / NEXT line or the hotbar. It shows whole cards only and scrolls the rest. Full size on phones; scaled like the HUD on PC.
3. **Phones:** FRIENDS / GROUP / PREMIUM left the column and are cards in the BOOSTS panel with their own green button (INVITE / JOIN / GET), only while you can still get them. The column now fits: PARTY, STARTER, GIFT, BOOSTS.
4. **Chip labels say what they are on phones too:** "BOOSTS x2.35", "STARTER 45:56:02", "PARTY 1d 0h" (they were just "x2.35" / a bare timer).
5. **UIAudit:**
   - TEXTHIT only counts the parts of texts that show (scrolled-out rows gave false hits);
   - the emulator's device frame no longer counts as clipping.

   Vault copies updated.
6. **Studio test switch:** `TestOpenWindow = "close"` closes the open window.

**Audit (BOOSTS panel open, scrolled to the top and to the bottom):** CLEAN on SE 667x375, Android 800x360 and 14 Pro. PC: no overlap or clipping. Studio is clean: no Workspace test attributes, replication lag 0.

Note: the stardust jumps in the test save between runs are AUTO-BUY (on in the save) spending it, not a bug.

# E. JUMP, THE STORE SCROLLS, THE LEFT CHIPS (9 Nov, owner)
**Jump** (owner: "lower the jump power by a bit and decrease the gravity too"):
- `GameConfig.Movement`: GravityCut 115 → **95**, new **JumpHeight 5.3** (was 7.2).
- GalaxyMapService sets the jump height on every spawn; StarterPlayer.CharacterJumpHeight = 5.3.
- Measured in Play: **11.2 studs high, 0.98 s in the air** (was ~12.3 / 0.92). Lower and floatier.

**STORE** (owner: "shop UIs are supposed to be scrollable, not a long one that fits in the screen"):
- **Cause:** the 7 new product cards made the window ~1300 tall, and the fit rule drew all of it at **x0.30**. The tiny scale also broke the product cards' text (titles over prices).
- **Now:** a fixed window like the others (PC 620x480, phones 620x272 like UPGRADES); the cards + CODES scroll inside it (Kit.scroller: wheel, drag, gold thumb, taps work on phones). PC draws it at the HUD's scale (x0.76 in Studio's small window), SE at x0.96.

**Left chips** (owner: "the labels on the left side of the screen are so ugly"):
- **Kit.hudChip** is redrawn in the top HUD's style (LVL / SHARDS / counter): the slanted plate (A.plate) with an ink outline and a dark inside, a thin line in the chip's colour under the text, the LVL chip's diamond tile with a coloured rim behind the icon, white text with an ink outline. The plate grows with its text.
- The stretched art chips (Kit.HudArt chip*) aren't used any more. One change in the kit, so every chip changed: PARTY, STARTER, GIFT, FRIENDS, GROUP, PREMIUM, BOOSTS.
- PC labels are shorter: "FRIENDS +10% EACH", "PREMIUM +10%".

**LUMI's line bubble:** it was 9 x 1.6 studs, so close to the camera it covered the whole top HUD. Now it's a fixed 290x34 px kit plate (gold rim, 14-18 px text).

**Audit (SE):** HUD, BOOSTS panel, STORE top and bottom: all CLEAN. Studio is clean: no Workspace test attributes, replication lag 0.

**Not changed:** STATS (560x620) is the other tall window. On a normal PC screen it fits at full size; only a small window shrinks it a little.

# F. BOOST TILES, LIKE PET SIM 99 (9 Nov, owner: "boosts bottom left with little icons, hover shows the effect like GROUP +23%")
**Built (GalaxyPotions):**
- The BOOSTS chip became a **row of small boost tiles**: the last row of the left column.
  - **PC:** the column now ends near the bottom-left corner (was 80% down).
  - **Phones:** the column's end, under the chips (the thumbstick owns the bottom-left corner).
- **Each tile:** the hotbar's dark rounded plate, a rim in the boost's colour, its icon, and under it the **time left** ("4:59", "1h05") or its **value** ("+10%"). Up to 6 a row, 2 rows.
- **The first tile is the TOTAL** ("x4.35"). Click / tap it = the full BOOSTS list (the panel from section D, with the INVITE / JOIN / GET cards on phones).
- **Tooltip:** hover (PC), or tap (phones, 3 s), shows a plate above the tile:
  - the name ("GROUP");
  - the effect in green ("+10% stardust"; VIP "+25% stardust, +10% shards"; x2 COMETS "x2 comets");
  - why / how long ("P&L Studios XP", "4:59 left", "forever").
- **Also:** LUMI's bubble text was invisible (the plate's gradient darkened the text too). The plate is now its own frame under the text.

**Checked:**
- PC, Play: 4 tiles show (x2.35, x2 PASS, VIP, GROUP). A real mouse hover shows the tooltip.
- UIAudit on PC: no overlap or clipping. The small text sizes come from Studio's small window; the whole HUD shrinks the same way there.
- **Phone audit NOT run yet:** Studio's Play start hung (stuck "start play", no dialog seen in the viewport). Run the SE / Android / 14 Pro check once Play starts again.
