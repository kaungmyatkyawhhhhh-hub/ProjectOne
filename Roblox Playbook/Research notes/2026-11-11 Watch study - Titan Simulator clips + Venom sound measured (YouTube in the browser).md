---
date: 2026-11-11
tags: [research, reference-study, titan-simulator, venom-evolution, sound, youtube, stomp-evolution]
---
# Watch study: Titan Simulator clips + the sound of +1 Venom Evolution, measured (11 Nov 2026, 02:45 to 03:25)

Owner (02:40): "try to fetch audio from youtube, find & get a tool if u cant rn. and also watch titan simulator clips from youtube and the gameplay was addicting, but the looks are trash".

Links: [[2026-11-11 Reference study - +1 Venom Evolution (art, models, UI, VFX, loop)]] · [[2026-11-09 Research - Dead game method (shut-down multiplayer games as an idea library)]] · [[TITAN ARC/2026-11-11 TITAN ARC - Design doc v0 (draft)]] · tool: `Roblox Playbook\Tools\Video kit\youtube_watch_in_browser.js`

## 0. Honest limits
- I do not hear. The sound was **measured** in the browser (level, pitch bands, when sounds start, how long, how loud against the bed) and lined up with frames.
- No audio file was downloaded. The workspace cannot reach YouTube (the proxy refuses `www.youtube.com`, a policy block I do not go around), and the Blender bridge was not connected, so yt-dlp could not run on the PC either.
- Every Venom video found has a YouTuber talking over it (voice in 95% of the 3 minutes checked; only 8.4 s of 180 s were free of it). I removed the voice with a stereo trick (left minus right), which also removes anything the game plays dead centre.
- Titan Simulator: 3 clips, sampled by frames. The thresholds and UI words below are read from frames.

## 1. Getting audio from YouTube: what works now
| Route | State | Gives |
|---|---|---|
| **In the owner's Chrome: `youtube_watch_in_browser.js`** (new, built and tested tonight) | **works** | level, band balance, every sound start, spectrogram under a frame strip, the biggest sound events, voice removal. Silent on the PC. 2x speed. |
| yt-dlp in Claude's workspace (2026.10.26 installed) | blocked | needs youtube.com + googlevideo.com allowed in claude.ai Settings → Capabilities (owner) |
| yt-dlp on the PC through Blender | Blender was closed | the real file; then EarShot (already approved 7 Nov) can describe each sound in words |
| A screen recording of the owner playing with game sound | best quality | clean game audio with no YouTuber |

How the new tool works: the page's own video plays into Web Audio, a recorder node collects the samples, a gain of 0 keeps the PC silent. It needs one real click on the page first (Chrome's rule). It puts the player's mute and volume back afterwards.

## 2. Titan Simulator (2017), watched
Clips: "ROBLOX TITAN SIMULATOR| HOW TO BECOME BIG FAST!" (3 min, a new player, game sound only), "Powering Up To Rebirth" (XdarzethX, 11 min, a veteran through a rebirth), "BIGGEST TITAN in ROBLOX" (21 min, sampled at 9 points; its sound is 94% voice).

### Why it was addicting (what the frames show)
1. **Every click pays, anywhere.** You punch the air and "+130" fists pop around you. No target, no walking, no waiting. This is the big one.
2. **The number that matters is always on screen:** "NEXT EVOLUTION AT: 200,000" bottom-left, with "DAMAGE MULTIPLIER: 4x" above it.
3. **Everyone is a different size in ONE field.** A new player stands between the legs of giants in the first seconds; a far giant shows as a silhouette in the haze. You see what you will become without any menu.
4. **Evolutions come fast at the start.** After the rebirth the thresholds read 150 → 2,500 → 4,500 → 30,000: three evolutions in about two minutes.
5. **Rebirth = tiny again, in the same server, among the giants,** with a bigger multiplier and a fast re-climb. The purple REBIRTH button is always visible bottom-right.
6. **Two numbers on the leaderboard: Power and Kills.** Tools: Punch, Stomp, Rage, a sword. Chat in the clip: "THEY KILL ME".

### Why the looks are trash (the owner is right)
- Shop = six plain coloured rectangles with default text down the left edge ("[PERMANENT] DOUBLE POWER!", "Growth Elixir", "5x / 10x / 50x Power Boost").
- Default Roblox leaderboard, default tool bar, no UI art, no icons.
- The only effect is a flat fist picture and a number.
- Default smooth terrain, flat green blobs for trees, haze hiding an empty map.
- An "evolution" is your avatar made bigger with a catalogue armour pack on it. No new shape, no name card, no moment.
- Sound (new-player clip, no voice): a music track that loops every 64.2 s with a gap of about 1 s at the loop point; a sound starts every 0.25 s and they are very regular (57 to 67% on the grid), which is the music's notes. No separate punch sound shows in the spectrogram. Most likely the game's own loop and nothing else.

So the game was a bare clicker with one great idea (your body is the score, and everyone can see it) and zero craft. That is why a modern version can win: same pull, real art.

## 3. +1 Venom Evolution: the sound, measured
Video: "Getting #1 LEADERBOARD in Roblox +1 Venom Evolution..." (VitaminSleepy), four windows between 150 s and 908 s.

