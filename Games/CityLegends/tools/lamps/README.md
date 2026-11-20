# Lamp shells (tools/lamps)

The glowing lamps of the newest cars (`client/CarLamps.lua`), cut from each model's own lamp pieces. The scratch data is not kept: run again to rebuild.

1. `LampScan.luau` (load as `ServerStorage.ClaudeTools.LampScan`, Edit): `summary(id)` lists the loose pieces (islands) near the nose and tail with place, size, picture colour. The result is padded so it lands in a file: put those in `lampscan/sum_<id>.txt`.
2. `lamp_pick.py`: picks islands per car (box per car in `HEAD`) -> a JSON for `ClaudeTools.LampPicks` (StringValue). `LampScan.dump(ids, car, piece)` hands the triangles back in slices (hex): put them in `lampscan/geo_*`, then `lamp_geo.py`.
3. `lamp_roles.py` + `lamp_mesh.py`: roles (core, cover, front and rear turn, reverse, tail), left side only, right side mirrored, a little proud of the model along the normals. Where a model has no separate piece, a slice of the tail lens or the head cover. Writes a preview.
4. `lamp_fbx.py` (Blender): FBX, 70 meshes a file; each name carries the true box in mm. Upload as a Model (group 33151111), `InsertService:LoadAsset` into `ServerStorage.LampHolding`, then `LampApply.luau`.

The 16 non-hypercars: `lamp_second.py` (roles per car in `TAIL`, clean slices in `cslice`); their boxes are in `lamp_pick.py`. Check a car from the front at night straight away: the Z223 pick first lit its bumper chrome.

Add a car: a `HEAD` box, run it, add the id to `CarLamps.CARS`.

A car whose .glb names its lamp pieces (2026-11-09, the first Precision Type 42): `lampfx_glb.py` cuts the shells straight from the .glb into the finished .blend before the pack (job `jobs/<car id>.json`, steps in its header), so no Studio scan is needed.

A car already in Studio with no .glb (2026-11-21, the 8 cars with no shells, tail cuts on lens-only cars): `lampfx_studio.py` + `jobs_studio/<id>.json` + `LampShellsStudio.luau` (paste it into execute_luau; it sets `_G.LS`). `LS.scan` lists the loose pieces (left half, `ax` = distance from the car's middle), a job picks them by box (`in`), cuts them (`box`), lays a piece on a lens (`drape`); `python lampfx_studio.py want job.json` prints the Lua call that fetches only those pieces, `LS.pg(id, i)` hands back the pages (they land in tool-results files), `python lampfx_studio.py job.json <pages>` writes `imports/sync/lamp_shells/<id>.glb`, upload it as a Model (group 33151111), `LS.apply(id, assetId)` backs the model up to `ServerStorage.LampBackup_21Nov` once, replaces the roles in the pack and stages a lit clone (`LS.unstage()` after looking). Models that sit off their pivot (458 Speciale, Sterrato, LP750) work about the middle of their own L / R shells (`LS.x0`). Self-check: `python lampfx_studio.py test`.
