---
date: 2026-11-11
tags: [titan, design-doc, next-game, draft, dead-game-method]
status: DRAFT v1.1 (v0 + the three kid sims + the new vault research of 11 Nov 02:25). Nothing is decided until the owner says so. Game name proposal: Stomp Evolution; TITAN ARC is only the folder name.
---
# TITAN ARC: design doc v0 (draft)

Owner (11 Nov, 00:45): "i wanna do like titan simulator copy but a update to date version".
Research behind it: [[2026-11-09 Research - Dead game method (shut-down multiplayer games as an idea library)]] section 6 (why Titan Simulator was loved and why it died), [[K01 Roblox platform and discovery]], [[K02 First session and retention]], [[K03 Incremental design and pacing]], [[K04 Monetization and economy]], [[K08 LiveOps, updates and analytics]], [[Launch gate]]. Format follows [[2026-11-10 +1 SHRINK - Design doc v0 (draft)]].
Methods used: **Dead game method** + **Data first** (market check below) + a pacing bot (`TITAN ARC/Calc/titansim.py`). Run on the plan 11 Nov: [[Impatient kid simulation]], [[Quality-nerd kid simulation]], [[Debate kids simulation]] (see v1 below). Not run yet: [[Kid focus group (ChatGPT)]], and all three again on a live config.

## v1.6 size: the growth step SHRINKS each evolution (owner 11 Nov 15:17): read this first, it corrects v1.5
Owner: "actually titan simulator scale gets smaller so not exactly 1.5^10". So the first evolution is about x1.5 and each later one adds a little less.
I do not have Titan Simulator's real numbers. **My curve (tunable in the config): step = 1 + 0.5 x 0.9^(n-1).** It starts at x1.5, each step keeps 90% of the last step's gain, and the total levels off on its own (about x70 after 30 evolutions), so no hard cap is needed and a 30-armour ladder like Titan Simulator's fits.
| After evolution | This step | Total scale | HEIGHT | Studs tall |
|---|---|---|---|---|
| 0 Starter | - | x1 | 1.7 m | 5 |
| 1 Brawler | x1.50 | x1.5 | 2.5 m | 8 |
| 2 Stone | x1.45 | x2.2 | 3.7 m | 12 |
| 3 Iron | x1.41 | x3.1 | 5.2 m | 16 |
| 4 Magma | x1.36 | x4.2 | 7.1 m | 22 |
| 5 Storm | x1.33 | x5.5 | 9.4 m | 29 |
| 6 Crystal | x1.30 | x7.2 | 12.2 m | 38 |
| 7 Star | x1.27 | x9.1 | 15.4 m | 48 |
| 8 | x1.24 | x11.2 | 19.1 m | 60 |
| 9 | x1.22 | x13.7 | 23.2 m | 72 |
| 10 | x1.19 | x16.3 | 27.7 m | 86 |
| 15 | x1.11 | x31.8 | 54.0 m | 168 |
| 20 | x1.07 | x47.6 | 81.0 m | 252 |
| 30 | x1.02 | x70.2 | 119.3 m | 372 |
Everything else in v1.5 still holds (one real city scale, speed / camera / stomp reach scale with the body, re-tune the pacing sim). Changed: the Star is about 9 times the Starter (not 17), a 10th evolution about 16 times (not 58), and the "about 10 evolutions per run" limit is no longer needed for size.
The HEIGHT number on screen can still climb faster than the body if the late game needs bigger numbers.

## v1.5 size: x1.5 bigger EVERY evolution (owner 11 Nov 15:15): the table below is SUPERSEDED by v1.6
Owner: "in titan simulator it gets bigger like 1.5x every time so stage 10 is like the 1.5^10". Not measured by me from footage; taken as the owner's memory of the game. It fits the pictures (a new player is ankle-high to a giant).
**Rule: every evolution makes the REAL body 1.5 times bigger than the one before.** This replaces the "x1.36 body ladder", the "real scale clamped at about 10x" and the "each district built at a smaller scale" trick in section 10.
| After evolution | Scale | HEIGHT | Studs tall (avatar about 5.3) |
|---|---|---|---|
| 0 Starter | x1 | 1.7 m | 5 |
| 1 Brawler | x1.5 | 2.5 m | 8 |
| 2 Stone | x2.2 | 3.8 m | 12 |
| 3 Iron | x3.4 | 5.7 m | 18 |
| 4 Magma | x5.1 | 8.6 m | 27 |
| 5 Storm | x7.6 | 12.9 m | 40 |
| 6 Crystal | x11.4 | 19.4 m | 60 |
| 7 Star | x17.1 | 29 m | 91 |
| 8 | x25.6 | 44 m | 136 |
| 9 | x38.4 | 65 m | 204 |
| 10 | x57.7 | 98 m | 306 |
**What it changes:**
- The city can be ONE real scale: a 30-stud house is knee-high to a Star (91 studs). No fake zoom needed.
- The old form gates (1.9 / 2.4 / 3.0 / 4.5 / 8 / 13 / 21 / 28 m) are replaced by the HEIGHT column. Growth inside a form stays under x1.5 so an evolve never looks smaller (MEGA BITE rule: biggest of a form at most 0.9 of the next).
- Walk speed, jump, camera distance, stomp reach and the shock ring all scale with the body, or a giant feels slow and a small player cannot see.
- The map must fit a 300-stud player: wide streets, long sight lines; small props stream out for giants.
- **It cannot go on forever:** x1.5 thirty times is about 190,000 times. Plan the 1.5 rule for about 10 evolutions per run; AWAKEN (rebirth) puts you back to x1, as in Titan Simulator.
- Re-tune `Calc\titansim.py` to these heights before any build (not done yet).
- The 8-stage picture shows stage 8 only 2.2 times stage 1 so the details are visible; in game the Star is 17 times the Starter.

