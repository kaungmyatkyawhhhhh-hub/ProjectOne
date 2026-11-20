# 21 Nov night run (laptop) - due 6 AM

Owner rule repeated tonight: **always update the vault** as work lands.

## Done
- Studio upload folders approved on the laptop (imports + build). Road file (.glb) uploads work.
- **Code fixes are in Studio** (14 scripts, checksum-identical to the repo): Cars (GC8 put away), Config (minimap ZoomNear 0.24), TrafficMix + TrafficBodies (no old-model traffic), Chauffeur (stand-in cars), new Frame module + Driving / UI / Weather / HousingClient / TrailerClient / CarDoors / LowEnd (locked-PC fix), Minimap (tile retry).
  - Put in by exact find-and-replace, because script-pack (.rbxmx) uploads sat "not done" for 10+ minutes on Roblox's side.
- Not synced on purpose: BrandMarks, CarSkin, DashGauges, LamboClusterArt, CarFinish, CarLamps, Windscreens. The repo copies are newer (15 Nov car work) than this laptop's place; left alone until checked.

## Running (agents)
1. P8 road swap: upload 40 road files, swap, scans, kit props, grass edges, deck feet, lanes. No Play test by the agent.
2. Minimap: building shapes exported from Studio, P8 added, tiles uploaded, YangonMapArt regenerated.
3. Lamp audit (read-only): every on-sale car's headlights and taillights vs the real car -> `Games/CityLegends/build/lamp_audit_21nov.md`.

## Left
- P8 Play drive test (roads + 7 decks), save.
- Apply the lamp fixes (owner, 21 Nov: "make the player cars' headlights and taillights not have bugs and look identical to real life versions").
- Not saved since v1650. Not published.
