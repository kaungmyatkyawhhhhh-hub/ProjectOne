# EVOLVE - Concept: an evolution game, not an "evolve" game

Owner, 18 Nov 2026: "i wanna be a evolution game, not like a evolve game like others".

## The difference
- **Evolve games (everyone else):** one creature levels up (eat, XP, a bigger skin), and you pick what you become.
- **Ours:** change happens across **generations**, by the real rules: variation → selection → inheritance → splitting → deep time. You can't buy or pick your evolution. Nature does it, and you live through it.

## Pillars
1. **You are a lineage.** Each life you play one member. At birth you see your mutations ("longer fins", "thick skin", "sees in the dark").
2. **The environment tests you.** Cold snaps, droughts, predators, oxygen spikes. Traits that fit help you survive and leave more children.
3. **Speciation is automatic.** When enough traits pile up: "Your lineage has changed so much it's a new species: Tiktaalik!" There's no menu and no shop.
4. **Branches come from what happened to you.** Two players who start the same can end as different species.
5. **Deep time.** Real species with real dates (the tree of life, v38, already built).

## Shared or per player? (decided 18 Nov 2026)
A **hybrid**:

| What | Where | Why |
|---|---|---|
| Your lineage: genes, mutations, species, date, tree position | **Per player**, on the server, saved | It's your story. A newcomer has to start at the first cell, not in the Jurassic. |
| Environment events (cold snap, drought, predator wave, the big extinction) | **Shared per server**: everyone in the server is hit at once | The social moment: "we all survived the ice age". It's a reason to play with friends. |
| World counter (species found, extinctions survived by everyone) | **Global**, across all servers (the existing World pill) | Cosmetic pride only. It never touches anyone's survival. |

Rules that make the hybrid work:
- **Events test traits, not eras.** A cold snap hurts a cell with no "thick membrane" and a mammal with no fur alike, so every stage plays the same event.
- **Newborn shelter.** Nobody gets hit by an event in their first ~3 minutes in the server.
- **Server-side only.** Every test and outcome is decided by the server. The client only shows it: the warning, the sky change, the reveal. Never trust the client for survival.
- **Not truly global.** A worldwide event clock would land the big extinction on a kid who joined 10 seconds ago. Cross-server sync is also cost with no fun in it.

## The first five minutes
1. Spawn as First Cell. The birth card shows 2 mutations (e.g. "Thick membrane", "Fast flagellum").
2. Eat orbs and survive. A pulsing sky tint warns: "The water is getting colder…"
3. Cold snap (shared, 20 s). Cells with Thick membrane stay fine; others slow down and lose orbs. Toast: "Your Thick membrane saved you!"
4. Die of old age, and a child is born. The card shows inherited traits plus 1 new mutation ("???" → reveal).
5. Around minute 4–5, traits pile up and you speciate: "Blue-Green Bacteria", with the date.

## Keep / cut
- **Keep:** generations, inheritance, mutations, the tree of life with dates, the world counter.
- **Cut:**
  - Shop "Family +1 evolution": buying evolution breaks the concept. Robux sells cosmetics or lineage slots instead.
  - Goals-to-evolve: evolution comes from traits, not chores.
  - Path-picking menus: branches come from traits.
- **Shelve:** town building, cyborg/space futures.

## Build order
1. Visible mutations at birth (2–3 traits from a small pool, shown on the birth card, inherited by children).
2. One shared environment event (a cold snap) that tests one trait, decided on the server.
3. Speciation from traits instead of Evo points; tree forks are chosen by which traits you carry.
4. More events (drought, predator, oxygen spike, extinction), then cut the shop evolution item and goals.

## Built 18 Nov 2026 (v41)
- **Thick Skin** trait ("warm in cold") joined the mutation pool.
- **Cold-birth selection:**
  - A child born during a cold snap has a 35% chance the Thick Skin sibling is the one that lived ("Only the Thick Skin sibling lived!").
  - Thick Skin is never lost during a snap.
