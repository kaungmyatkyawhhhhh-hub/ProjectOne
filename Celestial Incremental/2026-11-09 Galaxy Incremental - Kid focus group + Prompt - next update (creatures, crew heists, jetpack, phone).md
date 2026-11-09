---
date: 2026-11-09
tags: [galaxy, research, focus-group, prompt, update]
status: BUILT 9 Nov in Studio, OFF until 21 Nov (see Progress "Sat 21 update built"); owner tests + publishes
method: "[[Brain/Methods/Kid focus group (ChatGPT)]]"
---
# Galaxy Incremental: kid focus group (ChatGPT) + the next update

Owner (9 Nov): "u guys are multiple group of kids arguing over which roblox game to play. find the objections they have to yours and improve the game until everyone agrees to play ur game", then "put in obsidian and ill let claude change it".
ChatGPT played 7 kids in 3 groups; Claude pitched Galaxy and changed it each round until all 7 voted for it. ChatGPT chat: "Game Pitch Feedback".
**It's role-play, not real players.** Treat it as a list of objections to answer; the real check is the onboarding funnel + playtime after the update.

## The kids
| group | kids | they play |
|---|---|---|
| The Grinders | Jayden 12, Mia 11 | Pet Simulator 99, Grow a Garden, number-go-up games |
| The Chaos Squad | Leo 10, Kai 9, Zoe 10 | Steal a Brainrot, 99 Nights in the Forest, Dead Rails |
| The Mobile Kids | Ethan 8, Sofia 9 | Brookhaven, easy obbies; cheap phones, bored in 10 s |

## Rounds
| round | votes | what was pitched | what they said |
|---|---|---|---|
| 1 | 0/7 | the alpha as it is: island, stardust, pads, comets, Supernova | "a bigger rock? 😭", "just clicking", Supernova "deletes my island", can't troll friends, no reason to team up, phone lag |
| 2 | 1/7 | big numbers, space creatures + rarities, Supernova keeps creatures, stealing, raids, jetpack, auto-collect | Ethan in (jetpack). Others: how fast? is Secret really rare? double-steal? raids just tapping? cluttered phone screen? |
| 3 | 5/7 | real timings, odds shown, Secret serials + server beam, chain-stealing with tackles, 3 raid types, 3-button phone HUD, Black Hole spaghetti | Zoe: no real teamwork. Sofia: prove no lag. All: "is this real?" |
| 4 | **0/7** | honest: the alpha has the base game; the rest is "28 Nov" | everyone left. "Stop selling me features I can't play." |
| 5 | 6/7 | only what fits in ONE update; the kids picked 4 of 8 | picked A creatures, B stealing, C jetpack + Black Hole, G phone. Zoe out (no crews) |
| 6 | **7/7** | stealing becomes CREW HEISTS (crews escort the carrier, fill a shared Crew Core, Crew Supernova) | all 7 yes, each with a condition (below) |

