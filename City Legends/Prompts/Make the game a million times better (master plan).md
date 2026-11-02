# Prompt: make City Legends a million times better (the master plan)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). This plan ranks the work. The other prompts in `City Legends/Prompts/` are the "how" for each piece._

## The honest truth first (tell the owner this)
City Legends already has a huge number of features: cars, police, heists, towers, the hotel, casino, houses, the market, customs, challenges, the chauffeur, and now Riviera Bay. **More features won't make it a million times better.** What makes top Roblox games win is:
1. **the first 3 minutes are amazing** (players who leave in the first minute kill the game's ranking);
2. **driving feels great**;
3. **it looks great on a cheap phone**;
4. **a clear goal ladder and reasons to come back** on day 2, 7 and 20;
5. **playing with friends**;
6. **actually launching it** and improving it from real player numbers.

So this plan is: **finish, polish, launch, measure, repeat.**

## Before you start
- Read:
  - `CLAUDE.md`;
  - **`Roblox Playbook/Roblox Playbook - Rules for every game.md`** (follow it);
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - **`City Legends/Research - Driving games.md`** (the 15 lessons from the top driving games; Midnight Racing: Tokyo is the owner's favourite, Driving Empire for interiors).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup first. The place is on Team Create.
- Work in **phases**. After each phase:
  - play-test (2 players, PC + phone size);
  - FPS and memory numbers;
  - Lune tests and `luau-lsp analyze`;
  - save, commit and push;
  - a short report to the owner with screenshots;
  - **wait for the OK** before the next phase.

## Phase 1: audit (no changes yet)
Play the game start to finish as a **brand-new player on a phone**, then as a level-30 player. Write a ranked list in `City Legends/Audit (date).md`:
- every **bug, script error, stuck spot, crash, memory warning** (e.g. the EditableMesh memory warning);
- every **ugly or unfinished** thing (grey parts, blocky cars, placeholder UI, floating objects, old-map leftovers);
- **lag** spots (FPS under 30 on phone-size);
- the **first 3 minutes** step by step, with timings: loading → menu → first drive → first money → first goal. Where would a kid quit?
- a comparison with the 15 lessons in the research note: have / missing / worse.
- **Show the owner the top 15.**

## Phase 2: make it solid and fast
- Fix every bug and error from the audit.
- **Performance pass** on phones: streaming, LOD, part counts, lights near the player only, no every-frame loops over everything, memory (the runtime car meshes), and a Low / Medium / High / Ultra graphics setting.
- **Targets:** 30+ FPS on a cheap phone on Low, 60 on PC; the loading screen with SKIP after 5 s; no console errors.

## Phase 3: the first 3 minutes (most important for growth)
- Loading: fast, a good-looking screen, SKIP at 5 s.
- **In a car and driving within 15 seconds.** The starter car is fun to drive.
- **First reward within 60 seconds** (a cut-up combo, a near miss, a small cash pop with sound and effect).
- Show the next goal clearly on the HUD ("Earn $5,000 for your first upgrade", then "Buy your first car at Legends Motors").
- Hints only when stuck; no shop pop-ups in the first session.
- The onboarding funnel tracked with `AnalyticsService` (Playbook rule).

## Phase 4: driving feel and looks (what players feel every second)
Finish these existing prompts, in this order:
1. `Camera and car movement like the video.md` (camera, body roll, speed feel);
2. `Better car models and clean interiors.md` (new car models, own clusters, doors; sounds when the owner sends IDs);
3. `Realistic graphics, lighting and buildings.md` + `Fix buildings that look off.md`;
4. `Make the Monaco map look real (from the drive video).md` (Riviera Bay realism, day / night / casino square).

## Phase 5: reasons to keep playing (retention)
From the research (Midnight Racing / Driving Empire / CDT):
- **Goal ladder:** milestones all the way (first car, first race win, first tune, 5 / 10 / 25 cars, first house, first High house...), each with a reward, shown in a "Goals" panel.
- **Daily streak:** 7 days, rising rewards, **day 7 = a free car** (forgive one missed day).
- **Tuning that changes the feel** (engine / turbo stages, tyres, suspension, weight), unlocked by level (MR:T's heart).
- **Weekly event** (Playbook: Saturday 15:00 UTC): a limited car, a double-cash weekend, a special race.
- **Quests** (3 daily, 3 weekly) that send players to every part of the map.
- **Collection:** a "garage %" and a showroom of everything you own.

## Phase 6: play with friends
- **Races against players:** a lobby at a start line (up to 8, entry fee pot), plus quick 1v1 duels you challenge from the player list.
- **Crews:** name, colour, crew garage / meet spot, crew leaderboard (filtered text).
- **Car meets:** the casino square night show and parking spots where players line up cars, honk and vote "best car".
- **Cops vs. robbers** with players as police (optional team).
- **Invite reward** for both players (Playbook).

## Phase 7: get ready to launch
- Follow the Playbook storefront rules:
  - 3–5 **custom thumbnails** made from real gameplay (a car on the Riviera at sunset, the casino square at night, a race start);
  - an **icon** that's readable small;
  - a clear name and description;
  - the Maturity & Compliance questionnaire;
  - the genre set.
- **Money (fair):** a small catalogue (for example a VIP pass, a 2x cash pass, a starter pack under 400 Robux), prices read from Roblox, products granted only in `ProcessReceipt`, saved before confirming. Never sell race wins.
- **Admin tools:** server-checked permissions, actions logged, the Ban API. The test switches (`UnlockEverything`) are off in the live game.
- Saves: a version number, safe loading, a backup.
- **Show the owner everything before publishing.** The owner publishes.

## Phase 8: after launch (forever)
- Every week:
  - read D1 / D7 retention, the onboarding funnel, session length, FPS and crashes;
  - **fix the ONE biggest leak**;
  - ship one update on the Saturday slot, with new content behind a Config switch.
- Big updates every 2–4 weeks: new cars (the owner's models), new districts, events.
- Keep notes in `City Legends/City Legends.md`.

## Always
- Fictional names, no logos.
- No neon.
- No alcohol (no clubs; DJ only in penthouses).
- Casino scenery only.
- Driver hands are the player's R6 avatar hands.
- No auto-loading Creator Store models.
- Never touch the owner's passwords.

## When done with each phase, tell the owner (short)
- what's done;
- screenshots;
- the numbers (FPS, timings);
- what's next;
- anything you need from the owner (models, sound IDs, decisions).
