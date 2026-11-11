# Ability Design for MEGA BITE (kids' Roblox shark eat-and-evolve game)

Scope: principles for abilities that feel powerful and fun, per-shark kits (Minnow DART, Piranha FRENZY, Barracuda TORPEDO, Reef Shark SHARK SENSE, Hammerhead HAMMER RAM, Great White BREACH, Megalodon TIDAL ROAR), feedback recipes, mobile button/cooldown UX, progression and unlock reveal. Constraints: kid-friendly, no paid power in PvP, current to Nov 2026.

Source-quality note: Riot (official dev blog), Overwatch wiki, Brawl Stars wiki, Hungry Shark wiki and the Strongest Battlegrounds guide are primary or wiki-level sources for game mechanics. Game-feel numbers come from one Unreal tutorial (starting values, not an industry standard). Marine-biology facts come from Natural History magazine, ScienceDaily, Wikipedia, an aquarium blog and Sea Watch Foundation. Anything without a source is in Inferences (design proposals) or Gaps.

---

## 1. Principles and checklists for designing abilities

### Takeaway
A great ability is (a) a clear power fantasy, (b) readable at a glance, with attention scaled to its importance, (c) telegraphed so the victim can react, so damage feels fair, (d) answerable (counterplay), and (e) charged or cooldown-gated so it is an event, not spam. Riot's clarity rules and Overwatch/Brawl Stars charge systems give the most concrete templates.

### Cited Findings
**Clarity and readability (Riot, League of Legends)**
- Clarity = "being able to understand what is happening in the game and respond to it", and it must hold even in chaotic moments — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Hitboxes must match the effects; a mismatch between what an ability looks like and where it hits is a major frustration source — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Hierarchy rule: "the amount of attention an ability grabs should match its level of importance". Importance comes from damage, crowd control (hard/long CC should stand out), dodgeability (dodgeable spells draw more attention, and visuals must not overstate how dodgeable they are), and impact on play — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Minimal noise: visual and audio clutter reduces reactability; big effects may be noisier "only to a degree" — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Telegraphing: audio cue ahead of impact (wind-up sound), bright saturated visuals for important abilities; projectiles should show travel direction even when stationary (blurred trailing end); use established shape language — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Failure example: Arcane Comet's large ground circle suggests more dodgeability than it really has — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Skins: skin abilities must be at least as clear as the base; skins "should not be pay-to-win or pay-to-lose"; cosmetic animations must never give a competitive advantage; test in chaotic teamfights and on every map — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Transformations: big or lasting transformations should appear only in empowered states (e.g. while an ultimate is active); near-permanent transformations that look like active abilities are discouraged — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)

**Telegraphing = fairness**
- The telegraph tells the player what is coming so the resulting damage feels fair; add "a small delay" before the attack so intent can be read — [Game Developer: Enemy attacks and telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)
- Projectile telegraphs typically stack cues: particles gathering (charge-up), a reverse "vacuum-cleaner" sound, a bright flash, then the projectile; channels can include animation, sound, voice-over, VFX and force feedback; simpler sets also work (sound + cocking animation + voice line) — [Game Developer: Enemy attacks and telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)
- In Psychonauts' Lungfishopolis boss fight the boss announces its attacks aloud while animation and effects play — [Game Developer: Enemy attacks and telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)

**Charge systems (earn the big moment)**
- Overwatch: ultimate charge = 5 points/sec passive + points equal to damage dealt / healing done; charge stops at the cost (no banking a second ult); no charge while ult is active; all charge spent on activation, not refunded if interrupted — [Overwatch Wiki: Ultimate ability](https://overwatch.fandom.com/wiki/Ultimate_ability)
- Overwatch: passive generation was added in the Feb 2016 beta to replace charge from damage taken; costs have been raised over time (e.g. +10% in OW2 Season 9); high cost doesn't mean slow if the hero generates charge fast (Moira) — [Overwatch Wiki: Ultimate ability](https://overwatch.fandom.com/wiki/Ultimate_ability)
- Brawl Stars Fang: Super recharges by landing hits (4 hits since Sept 2023, down from 5); misses of some attacks still charge it; star power "Fresh Kicks" instantly recharges the Super if it gets a kill — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)
- Brawl Stars: since Feb 2025, gadgets no longer have 3 charges and use cooldowns instead — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)
- Brawl Stars Hypercharge = a temporary empowered Super (Fang's goes through walls and leaves popcorn); all Hypercharges also give +20% speed, +5% damage, +5% shield (Oct 2025); Hypercharge duration can't be extended (Feb 2024) — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)
- Fang's Super can't dodge damage, stuns or slows while dashing (built-in counterplay) — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)

