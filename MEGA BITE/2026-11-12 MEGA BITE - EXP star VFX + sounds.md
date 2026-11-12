# MEGA BITE - EXP star VFX + sounds (12 Nov 2026)

Owner (12 Nov, 13:59): "i think the 3d stars on screen after eating food would be better with vfx and better sfx".
The stars: `MB_UIMotion` section 1, 3D gold star meshes in a full-screen ViewportFrame (`MB_UI3D`) that burst out of every EXP gain (eat, quest done, reward toasts) and fly into the EXP counter. Before: no VFX and no sound of their own.

Research used: `Roblox Playbook\Research notes\Playbook notes - Sound and music.md` (a reward sound = transient + tonal body + sparkle tail; identity in 1-5 kHz for phones; coin ticks 40-60 ms apart; escalate a fixed signature sound by rising pitch only; batch many pickups into ticks + one final ding), the polish bible's coin-fly timings (already in the code), K06 (particles don't draw in ViewportFrames).

## VFX (2D layers that follow the 3D stars)
- Two new ScreenGuis: `MB_UI3D_Back` (DisplayOrder 11, under the stars) and `MB_UI3D_Front` (13, over them); both ignore the top-bar inset like the star layer.
- **Pop-out:** a small gold glow flash (14 -> 64 px) + `UIFx.BurstAt` (6 white-warm glints, a ring, 2 bubbles).
- **Each star:** a gold glow halo behind it (2.6x the star's size on screen, flickering slightly); a sparkle trail of gold/warm glints every 45 ms while it moves (not while it hangs); one white twinkle glint at the top of its pop.
- **Landing:** a warm flash on the counter for every star; a glint ring for the last one (with the existing counter pop).
- Images are pooled (up to 80); about 45 on screen at the peak of a 7-star burst. Off under Reduced Motion and while a window is open (as before).
- **Bug fixed on the way:** the stars landed ~58 px ABOVE the EXP number (the HUD's ScreenGui uses the top-bar inset, the 3D layer ignores it). The counter point now adds the inset.

## Sounds (our synth, `Audio\star\star.py` + `kit.py` = the UI set v3 helpers; C major like the UI family)
| Sound | Asset | What | Volume |
|---|---|---|---|
| StarBurst | 72479771954997 | the stars pop out: a light up-fwish + G6-C7-E7 sprinkle + sparkle, 0.48 s, -22 LUFS (sits on EatPop) | 0.4 |
| StarLand | 127305105511996 | each star into the counter: a crystal FM ting on C6, 0.40 s | 0.3 (6 players) |
| StarFinal | 131252613910925 | the last star lands: a C-E-G bell strum into sparkle + one bubble, 0.76 s | 0.42 (2 players) |
- All Approved before use. 1-5 kHz share: 87 / 100 / 98 %; nothing under 300 Hz.
- **The ladder:** each StarLand steps up C-major pentatonic (0, 2, 4, 7, 9, 12, 14, 16, 19 semitones, via PlaybackSpeed). It keeps climbing while you keep eating (a combo) and resets after a 1.1 s pause.
- **Pacing:** every ting is queued into its own 50 ms slot (stars that land in the same frame on a slow phone still each get their note, in order); a backlog over 0.35 s is dropped. StarBurst at most every 0.12 s, StarFinal every 0.3 s.
- `MB_Sounds.S.Play` now prefers a copy that is not still ringing (a re-Play restarted it and cut the earlier note). Helps every sound with variants.
- Preview of two quick eats (5 + 6 stars): `Audio\star\mb_sfx_star_preview.ogg`.

## Checked in Play (Studio, desktop)
- Two bursts 0.6 s apart: 2 StarBursts, all 11 tings in order (1.00 -> 3.00 speed), StarFinal on the first; no script errors.
- Frames: stars pop with gold halos, the trail streams to the counter.
- Not checked: a real phone, Reduced Motion, the landing flash frame (timing: the coordinates were checked in code).

Old scripts: `ServerStorage.MB_UIMotion_preStarFx_12Nov`, `MB_Sounds_preStar_12Nov`.
