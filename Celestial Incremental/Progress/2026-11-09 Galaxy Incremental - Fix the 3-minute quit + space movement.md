---
date: 2026-11-09
tags: [galaxy, progress, pacing, retention, economy, movement]
status: in Studio, NOT playtested (owner tests), NOT published
---
# Galaxy Incremental: fix the 3-minute quit + space movement (9 Nov, Claude Code)

Prompts:
- [[2026-11-09 Galaxy Incremental - Prompt - Fix the 3-minute quit (first 10 minutes pacing)]]
- [[2026-11-09 Galaxy Incremental - Prompt - Space movement (speed + low-gravity jump)]]

No playtest, as the owner asked. The only test was the Calc bot `Calc/live.py` (a simulation). Every changed script compiles.
Checklist rows: #84, #124, #223, #414 updated.

# A. THE 3-MINUTE QUIT

## What was wrong
**The economy numbers are NOT the problem.** The live EconConfig uses exactly the plan's formulas and costs:
- income 5^k x level x copies x 2^tier;
- UPGRADE 10 x 8^k x 1.8^level;
- +BODY 50 x 8^k x 4^(copies-1);
- unlocks 80 / 640 / 5,120, the same pads, the same XP formula.

The owner's screenshot matches them exactly: Asteroid Lv5, 1 copy, First Light, **+7.2/s**. "ROCK ASTEROID 4.22K" = levels 5→10 at x1.8 = 4,222.

**The guidance was wrong:**
1. **The HUD NEXT goal showed the cheapest thing you could NOT afford yet.** At 435 stardust the Moon (80), the next pad (60) and +BODY (50) were all affordable, so NEXT skipped them and showed ROCK (4.22K, ~10 min). It never showed a cheap buy or a single level-up. After the Gas Giant it showed a Supernova-sized goal (284K, "16 min").
2. **The tutorial order:** step 7 was "Asteroid to ROCK (Lv 10)", BEFORE "UNLOCK the Planet" (step 8). The plan has Planet 2:08 → Gas Giant 3:04 → Rock 3:41.
3. **After the tutorial's Gas Giant step nothing tells you what to buy** until the Supernova: in the bot, ~5 minutes of zero purchases with the stardust piling up.

**LIVE vs PLAN, every number that differs:**

| thing | plan (feel.py) | live | effect |
|---|---|---|---|
| NEXT goal | (not in the bot) | cheapest UNaffordable named thing | **the bug**: points at 4-16 min goals |
| tutorial order | Planet, Giant, then Rock | Rock (7) before Planet (8) | a ~4K grind at ~2 min |
| comets | x1.5 income on average | none before step 6, then every 20 s worth 30-60 s of income, 1 in 10 golden x5 | huge swing: 0% caught vs 50% caught = minutes apart |
| tutorial payout | none | ~20 s of income per step | faster |
| Supernova 1 | 300K (timeline run) | 250K | faster |
| XP start | 0 | 2 (First Light free) | same curve |
| perks open at LVL 1 | 2 | 4 | none |

**Bot vs Studio:** with no comets caught, the bot's best player reaches the first Supernova at 3:20. The Studio bot (5 Nov) measured 3.7-4.3 min, so the bot is close.

## The bot timelines (`py -I Calc/live.py old|new <catch rate>`)
**Players:**
- **guided** = a new player: does what the tutorial asks, buys the NEXT goal when they can pay for it, and otherwise waits.
- **best** = the plan's best-choice buyer.