## The 7 conditions (each yes depends on one)
| kid | condition |
|---|---|
| Jayden | the crew multiplier is worth it ("x1.2 and I'm uninstalling") |
| Mia | creatures look good ("not floating cubes"); trading comes next |
| Leo | heists are real chaos |
| Kai | tackling / body-blocking works, not buggy |
| Zoe | crews are NEEDED (you lose if you don't protect each other) |
| Ethan | jetpack + Black Hole spaghetti ship |
| Sofia | no lag on a cheap phone, even during explosions |

## Lessons
1. **Kids vote on what they can play tonight.** Round 4 went 5 → 0 when they learned the features weren't in the build. Rule: never put a feature in ads, the description, a thumbnail or a shout until it's live.
2. **Fewer, working features beat many promised ones.** Jayden: "four working things, not eight broken things pretending to be four."
3. **One feature can serve three kid types.** Crew Heists gave chaos (Leo, Kai), teamwork (Zoe) and a multiplier (Jayden) in one system.
4. **The phone kid vetoes everything.** If Sofia's phone freezes, nothing else matters.

## What the live build already has (Studio audit, 9 Nov 11:20)
| kids asked for | in the build now | gap |
|---|---|---|
| pets / creatures with rarities | STAR FORGE: rolls, odds shown, pity, 42-core book (GalaxyForge, EconConfig.Forge); LUMI pet follows you | cores are icons in a window; no mutations, Secret, serials or beam; Forge opens only at Ignition 1; 1 Essence per 25 comets |
| comets | catch comets, chain, golden, perks, paths, x2 COMETS potion | none |
| Supernova that doesn't feel like losing | Supernova + Black Hole (Dark Matter) | none |
| server-wide moments | Star Surge bar, Great Star, parties, island stars | none |
| stealing, crews, tackling | nothing (no steal / crew / tackle code) | ALL NEW |
| flying | low-gravity jump (GalaxyMovement) | no jetpack |
| Black Hole you can fly into | plaza BlackHoleGate opens the Black Hole window | no touch → spaghetti → random spot |
| phone performance | 7 Nov PHONE HUD fix; quality checks only in RankTags / Social | no single Low Graphics switch; phone HUD still busy |
| trading, boss raids, co-op dungeon | nothing | next update |

## When
The Sat 14 Nov update is already built and in your testing ([[2026-11-09 Galaxy Incremental - Weekly update plan (Sat 14 Nov)]]): don't touch it.
These 4 features = **the Sat 21 Nov update**. Claude Code builds them now, in order A → G → C → B (B is the biggest and riskiest; if it slips, ship A + G + C and keep B for the week after, but don't announce it).

---

## PROMPT for Claude Code (copy everything below)

Read first: `Brain/00 BRAIN.md`, `Celestial Incremental/CLAUDE.md` (map rules: MapConfig + BoardPlacer + MapAudit, never hand-place), this note, and the Studio scripts named below. The game is open in Studio: "[ALPHA] Galaxy Incremental" (place 111654682859982). Studio is the source of truth. Every number goes in a config table (EconConfig / GameConfig / MapConfig), never hard-coded. Don't touch what's built for Sat 14. Don't publish (the owner tests). Write a Progress note: what you built, every config value, the layout tables, MapAudit output, screenshots, open questions.

### A. STAR CREATURES (build on the Star Forge; don't make a second collection)
1. **Creatures you can see:** every Forge core gets a creature look (6 kinds x 7 rarities; rarity = colour, size, aura). Your 3 EQUIPPED cores float around your island and follow you near it (reuse LUMI's follow + bob code from GalaxySocial). Others see them within 60 studs, never on Low Graphics. Art: list the 6 creature kinds + the rarity look and write ChatGPT prompts with the art pipeline (skill roblox-chatgpt-art-pipeline). No grey cubes, ever (Mia).
2. **Mutations:** each roll also rolls a mutation, shown in the odds panel before rolling: `EconConfig.Forge.Mutations = { Golden = {chance = 1/20, power = 1.5}, Rainbow = {chance = 1/200, power = 3}, Void = {chance = 1/2000, power = 10} }`. A mutation is its own book entry (the book gets a Mutations tab).
3. **SECRET tier** above the 7 rarities: `EconConfig.Forge.Secret = { kinds = 1, oddsTarget = "about 1 per 2,000 player-hours" }`. Work out the odds from the live Essence rate (rolls per player-hour), write the maths in the Progress note, show the odds on screen like every other rarity. Can't be bought: Robux only ever buys Essence, and only where PolicyService allows (GalaxyGrowthService already handles this).
4. **Serials + announce:** Secret and Void creatures get a global serial (#n) from a DataStore counter (UpdateAsync). On a pull: a beam from the player's island the whole server sees, plus a chat / toast line `NAME pulled Void Nebula Whale #12!`. The book shows "n exist" for each Secret / Void.
5. **Reach it earlier:** a free FIRST roll as LUMI's gift right after the tutorial (the Forge window can still unlock at Ignition 1; the gift roll plays its reveal on the spot). `EconConfig.ForgeFeed.CometsPer = 10` (was 25). Re-run the impatient kid sim (`Calc/kidsim.py`) with the gift roll in; minute-1 stay must not drop.
6. Creatures are KEPT through Supernova and Black Hole (check EconConfig's keep lists and state it in the Supernova card: KEEP: creatures).

### G. PHONE MODE (before B: heists add players, particles and explosions)
1. One switch: `GameConfig.Graphics = { Mode = "Auto" }`, with options Auto / Low / High in Settings (GalaxySettings). Auto = Low when the saved quality level is ≤ 3, or when average FPS stays under 40 for 10 s (re-check every 30 s, never flip back and forth more than once a minute).
2. Low = particle rates x0.3; no other players' creatures / LUMI / trails beyond 40 studs; far islands' decoration hidden beyond `GameConfig.Graphics.FarDetailStuds = 300`; explosion VFX use the short version. Every script reads one shared flag (`shared.GalaxyLowGfx`); replace the separate checks in GalaxyRankTags and GalaxySocial.
3. Phone HUD (build on [[2026-11-07 Galaxy Incremental - Prompt - PHONE HUD fix (live game)]]): on touch screens only these stay out: stardust (top), ONE big NEXT UPGRADE button (bottom right), JETPACK (bottom left), MENU. Every other chip (gift, party, event, Ignition, potions...) moves into MENU, with a red dot when something's ready. Supernova's gold button still appears when ready.
4. Target: 30+ FPS on a low-end Android at 8 players during a Crew Supernova. Use the MicroProfiler on a server with 8 test clients; put the numbers in the Progress note.

### C. JETPACK + BLACK HOLE SPAGHETTI
1. **Jetpack:** hold to hover (phone: JETPACK button; PC: hold Space in the air). `GameConfig.Jetpack = { Fuel = 3, RefillGrounded = 1.5, Lift = 60, CeilingAbovePlaza = 120 }`. A fuel ring around the button, stardust thrust puff, soft whoosh. Disabled while carrying a heist comet.
2. **Spaghetti portal:** walking into the plaza BlackHoleGate's inner zone stretches your character (client-side visual, 1.2 s), then teleports you to a random safe landing (`MapConfig.BlackHolePortal.Spots` = every island's landing + plaza points, chosen by code). Cooldown 10 s. The Black Hole reset stays on its board / window, so nobody resets by accident. The zone is defined in MapConfig and placed by code; run MapAudit.

### B. CREW HEISTS (new GalaxyHeistService + GalaxyHeist client)
**Nobody ever loses their own income.** Heists use separate LOOSE COMETS, so the tycoon economy is never stolen from (Zoe: losing your stuff is "annoying").
1. **Crews:** up to 4, for this server only (not saved, v1). A CREW window (in MENU): INVITE a player in the server → they get an accept card. Leave anytime. Crewmates see each other's names in the crew colour.
2. **Loose comets:** `EconConfig.Heist = { LooseEvery = 60, OwnerGrabBonus = 2, Value = 120, CarryLimit = 45, CarrySpeed = 0.7, PickupHold = 0.5, TackleImmunity = 1.5, StealShield = 10, NewPlayerSafe = "until first Supernova" }`. Every 60 s a loose comet lands on a random owned island. The owner grabs it instantly for a bonus (x2); anyone else can grab it (0.5 s hold) and has to carry it to their own island's landing pad within 45 s, or it bursts back. Value = 120 s of the banker's income.
3. **Carrier:** glows, leaves a trail, 70% speed, no jetpack. **Tackle:** touching a carrier who isn't your crewmate drops the comet; the tackler can't grab it for 1.5 s (so chains happen). Crewmates can't tackle each other and can body-block. After a steal, the robbed island gets a 10 s shield. New players' islands (before their first Supernova) never get loose comets taken.
4. **Crew Core:** every banked comet = 1 point to your crew's CORE (solo players have their own). `EconConfig.Heist.Core = { Points = 10, GatherSeconds = 30 }`. Full → the Core glows over the crew leader's island; every crewmate online must stand on it within 30 s.
5. **Crew Supernova:** a server-wide shockwave that launches every player within 120 studs (ragdoll, short, safe landings; the "less shake" setting tones it down), using the Supernova VFX. Reward for each crewmate: x2 stardust for 10 min AND +2% permanent stardust per Crew Supernova, up to +40% (`EconConfig.Heist.Reward = { BoostX = 2, BoostMinutes = 10, PermanentPer = 0.02, PermanentCap = 0.40 }`). The permanent part is saved and shown in the stats (Jayden). It also fills the Star Surge bar.
6. **Server-side everything:** grab range, carrier speed, tackles, banking, core and rewards are all checked on the server. Rate-limit every remote.
7. Analytics: Heist_Grab, Heist_Tackle, Heist_Bank, Crew_Joined, CrewSupernova.

### Checks before handing back
- Impatient kid sim re-run (A changes minute 1-3); first Supernova still lands where it does now.
- Quality-nerd check on the creatures and the Crew Supernova (method: [[Brain/Methods/Quality-nerd kid simulation]]).
- [[Brain/Methods/Launch gate]] items for an update.
- Progress note with every value above and anything you changed from it (and why).

---

## Next update after this (promised to the kids; don't announce until built)
1. **Trade Plaza** (Mia, first): both sides confirm, a 5 s countdown that resets on any change, a value meter.
2. **Comet Boss raid** every 5 min with participation loot (Kai, Zoe).
3. **Wormhole Expedition**: co-op dungeon, one carries the Star Core, the others protect it (Zoe).

## Check after the Sat 21 update
Creator Hub: average playtime and D1; funnel steps; Heist_Grab / CrewSupernova counts (do crews form?); the share of sessions on Low Graphics, plus phone vs PC playtime (is Sofia's group staying?).
