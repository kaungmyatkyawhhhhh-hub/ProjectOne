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

## Not built yet (honest list)
- Interiors: the Strand lobby, the Central Station hall and the Bogyoke Market halls all have photos, but the buildings are closed blocks for now.
- The chinthe statues round the Independence Monument.
- City Hall's peacock and naga mouldings.
- The High Court's central second dome.
- Bogyoke Market's real hall layout: it is 4 parallel halls, not the real plan.
- Studio placement: see the Step 6 progress entry in the rescale plan.
