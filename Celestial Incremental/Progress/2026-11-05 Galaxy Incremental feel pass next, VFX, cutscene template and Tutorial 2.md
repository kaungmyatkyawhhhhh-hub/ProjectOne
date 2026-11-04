---
date: 2026-11-05
tags: [galaxy, progress, phase-1, feel, vfx, cutscene, tutorial]
status: built and bot-tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - feel pass NEXT, VFX layering, cutscene template, Tutorial 2 (5 Nov, Claude Code)

From the owner's "FEEL PASS – NEXT" (items 1-5), then Phase 1 in order: small-reward feedback + VFX layering ([[2026-11-05 Galaxy Incremental - Prompt - VFX layering pass]]) → cutscene template ([[2026-11-05 Galaxy Incremental - Prompt - Cutscene template (Sols RNG style)]]) → Tutorial 2 ([[2026-11-04 Galaxy Incremental - Prompt - Tutorial 2 (Regrowth style) + first 10 min]]).
Place "Galaxy Incremental" (111654682859982). GYM ARC was not touched. Social basics are next.
Checklist rows: **#77 #78 #79** (economy), **#110-#124 #128 #130** (tutorial), **#222 #223** (UI), **#239 #242** (SFX), **#266 #274 #275 #278 #279 #283-#287 #289 #294 #295 #298 #301 #303** (VFX). Statuses updated in [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]].

## The 5 items
1. **Supernova 1 ~5 min, runs never under ~1.5 min.** 
   - Needs now: **250K**, 1.8M, 12M, 48M, 240M, 400M, 460M, 1.4B, 1.7B, 1.9B, 2.6B, 16B.
   - Supernova 1 (bot, real minutes): **3.7 / 3.8 / 4.3** in 3 runs. That's under 5, and 220K would be faster still.
     - The bot buys the instant it can. A player who reads LUMI's card and walks to the boards is slower, so ~5 is likely.
     - Your playtest decides. Raising it further makes run 2 too short, because the pads carry over.
   - Runs after it: see the bot table below. One 1.2 min run (right after Heavy Elements) and one 1.5 → needs 5, 8 and 9 raised. **That last nudge is not bot-tested.**
2. **Ring 2 re-priced.**
   - Starfire 5 / 15 / 45 / **600 / 1,200** shards; Star Tier 3; Heavy Elements 120; Binary Star 600; capstone 1,000.
   - Bot check at Ignition 1: Starfire 3/5, Star Tier 1/1, Heavy Elements 1/1, **Binary Star 0/1, capstone not bought**: 3 of 8 levels + the capstone unbought (~38%), 435 shards in hand. ✔
3. **Phones: tap a board = its 2D window.**
   - TREE and INFO open T, BODIES opens U on BODIES, PERKS opens U on PERKS. The boards still look 3D.
   - Tested with the phone frame (`TestPhone`).
