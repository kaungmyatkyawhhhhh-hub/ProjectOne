# Research: STOMP CITY 10/10 map blueprint (owner's ChatGPT chat, 13 Nov 2026)

- Source: https://chatgpt.com/c/6af619d7-f2e8-83ec-a031-3bbef5c85717. Only the part after the owner wrote "we need a 10/10 in every detail / aspect map" (as he asked).
- Master map picture: `Art/Map/stomp_city_master_map_chatgpt.jpg` (ChatGPT's 16:9 isometric master map).

## The idea in one line
One continuous, living, destructible city (not zones with coloured borders). The city itself is the reward: at small size it is huge, as a giant you wreck it, at the end it is a miniature under you.

## 7 districts (one route from the starter park to the tallest towers, with side links)
| # | District | Size (their FT) | What's in it | Signature landmark |
|---|---|---|---|---|
| 1 | Starter Park | 4-12 | park, fountain, benches, playground, small shops, lots of easy props | giant playground slide |
| 2 | Suburbs | 12-30 | houses, garages, school buses, pools, streetlights, parking | big neighbourhood school (+ football pitch) |
| 3 | Downtown | 30-100 | shops, hotels, billboards, parking garages, intersections, apartments; buildings = main coins | MEGA MALL (domed) |
| 4 | Industrial Zone (side branch) | 50-150 | factory, harbour, cranes, cargo ship, silos, containers, warehouses | giant yellow construction crane |
| 5 | Skyline District | 100-350 | blue-glass office towers, helipads, skybridges, luxury flats | twin skyscraper towers |
| 6 | Titan District | 350-750 | futuristic purple megatowers, stadium, elevated highways, glow | Titan Tower + Titan Stadium |
| 7 | Crown Core | 750-1,000 | one colossal golden skyscraper on a raised plateau | Crown Tower |

Extras in the picture: a central roundabout with a crown fountain, food shops (pizza, burgers, cafe), a subway entrance, a river through the city with bridges, a train on an elevated line with a tunnel, a ring of hills/mountains as the natural border, waterfalls by Crown Core.

## Design rules from the chat
- Three scales of play:
  - small (streets, jump cars, shops as obstacles);
  - giant (crush intersections, walk through buildings, rooftops);
  - titan (shockwaves on groups, landmark targets, wide spaces for player vs player).
- "Size" is a gameplay number, not studs: the body grows on a controlled curve. Our game already does this: displayed height vs `C.Scale`.
- Every district has three kinds of things to break:
  - common objects that respawn fast;
  - bigger structures that need more size;
  - one landmark with a special destruction sequence + bonus.
- How things break, by kind:
  - vehicles flatten, with bouncing wheels and coin bursts;
  - small buildings: the roof falls and the walls break into chunks;
  - towers collapse floor by floor with a shockwave;
  - landmarks get special animations.
- Use pre-built destruction states + pooled debris, not physics fragments.
- **First-pass targets** (to test, not promises):
  - map: 3,000 x 3,000 studs, 7 districts;
  - 35-45 unique building designs, 7 landmarks, 25-35 prop variations;
  - 6-8 big open intersections;
  - 12 players per server, 30 fps on mid-range phones;
  - respawn in 15-30 s;
  - several routes, no choke points.
  - Use StreamingEnabled, simple far models, and limits on effects when several giants stomp at once.
- Downtown + Skyline are the heart (the biggest, most impressive part). Starter Park + Suburbs are smaller but very detailed. Industrial is a different kind of destruction. Titan + Crown Core are long-term goals.
- Add: a central highway, subway entrances, rooftop secrets, construction events, hidden collectibles.
- **Avoid:** seven rectangle zones with coloured borders. Neighbourhoods should change naturally like a real city.

### 12-point checklist
1. Impressive from the first spawn.
2. The starter area is clear at once.
3. Every district looks different.
4. Buildings get taller toward the core.
5. Reasons to go back to earlier districts.
6. Every main street has satisfying things to break.
7. Big players aren't blocked all the time.
8. Landmarks good enough for thumbnails.
9. Districts connect with no loading.
10. Destruction stays smooth in multiplayer.
11. Phones can see and control well.
12. Exciting at both human and titan size.

## How it maps onto Stomp Evolution today (13 Nov, after the city grid)
| Blueprint | Live game |
|---|---|
| 7 districts on a winding route | 4 districts by x along a straight grid (small → houses → shops → towers) |
| map 3,000 x 3,000 | about 1,700 x 700 inside 2,800 x 2,000 bounds |
| 8 forms (Starter … Star) across 1.7 → 21 m | 7 districts across 4 → 1,000 FT. The **forms map onto districts**: Starter/Brawler = Park, Stone/Iron = Suburbs, Magma = Downtown, Storm = Industrial/Skyline, Crystal = Titan, Star = Crown Core. |
| landmarks per district | we have a clock tower, fountain, ferris wheel, station + train |
| prop kinds: 25-35 | 9 kinds × 3 variants |
| building designs: 35-45 | House, ShopRow, Tower (3 variants each) |
| destruction states | one rubble pile per material + rise-up rebuild |
