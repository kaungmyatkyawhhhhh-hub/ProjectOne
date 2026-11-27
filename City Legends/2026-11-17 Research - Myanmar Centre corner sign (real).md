# Myanmar Centre corner sign (real) - research, 17 Nov 2026

> **Replaced 27 Nov 2026:** this ring sign is the old design and stood partly on the road at 1:1. The corner now has the current low semicircle: [[2026-11-27 Myanmar Plaza front - current design, off the road]].

Owner, 17 Nov: "the MYANMAR CENTRE sign is different in the real life modern myanmar plaza". Same day: "the canopies are suppose to be at middle. not on the left side".

## What the real sign is

The sign stands at the Kabar Aye Pagoda Road / No. 1 Industrial Road corner, in front of the round plaza.

- **Shape:** a low curved wall, about half a ring, round the front of the round plaza. Behind it are curved teal pools.
- **Wall:** polished maroon-brown granite, about 2.5-3 m tall, with a clipped hedge ring in front.
- **Band:** a white band runs along the top of the wall, about 0.6 times the granite's height. The granite rises past the band at the right end.
- **Text on the band:** "HAGL" in green, with a round green-and-white mark to its left, then "MYANMAR CENTRE" in orange. The letters fill about 60-65% of the band's height and are lit at night: orange glows, HAGL glows green.
- **Text on the granite:** four round logos, each with its name beside it, in light letters:
  - a green and gold disc: The Lake Suites
  - a blue disc: MYANMAR CENTRE TOWER
  - an orange and gold disc: MYANMAR PLAZA
  - no disc, just "MELIÁ YANGON" as text
- **Address line:** "192 KABA AYE PAGODA ROAD, BAHAN TOWNSHIP, YANGON", small, under the logos.
- **Lights:** small uplights along the foot of the wall.

**The older versions:**
- About 2016 (TripAdvisor): the same granite wall, but with one big round logo (a sunrise over green peaks) and gold "MYANMAR / CENTRE" letters stacked on the stone. There was no white band.
- April 2018 (Wikimedia Commons IMG_5389): the white band and orange "MYANMAR CENTRE" letters, but no HAGL.
- From about 2019: "HAGL" was added on the band.
- Our game had the 2018 version.

**What can't be confirmed:** I found no clear close-up taken in 2023-2026.
- Two news stories from August 2025 (Eleven Media, People Media) still print the HAGL version.
- In the People Media aerial, the BIDV tower carries no ooredoo sign. Ooredoo left Myanmar in 2022, so that aerial is probably from 2023 or later.
- A night drone video from 2024 shows the band letters still lit.
- In the owner's own drone photo the sign shows only as a pale ring, too small to read.

## Pictures

- `Owner ref - Myanmar Centre sign (real) 1.jpg`: the HAGL sign, front view (printed by Eleven Media in Aug 2025; the photo looks about 2019).
- `Owner ref - Myanmar Centre sign (real) 2.jpg`: aerial (People Media, Aug 2025). It shows the ring wall with HAGL MYANMAR CENTRE, the teal pools, and the glass canopy in the MIDDLE of the corner front, under the screen.
- `Owner ref - Myanmar Centre sign (real) 3.jpg`: Wikimedia Commons "Myanmar Plaza IMG 5389", April 2018, the older sign without HAGL.
- `Owner ref - Myanmar Centre sign (real) 4.jpg`: a night drone frame (YouTube "Myanmar Plaza Yangon Night Life", about 2024), with the band letters lit.
- `2026-11-17 MC sign and centred canopies - before and after.jpg`: the real photos next to the game before and after.

## What changed in the game

Following the "real names as plain 3D text, no logo artwork" rule.

**The sign**
- On the band: "HAGL" in green letters (new group HGL, glows green at night) with a plain green disc, then "MYANMAR CENTRE" in orange. The letters are 67% of the band's height and centred on the band.
- On the granite: plain discs (green, blue, orange) with two-line names, "MELIA / YANGON" as text only, and the address line.
- The letters used to stand 0.4 studs in front of the band at 1:1, floating. Now they sink 0.05 into the wall.
- The granite colour was 100, 62, 40 with a little reflectance, which rendered navy-black on the shaded wall. It is now 170, 88, 66 with no reflectance, which reads maroon. This changes every PGR piece of Myanmar Centre (the round plaza's granite too). It will also change Sedona's PGR at its next export.
- Code: `mc3d.sign_letters()`. The new strings were added to `build/landmarks/text3d.json` with `text3d_blend.py`. The Studio patch is `city/mc_sign_patch.py` (model 123546250666634).

**The canopy and pergola, centred**
- `mc3d.front_chain()` finds the corner front: the run of podium edges that face the junction. The door and the 44-stud canopy now sit at its middle, at (34774.7, 27215.4). Before, they sat on the east chamfer, 37 studs to the left as you face the front.
- The canopy's back edge follows the bend in the facade. It stands on two columns.
- The glass shopfront and its dark sill were rebuilt with the door gap in the middle. The front collision walls were redone the same way.
- The two soffit lights moved under the new canopy.
- The pergola moved to the middle (`MCDrone.luau`, 12.5 studs behind the facade).
- One roof garden bed moved: `mc_roof_gardens.py` was rerun and the `BEDS` list updated.
- The Studio patch is `city/mc_corner_patch.py` (model 82705685696662).

**Studio** (place version 1154; the log says "Saved new changes")
- The old parts are kept in `ServerStorage.MCSign_old` and `ServerStorage.MCCorner_old`.
- The patched meshes carry `OldMeshId_centre`, `OldSize_centre` and `OldPos_centre`.
