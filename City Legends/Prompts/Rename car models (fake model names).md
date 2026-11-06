# Prompt: give every car a fake model name (BMWs and Mercedes use chassis codes)

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## Why (owner, 2026-11-06)
The brand names are already fictional (except "Hemi", renamed below), but the model names are still real (Aventador, Huracan, M3, 458, Chiron...). Those are trademarks too, so they're a DMCA / takedown risk. The owner: "make fake model names, but for the BMWs ... don't make it N5 or N3, use their chassis name like F90 or G80". Mercedes, Porsche, Toyota, Nissan and Mazda use chassis codes the same way, so we use them there too; the rest get made-up names in the same spirit.

## Rules
- Change only the **display name** (`Name` in `Games/CityLegends/src/shared/Cars.lua`). **Keep every `Id`**, price, level, class, PI and model, so owners keep their cars and saves don't break.
- Also rename the extra trims built in code (e.g. the Veyron's "Super Sport" and "Grand Sport Vitesse" steps) and any other place that shows a car name (dealer, garage, market, Customs, races, chauffeur, notifications, store, notes).
- Search the whole game for the old model words (Aventador, Huracan, Gallardo, Murcielago, Urus, Revuelto, Countach, Veyron/Veyrun, Chiron/Chiroun, Camaro, Corvette, Skyline, Supra/Supro, Land Cruiser/Cruzer, Panamera, Boxster, Continental, Bentayga, Wraith, Phantom, Cullinan, Levante/Levanto, Maybach/Maybech, Vantage, Vanquish, DBX, LFA, Camry/Camri, Alphard/Alfard, Challenger/Challenjer, SRT, ZL1, GT3, AMG, Hemi, Gullwing, Gran Coupe, Performante, Black Series, M3/M4/M5/M6/M8, X6/X7, 458/599/F430, R8, 12C) in scripts, UI text and part / model names visible to players, and replace them. Internal ids stay.
- Retired cars get renamed too (owners still have them).
- **Rename one brand: "Hemi" → "Ironclad"** (owner, 2026-11-06: HEMI is a real registered trademark of the Dodge / Chrysler group). Change it in `Cars.Makes`, every car name, the garage / dealer brand lists, the market, and any other text. Players' saved cars use ids, so nothing is lost; check the garage still groups them under IRONCLAD.
- Don't change any other brand name or `makeOf()` (every new name still starts with its brand).

## The new names
| Id | Old name | New name |
|---|---|---|
| bnw_530i | Bavarica Werkz 530i G30 | Bavarica Werkz G30 2.0 |
| bnw_540i | Bavarica Werkz 540i G30 | Bavarica Werkz G30 3.0 |
| bnw_330i_g20 | Bavarica Werkz 330i M Sport | Bavarica Werkz G20 Sport |
| bnw_m3_e92 | Bavarica Werkz M3 E92 | Bavarica Werkz E92 V8 |
| bnw_m3_f80 | Bavarica Werkz M3 F80 | Bavarica Werkz F80 |
| bnw_m4_f82 | Bavarica Werkz M4 F82 | Bavarica Werkz F82 |
| bnw_m5_e60 | Bavarica Werkz M5 E60 V10 | Bavarica Werkz E60 V10 |
| bnw_m5_f10 | Bavarica Werkz M5 F10 | Bavarica Werkz F10 |
| bnw_m5_f90 | Bavarica Werkz M5 F90 | Bavarica Werkz F90 |
| bnw_m6_v10 | Bavarica Werkz M6 V10 | Bavarica Werkz E63 V10 |
| bnw_m8gc | Bavarica Werkz M8 Gran Coupe | Bavarica Werkz F93 Fastback |
| bnw_x6 | Bavarica Werkz X6 M Sport | Bavarica Werkz E71 Sport (check the model's generation: F16 / G06 if newer) |
| bnw_x7 | Bavarica Werkz X7 | Bavarica Werkz G07 |
| bnw_750li | Bavarica Werkz 750Li | Bavarica Werkz G12 Long |
| bentz_e300 | Tri-Star Silber E300 | Tri-Star Silber W213 2.0 |
| bentz_e400 | Tri-Star Silber E400 | Tri-Star Silber W213 3.0 |
| bentz_e63s | Tri-Star Silber E63 S | Tri-Star Silber W213 V8 S |
| bentz_cla45 | Tri-Star Silber CLA 45 | Tri-Star Silber C118 Turbo |
| bentz_cls63s | Tri-Star Silber CLS 63 S | Tri-Star Silber C218 V8 S |
| bentz_gle53 | Tri-Star Silber GLE 53 | Tri-Star Silber C167 3.0 |
| bentz_g63 | Tri-Star Silber G63 | Tri-Star Silber W463 V8 |
| bentz_s63 | Tri-Star Silber S65 W222 | Tri-Star Silber W222 V12 |
| bentz_s65_w221 | Tri-Star Silber S63 W221 | Tri-Star Silber W221 V8 |
| bentz_sl65bs | Tri-Star Silber SL65 Black Series | Tri-Star Silber R230 V12 Track |
| bentz_sls | Tri-Star Silber SLS | Tri-Star Silber C197 Wingdoor |
| bentz_gls | Tri-Star Silber Maybech GLS 600 | Tri-Star Silber X167 Royale |
| bentz_s680 | Tri-Star Silber Maybech S680 | Tri-Star Silber Z223 Royale V12 |
| bentz_190e | Tri-Star Silber 190E Evo II | Tri-Star Silber W201 Evo II |
| bentz_a45s | Tri-Star Silber A45 S | Tri-Star Silber W177 Turbo S |
| brabos_g63 | Rocket G63 | Rocket W463 800 |
| bentz_gt63s | Hemi SRT | Ironclad Supercharged |
| dodger_challenger | Hemi Challenjer | Ironclad LC V8 |
| suzaki_swift | Sompact Swiff | Sompact Zippa |
| toyoka_belta | Apex Belto | Apex Metro |
| toyoka_camri | Apex Camri | Apex Cambria |
| toyoka_crown | Apex Crowne Athlete | Apex Regent Sport |
| toyoka_alfard | Apex Alfard | Apex Grand Lounge |
| toyoka_lc200 | Apex Land Cruzer 200 | Apex J200 |
| toyoka_lc300 | Apex Land Cruzer 300 | Apex J300 |
| toyoka_supra_mk4 | Apex Supro MK4 | Apex JZA80 |
| toyoka_chaser | Apex Chasor Tourer V | Apex JZX100 Tourer |
| lexis_lx700 | Stealth-Apex LX700 | Stealth-Apex J310 |
| lexis_lfa | Stealth-Apex LFA | Stealth-Apex V10 Halo |
| lexis_lc500 | Stealth-Apex LC500 | Stealth-Apex Z100 V8 |
| nisun_350z | Horizon 350Z | Horizon Z33 |
| nisun_r34 | Horizon Skyline R34 GT-R | Horizon BNR34 |
| nisun_gtr | Horizon GT-R R35 | Horizon R35 |
| mazdo_rx7 | Ahura RX-7 | Ahura FD Rotary |
| mazdo_rx8 | Ahura RX-8 | Ahura SE3P Rotary |
| kio_ev6 | Orient EV6 | Orient Voltra |
| byt_seal | Dream-Build Volt Seal EV | Dream-Build Volt Orca EV |
| byt_u8 | Dream-Build Volt Yangwong U8 | Dream-Build Volt Titan |
| xiaomo_su7 | HyperSpeed Tech SU7 | HyperSpeed Tech S7 |
| porsha_panamera | Stuttgart Panamera Turbo S | Stuttgart 971 Turbo S |
| porsha_boxster | Stuttgart Boxster 718 | Stuttgart 982 |
| porsha_gt3 | Stuttgart 911 GT3 991.2 | Stuttgart 991.2 Track |
| chevo_camaro | Golden Camaro ZL1 | Golden Six Supercharged |
| chevo_c6 | Golden Corvette C6 | Golden Sting 6 |
| chevo_c7 | Golden Corvette C7 | Golden Sting 7 |
| audy_r8 | Precision R8 Type 42 | Precision Type 42 V10 |
| mclaran_12c | Speedmark MP4-12C | Speedmark P11 |
| astin_db9 | British Vanguard Vanquish | British Vanguard Vanta V12 |
| astin_vantage | British Vanguard Vantage | British Vanguard Vela V12 |
| astin_dbx | British Vanguard DBX | British Vanguard Highland |
| bentlee_contgt | Sovereign Continental GT | Sovereign Grand Tourer |
| bentlee_bentayga | Sovereign Bentayga | Sovereign Highlands |
| rolls_wraith | Ecstasy Wraith | Ecstasy Nocturne |
| rolls_cullinan | Ecstasy Phantom | Ecstasy Grandeur |
| maseroti_levante | Trident Motors Levanto GTS | Trident Motors Maestrale GTS |
| ferrara_f430 | Rosso Rampante F430 | Rosso Rampante F131 |
| ferrara_599 | Rosso Rampante 599 | Rosso Rampante F141 |
| ferrara_458 | Rosso Rampante 458 Itala | Rosso Rampante F142 |
| ferrara_458spider | Rosso Rampante 458 Spider | Rosso Rampante F142 Spider |
| ferrara_458speciale | Rosso Rampante 458 Speciale | Rosso Rampante F142 Speciale |
| ferrara_california | Rosso Rampante Californa | Rosso Rampante F149 Riviera |
| lambrini_lp700 | Enfurecido Aventador LP700-4 | Enfurecido LB834 |
| lambrini_lp750 | Enfurecido Aventador SV LP750-4 | Enfurecido LB834 RF |
| lambrini_svj | Enfurecido Aventador SVJ | Enfurecido LB834 RFT |
| lambrini_svj63 | Enfurecido Aventador SVJ 63 | Enfurecido LB834 RFT 63 |
| lambrini_revuelto | Enfurecido Revuelto | Enfurecido LB744 |
| lambrini_huracan | Enfurecido Huracan EVO | Enfurecido LB724 |
| lambrini_performante | Enfurecido Huracan Performante Spyder | Enfurecido LB724 Aero Spyder |
| lambrini_sto | Enfurecido Huracan STO | Enfurecido LB724 Track |
| lambrini_sterrato | Enfurecido Huracan Sterrato | Enfurecido LB724 Rally |
| lambrini_lp570 | Enfurecido Gallardo LP570-4 SL | Enfurecido L140 Leggera |
| lambrini_lp560 | Enfurecido Gallardo LP560-4 Spyder | Enfurecido L140 Spyder |
| lambrini_lp640 | Enfurecido Murcielago LP650-4 Roadster | Enfurecido L147 Roadster |
| lambrini_lp670 | Enfurecido Murcielago LP670-4 SV | Enfurecido L147 Veloce |
| lambrini_urus | Enfurecido Urus | Enfurecido Brava |
| lambrini_urusp | Enfurecido Urus Performante | Enfurecido Brava Sport |
| lambrini_countach | Enfurecido Countach LP400S | Enfurecido Classico 400 |
| bugotti_veyron | Velocité Noir Veyrun 16.4 | Velocité Noir Origine |
| (trim step) | Velocité Noir Veyrun Super Sport | Velocité Noir Origine Super Sport |
| (trim step) | Velocité Noir Veyrun Grand Sport Vitesse | Velocité Noir Origine Roadster Vitesse |
| bugotti_chiron | Velocité Noir Chiroun | Velocité Noir Éclair |
| bugotti_chiron_pursport | Velocité Noir Chiroun Pur Sport | Velocité Noir Éclair Pure |
| bugotti_chiron_supersport | Velocité Noir Chiroun Super Sport | Velocité Noir Éclair Super Sport |

Avoid in future names (owner, 2026-11-06): C6 / C7 style codes Chevrolet advertises, W16, "Gran Coupe", "Gullwing", "Performante", and anything a maker uses as a real model name.

## Side nicknames on the Aventador line (owner, 2026-11-06)
Our own version of the real SV / SVJ side lettering (the real cars say "SV" = Super Veloce, "SVJ" = Super Veloce Jota):
- **RF** = **Ruggente Furia** ("roaring fury"), on `lambrini_lp750` (old SV).
- **RFT** = **Ruggente Furia Tempesta** ("roaring fury storm"), on `lambrini_svj`.
- **RFT 63** on `lambrini_svj63`.
- Put it on **both sides** of the car, low on the doors / side skirts, like the real lettering: big italic letters, the full words small underneath, a thin stripe; design in `Games/CityLegends/imports/refs/ui/brand_logos/side_decals_rf_rft.png`. Make it a decal (or a texture painted in Blender) that sits flat on the body with no z-fighting, sharp at phone size, and doesn't change with Customs paint unless the player picks a decal colour. No real "SV" / "SVJ" lettering may stay anywhere on these cars.

If a new car (e.g. the Pending A45 S, or any future import) arrives, name it the same way: BMW / Mercedes / Porsche / Japanese cars by chassis code, the rest with a made-up name in the same style.

## Check before you say done
- Lune tests and `luau-lsp analyze` clean; the dealer, garage (grouped by brand), market, Customs and races show the new names; old saves load and owners still have every car.
- A search for every old model word (list above) finds nothing players can see.
- Commit, push, save the place; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- done, how many names changed, anything you couldn't rename.
