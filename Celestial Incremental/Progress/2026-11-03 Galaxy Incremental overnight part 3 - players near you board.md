---
date: 2026-11-03
tags: [galaxy, leaderboard, progress, overnight]
status: built and tested in Studio; not published
---
# Galaxy Incremental - overnight part 3: PLAYERS NEAR YOU board (3 Nov, Claude Code)

From the overnight run (part 3) and [[2026-11-02 Galaxy Incremental - Design additions (Regrowth + Immortality lessons)]] section 1.
Screenshots: `Progress\screens\overnight\p3-*`.

## What I found
- PLAYERS NEAR YOU already existed: it was the right half of the leaderboard wall (built 2 Nov).
  - Already working: the OrderedDataStore of lifetime Supernovas, 5 above and 5 below you, a 60 s refresh, your row in gold.
- **The problem:** two lists shared one 24-stud wall. Each row was ~0.8 studs tall, so a phone couldn't read it (shot p3-01).

## What changed
- **PLAYERS NEAR YOU has its own board**, standing next to the wall (shot p3-02):
  - 13 x 15 studs, facing the Core, the same brass frame, posts and lamps as the wall.
  - Where: on the floor between the wall's end and the star-chart gap (angle 110, 46 studs out). It clears the wall end by 5 studs, and the benches and chart too.
  - 11 rows (5 above, you, 5 below), with a soft band on every other row.
  - **Your row:** gold text on a gold band.
- **The wall is TOP SUPERNOVAS only**, in 2 columns of 5, so the rows are about twice as tall as before.
- **Same server code:**
  - GalaxyLeaderboardService (OrderedDataStore, top 10 + your neighbours every 60 s)
  - the client fills the new board (`GalaxyMapClient`, BoardEvent "Near")
- **The two boards are now their own builder function** (`Builder.Leaderboards(centre)`), so they could be rebuilt in Studio without rebuilding the whole map. That's how they were placed.

## Tested
- In Play: the list arrived (2 test accounts in the Studio store), and your row is gold.
- No errors.
- **Phone:** the view scaled to 375 px tall (p3-03).
  - **From ~15 studs:** the rows read like the island boards.
  - **From across the plaza:** they are small. Walking up is needed, as with every board.

## Not tested
- A full 11-row list: the Studio store only has 2 players. The layout is fixed rows, so a full list fills the same rows.

## Code
- **Changed:**
  - MapConfig: `NearBoard`
  - GalaxyMapBuilder: `Builder.Leaderboards`, the wall layout, the new board
  - GalaxyMapClient: fills the new board, gold band
  - GalaxyLeaderboardService: comment only
- **In the place:** `Workspace.Galaxy.Centre.Leaderboard` rebuilt, plus the new `Workspace.Galaxy.Centre.NearBoard`.
- **Vault copies:** `Code\map\`.
