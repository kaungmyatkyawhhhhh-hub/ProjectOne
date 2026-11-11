# Build MEGA BITE's ocean like a studio

To make MEGA BITE look as if a 20-person team built it with care, you do not need more content. You need **one consistent system applied everywhere**. Hungry Shark's fun comes from a hunger clock that never stops, with smaller goals stacked on top of it: a score multiplier, Gold Rush, missions, size-gated barriers and the next shark. Every bite moves several of those meters at once ([AppSpy](https://www.appspy.com/hungry-shark-evolution/review/); [Hungry Shark Wiki: Gold Rush](https://hungry-shark.fandom.com/wiki/Gold_Rush)). Its ocean feels alive because every hazard shows a warning before it acts, every hazard turns into food at a known size, and every hazard pays a reward once you can eat it. The puffer that inflates, then heals you for 15 HP when you finally can eat it, is the template ([Hungry Shark Wiki: Puffer Fish](https://hungry-shark.fandom.com/wiki/Puffer_Fish)). The world itself should follow the real ocean's depth ladder, which fiction already turns into an "underworld": sunlit to 200 m, twilight to 1,000 m, midnight, abyss, and the hadal trenches named after Hades ([WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)). Each zone gets its own light, fog, palette and hero landmark, so depth carries the progression and the mood. The polish layers have one rule in common. **Abilities, VFX, SFX and UI should all be built from anticipation, impact and a short fade, with attention matched to importance**, because "if everything is important, nothing is important" ([RealtimeVFX](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)). The research also overturns several earlier MEGA BITE assumptions. `Lighting.Technology` has been replaced by `LightingStyle` ([Roblox Docs](https://create.roblox.com/docs/reference/engine/enums/Technology.md)). Beams do not render behind Terrain water, which favours a fake air-filled ocean ([DevForum](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)). And the "sunburst behind the pop" in the earlier HUD plan breaks the owner's rule against sunbursts and must become a soft radial glow. Exact numbers from top studios are rarely published, so the timing and lighting tables below are starting values to tune on a real phone, not measurements.

## Hungry Shark runs on a hunger clock with nested meters around it

### The loop: one life, health as hunger, a soft timer that ends every run

A Hungry Shark run is a single life. **Health doubles as a stamina meter that drains constantly and is refilled only by eating.** The run ends at zero, whether from starvation, hazards or bigger predators. Pacing alternates calm swimming with feeding frenzies, and only a small part of the world is open at the start ([AppSpy](https://www.appspy.com/hungry-shark-evolution/review/)). Drain speeds up the longer you live. In Hungry Shark World, "late in the game, the toughest enemies stop progressing, and your health drains faster until you can't keep up" ([TV Tropes HSW](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)). Drain is also a per-shark balance knob: the Reef Shark drains slowest, while Megalodon and Big Daddy drain fast ([Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)). The studio, Future Games of London, rejected energy systems outright ("they just get in the way of the experience for us") and allowed long sessions on purpose ([MCV](https://www.mcvuk.com/development/studio-spotlight-future-games-of-london)).

The design consequence is that **food placement is the level design**. Standing still kills you, so sparse food near hazards creates tension and dense schools give relief. The rising drain works as a timer without needing an energy bar. Players do resent the late spike when it lands together with stacked attackers: one reviewer at about 300K score described being "repeatedly attacked by submarines, great whites and electro sharks" ([JustUseApp](https://justuseapp.com/en/app/535500008/hungry-shark-evolution/reviews)). For kids, MEGA BITE should ramp drain gently and signal it with a red edge pulse and a heartbeat sound. The earlier MEGA BITE design replaces death-ends-run with carried EXP that you bank. That still fits this loop: hunger pushes movement, and the carried EXP is what you stand to lose.

### The systems that make "one more run" irresistible

Hungry Shark stacks meters that run on different time scales. Hunger runs in seconds, the multiplier in tens of seconds, the Gold Rush bar in a minute or two, missions over a session, shark XP over several sessions, and the next shark unlock over days. Each mechanic is documented:

**Gold Rush.** The first one triggers at a per-shark point total, from 2,500 for the Reef Shark up to 500,000 for Pyro. Later ones trigger when the coin bar fills. During a rush **the shark is invincible, boost is unlimited, prey turns gold and pays coins, and dedicated music plays.** The multiplier scales by tier, from Reef 2x/16x up to 15x/120x for the top sharks ([Hungry Shark Wiki: Gold Rush](https://hungry-shark.fandom.com/wiki/Gold_Rush)). Because the trigger scales with shark size, every shark gets rushes at a similar pace. Reviewers single it out as the addictive part ([JustUseApp](https://justuseapp.com/en/app/535500008/hungry-shark-evolution/reviews)).

**Mega Gold Rush (Hungry Shark World).** After several rushes, a longer rush lets you eat any size of creature ([TV Tropes HSW](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)).

**Collectibles and missions.** HUNGRY letters scattered around the level supersize the shark when all are collected ([TV Tropes HSW](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)). Missions are revealed by finding shells in the world and cover score goals, targeted hunts and survive-with-multiplier challenges ([Ubisoft FAQ](https://ubisoft-mobile.helpshift.com/hc/en/8-hungry-shark-evolution/faq/76-what-are-the-missions-and-how-to-complete-them)). Each standard Hungry Shark Evolution shark has nine of them ([Hungry Shark Wiki: Coins](https://hungry-shark.fandom.com/wiki/Coins)). The biggest mission complaint is that targets are scarce exactly when you need them ([JustUseApp](https://justuseapp.com/en/app/535500008/hungry-shark-evolution/reviews)). **MEGA BITE should spawn mission targets near the player while a mission is active.**

**Size-gated barriers.** Hungry Shark World uses bone, stone, metal, blue stone, blue crystal and purple crystal walls, each breakable from a set size tier ([TV Tropes HSW](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)). Its Arctic map has surface ice that a medium or larger shark breaks by boosting into it, and the ice regrows ([Hungry Shark Wiki: Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)). Gates like these show progress in the world, not only in a menu.

**Portals.** Portals open timed mini-runs inside a run. A 3-minute timer drains and is refilled by eating local animals, and the run returns to the main level with full health ([Ubisoft FAQ: portals](https://ubisoft-mobile.helpshift.com/hc/en/8-hungry-shark-evolution/faq/78-how-do-the-portals-work)). This is a cheap way to add a fresh biome. Hungry Shark gated portals behind cooldowns and tickets that could be skipped with gems. MEGA BITE should use a free cooldown or a quest key instead.

**Bosses.** The Giant Crab is a dodge-three-pincers-then-bite-the-glowing-weak-spot fight. The Submarine can only be beaten by boost-ramming its front ([Latin Times](https://latintimes.com/hungry-shark-evolution-tips-get-megalodon-defeat-giant-crab-and-submarine-200354)). The game is still adding bosses in 2026: v14.1.0 (25 May 2026) added Roboshark 2.0, with missiles and pulse attacks ([APKMirror](https://www.apkmirror.com/apk/ubisoft-entertainment/hungry-shark-evolution-2/hungry-shark-evolution-14-1-0-release/)).

**Pets, accessories and daily rewards.** Baby sharks add stamina, from Baby Reef at +5 to Baby Megalodon at +30 ([Latin Times](https://latintimes.com/hungry-shark-evolution-tips-get-megalodon-defeat-giant-crab-and-submarine-200354)). Hungry Shark World pets have jobs: Polly the Octopus eats jellyfish ([TV Tropes HSW](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)). Accessories carry small stat bonuses and set bonuses ([PG.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)). A daily chest pays 100 to 400 coins over a four-day cycle ([Latin Times](https://latintimes.com/hungry-shark-evolution-tips-get-megalodon-defeat-giant-crab-and-submarine-200354)).

| System | Hungry Shark version | MEGA BITE version (proposal) |
|---|---|---|
| Hunger | Health drains, eat to refill, drain rises with time | Same; gentle ramp; red edge + heartbeat warning |
| Frenzy | Gold Rush: invincible, unlimited boost, golden prey, own music | PvE-only "Feeding Frenzy" meter filled by eating; 8–10 s eat-one-tier-up, golden prey, music swap |
| Letters | HUNGRY letters supersize you | M-E-G-A B-I-T-E letters per server life; supersize + bonus EXP |
| Missions | 9 per shark, found via shells | Shell-found quests; targets spawn near you while active |
| Gates | Bone → purple crystal walls by size | Coral, rock, wreck-metal, vent-crystal gates per tier |
| Portals | 3-min refill-by-eating timer biomes | Timed whirlpool biomes on a free cooldown, never paid skips |
| Bosses | Giant Crab (dodge 3, bite weak point), Submarine (ram the front) | Server bosses with readable patterns (see predators) |
| Pets | Baby sharks with stamina bonus | Remora/pilot-fish followers with one clear job |

### Fair versus unfair, and the kid-safe swaps

Hungry Shark sells coins and gems. Gems skip unlocks, buy premium sharks and buy revives. In Hungry Shark World, video revives are capped at two and the gem cost of a revive rises with each death, while costs grow faster than income at higher tiers, which is "the main hook" ([PG.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)). Players accept the system because there is no energy and the early game is smooth. They complain about gem prices ("the money for just a couple of gems is CRAZY!!") and about forced ads ([JustUseApp](https://justuseapp.com/en/app/535500008/hungry-shark-evolution/reviews)). Reviewers call the late game grindy ([Gamezebo](https://www.gamezebo.com/reviews/hungry-shark-world-review-sink-your-teeth-in/)). Hungry Shark Evolution shows blood on bites, which is part of why it is rated 8+ ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/hungry-shark-evolution)). Roblox's Mild rating allows only unrealistic violence, such as bodies vanishing at zero health ([Roblox Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)).

MEGA BITE should copy the loop and drop the pressure:

- **No blood.** Bites read as bubbles, sparkles and "CHOMP" text.
- **No eating humans.** Above-water prey becomes beach balls, floaties, rubber ducks and boats knocked over.
- **No escalating paid revives and no paid cooldown skips.**
- **Every core shark is earnable.**

Hungry Shark World's weakest point is its endgame: no multiplayer and little to do after the top tier ([PG.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)). That is exactly where Roblox-native features fit: the PvP Trench, a hunted crown, trading and limited event sharks.

## Every creature needs a tell, a flip tier and a reward

### The size-gated hazard ecosystem

Hungry Shark's sea is mostly food. A middle band of hazards punishes small sharks and becomes food once you reach a higher tier:

| Creature | Tell (warning) | Damage | When it becomes food |
|---|---|---|---|
| Puffer fish | Inflates when a shark comes close (in Evolution, the second time a shark passes) | 10 HP if a small shark bites it inflated | Tiger Shark and up. Pays 90 points and heals 15 HP ([Hungry Shark Wiki: Puffer Fish](https://hungry-shark.fandom.com/wiki/Puffer_Fish)) |
| Lionfish | Grows and spreads its venom spines when disturbed, calms when you leave; found in groups of 4–6 | **15 HP in one burst** (jellyfish drain over time instead) | Hammerhead and up ([Hungry Shark Wiki: Lionfish](https://hungry-shark.fandom.com/wiki/Lionfish)) |

The rest of the hazard roster, from the TV Tropes summary ([TV Tropes HSE](https://tvtropes.org/pmwiki/pmwiki.php/YMMV/HungrySharkEvolution)):

- Jellyfish that drain even large sharks.
- Stingrays that pause, then tail-sting.
- Anglerfish at depth.
- Seal pups that latch on and block eating.
- Mines whose knockback chains into other mines.
- Submarines with torpedoes.
- Pyro Shark, whose burn stops you eating.

Players call mines and subs "Demonic Spiders" (real threats) and the small hazards "Goddamned Bats" (annoying, not deadly) (same source). Readability is a lesson Hungry Shark learned the hard way. **A plain yellow puffer was confused with the green Gem Fish until the Gem Fish was redesigned** ([Hungry Shark Wiki: Puffer Fish](https://hungry-shark.fandom.com/wiki/Puffer_Fish)). Every role needs its own silhouette and colour.

Maneater makes the predator ladder clearer:

- **Prey:** easy wildlife lets new players "get their sea legs". Catfish are the quick emergency heal. Bigger groupers give more but are harder to eat.
- **Threats:** the muskellunge hisses (an audio warning), lunges, then flashes when it is vulnerable.
- **Area boss:** the Apex Alligator. Beating it unlocks an evolution.
- **Toy prey:** the turtle is food you can also play with. Hold it and fling it with a tail-whip.

Source: [Xbox Wire](https://news.xbox.com/en-us/2020/05/22/6-creatures-meet-then-eat-maneater-xbox/).

Put together, each MEGA BITE hazard needs four parts:

1. A visible and audible warning before it acts.
2. One damage style.
3. A size tier at which it flips from hazard to food.
4. A reward for eating it once you can.

The damage styles should stay distinct so kids can read them: burst (lionfish), damage over time (jellyfish), latch that blocks eating (seal pups), and knockback (mines). The fourth part is what makes small players want the next shark: "then I can eat puffers."

### A creature roster by tier

The table below is a design proposal. The roles and mechanics build on the cited patterns. Sizes and behaviours not linked to a source are general marine knowledge, and **must be checked before they appear in any Fish Index text**. Each prey silhouette is chosen to be instantly different from the others: a round puffer, a flat ray, a long eel, a many-armed octopus, a tall-finned sailfish and a hammer head.

| Tier band | Creatures | Role and mechanic |
|---|---|---|
| 0–1 food (reef, shallows) | Sardine/anchovy bait balls, clownfish, blue tang, damselfish, parrotfish, butterflyfish, crabs, flying fish | Value comes in small chunks for chain-eating. Clownfish dart into anemones as a safe spot. Crabs pinch at tier 0 and become food at tier 1. Flying fish give a jump-catch bonus. |
| 1–2 small hazards that flip to food | Puffer, lionfish, moon jelly, stingray, sea urchin, moray eel, octopus, squid, barracuda | Puffer bounce-back, lionfish burst, jelly tingle (damage over time), stingray pause-sting, moray lunging from rock holes, octopus ink that blinds the screen, barracuda hovering still and then bursting forward. |
| 2–3 rival hunters | Reef sharks, hammerhead schools, mako, tiger shark, sailfish, giant grouper, sea lions | Size-relative AI: chases smaller players, flees bigger ones. The sailfish flashes its stripes before charging. Sea lions are agile prey that is hard to catch. |
| 4–5 apex and bosses | Great white, orca pod, saltwater crocodile, giant squid, sperm whale, Megalodon, prehistoric event bosses | Area bosses with a wind-up, dodge and counter pattern (Maneater). The orca pod is a group boss. |
| Gentle giants (never food) | Whale shark, manta, humpback, sea turtle, blue whale silhouette | Moments of awe, and a moving safe aura. |
| Deep sea | Anglerfish, lanternfish, viperfish, gulper eel, vampire squid, dumbo octopus, giant isopod, goblin/frilled/Greenland sharks | Lure traps, glowing food schools, rare "living fossil" collectibles. |

A few real facts are sourced and safe to build on. The great white is the largest predatory fish, averaging 4.5 m, with females over 6 m and up to 2.5 tonnes, and it eats seals, sea lions and turtles. The striped marlin bursts up to 80 km/h and flashes iridescent blue stripes when excited. The bigfin reef squid reaches full size in about four months and changes colour for camouflage. Pilot fish swim with sharks and keep them clean ([Penguin Kids](https://penguin.co.uk/articles/childrens-article/facts-about-sea-creatures-for-kids)). Pilot fish make a ready-made cosmetic follower for big players.

One popular "fact" is a myth. **The sailfish's "110 km/h" top speed is wrong.** 2015–16 research measured about 10–15 m/s at most, with hunting bursts around 7 m/s ([Wikipedia: Sailfish](https://en.wikipedia.org/wiki/Sailfish)). The real sailfish behaviour is more useful anyway. Sailfish slash their bills sideways through schools, raise the sail during attacks, and hunt in loose groups of up to about 70 that benefit from each other's strikes (same source).

### Gentle giants and the deep

The whale shark is the strongest gentle-giant pick. It is the largest fish, at a longest widely accepted length of about 18.8 m. It eats krill, fish eggs and small fish through a throat about the size of a baseball. Its spot pattern is unique, like a fingerprint, and more than 17,000 individuals have been identified that way. Its skin is up to 15 cm thick, the thickest of any animal. It has dived to about 1,978 m, and it is harmless to people ([Marine Megafauna Foundation](https://marinemegafauna.org/whale-sharks/facts)). Hungry Shark turned it into a villain, the "Evil Whale Shark" ([Hungry Shark Wiki](https://hungry-shark.fandom.com/wiki/Evil_Whale_Shark)). MEGA BITE should do the opposite and make the whale shark a never-edible friend. Small players swimming beside it could get a protective aura, which ties into the safe-zone design.

Deep-sea creatures sell the dark zones through light. **About 80% of open-water animals make light, and that light is usually blue because blue travels best through water; red is "only very occasionally" seen.** Animals use it for belly lights that hide their silhouette, anglerfish lures, searchlights by the eyes, and startle flashes or glowing decoys ([NOAA Ocean Explorer](https://oceanexplorer.noaa.gov/explorations/15biolum/background/biolum/biolum.html)). Each of these is a ready-made mechanic. An anglerfish lure can pull food toward you, and a vampire-squid glow cloud can replace ink. The vampire squid has the largest eyes for its body size, and the barreleye looks upward through tube-shaped eyes ([Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)). Both make good rare Fish Index entries.

### Behaviour is what makes the sea feel alive

Fish schools should run on boids, Craig Reynolds' 1986–87 flocking model, which is the standard way to drive ambient wildlife, sea creatures included ([O'Reilly: AI for Game Developers ch. 4](https://oreilly.com/library/view/ai-for-game/0596005555/ch04.html)). Each fish steers by four rules: separation, alignment, cohesion and obstacle avoidance. To those, MEGA BITE should add a strong flee vector away from any bigger shark inside a fear radius. Raise cohesion when a predator approaches and the school squeezes into a bait ball that opens a hole around the shark, which looks spectacular at very little cost.

Abzu is the reference for crowd scale. Its schools of "tens of thousands of fish" are driven mostly by material maths and morph targets rather than skeletons, and the team "balanced noise against readability" across fish, kelp and particles ([80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)). On Roblox, the earlier MEGA BITE research found a demo running 10,000 NPCs at 55–60 FPS on an iPhone 8 Plus. The server sends bit-packed positions and clients interpolate them on single meshes ([DevForum](https://devforum.roblox.com/t/10000-physical-npcs-running-with-60-fps-on-low-end-device/3660293)). So the schools should be simulated on the client, the server should decide which fish was eaten, and far-away schools should update less often.

Idle life fills the gaps between fights: fins flutter, gills pulse, eels breathe in their holes, crabs wave their claws, rays flap, octopuses shimmer through colours, jellyfish bells pulse and seahorses bob. Endless Ocean Luminous was panned because its sea life barely reacted to the player ([Siliconera](https://www.siliconera.com/review-endless-ocean-luminous-is-a-shallow-dive-into-a-disappointing-sea/)). In MEGA BITE, schools must scatter from big sharks, follow small ones, and freeze when a bomb goes off.

## Depth is the level design: five zones, one hero prop each

### The real ocean hands you a colour script

The ocean has five depth layers, and each one comes with its own colour mood and progression step:

| Zone | Depth | Light | Life and features |
|---|---|---|---|
| Sunlit | 0–200 m | Sunlight reaches only about 200 m ([WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)) | Most marine life. Coral reefs, seagrass and kelp forests ([Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)) |
| Twilight | 200–1,000 m | About 1% of sunlight reaches 200 m, too little for plants ([Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)) | No plants. Plankton migrate down by day. |
| Midnight | To about 4,000 m | Perpetual darkness ([WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)) | Animals make their own light |
| Abyss | 3,000/4,000–6,500 m (the two sources disagree, and WHOI's ranges overlap) | Constant dark and cold | Small, slow-growing animals |
| Hadal | 6,000–11,000 m | None | "Named after Hades, the Greek god of the underworld", and found only in trenches ([WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)). Life is "at its most sparse", a cusk eel has been found at 8,372 m, and pressure is about 1,000 times the surface ([Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)) |

Hydrothermal vents add colour at the bottom. A 360 °C black smoker is made mostly of iron and sulfur minerals and is covered in tube worms with red gills ([NOAA](https://oceanexplorer.noaa.gov/explorations/05lostcity/background/overview/media/fig2strawberry.html)).

Fisch, the owner's quality bar, already uses this ladder. Its deep Mariana area runs Volcanic Vents → Challenger's Deep → Abyssal Zenith → Calm Zone → Veil of the Forsaken, and it has a Brine Pool ([Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)).

For MEGA BITE, the colour script goes from bright to blue dusk to black with glowing points to near-empty, and ends at the underworld trench. The underworld, though, should be **kid-scary, not horror**: glowing ruins, a sleeping giant, and a rim-lit boss silhouette against a vent glow. Fear-based content raises the maturity rating.

### How top games guide players without a map

Four reference games use the same method. **Depth is progression, each zone has its own light, fog and colour, landmarks replace mini-maps, and each area has one memorable hero prop.**

- **Abzu.** The team found that "changing how far the player can see into the murk" strongly shifts the player's emotional state, and built custom volumetric murk for it. Composition and colour guide the player, and playtests aimed for exploring "without getting too lost" ([80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)).
- **Subnautica.** It puts resources in the deeper, more dangerous biomes, so "the only way up is down". It has no mini-map and relies on landmarks and beacons, and sound warns of danger before anything is visible ([FeedMe Design](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)).
- **Hungry Shark Evolution.** Its main map has named sub-areas, each with a hero prop: Skull Island with a giant carved stone skull, Crab Lair, Death Tunnel, Volcanic Jets and Angler Nest. Staying near the surface is "reasonably safe" ([Hungry Shark Wiki: Skull Island](https://hungry-shark.fandom.com/wiki/Skull_Island)).
- **Fisch.** Its whirlpool entrance is marked by a **pillar of light**, and its islands are named for their silhouettes ("The Arch", "Haddock Rock") ([Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)).

Applied to MEGA BITE, the proposed layout is a central safe shallow reef with deeper, more valuable rings around it. Each area is named and gets one hero prop:

- Skull Rock cave
- Sunken Galleon
- Kelp Cathedral
- Volcano Vents
- Sunken City ruins
- Trench Gate (the underworld entrance)

Above each zone entrance stands a glowing beacon spire, tall enough to see through the fog of the neighbouring zone.

### Prop and plant kits that read instantly

**Reefs** read through variety of coral silhouette. Reef science names the forms a modular kit should cover:

- **Branching:** tree-like.
- **Corymbose:** dense bushes, which shelter juvenile fish.
- **Digitate:** finger shapes.
- **Encrusting:** sheets over rock.
- **Foliose:** lettuce-like plates.
- **Laminar:** flat shelves.
- **Massive:** brain and boulder domes; *Diploastrea* can pass 3 m across.
- **Submassive:** columns and lumps.
- **Solitary mushroom:** discs on sand.
- **Tabulate:** table corals, with fish sheltering underneath.

Source: [New Heaven Reef Conservation](https://newheavenreefconservation.org/learning-resources/explore-topics/coral-growth-forms). Add sea fans set perpendicular to the current, anemones with clownfish, tube and barrel sponges, giant clams, urchins and seagrass strips.

**The single biggest anti-"AI-made" rule for reefs is to cluster coral into patches with sand gaps, never an even carpet.** Use a 70/20/10 split: filler, mid pieces, heroes. This is art-practice inference, not a sourced figure.

**Kelp** reads through its anatomy, from [CCBC Open Oceanography](https://opencontent.ccbcmd.edu/ccardona2023oceanography/chapter/11-5-kelp-forest-ecosystems/):

- **Holdfast:** a root-like anchor that shelters brittle stars, sea stars, anemones and sponges.
- **Stipe and blades:** the stem, with fronds growing off it.
- **Gas bladders:** these float the blades up to the surface and form a canopy. Giant kelp has many bladders; bull kelp has a single one at the top.

Kelp grows 2 cm to 1 m a day. Purple urchins overgraze it into "urchin barrens" when otters are absent, which gives a natural "bad patch" sub-zone (same source). Abzu animated its kelp procedurally with rope simulation and tidal forces ([80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)). On Roblox, the equivalent is segmented sway, with amplitude growing toward the tip and phase following one global current direction.

**Trenches and vents** read through:

- black chimney spires with heat-haze and black "smoke" plumes;
- orange mineral crusts and red-plumed tube worm bushes;
- glowing fissures and pillow lava;
- glass sponges on mud;
- a clean white whale-fall skeleton as the landmark.

### Wrecks, treasure and bones that tell a story without gore

Sea of Thieves makes every object look used and worn. Figureheads carry the story, such as a lion guarding coins or a scarred bear, and a skull half-buried in sand hints at history without any gore ([Sea of Thieves](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure)). Hungry Shark turned whole wrecks into levels, with Titanic Zone and the Galleon map ([Hungry Shark Wiki: Skull Island](https://hungry-shark.fandom.com/wiki/Skull_Island); [Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)).

For MEGA BITE, the rule is that **every hero prop answers "what happened here?" with 3–5 supporting props around it.** A galleon broken in two, with its mast lying on a diagonal, would sit among spilled cannons, a chest and a crab guarding it, with coral reclaiming the hull. Other good set pieces:

- anchors whose chains run up into the dark, which leads the eye to the surface;
- sunken-city columns, shark-god statue heads and rune doors that act as progression gates;
- whale ribcage arches and a megalodon jaw fossil the size of a gate.

Bones are bleached, rounded and stylised, with no flesh and no blood.

### Islands, beaches and the over-sea world

Stylised islands work through three things: bright saturated colour, a silhouette landmark visible from far away, and worn hand-made props ([Sea of Thieves](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure); [Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)). Hungry Shark World puts land areas and above-water prey on its maps, such as the Arctic village and military base ([Hungry Shark Wiki: Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)).

The transition from island to deep sea is a recipe (art-practice inference) in seven bands:

1. **Island top:** palms leaning toward the water, a pier, and a lighthouse or volcano as the silhouette.
2. **Beach:** warm white sand with a darker wet band at the waterline, a foam line, shells and driftwood.
3. **Shallows:** pale turquoise water with seagrass and strong caustics.
4. **Reef crest:** where coral density peaks.
5. **Drop-off wall:** sea fans on the wall face. This is the best "wow" view, so place it where players see it on their first swim.
6. **Open blue:** big silhouettes and fading god rays.
7. **Trench slope:** dark rock and a fog wall.

The surface itself is a world layer, with five pieces:

- breach splash rings and droplets;
- a bright rippling surface sheet seen from below;
- a fast colour-grade swap when crossing the surface;
- breakable ice or floating debris;
- above-water kid-safe prey such as beach balls, floaties and tipping boats.

### Streaming and instancing keep a dense ocean playable on phones

Roblox's streaming documentation gives the defaults and settings ([Roblox Docs: Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)):

- **Radii:** StreamingTargetRadius defaults to 1024 and StreamingMinRadius to 64. Test at the minimum.
- **Stream-out:** `Opportunistic` lets the client "aggressively garbage collect content".
- **Model streaming modes:** Atomic models stream whole. Persistent models never stream out, so use them sparingly.
- **SLIM LOD:** fills distant static models with cheap imposter meshes.
- **Model size:** keep each model under about 64 studs so it streams as a unit.
- **Teleports:** call `RequestStreamAroundAsync` before each one.

Build a small library of coral and kelp MeshParts and vary them with scale, rotation and colour tint. Turn off collision, touch and query on decoration, turn off shadows on small filler, and run all sway, particles and boids on the client with distance culling.

## Light falls off with depth, but the player's shark must not

### Real optics, and why Subnautica deliberately broke them

Water strips colour out of light with depth ([Univ. of Hawaii](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)):

- **Red goes first.** Red fish look nearly black at 20 m, and almost all red light is gone by 40 m.
- **Over half of visible light** is absorbed in the first 10 m.
- **About 1%, mostly blue,** reaches 100 m in clear tropical water.
- **A white torch on an object brings back its full colour.** This is the physical basis for a head-lamp "reveal" in deep zones.

Subnautica **removed the blue cast near the player** on purpose. Its team decoupled sunlight attenuation from the attenuation of reflected light "to match how divers perceive water, not physical accuracy". It also moved from fixed per-area values with timed fades to parameters that vary continuously across the world ([Game Developer](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)). That is the core lighting rule for MEGA BITE. **Distance gets darker and bluer, and the shark and nearby prey keep their colour.**

### The Roblox toolset changed in 2025–26

**`Lighting.Technology` (Voxel, ShadowMap, Future) has been superseded by Unified Lighting.** Unified Lighting is controlled by `LightingStyle` (Realistic or Soft) and `PrioritizeLightingQuality` ([Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology.md); [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md)). When `PrioritizeLightingQuality` is false, the engine keeps view distance as quality drops. When it is true, it keeps close-up shadows ([Roblox Lighting docs](https://create.roblox.com/docs/environment/lighting.md)). For an open ocean on phones, start with **Realistic and false**.

Atmosphere is shaped by six properties. Density hides distant objects. Offset sets the horizon silhouette. Haze, Color, Glare and Decay tint the distance, with Glare and Decay needing Haze above 0 ([Roblox Atmosphere](https://create.roblox.com/docs/en-us/environment/atmosphere.md)). Underwater, Terrain water follows the time of day, and **Ambient sets how dark night can get** ([DevForum](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)). Post-effects placed under the Camera show only to that player, which makes per-player zone grading possible ([Roblox post-processing](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)).

### Choose the fake air-filled ocean

Terrain water has hard limits:

- **Beams, BillboardGuis, SurfaceGuis and slightly transparent parts do not render behind Water or Glass** ([DevForum](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)).
- Developers complain about skybox colours bleeding into the water at dawn and dusk, and about a cap on visibility ([DevForum](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)).

Together these kill beam god rays, beam caustics and soft glows seen from inside the water. **The recommendation is therefore an air-filled "fake water" ocean**: custom swim physics, a surface plane mesh, Atmosphere as the underwater fog, and a camera ColorCorrection that switches on when the camera is underwater.

This reverses the earlier MEGA BITE report, which preferred Terrain Water partly because its swimming is visible to the server and harder to exploit. With fake water, the server must validate movement itself, with speed and position sanity checks. A one-day prototype of both models in Studio should confirm the choice before the world is built.

### Starting presets per zone

These are **untested starting values** derived from the documented properties. Every one must be tuned on a mid-range Android phone. The rule behind them is a **value key**: surface brightest, reef mid-high, open sea mid, deep low, trench lowest but with saturated accent lights. Each zone should look different even in a greyscale screenshot.

| Zone | Atmosphere Density / Color | Ambient / Brightness / Exposure | ColorCorrection Contrast / Sat / Tint | Bloom Int / Size / Thresh |
|---|---|---|---|---|
| Surface / beach | 0.30 / (199,226,255), Haze 1.2, Glare 0.6 | (110,120,135) / 3 / 0.2 | 0.12 / 0.15 / (255,250,240) | 0.6 / 24 / 1.6 |
| Bright reef | 0.38 / (90,200,215) | (95,140,150) / 2.5 / 0.3 | 0.18 / 0.25 / (230,255,250) | 0.7 / 20 / 1.4 |
| Open sea | 0.50 / (25,95,170) | (45,75,115) / 1.8 / 0 | 0.15 / 0.05 / (200,225,255) | 0.5 / 24 / 1.5 |
| Deep sea | 0.62 / (10,35,80) | (20,35,65) / 1 / −0.3 | 0.20 / −0.1 / (170,200,255) | 0.9 / 30 / 1.1 |
| Red trench (underworld) | 0.70 / (60,12,18) | (40,14,18) / 0.6 / −0.5 | 0.28 / −0.05 / (255,200,200) | 1.0 / 32 / 1.0 |
| Night overlay | Density +0.05, colour toward (15,25,60) | Ambient never below (30,35,60) | Sat −0.1 | Raise so emissives read |

The red trench is stylised, not physical, because real red light is gone by 40 m. Justify it in the fiction with lava vents or red bioluminescence. Keep the player shark lit with a cool rim light so it does not merge into the red.

The flat blue haze that makes amateur ocean games look dull comes from three mistakes: Density too high, saturation too low, and the same values everywhere. Avoid it in five ways:

1. Keep colour near the player.
2. Place warm accents (coral orange, yellow fish) in the reef.
3. Give every zone one bright value (sand) and one dark value (overhangs).
4. Rim-light silhouettes.
5. Use Contrast rather than lower Brightness.

### Caustics, god rays, rim lights and transitions

**Caustics.** The underwater-caustics recipe uses a panning texture at two scales, warped by noise. Caustics are sharpest near the surface and blurrier deeper, and the effect should be built in separate layers so each can be scaled down ([80.lv](https://80.lv/articles/working-with-underwater-caustics-in-real-time)). On Roblox, the reliable form is a tileable caustic `Texture` on floor parts with `OffsetStudsU/V` scrolling ([DevForum](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)). With fake water, two crossed beams widened into planes also work ([DevForum](https://devforum.roblox.com/t/water-caustics-creation-and-tutorial/2842131)). Scroll two layers in different directions at different speeds, so the light shimmers rather than slides. Drive them from one client loop, and fade them out below reef depth.

**God rays.** Above water, `SunRays` handles god rays. Below water in a fake ocean, they are soft Beams with LightEmission 1, LightInfluence 0, a transparency fading 1 → 0.7 → 1 along the length, and a slow sway.

**Making characters pop.** Use a Highlight on the local player and on boss sharks only, with outline only (FillTransparency 1, OutlineTransparency about 0.6–0.8). Use a pale cyan rim in warm zones and a warm white rim in blue zones. Roblox caps a client at **255 simultaneous Highlights** ([Highlight docs](https://create.roblox.com/docs/reference/engine/classes/Highlight.md)), and each visible Highlight costs a draw call plus a full-screen post-process ([DevForum](https://devforum.roblox.com/t/lights-camera-more-highlights/4061534)). In deep, trench and night zones, add a small head PointLight on the shark. That follows Roblox's own diver-light suggestion and the white-light colour reveal.

**Bioluminescence.** Use Neon or emissive surfaces plus Bloom with a low threshold in deep zones, so only the emitters glow. Keep real PointLights for hero props only.

**Zone transitions.** Roblox has no post-process volumes, so a client script blends presets:

- **Continuous blend:** lerp every frame, or every 0.1 s on phones, by camera depth between the two nearest presets, as Subnautica's world-varying parameters do.
- **Special biomes:** region checks for kelp or the trench, with 1.5–3 s Sine InOut tweens.
- **Surface crossing:** a deliberately hard 0.15–0.25 s switch with a splash, a short blur and an audio low-pass. That sells breaking the surface.
- **Trench descent:** a slow 4–6 s blend, with bioluminescent props lighting up one after another.

Readability must never depend on DepthOfField or SunRays, because some post-effects drop out at lower quality settings ([Roblox post-processing](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)).

## Abilities: one verb, one telegraph, one counter, charged by eating

### Principles from Riot, Overwatch, Brawl Stars and Roblox battlegrounds

Riot defines clarity as "being able to understand what is happening in the game and respond to it", even in chaos. Its rules for abilities ([Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)):

- **Hitboxes must match the visuals.**
- **"The amount of attention an ability grabs should match its level of importance."**
- Important abilities get an audio wind-up.
- Big transformations appear only during empowered states.
- Skins "should not be pay-to-win or pay-to-lose" and must stay as clear as the base.

Telegraphing is what makes damage feel fair. Add "a small delay" before the attack and stack the cues: particles gathering, a reverse "vacuum" sound, a bright flash, then the projectile ([Game Developer](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)).

Charge systems turn a big ability into an earned event:

| Game | How the big ability charges | Rules worth copying |
|---|---|---|
| Overwatch | 5 points per second passively, plus points from damage or healing done ([Overwatch Wiki](https://overwatch.fandom.com/wiki/Ultimate_ability)) | Charge stops at full, so a second ultimate can't be banked. Nothing charges while the ultimate is active. |
| Brawl Stars (Fang) | His Super recharges in 4 landed hits ([Brawl Stars Wiki](https://brawlstars.fandom.com/wiki/Fang)) | Hypercharge grants +20% speed. While dashing, Fang cannot dodge damage (built-in counterplay). |
| The Strongest Battlegrounds | Awakening fills from damage dealt (standard 350) and is kept on death ([rblxguide](https://rblxguide.com/games/the-strongest-battlegrounds/updates/awakening-guide)) | Activation brings a stun roar, four stronger moves, speed, healing and unique music for about 45 s. Its paid outfit is cosmetic only. |

Hungry Shark itself shows where the gap is. **Its common sharks have no abilities at all**; their identity is stats. Its special sharks attach abilities to the boost button: Electro paralyses prey for double points, Ice freezes it, Shar-khan's roar stuns in a cone and has a bigger Super Shout, Zamaharibu's vortex pulls prey in, and DarkHammer's ghost pets charge by eating ([Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)). MEGA BITE's per-tier signature abilities fill exactly that gap. They give small players the reason to want big sharks.

### The per-shark kit

The ability structure has three parts:

- **One named active ability per tier**, so every shark has one.
- **A passive from Barracuda up.**
- **An eat-charged ultimate from Great White up.** It fills mainly from eating plus a slow passive trickle, so struggling players still get their moment (Overwatch's reason for passive charge). It caps at full, so it cannot be banked.

The table is a design proposal. The cooldowns are starting points to playtest, not sourced values. The real-creature hooks are sourced: the mantis shrimp's spring-and-latch strike exceeds 10,400 g of acceleration and makes "quite audible pops" with cavitation bubbles ([Natural History](https://www.nhmag.com/biomechanics/082071/knockout-punch)). Electric eels reach up to 600 V and puffers inflate to more than double their size ([Bristol Aquarium](https://www.bristolaquarium.co.uk/blog/15-ocean-animals-with-superpower-abilities/)). Orcas deliberately strand themselves on beaches to grab prey, riding waves in and out ([Sea Watch Foundation](https://www.seawatchfoundation.org.uk/from-sea-to-shore-strand-feeding/)).

| Shark | Fantasy | Active | Passive / ultimate | Counterplay |
|---|---|---|---|---|
| Minnow | "Too fast to catch" | **DART**: about 1 s zig-zag burst, 0.3 s untouchable window, CD about 4 s | School Shield: take less damage when 3+ NPC minnows are near | Short range, visible cooldown |
| Piranha | "Swarm bite" | **FRENZY**: 4 s of rapid bites; each bite on prey refunds 0.25 s of cooldown | Wounded prey glow faintly | Must stay in contact |
| Barracuda | "Living missile" | **TORPEDO**: 0.4 s spring wind-up, straight launch, first hit is a critical bite; hitting a wall stuns yourself | Ambush: bonus damage when biting from behind | Telegraphed line; sidestep |
| Reef Shark | "I see everything" | **SHARK SENSE**: 6 s pulse that outlines prey, chests and hidden threats through murk | Slowest hunger drain (Hungry Shark's Reef identity) | Information only; pinged players see a ripple |
| Hammerhead | "Battering ram" | **HAMMER RAM**: hold up to 1 s to charge; knockback plus a 0.5–0.8 s stun; breaks crates and gates | Wider bite cone | Glowing head during the wind-up; short stun |
| Great White | "The jump scare" | **BREACH**: dive, rocket out of the surface; the landing splash stuns and pulls prey in | Bigger bite on stunned targets; eat-charged 12 s "Gold Rush" empowered state | Shadow and bubble column 0.6–0.8 s before the breach |
| Megalodon | "King of the ocean" | **TIDAL ROAR**: 0.8–1.0 s wind-up, then a shockwave that stuns prey (2x points) and pushes players back | Ultimate "Abyss Awakening" (about 20–30 s): world darkens, music changes, vortex pull, server banner | Server-wide warning; knockback, never an instant kill; the safe zone is immune |

A spare pool of abilities can serve events and later sharks:

- Volt Coil (eel)
- Cavitation Pop (pistol shrimp)
- Chameleon (cuttlefish, with a shimmer outline left visible)
- Lure (anglerfish, PvE only)
- Ink Bomb (octopus)
- Puff Up (puffer)
- Pod Call (orca, a party speed buff)
- Bubble Net (humpback)
- Ghost Pups (DarkHammer-style)

Several real-creature hooks were **not** verified this pass and need checking before they go into "Fun Fact" text: hammerhead electroreception, great white breaching, pistol shrimp light, and humpback bubble nets.

**PvP fairness rules for kids (proposals):**

- Abilities that hit players only knock back, stun or slow. Kills come from bites.
- The same target cannot be stunned again for about 2 s, which prevents stun-locks.
- Every big-shark ability can be dodged by a small shark, and DART exists to do exactly that.
- Nothing works inside the safe zone.
- No paid ability, no paid cooldown reduction and no paid ultimate charge. Robux buys only VFX colours, trails and roar-sound skins that stay as readable as the default.

### Feedback recipe and button UX

Every ability plays in three beats: **anticipation, impact and recovery.** One Unreal tutorial gives starting values for a hit ([uhiyama-lab](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/)):

- **Hitstop:** time dilation 0.05 for 0.07 s, on the target only.
- **Camera shake:** 0.15 s, with a 0.02 s blend in and a 0.08 s blend out.
- **Order:** hitstop, then shake, then knockback, all on the same frame.
- **Weight:** light attacks get a small shake only. Heavy blows add hitstop.

Smash Ultimate scales hit-freeze with damage and caps it at 30 frames. Electric hits get 1.5x ([SmashWiki](https://www.ssbwiki.com/Hitlag)). Sakurai keeps it shorter in multiplayer, because a third player can act during the freeze ([Source Gaming](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)).

For MEGA BITE that means hit-freeze of 0.03–0.05 s for light bites and 0.06–0.09 s for heavy hits, capped near 0.15 s. Hit-freeze is client-only, for your own hits, so other players' games never freeze.

| Beat | DART | TORPEDO | HAMMER RAM | BREACH | TIDAL ROAR |
|---|---|---|---|---|---|
| Anticipation | Tiny tail flick, instant | 0.3–0.4 s pull-back, rising whoosh, sparkles at the nose | Head brightens while held, rising hum, haptic tick at full | 0.6–0.8 s dive, surface shadow and bubble column | 0.8–1.0 s: water sucks inward, low rumble, camera pulls back |
| Impact | Swish, bubble burst | Pop, white flash, hitstop 0.05 s | Thud, hitstop 0.07 s, medium shake, stun stars | Splash burst, 0.1–0.2 s local slow-mo, big shake | Ring decal equal to the hitbox, bass boom, 0.3 s shake, "STUNNED x2" pops |
| Recovery | Trail fades 0.5 s | 0.3 s vulnerable glide | 0.4 s slow turn | Rings linger 1 s | Ripple lingers, cooldown starts |

**Cooldown display.** Use a radial overlay whose value is remaining time divided by total time, with a dark tint while unavailable and a remaining-time label shown only during cooldown ([KidsCanCode](https://kidscancode.org/godot_recipes/4.x/ui/cooldown_button/)). Show whole seconds for kids, not decimals. When the ability is ready, play a flash, a pop sound and a light haptic. A press while it is cooling gives a small "nope" shake. Haptics should use `HapticEffect`, because Roblox calls `SetMotor` legacy ([HapticEffect](https://create.roblox.com/docs/reference/engine/classes/HapticEffect)).

**Ultimate meter.** Copy Overwatch: the meter sits as a ring and turns into the ability icon at 100%, with "almost ready" and "ready" cues ([Overwatch Wiki](https://overwatch.fandom.com/wiki/Ultimate_ability)). Enemies hear a distinct cue when a Megalodon ultimate fires.

**Unlock reveal (proposal, about 3–4 s, skippable):**

1. An evolution flash.
2. The camera orbits the new shark.
3. The ability name slams in with its own sound.
4. A 1.5 s in-world demo of the ability.
5. The button appears with "TAP TO TRY!"
6. The first use is free, on a spawned school of prey.

## VFX: anticipation, a white-hot impact, then a short fade

### What separates professional effects from amateur ones

Every effect has to answer three questions: which ability this is, what it does, and how much impact it has. Riot rates each spell's importance from 1 to 10, separately for the caster, allies and enemies, and gives crowd control more visual weight than raw damage ([RealtimeVFX](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)). When Riot updates effects, gameplay fixes come first, readability and noise reduction second (it strips out fine texture detail), and theme last ([League dev blog](https://www.leagueoflegends.com/en-us/news/dev/dev-behind-the-scenes-of-vfx-updates/)).

The League style guide boils down to ten rules ([VFX Apprentice](https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips)):

1. One clear primary shape.
2. Scale with importance.
3. Avoid pure black and pure white.
4. Use glow to push contrast.
5. Use saturation to draw focus.
6. One dominant colour and one secondary colour, following conventions (heal green, frost blue).
7. Hand-painted shapes.
8. Believable motion.
9. Anticipation, a payoff on the expected beat, then time to take it in.
10. **Keep effects short, because lingering effects clutter the screen and hide other spells.**

Timing has three parts: wind-up, spike and fall-off. Rhythms faster than a heartbeat read as aggressive, so heals and positive effects should pulse under 60 BPM. The recommended workflow is to sketch the sounds first, block the effect in with simple shapes, lock the timing, and polish last ([VFX Apprentice: timing](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)). Drive the phases from gameplay events and make the anticipation length tunable ([80.lv](https://80.lv/articles/vfx-staples-shape-color-and-motion/)). Explosions should scale on a logarithmic curve, fast then slow, so the final size can be read and matches the damage area ([Game Developer](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)).

Before any effect ships, it should pass a ten-point check:

1. Can a kid name it from a one-second clip?
2. Does it have one primary shape?
3. One hero colour plus a white-hot core?
4. Warm or bright against the dark blue water?
5. Are all three phases present?
6. Is the fade shorter than feels natural?
7. Do size and brightness match the gameplay weight?
8. Are there never 4+ transparent layers stacked on screen?
9. Does it still read on Low graphics?
10. Does the sound land on the impact frame?

The amateur tells to avoid:

- rainbow effects with no dominant hue;
- emitters left running at a constant Rate instead of firing `:Emit()` bursts;
- flat size and transparency curves;
- effects that pop off with no fade;
- the same big explosion on every hit;
- noisy textures that shimmer at distance.

### Recipes for the shark game (starting values to tune)

The universal layer stack:

| Layer | Timing | What it contains |
|---|---|---|
| 1. Anticipation | 0.1–0.3 s | Inward-gathering particles (`ShapeInOut = Inward`), a squash of the shark, a rising sound |
| 2. Impact frame | under 50 ms | A white-hot core flash, the primary shape, an `:Emit(15-30)` burst of bubbles, hitstop, camera punch and sound |
| 3. Secondary | short | Expanding rings and bubbles with Drag 3–6, so they start fast and finish slow |
| 4. Dissipation | 0.3–0.8 s | Low-contrast puffs fading out |

On Roblox, `:Emit(n)` with the emitter disabled gives controlled bursts ([ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)). Higher ZOffset renders in front ([DevForum](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650)). `Squash` and `VelocityParallel` make streaks, and `VelocityPerpendicular` lays rings flat ([Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)).

**Bite (kid-friendly).**

- *Anticipation:* the jaw opens over 0.12 s while white streaks converge on the mouth.
- *Impact:* two white tooth-arc crescents snap shut over 2–3 frames, a white-to-hero-colour mouth flash, a bubble burst, and a "CHOMP" or "+XP" pop with a Back overshoot. The pop sits on a soft round glow, **never a spiky ray burst**.
- *The prey:* flashes white through a Highlight, squashes, and pops into bubbles and sparkles.
- *Camera:* an FOV punch of −3 to −5.

**Roar and shockwave.**

- *Anticipation:* a 0.3–0.4 s rear-back with the screen darkening slightly.
- *Impact:* a ring that scales out on Quint Out over about 0.35 s, with a second, thinner ring 0.05 s later (double rings read as power), radial streaks, and bubbles pushed outward.
- *Camera:* a low-frequency shake of about 0.3 s.
- The ring's final size equals the real radius.

**Dash and torpedo.**

- A cone-shaped speed shell around the nose.
- Fin trails with a 0.2–0.35 s lifetime.
- Squashed streaks and a bubble wake.
- FOV +8 to +12.
- Speed lines at the screen edges only.

**Ram.** The dash, plus hitstop of 0.08–0.1 s, a 16-frame impact-star flipbook and heavier debris. Knockback starts as the hitstop ends.

**Evolve (2.0–3.5 s, skippable after the first time).**

1. *Charge, 0.8–1.2 s:* inward spiral, the shark whitening, the background desaturating.
2. *Peak:* a brief near-white flash that hides the model swap.
3. *Reveal:* a pillar of light, 2–3 rings and hero-colour sparkles.
4. *Settle:* the name card appears and the new aura starts.

**Aura rarity tiers.** Escalate layers, motion complexity and brightness together, not colour alone, so colour-blind players can rank them too:

| Tier | Adds |
|---|---|
| Common | Soft motes |
| Uncommon | Slight glow |
| Rare | Orbiting particles, a pulse under 60 BPM |
| Epic | A shell glow |
| Legendary | Spiralling beams and flipbook energy |
| Mythic | Irregular event bursts and an animated gradient |

Auras sit behind the shark and never cover its face. Roblox creators build unique auras from animated meshes rather than built-in sparkles ([DevForum](https://devforum.roblox.com/t/how-do-yall-make-auras/1383893)).

**Pickups** bob and glow. On collect they scale to 1.3x in 0.06 s and then fly to the counter. **Level-up** is a rising ring, a 0.5 s light column and a "LEVEL UP" pop on a soft glow, all under 1.5 s. **Ambience** stays low-contrast and slow, so action effects stand out against it:

- marine snow from a camera-following emitter;
- bubble columns from vents;
- god rays;
- caustics.

**Camera** work is all client-side:

- **Shake:** a trauma-squared noise shake applied after the camera updates. Separate rotation shake reads better than big position shake.
- **FOV punches.**
- **Flashes:** infrequent and never strobing.
- **Slow-mo:** faked with `AdjustSpeed` and particle `TimeScale`, because global physics time cannot be slowed.

### Roblox limits that shape every effect

| Area | Limit or behaviour | Source |
|---|---|---|
| Particle rate | 400 particles/s per emitter on desktop, **100/s on mobile**; lifetime max 20 s; large overlapping particles cost fill-rate | [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) |
| Blending | LightEmission 1 is additive; Brightness only works when LightInfluence is 0 | same |
| Flipbooks | Grid layouts up to 8x8, 30 fps cap, may be disabled automatically on low-memory phones | same |
| Low graphics | Roblox thins particles automatically: one developer's splash showed about 15 particles normally and 1 on low | [DevForum](https://devforum.roblox.com/t/allow-us-to-disable-vfx-scaling-with-graphics-level/2301568) |

**Every important event therefore needs a non-particle layer as a safety net**: a mesh ring, a Highlight flash, a camera punch, a UI pop and a sound. Other rules for keeping effects cheap and visible:

- Check Beams and Trails at the lowest and highest Editor Quality Level ([Roblox: Beams](https://create.roblox.com/docs/effects/beams)).
- Avoid EditableMesh for core effects. It is gated by ID verification and permission requirements ([DevForum](https://devforum.roblox.com/t/editablemesh-and-editableimage-improvements/3818624)).
- Fake "shader" effects with scrolling textures, beam texture speed, tweened mesh scale and transparency, and flipbooks.
- Build every effect on the client, pool the parts, and have the server send only "bite happened at X".

## Sound: four layers, phone loudness, and a muffled sea

### Recipes for every big sound

Every professional impact uses four layers ([Violet Recording: impacts](https://violetrecording.com/how-to-make-impact-sounds/)):

| Layer | Content | Notes |
|---|---|---|
| Transient | A bright crack | "Lives mostly above 1 kHz" |
| Body | A tonal mid | Around 200 Hz |
| Sub | A single sine falling in pitch | 30–60 Hz, dropping over 200–400 ms |
| Tail | A dark reverb | On the body only; the sub stays dry |

Glue the layers with gentle compression and high-pass below about 25 Hz. **Trim game hits "to a few hundred milliseconds so repeated triggers don't fatigue."** Risers should follow an exponential curve "so most of the change lands in the final beat or two", peak exactly on the impact, then cut ([Violet Recording: risers](https://violetrecording.com/how-to-make-risers-and-sweeps/)).

Creature sound starts from animal sources. Tigers and lions give size and ragged aggression, and pigs and dogs make good bases. The Jurassic Park T-Rex reportedly came from a baby elephant. Breaths and lip smacks "stitch a creature together", and the most common director note is "it doesn't sound big enough" ([A Sound Effect](https://asoundeffect.com/creature-sound-design/)).

The design proposals built on these sources:

| Sound | Recipe | Length |
|---|---|---|
| **Bite / chomp** | Teeth-clack transient, a wet cartoon crunch for the body, a tiny sub only for big prey, and a bubble-pop tail. Make 4–6 variations played at random pitch ±5–10%, stepping up in semitones on combos. | ≤300 ms |
| **Kid-friendly roar** | A big low bellow (walrus, elephant or whale-like) with a pitched-down lion for texture, less 2–5 kHz rasp, no screams, a short upward pitch bend at the end, and an underwater low-pass with a bubble burst. Each bigger tier plays the same roar 2–4 semitones lower with more sub. | — |
| **Evolve** | A 1.5–2.5 s exponential riser, about 0.15 s of near-silence, a layered hit with a heroic major-key brass or choir tone, a rising shimmer tail, then a short roar from the new form. Duck the music under it. | 2.5–3.5 s |
| **Dash** | An underwater whoosh with a thrust thump at the start. | 300–600 ms |
| **Shockwave** | A reversed suck-in, then the impact, then a low-passed rumble and bubbles. | 1–1.5 s |
| **Pickup** | A bright chime that climbs a pentatonic scale on rapid pickups, so it never sounds sour. | 80–200 ms |

**UI sounds** follow their own rules ([Violet Recording: UI](https://violetrecording.com/how-to-design-ui-sounds/)):

- Taps last 30–150 ms. Chimes run up to about 500 ms, and most cues stay under 300 ms.
- Rising pitch means positive. Success is an upward major third or fifth, and errors are lower or falling.
- Build every cue from one synth patch with shared reverb, so the UI "sounds like one product".
- High-pass below about 120 Hz and tame 2–5 kHz harshness.

Pitch can also carry information. Overwatch's heal beam rises in tone as health fills ([PC Gamer](https://pcgamer.com/how-overwatch-uses-sound-to-pinpoint-threats-you-cant-see)).

### Getting usable sounds from Fish Audio on the first try

Fish Audio's SFX tool lets you adjust duration, guidance and steps, and download MP3 or WAV. **SFX generated on paid plans "include full commercial rights"** ([Fish Audio](https://fish.audio/sound-effects/)). Its guidance says the model reads action, material, environment and emotional tone. It advises being specific, asking for loopable output for ambience, generating several variations, layering them, and preferring WAV for games ([Fish Audio blog](https://fish.audio/blog/how-to-generate-sound-effects-with-ai/); [Fish Audio guide](https://fish.audio/blog/sound-effects-generator)). ElevenLabs' docs confirm the general rule: **one sound event per prompt works best; generate layers separately and combine them** ([ElevenLabs help](https://elevenlabs.io/docs/help-center/product/core-capabilities/sound-effects/how-do-i-prompt-for-sound-effects)).

The prompt template is one layer per prompt:

> "[one-shot | seamless loop], [duration] seconds, [action] of [source], [character], [space: underwater, close-mic, dry], no music, no voice, clean start, no background noise."

Asking for "dry" and "clean start" lets you add the shared reverb yourself and trim the attack. Generate 3–6 takes per layer, then build round-robins from the best ones. Never ship a single raw take. Synthesise the sub sine yourself, because AI generators are weak at tight sub-bass and clean transients.

The processing chain in Python runs in this order:

1. Trim the leading silence and fade the tail.
2. High-pass: 120 Hz for UI, 30–40 Hz for SFX.
3. EQ each layer into its frequency slot.
4. Add light saturation.
5. Glue-compress the layers.
6. Add the shared reverb for that sound family.
7. Match loudness within each family.
8. Limit peaks to ≤ −1 dBTP.
9. Export mono 48 kHz WAV for one-shots; keep stereo only for music and ambience.

Fish Audio's model name, maximum duration and exact parameter meanings are not documented publicly. Test them in the app.

### Mixing for phones and the underwater filter

**Loudness targets.** PlayStation's mobile target is **−18 LUFS ±2, with true peak at most −1 dBTP and loudness range at most 20 LU** ([Audiokinetic](https://audiokinetic.com/en/mastering-a-game-with-wwise-part1)). Real phone tests found that **around −16 LKFS is nearly the most phones will play before their own limiting kicks in** ([Audiokinetic blog](https://audiokinetic.com/en/blog/loudness-and-frequency-response-on-popular-smart-phones)). So aim for −16 to −18.

**Frequency response.** Phone speakers start to roll off at about 220 Hz (Android) to 400 Hz (iPhone 7 Plus) (same source). Bass therefore has to be implied by saturated harmonics in the 100–400 Hz range, and harsh 4–5 kHz content needs controlling.

**Priority, not volume.** Overwatch's mix boosts the sounds that matter (threats) instead of letting the loudest sound win ([PC Gamer](https://pcgamer.com/how-overwatch-uses-sound-to-pinpoint-threats-you-cant-see)). MEGA BITE's priority tiers:

| Priority | Sounds |
|---|---|
| P1 | Your own bite, danger warnings, evolve |
| P2 | Abilities and nearby bites |
| P3 | Pickups |
| P4 | Ambience |
| P5 | Music |

Ambience and music duck under P1 through a sidechained compressor, with a fast attack and a 300–600 ms release. Cap each sound at 2–4 simultaneous copies, stealing the oldest.

**Underwater filtering.** Low-pass world sounds underwater. Roblox's `AudioFilter` sample treats 500 Hz as "muffled" ([Roblox AudioFilter](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioFilter)), and `AudioEqualizer` is the documented tool for "muffling audio underwater" ([Roblox Audio effects](https://create.roblox.com/docs/en-us/audio/effects.md)). Keep the player's own bites and UI unfiltered, because readability beats realism.

**The ambient bed.** Subnautica's hydrophone recordings showed that real underwater sound has prominent frequent clicking ([Unknown Worlds](https://unknownworlds.com/news/underwater-sound-recording-subnautica)). Build the bed in layers:

- a low-passed pressure drone;
- sparse clicks;
- bubble one-shots placed in 3D;
- gentle distant whale calls every 20–60 s;
- a signature for each zone.

**The surface crossing.** Sweep the filter open over about 200 ms when breaching, with a splash and an air whoosh. Reverse it on diving.

### Music and the 2026 Roblox audio graph

Sackboy's score combined two techniques. Horizontal resequencing switches between loopable chunks as the player acts, and vertical layering fades stems (drums, bass, lead) in and out. Stingers give feedback for actions and collectibles ([Audiokinetic](https://blog.audiokinetic.com/how-to-use-interactive-music-to-score-gameplay/)). For MEGA BITE that means one key and tempo family per zone and four layers:

| Layer | Content | When it plays |
|---|---|---|
| L0 | Pad | Always |
| L1 | Bass and percussion | When moving or hunting |
| L2 | Lead | During a chase or frenzy |
| L3 | Boss drums | When an apex predator is near |

Stingers in the same key mark evolve, rare catches, level-ups and danger.

**The Roblox audio API** exited beta in September 2024 ([DevForum](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454)). Sounds wire from AudioPlayer to AudioEmitter, and AudioListener to AudioDeviceOutput ([Roblox Audio objects](https://create.roblox.com/docs/en-us/audio/objects.md)).

- `AudioEmitter` takes custom distance curves of up to 400 points ([AudioEmitter](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioEmitter.md)).
- `AudioCompressor` has a Sidechain pin for ducking ([AudioCompressor](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioCompressor.md)).
- `AudioLimiter` goes down to −12 dB ([AudioLimiter](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioLimiter.md)).
- SoundGroups are now "discouraged" ([Roblox Sound groups](https://create.roblox.com/docs/en-us/sound/groups.md)).
- Acoustic Simulation was marked out of beta on 22 Sep 2026. It costs resources and can drop out on weak devices ([DevForum](https://devforum.roblox.com/t/full-release-acoustic-simulation-emit-audio-with-presence/4307121)). Open water has little to occlude, so use it only in caves and wrecks.

The recommended graph:

1. Category faders: SFX, Creatures, UI, Ambience and Music.
2. A master compressor, then a limiter at −1, then the output.
3. A sidechain from P1 to the Ambience and Music faders, for ducking.
4. A low-pass on the world bus.
5. An `AudioPitchShifter` that drops one roar asset by tier.

## UI: one token system, one light direction, motion under 300 ms

### What reads as premium

Premium UI comes from **system consistency plus custom art**. The creators of Pls Donate and Pet Simulator 99 drew custom graphics for every button and menu. Those graphics are mostly ImageButtons layered with native frames, which is the main reason those games look distinctive ([DevForum](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)).

Reviewers name the same rules over and over ([DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)):

- **Outer corner radius = inner radius + padding.**
- Even padding on all sides.
- One consistent stroke size.
- Dark outlines, not white.
- A subtle top-light gradient on buttons.
- Button text at about 60% of the button's height.
- Design at a fixed resolution with one UIScale, never stretch Scale-only layouts.

Buttons need a visible border, rounded corners and a shadow, so they look physically pushable ([Indieklem](https://indieklem.substack.com/p/8-better-designed-buttons)). Supercell's stylised art keeps the base colours simple, deliberately "breaks PBR" for cleaner gradients, and keeps detail "subtle and very local" ([Adobe Substance](https://www.adobe.com/products/substance3d/magazine/supercell-helsinki-creating-stylized-content-for-clash-of-clans-and-clash-royale.html)). Clash Royale carries its brand on one bespoke chunky display font ([Fonts In Use](https://www.fontsinuse.com/uses/66357/clash-royale-mobile-game)). And unattractive UI makes the whole product look "cheap and poorly-made" ([PocketGamer.biz](https://www.pocketgamer.biz/pg-connects-london-the-untapped-artistry-of-ui)).

**The premium-slab recipe (synthesis), from back to front:**

1. A drop shadow, offset straight down.
2. A dark outer stroke.
3. A body fill with a top-light gradient.
4. A thin highlight along the top edge.
5. Content inside uniform padding.

**One light direction must govern every gradient, highlight, shadow and icon render.**

Before drawing any screen, write a token sheet: 3 radii, 2 stroke weights, 1 spacing unit, 4 text roles, an ocean palette (deep blue and teal windows), and warm accents (yellow, orange and green) reserved for primary actions and rewards. The earlier HUD research warned that Fredoka with a thick stroke alone has been called the house style of "soulless cashgrab simulators" ([DevForum](https://devforum.roblox.com/t/cartoon-style-ui-review/3617988)). So identity has to come from MEGA BITE's own ocean art: sea-glass rims, pearl studs and coral textures.

### Roblox tools, 3D icons and the reveal stack

Much of the slab can now be built natively ([Roblox Docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)):

- **UIStroke** supports gradients and two strokes per text. Do not tween its Thickness on text, because that flickers and costs performance.
- **UIGradient** has Radial and Conical types in beta.
- **UICorner** supports per-corner radii.
- **UIShadow** offers blur, spread and inset shadows.

**9-slice** custom frames keep their corners fixed at any size ([Roblox 9-slice](https://create.roblox.com/docs/ui/9-slice)). Use native modifiers for anything that will be recoloured (rarity, state) and 9-sliced painted art for hero surfaces.

**CanvasGroup needs care.** It renders blank once it passes a texture-memory cap, and needs a new texture whenever it resizes ([Roblox CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup.md)). Developers report it rendering black or not at all on some phones ([DevForum](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119)). Use it only for small fixed-size fades.

**Safe areas.** Interactive UI goes on `CoreUISafeInsets`, which avoids both notches and the Roblox top bar ([ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)).

**Icons versus 3D previews.** Pre-rendered icons beat ViewportFrames for quality and shading control. Use one consistent light rig so all renders match, and retouch them so they pop. ViewportFrames scale to big catalogues but look weak unless they are large ([DevForum](https://devforum.roblox.com/t/image-rendering-for-user-interface/265787)). So render every shark, skin and pet icon in Blender with one saved rig: key light top-left to match the UI, rim light from behind, 3/4 view, the same framing per category. Use a large ViewportFrame for the evolve and unlock reveal.

**Particles do not show inside ViewportFrames**, and neither do Highlights, so reveal sparkles must be 2D sprites, or real parts placed in front of the camera ([DevForum](https://devforum.roblox.com/t/is-it-better-to-use-viewportframe-or-camera-position-to-open-egg/2861023)).

**The reveal layer stack (synthesis), from back to front:**

1. A dim backdrop.
2. A slow, soft radial glow or light shafts in the rarity colour. **Never a spiky ring of rays; the owner has banned sunbursts everywhere.**
3. The ViewportFrame hero, scaling 0 → 1.15 → 1 while spinning.
4. Staggered 2D sparkle glints.
5. A shine sweep over the name plate.
6. A rarity text punch.
7. Confetti for epic tier and above.

Brawl Stars' Starr Drops start every reward at Rare and visibly "upgrade" through rarities, and the near-miss with Legendary drives replays ([Mechanics of Magic](https://mechanicsofmagic.com/2026/05/22/how-brawl-stars-rebuilt-chance-after-swearing-it-off/)). For kids, that pattern belongs only on earned rewards, never on paid random items.

### Motion timing table

No studio publishes its timing tables. The defensible baselines:

| Baseline | Value | Source |
|---|---|---|
| Fluent durations | Normal 250 ms, Fast 167 ms, Faster 83 ms; entering UI decelerates, exiting UI accelerates | [Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/design/motion/timing-and-easing) |
| Instant feedback | Under 100 ms feels instant | [Val Head](https://valhead.com/?p=2978) |
| Small changes | About 200–300 ms | same |
| Large motion | About 400–500 ms | same |
| Bounce and elastic | About 800–1200 ms, so they can settle | [web.dev](https://web.dev/articles/choosing-the-right-easing) |

A Roblox DevForum coin-fly bursts 5–15 coins outward over 0.5 s (Quad Out), waits about 0.25 s, then flies them to the counter over 0.8 s (Quad In), and the counter bumps as each coin lands ([DevForum](https://devforum.roblox.com/t/how-to-make-this-coin-ui-animation/1812608)). Zynga's Empires & Allies has two useful details: the HUD icon pulses about 30% larger over about 0.25 s when a reward lands, and uncollected rewards pulse once at 7 s, then four times quickly ([Game Developer](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)). A shine sweep tweens `UIGradient.Offset` from −1 to 1 over 1 s (Circular Out), twice, then rests 2.5 s ([DevForum](https://devforum.roblox.com/t/4-uigradient-animations-including-rainbow/557922)).

| Event | Duration | TweenInfo style |
|---|---|---|
| Button press | 0.06–0.08 s to UIScale 0.92 | Quad Out; starts within one frame |
| Button release | 0.18–0.25 s back to 1.0 | Back Out, or a spring (damping 0.5–0.6, frequency 4–5) |
| Window open / close | 0.25–0.35 s / 0.15–0.2 s | Back Out from 0.85 / Quad In |
| Tab switch | 0.15–0.25 s | Quint Out, content shifts 8–16 px |
| Grid stagger | 0.2–0.3 s per item, 0.03–0.06 s offset, total cap about 0.5 s | Back Out |
| Count-up | 0.4–1.0 s by size of gain | Quint Out on a NumberValue |
| Currency fly | Burst 0.4–0.5 s, fly 0.5–0.8 s; counter bump 0.1 s, then a 0.15–0.25 s settle | Quad Out / Quad In / Back Out |
| Toast | In 0.25–0.3 s, hold 1.5–2.5 s, out 0.2 s | Back Out / Quad In |
| Reward reveal | Anticipation 0.4–1.0 s, burst 0.1 s, settle 0.3–0.5 s | Back or Elastic Out; tap to skip |
| Idle breathing | 1.5–3 s cycle, scale 1 to 1.03–1.05 | Sine InOut with a random phase |

The `spr` spring library is worth using for anything that can be interrupted (hover spam, toggles), because a spring keeps its velocity where a restarted tween snaps ([DevForum: spr](https://devforum.roblox.com/t/spring-driven-motion-spr/714728)). Use UIScale rather than Size for punches, so layouts don't reflow. "Juice It or Lose It" is the canonical talk on game feel ([GDC Vault](https://gdcvault.com/play/1016789/Juice-It-or-Lose)), and the counterweight is that "it's easy to go overboard": stop once the interaction communicates enough ([dvdfu](https://medium.com/@dvdfu/practical-juicing-for-game-devs-efe9b06c246b)).

Rules to keep the motion in check:

- Animate only 1–2 idle elements per screen region, and only one loud one at a time.
- Give each animated element a random phase, so the screen never pulses in unison.
- Honour Roblox's Reduce Motion setting ([DevForum](https://devforum.roblox.com/t/introducing-accessibility-settings/2723187)).
- Stop idle loops when a GUI is hidden.

### UI sound

Every interaction gets a sound that matches its visual weight. Repeated sounds get a small random pitch shift. **Combos climb one semitone per step (PlaybackSpeed × 1.0595)** ([Game Developer: pitch shifting](https://gamedeveloper.com/audio/the-power-of-pitch-shifting)). Empires & Allies raises the pitch on each combo fill and **leaves auto-collected rewards silent**, so positive feedback goes only to the player's own action ([Game Developer](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)).

| Event | Sound |
|---|---|
| Press | Soft pop, 30–80 ms |
| Close | The same patch, pitched about 0.9x |
| Window open | 150–300 ms airy whoosh plus a pop when it lands |
| Error | A low two-note fall, never harsh |
| Coin arrival | One tick per coin, PlaybackSpeed randomised 0.95–1.05, rising a semitone per coin up to +12 |
| Count-up | Ticks capped at 15–25 per second, ending in a "ding" |
| Reveal | A riser, a hit, a sparkle tail; layers escalate with rarity |
| Level-up | A 1–2 s major fanfare |

Never play more than 3–4 overlapping copies of the same sound.

### Cheap tells and accessibility

The cheap tells are mostly inconsistency:

- mismatched radii, strokes and padding;
- text touching borders;
- many text sizes;
- white outlines;
- flat single-colour fills;
- clashing saturated colours;
- an off-centre X button;
- cramped icons;
- disabled buttons that give no explanation ([DevForum](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497); [Indieklem](https://indieklem.substack.com/p/8-better-designed-buttons)).

The AI-art tells that ChatGPT output needs cleaning of:

- drifting light direction between assets;
- mushy edges;
- fake baked-in text;
- noisy over-detail;
- random extra rivets;
- mismatched perspective.

The fix is to generate each family from one locked style prompt, recolour to the token palette, re-cut clean alpha edges, and set all text in-engine.

**Accessibility minimums:**

- **Touch targets:** 44×44 pt on iOS and 48×48 dp on Android, with about 8 px gaps ([Adrian Roselli](https://adrianroselli.com/2019/06/target-size-and-2-5-5.html)).
- **Text:** at least 18 px at 100 DPI on mobile, scaled linearly, with support for 200% scaling ([Xbox Accessibility Guidelines 101](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/101)).
- **Colour:** never carries meaning alone. The edibility outlines need shapes as well as colours, as the earlier HUD report found.

## Corrections to earlier MEGA BITE plans

| Earlier item | Correction | Why |
|---|---|---|
| Centre pops and evolve "with sunburst" (HUD report) | Replace with a soft radial glow, light shafts or a bubble ring | Owner rule (11 Nov 2026): no spiky sunburst anywhere |
| Any "Technology = Future" setting | `LightingStyle = Realistic`, `PrioritizeLightingQuality = false` to start | Technology superseded by Unified Lighting ([Roblox Docs](https://create.roblox.com/docs/reference/engine/enums/Technology.md)) |
| Terrain Water ocean (first research report) | Prototype an air-filled fake ocean with server-side movement checks | Beams and transparent parts do not render behind Water ([DevForum](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)) |
| "Sailfish 110 km/h" in any fact text | Use measured hunting behaviour instead | Speeds measured far lower ([Wikipedia](https://en.wikipedia.org/wiki/Sailfish)) |
| Highlight cap "31" | 255 per client; still use sparingly for cost | [Highlight docs](https://create.roblox.com/docs/reference/engine/classes/Highlight.md) |
| SoundGroup-based mixing | Audio API faders and a sidechain compressor | SoundGroups "discouraged" ([Roblox Docs](https://create.roblox.com/docs/en-us/sound/groups.md)) |

## Conclusion

The research shows that what makes a game look like a "20-person team made it" is **coherence across disciplines, not volume**. The same three-beat grammar of anticipation, impact and short fade should run through a puffer inflating, a TIDAL ROAR, a bite sound, a coin flying to the counter and a window opening. The same attention ladder decides how big each of them gets. When the depth zone, the fog, the music layer, the creature roster and the gate all change together at the Trench Gate, kids feel they have descended into the underworld without reading a word. A lone team can afford this because each layer is a rule, not a pile of assets: one creature template (warning, flip tier, reward), one zone preset table, one effect stack, one sound chain, one UI token sheet.

The weakest evidence is the exact numbers. No top studio publishes its timing, lighting or loudness presets for games like this, several Fish Index facts still need checking, and the air-filled versus Terrain water choice needs a one-day prototype. The fastest way to close those gaps is to build one vertical slice: the bright reef, its drop-off wall, the puffer and lionfish, the bite and DART, and the HUD. Put it on a cheap Android phone and judge it with the quality-nerd kid sim before scaling the recipes out to the other zones.