| Measure | With the voice | Voice removed (left minus right) |
|---|---|---|
| Sound starts per second | 4.1 (150-330 s), 4.6 (900-908 s) | 3.9 (150-250 s), 4.0 (330-830 s) |
| Typical gap between sounds | 0.19 to 0.21 s | 0.24 to 0.25 s |
| Energy 60-250 Hz / 250-2,000 Hz / above 2,000 Hz | 46% / 36% / 16% | 45% / 41% / 4% |
| Level | -21 dB | -48 to -51 dB (the game mix is close to mono) |

What that says:
1. **It is never quiet.** A sound starts about 4 times a second for the whole 12 minutes checked. Every hit, pick-up and tick has a sound.
2. **The weight is low.** Almost half the energy is under 250 Hz: thumps and bass, not sparkle.
3. **Big moments are rare, short and much louder.** In 500 s only 5 events stood well above the running level, each 0.3 to 0.5 s long and filling the whole range from 60 Hz to 11 kHz:
   | Time | Length | Above the bed | What the frame shows |
   |---|---|---|---|
   | 583.8 s | 0.47 s | +23 dB | boss "Scrap King" dies (HP 312K → 22), then "STAGE CLEARED" |
   | 747.0 s | 0.47 s | +20 dB | a big ability: black tendrils, ground cracks, white-purple flash |
   | 642.7 s | 0.29 s | +19 dB | "STAGE 6 ... STAGE CLEARED" + "Quest complete: Defeat 6 bosses!" |
   | 791.8 s | 0.29 s | +17 dB | a hit in the boss fight with "Relay" |
   | 344.5 s | 0.38 s | +13 dB | a letterboxed close-up of the creature's head (cutscene) |
4. **The boss kill is a double hit:** the kill burst, then a second bright burst about 1 s later with the "STAGE CLEARED" text.
5. **The mix is close to mono** (the stereo part is 26 to 30 dB under the middle). Likely the sounds are played flat to the player, not placed in the 3D world. It could also be how the YouTuber recorded.

New facts from these frames for the Venom note: stages with waves ("STAGE 1", "DEFEAT THE WAVE", "Recommended Level 5", a countdown clock), named bosses with a portrait HP bar (Scrap King, Warden Vale, Relay), "Level 35 MAX", "Total Venom: 18M", a row of paid "+10K / +100K / +1M / +2M Venom" buttons along the bottom, "Friend Boost", "x2 Wins", a Starter Pack button.

## 4. Sound rules for Stomp Evolution (from the numbers above)
1. **No silent action.** Every stomp, coin, tick and UI press makes a sound; aim for 3 to 5 sound starts a second while playing.
2. **The stomp is a low thump:** core energy 60-250 Hz, 0.15 to 0.25 s, 3 variants with small pitch changes; the prop's crumble sound (by material) sits on top.
3. **Save the big burst** for evolve, boss kill, the crown and ROGUE ALERT: 0.4 to 0.5 s, full range, at least 15 dB above the bed.
4. **Double hit on rewards:** the burst, then about 1 s later a second bright sting together with the name card or "CLEARED" text.
5. Music bed steady and quiet under all of it, so the bursts have room.
6. Make the sounds with the game-sounds method (Fish Audio), then measure ours with the same tool against this table before the owner hears them.

## 5. What Stomp Evolution takes from Titan Simulator
1. **Every stomp pays, even on bare ground.** A stomp with no prop under it gives 10% of your best prop's Mass and leaves a footprint. Tested (`TITAN ARC\Calc\anytap.py`, 200 runs each): taps that pay 42% → 100%, longest wait for a reward in minute 1 from 1.9 s → 0.5 s, first boss 9.8 → 9.5 min, so the pacing holds. At 25% the boss comes at 9.3 min; at 50% the city stops mattering. **10% it is.**
2. **Giants walk the starter street.** The way to the next district, the upgrade pads and the Sumo Ring sit so that big players cross the first street. A new player sees ankles in the first 30 s. Their steps shake your screen and bounce you; they never hurt you (no PvP in the city stays).
3. **The NEXT number is always on screen** with the form's name: "NEXT: ROCKHIDE at 3.0 m".
4. **AWAKEN works like Titan's rebirth:** tiny again in the same server among the giants, and the first four forms come back in about 2.5 minutes.
5. **Two numbers on the board:** HEIGHT and Sumo wins.
6. **Not taken:** 5x / 10x / 50x paid power (pay to win), killing small players on the field, text buttons, catalogue armour as "evolutions".
7. **Boss name clash:** Venom has a boss called "Scrap King". Ours was "Scrap Colossus", a scrap robot too. Renamed **JUNK TITAN** (not yet checked against other games).

## 6. Next
- With the audio file itself (owner allows the two YouTube domains, or Blender is open), EarShot can put words on each sound. Best of all: 2 minutes of the owner playing Venom with game sound recorded.
- The tool reads only what plays; a 10 minute video takes 5 minutes at 2x.

## Sources
- YouTube: youtube.com/watch?v=wPRhmNIH6hE · youtube.com/watch?v=L5FwKiZKRyQ · youtube.com/watch?v=ZH8lSzjwBAI · youtube.com/watch?v=wwHpliHsQfA (watched in the owner's Chrome, 11 Nov 2026)
- Roblox API: apis.roblox.com/search-api/omni-search (+1 Venom Evolution, 20,650 playing at 03:05), games.roblox.com/v2/games/10769464063/media (2 images, no video on the game page)
