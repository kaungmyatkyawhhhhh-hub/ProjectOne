# Far NPCs: smoother (27 Nov 2026)

Owner: "the npcs from far away are laggy".

## Cause
Two FPS savings from 6 and 26 Nov made far NPCs move in steps.

**Traffic cars** (`src/client/Traffic.lua`):
- Cars more than 380 studs from the camera think and move only every 3rd frame. That is 20 moves a second at 60 FPS, and 10 at 30 FPS on a phone.

**Walkers** (`src/client/YangonStreetLife.lua`):
- Past 140 studs they were posed 4 times a second.
- Between 70 and 140 studs, 10 times a second.

## Fix
**Traffic:**
- A far car still *thinks* every 3rd frame (the cost saving stays).
- On the frames in between, a car in view slides forward at its own speed (`pos + fwd * speed * bank`). Its next think corrects it.
- Visible far cars now get their transform every frame.
- Cars behind the camera still update every 3rd frame (unseen).

**Walkers:**
- Posed every frame within 90 studs, and 30 times a second beyond.
- Behind the camera still 4 a second (unseen).
- Cheap now that the owner cut walkers to `PedMax` 20.

## State
- **In Studio (saved v2342):** `Traffic` (synced by another session) and `YangonStreetLife` (my one change by find/replace).
- **Not checked yet:** FPS and smoothness in Play.
- **Commit note:** commit 09e6cf41 also swept other sessions' uncommitted edits in these two files into the repo.
- **Still to do:**
  - Watch far traffic in Play.
  - Check FPS on the phone preview.
- **Before any publish:** the scripts must match (the 26 Nov rule).
