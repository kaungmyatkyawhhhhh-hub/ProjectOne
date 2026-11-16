---
tags: [city-legends, yangon, 3d, landmark, 1to1, p3]
created: 2026-11-16
---
# Downtown landmarks at 1:1 (P3)

The 9 lots left empty by the P3 district build, each built at real size from its OSM outline, the landmarks catalogue and the catalogue photos (`Games/CityLegends/build/landmarks/refs/catalogue/<id>/`). Pure Python, no Blender.

## Files
- Builder: `Games/CityLegends/tools/yangon/landmarks3d/dt_landmarks.py <id>` (run from `Games/CityLegends`).
  - The walls are cut into facade panels by the kit's own primitives (`kit_panels.col_arch` arched windows 0.35 m deep, bands with drips, parapets, stains).
  - It adds tiered Burmese roofs (`pyatthat`), domes, spires, gables, hipped and skirt roofs, clock faces, and marble steps.
  - The gold finials come from the ornament kit (`ornament_kit.flame_finial`).
  - Every scene goes through `city/flicker_check.py`.
- Outputs:
  - `imports/sync/landmarks/<id>.glb`: MeshParts named `LOOK_<id>s<k>_<box>`, in world studs.
  - `build/landmarks/<id>/place.json`: looks, collision boxes and base.
- Studio placer: `tools/yangon/landmarks3d/DowntownPlace.luau`, called as `D.place(holding, placeJson, folder)`. It places one Model per landmark with `Visual` (Box fidelity, no collision or query) and `Collision` (invisible boxes) sub-models, and tags the night window panes `FacadeNight`.
- Packs for Studio:
  - `imports/sync/landmarks/dt_A.glb`: Bogyoke Market, Central Station, City Hall.
  - `imports/sync/landmarks/dt_B.glb`: the other six.
  - `imports/sync/landmarks/dt_place.rbxmx`: the placer, `P3Place` and the 9 place.json files.

## The landmarks (what they are built from)
| Landmark | Outline | Built | Height | Flicker |
|---|---|---|---|---|
| City Hall | rel/5677100, 119 x 85 m | White stucco, pale teal trim. A ground-floor arcade, a tall main floor of arched windows and an attic. 4 corner pavilions under 3-tier white roofs. A 5-tier white roof with gold finials on the south front, facing the park. | 39 m to the finial (catalogue: ~40 m) | 0 |
| High Court (former) | rel/2409553, simplified to 8 corners (+9% area: the offsets self-intersected) | Red-washed brick, cream bands. Three storeys of arcades round an 18 m-deep courtyard ring. Terracotta hipped roofs. A north-east clock tower with clock faces and a red dome. | 37 m | 0 |
| Strand Hotel | way/102682120 (3 floors) + ballroom way/185858884 (2 floors) | Cream-white render, teak-framed windows, cornices and parapets. A porch with a pediment on Strand Road and white marble steps. | 15 m | 0 |
| Immanuel Baptist Church | way/182859345 | All white, pointed windows, a green roof. Two towers with silver spires and a clock in the front gable, facing the park. | 34 m | 0 |
| Holy Trinity Cathedral | way/186939481 | Salmon-red brick, a brown metal gable roof. A front-corner brick tower with a white spire and 4 pinnacles. | 48 m | 0 |
| Central Railway Station | way/102685394, 197 x 49 m | Cream walls with two floors of arched windows, a green hipped roof. 4 towers along the south front under gold 4-5 tier pyatthat roofs. | 28 m | 0 |
| Secretariat (Ministers' Building) | way/264732913 (wings) | Red brick, cream bands, an arcade and arched windows on three floors. A red pitched skirt roof. 4 corner towers with small domes (the central cupola fell in 1930). | 26 m | 0 |
| Bogyoke Aung San Market | area way/23395611, 187 x 187 m | 4 long two-storey halls (cream walls, arcaded shopfronts, terracotta gable roofs) with lanes between them. A white clock tower with a white dome on the south front. | 25 m | 0 |
| Maha Bandula Park + Independence Monument | park way/129485365 | A paved circle and a stepped round platform. A white drum with 3 gold bands. A 46 m obelisk with a pyramidion and 5 fins round its foot. The lawns are the terrain's grass. | 46 m | 0 |

## Walkable interiors (built from the catalogue photos)
- **Bogyoke Market halls (photos Textile_shop and Bogyoke_Market_Jwelly):** the ground floor of all 4 halls.
  - The ground falls about 3 m across the market, so each hall stands on its own plinth, 1 m over its highest ground. Marble steps go up to a 3 m door at every aisle end, in both gable walls.
  - Inside: 3.2 m aisles between rows of stalls, with a cross aisle every ~30 m. Each stall has a counter at the aisle, coloured cloth hanging behind it and a red name board. Hall 0 is the jewellery hall: glass counters and gold.
  - Tiled floor, a cream ceiling at 4.6 m, dark beams every 4 m, fluorescent tubes along the aisles and a warm PointLight every 24 m.
  - Collision: the stall rows, the walls (open at the doors), the slab and everything over the ceiling.
  - The terrain is cleared out of each hall (`clear` boxes in place.json: DowntownPlace fills them with Air). Without this the grass came up through the floor.
- **Central Station undercroft (photo 05):** a 14 m drive-through under the middle of the station, between the two inner towers. It has a flat cream concrete ceiling at 6 m with beams every 1.6 m, and cream walls with deep round arches (`niche_arch`, 1.5 m deep). There are 3 green food carts with blue canopies and 3 warm lights. The upper storey bridges over it.
- **Strand lobby (walkable, from photos 2 and 3):** an open porch on 6 pillars, then a teak-framed door into an 18 x 14 m lobby with cream panelled walls, a dado rail and teak doors. It has a white coffered ceiling, 4 ceiling fans and a chandelier with warm PointLights, a marble floor with a teak border, and 16 wicker armchairs round 4 tables. The collision leaves the lobby open.
- **Independence Monument chinthes (photo 1):** 10 seated dark-bronze chinthe on stone pedestals, 17 m out on the paving, facing out (Shwedagon's chinthe model at 0.37, 3.3 m with the plinth). The photo shows about a dozen; their exact spots are a guess.

![[Bogyoke Market hall aisle - Studio copy.jpg]]
![[Central Station undercroft - Studio copy.jpg]]
![[Independence Monument chinthes - Studio copy.jpg]]

## Not built yet (honest list)
- The Central Station platforms and ticket hall: no photos of them in the catalogue.
- The Bogyoke Market upper floors (closed).
- City Hall's peacock and naga mouldings.
- The High Court's central second dome.
- Bogyoke Market's real hall layout: it is 4 parallel halls, not the real plan.
- Studio placement: see the Step 6 progress entry in the rescale plan.

## In the main place (16 Nov, version 1094)
All 9 landmarks are in `Workspace.Yangon1to1.Landmarks`, each with `Visual` (Precise render fidelity) and `Collision`. Asset ids are in `Games/CityLegends/build/landmarks/dt_assets.json`. The Independence Monument stands on a terrain pad (top 20.4, radius 88 studs: `terrain.PILOT_PADS['P3']`). Without the pad, its paving was hidden under the grass, because the smooth terrain bulges about 2 studs over its set height.
