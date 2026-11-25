---
date: 2026-11-25
tags: [gymarc, christmas, advent-calendar, build-brief, claude-code]
---
# GYM ARC CHRISTMAS UPDATE: build brief for Claude Code (launch Sat 5 Dec)

**How to use:** tell Claude Code on the Studio PC: *"Read `GYM ARC/2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec).md` and build Phase 1. Don't publish."* Then one phase per chat.

## Read first (in this order)
1. `Brain/00 BRAIN.md` → `GYM ARC/CLAUDE.md` (the map placement rules) → `Roblox Playbook/Roblox Playbook - Rules for every game.md`
2. Decisions:
   - [[2026-11-12 GYM ARC - Christmas update decision (Advent calendar, 5 Dec)]]
   - [[2026-11-12 GYM ARC - Christmas calendar style decisions (owner OK)]]
3. Research:
   - [[2026-11-12 Research - Modern Roblox advent calendar and pass UI (videos watched)]] (the look and the reveal motion)
   - [[2026-11-12 Research - Tap Simulator REBORN secret reveal sound breakdown (measured)]] (the sound recipe)
4. Systems to REUSE, don't rebuild:
   - [[GYM ARC - Live Update Events]] (`Config/LiveEvents`, countdown, launch cutscene, `LiveEvents.Unlocked()`)
   - [[GYM ARC - Economy and Daily Rewards]] (DailyService)
   - [[GYM ARC - Body Alters]] (alter variants, `SkinStages.Alter_<id>`)
   - [[GYM ARC - UI System]] (the kit)
   - ComeBackClient (23 Nov)
5. Why it matters (25 Nov):
   - [[2026-11-25 GYM ARC - Ad creatives study (5 percent CTR, audience)]]
   - [[2026-11-24 GYM ARC - Slow revive plan to 50 CCU before Christmas]]
   - Home first-play bounce over 56 days: **15.2% < 60 s, 22.6% at 61-180 s.** The Christmas version must make minutes 1-3 stronger.

## Owner rules that apply (do not break)
- **UI:**
  - the GYM ARC kit (black + gold, kit fonts) with Tap Simulator REBORN energy;
  - **no sunburst / ring of rays anywhere**;
  - no placeholder-looking UI;
  - account for the mobile joystick + jump button zones.
- **Windows:** never open by themselves while the player is training. Reveals play OFF the machine.
- **Lighting:** never dark (the winter gym is bright and cosy, not night-blue gloom).
- **Models:**
  - HIGH quality but LOW triangles;
  - built with the `roblox-3d-model-from-sheet` skill;
  - map changes follow `GYM ARC/CLAUDE.md` (layout table → place by code → MapAudit → player-eye screenshots).
- **Sounds:** synthesized in code from the measured recipe (no Fish Audio / ElevenLabs).
- **Art** (present renders, tile backgrounds, the event icon): ChatGPT via the `roblox-chatgpt-art-pipeline` skill, one-try prompts, then cleaned. Character art: the approved icon G look (Bacon Hair, the classic "Man" face, glossy golden-orange skin).
- **Code:**
  - no mid-line comments (they caused two bugs on 18 Nov);
  - run `ThumbnailRigBuilder.RestoreTemplates()` before any save if BodyStages was required in Edit;
  - check `game.PlaceId` before editing.
- **Never publish.** The owner publishes.

## Scope (in priority order; if time runs short, cut from the bottom)
| # | Part | Must have by |
|---|---|---|
| 1 | **Advent calendar** (24 days, opened from a Christmas tree in the gym) + claim reveal + sound | 30 Nov |
| 2 | **Candy Canes** event currency (earned from training) + the day-one free present for new players (first-3-minutes hook) | 30 Nov |
| 2b | **First-5-minutes fixes from the 4 kid sims** (Benny auto-open, GROW on READY, 8 s intro, calm HUD before Growth Spurt 2, one queue per screen strip, the 5 cheap-looking spots). Small, and the biggest bounce fix: do it with Phase 2 | 30 Nov |
| 3 | **Winter gym** (snow outside, garlands, a big tree, warm lights) + the LiveEvents launch (countdown, cutscene, reward) | 2 Dec |
| 4 | **Christmas Alters** (3 limited skins bought with Candy Canes, worn from Inventory > Alters) | 3 Dec |
| 5 | **Gift drops** in servers (a present falls every ~10 min; the first player to tap it gets Candy Canes, everyone nearby gets a small share) | 3 Dec |
| 6 | **Holiday pass** (one limited pass, ≤449 R$: x2 Candy Canes + a gold Santa-hat title) | 3 Dec |
| 7 | Test day: full checklist below, phone + PC, fixes | 4 Dec |
| - | Owner publishes early with everything hidden; launch **Sat 5 Dec 15:00 UTC** (9:30 PM Myanmar) via LiveEvents | 4-5 Dec |

