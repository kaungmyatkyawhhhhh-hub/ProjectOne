# Ocean Habitats, Props and Plants for a Roblox Shark Game (MEGA BITE): Environment Art Research

Scope note: this covers real ocean zones and habitats, how well-known ocean games dress and guide their maps, storytelling props, island and beach transitions, and Roblox performance. Research was capped at about 25 tool calls, so several threads are only partly sourced. Anything not backed by a fetched source sits under **Inferences** (labelled as general art or ocean knowledge) or **Gaps**. Treat Inferences as design suggestions to check, not verified facts.

---

## 1. Real ocean depth zones: what life, props and light each has

### Takeaway
The ocean has five pelagic layers: sunlit (0–200 m), twilight (200–1,000 m), midnight (to about 4,000 m), abyss (about 3,000/4,000–6,500 m) and hadal (6,000–11,000 m, trenches only). Light drops to about 1% by 200 m and is gone by about 1,000 m. Below that, the only light is bioluminescence, which is mostly blue. That gives a ready-made colour script and progression ladder: bright, then blue dusk, then black with glowing points, then near-empty, then the "underworld" trench.

### Cited Findings
- Sunlit (epipelagic): surface to about 200 m. "Sunlight penetrates only to depths of about 200 meters." Water strongly absorbs light. — [WHOI Ocean Zones](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)
- Most marine life lives in the sunlit zone, including plants, algae, herbivores and carnivores. Coral reefs, seagrass and kelp forests "thrive in the shallows". — [Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)
- Twilight (mesopelagic): 200–1,000 m, "just beyond the reach of sunlight". — [WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)
- "Just one per cent of sunlight penetrates to 200m," which is not enough for photosynthesis, so there are no plants below this depth. Plankton migrate down by day to hide from sight-hunters. Iconic animals are the vampire squid, which has the largest eyes for its body size and traps "marine snow" on sticky filaments, and the barreleye, which has upward-pointing tubular eyes. — [Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)
- Midnight (bathypelagic): reaches about 4,000 m, "in perpetual darkness", and in many places extends to the seafloor. — [WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/). "No sunlight at all reaches" it. Animals make light chemically in special organs to communicate, hunt or deter predators. — [Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)
- Abyss (abyssopelagic): 3,000–6,500 m per WHOI, or "from about 4,000m" per Discover Wildlife. It covers both the seafloor and the water above it, "a realm of constant dark and cold". Animals are generally small and slow-growing because of cold and scarce food. — [WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/); [Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones). *The two sources' boundaries conflict, and WHOI's own ranges overlap.*
- Hadal: 6,000–11,000 m, "named after Hades, the Greek god of the underworld… occur only in trenches." — [WHOI](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/). Range given as 6,000–10,994 m, where life is "at its most sparse" and invertebrates dominate. A cusk eel was trawled from 8,372 m in the Puerto Rico Trench. Pressure at the deepest point is about 1,000 times surface pressure. — [Discover Wildlife](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)
- Bioluminescence is "usually blue because it travels best through water". It ranges from near-violet to green-yellow and is "only very occasionally red". About 80% of open-water animals make light, mostly fish, squid, jellyfish and comb jellies. Uses include belly lights that hide the silhouette (counterillumination), stalked lures (anglerfish), searchlight organs near the eyes, and startle flashes or detachable glowing decoys when touched. — [NOAA Ocean Explorer, Bioluminescence and Vision on the Deep Seafloor](https://oceanexplorer.noaa.gov/explorations/15biolum/background/biolum/biolum.html)
- Hydrothermal vents: a 360 °C black smoker at Main Endeavour (Juan de Fuca Ridge) is mostly iron and sulfur minerals and is covered in "vibrant colonies of tube worms with red gills". — [NOAA Ocean Explorer, Lost City / Strawberry Fields](https://oceanexplorer.noaa.gov/explorations/05lostcity/background/overview/media/fig2strawberry.html)

### Inferences (design use; colour values are suggestions)
- **Colour script by zone (suggested):**
  - Sunlit: turquoise to cyan water (#3FD0D8 to #2AA9D6), warm sand, saturated reef colours, strong caustics and god rays.
  - Twilight: desaturated teal-blue to navy (#1C5D8C to #123A66), fewer props, first glowing jellies, vertical "rain" of marine snow.
  - Midnight: near-black navy (#08142B) with fog close in. The world is lit only by blue, cyan and green glow points (jellies, lanternfish, anglerfish lures). Red animals read as dark, because red light is absent at depth (general oceanography; NOAA notes red light is rare).
  - Abyss: muddy grey-brown floor, sparse sea cucumbers, glass sponges and sea pens, pale "ghost" palette.
  - Hadal/underworld: the darkest zone, with trench walls, narrow vertical shafts and the strongest single accent colour (vent orange or eerie violet) for the boss arena.
- **Map translation:** depth equals progression. Each zone gets a different fog colour and distance, ambient level, particle type and prop silhouette family, so players feel the zone change without a UI label. This matches how Subnautica gates its biomes (section 3).
- **Kid-friendly tone:** fiction gives "underworld" its scale. The hadal trench can host glowing ruins and a giant sleeping creature, not gore. Keep the boss readable with a rim-lit silhouette against a glowing background.

### Gaps
- No sourced per-zone temperature or pressure figures, apart from the about 1,000× pressure at maximum depth.
- Marine snow appearance (flake size, density) was not sourced visually. Only its existence and its role as food are cited.
- Brine pools, whale falls and cold seeps were not researched in this pass.

---

## 2. Props and plants that make a reef, kelp forest or trench read instantly

### Takeaway
Reefs read through coral **silhouette variety**: branching, table, brain/massive, plate, finger and encrusting forms, plus soft corals and sea fans. Kelp reads through tall vertical stipes with gas bladders, a sunlit canopy at the surface and a holdfast-and-urchin floor. Trenches and vents read through vertical black chimneys, red-plumed tube worms, shimmering heat haze and steep walls.

### Cited Findings: coral shapes (for a modular prop kit)
Source for every coral form below: [New Heaven Reef Conservation, Coral Growth Forms](https://newheavenreefconservation.org/learning-resources/explore-topics/coral-growth-forms)
- **Branching:** tree-like ("dendritic"), long tapered branches that split regularly. Abundant on shallow, flat reef zones.
- **Corymbose:** dense, bushy, irregular "crazy" branching. Needs strong sun and current. A nursery for juvenile fish.
- **Digitate:** short, unsplitting finger branches. Spreads wider while height stays about the same.
- **Encrusting:** thin sheets that spread over rock instead of growing up.
- **Foliose:** thin plates in 3D shapes like foliage or lettuce, where sunlight is high.
- **Laminar:** thin horizontal shelves, in low wave action and clear water.
- **Massive:** dense spheres or hemispheres (brain and boulder corals). Slow-growing and forms the long-term structure. *Diploastrea* can exceed 3 m across.
- **Submassive:** irregular columns or lumps. *Porites* grows from about 2 m to 20 m deep.
- **Solitary (mushroom):** free-living discs on rubble and sand. Large patches mean a recovering reef.
- **Tabulate (table):** large flat tables at one height. Fish shelter underneath.

### Cited Findings: kelp
Source for every kelp point below: [CCBC Open Oceanography 11.5, Kelp Forest Ecosystems](https://opencontent.ccbcmd.edu/ccardona2023oceanography/chapter/11-5-kelp-forest-ecosystems/)
- **Holdfast:** a root-like anchor on rock. It shelters brittle stars, sea stars, anemones, sponges and tunicates.
- **Stipe:** the stem. **Blades** (fronds) grow off it.
- **Pneumatocysts:** gas bladders that float blades to the surface. Giant kelp has many. Bull kelp has a single bladder at the top of its stipe.
- Kelp grows about 2 cm to 1 m per day. Giant kelp lives up to 7 years.
- Kelp grows in cool, shallow, nutrient-rich coastal water. It is a brown alga.
- Sea otters eat purple urchins. Without otters, urchins overgraze kelp and leave an "urchin barren".
- Abzu animated its kelp procedurally with rope simulation and tidal forces. — [80.lv, Abzu creative director interview](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)

### Cited Findings: vents and deep floor
- Black smoker chimneys are made of iron and sulfur minerals, reach about 360 °C, and are covered with red-gilled tube worms. — [NOAA Ocean Explorer](https://oceanexplorer.noaa.gov/explorations/05lostcity/background/overview/media/fig2strawberry.html)
- Fisch's deep Mariana zone runs Volcanic Vents → Challenger's Deep → Abyssal Zenith → Calm Zone → Veil of the Forsaken. Desolate Deep includes a Brine Pool. This shows a top Roblox game already uses vents, trenches and brine pools as named depth tiers. — [Destructoid, Fisch map](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)

### Inferences: prop checklists (general reef, kelp and deep-sea knowledge; not individually sourced)

**Coral reef kit (sunlit, 0–30 m game-depth)**
- Hard coral silhouettes:
  - Staghorn/branching: sandy orange, lilac or pink tips.
  - Table coral: tan or green-brown top, darker underside.
  - Brain/massive: yellow-green or mustard, with a groove pattern.
  - Plate/foliose: rust, purple or green rings.
  - Finger coral: cream or yellow.
  - Mushroom coral: on the sand.
- Soft life:
  - Sea fans (gorgonians): purple, red or orange flat lace, always set **perpendicular to the current**.
  - Soft corals: pink or red tree shapes.
  - Sea whips.
  - Anemones (green, magenta or purple tips) with clownfish.
  - Tube sponges (orange, purple, yellow).
  - Barrel sponges (brown).
  - Giant clams (blue or teal lips).
  - Sea stars, urchins (black spines), sea cucumbers.
  - Seagrass meadow strips on sand flats.
- Ground: white or cream sand with ripple normals, coral rubble, boulders, sand channels between coral "bommies".
- Life layer: small reef fish schools (yellow tang, blue chromis, butterflyfish), turtles, rays gliding over sand.
- Composition rule: cluster corals into **patches with sand gaps**. Uniform carpets look procedural and "AI-made". Use a 70/20/10 mix:
  - 70% filler: small corals, grass, rubble.
  - 20% mid pieces: tables, fans, sponges.
  - 10% heroes: giant brain coral, an arch, a coral tower.

**Kelp forest kit (cool water, 5–30 m)**
- Tall kelp: stipe plus blades plus round bladders, 20–40 studs and more, reaching up to break the surface and form a **canopy mat** of floating fronds.
- Floor: holdfast clumps, rocky reef, purple urchins, red and orange sea stars, anemones, abalone shells.
- Fish: garibaldi (bright orange; general knowledge), rockfish, leopard sharks, sea otters at the surface, seals.
- Optional urchin barren: a purple-spiked bald patch as a "bad" zone.
- Light: green-gold shafts through the canopy and dappled shade. Water tint is greener than on the reef.
- Sway animation: rope-like chain bones, or several segmented parts with offset sine phases. Amplitude grows toward the tip, and the phase follows one global "current" direction (Abzu approach above).

**Twilight and midnight kit**
- Floating jellyfish (Beams or emissive Neon parts), siphonophore chains, lanternfish schools with dot lights, vertical marine snow particles drifting down slowly.
- Big shapes in the fog: whale silhouettes, a squid passing.

**Trench, vent and underworld kit**
- Black or charcoal chimney spires with shimmering heat-haze particles and black "smoke" plumes.
- Orange or yellow mineral crusts.
- White-shelled tube worm bushes with red plumes, white crabs, shrimp swarms, mussel beds.
- Glowing fissures, basalt pillow lava, steep cliff walls, narrow chasms.
- Glass sponges and sea pens on soft mud.
- A whale fall: a giant whale skeleton, kid-safe "bones", as a landmark.

### Gaps
- No sourced numbers on stylised prop density per stud². Density guidance here is art-practice inference.
- Coral colour values are not sourced. Real coral colours vary, and colour comes from zooxanthellae and pigments.
- No visual reference was pulled for soft corals, sea fans or sponges. The fetched coral page did not cover them.

---

## 3. How top games dress ocean maps, place landmarks and guide players

### Takeaway
Across Abzu, Subnautica, Hungry Shark and Fisch, the shared method is: **depth is progression; each zone has its own light, fog and colour mood; landmarks replace mini-maps; one memorable hero prop per area.** Visibility (fog distance) is a primary emotional lever.

### Cited Findings
**Abzu (Giant Squid, art director Matt Nava)**
- Light, colour and sound carry the story with no dialogue, building an emotional curve of lows and highs. The goal was a dreamlike ocean, not a scuba simulation. — [80.lv interview](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- "Changing how far the player can see into the murk" strongly shifts the player's emotional state. The team built custom volumetric murk and light rays. — [80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- Hundreds of species are simplified to their most iconic traits. Schools of "tens of thousands of fish" are driven mostly by material maths and morph targets, not skeletons. — [80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- With dense fish, kelp, particles, seagrass and coral, the team "balanced noise against readability". The stylised look keeps even small elements readable. — [80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- Composition, colour and detail placement guide the player. Playtests aimed for players to feel they were exploring "without getting too lost". Terrain was built from small editable patches. — [80.lv](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- The GDC 2017 talk "Creating the Art of ABZÛ" exists, but the fetched page held only the video, with no transcript. — [80.lv GDC 2017](https://80.lv/articles/gdc-2017-creating-the-art-of-abzu/?amp=1); [GDC Vault](https://gdcvault.com/play/1024409/Creating-the-Art-of-ABZ)

**Subnautica (Unknown Worlds)**
- Resources sit in deeper, more dangerous biomes, so "the only way up is down". The Safe Shallows are a calm place to linger. — [FeedMe Design](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- There is no mini-map. Players navigate by landmarks, beacons and their own sense of direction. Crafting needs guide them instead of objective markers. — [FeedMe Design](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- A slightly cartoonish style with "dazzling coral and glowing flora" softens the scary moments. — [FeedMe Design](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- Sound warns of danger before anything is visible: muffled ambience, clicks, roars. — [FeedMe Design](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- Official concept art posts exist for Kelp Forest and Coral Reef, but they were not fetched. — [Unknown Worlds, Kelp Forest concept](https://unknownworlds.com/news/subnautica-concept-art-kelp-forest); [Coral Reef 3](https://unknownworlds.com/news/subnautica-concept-art-coral-reef-3); GDC 2019 "The Design of Subnautica" — [GDC](https://gdconf.com/news/dive-deep-design-subnautica-gdc-2019)

**Hungry Shark World / Evolution (Future Games of London / Ubisoft)**
- Hungry Shark World has four main maps: Pacific Islands, Arctic Ocean, Arabian Sea and South China Sea. Special maps are Galleon, The Bay, Harbor and Boss Battle. — [Hungry Shark wiki, Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)
- Arctic Ocean details:
  - Sunset under a cloudy sky, purplish-blue water, thick surface ice sheets that break when a medium or larger shark boosts through them and regenerate over time.
  - Snowy Village and Military Base areas.
  - Hazards: mines, mega and ultra mines, toxic barrels, deep-sea subs, currents.
  - Props: junk, bottles, dollar bills.
  - Prey: seals, cod, narwhals, penguins, orcas, villagers and divers. The map icon is an igloo.
  — [Hungry Shark wiki](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)
- Hungry Shark Evolution's main map is split into named sub-areas: Skull Island (a giant carved stone skull, crates, and an "Electric Guitar" where Blobfish spawn to restore health), Crab Lair, Kempy Cave, Western Sea, Death Tunnel, Volcanic Jets, Angler Nest and Space. Separate maps are Arctic Land, Alien Planet, Shawaii and Titanic Zone (with the Titanic wreck). Staying near the surface is "reasonably safe" while depth holds the danger. — [Hungry Shark wiki, Skull Island](https://hungry-shark.fandom.com/wiki/Skull_Island)

**Fisch (Roblox; the user's stated quality bar)**
- Fisch uses a hub island (Moosewood) with themed islands around it:
  - Mushgrove Swamp: mushrooms, alligators, totem fog.
  - Roslit Bay: volcano and coral.
  - Snowcap: mountain and cave.
  - Ancient Isle: ruins and lighthouse.
  - Grand Reef: whirlpools and a pirate ship.
  — [Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)
- Vertigo is entered through a whirlpool marked by a **pillar of light**, a strong landmark-beacon pattern. Atlantis is a ruined underwater city that needs diving gear, with themed rooms (Zeus Trial, Poseidon Temple, Ethereal Abyss). Mariana sits under Roslit Bay with five deepening zones and submarine depth upgrades. — [Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)

**Sea of Thieves (Rare)**
- Brushmarks and an illustrative look. Islands are bright and vibrant, with a distant rock formation that "invites exploration". A skull in the sand hints at a dark past. Every item has "a sense of history" and looks worn. The palette shifts with mood (eerie green mist for ghosts). — [Sea of Thieves, A Closer Look at the Art of Adventure](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure)

### Inferences (applied to MEGA BITE)
- **Layout:** a central safe shallow reef (the spawn and slow-levelling zone Zev proposed), with deeper, more lucrative rings around it and a PvP zone. This mirrors Subnautica's "down for value" and Hungry Shark's "surface safe, depth dangerous".
- **Named sub-areas with one hero prop each,** like Hungry Shark's Skull Island skull:
  - Skull Rock cave
  - Sunken Galleon
  - Kelp Cathedral
  - Volcano Vents
  - Trench Gate (the underworld entrance)
  - Sunken City ruins
- **Beacons:** a light pillar or tall glowing coral spire above each zone entrance (Fisch's whirlpool pillar), visible through fog.
- **Breakable surface elements** (Arctic ice sheets) reward size progression in the environment itself.
- **Fog as mood:** shallow fog end at about 250–400 studs, twilight about 150, midnight about 60–90 with glow accents. These are suggestions to tune, not sourced values.

### Gaps
- No primary source fetched on Endless Ocean (Luminous, 2024) map design.
- No breakdown of Roblox-specific shark games (e.g. SharkBite) map dressing was fetched.
- Hungry Shark World Pacific Islands and South China Sea landmarks were not detailed.

---

## 4. Environment storytelling props (wrecks, treasure, ruins, sunken cities, submarines, anchors, bones without gore)

### Takeaway
Props tell a story through **wear and specific details**: a worn chest, a scarred figurehead, a skull half-buried in sand. Wrecks and ruins double as landmarks and progression gates, as Titanic Zone, Atlantis and the Galleon map show.

### Cited Findings
- Sea of Thieves objects look used and worn. Figureheads carry narrative: a lion guarding coins, a scarred bear. A skull in sand implies history without gore. — [Sea of Thieves](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure)
- Hungry Shark Evolution's Titanic Zone (with the Titanic) and Hungry Shark World's Galleon special map show wrecks used as whole themed levels. — [Hungry Shark wiki, Skull Island](https://hungry-shark.fandom.com/wiki/Skull_Island); [Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)
- Hungry Shark Evolution hides 15 sunken treasure items around the map (treasure-map collectibles). — [UrGameTips](https://www.urgametips.com/2013/03/hungry-shark-evolution-treasure-maps.html?amp=1) *(only the search snippet was seen, not fetched)*
- Fisch's Atlantis is a ruined city with god-themed temples and trials. Grand Reef has a pirate ship. — [Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)

### Inferences: storytelling prop list (kid-friendly)
- **Wrecks:**
  - Galleon broken in two, with masts lying diagonally (a strong diagonal reads well).
  - Hull ribs as a swim-through.
  - Spilled cargo trail: barrels, crates, cannons, cannonballs.
  - Coral and anemones growing on the wreck, showing the reef reclaiming it.
  - Fish schools inside.
  - A captain's cabin with a treasure chest.
  - A rusty WWII-style submarine or cargo ship with containers spilled down a slope.
  - A crashed plane wing, a lost diving bell, a sunken lighthouse.
- **Treasure:** half-open chests with gold glints (cheap sparkle particles), coin piles, crowns, gem clusters, a golden idol on a pedestal lit by a god ray.
- **Ruins and sunken city:** broken columns, arches, giant statue heads (a shark god), stairs into darkness, mosaic floors, glowing rune doors as progression gates.
- **Human traces:** anchors with chains running up into the dark (this leads the eye to the surface), lobster pots, buoys, a fishing net with a "trapped" chest, a diver's helmet, a lost camera, a mine field of the sea bombs Zev mentioned, a research station.
- **Bones without gore:** clean white whale skeleton, ribcage arch swim-throughs, a megalodon jaw fossil the size of a gate, ammonite and trilobite fossils in trench walls. Keep them bleached, rounded and stylised. No blood, no flesh.
- **Storytelling rule:** every hero prop answers "what happened here?" with 3–5 supporting props nearby (galleon, cannons, chest, broken mast, crab on the chest).

### Gaps
- Shipwreck-as-artificial-reef colonisation patterns (which organisms grow first) were not sourced.
- Endless Ocean wreck design was not sourced.

---

## 5. Islands and beaches: stylised look and the beach → reef → deep transition

### Takeaway
Stylised islands look good through **bright saturated colour, a strong silhouette rock or landmark visible from far away, and worn hand-made props**. The water transition is told by a colour gradient (white sand, turquoise shallows, the dark blue drop-off), which the user can build with Roblox Terrain and water colour.

### Cited Findings
- Sea of Thieves islands are "beautifully landscaped", use bright vibrant colour and set a distant rock formation as a lure. The look is brushstroke and illustrative. — [Sea of Thieves](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure)
- Fisch gives each island one clear theme (volcano, swamp, snow peak, ruins and lighthouse, arch rock) and names islands after their silhouette ("The Arch", "Haddock Rock"). — [Destructoid](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)
- Hungry Shark World maps include land areas and above-water prey (Village, Military Base, villagers and spear throwers on the Arctic map). — [Hungry Shark wiki](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)

### Inferences: the transition recipe (general environment-art practice)
1. **Island top:** palm clusters (leaning toward the water), huts, a dock and pier with posts, a lighthouse or volcano as the silhouette.
2. **Beach:** warm white sand, a wet darker sand band at the waterline, foam line, shells, starfish, driftwood, beached crates. Tide pools on rock edges.
3. **Shallows (0–10 studs deep):** pale turquoise. Seagrass, scattered small corals, rays, strong caustics.
4. **Reef flat to reef crest:** coral density peaks here. Breaking-wave foam on the crest.
5. **Reef wall / drop-off:** a sudden cliff where water turns deep blue. Sea fans on the wall face. The best "wow" vista. Place it so players see it on their first swim.
6. **Open blue:** few props. Large silhouettes (whales, bait-ball fish schools), god rays fading downward.
7. **Deep slope down to trench:** dark rock, sparse glow, a fog wall.
- **The waterline and surface world:** foam particles where the shark breaches. A splash ring and droplets on exit. A camera colour-correction swap between above and below water. Underwater, keep the surface visible from below as a bright rippling sheet (Snell's-window feel). Surface prey on boats, docks and swimmers lets the shark leap. Hungry Shark's breakable ice is a good surface interaction.

### Gaps
- No sourced ArtStation breakdown of stylised beach-to-reef gradients was fetched. The Sea of Thieves ArtStation projects by Joachim Coppens were found but not fetched: [Ancient Isles](https://joachimcoppens.artstation.com/projects/832eG), [Dead Man's Grotto](https://joachimcoppens.artstation.com/projects/bKqNQk).

---

## 6. Lighting, caustics, god rays, fog, particles

### Takeaway
Underwater lighting is layered: sharp caustics near the surface, blurred caustics deeper, a blue scatter gradient with depth, volumetric rays, and drifting particles. Roblox's built-in water darkens with TimeOfDay, which needs ambient compensation.

### Cited Findings
- Caustics recipe:
  - A panning texture at two scales, UV-warped by Perlin noise, multiplied over light at 0.8.
  - Caustics are "sharpest near the surface".
  - Fake colour split with offset red, green and blue lights.
  - A higher mip bias (blur) for deeper layers.
  - Shadows off deeper.
  - A gradient from clear at the surface to deep blue at depth.
  - Layer surface, light and volume particles so each can be scaled down.
  - Prefer opaque materials over translucency.
  — [80.lv, Working with Underwater Caustics in Real Time](https://80.lv/articles/working-with-underwater-caustics-in-real-time)
- Roblox underwater lighting matches the above-water time of day. WaterColor intensity scales with TimeOfDay, so night water can get very dark. Raise Ambient to compensate. Give divers a PointLight for an eerie effect. — [Roblox DevForum, Upcoming Underwater Lighting Improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- Developers complain that the WaterTransparency limit of 1 gives too little fog control. — [DevForum thread](https://devforum.roblox.com/t/underwater-fog-watertransparency-limit-of-1-too-small/382370) *(only the title was seen, not fetched)*

### Inferences: Roblox implementation (general Roblox practice; verify in Studio)
- **Depth-driven post FX:** a client script reads camera Y and tweens Lighting.FogColor/FogEnd (or Atmosphere Density/Color), ColorCorrection TintColor/Saturation/Brightness and Ambient per zone band.
- **Caustics:** an animated Texture or Decal flipbook on the seafloor, or a SurfaceGui. Alternatively, a SpotLight pointing down with a moving cookie-like texture is not natively supported, so the common Roblox route is animated textures on terrain-hugging planes in the shallows only.
- **God rays:** Beam objects with a soft gradient texture, slanted from the surface and slowly fading in and out. Lighting.SunRays only works above water.
- **Marine snow:** a ParticleEmitter attached to the camera (a local part) with tiny white specks, slow downward drift and low rate. Raise its density in the twilight zone.
- **Bioluminescence:** Neon material plus PointLight sparingly (lights are costly). Prefer Neon or emissive textures without real lights for most glow, and keep real PointLights for heroes.
- **Kelp and coral sway:** client-side CFrame sine animation on bones, or TweenService on segmented parts. Only animate within about 150 studs of the camera.
- Tie this to the user's preference for audio: zone ambience (muffled bubbles, whale songs, vent rumble) does as much as visuals. This follows Subnautica's sound-first warnings (section 3).

### Gaps
- No primary Roblox doc fetched for Atmosphere/fog interaction underwater, or for current FogEnd behaviour inside Terrain water.

---

## 7. Roblox performance for dense props

### Takeaway
Use StreamingEnabled with small spatially grouped models (each about 64 studs or less), SLIM LOD for distant static models, few Persistent models, and prefetching before teleports. Reuse the same MeshIds so the engine can instance them, and keep lights and animated props local and limited.

### Cited Findings
Source for every point below: [Roblox Creator Docs, Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)
- StreamingTargetRadius defaults to 1024. StreamingMinRadius defaults to 64. Test at the minimum radius.
- StreamOutBehavior = Opportunistic lets the client "aggressively garbage collect content".
- ModelStreamingMode modes:
  - **Atomic:** streams the whole model together, which is safe for client scripts.
  - **Persistent:** never streams out, so use it sparingly.
  - Nesting a persistent model inside an atomic one makes the atomic model act persistent.
- Model LevelOfDetail = SLIM fills non-streamed models with lightweight composite or imposter meshes. It works for static meshes and parts only, not animated or runtime-modified ones.
- Keep each model's extent under about 64 studs so it streams as a whole. Break big container models into smaller ones, because containers reduce streaming efficiency.
- Call `Player:RequestStreamAroundAsync()` before teleports. Do full-world queries on the server.

### Inferences (general Roblox practice)
- **Instancing:** reuse a small library of coral and kelp MeshParts (same MeshId and TextureID) and vary them with scale, rotation and Color tint instead of making unique meshes. Roblox automatically instances identical meshes.
- Set CanCollide, CanTouch and CanQuery false on decorative props. Set CastShadow false on small filler. Use RenderFidelity Automatic.
- **Prop budget per zone:** keep heroes high-poly (the user requires high-quality models) and fillers low-poly. Hide fog-culled distance with the fog itself.
- Run animation, particles and fish-school boids **client-side only**, with distance culling. Fish schools can be a single mesh moved as a group, which echoes Abzu's cheap material-driven fish.
- Limit real lights (PointLight/SurfaceLight) per screen. Fake glow with Neon.

### Gaps
- No sourced figures for safe part or triangle counts on mobile, or for the current (Nov 2026) state of SLIM/LOD features beyond the docs page.

---

## Sources consulted (all)
- [WHOI Ocean Zones](https://www.whoi.edu/know-your-ocean/ocean-topics/how-the-ocean-works/ocean-zones/)
- [Discover Wildlife, Ocean zones](https://www.discoverwildlife.com/environment/what-are-the-ocean-zones)
- [NOAA Ocean Explorer, Bioluminescence](https://oceanexplorer.noaa.gov/explorations/15biolum/background/biolum/biolum.html)
- [NOAA Ocean Explorer, Black smoker / Strawberry Fields](https://oceanexplorer.noaa.gov/explorations/05lostcity/background/overview/media/fig2strawberry.html)
- [New Heaven Reef Conservation, Coral Growth Forms](https://newheavenreefconservation.org/learning-resources/explore-topics/coral-growth-forms)
- [CCBC Open Oceanography, Kelp Forest Ecosystems](https://opencontent.ccbcmd.edu/ccardona2023oceanography/chapter/11-5-kelp-forest-ecosystems/)
- [80.lv, Abzu creative director interview](https://80.lv/articles/interview-with-the-creative-director-of-abzu/)
- [80.lv, GDC 2017 Creating the Art of Abzu](https://80.lv/articles/gdc-2017-creating-the-art-of-abzu/?amp=1)
- [80.lv, Underwater caustics in real time](https://80.lv/articles/working-with-underwater-caustics-in-real-time)
- [FeedMe Design, Subnautica depth](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- [Hungry Shark wiki, Arctic Ocean](https://hungry-shark.fandom.com/wiki/Arctic_Ocean)
- [Hungry Shark wiki, Skull Island](https://hungry-shark.fandom.com/wiki/Skull_Island)
- [Destructoid, Fisch map](https://www.destructoid.com/fisch-map-with-all-islands-and-npcs/)
- [Sea of Thieves, Art of Adventure](https://www.seaofthieves.com/news/archive/a-closer-look-at-the-art-of-adventure)
- [Roblox DevForum, Underwater lighting improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- [Roblox Creator Docs, Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)
