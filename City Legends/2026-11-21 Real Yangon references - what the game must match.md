# Real Yangon at night: the owner's reference videos (21 Nov)

Source: `C:\Users\kaung\Downloads\IrlReferences\` (29 videos + photos, 1.6 GB, laptop only). Owner: "its the real life yangon city" (not a car-lamp reference). 25 frames are in `refs_21nov/` (named `<clip>_<time>.jpg`). Long clips were sampled every 5-10 s, not watched in full.

## Places (from signs in frame)
- **P1 (in game):** 0799 = Kabar Aye Pagoda Road: The Central, Sedona, Myanmar Plaza (CB Bank, Melia).
- **P2 (in):** 0792-0795 = inside the GG Gaming Fest hall (YCC).
- **P3 (in):** 0806 = Sule shops, City Hall, Maha Bandula Park; 0804 from 50 s = Sule Pagoda Road bridge; 0820, 0816-0818 = Junction City / Pan Pacific; 0807, 0810, 0811 = Dala bridge approach.
- **Outside every district:** 0808 = Dala bridge span and toll plaza; 0809 = Dala town.
- **Likely (no sign):** 0802 / 0803 = Hanthawaddy Roundabout (P1 / P6 edge); 0800 = Chinese temple by the Kokkine flyover.
- **Unknown:** 0797 / 0798, 0814 / 0815, 0819, 0821, the 0822 car park, the church in 0804.

## Measured night look (RGB)
- Sky near black (5, 6, 10); navy-grey (30, 34, 45) over bright strips; haze only as halos round lamps.
- Lit road: warm grey (197, 192, 164). Game night ambient is blue (74, 86, 124).
- Main-road lamps: white LED (game matches). Some streets: amber sodium, road (157, 116, 75).
- Kerbs red and white (matches). Centre line: double yellow (230, 222, 114); the game rule is all white.

## Ranked fixes (frame)
1. Double yellow centre lines, yellow junction hatching, ramp chevrons (0804_11s, 0804_46s, 0811_photo). **Conflicts with the "all lines white" rule: owner's call.**
2. Night grade: neutral warm grey instead of blue (0804_81s).
3. City Hall: warm-white light on every roof tier + floodlight (238, 230, 213); game has lit windows only (0806_19s).
4. Lit roadside billboards (0804_46s).
5. Roundabout monument: gold (232, 227, 96), green base ring (156, 201, 116); game has a bare island (0803_2s).
6. Maha Bandula fence neon red (216, 93, 49) and green (128, 211, 100), gold LED pole wraps (0801_5s).
7. Sule shops: crest floodlights, yellow boards (0806_1s).
8. Myanmar Plaza strip: CB Bank yellow sign, Melia and Sedona signs (0799_85s, 0799_99s, 0799_43s). The real corner has a big LED screen; the owner removed the game's on 16 Nov: owner's call.
9. The Central as a landmark (0799_1s, 0799_36s).
10. Junction City canopy lights, name wall, roof signs (0820_19s, 0818_photo).
11. Amber lamps on some side streets (0815_photo). **Conflicts with "Yangon lights are white": owner's call.**
12. Sule Pagoda Road truss bridge (0804_56s).
13. YCC interior: dark steel and bare concrete, not white vault and red carpet (0793_photo).
14. Dala bridge: a new area (0808_41s, 0808_131s, 0808_221s).
15. Chinese temple by the flyover, once located (0800_1s).

"Game has none" was judged from the repo only, not checked in Studio.

## Owner decision (21 Nov): the videos overrule the old rules
"the videos overrule the old rules, use yellow lines on the ones that uses yellow in real life, not all"
- Lines: double yellow centre line between opposing traffic, yellow hatching and chevrons; lane dividers stay white. (Game CLAUDE.md rule updated.)
- By the same decision the two other clashes follow the videos: amber lamps on the side streets that have them in real life (main roads stay white LED), and the LED screen at the Myanmar Plaza corner.

## Flyover feet (owner, 21 Nov, with a game screenshot and a real photo)
"on almost every overhead road, its like this. its suppose to be like the 2nd pic": in the game the ramp rises in the middle with the ground lanes kerbed off, a stray box and a pointed island; in real life the road forks, the ground road runs on beside the ramp at full width, and yellow barriers mark the nose. Generator fix in progress; every flyover-foot cell then needs a rebuild and re-bake.

## More owner orders (21 Nov, night)
- "there is sule roundabout too": Sule roundabout night look added to the build list.
- "the city hall needs fix too" (screenshot): tower roofs are plain white boxes, one tower floats off the building, flat brown roof, cyan trim. The model itself is being fixed (backup `ServerStorage.CityHall_before_21Nov`), then lit.
- "the dala bridge needs to be 1:1 exactly the same as the real life": Yangon-Dala Bridge being built from real engineering numbers + the owner's videos (0807, 0808, 0810, 0811) into `Workspace.Yangon1to1.Landmarks.DalaBridge`; script `tools/yangon/DalaBridge.luau`. It lies outside every district, so joining it to the road network is a separate step.

## Done 21 Nov (night look agent; in Studio, not saved, not published)
- **Night grade (fix 2):** `DayCycle.lua` `R_NIGHT` (+ `tools/yangon/PlayLight.luau`): ambient 74,86,124 -> 80,78,74, outdoor 88,104,154 -> 96,94,90, shiftTop -> 120,116,108, atmosphere 34,50,96 / decay 18,28,66 -> 28,30,36 / 14,15,18, tint 255,240,220, water 10,18,24, sat 0.04, con 0.12. Night only (21:00-4:36 keys); day, dawn, sunset, blue hour untouched; no extra haze. Studio DayCycle = repo (checksum 374566397). Sky still reads dark navy (about 1,5,22 vs the videos' 5,6,10): it is the Day skybox dimmed; the Night box measured the same.
- **Lamps (fix 11):** main-road lamps stay white LED, pool widened (template `SNE_lamp1` / `SNE_lamp2` SpotLight Range 42 -> 60, Angle 120 -> 135: the road between posts was black). Side-street power-pole lamps `SNE_ppolel` are amber sodium (head 255,176,92, light 255,170,96); coil poles `SNE_ppolebl` stay white, so side streets are a mix. Templates in `ReplicatedStorage.YgnKit.Templates`; repo `tools/yangon/YangonStreetKit.luau`. Same light count, so no new FPS cost beyond the wider pools; low-end mode still turns every world light off (checked: only the 4 ReplicatedStorage templates stay "on").
- **Signs (fixes 4, 8, 9, 10):** `Workspace.Yangon1to1.Landmarks.IrlSigns21Nov` (25 parts, no Light objects; script `tools/yangon/IrlSigns21Nov.luau`, Studio `ServerStorage.ClaudeTools.IrlSigns21Nov`): Myanmar Plaza LED screen + MYANMAR PLAZA name on Myanmar Centre's Kabar Aye wall; Junction City cream name wall + roof sign; THE CENTRAL letters by Kabar Aye; 6 lit billboards (made-up ads: Legends Motors, Golden River Bank, Swan Mobile ...) on Kabar Aye's lake verge and Sule Pagoda Road. Plain text only, no logo art.
- Pictures: `2026-11-21 Real Yangon look - * (ours vs real).jpg` (night grade, before-after, Myanmar Plaza, Junction City x2).
- **Not done:** amber lamps not seen in a screenshot (checked by property only); THE CENTRAL letters and billboard fronts not screenshotted; Junction City canopy lights and The Central's glowing pavilion; CB Bank / Melia / Sedona signs (real brands: owner's call); truss bridge (12); YCC interior (13); Chinese temple (15). Junction City is still one plain shell block in the game.
