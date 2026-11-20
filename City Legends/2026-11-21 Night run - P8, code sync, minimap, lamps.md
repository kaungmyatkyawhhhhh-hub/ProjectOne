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

## Minimap done (in Studio, not play-tested)
- Building shapes: 70,512 boxes exported from Studio (`Buildings.Shell`) into `build/city_1to1/buildings_<tag>/Shell_studio.txt` (P1 7261, P2 8246, P3 13016, P4 14097, P6 10812, P7 4757, P8 12313).
- `minimap_1to1.py` FULL now has P8. 53 detail tiles (5 x 13 grid) + 13 overview tiles, 66 uploaded as Image assets; one (`d_0_0`, 78495515679494) was still in review.
- `YangonMapArt.lua` regenerated and installed in Studio (4914 chars, equal checksums). Minimap.lua reads cols / rows from the art, so the wider grid needs no code change.

## Lamp audit done (read-only) - 53 trims, 52 models
Full list: `Games/CityLegends/build/lamp_audit_21nov.md` (build/ is not in git: laptop only).
- **Code bugs (being fixed in the repo now):** other players never see brake / reverse lamps; lamps stay lit after getting out and brake-red can stick; double tail glow on 22 cars (cut tail shell + whole red lens both lit); stale tail entries (GLS, S680, California, LP750, Focus RS, Countach, LP700, LFA); daytime running lights on cars that never had them (AE86, Chaser, Supra, both CP9A, Countach, LP640, LP670); one white headlamp colour for every car (now warm halogen / cool xenon / LED per car).
- **Data work left (shell cuts with tools/lamps, in Studio):** 8 cars have no lamp shells at all (astin_dbx, bentlee_contgt, bentz_sl65bs, bentz_sls, bnw_330i_g20, ferrara_599, mclaran_12c, nisun_350z; the DBX also has no tail lamp); 12 cars light the whole rear lens; re-cuts for CP9A Champion, Supra, Bentayga reverse, 458 Spider, Chaser; GLS bumper strip lights as a tail lamp.
- **Not possible without new meshes:** LED signatures fused into one piece (Audi / BMW light guides, angel eyes, Lamborghini Y tails, Porsche four-point), separate brake element, AE86 pop-ups, sequential indicators.
- Stray `Workspace._WheelStage.lexis_lfa` (20 visible Neon shells) is in the place: remove before publishing.
