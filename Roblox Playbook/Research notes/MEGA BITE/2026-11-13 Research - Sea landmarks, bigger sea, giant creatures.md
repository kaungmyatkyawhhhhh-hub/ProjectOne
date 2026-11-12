# Research - Sea landmarks, a bigger sea and giant creatures (13 Nov 2026, 01:00)

Owner 00:56: "we should put some like landmarks and monuments and stuff in the sea, and also expand the sea more so theres more places to explore and have huge creatures that are violent and some friendly too".
Built on the vault notes: "Notes - Map and world" (9 Nov), "Red Trench ring map" (11 Nov), the Art style guide, "Hungry Shark Evolution inspiration" (11 Nov), and tonight's quality-nerd sim (the Open Sea repeats 11 meshes and has 1 set piece per 5 min).

## What the live map is now (Studio, 13 Nov)
- Safe Reef r < 300. Open Sea only r 300-440 (a 140-stud band). Red Trench (PvP) ring r 440-1120, swim border 1150/1190.
- So the non-PvP space to explore is a disc of r 440 (~0.6 M studs^2) - small. Most of the map's area is the PvP ring.
- Big creatures now: the friendly manta (60-stud wingspan, scenery) and 3 NPC predator types in the Open Sea (Hunter Barracuda, Reef Prowler, Big Chomper).

## What works in other ocean games (sources below)
- **A named hand-made landmark in the middle of each biome**; players find their way by landmarks and distinctive shapes more than maps (Subnautica: wrecks placed at biome centres; "a pointy reef or a round hill"). Repeated landmark interiors read as bland: each one must be different. (Radiator blog, vault "Notes - Map and world")
- **Deeper / farther = more danger and bigger rewards**; the edge of the map is guarded by a giant (Subnautica's dead zone). (Radiator blog)
- **Danger is heard before it is seen**: leviathan roars, sonar pings and a warning voice build tension before the creature shows. A bright stylised art style keeps scary places inviting. (feedme.design, "Designing with Depth")
- **Hungry Shark World**: 4 themed maps; a **Giant Squid boss** in its own event lair; oversized enemy sharks you can only beat during Gold Rush; size-tier barriers that only big sharks can break. (TV Tropes, Hungry Shark Wiki)
- **Roblox Fisch's Megalodon Hunt**: a random server event with an on-screen announcement ("Megalodon Hunt event has begun"), a red circle + red clouds over the spot so everyone can find it, rare variants (Ancient 8 %, Phantom 2 %). A shared server moment that pulls everyone to one place. (Sportskeeda)

## Decisions for MEGA BITE (Claude decides, owner approves the art)
1. **Bigger non-PvP sea:** grow the Open Sea from a 140-stud band to a wide ring (r 300 -> ~1300), split into 4 biomes, each with its own colour, light, sound and ONE hero landmark tall enough to see from the next biome. Move the Red Trench ring outward so it still surrounds everything (owner's 11 Nov sketch).
2. **Landmarks (all original, no brands):** a giant sunken stone statue head (the "Ocean King"), a sunken galleon, a blue-whale skeleton arch, a sunken lighthouse in a kelp forest, a crystal arch + glowing garden. Dense kit around each, open sand "breathers" between.
3. **Giant creatures, friendly:** the manta (live), a **giant sea turtle** (swim on its back for a speed ride), a **blue whale** that sings and drags a cloud of food (swim beside it: easy food). Harmless, slow, huge - the "wow" moments.
4. **Giant creatures, violent:** a **colossal eel** that lives in the ruins (glowing eyes in a crack, a growl first, then a lunge; DART dodges), and a **KRAKEN event** (giant squid) every ~10 min in one biome: on-screen "THE KRAKEN IS RISING!", a red marker on the minimap, tentacles slam (telegraphed red circles), all players nearby team up; big EXP shared by everyone who hit it (Fisch Megalodon Hunt + HSW Squid Boss). Kids' game rules: no blood, telegraph every attack, small sharks can always flee, nothing paid helps.
5. **Phones:** landmarks as Atomic streaming models (persistent where they're the "next goal"), MB_Cull for the kit, a mesh-part budget per biome.

## Sources
- [Mapping the sea floors of Subnautica (Radiator blog)](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html) (via vault "Notes - Map and world")
- [Designing with Depth: How Subnautica Turns the Ocean Into Its Greatest Threat (feedme.design)](https://feedme.design/designing-with-depth-how-subnautica-turns-the-ocean-into-its-greatest-threat)
- [Hungry Shark World (TV Tropes)](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/HungrySharkWorld)
- [Hungry Shark Wiki - Crab Boss](https://hungry-shark.fandom.com/wiki/Crab_Boss_(HSP2))
- [Roblox Fisch Megalodon event guide (Sportskeeda)](https://www.sportskeeda.com/roblox-news/roblox-fisch-megalodon-event-guide)
- [Subnautica 2 devs on the new leviathan (PC Gamer)](https://www.pcgamer.com/games/survival-crafting/subnautica-2-devs-reveal-the-latest-horrifying-leviathan-to-grace-the-deep-sea-it-has-4-tentacles-to-grab-crush-swat-and-terrify-players/)
