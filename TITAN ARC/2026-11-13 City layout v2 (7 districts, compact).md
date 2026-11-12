# 2026-11-13 Stomp Evolution - City layout v2 (7 districts, compact)

Based on: Roblox Playbook "2026-11-13 Research - STOMP CITY 10-10 map blueprint (ChatGPT chat)" + the impatient-kid sim (search is the big problem; the guide arrow was the biggest fix).
Owner OK'd "smaller and tighter, skip subway / rooftop secrets / industrial side branch for now" (13 Nov, 03:22).

## Decisions
- Size about 1,800 x 1,200 studs (not 3,000 x 3,000): x -420..1400, z -600..600. Dense, short walks.
- One loop route (U shape): Park (west) -> Suburbs -> Downtown along the main street -> bridge over the river -> Skyline -> north to Titan -> west bridge -> Crown Core hill (north middle, seen from everywhere).
- River runs north-south at x 890..950 and widens into a harbour in the south (Industrial). Bridges on the main street (z 0), the avenues (z +-300) and the Crown bridge (z 470).
- Ring of terrain hills/mountains around the edge; the invisible walls stay hidden behind the crests.
- District ground tint + lighting identity per district (not coloured rectangles: borders sit on streets/river).
- Breaking: normal props keep the quick break; special collapse only on landmarks (later step).
- Phones first: light models, check a phone-size screenshot per district.

## Districts -> forms -> props (by "need" height)
| District | Area | Forms | Props now | Landmark (step 2) |
|---|---|---|---|---|
| Starter Park | x -420..150 | Starter, Brawler | Flower, Bin, Mailbox, Bike | giant slide playground |
| Suburbs | x 150..500 | Stone, Iron | Car, House | school |
| Downtown | x 500..890 | Magma | Bus, ShopRow | Mega Mall |
| Industrial harbour | x 950..1400, z -600..-250 | Storm | (new: containers, cranes) | crane + cargo ship |
| Skyline | x 950..1400, z -250..250 | Storm, Crystal | Tower | twin towers |
| Titan District | x 950..1400, z 250..600 | Crystal | (new big props) | stadium + Titan Tower |
| Crown Core | x 380..890, z 390..600, hill | Star | (new) | Crown Tower |

## Step 1 build notes (Studio)
- Backup: ServerStorage.Map_preV2_13Nov (Baseplate, Bounds, Dressing hills).
- Props in the river band (40) removed; Center attribute is what server/client/guide read, so moved props must update Center.
