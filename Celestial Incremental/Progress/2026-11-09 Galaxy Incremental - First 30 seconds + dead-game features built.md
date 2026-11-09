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
