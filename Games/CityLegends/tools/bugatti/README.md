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

## Step 3 (conversion, 2026-11-03)
- Logos: `tools/logo_paint/bugotti_*.json` (painted textures; badge meshes dropped; the Veyron SS / GSV
  interior atlas is `bugotti_veyron_*_interior.png` = their own atlas 2x with the 16.4's dial faces;
  the Chiron screen is `bugotti_chiron_dash.png`: its painted needle and the maker's mark taken out).
- `conv.sh` paints and converts all 6 (auto_car hints in it), `veyron2.sh` redoes the Veyron family
  with the shared cockpit (`tools/share_cockpit.py`: 16.4's wheel and needles, hub logo cut and capped,
  orange stitching on the GSV, rear letters cut). The Chiron family: `share_cockpit.py` with
  `--wheel`, `--wheel-img` (black leather), `--screen`, `--cut-hub/--cap-hub`, `--cut-box`
  (see City Legends.md for the numbers).
- Needle numbers: `tools/needle_specs.py` with `ns_*.json` (dial centres and labels in texture px)
  -> CarSkin.OWN_NEEDLES (Veyrons) and DIAL_NEEDLES (Chirons).
- `final.sh` renders all 6 and packs `imports/new_cars/bugatti_veyrons.fbx` / `bugatti_chirons.fbx`.
- Checking: `ends.sh` (front / rear close-ups), `closeup.py --pick` (which part / texture pixel is
  under a pixel of a render), `boxfaces.py` (faces of each part inside a box).
