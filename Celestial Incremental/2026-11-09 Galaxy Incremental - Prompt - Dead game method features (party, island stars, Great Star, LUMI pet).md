---
date: 2026-11-09
tags: [galaxy, prompt, claude-code, social, liveops, dead-game-method]
---
# Galaxy Incremental: the dead-game-method features (owner, 9 Nov)

Owner: "lets put those researched information changes in galaxy incremental too".
Research: [[2026-11-09 Research - Dead game method (shut-down multiplayer games as an idea library)]] (section 4 "Steal NOW for Galaxy").
Checked in Studio first (9 Nov): islands can already be walked onto in the same server (boards show grey VISIT to visitors); the STAR SURGE bar exists (every Supernova fills 5%, full = x2 for 3 min); there is no island like/star, no lasting server project, no companion. So this builds only the missing parts.

Order: send AFTER [[2026-11-09 Galaxy Incremental - Impatient kid simulation + first 60 seconds fix]] (the first minute matters most). Target: the Sat 21 Nov update (14 Nov stays the pacing/movement/phone update).

```text
GALAXY INCREMENTAL – 4 FEATURES FROM THE DEAD GAME RESEARCH (Club Penguin, Toontown, Glitch, Moshi). Do NOT playtest and do NOT publish: the owner tests. Phone first (all UI follows the phone layout rules: safe insets, no centre-screen popups for people who didn't take part, text ≥ 14 px). All numbers in config. Use the existing EventController (GalaxyLiveService), WindowManager/UiKit, the island boards and the trail system; don't duplicate systems.

1. MONTHLY PARTY (Club Penguin's monthly parties: "were you there?")
   - Config.Parties = { { id = "Starfall", title = "STARFALL PARTY", start = "2026-11-27T12:00:00Z", days = 10, ... } }, one per month, run by the EventController.
   - During a party: plaza decorations (falling star VFX, coloured lights, banners: a PartyDecor model shown/hidden by the server), a party music track (from the hype playlist), and 3 PARTY QUESTS (e.g. "Catch 15 comets", "Go Supernova 3 times", "Visit 3 islands") on a small plaza board + the quest window.
   - Finishing the quests = a FREE limited cosmetic (the first one: a "Starfall" trail) that can ONLY be earned during that party, kept forever, shown in the trail picker with "STARFALL PARTY 2026". Never sold.
   - A HUD chip "PARTY: 6d 3h" with the real time left; tap = the quest window.
   - Analytics: Party_Joined, Party_QuestDone (quest id), Party_ItemEarned.

2. ISLAND STARS (Club Penguin igloos: decorate, others visit)
   - On every island (not your own), a "LEAVE A STAR" floor pad at the landing spot (tycoon-style, step on it) + the tap backup. 1 star per visitor per island per day (server checks, saved per UserId pair per day in a DataStore or a capped table in the visitor's save).
   - The owner gets a toast "★ <name> starred your island!" and the star count shows on the island's name tag ("★ 128").
   - Stars give the island owner +1% stardust each for the day (max +10%), so visiting matters.
   - Plaza board "TOP ISLANDS THIS WEEK" (OrderedDataStore, weekly key, Monday 00:00 UTC): top 10 by stars received.
   - Badge: "Star Island" at 50 stars received (id 0 until the owner creates it).
   - Party quest 3 above uses island visits.

3. THE GREAT STAR (Glitch / Toontown: the whole server builds something together)
   - A giant star sculpture in the plaza centre that GROWS in 5 visible stages every week.
   - Every Supernova by anyone, in ANY server, adds 1 point to a global weekly counter (MemoryStoreService sorted map or a DataStore key updated with UpdateAsync, batched every 30 s per server; key per week, resets Monday 00:00 UTC).
   - Stages at 500 / 1,500 / 3,000 / 6,000 / 10,000 points (config; the owner tunes them to the real player count). Reaching a stage: a server-wide celebration (fireworks VFX, a sound, x2 STARDUST for everyone online for 10 min) in every server, and everyone who added at least 1 point that week can claim a gift (stage 1-4: stardust; stage 5: 2 Essence) from the plaza.
   - A plaza board shows the progress bar ("THE GREAT STAR: 2,431 / 3,000 · stage 2/5") and "YOU added 14 this week".
   - Keep the existing STAR SURGE as it is (it's per server, short); the Great Star is the weekly, galaxy-wide goal.

4. LUMI PET (Club Penguin puffles / Moshi monsters: something cute that's yours)
   - LUMI (the tutorial guide, art already in ArtIds.lumi with 6 expressions) becomes a small companion that floats beside your character: a BillboardGui (studs-sized, 2.5 x 2.5, MaxDistance 60) with a soft glow + a gentle bob, following with a smooth spring (client-side, others see it too, low cost).
   - LUMI reacts: happy face on a buy, excited on a new body/pad, proud on a Supernova, thinking when you've had nothing to buy for 20 s (and then points toward the cheapest thing).
   - Tap LUMI = a quick line ("Let's go Supernova!") from a list of 20 friendly lines.
   - Settings toggle "Show LUMI pet" (default on). Max 1 per player; hide others' pets beyond 60 studs and on low-end devices.
   - Later (not now): LUMI outfits as fixed-price cosmetics (never random).

REPORT (short): files changed, the config tables, how the global counter works (keys, batching, limits), and phone screenshots are NOT needed (the owner tests).
```