4. **Ignition camera.**
   - Frame-by-frame renders of the flight path: `Progress\screens\2026-11-05-ignition-camera\` 1-6.
   - Camera.Focus is set every frame, and the camera comes back to you after (frame 8 = the PATH card).
   - Live screenshots hang while a scripted camera runs, so frames 1-6 are renders along the same path.
5. **Perks, paths, Forge cores** → [[2026-11-05 Galaxy Incremental - Perks, paths and Forge cores (numbers for review)]]. The note says an Offline core gets added (the XP core stays) when offline earnings is built.

## Small-reward feedback + VFX layering
- **NEXT line** under the counter: "NEXT: ROCK ASTEROID · 4.44K" (#223).
- **"NEW: <TIER>!"** on every new body tier: now the cutscene's 1.2 s mini version (#222).
- **Income tick** every ~1 s, pitch climbing with income, and a tiny pop on the counter (#239 #283).
- **Two-note buy** sound (#242).
- **Tree node bought:** the tile flashes, a gold line draws to it, 10 sparkles (#284).
- **New body:** a streak flies in + a ring flash, bigger tier = bigger (#285).
- **x2 tier-up:** the body pulses, a gold ring, an "x2" pop (#286).
- **Comet caught:** 16 sparks fly to your star (#287). Run 1: a GOLDEN comet now and then (x5, gold head + trail) (#79).
- **Supernova layers:** sharp shards (fast) + embers and haze (slow) + rings + shake, coloured by your rank; the nebula blooms in slowly (#279 #294 #295 #298).
- Textures: placeholders I made (`UI\make_fx_set.py`). Final art from your artist, list below.

## Cutscene template (GalaxyCutscene, new ModuleScript)
- One client module for every big moment. Screen layers in the moment's ONE colour: nebula glows, the big symbol, 3 rings, glints, speed lines, constellation lines, words, title.
- **Beats:**
  1. world dims + music out
  2. build
  3. 0.3 s black breath
  4. the CLIMAX on the drop (white flash + starburst rays + boom + FOV punch, same frame)
  5. tail
- **Audio:** the riser is started so its END lands on the drop.
- **Rules:**
  - The reward is given at the climax.
  - SKIP after 1 s.
  - Reduced Motion = no flash / shake / punch.
  - One flash per cutscene.
  - Camera.Focus every frame; camera, exposure and music restored.
- **Wired:**

  | Moment | Length | Notes |
  |---|---|---|
  | First Supernova | 10 s | windup 7.6 + hold 0.4 + fade 2.0; your rank colour; the old world effects stay under it |
  | Ignition | 8 s | constellation lines, "SECTOR 1 · EMBER BELT", the camera arc to Sector 2 |
  | Forge rolls | by rarity | Rare 3 s · Epic 5 · Legendary 8 · Mythic 12 · Celestial 18 |
  | NEW tier | 1.2 s mini | - |

- A **CELESTIAL** roll tells the whole server: "<name> forged a CELESTIAL core!" (#301 partly).
- Art + sounds needed: [[2026-11-05 Galaxy Incremental - Cutscene template art list (for the artist)]].
- **Tested in Studio** (Legendary roll, 6x slow; frames in `Progress\screens\2026-11-05-tutorial2-cutscene\` 06-13): opener → veil → rings + symbol → speed lines → the symbol grows ("SPEAKS") → the black breath → CLIMAX (rays + "LEGENDARY!" + "STARDUST CORE") → HUD back.
- **Fixed in the test:**
  - The HUD and the Forge window showed through, so a full cutscene now hides every other screen UI and uses a darker backdrop (screen 05 = before).
  - A "NEW tier" mini at the same moment as Ignition blocked the Ignition cutscene, so now a full cutscene waits for the mini.
- **Not checked live:**
  - The Ignition and first-Supernova versions move the world camera, and Studio screenshots hang during those.
  - Ignition frames: `2026-11-05-ignition-camera`.
  - Please record both with Win+Alt+R.

## Tutorial 2
- **20 GOAL steps with a live counter, to IGNITION 1 (~27 min):**
  1. Upgrade the Asteroid 3
  2. First Light
  3. 1st pad
  4. Moon
  5. +BODY
  6. 2 comets
  7. Asteroid to ROCK
  8. Planet
  9. 4 pads
  10. LVL 3
  11. Gas Giant
  12. 100% SUPERNOVA
  13. **SUPERNOVA (+3)**
  14. Starfire
  15. the Star
  16. Supernova again
  17. 10 pads
  18. LVL 10
  19. 6 Supernovas
  20. **IGNITION (+3)**
- **LUMI's card,** bottom centre:
  - LUMI is a star spirit, made in Blender in our icon style (`UI\star_spirit_blender.py`, `UI\roblox\star_spirit.png`).
  - "STEP 4/20", the goal, a segmented bar + "3/5", +Essence + BONUS.
  - HIDE shrinks it to the goal line. SKIP is red and needs 2 taps.
  - The card hides while a window is open; the arrow + ring guide inside the window.
- **Every step pays** +Essence and ~20 s of income in stardust.
  - Steps done together pay once.
  - The stardust is spending money only. It doesn't count toward the Supernova, so the curve stays tuned.
- **Beam:** 6 bigger gold chevrons creeping toward the target. The pad steps point at the next pad.
- **Run 1 only:** a comet every ~20 s (#78), 1 in 10 GOLDEN x5 (#79).
- **No comets during steps 1-5.** Step 6's tutorial comets come every 15 s until you catch 2.
- **Funnel:** all 20 steps are logged (onboarding funnel); a SKIP is logged too.
- **Old saves:** finished the old 7 steps = done; otherwise Tutorial 2 starts and skips past what you already have.
- **Store** shows after step 14 (was step 7).
- - **Screens:**
  - 00 LUMI
  - 01 beam
  - 02 the card (PC)
  - 03 the counter 8/10
  - 14 the phone frame: the card sits above the hotbar, x0.8. It covered the hotbar first, now fixed.
  - 15 the NEW mini

## Bot test (fresh save, no pass)
- **Setup:**
  - fresh save, no x2 pass
  - the same best-payback bot as before (catches every tutorial comet, half of the others)
  - real time = bot x 1.4
- **Final run (needs before the last nudge):**

| | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Supernova at (min) | 3.7 | 5.8 | 8.2 | 10.7 | 12.2 | 15.1 | 17.3 | 18.5 | 20.4 | 22.5 | 25.1 |
| Run (min) | 3.7 | 2.1 | 2.5 | 2.5 | **1.5** | 2.9 | 2.3 | **1.2** | 1.9 | 2.1 | 2.7 |

- **Ignition 1 checklist:**
  - a body at IRON: 15.0 min
  - all 20 pads: 22.3
  - Supernova 11: 25.1
  - **LVL 19 + IGNITION: 27.4 min** ✔ (target ~27.5)
- **Tutorial:**
  - Steps done at (min): 1: 0.6 · 3+5: 0.9 · 6: 1.3 · 11: 2.7 · 12-15: 3.7 · 16-17: 5.8 · 18: 8.0 · 19: 15.1 · **20: 27.4** ✔
  - Gaps over 90 s in the first 10 min: one, 5.8 → 8.0 (135 s), so step 17 is now "12 pads" (~7.2 min). Not re-run.
  - The bot does several steps at once; a player spaces them more.
- **Earlier runs, what they taught:**
  - Payouts first counted toward the Supernova and stacked: Supernova 1 at 3.1 min. Now they don't count, and pay once a batch.
  - Supernova 1 at 150K: 3.55 min, so it went to 250K.
  - Ring 2 at Ignition was only 25% unbought: Starfire 4/5 went 450/900 → 600/1,200.
  - Raised needs 8-9 pushed Ignition to 30.5, so 9-11 were eased.
- **Output:** no errors from the game scripts.
  - All 35 scripts: vault = Studio.
  - Test switches cleared: TestFreshSave, TestNoPass, TestPhone, TestIgnitionReady.

## For you
1. **File > Save** in Studio. Nothing was published.
2. LUMI: name and look are mine. Change both if you want.
3. Art list for your artist: [[2026-11-05 Galaxy Incremental - Cutscene template art list (for the artist)]].
4. Clips: please record the first Supernova, Ignition and a Legendary roll with Win+Alt+R ("would a kid post this?").
