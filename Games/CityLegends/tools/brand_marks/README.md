# Brand marks

How `src/client/BrandMarks.lua` was made: the real makers' badges, logos and names on each converted car, so CarSkin can hide or cover them (owner, 2026-10-17).

The scripts run with Blender's Python module (`bpy`) on the converted `.blend` files (from `auto_car.py`). Their input and output paths point at the scratch folders used when they were written; change them before running again.

1. `views.py <car.blend> <id> <dir>`: renders the front, back and side of a car (badge-named parts in magenta). Put a grid on the renders and read off where printed logos and name plates are.
2. `picks.py`: those picks, per car: `(view, x, y, w, h, kind)` in render pixels. `kind` is `blank` (a patch in the colour round it), `emblem` (our fictional BNW / Mercer / Lexis emblem), or `stand` (an emblem facing the viewer, for hood stars). `PLATES` lists name plates. `KEEP` lists badge-named parts that are more than badges.
3. `measure.py <car.blend> <id> <out.json>`: turns the picks into 3D spots on the model (position, facing, size, colour), and measures the badge parts, the wheel centre caps and the steering wheel's hub.
4. `collect.py`: gathers every car's measurements and which parts to hide.
5. `check.py <car.blend> <id> <dir>`: removes the badges, puts every cover on, fills in the badge-spot emblems' facing and colour, and renders the car again to check it. It writes the final per-car data.
6. `marks.json` holds that data for all cars. `to_lua.py` (run from `Games/CityLegends`) writes it to `src/client/BrandMarks.lua`.

Cars built in Roblox (not converted) are handled by name only: parts, groups and decals named badge, logo, emblem or "BMW SIGN" are left out.
