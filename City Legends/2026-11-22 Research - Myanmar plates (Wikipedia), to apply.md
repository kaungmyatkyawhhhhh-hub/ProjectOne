# Myanmar number plates from Wikipedia: what to apply (owner, 22 Nov)

Owner: "read this, https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_Myanmar ... apply it to the game" and "for the myanmar license regional city it will only be 3, MDY,YGN,NPW". To do AFTER the tail lights, flame tune and performance mods jobs. Read 22 Nov in the built-in browser (the quick fetch was blocked by the network).

## What the page says
- Current format since 1 July 2021, Latin letters since September 2013 (Burmese characters before). Plate 358 mm x 162 mm. Run by the RTAD.
- Three lines: top = three-letter region code + township number (e.g. `YGN-38` = Yangon Region, Dagon Township); middle = the serial; bottom = the vehicle's make and model (e.g. `SUZUKI ERTIGA`).
- Region codes on the page: 15 (AYY, BGO, CHN, KYH, KCN, KYN, MGY, MDY, MON, NPW, RKE, SGG, SHN, TNI, YGN). **The game uses only three (owner): YGN townships 1-45, MDY 1-28, NPW 1-8.**
- Colours by type (background / text): private black / white; hire vehicles and trailers red / white; touring blue / white; religious yellow / black; embassies and organisations white / black; volunteer service green / white; hearse red / white.
- Serials by type (the page's examples): private `3G-7224`; hire vehicle / truck `1A-1234` (red); taxi `AA-1234` (red); religious `RLG-1234`; industrial zone `8A-1234` with `I-ZONE` on the bottom line; volunteer `AA-1234` (green); UN `UN 12-34`; diplomats `CD 12-34`; other international organisations `IO-1234`; touring `1A-1234` (blue); hearse `HSE-1234`; tractor `1A-12345`; motorcycle `MDY-10 W` over `12345`; three-wheeler `MDY-18 U` over `1234`.

## The game now (`src/shared/Plates.lua`, 19 Nov)
- Private `[1-9][A-Z without I, O]-[1000-9999]`, black with white, top line `YGN-<township>`; taxis `AA`..`HH` on red; job vehicles and the chauffeur get red plates.

## Gaps to close
1. Region: let a plate be YGN, MDY or NPW (township number within that region's range), chosen at the Plate Office; default YGN.
2. **No bottom line (owner, 22 Nov: "dont add bottom line car names").** The plate keeps two lines: region + township, and the serial.
3. Colours for the game's vehicle kinds: bus / truck / delivery job vehicles red (hire), tour or chauffeur service blue if the owner wants touring, taxis red with a two-letter serial (already), everything else black.
4. Keep the pricing rules of 19 Nov (lucky numbers) as they are; a region code is cosmetic unless the owner prices it.
