---
tags: [city-legends, map, landmarks, cleanup]
created: 2026-11-27
---
# City Hall: old invisible parts removed (27 Nov 2026)

**Owner:** "in sule, the city hall has some invisible parts from the old pillars that were removed and redesigned".

## What it was
- The 21 Nov rebuild (`Landmarks.city_hall.Rebuild21Nov`, see [[2026-11-21 Night run - P8, code sync, minimap, lamps]]) hid five of the old design's meshes in `city_hall.Visual` instead of removing them. Each was set to Transparency 1 and kept an `Old21Transparency` attribute:
  - `GLD`, `ROW`, `WAL`, `TRM`, `WTR`.
  - Each is a building-sized invisible shell (WAL alone is 362 x 111 x 263).
- They weren't solid in Play (CanCollide / CanQuery off). In Studio, though, a click on the City Hall selected these invisible shells, and they still carried weight in the place.

## Fix
- Moved those five into `ServerStorage.CityHall_hiddenOld_27Nov` (each part's attribute `From` gives its old path). The older full backup `ServerStorage.CityHall_before_21Nov` is unchanged.
- **Kept**, because the rebuild still uses them:
  - `GLW` (glass) and `GRL` (grille): with them hidden, the window and arch openings disappeared;
  - `GR2`, `STN`, `STK`, `SLB`;
  - `NIT` (the night windows, tag `FacadeNight`).
- Saved as version 2246, not published.

![[2026-11-27 City Hall - after the old hidden shells were moved out (Edit).jpg]]

## Checked
- **Nothing else invisible and solid is near the building**, in Edit or in Play (client side, within 150 studs). The only invisible solid parts there are:
  - the City Hall's own collision box, which matches the rebuilt walls to within 0.1 stud;
  - Sule Pagoda's wall blocks;
  - road collision;
  - other buildings' shells.
- No other Yangon landmark has parts hidden the same way. The two hidden lights at Myanmar Centre look intentional.

## Not sure
- Whether these were the parts the owner saw. If something invisible still blocks the car or player at the City Hall, the next step is a screenshot of the spot.
