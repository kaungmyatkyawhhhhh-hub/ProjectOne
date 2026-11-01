# Riviera (Monaco-shaped) map plan

The 2D plan for the new map (Phase 1 of `City Legends/Prompts/New map shaped like Monaco.md`).

- `data/monaco.json`: coastline, main roads, piers and breakwaters from OpenStreetMap (Overpass, 2026-11-01). © OpenStreetMap contributors, ODbL. Shape guide only.
- `data/elev.json`: 30 x 30 height grid (EU-DEM 25 m via opentopodata.org) over lat 43.718-43.762, lon 7.388-7.452.
- `geo.py`: lat/lon to metres, turned -50 degrees so the coast runs along +x and inland is +y (sea at -y). `Elev.at(x, y)` gives the real height in metres.
- `routes.py`: Catmull-Rom splines, road height profiles (smoothed terrain, grade cap, fixed ends).
- `layout.py`: the plan itself: the 3 routes (Coast, Town, Mountain), the switchbacks, town streets, districts, labels. Points are in real metres in the turned frame.
- `plan.py`: draws it. Game scale: 1.6 studs per metre across, 1 stud per metre up; roads drawn at 64 studs (2+2 lanes).

Run (from `Games/CityLegends`):

```
python -I tools/map_plan/plan.py tools/map_plan tools/map_plan/data plan.svg tools/map_plan/layout.py
msedge --headless=new --screenshot=plan.png --window-size=2400,1250 file:///.../plan.svg
```

It prints each road's length, height range, steepest grade and cut/fill, and any road point that falls in the sea.
