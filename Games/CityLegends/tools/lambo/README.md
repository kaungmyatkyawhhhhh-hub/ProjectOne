# Lamborghini imports: Step 1 check scripts (2026-11-04)

Paths point at the session's temp folder; change them before reuse. Results are in `City Legends/City Legends.md`.

- `run_one.sh id:file:wheelbase[:hints]`: auto_car.py (budget 1.2M, no thinning) + render_car.py, marked and plain.
- `pick.py`: rays from the cluster camera; what part, material, images and UV each spot of the cluster is.
- `zoom.py`: a tight cluster shot with the steering wheel hidden, plus the parts near it.
- `share_evo.py`: the EVO's cluster in the other Huracans.
- `share_gallardo.py`: the SL's dash fixed, and its pictures on the LP560 Spyder's dials.
- `cluster_art.py`: Revuelto, SV and LP700 clusters redrawn from the owner's photos.
- `put_art.py`: a picture projected onto a car's blank screen. `lp700_atlas.py`: the LP700's into its model's atlas.
