# Bugatti imports: Step 1 / Step 2 working scripts (2026-11-03)

Working scripts from the check and the shared-cockpit preview (paths point at the session's temp
folder; change them before reuse). Numbers are in `City Legends/City Legends.md` (Six Bugatti imports).

- `run.sh`: auto_car.py (budget 1.2M, no thinning) + render_car.py for all 6 (check only).
- `glb_inspect.py`: triangles, textures, licence (asset extras), doors / logos / cluster names.
- `dials.py`: dial centres and radii in the cluster textures (circle fit on the tick dots).
- `uv3d.py`: a texture pixel -> its 3D point on a converted car (which dial sits where).
- `paste_dials.py`: the Veyron 16.4's dial faces pasted into the Super Sport / Grand Sport Vitesse
  interior atlas (2x) over their own dials, matched by 3D position.
- `preview_share.py`: renders a car with the shared cluster art (`--img`), the donor's screen
  (`--screen`, `--clear-near` removes the car's own screen faces at it), the donor's steering
  wheel (`--wheel`, `--wheel-img` recolours it).
- `sheet.py`, `sheet2.py`: the comparison pictures.
