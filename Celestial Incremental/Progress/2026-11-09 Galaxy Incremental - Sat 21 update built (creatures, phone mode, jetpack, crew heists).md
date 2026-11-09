---
date: 2026-11-09
tags: [galaxy, progress, update, creatures, heists, jetpack, phone, sat21]
status: built in Studio, all OFF (GameConfig.NextUpdate) until the 21 Nov publish. Tested in Studio Play, 1 player.
---
# Galaxy Incremental: the Sat 21 Nov update, built (9 Nov, Claude Code)

Prompt: [[2026-11-09 Galaxy Incremental - Kid focus group + Prompt - next update (creatures, crew heists, jetpack, phone)]]
Order built: A → G → C → B.

**Owner, 9 Nov (before building):** G.3 "phone HUD = stardust + NEXT + JETPACK + MENU" clashed with today's HUD decisions. Answer: **keep today's layout** (left buttons, bottom-left icons on phones, STARTER under SUPERNOVA), just add the JETPACK button. So G.3 / MENU is not built.

## How it's switched on
- **Off switches:** `GameConfig.NextUpdate = { Creatures, PhoneMode, Jetpack, Heists }`, all **false**. The Sat 14 publish can't ship any of it. **For 21 Nov: set the four to true**, then publish.
- `GameConfig.NextOn(name)` is what every script asks.
- **Studio test:** Workspace attribute `TestNextUpdate = true` (all) or `"Creatures,Jetpack"`.
- **Studio test switches:** set them from the SERVER side; client-set attributes don't reach the server.
  - `TestGiveEssence = n`;
  - `TestForgeForce = "Secret"/"Void"/"Golden"/"Rainbow"` (the next roll);
  - `TestForgeClean = true` (removes every mutation / SECRET core from the saves in the server);
  - `TestHeistComet = true / "other"` (a loose comet on an owned / empty island);
  - `TestHeistGrab = true`;
  - `TestCrewCore = n`;
  - `TestFreshSave = true` (a new save that never saves).
- **Careful:** Studio play saves to the real `GalaxySave1`. Test pulls went into the owner's save, then were removed with TestForgeClean and re-saved. Test with `TestFreshSave` from now on.

# A. STAR CREATURES (on the Star Forge)
**Creatures** (`GameConfig.Creatures`):
- The kinds: STARDUST = NOVA FOX, SHARDS = CRYSTAL CRAB, COMETS = COMET RAY, XP = SUN OWL, LUCK = LUCKY JELLY, GIANT = PLANET TURTLE; SECRET = NEBULA WHALE.
- **Size by rarity (studs):** Common 1.8 → Celestial 3.8, Secret 5.
- **Aura:** none (Common, Uncommon); glow (Rare); glow + 2 orbiting sparkles (Epic to Mythic); rainbow (Celestial, Secret).
- **Mutation look:** GOLDEN and VOID are tints; RAINBOW is a turning rainbow.

