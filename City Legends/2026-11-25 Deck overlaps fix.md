# 25 Nov: overhead roads overlapping and stacked (deck overlaps fix)

Owner in Play: "overhead roads overlapping and double overhead roads stacking each other". Found and fixed map-wide.

## What the scan found (step 1)
Scan files: `Games/CityLegends/build/city_1to1/deck_dups_25nov/` (`scan.py`, `deck_osm.py`, `fixscan.py`, `dboxes.txt`).

| Check | Result |
|---|---|
| Deck collision boxes (2,597 "D" boxes), same deck twice | 0 |
| Deck boxes over each other 0.5-14 studs apart | 0 |
| Data decks with no OSM bridge / layer way near | 0 of 51 |
| Data: one OSM bridge split into two decks | 1: Pyay Road by Hledan ("Pyay Road Flyover #2" + "#3", a dip between) |
| Hand-built deck lying over a baked deck | 1: `Roads.HledanDeckFix` (22 Nov, 417 parts) stood 1-16 studs over the baked Pyay deck: **the double deck** |
| Old invisible boxes under a flyover | `Roads.CollideFix_MyanmarPlazaFlyover` (21 Nov): 150 of 270 lay on today's road boxes, 81 of them 0.4-1.6 studs higher (invisible bumps) |
| Deck meshes doubled (triangle scan of every R mesh in the 64 deck cells) | 0 left (the P11 copies of the U Chit Maung deck were already re-baked by the P11 agent) |
| Two road surfaces on one spot at deck ends (0-1.4 apart, crossing = z-fighting) | 13 deck ends (list below) |
| Deck with collision but no visible surface | Baho Road Flyover #2 south end, x ~23000, z 20370-20670 (cells 14x13 / 15x13, P5/P4 seam): NOT fixed |

The 13 deck ends with two surfaces (D box, place, cell):
- Pyay Road deck north foot (27263, 27133) 17x17 and south foot (27415, 29250) 17x19
- Lanmadaw x Myoma Kyaung deck joint (32504, 43010) 21x27 / 21x28
- May Ni Gone deck end (29049, 35073) 18x22 (two boxes)
- Thamaing Station x Bayint Naung Bridge 2 joint (18138, 17238) 11x11
- Gyophyu onto the Sule deck (36214, 42595) 23x27
- Pansodan Bridge deck start (36992, 43532) 24x28
- Nga Moe Yeik Bridge deck end (45091, 18963) 29x12
- Bayint Naung Road deck start (52582, 18655) 34x12
- Baho Road deck end (28072, 40685) 18x26
- U Chit Maung deck start (38919, 31304) 25x20, East Horse Race Course deck end (40431, 31055) 26x20

## Causes
1. **Hledan (the double deck):** OSM has ONE bridge each way along Pyay Road (z ~26440-29260). The roads05 data made two decks with a ground dip between. On 22 Nov a hand-built deck was laid over the dip instead of fixing the data, so two decks stacked.
2. **Deck ends:** where a deck meets a ground road or another deck, the builder lays both slabs on the same spot, tilted against each other. The lower one pokes through (z-fighting).
3. **`RebuildCell` (P11, 24 Nov):** "build every deck that touches the box" built a deck once per step box; the bake kept every copy (U Chit Maung deck 2-3 times). The P11 agent's exact-duplicate filter in the bake caught exact copies only.

## Fixes in the tools (step 2)
- `tools/yangon/RebuildCell.luau`: `_G.RBXRunStart()` / `_G.RBXRunEnd()` around a queue of boxes for one bake. Each deck is still built in every box (kerb seal / scrub at its feet need it) but only the first box keeps it for the pages. A single box keeps every touching deck.
- `tools/yangon/city/roads05_deck_join.py` (new, `test`), called by `roads05_bake.bake`: near decks, where two up-facing road triangles overlap within 1.6 studs, each keeps only the part where it is the top surface (re-triangulated). Every future bake does this.
- `roads05_bake.deck_spill`: the bake prints `DECK SPILL` when a deck in the baked cells also lies in cells not being baked (those keep their old copy), and lists it in `bake_stats.json`.
- `tools/yangon/city/roads05_hledan_fix.py` (new, `test`): Pyay Road #6 gets ONE deck over samples 0..276 (the 22 Nov profile: level 73, 6.8% down to the south foot). Applied to the net, LP1to10, LP1to11 (backups `roads_before_hledanfix.json`) and subset `roads05_RB4h`.
- `tools/yangon/RebuildPrint.luau` (new): `_G.RBXPRINT(label, marker)` prints a job's slices into the Studio log for `roads05_loggrab.py`.
- `src/shared/YangonDeckFix.lua`: Hledan stations emptied (unspike / cliff kept). `src/client/YangonMedians.lua`: no `HledanDeckFix` in its ray filter. `tools/yangon/HledanDeck.luau` marked superseded.

## Fixed in the place (step 2-3)
- **Hledan:** cells 17x17, 17x18, 17x19 rebuilt whole from `roads05_RB4h` (one stepCell box {26112, 26112, 27648, 30720}, 168,218 parts, 0 MOUTH FAILED, 1 Pyay deck, 29 piers), baked (deck joins 1,640 pairs), swapped (2,842 old boxes out, 3,461 in). `Roads.HledanDeckFix` deleted. Assets: data 119660814626897, glbs 87991329079491 131703350090707 113763310300328 99598704573239 96937373960442, collide 128707260831866.
- **Deck ends:** cells re-baked from the builds that own them, meshes only (collision is from the data, unchanged): 21x27 + 21x28 (RB3x), 18x22 (RB6s), 11x11 (RB5), 23x27 + 24x28 (RB3). Each checked first: kerb / pavement / paint triangle counts equal to the place (same build). The Lanmadaw joint went from 152 doubled points to 0.
- **Myanmar Plaza flyover boxes:** the 150 old boxes lying on today's road boxes removed; 120 kept (nothing else under them).
- **Chain after:** lanes `LP1to11` (323 rows in the rebuilt box dropped, raw install, LaneHeights 223 new rows, install: 1,382 lanes / 3,247 links / 0 dead ends), all 28 lane modules = repo (7 had differed), require 28/28. DeckFeetCheck Pyay deck 2 ok / 0 BAD; rays: D top 73.00 straight across the old dip, 58.47 at the south foot.
- **Saves:** v2014 (before Play), v2018 (after, store CityLegends_v1).

## Play test (CityLegends_test, traffic hidden on the client)
- Pyay Road deck, north foot to south foot (457 path points): car 1.91-2.27 over the boxes the whole way, worst jolt 15.1 at the 73 -> 6.8% grade break (28951). Shot: `2026-11-25 Deck overlaps - Hledan one deck (Play) - after.jpg`.
- Lanmadaw -> Myoma Kyaung decks: gap 1.89-2.18, worst jolt 12.8 at the crest between them.
- May Ni Gone deck end: gap 2.03-2.08, jolt 4.3.
- Edit shots before / after: `2026-11-25 Deck overlaps - Hledan double deck (Edit) - before/after.jpg`, `... Lanmadaw deck foot (Edit) - before/after.jpg`.

## Left
- See the handover entry "DECK OVERLAPS FIX" for the cells still to swap in this pass and anything not done.
