---
tags: [city-legends, cars, models]
created: 2026-11-18
---
# Cars still on old models (checked in Studio, 18 Nov 2026)

How it was checked: every car in `Cars.All` against `ReplicatedStorage.CarModels` in the main place. **New-pipeline** models (the 2026-11-08 to 11-15 imports) have PBR SurfaceAppearances (20+) and wheel kit 2 (JDM cars use their own wheels). **Old** models have almost no SurfaceAppearances and no wheel kit. Trims (`_sport` / `_top`) use their base car's model, so replacing the base fixes them too.

## Old models, on sale (31 cars, plus their trims)
Toyota-style: `toyoka_camri` (Belta Camri), `toyoka_alfard`, `toyoka_lc300`
Bavarica: `bnw_540i` (+ `bnw_m5_f10` uses it), `bnw_m3_f80`, `bnw_m8gc`, `bnw_x6`, `bnw_x7`, `bnw_750li`
Tri-Star: `bentz_e400` (+ `bentz_e63s` uses it), `bentz_cls63s`, `bentz_gle53`, `bentz_g63`, `bentz_s63`, `bentz_gt63s`, `bentz_190e`, `bentz_s65_w221`, `brabos_g63`
Others: `nisun_r34`, `dodger_challenger`, `xiaomo_su7`, `lexis_lx700`, `byt_u8`, `porsha_panamera`, `chevo_camaro`, `chevo_c7`, `rolls_wraith`, `rolls_cullinan`, `maseroti_levante`

## Not sure: older conversions (some PBR, no wheel kit)
`kio_ev6`, `toyoka_lc200`, `bnw_m6_v10`, `porsha_boxster`, `astin_db9`, `astin_vantage`, `lexis_lc500`

## Waiting for a model (Pending)
`bentz_a45s` (+ trims), `ronin_ct9a`, `ronin_cz4a`, `pleiad_gdb`, `pleiad_zc6`, and `pleiad_gc8`. Studio's `Cars` lists `pleiad_gc8` as Pending, but it was imported on 15 Nov, so Studio's `Cars.lua` may be behind git.

## Retired (owners keep them; not on sale)
`suzaki_swift`, `toyoka_belta`, `toyoka_crown`, `byt_seal`, `mazdo_rx8`, `bnw_530i`, `bentz_e300`, `bentz_cla45`, `chevo_c6`, `ferrara_458`, `lambrini_urus`
