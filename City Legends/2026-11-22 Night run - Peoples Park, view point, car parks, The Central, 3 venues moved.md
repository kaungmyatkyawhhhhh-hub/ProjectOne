# 22 Nov night run: People's Park, Shwedagon view point and car park, The Central, 3 more venues moved

Owner (21 Nov): "view peoples park View point shwedagon pagoda and also the shwe dagon pagoda parking. Also view the central point and build it", "yes move every venues to their actual place", "dont ask me any questions, just build it". 22 Nov: "why u ask questions, Dont ask questions when i said no to" (rule: on autopilot never end a report with a question; keep going down the list).

## Built (in the place, saved by me; Team Create)
Tool: `Games/CityLegends/tools/yangon/PeoplesPark.luau` (`ServerStorage.ClaudeTools.PeoplesPark`: `P.all()`, `P.central()`, `P.undo()`). Shapes = the real OSM outlines (`build/osm_ygn/areas.json`) as oriented boxes in `P.RECTS`. Everything is in `Workspace.Yangon1to1.Parks`.

| What | Where (x, z) | Notes |
|---|---|---|
| Fountain garden (People's Park) | 31419, 37668 (949 x 85) | 11 level basins with jets, paving, planted beds, lamps, benches; its axis points at the Shwedagon's west stairs, as in real life |
| Shwedagon view point | 31905, 37519 | raised stone terrace at the garden's east end, balustrade, round fountain, benches, sign |
| People's Square + big fountain + Elephant Fountain | 30679, 38070 | paved square, 15-jet basin, round basin with three white elephants |
| Shwedagon car park (west side, by U Wisara Road) | 31721, 37138 | 128 bays beside the park's own service roads (they are the aisles) |
| Square car park | 30766, 38602 | 78 bays |
| The Central (Kabar Aye): forecourt + fountain, car park, drive | 34992, 25279 / 35180, 25405 | paved forecourt in front of the round pavilion, 300-odd-part car park on the lawn behind the shop row, asphalt drive from Kabar Aye Pagoda Road at z 25495 |

- **Shwedagon shows from far now:** its 55 biggest visual pieces moved into `Landmarks.Shwedagon.FarVisible` (Model, Persistent; attribute `WasIn` = old folder). Before, the pagoda streamed out beyond 640 studs: nothing to see from the view point.
- **Two shell buildings in the view line removed** (no towers there in real life): `KW6` (32026, 37494) and `KW4` (32266, 37393) -> `ServerStorage.Backups.ViewPointRemoved`, with KeepOut boxes `viewpoint`, `viewpoint2`.
- **KeepOut boxes** `park_<key>` in `ReplicatedStorage.YgnKit.KeepOut` for every park box: the client kit's trees / walls / props no longer stand in them (palms stood in the car park, a compound wall crossed the drive).

## Venues moved to real places (Config.YangonVenues.Sites, synced to Studio)
| Venue | Real place (Google Maps pin) | New lot | From the pin |
|---|---|---|---|
| bank | CB Bank head office, 16.7742255, 96.1674183 | 38525, 45372, facing (1, 0), y 21.29 | 307 studs |
| gems | Gems Museum, 16.8547066, 96.156315 | 35023, 18623, facing (0.866, -0.5), y 63.70 | 233 studs |
| tower_crown | Kan Thar Yar Centre, 16.7923256, 96.1696286 | 39387, 39273, facing (0, -1), y 35.86 | 128 studs |

- Golden City (16.8270399, 96.1655201 -> 38157, 27665) was meant for tower_skyline: **no roads built there** (district not in the map yet), so tower_skyline stays.
- `YangonSites.prepare`: 12 + 10 + 8 shells moved out. Old lots stay as empty flat ground.
- Not moved (no real counterpart picked): rewards, realty, drop-off, Racing Hub, Legends Service, plate office.

## Tested
- Play (server): the three venues build at the new lots (gems 1,070 parts, bank 1,125, tower 986); no script errors, no EntranceRamp warnings.
- Play pictures: fountain garden + view point, Shwedagon car park, The Central (in this folder, `2026-11-22 ...jpg`). After removing the second tower the view was only seen in Edit.
- **Not tested:** driving into any car park or up The Central's drive, the bank robbery / gem run with the bank now downtown (the drop-off is still by Myanmar Plaza: a long drive), fast travel to the moved venues, minimap icons, night look, phones. The parks add about 3,000 parts and ~60 fountain emitters: FPS on weak phones not measured.

## Lessons
- **Studio crashed on Stop Play (out of memory, 3rd Play of the session).** Team Create kept every Edit change. Reopen with `Start-Process "roblox-studio:1+launchmode:edit+task:EditPlace+placeId:121430381830562+universeId:10769952933"`, wait ~4 min; the MCP shows the Studio with no name for a while: confirm with `game.PlaceId` (read only) before editing. Save BEFORE a Play test from now on.
- Terrain under a new slab: fill the ground only up to 4 under the slab top, cut the air from 2.5 under it, and cut ALL air after ALL fills (a neighbour's fill came back over the paving). Slabs 5 thick hide the cut.
- Park "service roads" in OSM are built as full roads with kerbs: a car park there = bay tiles beside them (skip tiles that touch a road box), not one big slab.
- A far landmark is invisible in Play past the streaming radius: its big pieces need a Persistent model.
- "The central point" was read as The Central on Kabar Aye (not Centrepoint Towers downtown).
