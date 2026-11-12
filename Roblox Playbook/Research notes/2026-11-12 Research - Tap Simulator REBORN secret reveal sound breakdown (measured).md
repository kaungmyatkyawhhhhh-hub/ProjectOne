---
tags: [research, sound, sfx, reveal, christmas, gymarc, reference-study]
created: 2026-11-12
---
# Research: Tap Simulator REBORN secret-pet reveal, sound broken down layer by layer
Date: 12 Nov 2026 · Video: D0Culetz "I opened 200.000+ EGGS and HATCHED This SECRET in Tap Simulator Reborn" https://www.youtube.com/watch?v=rBA8tIo4apg (raw clip, no commentary, 0–41 s measured)
Method: the YouTube player's audio was tapped into Web Audio in the built-in browser (PC kept silent). I measured level, energy in 5 bands (sub <120 Hz, low 120–400, mid 400–1.5k, high 1.5–5k, air 5–16k) and the peak frequency every ~15 ms, detected the sound starts, then lined each one up with frames from the video.
Related: [[2026-11-12 Research - Modern Roblox advent calendar and pass UI (videos watched)]] (the picture side), [[2026-11-11 Watch study - Titan Simulator clips + Venom sound measured (YouTube in the browser)]] (same measuring method).
Caveat: the sound was MEASURED, not heard. Pitches are approximate to about ±23 Hz (FFT bin width). Levels are relative to each other, not absolute.

## Timeline: picture and sound
| Time | On screen | Sound measured |
|---|---|---|
| 0–13 s | "Hold to Reveal": a black silhouette egg, coloured energy wisps (purple, green, yellow) swirling round it, sparkles | **Heartbeat sub-thumps** at 0.66, 4.33 and 7.92 s (~3.5 s apart): a pure low hit around 47 Hz, ~0.45 s decay, the loudest layer. **Air shimmer bed**: a 5–16 kHz sparkle wash that starts at 2.1 s and lasts ~7 s |
| 3.1 s | A white ring pulses out from the egg | Two **clicks** in the mids (~940 then ~1055 Hz), 40 ms each |
| 6.7–7.1 s | The wisps speed up | A **rising tick run**: 938 → 1055 → 1148 → 1266 Hz, one tick every 0.12 s, 40–60 ms each (roughly whole-tone steps going up) |
| 13.5 s and 18.9 s | The egg turns into the glowing "?" egg with sparkles | **Shimmer swells**: air band only, ~0.9 s each |
| 23.4 s | Hard cut to a dark cutscene world | **All highs drop out** (high and air fall ~50 dB). Only a sub drone around 70–95 Hz is left. This "vacuum" builds tension |
| 23.9–24.9 s | The camera creeps | Three soft **sub pulses** under the drone |
| 26.0 s | Dark silhouette shot | **THE DROP**: the biggest rise in the clip (+64 dB in 60 ms), a pure sub boom around 47 Hz with a 1.5 s tail. Nothing above 400 Hz |
| 27.6 s | Text "Did you hear that?" | A sub rumble, ~1 s |
| 29.0–31.0 s | A cracked, glowing purple egg fades in | An **accelerating heartbeat**: sub thumps at 29.0, 29.5, 29.94, 30.3, 30.6, 30.82 and 31.03 s. The gaps shrink 0.50 → 0.44 → 0.36 → 0.30 → 0.22 → 0.21 s |
| 31.6 s | **REVEAL**: purple light rays burst out of the egg | A big impact: sub plus high-mid content returning, 1.3 s tail. The full spectrum opens back up |
| 33.4 s | Title "SECRET DISCOVERED / VOID WRAITH / 1/25,000,000" | A second **title-slam hit**: sub plus mids, 1.3 s tail |
| 36.8 s | Back to gameplay | Near silence, then a crisp **UI click** at 37.08 s (mid ~1150 Hz, 20 ms) |

## The layers (how the sound is built)
1. **Sub heartbeat:** a ~47 Hz thump with ~0.45 s decay. Slow at first (3.5 s apart), then accelerates (0.5 → 0.2 s) just before the reveal. It's the backbone of the tension.
2. **Air shimmer bed:** a constant 5–16 kHz sparkle wash while the player holds. It makes the egg feel magical without any melody.
3. **Rising ticks:** short mid clicks (~1 kHz) climbing in pitch, about 8 per second. Pure anticipation.
4. **Shimmer swells:** ~1 s air-band swells each time the egg changes stage.
5. **Vacuum:** right before the big moment, every high frequency is cut and only a sub drone remains. The silence of the highs makes the drop hit harder.
6. **Sub drop:** one huge, isolated sub boom (~1.5 s tail) inside the vacuum.
7. **Reveal impact:** sub plus highs returning together, the "full spectrum opens" moment, timed to the light-ray burst.
8. **Title slam:** a second hit, about 1.8 s later, when the name and "1/25,000,000" appear.
9. **UI click:** a tiny, clean ~20 ms mid click for every button.

Structure rule: **tension (thin, sub plus air) → vacuum → drop → full-spectrum reveal → title slam.** The reveal hit lands exactly on the visual burst, and the heartbeat speeds up to point at it.

## Applied to the GYM ARC Advent calendar (decision)
- **Small days:** a short version, about 2.5 s: one sub thump on tap → rising ticks while the present shakes → reveal impact + sparkle on the burst → a small title hit → coin ticks to the HUD.
- **Big days (7, 14, 21, 24):** the full cutscene recipe: heartbeat + shimmer bed → vacuum → sub drop → accelerating heartbeat → full-spectrum reveal → title slam. Gym flavour: the heartbeat could be a barbell plate thud, the ticks a ratchet/clicker.
- All sounds are synthesized in code by Claude (no Fish Audio / ElevenLabs), using these measured pitches, decays and timings as the target.
