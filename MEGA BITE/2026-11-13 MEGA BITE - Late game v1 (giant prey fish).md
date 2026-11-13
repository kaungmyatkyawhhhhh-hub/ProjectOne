# MEGA BITE - Late game v1: giant prey fish (13 Nov 2026)

Owner (work order 03:40): "when u become great white / megalodon, the game becomes easy because theres not much to eat afterwards" and "if its tanky ... the exp must be equal to the effort".
Status: built and tested in Studio (Play). Not published. Backups in ServerStorage end in `_preGiantFish_13Nov`.

## What was wrong (read from the live game)
- Every fish in the sea was 12 studs or shorter (the tuna). The "size" of the far rings only made the schools bigger, not the fish.
- A Megalodon swallows anything up to 32 studs, so everything was one bite for 16 EXP (tuna 8 x Open Sea x2).
- Only the hunters were worth a fight (Ancient Titan 5,684 EXP).

## What was added
Four giant prey fish for the far rings. They are the approved fish models, bigger and tinted (scaled copies in `ReplicatedStorage.MegaBite.Fish`), so nothing had to be uploaded.
HP = length squared, like every fish. EXP per HP is the same as the tuna (0.055), so more bites = that much more EXP, paid on every bite (Combat v1).

| Fish | Model | Length | HP | EXP (x2 in the Open Sea, x4 in the Trench) | Swallowed whole by | Bites: Hammerhead / Great White / Megalodon | Lives in |
|---|---|---|---|---|---|---|---|
| King Mackerel (gold tint) | Mackerel x2.3 | 19.6 | 384 | 21 | Great White | 2 / 1 / 1 | The Wilds, Deep Sea, Far Deep |
| Colossal Squid (crimson, inks) | Squid x4.8 | 26.7 | 713 | 39 | Megalodon | 3 / 2 / 1 | Deep Sea, Far Deep, Trench |
| Monster Puffer (slow tank) | Puffer x8.5 | 35.6 | 1,267 | 70 | nobody | 5 / 3 / 2 | Far Deep |
| Titan Tuna (fast, dark steel) | Tuna x3.3 | 38.6 | 1,490 | 82 | nobody | 5 / 3 / 2 | Far Deep, Trench |

- Fish Index: 12 species now (three rows of four). New rarities: King Mackerel Rare, Colossal Squid and Monster Puffer Epic, Titan Tuna Legendary.
- The giants swim higher over the seabed and stay under the surface (new band `giant` and a `clear` value per species). Their HP bar is bigger and sits above the body.

## Test (Studio Play, Megalodon in the Far Deep)
| Check | Result |
|---|---|
| Giants appear around the player | yes: Titan Tuna 8, Colossal Squid 7, Monster Puffer 2, King Mackerel 21 (second spot) |
| Titan Tuna eaten (2 bites), EXP paid per bite | yes (164 EXP before boosts; the test account had x8 boosts on: 1,312) |
| Monster Puffer (2 bites), Colossal Squid (1 bite) | yes |
| Movement audit, 2 spots, 16 s | giants never under 5 studs from the seabed or props; 0 fish under the seabed; 1 old tuna touching a spire in 8,840 samples |
| Script errors | none |
| Fish Index with 12 tiles | fits, colours right, unfound = dark shape with a padlock |

## Feat words and the big multiplier (same pass)
From the Hungry Shark video study ([[2026-11-13 Video watch - HSE all sharks + Astaroth (NextGen Gaming)]], items 2 and 5). Mechanics only; the words are our own. Code: the end of `MB_GrindFx` (backup `MB_GrindFx_preWords_13Nov`).
- **Feat words:** a short funny word pops by your shark: always for a kind you eat for the first time and for the giant prey (gold: "TITANIC BITE!", "CALAMARI PARTY!", "BALLOON POPPED!", "ROYAL FEAST!"), about 1 bite in 7 otherwise ("HOLY MACKEREL!", "INK-REDIBLE!"), for 6 bites in 2.5 s ("WHOLE SCHOOL!"), for beating a hunter ("HUNTER HUNTED!") and in a Gold Rush ("GOLDEN GULP!"). At most one every 1.6 s.
- **Big multiplier:** while a Gold Rush runs, "x3" (or "x6" with a Feeding Frenzy) is the biggest text on screen, top centre under the quest card and the toast line; every bite kicks it.
- Tested in Play: both show, no script errors. Not done from that study: kill feed with portraits (Trench PvP), tier rooms in the Shop, hunters that come only for big sharks.

## Where the numbers live
`GameConfig.Fish.Species` (the four rows), `Fish.Order` (appended), `Fish.Bands.giant`, `Fish.Pop.Tiers` (how often per ring), `Trench.Fish`.

## Not checked yet
- Pace, by the numbers (not played): a school in the Far Deep is worth 216 EXP on average now (108 before), so the 16 schools around a player are about 3,460 EXP (1,730 before). Great White to Megalodon (30,000 EXP) is about 9 full sweeps of the Far Deep instead of 17, with the Ancient Titans and Hammer Brutes hunting there. Tune the weights in `Fish.Pop.Tiers` after a real playtest.
- Phones (real devices).

## Next (needs the uploads)
The giant creatures (friendly turtle and blue whale, the eel ambush, the Kraken event). See [[2026-11-13 MEGA BITE - Giants (whale, turtle, eel, Kraken) models and plan]].
