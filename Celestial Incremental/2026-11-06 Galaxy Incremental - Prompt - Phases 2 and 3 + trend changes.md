---
date: 2026-11-06
tags: [galaxy, prompt, phase2, phase3]
---
# Galaxy Incremental - Prompt: Phases 2 + 3 with the 6 Nov trend changes

Sources:
- [[2026-11-05 Galaxy Incremental - BUILD PLAN in priority order]]
- [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]]
- [[2026-11-06 PLAN - Trend research applied to Galaxy Incremental and +1 SHRINK]]

Answers to Claude Code's pad/crystal report (6 Nov):
1. Pads hidden from the landing point: leave them.
2. Gyro ring: leave it.
3. Forge sign: yes, change it to "IGNITION 1".

```text
GALAXY INCREMENTAL – PHASES 2 + 3 (+ the 6 Nov trend changes). Quality over speed.

READ FIRST (all of them, before touching anything):
- Celestial Incremental\2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built).md
- Celestial Incremental\2026-11-05 Galaxy Incremental - BUILD PLAN in priority order.md
- Roblox Playbook\Research notes\2026-11-06 PLAN - Trend research applied to Galaxy Incremental and +1 SHRINK.md
- Roblox Playbook\Research notes\2026-11-06 Research - Depth Incremental (10 videos watched).md
- The source note for each row you build (the checklist's "Source" column).

HOW TO WORK (applies to every step):
- One step at a time, in the order below. Build it, test it, write its Progress note, update its checklist rows (BUILT/PARTLY + evidence), then go to the next step. At the end of each PHASE stop and send me the report. Don't start the next phase without my OK.
- Don't publish. Save only in Studio. No hand-placed parts: everything goes through the builder + config (as in the pad fix).
- Never remove or weaken anything a player owns. Old saves must load (add a save-version migration whenever the save shape changes).
- Use the locked UI kit and the art rules: our own textures, designed art, no placeholders, no emojis in UI. Every action gets sound + visual + number (#227).
- Server checks every buy, claim and reward. Rate limits. Developer products are granted only in ProcessReceipt, saved first, never twice (#454).
- No paid random items. No fake timers or "was" prices. Odds are shown before any free random roll.
- Test every step:
  (a) a bot run with the timing printed;
  (b) a PC screenshot plus a 667x375 phone screenshot of every new screen;
  (c) a 2-player local server for anything social;
  (d) FPS on the phone emulator stays at least what it is now.
  Put the screenshots in the Progress note.
- If a number isn't decided in the notes, pick it from the research, write WHY in the note, and flag it for review. Don't stop to ask.

QUICK FIX FIRST: change the Sector 2 Forge sign from "SUPERNOVA 3" to "IGNITION 1". Leave the 3 pads hidden from the landing and the Gyro ring as they are.

══════ PHASE 2 – reasons to come back (blocks the ALPHA 21 Nov) ══════
2.1 GALAXY LIT BAR (new, from the Depth research)
- A thin always-on bar at the top centre of the HUD: the sector name + "GALAXY LIT 7%", filling as you play. It's the one big "how far" number, like Depth's depth bar.
- It replaces nothing: the SUPERNOVA % goal bar stays under the counter (#141).
- Tap it to open the Sectors window (#27, #14). Locked sectors are dark "?" silhouettes; each lists its rooms with a % complete.
- Also show it on your island plate and as a leaderboard column (#406).
- Phone: it must not cover the top bar or the chat button.

2.2 AUTOMATION (moved to the front: the late reward in every game watched; #55, #94, #417, #50)
- Ring 2 AUTOMATION branch:
  - auto-buy bodies (toggle);
  - keep ring 1 through Supernova;
  - better offline (feeds 2.3).
- Unlock timing: auto-buy around minute 60 of play, as decided.
- Rule: "each layer automates the last layer's busywork".
- Show the moment with the cutscene template: a short "AUTOMATION ONLINE" beat ending on a tease.

2.3 OFFLINE EARNINGS + RETURN SCREEN (#411)
- 50% of income for up to 4 h (better with the Automation node).
- Return screen:
  - "While you were away" + the amount with a count-up;
  - CLAIM (free);
  - an x2 Robux option (developer product, server-granted).
- Never block play; it closes with X.

2.4 DAILY REASONS (#412, #413, #414, #435)
- 7-day streak calendar (Essence 2/2/3/3/4/4/5 + Time Warp on day 7). Missing a day resets to day 1 but keeps what you got.
- 3 daily quests sized to one session (Essence + income-scaled stardust). Add a QUESTS key on the hotbar (#142).
- Playtime gifts at 5/15/30/60 min, 1 Essence each.
- Plus a lobby FREE REWARDS board (new): like the game / join the group → claim once, server-checked through the group API; liking can't be verified, so make it a one-time honour-system claim.

2.5 FORGE COLLECTION BOOK (#62, #438; Depth fossil-list lesson)
- 42 Star Cores (7 rarities x 6 kinds), greyed "?" until found. Duplicates level cores 1-10.
- Each core has a MAX level; when a kind is maxed, that kind's roll weight moves to the rarer ones.
- % complete per rarity and in total. Small rewards for completing a rarity (title, badge, card trim).
- Rarity colour ladder grey/green/blue/purple/gold/rainbow, with a text label (#158).
- Forge sound ladder (#247) and the roll VFX ladder finished (#289).

2.6 RING 2 COMPLETE (#53, #54, #56, #136, #135)
- COMETS branch (Comet Chain, Golden Comets, Comet Tail) and FORGE branch (Forge unlock, +1 Essence, Forge Luck, Bulk Roll).
- Capstone pick 1 of 3, free swap on each Supernova.
- A BUY ALL AFFORDABLE button in the tree. The tree shows the next 2-3 nodes; the rest stay "?".

2.7 SMALL POLISH that blocks the alpha:
- #2 Supernovas leaderstat.
- #4 Stats screen (income split by every multiplier, time to next Supernova).
- #6 number format setting.
- #144 BOOSTS chip and #229 ACTIVE BOOSTS panel.
- #214 beacon on a board only while something is buyable.
- #215 locked FORGE/BLACK HOLE boards with a padlock and unlock text.
- #138 phone layout for UPGRADES + tree, captions at least 14 px.
- #163 one window at a time.
- #91 save on leave/shutdown/purchase with pcall + retries.

PHASE 2 REPORT, then STOP:
- Bot timeline of the first 90 min: every purchase, unlock and quest, and the longest gap with nothing new (target under 5 min, #420).
- Screenshots of every new screen (PC + phone).
- Checklist rows updated.
- Anything you flagged.
- A recommendation for the friends test.

══════ PHASE 3 – full launch content (launch 5 Dec) ══════
3.1 BLACK HOLE layer (#58, #26, #299, #258)
- Needs 100K shards; Dark Matter = floor(sqrt(shards/1000)), +25% shards each.
- WOAH moment: everything pulled in, warping rings, silence, dark pulse, plus its sound.
- Auto-Supernova unlocks here (#417).

3.2 RING 3 Dark Matter tree (#57): 10 nodes + capstone pick (Singularity / Nebula Heart / Time Dilation).

3.3 SECTOR GUARDIAN BOSSES (new, from the Depth research; from IGNITION 2 on)
- Each new sector is guarded by a boss at its gate (Sector 2 Comet Reach, then Nebula Gate...).
- Short arena fight: telegraphed attacks on the floor, 3 hearts, retry any time, damage based on your income.
- The kill drops the SECTOR KEY that opens the next sector.
- After a reset the old boss can be one-shot (power fantasy, the clip moment).
- Each boss gets a cutscene intro and a server message on the kill.
- Phone controls: one ATTACK button. No paid revives.

3.4 SECTORS AS PLACES (#19, #361, #362, #13)
- Each sector has its own sky colour and island look (EMBER BELT warm, Comet Reach icy, Nebula Gate violet, Ring Nebula pink).
- The galaxy lights up per completed sector.
- Pulsar tier at Black Hole 1, Quasar at Black Hole 2 (#43, #300, #259).

3.5 EVENTS (#415, #416, #145, #439, #478)
- Weekly METEOR WEEKEND, Sat 15:00 UTC (x2 comets, golden x2), switched on by Config at that time. Event pill on the HUD while it runs.
- Lost Stars hunt + weather events.
- Each weekly update also gets a Roblox Experience Event (I make it in the Creator Dashboard; give me the text).

3.6 SOCIAL (#392, #402, #403, #407, #399)
- Server message on Supernova / Mythic+ roll / boss kill.
- Fastest-Supernova and fastest-Black-Hole boards.
- Server crown for the top player.
- Invite reward for both players.
- Shared sky: constellations anyone lit stay.

3.7 ACHIEVEMENTS + CHALLENGES (#410, #437, #63): achievements % and Cosmos Charted %; 4 challenges at Supernova 8.

3.8 STORE (#441-#446, #449, #450, #457, #459, #460)
- Products:
  - VIP 399;
  - +1 Core Slot 349;
  - Auto Roll 199;
  - Time Warp 49/199;
  - Server Surge 99;
  - Supernova Starter 99 (offered once after Supernova 1, no timer);
  - private servers 100;
  - timed x2 boosts.
- A free way to earn a pass with tickets. Small product bubbles beside your system.
- Store opens after tutorial step 7. All pass icons 512, our art.

3.9 SOUND + VFX FINISH (#236, #251, #256, #257, #288, #306, #303)
- Supernova motif, layered hero sounds, stamp stinger, rank chime, Star Surge gold wave, Core rays.
- Record a 10 s clip of every hero effect and ask "would a kid post this?".

3.10 LAUNCH CHECKS
- #475 maturity questionnaire list.
- #479 restart outdated servers with a countdown.
- #480 admin tools logged.
- #92 erasure handler.
- #482 depth list for the description ("4 layers, 40 tree upgrades, 42 cores, sector bosses").
- #472/#484 title tag + update names + codes per update.
- #468 every asset owned by P&L Studios XP.

PHASE 3 REPORT, then STOP:
- Bot timeline of a full first day (0-4 h) showing when each new thing opens.
- Boss fight clips.
- Store list with prices.
- Updated checklist summary table.
- What is still NOT BUILT, and why.
```
