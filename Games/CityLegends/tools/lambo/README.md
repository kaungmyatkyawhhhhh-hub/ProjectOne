# Lamborghini imports: Step 1 check scripts (2026-11-04)

Paths point at the session's temp folder; change them before reuse. Results are in `City Legends/City Legends.md`.

- `run_one.sh id:file:wheelbase[:hints]`: auto_car.py (budget 1.2M, no thinning) + render_car.py, marked and plain.
- `pick.py`: rays from the cluster camera; what part, material, images and UV each spot of the cluster is.
- `zoom.py`: a tight cluster shot with the steering wheel hidden, plus the parts near it.
- `share_evo.py`: the EVO's cluster in the other Huracans.
- `share_gallardo.py`: the SL's dash fixed, and its pictures on the LP560 Spyder's dials.
- `cluster_art.py`: Revuelto, SV and LP700 clusters redrawn from the owner's photos.
- `put_art.py`: a picture projected onto a car's blank screen. `lp700_atlas.py`: the LP700's into its model's atlas.
- `gallardo_dash.py`: the SL's binnacle in the LP560 Spyder. `mesh_cut.py`: delete faces and keep a part's shading.
- `cluster_live.py`: Revuelto, SV and Huracan in layers: `preview`, `assets`, `lua` (writes `src/client/LamboClusterArt.lua`); after new pictures upload them and update `cluster_ids.json`.
- Step 3, in order: `convert_all.sh` (paint_glb + auto_car, hint `keep_big`), `cockpit_all.sh` (the owner's cluster calls), `finish_all.sh` / `finish_car.py` (names, badges out, covers, pieces, surface table), `tools/pack_cars.py`, `pbr_table.py`.
- `closeups.py`: nose, tail, wheel, hub, dash, seats of a car, to look for logos and holes.
- `gallardo_dials.py`: the SL's painted needles out of its dash picture.
- `PbrApply.luau`: SurfaceAppearances on the parts after the Import 3D. `step4_patch.py`: run once after the import.
- `cabin_export.py`, `cabin_dark.py`: pale cabin pictures made dark. `LookFixes.luau`: the look pass in `CarModels`. `step4_patch.py` has run (2026-11-04): don't run it again.
- `frame_probe.py`: depth across a cluster frame. `window_*.png`: a screen cut to the frame's openings. `gallardo_art.py`: the Gallardo's big dials, sharp.
- `cluster_close.py`: Step 1 close-ups from a converted car (cluster with the wheel hidden, steering wheel, what the cluster is made of). `glb_view.py`: the same shots from the original `.glb`, which keeps the second UV set (glow pictures land right).
- `share_cabin.py`: a whole cabin in another car of its family. `share_wheel.py`: only the steering wheel. `cabin_shots.py`: six looks into a cabin. `urus_pods.py`: the Urus's side gauges on the model.
- `seat_view.py`: a cluster from the driver's seat with the wheel in, the check that counts. `lift_wheel.py`: moves the steering wheel up or down.