**Roblox battlegrounds "awakening" (ultimate mode)**
- The Strongest Battlegrounds: dealing damage fills the awakening gauge (standard 350 damage; some characters 200 or ~420–450), gauge is kept on death; hitting dummies fills less than hitting players unless you're alone — [rblxguide: TSB Awakening guide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)
- On activation: moveset switches to four stronger moves, speed increases, health restores (most characters), i-frames longer than the activation animation (most), unique music per awakening, activation animations (e.g. a roar that stuns nearby players) — [rblxguide: TSB Awakening guide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)
- Once active, the gauge drains as a timer: ~45 s on most (character pages give 42–53 s, one 86 s) — [rblxguide: TSB Awakening guide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)
- Monetization note: TSB sells an "Awakening Outfit" gamepass (99 Robux) that is cosmetic only (swaps your avatar outfit) — [rblxguide: TSB Awakening guide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)

**Hungry Shark Evolution precedent (the user's named reference)**
- Most standard sharks (Reef, Mako, Hammerhead, Tiger, Great White, Megalodon) have no special ability; their identity is stats (Reef slowest health drain, Hammerhead better boost, Tiger can eat inflated pufferfish, Megalodon big health but fast drain) — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Special sharks get abilities tied to the BOOST button: Electro Shark boosting electrocutes/paralyses nearby prey for double points; Ice Shark boosting freezes prey (2x points); Pyro's Dragon Breath triggered by boosting; Ghost Shark teleports through walls when boosting — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Evolved sharks: DarkHammer's "Ghost Pets" charge by eating prey, then 3 ghost sharks follow you and eat; Shar-khan's boost roar stuns prey in a cone (2x points) plus a bigger button-activated "Super Shout"; Lord Snappy's Mega Shout turns prey to stone; Zamaharibu's vortex pulls in distant enemies — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Gold Rush (a frenzy state) acts as the "ultimate" layer: e.g. DarkHammer's energy shield destroys prey on contact; Pyro's Meteor Storm; Abysshark stuns nearby targets — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Hungry Shark World's Meltdown Shark charges by eating prey then triggers a damaging speed burst; Hungry Shark Primal's Liopleurodon gets +50% bite bonus attacking from behind; Creto stuns what it runs into while boosting; Dunkleosteus damages what touches it — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)

### Inferences
**Ability design checklist (synthesised from the above):**
1. Fantasy in 3 words a kid would say ("I'm a torpedo!"). Name = verb the kid does.
2. One clear verb per button (dash, bite-chain, ram, breach, roar). No hidden rules.
3. Hitbox = visuals. If the VFX ring is 20 studs, the hit is 20 studs.
4. Attention hierarchy: Minnow DART small/quiet; Megalodon TIDAL ROAR is the loudest thing in the server.
5. Telegraph anything that hurts players: wind-up sound + visual gather + a ground/water decal for area hits. Kids need longer windows than adults (see section 3).
6. Counterplay for every PvP-damaging ability: dodge window, line of sight, a shield/escape ability, or a safe zone.
7. Earn-it gating: big abilities charge by eating (the core loop), not only by time — copies Overwatch/Brawl Stars/TSB/DarkHammer. Keep a small passive trickle so new/weak players still get their moment (Overwatch's reason for passive charge).
8. Shared economy: eating = EXP + ability charge, so the ability reinforces the eat loop (Electro/Ice give 2x points on stunned prey — strong model for PvE abilities).
9. Can't bank: cap at full, no stacking two ults (Overwatch rule) to stop "save three ultimates and wipe the lobby".
10. Paid items are cosmetic only (VFX colour skins must keep clarity parity, Riot rule; TSB's paid outfit is cosmetic).
11. Transformation looks only during the ultimate (Riot rule) — e.g. Megalodon glows only during TIDAL ROAR.
12. Test it in a crowded 20-shark brawl, on every biome, and on a small phone.

**HSE lesson for MEGA BITE:** HSE's common sharks have *no* abilities, which is exactly the gap the user wants to fill ("abilities big sharks have that make small players want them"). Using HSE's pattern (ability attached to boost + bonus points on stunned prey + Gold Rush empowered state) matches the reference game while giving every tier an identity.

### Gaps
- I did not find a public GDC talk transcript with numeric ability-design rules from Riot/Blizzard/Supercell; Riot's clarity blog is the best primary source found. Brawl Stars gadget cooldown lengths are not listed on the wiki.
- No source found specifically on PvP fairness research for children; recommendations for kids are inferences.

---

## 2. Per-shark ability improvements, second abilities and ultimates

### Takeaway
Give each tier one signature "boost-style" active (the named ability) plus, from Barracuda up, a passive, and from Great White up, an ultimate charged by eating. Ground each in a real creature fact (cited below) so the fantasy feels "real but super". Size the power of each ability to its tier and give every PvP-impacting one a counter.

### Cited Findings (real-creature hooks)
- Mantis shrimp club moves "at more than fifty miles an hour" with peak acceleration over 10,400 g; a chitin spring + catch mechanism stores energy and releases it suddenly (~100x the power the muscles alone could make); the strike makes "quite audible pops"; cavitation bubbles form and collapse with pressures of thousands of psi and heat the vapour — [Natural History: Knockout Punch](https://www.nhmag.com/biomechanics/082071/knockout-punch)
- Mantis shrimp strike speeds measured 14–23 m/s; force "well over a hundred times" body weight; cavitation from exploding bubbles may help break snail shells, perhaps producing sound "and perhaps even light" — [ScienceDaily (2004)](https://www.sciencedaily.com/releases/2004/04/040421233921.htm)
- Electric eel: tens of thousands of electrocytes, up to 600 volts, to stun prey or deter threats — [Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/)
- Pufferfish inflates with water/air, sometimes to more than double its size, to deter predators — [Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/)
- Cuttlefish change colour, pattern and texture to camouflage, hunt and communicate; octopus releases ink clouds and camouflages; mimic octopus imitates lionfish, jellyfish, sea snakes — [Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/)
- Archerfish shoot water jets at prey; about a third of squid species are bioluminescent; brittlestars glow to startle predators — [Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/)
- Mako shark up to 74 km/h; sailfish "up to 110 km/h"; black marlin "reportedly" 129 km/h — [Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/); CONTRADICTED for sailfish by [Wikipedia: Sailfish](https://en.wikipedia.org/wiki/Sailfish): 2015–16 research puts top speed at ~10–15 m/s (35–55 km/h), measured hunting bursts ~7 m/s, never over 10 m/s. Treat the 110 km/h figure as a myth.
- Sailfish hunt by slashing their bill sideways through schools (injuring ~2 fish per attack; ~24% of attacks capture); they raise the sail during attacks, which reduces head movement and makes the bill harder for prey to detect; groups benefit from each other's attacks ("proto-cooperation", up to ~70 individuals) — [Wikipedia: Sailfish](https://en.wikipedia.org/wiki/Sailfish)
- Orcas deliberately strand on beaches to grab seals/penguins, riding waves in for speed and waiting for a big wave to carry them back; adult females teach juveniles — [Sea Watch Foundation](https://www.seawatchfoundation.org.uk/from-sea-to-shore-strand-feeding/)
- Game hooks: HSE Shar-khan's cone roar that stuns prey (2x points) + bigger "Super Shout"; Zamaharibu's pulling vortex; DarkHammer's ghost-shark pets; Liopleurodon's +50% bite from behind; Creto stuns on boost-collision — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Fang's chain-bouncing Super (bounces to an enemy within 7 tiles, up to 4 enemies) and instant reset on kill — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)
- TSB awakening roar that stuns nearby players at activation; 4 stronger moves + speed + music for ~45 s — [rblxguide: TSB Awakening guide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)

### Inferences (design proposals — numbers are starting points to playtest)

General structure per tier: **Active** (button, cooldown or charge) / **Passive** (always on, from tier 3) / **Ultimate** (charged by eating, from tier 6; tier 5 gets a "Gold Rush" style empowered state). Ult meter: fills from eating (main) + a slow passive trickle; capped; no banking.

| Shark | Fantasy | Active (named) | Passive | 2nd / Ultimate | Real/game inspiration | Counterplay |
|---|---|---|---|---|---|---|
| Minnow | "Too fast to catch" | **DART**: instant short zig-zag burst (~1 s) with 0.3 s of dodge-through (can't be bitten mid-dart). CD ~4 s. Leaves a bubble trail. | **School Shield** (upgrade): near 3+ NPC minnows, take less damage (hide in the school) | Upgrade "Double Dart" (2 charges) | Sailfish "proto-cooperation"/schooling; Fang's dodge-less dash inverted | Short range; predictable if spammed; CD visible |
| Piranha | "Swarm bite" | **FRENZY**: 4 s of rapid auto-bites (+bite speed), each bite on prey refunds 0.25 s CD. Red water ripple + chomp ticks. CD ~12 s. | **Blood Scent**: wounded prey glow faintly nearby | Upgrade: Frenzy chains to next prey within X studs (Fang bounce) | Fang chain Super; HSE 2x-points stun idea | Must stay in contact; easy to swim away from |
| Barracuda | "Living missile" | **TORPEDO**: 0.4 s wind-up (body pulls back like a spring, reverse-whoosh SFX), then a straight-line launch; first prey hit is crit-bitten. CD ~8 s. Hitting a rock/wall = bonk stun on self. | **Ambush**: +bite damage from behind (Liopleurodon 50% idea, smaller) | Upgrade: "Spring Strike" cavitation pop at end of torpedo (small stun ring) | Mantis shrimp spring-and-latch + pop + cavitation; sailfish raised sail = stealthy approach | Telegraphed line; dodge sideways; self-stun on miss |
| Reef Shark | "I can see everything" | **SHARK SENSE**: 6 s sonar pulse that outlines prey, food chests and hidden threats (bombs, bigger sharks) through walls/murk; tasty prey highlighted gold. CD ~15 s. | **Steady Hunter**: slowest hunger drain (HSE Reef identity) | Upgrade: "Ink Dodge" — octopus-style ink puff when hit hard (decoy + short blind for the attacker), long CD | HSE Reef slow drain; octopus ink; electroreception (see gaps) | Info only — no damage; enemies see a ripple when pinged (fair warning) |
| Hammerhead | "Battering ram" | **HAMMER RAM**: charged dash (hold up to 1 s, longer = farther) that knocks back and stuns (0.5–0.8 s) the first shark/prey hit; breaks rocks/crates/sea-bomb cages. CD ~10 s. Hitbox = the wide head. | **Wide Scan**: wider bite cone (hammer head) | "Shock Ram" upgrade: electric-eel crackle stun on the ram (Electro Shark homage) | Electro Shark boost-paralyse; Creto stun-on-collision; Fang Roundhouse Kick 0.5 s stun | Long, visible wind-up (head glows); stun short; no damage-through-shield |
| Great White | "The jump scare" | **BREACH**: dive, then rocket up and burst out of the surface; on landing, a splash ring stuns and pulls in prey below; huge camera moment. CD ~18 s. | **Apex Bite**: bigger bite on stunned targets | Empowered state **"Blood Rush"** (charged by eating): 12 s, +speed, every bite stuns small fish, gold VFX (HSE Gold Rush model) | Orca wave-riding/strand feeding (launch and return on a wave); great-white breaching (gaps) | Shadow + bubble column on the surface 0.6–0.8 s before breaching; dodge out of the ring |
| Megalodon | "King of the ocean" | **TIDAL ROAR**: 0.8–1.0 s wind-up (camera pull-back, low rumble, water sucks inward), then a cone/360° shockwave that stuns prey (2x points), pushes players back, and shatters sea-bombs. CD ~25 s or ult-charged. | **Titan Hide**: shrugs off small-fish nibble damage | **Ultimate "Abyss Awakening"** (eat-charged, ~20–30 s): world tint darkens, music change, bigger roar, vortex pull (Zamaharibu) of nearby prey, announce banner "A MEGALODON HAS AWAKENED!" server-wide | Shar-khan Super Shout; TSB awakening roar + music; Overwatch enemy-voice-line warning | Server-wide warning, telegraphed wind-up, PvP effect = knockback not instant kill; safe zone immune |

Extra ability pool (for skins of the same tier ability, events, or later sharks — keep cosmetic variants clarity-parity):
- **Electric eel "Volt Coil"** — boost leaves a crackle ring that paralyses prey (2x points) [Electro Shark + 600 V eel].
- **Pistol/Mantis "Cavitation Pop"** — tap releases a bubble that pops after 0.5 s with a flash and small stun.
- **Cuttlefish "Chameleon"** — 4 s invisibility, broken by biting; shimmer outline stays visible to nearby players (counterplay).
- **Anglerfish "Lure"** — glowing bulb attracts NPC fish toward you for 5 s (PvE only).
- **Octopus "Ink Bomb"** — cloud that blocks vision; attacker loses lock.
- **Puffer "Puff Up"** — briefly double size, spikes hurt biters; can't swim fast while puffed.
- **Archerfish "Water Jet"** — ranged knock of small prey out of hiding spots.
- **Orca "Pod Call"** — teammates nearby get +speed (party/friend play).
- **Whale "Whale Song"** — long-range ping that calls food schools to you; doubles as a party "regroup" ping.
- **Humpback "Bubble Net"** — circle-swim to create a ring that traps prey inside (skill expression).
- **DarkHammer-style "Ghost Pups"** — eat-charged; 3 small spirit sharks auto-eat nearby prey (PvE only).

PvP fairness rules for kids (proposed):
- Abilities that affect players = knockback/stun/slow, short; kills come from bites. No one-shot ability KOs.
- Stun cap: same target can't be stunned again for ~2 s (diminishing returns) — prevents stun-lock frustration.
- Big shark abilities must be dodgeable by small sharks (Minnow DART i-frames are the dedicated "escape tool" — the small-shark fantasy is "survive the Megalodon").
- Safe zone: abilities can't hit players inside; Megalodon ult can't be cast there.
- No paid ability, no paid cooldown reduction or ult charge. Robux sells VFX colour variants, trail, roar sound skins, emotes — and they must stay as readable as the default.

### Gaps
- No source fetched for: hammerhead electroreception (ampullae of Lorenzini), great white breaching at seals, pistol shrimp snap temperature/light ("shrimpoluminescence"), anglerfish lure, humpback bubble nets, whale song range, orca wave-washing seals off ice. These are widely reported but not verified in this pass; the designer should verify before using them in in-game "Fun Fact" text.
- No data on Feed and Grow: Fish ability specifics (not researched due to tool-call budget).
- All cooldown numbers above are proposals; no source gives correct values for this game.

---

## 3. Ability feedback recipes (anticipation, impact, recovery)

### Takeaway
Layer feedback in three beats: anticipation (gather particles + reverse/rising SFX + body wind-up + decal for area hits), impact (flash, hitstop ~0.04–0.07 s, short camera shake ~0.15 s, knockback, punchy SFX, number pop), recovery (trail fade, lingering ripple, short self-vulnerability). Keep light actions small and save hitstop and big shake for finishers and ultimates.

### Cited Findings
- Starting values for a hit (Unreal tutorial): hitstop = time dilation 0.05 for 0.07 s on the target only (global time unchanged); camera shake 0.15 s (blend in 0.02 s, out 0.08 s), pitch amplitude 1.0, frequency 25, scale 0.5 (0.25 to tone down); knockback 600 cm/s horizontal + 150 cm/s up; tune hitstop down to 0.04 — [uhiyama-lab: Making Hits Feel Good in UE5](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/)
- Feedback fires in order on the same frame: hitstop, then shake, then knockback — [uhiyama-lab](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/)
- Light attacks: small shake only; heavy blows add brief hitstop and bigger launch; keep normal attacks light and strengthen only the finisher — [uhiyama-lab](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/)
- Telegraph stack: charge-up particles gathering, reverse "vacuum" sound, bright flash, then projectile; channels: animation, sound, VO, VFX, force feedback (haptics) — [Game Developer: Enemy attacks and telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)
- Wind-up audio cue before impact, bright saturated visuals for important abilities, direction shown by blurred trailing end — [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Ultimate announcement: Overwatch plays distinct friendly vs enemy voice lines on ult activation, and charge-status lines at 0–89%, 90–99%, 100% — [Overwatch Wiki](https://overwatch.fandom.com/wiki/Ultimate_ability)
- TSB awakening: activation animation, unique music per awakening, i-frames covering the animation — [rblxguide: TSB Awakening](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)
- Mantis shrimp strike's "audible pops" and cavitation bubbles = natural SFX/VFX reference for TORPEDO/HAMMER RAM impacts — [Natural History](https://www.nhmag.com/biomechanics/082071/knockout-punch)

### Inferences
Recipe template (per ability; times are starting points):

| Beat | Minnow DART | Barracuda TORPEDO | Hammerhead RAM | Great White BREACH | Megalodon TIDAL ROAR |
|---|---|---|---|---|---|
| Anticipation | none (it's an escape; instant) — tiny tail flick | 0.3–0.4 s body pull-back, rising whoosh, sparkles gather at nose | hold 0–1 s: head glows brighter, rising hum, haptic tick on full charge | 0.6–0.8 s: dive, shadow + bubble column on surface, deep "whomp" build | 0.8–1.0 s: water pulls inward, low rumble, camera pulls back + FOV widen, enemy-heard roar build |
| Impact | swish + bubble burst, light FOV punch | crack/pop (mantis), white flash, hitstop 0.05 s, shake small | thud + crunch, hitstop 0.07 s, shake medium, knockback, stun stars | splash explosion, slow-mo 0.1–0.2 s at apex (local client only), shake big, spray particles, screen-edge water droplets | shockwave ring (decal = exact hitbox), bass boom, shake big 0.3 s, haptic heavy, prey flip "STUNNED x2" pops |
| Recovery | bubble trail fades 0.5 s | 0.3 s glide (vulnerable), bonk stun if wall hit | 0.4 s slow turn (vulnerable) | splash rings linger 1 s, shark re-enters water | 0.5 s ripple lingers, cooldown ring starts, banner fades |

Rules: one hitstop per action max; scale shake with tier; client-side slow-mo only for the caster (never freeze other players in multiplayer); reduce-motion setting that halves shake; haptics on mobile (Roblox HapticService) for full-charge and impact. Audio is half the impact — every ability needs a wind-up, impact and tail sound (per the user's stored preference to make their own sounds in Fish Audio).

### Gaps
- No authoritative kid-specific reaction-time data was gathered; the 0.6–1.0 s telegraph windows for big abilities are design judgement (longer than adult-PvP norms on purpose).
- Roblox HapticService support on specific phones not verified this pass.

---

## 4. Mobile ability button UX, cooldown display, combos and unlock reveal

### Takeaway
On mobile, use one big ability button beside the bite/boost thumb area with the ability's icon, a radial sweep darkening that unwinds as it recharges, a big remaining-seconds number, and a "ready" pop (flash + sound + haptic). The ultimate gets its own meter that fills from eating and turns into the icon at 100%. New abilities should be revealed with a short showcase moment and a free try.

### Cited Findings
- Cooldown button pattern: a radial progress overlay (counter-clockwise fill) over the icon whose value = remaining time / total; dark semi-transparent tint marks unavailable; a remaining-time label (one decimal, outlined for readability) shown only during cooldown; button disabled while cooling, re-enabled and label hidden when done — [KidsCanCode: Cooldown Button](https://kidscancode.org/godot_recipes/4.x/ui/cooldown_button/)
- Overwatch's ult meter sits bottom-centre, shows 0–99%, and turns into the ultimate icon at 100% — [Overwatch Wiki](https://overwatch.fandom.com/wiki/Ultimate_ability)
- Overwatch charge-state voice lines ("charging", "almost ready" at 90–99%, "ready") — [Overwatch Wiki](https://overwatch.fandom.com/wiki/Ultimate_ability)
- TSB: ultimate gauge fills by damage, persists through death, then drains as a visible timer while active — [rblxguide: TSB Awakening](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)
- HSE: abilities on many special sharks are tied to the existing boost button, keeping controls simple; Shar-khan adds a separate button for the bigger Super Shout — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Brawl Stars combo/upgrade layering: Super + gadget (cooldown) + star power (passive) + Hypercharge (empowered Super) — [Brawl Stars Wiki: Fang](https://brawlstars.fandom.com/wiki/Fang)

### Inferences
**Mobile layout (right thumb arc):** BITE (biggest, bottom-right) → BOOST (above-left) → ABILITY (above bite, ~1.2x boost size, ability icon) → ULT (appears only when unlocked, top of arc, pulsing gold ring when ready). Left side = swim joystick. Minimum tap target ~ thumb size; ability button never under the joystick thumb.

**Cooldown display:** radial sweep (dark → clears clockwise), big centred number only when ≥ 1 s left (integers for kids, not decimals), "ready" = white flash + pop SFX + light haptic + icon bounce; pressed-while-cooling = small shake + soft "nope" sound (teaches the rule). Ult meter = ring around the ult button filling with water/blood colour; at 90% it shimmers; at 100% announce "TIDAL ROAR READY!" with sound. Enemies hear a distinct cue when a Megalodon ult is ready/used (Overwatch friendly/enemy idea).

**Combos (simple, kid-readable):** each tier has one "discoverable" combo shown via a hint tip: e.g. Hammerhead RAM → stunned target takes Great-White-style bonus bite; Reef SENSE reveals → TORPEDO crit; Megalodon ROAR stun → bites deal 2x. Show "COMBO!" text + bonus EXP pop. Keep combos optional skill expression.

**Progression/upgrades (no paid power):** each ability has 3–5 upgrade levels bought with in-game currency earned by eating (−CD, +radius, +duration, or one "evolution" twist at max like Double Dart, Shock Ram, Spring Strike). Abilities carry forward as you evolve? Recommend: each shark owns its signature; once a shark is unlocked permanently, its ability can be equipped as the "secondary" on later sharks at reduced power (keeps early sharks relevant and gives a collection goal).

**New ability unlock reveal (proposed recipe, ~3–4 s, skippable):** evolution flash → camera orbits new shark → ability name slams in with its own SFX → a 1.5 s ghost demo of the ability in-world → button appears on HUD with a glowing ring and finger-pointer "TAP TO TRY!" → first use is free (no cooldown) on a spawned prey school, with bonus EXP. Then a one-line tip card. Server chat/banner for rare tiers ("Aye just became a MEGALODON!") to make small players want it.

### Gaps
- No primary Supercell/Roblox mobile HUD guideline (thumb-zone sizes in px) was fetched; layout values are judgement.
- No source verified for best-practice unlock-reveal length on Roblox; Feed and Grow and Roblox RNG "cutscene reveal" patterns were not researched in this pass.
- No source found on Roblox policy regarding paid power in PvP specifically; "no paid power" is the user's constraint, supported by Riot's no-pay-to-win skin rule.
