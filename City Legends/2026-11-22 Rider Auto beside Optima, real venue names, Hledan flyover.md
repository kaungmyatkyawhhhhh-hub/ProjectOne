# 22 Nov: Rider Auto beside Optima Werkz, venues take real names, Hledan flyover made continuous

Owner (22 Nov): "make the rider auto dealership at its exact place. Right beside optima werkz in google maps and put them in the map where they belong", "and rename every venues to their actual name depending on their location", "also fix the pyay road bridge near novotel. Check 3d or earth or google maps to check and build it".

## Rider Auto + Optima Werkz
- **The right Rider Auto:** "RIDER AUTO Premium Exclusive", 16.8152942, 96.145257 (game 31680, 31560), about 40 m south of Optima Werkz (16.8156414, 96.1451333 -> 31641, 31445). The 21 Nov move used another branch ("Rider Auto Premium Car Sale Center", 16.80879, 96.13499): wrong one.
- **Why not on the pins:** both real plots lie in blocks only ~84 studs (28 m) deep between two real streets (z 31409-31493 and 31535-31619). The showroom model is 220 x 163 studs and the workshop needs a 216 lot; nothing fits without taking a real street out.
- **Done:** dealership -> lot 32076, 31260, facing (-1, 0), y 78.37 (29 shells moved out): directly across the road from Optima Werkz's lot (31773, 31265). They stand side by side, one block north-east of the pins (Rider 497 studs from its pin, Optima 223).
- To sit on the exact pins a smaller showroom and workshop (about 80 studs deep) would have to be modelled.

## Real names (this overrules "fictional names only" for the venues; cars stay fictional)
| Venue | Was | Now |
|---|---|---|
| dealership | Legends Motors | Rider Auto |
| customs | Legends Customs | Optima Werkz |
| hotel | Legends Grand Hotel / The Legends Grand | Novotel Yangon Max |
| tower_aurum | Aurum Residences | Lotte Hotel Yangon |
| tower_crown | The Crown | Kan Thar Yar Centre |
| bank | Legends Reserve Bank | CB Bank |
| gems | Legends Gem Showcase | Myanmar Gems Museum |
- Unchanged (no real place picked): Skyline One, Legends Rewards, the realty, Racing Hub, Legends Service, the plate office.
- Plain text only, no logos. 37 scripts changed by one replace pass (signs, prompts, menus, toasts, travel spots, `Strings.lua` English keys so the Burmese lookups still match; the Burmese lines themselves still say the old names). `ServerStorage.DealerBody` sign attributes -> RIDER AUTO. Model names / ids / save keys untouched.
- Studio's `Minimap` and `CarSkin` differ from the repo (someone's newer edit): left alone, they only had comment changes.

## Hledan flyover (Pyay Road, north of Novotel)
- **Real:** one continuous flyover, about 860 m (OSM bridge; Esri satellite shows one deck over the Hledan junction).
- **Game before:** a high hump (deck top 73, z 27496-28240), a ramp down to the ground (z 28517-28710) and a low hump (58.3, z 28834-29142): the "P8 deck dip".
- **Fix:** `tools/yangon/HledanDeck.luau` (`ClaudeTools.HledanDeck`: `build`, `undo`) lays a new deck (`Roads.HledanDeckFix`, 417 parts: slabs with RoadBox "D", parapets, lines, portal piers) level at 73 from z 28240, then down 6.8% onto the low hump's south end (z 29142). The road meshes are whole 1536-stud cells, so the old dipped road cannot be removed here: it stays underneath as a ground road (its north ramp now ends under the new deck).
- **Traffic:** `src/shared/YangonDeckFix.lua` (stations x, z, old top, new top) lifts the lane points on that stretch (220 points); `RivieraTraffic.build` calls it. `YangonMedians` also rays against `HledanDeckFix` so no planted median is built on the deck.
- A true fix = re-bake that road cell with one deck in the roads05 data; then delete `HledanDeckFix`, `YangonDeckFix` and the hook.

## Tested (Play, 22 Nov)
- Dealership builds on the new lot (1,773 parts), signs read RIDER AUTO / OPTIMA WERKZ / NOVOTEL / LOTTE / KAN THAR YAR / CB BANK, 0 script errors.
- Flyover: 8 of 21 nearby traffic cars were on the new deck, lines and piers seen.
- **Not tested:** driving a player car over the new deck and its two joins, buying / test drive at the new dealership, its driveway, the menus' new names on a phone, Burmese text, the median fix after the last sync, night.
- Place saved by me (version 1777, then once more). Studio restarted itself once during a scan; Team Create kept everything.

## Pyay Road medians narrowed (owner, 22 Nov: "Medians is on the road ... blocking half the road")
- Cause: `YangonMedians` took its width from the lane data (distance between the two inner lanes minus one lane), up to 9 studs, and laid it on the carriageway where the road has no real gap.
- Now each piece rays across the road for the real gap between the two carriageways' road boxes (RoadBox R): it fills only that gap and moves to its middle. With no gap (one carriageway, painted centre line) it is a 1.3-stud strip on the centre line, and plants shrink with the strip (`plantK`). Pieces whose lanes are two apart with no gap are dropped (their middle is a traffic lane).
- Play (Pyay Road, 27537, 29681): beds 0.6 wide, lanes clear both sides (picture in this folder, taken before the stray-piece rule). **The last rule (stray piece in a lane dropped) is synced and saved but not looked at in Play.**