## v1.4 forms are armour sets on YOUR avatar (11 Nov, 05:05): read this first
Owner rejected the monster pictures ("It doesn't even look Roblox anymore"). Study: [[2026-11-11 Reference study - Titan Simulator evolutions (30 armours) + line-up v4]].
- Every form = an original armour BODY SET on the player's Roblox avatar (R15). Head, face, hair and hats stay the player's own. Oversized stomping boots on every set. This replaces "full monsters from form 3" in v1.2 and v1.3 point 8.
- One standard rig and the standard Roblox animations; no custom creature rig.
- Plan more forms: Titan Simulator had 30, nine of them inside the first 1,000 power. Themes can change every week.
- We make our own sets (Titan Simulator used Roblox's catalog bundles). Owner can overrule.

## v1.3 after watching Titan Simulator clips and measuring Venom's sound (11 Nov, 03:25): read this first
Source: [[Roblox Playbook/Research notes/2026-11-11 Watch study - Titan Simulator clips + Venom sound measured (YouTube in the browser)]]. Owner: "the gameplay was addicting, but the looks are trash".
1. **Every stomp pays, even on bare ground:** 10% of your best prop's Mass + a footprint. Sim (`Calc\anytap.py`): taps that pay 42% → 100%, longest wait for a reward in minute 1 from 1.9 s → 0.5 s, first boss 9.8 → 9.5 min.
2. **Giants cross the starter street** (the way onward, the pads and the Sumo Ring are placed for it). Their steps shake and bounce small players, never hurt them.
3. **HUD:** "NEXT: <FORM NAME> at <height>" always on screen.
4. **AWAKEN = Titan's rebirth:** tiny again in the same server, first four forms back in about 2.5 minutes.
5. **Leaderboard:** HEIGHT and Sumo wins.
6. **Sound rules:** no silent action (3 to 5 sound starts a second); the stomp is a low thump (60-250 Hz, 0.15 to 0.25 s, 3 variants); big full-range bursts (0.4 to 0.5 s, 15 dB or more above the bed) only for evolve, boss kill, crown and ROGUE ALERT; rewards are a double hit (burst, then a sting about 1 s later with the name card).
7. **Boss renamed JUNK TITAN** (Venom has a boss called "Scrap King"; ours was "Scrap Colossus"). Wherever this doc says Scrap Colossus, read JUNK TITAN. Name not yet checked against other games.
8. **Correction to v1.2 below:** the wind-up TOY family was withdrawn at 02:50 (owner: "u sure toy is good?"). The family is D: real little monsters with natural armour, in a bright cartoon city (not a toy city), with the staged transformation from the Venom study (monster feet on your avatar first). ROGUE ALERT, IRONBOOT and the glowing soles stay.

## v1 after the three kid sims (11 Nov, 01:45): read this first
Now named **Stomp Evolution** (owner: the game is "evolutions more than titan", and no "+1"). Full results: [[2026-11-11 Stomp Evolution - Three kid simulations (impatient, quality nerd, debate)]].
**The game in one line (v1):** you are a small creature in a toy city. Stomp to grow, and about every half minute you EVOLVE into something bigger with a new look and a new move, until you step over towers. Everyone sees how big you are; the biggest wears the crown; the whole server fights a Rampage together.
**What changed from v0 below (v1 wins wherever they differ):**
1. **Forms:** 8 before the first boss at 1.9 / 2.4 / 3.0 / 4.5 / 8 / 13 / 21 / 28 m (v0 had 3). First evolve ~28 s, second ~48 s. Each form has its own kit, move and cutscene, plus 3 visible growth stages inside it. The NEXT bar names the next form.
2. **First street:** 3 prop kinds from second one (flower, mailbox, bin); bikes at 2.05 m; a golden prop near every new player at ~25 s; first Ground Pound at stomp 6.
3. **Upgrade pads:** step-on pads along the street, one per block. This was the biggest single gain for impatient kids (72% → 98% staying 5 minutes at 7 s patience).
4. **Hand-made city:** 3 variants of every breakable prop, 5 crumbles by material, rubble stays and a visible rebuild, moving life (toy cars, birds, lights, alarms), a set piece every ~250 studs that breaks in 3 stages, district identity (palette, light, music), natural borders, streaming tuned.
5. **Fighting at launch:** the Sumo Ring (size brackets) moves from week 3 to launch; the Rampage is the crown holder against the server.
6. **Funny and cute:** squeaky toy city, silly props, a pet-size first form.
7. **Servers:** 10 slots, filled fullest first, NPC stompers so the city never looks empty. A weekly-update board with a countdown in the plaza.
8. **Up front:** the city, the crown and the Rampage in minute 1 and on the icon.
**Sim results on the plan:** impatient kid 74% → 100% staying 5 minutes; quality-nerd kid 115 → under 1 cheap tells per 10 minutes; debate kids 9% → 100% "everyone agrees" (robust to ±1), 93% first pick. **Left for marketing:** with a small launch crowd, 41% of friend groups still say "it's dead".

## v1.1 new vault research applied (11 Nov, 02:25)
Owner: "check vault again, theres new research". Four notes were new since midnight (written by other chats): [[2026-11-11 Research - 14 TikToks (Claude cutscenes, VFX, ocean games, Roblox dev tips)]], [[2026-11-11 Research - VFX reference (bbstudios Claude sword combo TikTok)]], [[2026-11-11 Research - 5 viral TikToks watched (Claude motion design + Roblox) + trending sounds]], [[2026-11-11 MEGA BITE - Titan steals built (growth, size tags, crown)]]. Also used: [[2026-11-01 Research - Do cutscenes help, what makes a good one]] and the free-ocean HUD v3 line on the MEGA BITE home note.

**1. The evolve moment (from the cutscene TikToks + our own cutscene research).** The new notes say every big unlock deserves a 2-3 s cutscene: dark backdrop, ONE hero colour, emissive glow, a light burst, weather or particles, a NAME CARD in caps, a clean exit (white-out or TV-off). Our 1 Nov research says the opposite for common things: never a cutscene on a repeated action, rare = special, and bigger effects alone lower motivation. With 8 evolves in 10 minutes both are true only if the size follows the rarity:
| Evolve | Length | Camera | What plays |
|---|---|---|---|
| Forms 2-4 (every ~30 s) | 1.2 s, you keep control | none | the scene dims, a star glint + ring + halftone burst in the form's colour, the new kit snaps on, a small name card |
| Forms 5-7 | 2 s | a quick orbit | plus a light burst and the form's weather (dust storm, sparks, embers) |
| Form 8, first boss kill, AWAKEN | 3-4 s, skippable after the first time | full cinematic | speed-line tunnel → white-out → the new form in silhouette → name card → it ENDS on the next form's shadow (the question that keeps kids playing) |
Each form owns one hero colour (Stone grey-green, Iron steel-blue, Magma orange...). The rest of the server sees a beam and a toast.

**2. The stomp (from the VFX reference).** The core action is done thousands of times, so it gets the "calm → 0.1-0.2 s burst → slow linger" rule, in 4-6 simple layers: leg lifts with a small glint (0.12 s) → impact: shock ring + two dust crescents + speed lines + debris chips (0.1-0.15 s) → **a cracked footprint stays on the ground and fades over ~6 s**. One hero colour (your form's), white for the flash, dark dust for weight. Ground Pound adds the 4-point star with the colour-split fringe and a halftone burst. Bigger forms leave bigger footprints: the street shows who walked there.

**3. HUD (from MEGA BITE's free-ocean HUD v3).** The owner felt the boxed HUD was "a trap, not freedom". Same rule here from the first mockup: no dark boxes, HEIGHT and Coins float, the NEXT bar fades in when it moves, moves stay hidden until earned, toasts are floating rewards. And no placeholder buttons ever: the TikTok of the Pacific Rim game shows a beautiful game looking unfinished because of grey HUD boxes.

**4. Boss and Rampage intro cards.** A 1.5 s card with the name in caps ("SCRAP COLOSSUS", "RAMPAGE") before each boss and each Rampage.

**5. Air in the city.** Light shafts between the towers, floating dust motes, confetti after a big crumble. (The diving game is loved for its calm beauty; ours is a bright toy city, same idea.)

**6. Build it on MEGA BITE's code (the other chat built the Titan steals tonight).** Ready to reuse: server-replicated `Model:ScaleTo` growth with a 0.35 s overshoot; **Weld with an explicit C0, not WeldConstraint**, so the scale replicates; BonePlayer refits clip translations when the scale changes; the size-tag script (name, size, form, ▲/▼/= badge, 12 nearest, MaxDistance 140); the crown server (2 s check, 6 s hold, 20 s gap, a `Changed` hook, one toast with the drawn icon). Lessons to copy: growth follows how far you are into the tier (complete at 80% of the way), never a bite count; the biggest size of a form is at most 0.9 x the next form; a monotone body ladder (about x1.36 per form); reset the growth BEFORE the model swap so an evolve never looks smaller. This cuts the first slice's work: the crown, tags and growth are a port, not a new build.

**7. Marketing: the answer to the debate sim's last objection ("nobody plays it").** From the 5 viral TikToks (all small accounts; the format carried them, polish did not):
- A doubt or a claim in second 1, then proof. For us: "AI can't make a good Roblox game" over a plain clip → cut on the beat to a phone filming the city crumbling under a giant. Or "tiny to tower in 15 seconds": the 8 evolves back to back.
- The "remade them" before/after format for the forms.
- 10-15 s, the screen filmed in the real world (a phone on a desk), one plain caption, a reason to comment.
- Cut to a sound that is trending in the owner's own feed. Not from chart sites: the owner said those lists are wrong. Deliver the video without music and add the sound in the TikTok app.
- Cheap volume later: code-rendered Roblox animations (the "75 shots, 102 sound effects, 0 animators" video) fit our video pipeline.

**8. Order.** The 14-TikTok note found a direct "Hungry Shark Roblox" competitor being built, basic but live, and says to move fast. That is one more reason MEGA BITE ships before this game starts.

**The three sims were not re-run:** these are specs for things the sims already counted (form cutscenes, crumbles, a hand-made look). The numbers stay as in v1 until there is a build.

## v1.2 models (11 Nov, 02:40)
[[2026-11-11 Stomp Evolution - Model brainstorm (families, model list, style)]]. **Reversed:** forms are FULL creature models, not your avatar wearing a kit (in evolution games you become the creature: Bug Evolution, 14K playing; kits hide the evolution and clip on avatar bodies). Proposed family: big-foot monsters that grow element armour (SPROUT → STOMPLING → ROCKHIDE → IRONFOOT → MAGMABACK → STORMHORN → PRISMFANG → STARCROWN). About 70 models for launch, about 30 for the first slice. The owner picks the family before any sheet is made.
**Update 02:35 (owner: "we need scores to 35/35"), the toy part WITHDRAWN at 02:50, see v1.3 point 8:** the family is now D2, WIND-UP TOY MONSTERS (a key on the back, ball joints, snap-on armour plates, the feet tell the form): 35/35 with a test behind every 5. **The RAMPAGE event is renamed ROGUE ALERT everywhere** (Rampage is a Warner Bros. game series about giant monsters destroying cities); wherever this doc still says Rampage, read ROGUE ALERT. Form 4 is IRONBOOT; form 5's glow is in its soles, not on its tail.

## The game in one line
You start human-size in a toy city. Every stomp makes you bigger. Grow through titan forms until you step over towers. The biggest player in the server wears the crown, and every 10 minutes the whole server fights a RAMPAGE together. **How big can you get?**

## 1. Market check (Roblox search + games APIs, 11 Nov 2026 ~01:00 MMT)
**A straight copy is already live, and it is empty.**
| Game | Made | Playing | Visits | Likes | What it is |
|---|---|---|---|---|---|
| Titan Simulator (the original) | Oct 2017 | 13-18 | 91.7M | 87% | click, grow, stomp players |
| **Titanus Simulator** | May 2026, UPD 6 on 8 Nov | **2** | 450K | **58%** | the up-to-date copy: click to grow, PvP with an on/off switch, King of the Hill, daily + weekly quests, supply drops |
| Biggest Titan Simulator | Dec 2024 | 23 | 4.4M | 66% | push-ups, titan forms, eat players, safe zone |
| Titan Training Simulator | Jun 2024 | 109-125 | 94.8M | 95% | two camps, pets, rebirths. No update since Aug 2025 |
| Giant Simulator REBORN (Mithril) | Feb 2023 | 178 | 8.8M | 89% | click to grow, weapons, pets, rebirth, offline gains |

**The same fantasy in a 2026 format is doing well.**
| Game | Made | Playing | Visits | Likes | What it is |
|---|---|---|---|---|---|
| **+1 Titan Evolution!** | 5 Oct 2026 | **1,878** | 4.19M | 91% | click for power, smash walls for wins, transform into stronger titans, rebirth, pets, rare titles, a server-wide arena event, world 2. 260K favourites (62 per 1,000 visits, very high) |
| **Grow And Build Giants** | 12 Sep 2026 | **2,515** | 1.25M | 93% | steal orbs from bosses, feed YOUR giant so it grows and earns, parts from lucky blocks, bat fights to steal orbs. 6-player servers |
| +1 Size Per Step | 23 Aug 2026 | 946 | 21.3M | 92% | bigger every step, beat enemies and bosses, smash stages. Last update 17 Oct: fading |
| Feed a Giant | 21 Sep 2026 | 887 | 3.4M | 87% | steal food, fire it into a giant's mouth |
| Hunt a Titan | 2 Oct 2026 | 550 | 484K | 86% | train speed, hunt rare titans, keep them on your plot |
| Muscle Legends (the evergreen) | Aug 2019 | **2,526** | 2.32 BILLION | 88% | train, new gyms, pets, moves, brawls + arenas. Still updated (9 Nov 2026). Passes 99-799 R$ |

**What this means**
- The old recipe (open PvP, click to grow) does not hold players in 2026, even with the fixes bolted on: Titanus has a PvP switch, quests and weekly updates and sits at 2 players with 58% likes. **So not a copy: the fantasy, rebuilt.**
- What moved since 2017: growth comes from PvE (walls, bosses, a city), not from farming new players; you TRANSFORM (new forms), not only scale; there is a collection layer; servers are small (6-10); there is a server event.
- What none of the new ones kept from Titan Simulator: **the body as the leaderboard between players, and the gang against the giant.** That is our twist (K09: theme + one twist; a late clone rarely wins).
- Owner on 6 Nov: "+1 is too much this month already". +1 Titan Evolution already owns "+1 titan". So no "+1" title and no wall-smashing lanes.
- Evergreen proof: Muscle Legends is the long-lived grandchild of this fantasy (7 years, 2.3B visits) because it never stopped updating (K08 rule 1).

## 2. What we keep, fix and add
| From Titan Simulator | Why it mattered | In TITAN ARC |
|---|---|---|
| Your body is the leaderboard | status with no menu | body grows with every stomp, HEIGHT tag over every player, crown on the biggest |
| The stomp | being big gives you a new verb | stomp = the core action; each form adds a move (Ground Pound, Boulder Kick, Quake) |
| Team up against the giant | the big player is the server's event | RAMPAGE every 10 min: the crown holder can BE the rampaging titan, everyone else brings him down, both sides get paid |
| Giants farm newcomers (death) | kids quit and dislike | **no PvP in the city at all**; an opt-in Sumo Ring with size brackets |
| Hard cap, nothing after (death) | players finish and leave | districts + AWAKEN (rebirth) + a new district every week; HEIGHT has no cap |
| Paid sword that wins fights (death) | pay-to-win | nothing bought helps in the Ring or the Rampage (K04, K08 rule 7) |
| Makers left (death) | the #1 killer | weekly Saturday drops written into the plan BEFORE the build (section 11), and the honest check in section 12 |

## 3. Core loop
1. **Stomp** anything your size can break (walk into it + tap; hold = keep stomping). It crumbles, pays **Mass** and **Coins**.
2. **Mass** makes your body bigger at once (a little every stomp) and moves the HEIGHT number.
3. Things too big for you show a padlock badge and "BE 6 m". Reach it and the next kind of prop opens: flower → bike → car → bus → house → shop row → tower block.
4. **Forms:** at set heights you transform (new look, new move, a short cutscene).
5. **Coins** buy three upgrades at floor pads: Stomp Power, Shockwave (hit more things per stomp), Speed.
6. Each district ends with a **boss** (a giant machine guarding the gate). Beat it → **AWAKEN** (rebirth): keep forms, titles and index; get a Mass multiplier; the next district opens.

**The one big number:** HEIGHT, top of the HUD: `1.7 m` → `12 m` → `60 m` → `300 m` → `2 km`. It only goes up. It is the thumbnail and the playground brag ("I'm 300 metres").

## 4. Forms (launch = 5, then one every 2-3 weeks)
| # | Form | Height | New move | Look |
|---|---|---|---|---|
| 1 | Rookie | 1.7 m | Stomp | your own avatar |
| 2 | Brute | 2.2 m | Double Stomp | avatar + chunky boots and fists |
| 3 | Stone Titan | 12 m | Ground Pound (ring shockwave) | stone shoulder + shin plates, moss |
| 4 | Iron Titan | 24 m | Boulder Kick (sends a prop flying into others) | riveted iron plates, steam vents |
| 5 | Magma Titan | 34 m+ (after boss 1) | Quake (cracks a whole street) | glowing cracks, ember trail |
| later | Storm, Crystal, Star | weekly districts | | |
**Decision (Claude): the player's own avatar grows and wears a form KIT** (boots, fists, shoulder and shin plates, aura), not 8 full new characters. Kids keep their look, thumbnails use the real avatar (our icon recipe), and it is 5 armour kits to model instead of 5 rigs. Every kit goes through the high-quality model rule (ChatGPT sheet → Blender → checks). **Never Attack-on-Titan looks:** no skinless giants, no walls + scouts, no "Rumbling", no "shifter". "Titan" itself is a generic word (K01 copycat rule).

## 5. Districts (launch = 2, then one every Saturday)
| # | District | You are | Props (our own kit) | Boss |
|---|---|---|---|---|
| 1 | **Toy Town** | 1.7 → 18 m | flowers, bikes, cars, buses, houses | - |
| 2 | **Downtown** | 18 → 34 m | shop rows, tower blocks, billboards, a ferris wheel | **Scrap Colossus** (a junkyard robot) |
| 3 | Harbour (week 1) | 34 → 90 m | cranes, ships, containers | Kraken Crane |
| 4 | Skyline (week 2) | 90 → 300 m | skyscrapers, a stadium | Storm Zeppelin |
| 5 | Mountains (week 3) | 300 m → 2 km | peaks, dams, a volcano | Volcano Heart |
The city **rebuilds itself** (props respawn in ~6-10 s with a pop-up animation), so the map is never empty. Bright toy colours, cartoon dust, nobody inside the buildings (no people harmed: Minimal/Mild rating, K01).

## 6. Social: the part nobody else has
- **HEIGHT tag** over every other player: name, height, form, and a ▲ / ▼ / = badge versus you (shape, not colour only).
- **Crown:** the tallest in the server, with a toast when it changes hands (6 s hold, 20 s minimum gap, same rules as the MEGA BITE crown).
- **RAMPAGE (every 10 min, 90 s):** a Rogue Titan attacks the plaza. Everyone stomps its feet and hits glowing weak spots; damage = your Stomp Power. Reward by share of damage, with a floor so small players always get something. **If the crown holder says yes, HE controls the Rogue Titan** and earns for every second he survives. No one loses Mass. Solo or quiet server = an NPC runs it (dead-game rule: bots fill).
- **Sumo Ring (opt-in):** push the other titan out. Brackets by form, so nobody meets a giant. Wins give a title, never power.
- Friend boost +10% each (max 3), a "join friend" button, a server goal ("this server flattened 5,000 houses" → x2 Mass for 10 min). Co-play days are a Home ranking signal (K01).

## 7. First 60 seconds (script) + pacing
- 0 s: you land in Toy Town with a thud; HEIGHT shows 1.7 m; a flower bed is under your feet. First stomp inside 3 s: crumble, coins fly, "boing", `1.71 m`.
- 0-30 s: a prop every ~1.5 s along the street; a welcome gift of 10 Coins; the first Stomp Power pad glows 4 studs away.
- ~60 s: **BRUTE** (first transform, a 2 s cutscene, boots slam down). Bikes unlock.
- ~3 min: Stone Titan + Ground Pound. ~4.7 min: Downtown opens. ~6 min: Iron Titan. **~10 min: Scrap Colossus.**
- A Rampage lands inside the first 10 minutes for everyone (server clock), so every new player sees the big thing.
- Like prompt only after the first boss (Launch gate). No shop offer in the first 5 minutes.

**Pacing bot (draft, `TITAN ARC/Calc/titansim.py`, 20 runs, a best-choice player):**
| Check | Target (K02/K03) | Bot |
|---|---|---|
| Something to do every ~3 s in the first 30 s | yes | max gap 2.0 s |
| First 3 min | 90% of gaps ≤ 7 s | 100%, about 200 actions |
| No wait over ~20 s in the first 10 min | ≤ 20 s | max 2.0 s |
| First transform | ~60 s | Brute at 57 s (52-61) |
| First big goal | 5-10 min | boss gate at 9.8 min (9.7-10.0) |
Numbers: height = 1.7 × (1 + Mass / 40)^0.24; Stomp Power 8 coins × 2.1 per level (+35% each); Shockwave 20 × 2.6 (max 4); Speed 12 × 1.7 (max 6); every 15th stomp is a Ground Pound worth x6.
**Honest limits of the bot:** it never gets lost and never stops, so real kids will be slower (plan for 1.3-1.5x). It counts stomps as "something to do"; the gaps between NEW things are longer (nothing new from 3.0 to 4.7 min and from 6 to ~9 min). Fill those with a mid-district mini event or an aura unlock before the first build. Re-run on the LIVE config before any launch (Galaxy lesson, K03).

## 8. Money (owner rules: ≤ 449 R$, no paid random, no fake timers)
| Item | Price (draft) | Why |
|---|---|---|
| **Auto Stomp** | 399 | the hero "auto" pass (K04) |
| x2 Mass | 249 | classic; Muscle Legends sells x2 Strength at 349 |
| VIP (+25% Mass, gold tag, gold dust trail) | 299 | |
| +1 Aura slot | 199 | cosmetic stacking |
| Starter Pack (after the first boss only) | 39 | first big moment; +1 Titan Evolution sells one at 19 |
| Time skips (Mass = 15 / 60 min of income) | 15 / 39 / 99 | scale with your stage |
| Offline x2 | 25 | impulse |
| Stomp shockwave skins, footprints | 49-149 | fixed price cosmetics |
Not copying: +1 Titan Evolution's 659 R$ titan (over our ceiling) and its dice/egg bundles (paid random); Muscle Legends' 499-799 passes; anything that helps in the Ring or the Rampage.

## 9. Collect + come-back hooks
- **Smash Index:** every kind of prop with a count and a max ("Houses 250/250 ✓"), % per district, a small permanent buff per completed row (K02 #8).
- **Golden props:** 1 in 200 props is golden (x25 Mass, a server toast). Earned only, never sold.
- **Titles** from big moments (first boss, Rampage MVP, crown held 5 min). Kept through AWAKEN.
- Offline Mass, a 7-day streak with one grace day, playtime gifts (5/10/20/40/60 min), a code per update, a monthly party with a free limited aura.

## 10. Tech notes (for the Claude Code prompt later)
- **Size is a display value plus a clamped real scale.** HEIGHT is a number (log growth forever). The character's real scale follows it on a log curve from 1x to about 10x across the whole game, and each district is built at a smaller scale than the last (Toy Town houses are 30 studs tall, Skyline towers are 30 studs tall too). A "zoom out" transition (FOV + flash) sells the jump between districts. This keeps physics, camera and streaming sane (same trick as the +1 SHRINK doc, mirrored).
- Props: one anchored MeshPart per prop + a pooled crumble effect (no physics debris on phones); server owns prop state and respawn; clients only play effects. Stomp requests are rate-limited by a token bucket (as in MEGA BITE's bite).
- 10-player servers. Rampage boss is one server-driven rig; a player controlling it sends only move + stomp inputs.
- Config: `GameConfig.Props`, `.Forms`, `.Districts`, `.Upgrades`, `.Rampage`, `.Crown`, `UIKit.Colors`. HUD from ONE approved phone mockup first (HEIGHT counter, Coins, NEXT bar, stomp button).
- **Shares most of its engine with +1 SHRINK** (a size number, districts at scale, a boss gate, a rebirth room, the collect index). Build that engine once.

## 11. Updates planned before the build (so it does not die like Titan Simulator)
Saturday 15:00 UTC, each with a code: W1 Harbour + Kraken Crane · W2 Skyline + Storm Titan form · W3 Mountains + Sumo Ring season 1 · W4 monthly party + Crystal form · then a district or a form every week, a bigger drop every 2-4 weeks, one no-release week a month (K08).

## 12. Honest check before saying yes
1. **This would be game number 4 in motion.** Galaxy still needs its fixes, MEGA BITE is mid-build, +1 SHRINK has a draft. Tonight's research says the makers moving on is what kills these games. One at a time.
2. **It sits in a crowded month.** +1 Titan Evolution is 5 weeks old with 1.9K players. Our edge has to be the crown + Rampage + the city, and it has to be visible in the first minute and on the thumbnail.
3. **It overlaps GYM ARC** (train, body grows, show off). That is useful: the lessons carry over. But read the GYM ARC shareholder deal first to be sure a body-growth game in P&L Studios XP is outside it, and reuse no GYM ARC assets (K10).
4. **Models:** 5 form kits + ~40 props + 2 bosses at the high-quality bar is weeks of art, like the 7 sharks.
5. **Reaching kids:** the Kids/Select gate is per game (250 engaged 16+ plays, K01).

## 13. First playable slice (when the owner says go)
Toy Town only: 12 prop kinds, forms 1-3 as kits, HEIGHT counter + NEXT bar, three upgrade pads, the crown + tags, one Rampage with the NPC titan. Then the impatient-kid sim on the live config, a phone test, and the debate-kids sim against +1 Titan Evolution and Muscle Legends before any art polish.

## Needs the owner
1. **Go or not, and when:** my pick is after MEGA BITE launches, and before +1 SHRINK only if you want it more (they share an engine, so the second one is cheap).
2. **Name (changed 11 Nov 01:24):** the owner said TITAN ARC "doesn't make sense like Titan Simulator". He is right: [[Playbook notes - Names and descriptions]] says a title works like a search box (plain words a child can type, the keyword early, the first ~12-15 characters readable alone), and "ARC" says nothing about the game. TITAN ARC stays only as the folder name until he picks.
   - **New proposal: `Titan Stomp Simulator`** (brand in two words: TITAN STOMP). Built like MEGA BITE: the goal (titan) + the action (stomp). "Titan Stomp" is 11 characters, so it survives the cut in friends lists, and the full title still matches the search words "titan" and "simulator".
   - Not the bare name "Titan Simulator": it is the 2017 game's exact name (it shows 2nd for that search, under +1 Titan Evolution), so ours would be one more look-alike with no word of its own to find it by a second time.
   - Checked 11 Nov: Roblox search for "titan stomp" shows no game with that name in the first 15 results. Still to do from the name-check list: exact-name search on the Games tab, a web search, a trademark search, and say it to a child.
   - Other options looked at: Stomp a City (names the loop, but drops the word "titan"), Become a Titan / Be a Titan (a "Be a Titan (AOT)" already exists), Grow a Titan (rides the crowded "Grow a" pattern).
   - **Owner 11 Nov 01:29: "our game is like evolutions more than titan but i also dont want +1".** So the title leads with evolution, not titan, and carries no "+1". **Current proposal: `Stomp Evolution`** (15 characters, fits the friends-list cut). It names the action and the payoff, and "Stomp" is a word of our own to be found by.
     - Checked in Roblox search (11 Nov): "[word] Evolution" with no "+1" is a live pattern: Bug Evolution 14K playing, Farm Evolution 6.6K, Capybara Evolution 1.8K, Brainrot Evolution 1.6K. No game named Stomp Evolution in the first 20 results for that search.
     - Second choice: `Giant Evolution` ("giant" searches return grow-and-size games, not anime). A "+1 Giant Evolution" exists with 0 players and 206 likes, so it is close to a dead game's name.
     - Not `Titan Evolution`: "+1 Titan Evolution!" is live with 1.7K players and a "Titan Evolution Simulator" exists; ours would read as their copy.
     - Honest note: dropping "+1" from the title does not take the game out of that crowd. Most of the 40 results for "evolution" are +1 games, and ours would sit in the same list. The icon and the first minute (a city to stomp, the crown, the Rampage) have to show the difference.
     - If the game is evolution-first, the forms carry the game: each one needs its own look, move and cutscene, and the HUD's NEXT bar should name the next form, not only the height.
   - Watch-out: most results for "titan" are Attack on Titan games (Attack on Titan Revolution has ~48K playing). The icon must show a blocky avatar giant in a bright toy city so nobody expects an anime game and bounces (K01).
3. **Own avatar + form kits** (my pick) or full titan characters.

## Sources (11 Nov 2026)
- Roblox search API: [titan simulator](https://apis.roblox.com/search-api/omni-search?searchQuery=titan%20simulator&sessionId=a1b2c3d4-0000-4000-8000-000000000001&pageType=all) · [giant simulator](https://apis.roblox.com/search-api/omni-search?searchQuery=giant%20simulator&sessionId=a1b2c3d4-0000-4000-8000-000000000002&pageType=all) · [grow big stomp](https://apis.roblox.com/search-api/omni-search?searchQuery=grow%20big%20stomp&sessionId=a1b2c3d4-0000-4000-8000-000000000003&pageType=all)
- Roblox games API: [new-wave games](https://games.roblox.com/v1/games?universeIds=10769541317,10766219563,10755740733,10773501077,9877481048) · [Muscle Legends, Titanus, Giant Simulator REBORN and others](https://games.roblox.com/v1/games?universeIds=10767341443,10769045617,1268927906,10140303758,4435906301)
- Passes: [Muscle Legends](https://apis.roblox.com/game-passes/v1/universes/1268927906/game-passes?passView=Full&pageSize=100) · [+1 Titan Evolution](https://apis.roblox.com/game-passes/v1/universes/10769541317/game-passes?passView=Full&pageSize=100)
- [Titanus Simulator page](https://www.roblox.com/games/89676960828878/Titanus-Simulator)