**Following (new client script `GalaxyCreatures`, LUMI's follow + bob):**
- Your equipped cores float round you while you're within HomeRange 80 of your island's centre; further away they float round the island.
- Others' creatures show within Range 60, never on LOW graphics.
- Tap yours: a toast with its name, rarity and effect.

**Art:** `Creatures.Kinds[k].art = 0` means not drawn yet; the kind's glossy icon stands in. **Quality-nerd tell:** until the art lands they're floating icons, not creatures (Mia: "not floating cubes"). The prompts are at the end.

**Mutations** (`EconConfig.Forge.Mutations`): GOLDEN 1/20 (x1.5), RAINBOW 1/200 (x3), VOID 1/2000 (x10).
- Every roll rolls one, rarest first.
- The power multiplies the core's BONUS: p → 1 + (p − 1) × power.
- Its own book entry, key `Kind:Rarity:Mutation` (levels like any core).
- Shown in the odds panel before rolling: "+ GOLDEN 5% · RAINBOW 0.5% · VOID 0.05%".
- **The BOOK's new MUTATIONS tab:** per kind, how many of the 7 rarities you have in each mutation, plus "VOID · n exist" and the SECRET row.

**SECRET** (`EconConfig.Forge.Secret`): the NEBULA WHALE, a STARDUST core, mult 30.
- Rolled before the ladder, no pity, never sold.
- **The maths:**
  - odds per roll = 1 / (HoursPerSecret × RollsPerHour) = 1 / (2,000 × 8) = **0.00625%** (shown as 0.006%);
  - **RollsPerHour = 8 is an estimate:** average Forge rolls per player-hour over ALL players, including the hours before Ignition 1 that have none. An active post-Ignition player rolls ~15-25 an hour.
  - Fix it from Creator Hub: ForgeRoll events ÷ total player-hours, then change `RollsPerHour`.

**Serials + announce:**
- SECRET and VOID creatures get a global #n: one DataStore counter per creature, UpdateAsync. Store `GalaxySerials1`; Studio uses `GalaxySerials_Studio`.
- **On a pull, everyone gets:** a chat line, a banner ("LUIGIRED PULLED GOLDEN NEBULA WHALE #1!") and a sky beam from the puller's island.
- "n exist" = Galaxy attributes `Exist_<kind>_<rarity>_<mut>`, read every 10 min.

**LUMI's gift:**
- A free first roll right after the tutorial (a skipped tutorial too). The Forge window opens on its reveal; it still unlocks at Ignition 1.
- Saves that had finished the tutorial before the update don't get it.

**Other A changes:**
- **Essence:** 1 per **10** comets (`ForgeFeed.CometsPerNext`, was 25).
- **KEEP:** creatures survive Supernova + Black Hole (the Forge is never reset). The Supernova card's KEEP line says "Essence + your CREATURES".
- **Reveal:** the creature's name + mutation, with its serial when it has one.
- **Under the hood:** every core key is read through `Econ.ParseCoreKey`.

**Tested (Play):**
- a forced VOID → "XP:Epic:Void" (+1500% XP);
- a forced SECRET → GOLDEN NEBULA WHALE #1, with the banner for the server;
- the gift roll on a fresh save: COMMON PLANET TURTLE reveal + the First Star Core badge;
- the creatures float round you; the odds panel and the MUTATIONS tab.

**Impatient kid sim** (`Calc/variants.py`, new G = F + the gift roll):

| version | stay 60 s | stay 5 min |
|---|---|---|
| F (live) | 100% | 94.7% |
| G | 100% | 94.9% |

The gift comes after the tutorial, so minute 1 doesn't change.

# G. PHONE MODE
**One switch:** `shared.GalaxyLowGfx`, from the new client script `GalaxyGraphics`.
- **Settings:** GRAPHICS AUTO / LOW / HIGH, saved on the server (`GfxMode`). The label shows "AUTO (HIGH)" / "AUTO (LOW)".
- **AUTO goes LOW when:** the saved quality is 1-3, or FPS < 40 for 10 s. Re-checked every 30 s; it flips at most once a minute.

**What LOW does** (`GameConfig.Graphics`):
- every ParticleEmitter's rate ×0.3 (tested: 350 → 105 → 350);
- VfxLibrary bursts at 30%;
- others' trails only within 40 studs;
- others' LUMI only within 40;
- others' creatures off;
- other islands' bought pieces hidden past 300 studs;
- GalaxyRankTags + GalaxySocial use the shared flag now.

**Not done:**
- G.3 phone HUD / MENU (owner's choice, above).
- **G.4:** the 30+ FPS check on a low-end Android with 8 players during a Crew Supernova (MicroProfiler, 8 test clients). My Studio tool runs 1 player: **owner**.

# C. JETPACK + BLACK HOLE PORTAL
**JETPACK** (new client script `GalaxyJetpack`; `GameConfig.Jetpack = { Fuel 3, RefillGrounded 1.5, Lift 60, CeilingAbovePlaza 120 }`; rise capped at 26 studs/s):
- **Controls:** PC: hold Space in the air. Phone: the JETPACK button.
- **Phone button placement:** just above the hotbar's right end. The right side is full (SUPERNOVA, STARTER, the jump button) and the hotbar reaches past the jump button's left.
- **Look:** a fuel ring of 12 lights; a stardust puff + whoosh while it pushes.
- **Rules:** off while carrying a heist comet; hidden while a window is open.
- **Tested:** 2.5 s of Space = **+67 studs**, a soft landing.

**BLACK HOLE PORTAL** (new server script `GalaxyPortalService`, `MapConfig.BlackHolePortal`):
- **The trip:** walk into the plaza gate's void → the server picks a random landing → your screen plays a 1.2 s spiral + fade + FOV punch, and the server moves you.
- **Rules:** cooldown 10 s. The Black Hole RESET stays on its prompt / window.
- **Detection:** checked every frame, including crossing the void's plane (Touched missed walk-ins; a running player crossed the zone between checks).
- **Tested:** walk in → landed on the plaza, 81 studs away.

**Layout table (map rules):**

| zone | object | position | ground y | facing | size | why here |
|---|---|---|---|---|---|---|
| plaza | PortalZone (invisible, CanCollide off, Floating + NotGround) | on the BlackHoleGate's Void (−36.8, 55.5, −36.8) | in the ring | the gate's | 4 × 15.9 × 15.9 | the void you walk into; the Void stopped being solid |
| plaza | landings ×8 | 30 from the centre at 22.5°, 67.5° … 337.5° | floor + 3 | the Core | – | open floor between the Core (r 13) and the boards (r 46+) |
| islands | landings ×8 | each island's Landing part | its top + 3 | the island centre | – | where the bridge arrives |
| leader's island | CrewCore orb (Floating) | island centre + 34 up | – | – | 8 | over the island, seen from the plaza |
| leader's island | CrewGather ring (NotGround) | on its Landing | landing top + 0.2 | flat | 18 across | flat ground everyone can reach |
| owned islands | loose comets | centre + 9-18 studs, on the ground by raycast | ground + 2.2 | – | 2.6 | on the island, clear of the centre's star |

**MapAudit** (server, `root = workspace.Galaxy`, with the portal): `26 objects, 3 interactables, CLEAN`.

# B. CREW HEISTS
**Numbers** (`EconConfig.Heist`):
- LooseEvery 60, OwnerGrabBonus 2, Value 120 s of the banker's income
- CarryLimit 45, CarrySpeed 0.7, PickupHold 0.5, TackleImmunity 1.5, StealShield 10
- NewPlayerSafe "until first Supernova", MaxCrew 4, TackleRange 3.5, BankRange 10, MaxLoose 4, LooseLife 180
- Core { Points 10, GatherSeconds 30, GatherRange 9 }
- Reward { BoostX 2, BoostMinutes 10, PermanentPer 0.02, PermanentCap 0.40 }
- Shock { Range 120, Up 70, Out 40 }; SurgeNovas 3

**Server** (new `GalaxyHeistService`):
- **Crews:** everyone starts in a crew of one; INVITE → an accept card → ACCEPT; LEAVE = alone again.
- **Loose comets:** the owner grabs at once (×2, no hold); anyone else holds 0.5 s and carries it home within 45 s.
- **Carrier:** Highlight glow, 70% speed, no jetpack.
- **Tackle:** touching a carrier who isn't your crewmate drops it; 1.5 s immunity for the tackler.
- **Banking:** at your own Landing → stardust (counts toward the Supernova like a comet) + 1 Core point.
- **Shields:** the robbed island is shielded for 10 s; a new player's island (no Supernova yet) is never robbed.
- **The Crew Core:** full = a glowing orb + a gather ring at the leader's landing; everyone in the ring within 30 s → the CREW SUPERNOVA:
  - a shockwave for everyone within 120: thrown up + a short flop; tamer with Reduced Motion;
  - each crewmate gets x2 for 10 min + a permanent +2% (saved, `crewNovas`, max +40%);
  - the Star Surge fills like 3 Supernovas.
- **Safety:** every remote is rate-limited (0.3 s); everything is checked on the server.
- **Analytics:** Heist_Grab, Heist_Tackle, Heist_Bank, Crew_Joined, CrewSupernova.

**Screen** (new `GalaxyHeist`):
- a **CREW** side button (purple, comet icon, badge "CORE 3/10" / "CORE READY!");
- the **CREW window**: your crew in its colour + LEADER, the CORE bar + what to do, the INVITE list;
- the invite card (ACCEPT / NO, 20 s);
- crewmates' name tags in the crew colour;
- "BRING IT HOME! 44s" while carrying;
- toasts for landings, steals, tackles and the core.

**Also:** CREW SUPERNOVAS shows in the BOOSTS list and in STATS (a 6th row, "CREW NOVAS n (+x%)").

**Tested (1 player):**
- owner grab: instant, +3.38K (240 s of income), core 1;
- steal path: carrying, walk 24 → 16, glow, banked +759 at my landing, core +1;
- core 10 → ring + orb → stood in it → Crew Novas 0 → 1, x2 for +598 s, core reset, ring gone, thrown up;
- the CREW window UIAudit CLEAN on SE.

**Not tested (needs 2+ players): owner** (Test > Clients and Servers, 2-3 players):
- tackles;
- invites / accept / leave;
- crewmates' name colours;
- the shield;
- the new-player safety;
- a Crew Supernova with 2+ crewmates.

# Phone check (SE 667x375)
- The HUD with CREW + JETPACK, and the CREW window: **CLEAN**.
- Android / 14 Pro: not re-run.
- **FOUND (older than today):** the **STAR FORGE window has no phone layout**. On SE its text is 8-13 px; it was never in the phone audit because only Ignition-1 players opened it. **LUMI's gift now opens it for brand-new players in their first session, so it needs a phone layout before 21 Nov** (like UPGRADES / DAILY).

# Owner / open
1. **Before 21 Nov:** the STAR FORGE phone layout (above).
2. The 2-player test of the heists; the 8-client FPS check (G.4).
3. **Balance:** VOID ×10 on the core bonus (an Epic XP core = +1500% XP) is what the prompt asked for, but strong. Check after a week (Secret / Void counts).
4. **SECRET odds:** correct `RollsPerHour` from the ForgeRoll analytics.
5. **Creature art:** run the prompts below (ChatGPT art pipeline), then put the ids in `GameConfig.Creatures.Kinds[k].art`.
6. **For the 21 Nov publish:** set `GameConfig.NextUpdate` all true; File > Save; publish.

## Creature art prompts (ChatGPT art pipeline; icons on BLACK; one sheet)
STYLE BLOCK (matches the game's glossy UI icons: the comet, essence, trophy):
"chunky glossy Roblox simulator pet style, cute big-eyed chibi creature, soft cel shading, strong white top highlight, thick dark navy outline, bright saturated space colours (violet, cyan, gold, magenta), small star sparkles; NOT a photo, NOT realistic"

PROMPT (sheet 1, 2048x2048):
"Create ONE image, 2048x2048, pure black #000000 background. An exact 3x3 grid; each cell holds ONE creature, centred, three-quarter front view, the same size in every cell, wide empty black space around it, nothing touching. NO text, NO numbers, NO letters anywhere. No floor, no shadow on the background.
TOP ROW: 1) NOVA FOX: a small fox made of warm gold stardust, a glowing four-point star on its forehead, a fluffy tail that fades into sparkles. 2) CRYSTAL CRAB: a round crab whose shell is a cluster of purple crystal shards, two small claws, glowing violet joints. 3) COMET RAY: a manta ray, cyan-blue body, an icy comet tail streaming behind it.
MIDDLE ROW: 4) SUN OWL: a round owl with orange-gold sun-flare feathers, a little sun disc on its chest. 5) LUCKY JELLY: a jellyfish with a teal-cyan bell shaped like a lucky crystal, soft glowing tentacles. 6) PLANET TURTLE: a turtle whose shell is a small ringed gas-giant planet (peach and cream bands, a gold ring).
BOTTOM ROW: 7) NEBULA WHALE: a whale whose body is a purple-pink nebula with tiny stars inside, a glowing blowhole spout of stardust; slightly bigger presence than the others. 8) and 9) empty black cells.
Every creature: friendly face, two eyes, no extra limbs or fins, not perfectly symmetric, the same art style as the STYLE BLOCK."
Then: icons alpha from a black-border flood fill; QA on light + dark; upload to the P&L Studios XP group; ids into `GameConfig.Creatures.Kinds`.

# Files (Studio)
- **New:**
  - ServerScriptService: GalaxyHeistService, GalaxyPortalService;
  - StarterPlayerScripts: GalaxyCreatures, GalaxyGraphics, GalaxyJetpack, GalaxyHeist.
- **Changed:**
  - ReplicatedStorage.Galaxy: GameConfig, EconConfig, MapConfig, UIKit, VfxLibrary.
  - ServerScriptService: GalaxyEconService, GalaxyStarSurgeService.
  - StarterPlayerScripts: GalaxyForge, GalaxyHUD, GalaxySettings, GalaxyPotions, GalaxySocial, GalaxyRankTags, GalaxySupernova.
- **Vault:** `Calc/kidsim.py` (gift_roll), `Calc/variants.py` (variant G).