- **Cold snap, shared per server:**
  - Every 5–8 minutes: "It's getting colder..." (20 s of warning, icy tint), then 30 s of cold.
  - Players without Thick Skin move at 0.6x and get 0.5x orb DNA. Players with it get 2x orb DNA.
  - Players new to the server are sheltered for 180 s.
  - Everything is decided on the server; the client only shows the tint (ColorCorrection "ColdSnap", tint 150,195,255, saturation -0.6).
  - Tested in Play: speed 16 → 9.6, the tint reads as cold, and the self-check passes.
- **AFK (owner: "i want like some part of target audience to afk"):**
  - An idle life (goal not done) still evolves 50% of the time.
  - The client presses a virtual button on `player.Idled`, so the 20-minute kick never fires.
  - Lives already loop on their own, so an AFK lineage keeps evolving slowly and active play is about 2x faster.
- Backup: ServerStorage `Evolution_backup_before_coldsnap`.

## Traits decide the branch (v42, 18 Nov 2026)
- **Body-plan traits per lane:**

  | Split | Lanes and their traits |
  |---|---|
  | F1 | Fish = Backbone, Bugs = Jointed Legs, Shells = Soft Body |
  | F2 | Bony = Bony Skeleton, Sharks = Cartilage |
  | F3 | Synapsids = **Thick Skin** (so cold snaps push families toward mammals), Reptiles = Scales |
  | F4 | Dinosaurs = Gigantism, Birds = Feathers |
  | F5 | Primates = Grabbing Hands, Whales = Flippers |
  | F6 | Sapiens = Sharp Mind, Neanderthals = Stocky Build |

- **How a branch is chosen:**
  - From 2 stages before a split, each birth has a 50% chance to mutate a lane trait. The main lane is 2x as likely.
  - The trait the family carries picks the branch ("New branch! Fur line").
  - With no fitting trait, evolution waits 3 lives ("Waiting for a new trait..."), then nature picks.
- Body-plan traits are never lost.
- The menu remains only for the imagined future split (F7).
- Self-check: about 50% of F1 runs go to Fish (400 runs).
- Play test: Backbone → Haikouichthys, then Bony Skeleton → Arandaspis.
- Backup: `Evolution_backup_before_traitforks`.

## Per-player era world (v43, 18 Nov 2026)
Owner: "the world looks futuristic but not for all".

New LocalScript `StarterPlayerScripts.EraWorld` (copy in `Assets/UI art/scripts/EraWorld.luau`). Each player sees the world of their own depth on the tree (`StageNum`):

| Depths | Era | Look |
|---|---|---|
| 1–11 | Ancient Sea | Teal underwater fog, sand floor, round trees hidden, palms = kelp, bushes = coral |
| 12–16 | First Forests | Misty green swamp, dark moss, round trees hidden (palms read as tree ferns) |
| 17–29 | Age of Reptiles | Warm haze, olive ground, dark conifer green |
| 30–37 | Savanna | Tan grass, olive trees, palms hidden |
| 38–60 | Today | The map as built |
| 61+ | Future | Sunset dusk, pastel cyan/magenta trees. Neon blew out in testing, so it was dropped. |

- Only looks change: Atmosphere, an "EraTint" ColorCorrection, ClockTime, terrain grass colour, and the World folder's part colours and visibility.
- Hidden parts lose collision locally only.
- Streamed-in parts are restyled as they arrive (StreamingEnabled is on).
- Everyone still shares the same ground, players, mysteries and events, and the server decides gameplay.
- World Age pill moved to the right-middle edge (owner request).
- **Known gaps:**
  - Whales and sharks get the land era for their depth; it should be sea by lane.
  - No era-specific props yet (huts, fields, city).
  - Phone not checked.

## 250+ species (v45, 18 Nov 2026)
Owner: "Species to 250".

**Index count:** 392 names in total.
- 90 are the imagined future (Machines, Space, Digital).
- About 25 are human eras (Shell Diver … Knight).
- That leaves **about 277 real species** with real dates.