**Times:** bot time → real time (x1.4, the plan's rule for real players).

**OLD (live today), guided player, 25% of comets caught:**

| bot → real | what |
|---|---|
| 0:36 → 0:50 | PAD 1, MOON |
| 1:00 → 1:24 | NEXT = 4.39K (192 s away): the ROCK goal from the screenshot |
| 2:02 → 2:50 | ROCK Lv10, then PLANET, PAD 4 |
| 2:14 → 3:07 | GAS GIANT |
| 2:14-8:39 | income stuck at 247/s: **no purchase for 6+ minutes**, NEXT = 284K (16 min) |
| 8:39 → 12:06 | Supernova ready |

**NEW (after the fixes), guided player, 25% of comets caught:**

| bot → real | what |
|---|---|
| 0:35 → 0:49 | PAD 1 |
| 0:36 → 0:50 | MOON |
| 0:39 → 0:54 | PAD 4, PLANET |
| 0:41 → 0:57 | COSMIC LVL 2 |
| 1:09 → 1:36 | first perk the player picks himself (STARDUST) |
| 1:10 → 1:38 | GAS GIANT, ROCK Lv10 |
| 1:49 → 2:32 | COSMIC LVL 5 |
| 2:30 → 3:30 | the x2 STARDUST gift (5 min) |
| 3:15 → **4:33** | **first Supernova** |

- **Income every 30 s (bot):** 1, 2, 68, 851, 1,055, 2,777, 3,075 /s.
- **NEXT is never more than 17 s away.**

**First Supernova, real time, by comets caught:**

| comets caught | old game | new game |
|---|---|---|
| 0% | not in 14 min | 4:52 |
| 25% | 12:06 | 4:33 |
| 50% | 9:38 | 3:02 |

**Targets:**

| target | new game |
|---|---|
| no gap over 20 s without a buy | longest gap 24 s bot (the very first one); NEXT always within 17 s |
| something NEW every 30 s for 5 min | met except the first 35 s (asteroid levels before step 1, like the plan's own start) |
| first Supernova 4:30-5:30 | 4:33-4:52 at 0-25% of comets |

**Caveat:** a player who catches half the comets gets there in ~3:00. That's the comet values (live run-1 comets pay far more than the plan's x1.5). **Owner to decide** whether to lower run-1 comet value; I didn't change it.

## What changed
1. **HUD NEXT goal (GalaxyHUD)**, in this order:
   1. while the tutorial asks for a buy, that buy (NEXT and LUMI never point two ways);
   2. else the cheapest NEW thing (unlock, +BODY, pad, named tier) within **60 s of income**;
   3. else a PERK your XP pays for ("NEXT: PERK STARDUST · 4 XP");
   4. else the cheapest single UPGRADE.

   The Supernova stays the bar under the counter.
2. **Tutorial order (EconConfig):** ... Comets, **Planet, 4 pads, LVL 3, Gas Giant, Rock**, Ready, Supernova ... Steps 12-20 are unchanged, so STORE_AT_STEP 14 still means the same step. Players mid-tutorial just carry on: steps check what you own.
3. **XP for the first 5 levels:** XP x1.3 and at least 0.12 a second until Cosmic LVL 5. Bot: LVL 2 ~0:57, LVL 5 ~2:32 (real). From LVL 5 on, XP is as before, so nobody's level or XP changes.
4. **Level-up feedback:** it already had the milestone sound + a chip pop; now also a "LEVEL UP! COSMIC LVL n" toast.
5. **The 2:30 gift:** a new first playtime gift at 2:30 = **x2 STARDUST 5 min**. It uses the existing GIFT chip and DAILY tiles (now 6 tiles in the same 3x2 grid).
6. **Supernova preview:** the SUPERNOVA % bar shows from tutorial step 2 (~minute 1; it was step 9). A star at its right end grows from x0.55 to x1.15 as it fills.
7. **Onboarding funnel (GalaxyEconService):** 10 steps:
   1. spawned
   2. first buy
   3. first pad
   4. Moon
   5. Planet
   6. LVL 5
   7. first perk
   8. Gas Giant
   9. first Supernova
   10. second Supernova

   - Each is logged once per NEW save and in order; a step reached early is logged when the ones before it are.
   - Saves from before today are marked `funnel = -1` and never logged, so they can't flood it.
   - The 20 tutorial steps are now a custom event `TutorialStep`.
8. **Values in GameConfig:** `Config.FirstSession = { EarlyXP = { Until = 5, Mult = 1.3, Floor = 0.12 }, FirstGift = { minutes = 2.5, boostMinutes = 5 }, NextWithin = 60 }`. EconConfig reads them.

**Not changed:**
- Supernova 1 stays 250K: raising it would move unfinished players' goal further away (Playbook rule 8).
- No cost, income or comet value changed.

# B. SPACE MOVEMENT

**Values (GameConfig.Movement):**

| setting | value |
|---|---|
| WalkSpeed | 24 |
| GravityCut | ~~115~~ **95** (owner 9 Nov: "decrease the gravity") |
| JumpHeight | ~~7.2~~ **5.3** (owner 9 Nov: "lower the jump power by a bit"; StarterPlayer + set on every spawn) |
| VoidDepth | 40 |
| RailHeight | 7 |

**Walk speed:**
- `StarterPlayer.CharacterWalkSpeed` = 24.
- GalaxyMapService also sets 24 on every spawn.
- **Nothing reset WalkSpeed anywhere:** I searched every script for WalkSpeed / JumpPower / JumpHeight / PlatformStand / Gravity / control disabling. The void rescue anchors the root while streaming (it doesn't touch the speed).

**Low gravity, per character (new LocalScript `GalaxyMovement`):**
- A VectorForce on your root (world space, centre of mass) = mass x (196.2 - 115). You feel 115 instead of 196.2.
- The mass is re-read when the avatar's parts change and once a second.
- Workspace.Gravity is untouched.
- ~~The jump is unchanged (JumpHeight 7.2), ~12 studs high.~~ **9 Nov, owner:** jump 5.3 + felt gravity 95 = **11.2 studs high, 0.98 s in the air** (measured in Play; was ~12.3 / 0.92 s): a lower, slower, floatier jump.
- Pads use Touched as before.

**The feel:**
- **Your jump:** a low quiet whoosh (`jump`, Roblox UI whoosh) + a stardust puff (`sparkle_star` _alpha, LightEmission 0).
- **Your landing after a real hop:** a dust ring (`ground_dust_ring` _alpha) + a small puff.
- **Rate limit:** 0.25 s; phones get half the particles.
- **Other players:** only the puff and ring, no sound, half rate, within 60 studs.

**Void safety:**
- **The catch:** the existing hotfix catch stays (server, 4 times a second, 40 studs under the floor, `RequestStreamAroundAsync` first, anchored while waiting). It now reads `VoidDepth`, and tells your client "VoidRescue": a 0.15 s fade to the void's colour + a low whoosh. The fade lifts once the server lets go of your root (max 5 s). No death, nothing lost.
- **Invisible edge rails** (CanCollide only; invisible, no shadow, CanQuery off so the camera and board taps ignore them, CanTouch off so the pads never see them):
  - round every **stone island's** rim, just outside the brass rim, open at its bridge (built with pad 1, so it's there whenever the stone disc is);
  - along **both sides of every island bridge**, following the arch;
  - round the **plaza's rim**, open at the 8 island bridges and the Sector 2 bridge, in an always-streamed model.

  The bare asteroid (no pads yet) has no rail.
- **MapAudit not run** (it needs Play, and the owner said no testing). The rails are marked `EdgeRail` + `NotGround`.

# Files changed (in Studio)
- `ReplicatedStorage.Galaxy`: GameConfig, EconConfig, Sounds.
- `ServerScriptService`: GalaxyEconService, GalaxyMapService.
- `StarterPlayerScripts`: GalaxyHUD, **GalaxyMovement (new)**.
- `StarterPlayer.CharacterWalkSpeed`.
- Vault: `Calc/live.py` (new bot), `Calc/old_timeline.txt`, `Calc/new_timeline.txt`.
- **Vault code copies (`Code/friends-test/`) are not updated** (no file sync from Studio this session). Studio is the source.

# Owner to check
1. On a NEW save, does NEXT always show something close? Does the tutorial go Planet → Gas Giant → Rock?
2. Is the 2:30 gift on the GIFT chip?
3. Do the jump height and fall feel right? If not, tune `GravityCut` (lower = floatier).
4. Run along a bridge and the island edge: do the rails hold you? Can you still walk onto every bridge?
5. Jump off the island: fade, whoosh, back on your island?
6. Decide whether to lower run-1 comet value.
