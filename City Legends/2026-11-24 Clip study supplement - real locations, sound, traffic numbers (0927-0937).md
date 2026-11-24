# Clip study supplement: real locations, sound and traffic numbers (0927-0937)

24 Nov 2026. Adds what the first study left out. Hub: [[2026-11-23 Real Yangon by day - clip study (what the game must match)]]. Visual catalogues (buildings, roads, rooms, cars, signs) are in the four `2026-11-24 Clip catalogue` notes; this note does not repeat them.

Source: `C:\Users\kaung\Downloads\ClipsToStudy\` (iPhone 17 Pro, 1080p60 portrait, 23 Nov 2026). IMG_0938 is not a video: it is a 120x160 thumbnail JPEG and has nothing to study.
New pictures: `refs_23nov/audio/IMG_<clip>_audio.png` (loudness + spectrogram per clip), `refs_23nov/IMG_0930_signal_wait_sheet.jpg`, `refs_23nov/IMG_0931_lane_signs_sheet.jpg`, `refs_23nov/IMG_0933_036s_sidecar_bike.jpg`.

---

## 1. Real locations (GPS from each clip's metadata)

Each clip stores the phone's GPS **at the start of the clip** (accuracy 2-19 m, 47 m for 0931). These pin every clip to a real place. Use them to check the matching spot in the game map (P9 = Okkalapa / Parami / Thingangyun side; P10 = east of P9; see [[2026-11-24 rebuild P9 - district and roads in]]).

| Clip | Local time (23 Nov) | Start GPS (lat, lon) | What it is | Map district (likely) |
|---|---|---|---|---|
| 0927 | 10:52 | 16.8030, 96.1859 | Old apartment block, outside + stairwell | Thingangyun side (P9/P10 edge) |
| 0928 | 10:54 | 16.8030, 96.1859 | Same block, inside the flat | same |
| 0929 | 11:03 | 16.8116, 96.1847 | Waizayandar Rd (proven by street sign) | P9 |
| 0930 | 11:07 | 16.8220, 96.1826 | Toddy palm avenue, big junction, Mingalar Hotel | P9 |
| 0931 | 11:34 | 16.8359, 96.1770 | Junction with blue lane-arrow signs, white MAN CAVE condo | P9 |
| 0932 | 11:35 | 16.8375, 96.1761 | YBS city drive (starts 200 m from 0931) | P9 |
| 0933 | 11:39 | 16.8471, 96.1809 | Side street, then wide junction under trees | P9 |
| 0934 | 11:41 | 16.8462, 96.1797 | Kone Baung (14) St residential lanes (proven by street sign) | P9 |
| 0935 | 12:55 | 17.0776, 96.1739 | Expressway toll plaza | outside the map (26 km north) |
| 0936 | 12:56 | 17.0789, 96.1743 | Just past the toll | outside the map |
| 0937 | 12:57 | 17.0818, 96.1747 | Old 2-lane highway with km stones | outside the map |

- So the "unknown street" places in the catalogues now have points: Mingalar Hotel / Laser Care Clinic / Lucky Seven Tea Shop are along the 0930 drive from 16.8220, 96.1826; the Myanmar Property Gallery / WEPOZT EXPRESS / Pet Food Mart run starts at 16.8375, 96.1761; MAN CAVE / RANK is at about 16.8359, 96.1770.
- Only the start point is stored, not a track. Positions later in a clip are along the road the car was on, in the direction the catalogue describes.
- Not done: the GPS was not converted to game studs (`ygn_roads_v5.json` has `ox`/`spm`, but the map was rescaled later and the current projection is in the build tools on the PC). Run the map tool's lat/lon -> world function on these points before placing anything.
- The "likely" districts come from the P9 note's township list, not from projecting the points.

## 2. How fast and how slow the drive was (GPS start to next start)

Straight-line distance between clip start points, so these are **lowest possible** average speeds (real roads bend):

| Stretch | Distance | Time | Average |
|---|---|---|---|
| Flat (0927) -> Waizayandar (0929), walk + drive | 0.96 km | 11.4 min | 5 km/h (includes getting to the car) |
| 0929 -> 0930, main road | 1.18 km | 3.4 min | at least 21 km/h |
| 0931 -> 0932, at the lane-arrow junction | 0.20 km | 1.3 min | 10 km/h (red light) |
| 0932 -> 0933, YBS city drive | 1.18 km | 4.1 min | at least 17 km/h |
| 0933 -> 0934, side streets | 0.16 km | 1.7 min | 6 km/h |
| City -> toll plaza | 25.7 km | 73 min | at least 21 km/h |
| 0935 -> 0936, through the toll | 0.15 km | 0.9 min | 10 km/h |
| 0936 -> 0937, leaving the toll | 0.33 km | 1.2 min | 17 km/h and rising |

**Game takeaway:** real Yangon midday traffic averages roughly 15-25 km/h in the city with long stops; NPC traffic in City Legends can stay slow (it fits FPS too), with the player as the fast one.

## 3. Red-light waits and signal heads

- **0930, 58-100 s:** the car sits at a red for about 42 s (the clip's loudness drops ~10 dB to idle). At 92 s the left-turn head shows **a red left arrow with "59" in red digits** beside it; the straight head is a separate red lamp unit. So a red phase here is a minute or more.
- Signal head layout (0930 @ 92 s): two **horizontal** heads on the mast arm, the left one = [red arrow][2-digit red countdown][amber/green], the right one = straight-ahead red. A white **CCTV camera arm** (2 cameras) spans the road just before the stop line.
- **0931:** blue panel with lane arrows (straight, straight, straight, right) hangs on the arm beside a single red head; the pole top carries a **solar panel**. Our car waited about a minute here (see 2).
- **Game:** NPC cars should queue and sit for 40-60 s reds at big junctions, with red countdown digits on the heads (fits [[2026-11-16 Research - Yangon street furniture and traffic life]]). Shorter (15-20 s) is kinder for players; owner's call.

## 4. Traffic numbers (counted by a detector)

Method: 2 frames a second, YOLO11s object detector + ByteTrack tracker, counting cars, buses, trucks, motorbikes, bicycles and people. The camera is a handheld phone that often points out the side window, so counts are **lower limits** for what was really on the road. Vans and pickups count as "truck"; SUVs and Probox wagons as "car".

| Clip | Road | Cars seen | Buses | Trucks/vans | Motorbikes | People | Most cars in one frame |
|---|---|---|---|---|---|---|---|
| 0929 | Waizayandar Rd (2-3 lanes a side) | 81 | 5 | 17 | 0 | 5 | 8 |
| 0930 | Toddy palm avenue + junction | 82 | 3 | 11 | 0 | 12 | 9 |
| 0931 | Lane-arrow junction | 16 | 3 | 6 | 0 | 0 | 4 |
| 0932 | YBS city drive | 151 | **21** | 29 | 1 | 18 | 8 |
| 0933 | Side street + wide junction | 43 | 1 | 7 | 2 | 0 | 9 |
| 0934 | Kone Baung St lanes | 21 | 0 | 5 | 0 | 7 | 7 |
| 0935 | Toll plaza | 12 | 3 | 4 | 0 | 0 | 4 |
| 0936 | After the toll | 10 | 0 | 2 | 0 | 0 | 2 |
| 0937 | Old highway | 7 | 4 | 7 | 0 | 0 | 1 |

What it means:
- **City mix (0929-0934 together): 78% cars, 15% trucks/vans/pickups, 7% buses.** Use this as the NPC spawn mix by default; on bus routes (like 0932) buses go up to about 1 in 8.
- **Flow:** about 30-50 vehicles a minute pass on the main roads (0929 ~28/min, 0930 ~36/min, 0932 ~52/min, 0933 ~46/min); about 20/min in the side streets (0934). At any one moment 1-2 cars are near the camera and up to 8-9 in a queue.
- **Motorbikes almost never:** 3 in all the city clips. Yangon city bans motorbikes, and that shows. The one clear one (0933 @ 36 s) is a **motorbike with a side cart**, a big beige vendor parasol and a passenger riding on the cart, crossing the junction beside YBS route 10 and a cream City Taxi Corolla wagon. The catalogues also saw a motorbike crowd at one side street (0930) and a vendor bike with a parasol. **Game:** no motorbikes in normal traffic; a few slow parked/ambient side-cart vendor bikes in side streets only.
- **Pedestrians are few** on the main roads (0-2 in frame); the most were along 0930's shops and 0934's lanes.
- **Highway is the opposite mix:** half the vehicles are buses and trucks (0937: 7 cars, 4 buses, 7 trucks in 2.75 min, ~6.5 a minute). Out-of-town traffic = sparse, big, slow coaches and lorries.

## 5. Sound (the first study had none)

Measured from each clip's audio track (mono, 22 kHz). Pictures in `refs_23nov/audio/`. Values are phone-mic levels in dBFS, so use them as **relative** levels.

| Clip | Place | Median level | Quietest 10% / loudest 10% | Low rumble share (<150 Hz) | What you hear |
|---|---|---|---|---|---|
| 0927 | Apartment yard + stairwell | -35 | -38 / -29 | 59% | Footsteps on concrete stairs (sharp clicks about 1 a second), a bird call at 17-20 s, faint distant traffic. |
| 0928 | Inside the flat | -40 | -45 / -31 | 38% | Room tone, AC hum, a little chatter. Quietest clip. |
| 0929 | Waizayandar Rd, driving | -20 | -32 / -14 | 88% | Engine + tyre rumble, in-car talk. |
| 0930 | Palm avenue + red light | -23 | -33 / -19 | 89% | Rumble while moving; **drops ~10 dB to idle at the red (58-100 s)**; **one long car horn at 107 s** (2.6 s, ~405 Hz with a full stack of harmonics up to ~5 kHz); a steady ~3.3 kHz whistle-like tone at 110-113 s (unsure: traffic police whistle or a vehicle beeper); our car's turn chime at 135 s. |
| 0931 | Lane-arrow junction | -27 | -34 / -21 | 83% | **Our car's turn-signal chime the whole wait**: a ~2.0 kHz beep, 2.5 beeps a second, on half the time (0-27 s). |
| 0932 | YBS drive | -20 | -27 / -17 | 83% | Mostly people talking in the car over road rumble. |
| 0933 | Side street + junction | -26 | -33 / -19 | 87% | Rumble, talk. |
| 0934 | Kone Baung St | -21 | -28 / -17 | 81% | Lots of in-car talk; quiet street. |
| 0935 | Toll plaza | -23 | -30 / -19 | 92% | Talk, a thump at 24 s (passing the booth, unsure), then speeding up: broadband rise from 24 s. |
| 0936 | After the toll | -18 | -28 / -14 | 92% | Steady acceleration roar. |
| 0937 | Old highway | -19 | -20 / -16 | 82% | **Very steady** road roar (tyres, 200-2,500 Hz hiss over the rumble), the loudest and flattest clip; **pass-by whooshes** of oncoming big vehicles at 125 s and 127.5 s (about 1 s of broadband noise each). |

What it means for City Legends' sound (made in code, as the owner prefers):
- **Horns are rare.** One clear honk in about 13 minutes of city driving. Do not fill the city with honking; an NPC horn now and then (a blocked queue, a car cutting in) is right.
- **Horn recipe** (from 0930 @ 107 s): a buzzy tone, fundamental ~400 Hz, strong harmonics at every multiple up to ~5 kHz (sawtooth-like), held 0.3-2.6 s, sometimes as 2-3 short beeps.
- **Turn-signal chime** (heard in our car twice): ~2.0 kHz sine beep, 2.5 per second, 50% on. Good for the player's car indicator sound.
- **City bed:** most energy below 150 Hz (low engine/road rumble), little above 2 kHz. Moving is ~10 dB louder than idling at a red.
- **Highway bed:** flat, steady roar with more 200-2,500 Hz tyre hiss than the city; add ~1 s broadband whooshes when a bus or lorry passes the other way.
- **Inside buildings / flats:** quiet room tone ~15-20 dB below the street, faint AC hum; stairwells have hard footstep clicks with a short echo.
- **Birds:** one clear call (0927), no constant birdsong in the clips.

## 6. Small things seen while checking (not in the catalogues)

- **Diesel generator on the pavement** (0930 @ 62 s): a big orange "POWER" genset box in front of a white shop with a large black "BA" logo and Burmese sign. Generators outside shops are normal (power cuts). Good street prop.
- **Old green army-style lorry** with a canvas cover and a red/yellow plate panel (0930 @ 68 s and 102 s), queued with the cars.
- The EV City Taxi in the 0930 queue has cartoon stickers and a round green sticker on the rear glass; sticker-covered back windows are common.

## Not checked / limits
- The detector counts are approximate (handheld camera, 2 fps tracking can split one car into two tracks, or miss cars out of shot).
- Speech was not transcribed (no useful content expected; it's passengers chatting).
- The 3.3 kHz tone in 0930 and the thump in 0935 were not confirmed by eye.