**New splits.** Each one needs the lane it grows from, and traits decide the branch.

| Split | Grows from | Branches |
|---|---|---|
| F20 (depth 6) | the first animals | Jellyfish, Sponges, Sea stars |
| F8 (10) | bony fish | Ray fins (11), Coelacanths, Lungfish |
| F9 (15) | lobe fins | Amphibians (Eryops … Axolotl) |
| F10 (18) | reptiles | Turtles, Lizards + snakes, Sea reptiles, Pterosaurs, Crocodiles |
| F11 (23) | dinosaurs | Long necks, Armored, Horned, Duckbills |
| F12 (25) | birds | Penguins, Giant runners, Owls |
| F13 (21) | mammals | Egg-laying mammals (Platypus), Pouch mammals (Kangaroo) |
| F5 (23, extended) | placentals | Dogs, Cats, Horses, Elephants, Rodents, Bats, Rhinos |
| F15 (27) | primates | Orangutans, Gorillas, Monkeys |
| F16 (31) | hominins | Paranthropus |
| F6 (35, extended) | Homo | Denisovans, Homo floresiensis |
| F17, F18, F19 | inside Bugs, Shells, Sharks | Spiders, Crustaceans, Scorpions; Snails, Clams; Rays |

**Engine changes:**
- A lane with no names continues the line it grew from (nodeOf falls through).
- lineEnd: the newest split wins.
- natureLane: the main lane gets 50% of the chances.
- Load migration TreeV 3: splits a player is already past take the main lane.
- inherit runs 5 passes.

**Self-checks pass:**
- Triceratops, T. rex, Lion and jellyfish ends.
- Every inner split starts before its branch ends.
- At least 250 species.

**Play test:** the Sauropods path at depth 26 gives Diplodocus, "154 million years ago".

**Known gap:** a whole lane shares one part-built body (Diplodocus looks like T. rex). Bodies made from traits are the next step before "1000+" can be honest.

**Backup:** `Evolution_backup_before_species250`.

## Trait bodies (v47, 18 Nov 2026)
Owner: "Yes, trait bodies".

**Each body is built from the species' look**, not one shape per lane:
- `LANE_LOOK` gives a lane its body plan, e.g. Sauropods `quad neck`, Horned `quad frill horns`, Penguins `penguin`.
- `SPECIES_LOOK` adds the species' own features and size, e.g. Triceratops `horns=3 size=1.4`, Stegosaurus `plates`, Woolly Mammoth `tusks woolly size=1.8`.
- `lookOf(node)` merges the two.

**What the looks build:**
- **New body kinds:** snake (+ cobra hood), jellyfish, sea star, sponge, clam, snail, ray, spider, penguin, giant runner bird.
- **Dinosaurs:** one body shaped by the look: biped or four legs, neck length, duck bill, plates and tail spikes, armor studs, club, frill + spikes, 1 or 3 horns, crest, sail.
- **Extras on other kinds:**
  - Mammals: wool, mane, trunk, big ears, tusks, horn, fangs, teeth, bill, spines, big tail.
  - Birds: owl face, crest, hooked beak.
  - Reptiles and amphibians: shell, croc snout, boomerang head, gills, frog.
  - Fish: bill, sail.
  - Sea reptiles: neck, paddles, dorsal fin.
  - Bugs: claws, stinger.

**Play test (screenshots):**
- Read well: Triceratops, Kentrosaurus, Patagotitan, Woolly Mammoth, Lion, King Cobra, Emperor Penguin, Lion's Mane Jellyfish, Manta Ray, Emperor Scorpion.
- Fixed after the first look:
  - The frill stood up like a sail; the brow horns pointed up.
  - The sauropod neck was a dotted line.
  - The mammoth wool was black.
- No script errors.

**Known gaps:**
- Legs are still plain dark boxes.
- The ray is a plain oval.
- About 100 species have no own look and use their lane's body.

**Backup:** `Evolution_backup_before_traitbodies`.