## Phase 1: Advent calendar (the most important piece)
**Data and rules**
- `Config/Advent`: 24 days, each with a reward, a rarity (Common / Rare / Epic / Legendary), and `big = true` on days 7, 14, 21, 24.
- Dates (owner decision):
  - opens with the update on Sat 5 Dec, **days 1-5 claimable at once** (catch-up burst);
  - then one new day per UTC day, so **day 24 = 24 Dec**;
  - ends 6 Jan.
- Missed days are shown **frozen in ice** with a **Restore** button (Robux developer product, ~25 R$). Restore only works for days already past.
- Server pays everything. Save the claimed days set first (no double pay across servers or rejoins).
- **Reward ideas** (tune with the economy; minutes of coins at the player's stage, like `Economy.Rewards`):
  - coins
  - Candy Canes
  - serums (BEAST FORMULA / MONSTER MIX / TITAN SERUM)
  - DNA tokens
  - 1.5x EXP boosts
  - day 7: a Christmas title
  - day 14: Christmas Alter #1 (free)
  - day 21: a gold Santa hat cosmetic
  - **day 24: the Legendary "Frostbite Titan" Christmas Alter**, free only through the calendar. This is the reason to come back 24 days.

**Opening it**
- A big lit Christmas tree in each gym's lobby area (follow the map rules: facing the spawn path, 4×4 standing spot, ProximityPrompt 8-10).
- A calendar pill in the HUD right column with a red dot when a present is ready.
- Never auto-opens while training.

**Look** (Tap REBORN energy in the GYM ARC kit)
- A chunky outlined panel. Title "ADVENT CALENDAR" half outside the panel edge.
- A 6×4 grid of present tiles: 3D-rendered presents (ChatGPT art, 4 colour variants + gold for big days) that overflow their tiles.
- Day numbers in the heavy stroked kit font.
- Big-day tiles are holographic (a rainbow sheen sweeping across).
- Today's tile pulses gently. Claimed tiles show the opened box + the reward icon. Future tiles are dim with a lock. Missed tiles are under ice.
- A countdown line: "Next present in 6h 12m".

**Claim reveal** (plays off the machine)
- **Normal days, ~2.5 s, something new every ~0.3 s:**
  1. the present shakes, with light in the rarity colour leaking from its seams;
  2. a white flash;
  3. a burst of ribbon, snow and shards plus speed streaks (NO sunburst);
  4. the reward pops with a scale bounce;
  5. its name slams in;
  6. coins / canes fly to the HUD.
- **Big days (7, 14, 21, 24):** the full cutscene, a short camera shot of the tree in the gym → heartbeat → vacuum → drop → full-spectrum reveal → title slam.
- **Sound** (synthesized, from the measured research):
  - normal days: a sub thump on tap → rising ratchet ticks while it shakes (~938→1266 Hz, 0.12 s apart) → reveal impact + sparkle → a small title hit → coin ticks;
  - big days: the full recipe, a 47 Hz heartbeat (a barbell-plate thud) + air shimmer → vacuum (cut the highs) → sub drop → accelerating heartbeat (0.5 → 0.2 s) → full-spectrum reveal → title slam 1.8 s later;
  - a clean 20 ms UI click on every button.
- Reduced Motion setting: fades instead of punches.

## Phase 2: Candy Canes + the first-3-minutes hook
- **Candy Canes** (event currency, its own HUD pill during the event):
  - +1 per N reps (tune so ~40-60 an hour of normal play);
  - more from gift drops, the calendar, quests;
  - x2 with the holiday pass;
  - x1.5 in Rush Hour.
- **First 3 minutes for a NEW player during the event** (this is the bounce fix):
  - **0-30 s:** right after spawning, a present glows under the tree with "FREE GIFT!" and an arrow. Walking to it = the first claim (day 1, no tutorial block). Coins + 25 Candy Canes with the full short reveal. The tutorial continues after.
  - **Within the 1st minute:** the first visible muscle growth (already in Chapter 1: check it still lands before 60 s).
  - **Minutes 1-3:** show something to chase. A small "CHRISTMAS ALTERS: 0 / 150 🍬" goal chip appears once, with the first alter's picture.
  - **After the first Growth Spurt:** ComeBackClient shows TOMORROW's present ("Day 2: a mystery present!").
  - Analytics funnel steps: `Xmas_FreeGift_Claimed`, `Xmas_First60s_Growth`, `Xmas_GoalChip_Seen`.

## Phase 2b: first-5-minutes fixes (from the 4 kid sims on live v1914, 25 Nov)
Source: [[2026-11-25 GYM ARC - Kid sims on live v1914 (debate, impatient, overstimulated, quality nerd)]]. Each fix is a config value or a small change; grep for the names, don't rebuild systems.
1. **Benny never stalls** (the biggest bounce cause: kids stood 40-120 s at his table with nothing open). When the BeatBenny tutorial step walks the player to his table, open Benny's card by itself after the walk (`BennyAutoOpenDelay = 0.6` s), swing the camera to his face (`BennyCamFocus = true`), keep the band line ON (no 3-of-12 s blink) and cut the card text to ≤ 15 words. Keep the E prompt as a backup.
2. **GROW right when READY:** when the Growth Spurt bar is full, start the transform after `GrowReadyGap = 1.5` s (was ~6 s of waiting on the READY card).
3. **Intro cutscene 18 s → 5 s** (26 Nov: see Phase 2d item 9; one shot, skippable after 1 s).
4. **Calm HUD before Growth Spurt 2:** no DEAL / FREE 1,000 / PLUS +20% / INVITE +10% tiles and no red "!" / NEW badges until the player has done Growth Spurt 2 (`CalmHudUntilSpurt = 2`). The INVITE card only after Growth Spurt 2 and never while on a machine.
5. **One queue per screen strip:** the top strip (tutorial band, notifications, NEW PERSONAL RECORD) shows one line at a time; the next waits; PERSONAL RECORD and notifications become a side toast during the tutorial. KEY tutorial lines stay at least `words / 1.5 + 0.5` s. While a centre card is open (Benny, GROW READY, a reward), hide the side cards and the top strip.
6. **Benny story shot 4 s with a 3-word caption** ("You? Beat ME?"; 26 Nov, replaces 7.5 s / 5 words: 3 words fit the slowest readers in 4 s).
6b. **Every tutorial line leads with a big icon + a 3D arrow / glow on the target** (dumbbell icon + arrow to the bench, leg icon + arrow to the leg machine, Benny's face + arrow to his table). Words become optional: half the players are non-English and the slowest 7-year-olds read ~1 word/s. Re-run (26 Nov): KEY messages missed by 7-year-olds 28% → 0%.
7. **The FREE GIFT (Phase 2) goes through the same queue:** it glows AFTER the intro and the first tutorial line, never on top of them.
8. **Cheap-looking spots (quality-nerd kid):**
   - trainer NPCs (e.g. LOU 03) never between the camera and the player: fade them (LocalTransparencyModifier) when they block the view;
   - the plain black box in the middle of the Hall of Fame plaza → a real centrepiece (gold trophy on a plinth), built with the roblox-3d-model-from-sheet skill, low tris;
   - blank black screens/boards at the Hall of Fame and ProGym → live leaderboards or poster art;
   - flat card palm leaves at the beach → real leaf meshes (low tris);
   - the floating red/black plate sign → put it on a post;
   - 3 plate/rack variants (colour + wear) so the same prop doesn't repeat in one view.
- **Tests (add to the checklist):** every tutorial line has an icon + arrow; a NEW player reaches Benny's card with no key press; GROW starts ≤ 2 s after READY; no DEAL/INVITE/badge before Growth Spurt 2; never two lines on the top strip at once; phone screenshots of the plaza, beach, ProGym show none of the 5 spots.
- Expected (model): stay past 3 min ~54% → ~96%; overload 370 s → 0 s per 10 min; cheap tells 8.7 → 0.4 per 10 min.

## Phase 2d: the tutorial plays itself → YOUR taps (owner 26 Nov: "the tutorial is boring", "the intro cutscene and cutscenes too")
Source: [[2026-11-26 GYM ARC - Tutorial and cutscene redesign (your taps, short scenes)]]. Keep every autoGo (walking was dead time) and every saved step number. Only the taps and the scenes change. Grep for the names; don't rebuild the tutorial.
1. `TutorialAutoReps = false`, `TutorialAutoPump = false`: in MachineClient's tutorial loop (the `UIBus.TutorialRunning()` branch) stop the automatic taps/reps. The PUMP bar fills from the player's own reps (`TutorialPumpPerRep = 0.25`) and pumps itself when full (still no manual pump lesson: owner, 3 Nov).
2. `TapHintDelay = 3`: no tap for 3 s on a tutorial machine → the REP button pulses + an animated hand taps it (once per step; not under the joystick / jump button).
3. Tutorial rep juice: every 2nd rep the trained muscle's pump flash, "+EXP" pops rising from the muscle, combo "x5!" / "x10!", the clank pitch +2% per rep in a set.
4. **PICK YOUR NEXT MUSCLE** after StopBench: the Squat Rack, Crunch Bench and Pull-Up Bar glow with big icons (leg / abs / back) + three big buttons. The pick = that step's autoGo. The other two glow until done, any order (`ChoiceGroup = { "GoSquat", "GoCrunch", "GoPullUp" }`; step IDs stay, the client picks which one runs next).
5. `AutoGoDash = true`, `AutoGoSeconds = 2`: the autoGo move is a 2 s dash with speed lines + a whoosh (was 3-4.5 s).
6. GROW is the player's tap: the READY card's GROW button pulses (no auto press); `GrowTransformSeconds = 4`; it ends on the player flexing + the next tease.
7. Story shots: Benny 4 s (3-word caption), Coral 4 s (≤ 3 words). `CutsceneSkipAfter = 1` for EVERY cutscene, the first view included (tap anywhere; skipping still gives everything). NPC faces in frame (Phase 2b).
8. Benny match, no auto push: winnable at 2 taps/s; if the player taps < 1/s for 3 s, show "BENNY IS TIRED!" and weaken his push so every kid wins by tapping; the TAP button pulses with the hand after 2 s of no tap.
9. `IntroCutsceneLength = 5`: one shot (wide gym → push-in on YOU → Benny's 3-word taunt on screen → control). Skippable after 1 s.
10. `AutoTrainAfter = 5`: GO TRAIN (until Growth Spurt 1) presses itself only after 5 s with no press.
11. GO TRAIN stretch paid in steps: the Growth Spurt bar pays small coins at 50 / 75 / 90% with a pop, and each GO goes to a machine the player hasn't used yet when there is one.
12. **Benny comes to YOU** (replaces his story shot, the walk to his table and reading his card): at the end of the GROW transform Benny walks into the shot. A challenge card ("Big now? Prove it!" + ARM WRESTLE) waits for the tap → a 1.5 s dash to his table → the match starts at once.
13. Screen rules for all of this (overstimulated-kid check):
    - +EXP pops and the combo float over the trained muscle in 3D (BillboardGui on the muscle), not in the HUD;
    - no NEW PERSONAL RECORD banner while the tutorial runs (the combo pop is the cheer);
    - the tap hand waits until the coach line has gone;
    - the coach's welcome = 6 words ("Welcome! Lift to GROW TALLER!"), shown during the dash to the bench, never on a machine;
    - no machine HUD under the PICK screen.
- Tests: a new player who doesn't touch the screen gets the hand within 3 s and the tutorial does NOT move on by itself; tapping REP fills the pump; the muscle pick works in any order and saves; every cutscene skips after 1 s and still pays; Benny can be beaten at 2 taps/s, and at 0.8 taps/s after "BENNY IS TIRED!"; intro ≤ 5 s; phone screenshots of the hand and the pick screen.
- Expected (model): stay past 3 min ~49% (live) → ~89% with Phase 2b → **over 90% even for very impatient kids** with 2b + 2d (96% at 5 s patience, ~100% at 11 s; a ceiling, lag and bugs aren't modelled). Overload 0 s, KEY messages missed 0%. If Experiments are set up, A/B auto vs taps on the funnel.

## Phase 2e: minutes 3-10 (owner 26 Nov: "now we need them to play for 10 minutes")
Source: [[2026-11-26 GYM ARC - The 10-minute plan (minutes 3-10)]]. Only for a player's FIRST session (until they leave, or 15 min) unless it says otherwise. Grep for the names; small changes.
1. Beach grind 70 → 40 reps: Config/Onboarding BeachChest / BeachCore / BeachLegs / BeachBack `count = 10` each (step IDs and numbers stay).
2. No QUESTS TOUR in the first session (the Tour that opens DailyQuests after Growth Spurt 2). Instead one toast: "DAY 1 STREAK: +750 · CLAIM" (one tap). CLAIM must never be blocked by a tour. The tour's SKIP button hides with the tour.
3. No paid offers before Growth Spurt 3: StarterSticky, the stamina REFILL / ENDLESS offer, DEAL tag (extends Phase 2b's calm HUD). `CalmOffersUntilSpurt = 3`.
4. GO TRAIN for the whole first session: when the muscle you're on is FULL for the current spurt, show "FULL! Next: CHEST" and take the player there after 3 s unless they tap STAY (`FirstSessionAutoNext = 3`). The "Heavier weight open! Tap +" guide line only while on a machine.
5. No stamina wall in the first session: stamina refills while walking / dashing; the first time it hits 0, a free Energy Shake drops into the hotbar with the tap hand (`FirstSessionStaminaRefill = true`).
6. Playtime gifts: count from join (tutorial included), every 2 min (2, 4, 6, 8, **10 = a free trainer roll**), then every 5 min; a small countdown chip under the coins ("GIFT in 0:45"), not under the joystick / jump button (`PlaytimeGiftTimes = { 120, 240, 360, 480, 600, 900, 1200, ... }`, `BigGiftAt = 600`).
7. A new player's sky stays day for their first 15 min (DayNightClient: hold ClockTime at the day value while `SessionSeconds < 900` and it's their first session), or lift `NightOutdoorAmbient` so night is never dark (owner rule 13 Nov).
- Bugs to fix with it: CLAIM blocked during the tour; SKIP left on screen; the "Heavier weight" line off-machine; the GS1 READY card flashing again for ~1 s after GROW.
- Tests: a fresh player (FreshPlayer) reaches GS2 by ~4:00, no tour, the claim toast works; on a full muscle, "FULL! Next" moves them in 3 s; no R$ popup before GS3; gifts at 2/4/6/8/10 min with the chip; the sky is day at 10 min on a server started at 15:00 game time.
- Expected (model, calibrated to live): of the players past 3 min, ~56% (live) → **~100% stay past 10 min** (92% for very impatient kids); mean session ~18 → ~27 min. Ceiling, not a promise. Add funnel steps "GS2", "GS3", "10 min in session".

## Phase 2f: long sessions, minutes 10-60 (owner 26 Nov: "very long average session even with the very impatient kids")
Source: [[2026-11-26 GYM ARC - Long sessions even for impatient kids (minutes 10-60)]]. Grep for the names; small changes on top of what's there.
1. Growth Spurt steps: at 25 / 50 / 75% of every Growth Spurt bar, a visible body step (MuscleRig look) + a coin pop + a short sting (`SpurtStepShares = { 0.25, 0.5, 0.75 }`).
2. THE RUNWAY for new players (first 3 sessions): 30 s before a show, a big JOIN card in the centre queue; one tap = dash to the stage (`RunwayJoinCardSessions = 3`). Their first 2 shows: NPC fill models pose weaker so the newcomer reaches the podium.
3. Trainer rolls from anywhere: when coins ≥ `Trainers.RollCost` (150), a "ROLL READY" chip (top-left, clear of the joystick); tap = the roll card on the spot. In the first session it pulses at most every 4 min (`RollChipEvery = 240`).
4. Playtime gifts every 5 min to 60 min after the Phase 2e ones: Config/Playtime `Gifts` at 15, 20, 25, 30, 35, 40, 45, 50, 55, 60 min, trainer rolls at 20 / 40 / 60.
5. Server event every 15 min: "PROTEIN DROP: x2 gains for 3 min" for the whole server, a countdown on the chip (`ProteinDropEvery = 900`, `ProteinDropSeconds = 180`). Reuse the GIFT RUSH system (Phase 2c) so one system runs both.
6. AFK gift chair from Phase 2c stays (coins + Candy Canes, no reps).
- Tests: the 25/50/75% steps fire once each per spurt; the RUNWAY card queues behind other cards and never covers a KEY message; the ROLL READY chip opens the roll card off-Agency and respects the 4-min limit; gifts at the new minutes; a Protein Drop fires every 15 min in a test server (dev hook to fast-forward) and stacks correctly with other boosts.
- Expected (model): mean session for very impatient kids ~7 → ~37 min (patience 7 s: ~10 → ~46). Relative, not a forecast (the model caps at 60 and has no lag/bugs/real life). Add funnel steps "20 min", "first roll", "first show".

## Phase 2c: crowd levers (so the game tile shows 1,000+ players; from the CCU growth model, 26 Nov)
Source: same sims note, section 5. Kids veto a game under ~1,100 players ("nobody plays it, it's dead"). These raise how many players come back and stay. Build the cheap ones with Phase 2-5.
1. **Friend invite = a bonus Advent present for BOTH** (Roblox invite prompt from the calendar; the friend gets it on first join).
2. **GIFT RUSH 3 times a day at fixed times** (e.g. 15:00, 19:00, 23:00 UTC): gift drops every minute for 10 min. A countdown on the tree.
3. **Roblox experience notifications (opt-in, after the first calendar claim):** "Today's present is ready", "Gift Rush in 10 min".
4. **AFK gift spot** (a cosy chair by the tree): sitting idle pays a small coin trickle + 5 Candy Canes every 20 min. No reps, so the AUTO REP pass (best seller) keeps its value.
5. **7-day login streak** (in the calendar UI) + one code per week in the Discord and the group.
6. After Christmas (January): the ranked arm-wrestle weekly board.
- Tests: invite reward lands for both; Gift Rush fires at the 3 times in a test server (dev hook to fast-forward); notifications only after opt-in; AFK spot pays 5 🍬 / 20 min and never reps.

## Phase 3: Winter gym + launch
- **Winter look** (gated by `LiveEvents.Unlocked("Christmas")`, removable after 6 Jan):
  - snow on roofs, ledges and the street outside;
  - garlands with warm bulbs on the racks;
  - a big tree per gym;
  - a few presents by the walls;
  - frosted window edges.
- Lighting stays bright and warm (check with the gym lighting config; never darker than now).
- Snowfall particles only outside or near windows (phone FPS: test on the A06 phone profile).
- **LiveEvents entry "Christmas":** 24 h countdown card, the launch cutscene (camera to the big tree, lights switch on, snow starts, fireworks, "CHRISTMAS UPDATE"), the launch reward (Launch Day 2 title + 30 min 1.5x), NEWS entry, the "NEW: CHRISTMAS" popup for 7 days.
- Creator Hub configs:
  - `Launch_Christmas_Time` = `2026-12-05 15:00`;
  - `Launch_Christmas_Enabled`;
  - `Xmas_Enabled` (kill switch).

## Phase 4: Christmas Alters (3)
- Reuse the alter **variant** system (a variant's skin = `SkinStages.Alter_<id>` with a new colour map; worn from Inventory > Alters; cosmetic only, no gains bonus change).
- **The three** (ChatGPT skin textures through the art pipeline, like the ELEMENTS alters):
  1. **Candy Cane:** red and white stripes, glossy.
  2. **Gingerbread:** warm brown with white icing lines.
  3. **Frostbite Titan** (calendar day 24 only, Legendary): icy white-blue with frost cracks + a soft cold glow.
- Candy Cane and Gingerbread are sold for Candy Canes (e.g. 150 / 400) at a "Christmas Shop" stall next to the tree.
- Limited: can't be bought after 6 Jan; owners keep them forever.

## Phase 5: Gift drops
- Every ~10 min per server, a present parachutes to a random open spot in the current gym (on the ground, not inside anything; reuse the loose-plate spawn spots).
- Big glow + a jingle.
- The first tap gets 30 Candy Canes; everyone within 40 studs gets 10 (co-play signal: being near friends pays).
- Despawns after 60 s.

## Phase 6: Holiday pass
- One game pass, ≤449 R$: x2 Candy Canes + a gold "Santa's Strongest" title + gold present tiles.
- Sold from the Christmas Shop and the calendar window footer (never a popup while training).

## Test checklist (Phase 7: every line PASS before the owner publishes)
**Calendar**
- [ ] New player, phone size: free gift claimed within 30 s; first growth before 60 s; goal chip seen before 3 min; 0 errors.
- [ ] Calendar: days 1-5 claimable on 5 Dec; day 6 locked until 6 Dec 00:00 UTC (test by faking the date in Studio).
- [ ] Each day pays once across rejoin + a second server.
- [ ] Missed day shows ice; Restore works only for past days.
- [ ] Big-day cutscene plays off the machine; a normal claim ≤ 3 s.
- [ ] All sounds play; none clip.

**Economy and alters**
- [ ] Candy Canes: earn rate in range (~40-60/h); pass doubles them; saved.
- [ ] Christmas Alters: buy, wear, unwear, rejoin; other players see the skin.
- [ ] Gift drop: lands on the ground, the first tap pays, nearby players get their share, despawns.

**Minutes 10-60 (Phase 2f)**
- [ ] Spurt steps at 25/50/75%; RUNWAY join card for new players; ROLL READY chip works off-Agency; gifts every 5 min to 60; Protein Drop every 15 min.

**First 10 minutes (Phase 2e)**
- [ ] GS2 by ~4:00; no quests tour, one-tap claim; FULL! Next works; no R$ popup before GS3; gifts every 2 min + chip; day sky at 10 min.

**First 5 minutes (Phase 2b + 2d)**
- [ ] No auto reps/pump in the tutorial; hand after 3 s; muscle pick any order; every cutscene skips after 1 s; Benny walks into the GROW shot and is won by tapping; intro ≤ 5 s; no RECORD banner in the tutorial; pops float over the muscle.
- [ ] New player: Benny's card opens by itself at his table (no E press); camera shows his face.
- [ ] GROW starts ≤ 2 s after READY; intro ≤ 8 s.
- [ ] No DEAL / INVITE / red badge before Growth Spurt 2; never two lines on the top strip at once.
- [ ] No trainer between camera and player; plaza, screens, palms, sign fixed (phone screenshots).

**Launch**
- [ ] LiveEvents: countdown, launch cutscene with 2 players, launch reward once, NEWS entry, the NEW popup.
- [ ] Kill switch `Xmas_Enabled` = false hides everything.

**Map, phone and performance**
- [ ] MapAudit clean; player-eye screenshots from every spawn.
- [ ] Phone FPS on the A06 profile not worse than v1914 (± 5%).
- [ ] Memory not higher than v1914 by more than 50 MB.
- [ ] Mobile: no button under the joystick / jump zones; text ≥ 14 px.

## Ads tie-in (owner)
- Ad creative #6 "CHRISTMAS UPDATE" goes live the moment the update launches (it's in `Assets\ads_creatives_25nov\`).
- The $200 burst: [[2026-11-25 GYM ARC - Ad creatives, the 10 for the test]]. **Changed 26 Nov (growth model): run it 19-23 Dec** (school holidays, when Roblox has the most kids and our Gift Rush/calendar are running) instead of 5-7 Dec: tile CCU over 20-31 Dec median ~1,060 → ~1,230 for the same money. Launch day can use a small $20-30 test of the 10 creatives to find the 5%-CTR ones.
- Owner's choice (money): putting half of the game's earnings back into ads from 19 Dec is what lifts the chance of 1,830+ players from ~20% to ~60% (~90% if the creatives hold 5% CTR) in the model.
- Update the game title for the event: `[🎄CHRISTMAS] GYM ARC` and the description's first line.

## Report after each phase
A Progress note in `GYM ARC/Progress/` with:
- what changed and where;
- screenshots (phone + PC);
- the test lines passed;
- anything not done.
