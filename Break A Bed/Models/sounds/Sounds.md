# Custom sounds (made by Claude, 2026-10-14)
Synthesized with code (`../source/sounds.py`), so they're 100% ours, with no copyright issues. They replace the pitched-up/down game sounds. Format: OGG, 44.1 kHz stereo. Upload with Asset Manager (Audio) and use the ids.

| File | Use it for | Length |
|---|---|---|
| `gong.ogg` | belt earned (the gong), master belt (play at PlaybackSpeed 0.8 for a deeper gong) | 7.5 s (fades) |
| `wind_chime.ogg` | Sensei when a player comes close; the first-join intro | 6 s |
| `singing_bowl.ogg` | Sensei's idle hum (Looped, very quiet, RollOff 30 studs) | 6 s loop |
| `taiko_hit.ogg` | single drum hit (cutscene beats, Sensei appears) | 2.4 s |
| `taiko_pattern.ogg` | belt-test bed drums when you walk near; intro fly-down | 4.4 s |
| `flute_phrase.ogg` | crane rebirth cutscene | 4.6 s |
| `whoosh_rise.ogg` | rebirth swirl / tornado rising | 2.5 s |
| `sparkle.ogg` | belt flies onto you, stripe appears, rewards pop in | 2.6 s |
| `boom.ogg` | the burst moment (flash + shockwave) in every rebirth cutscene | 3.5 s |

**Animal voices** (tiger roar, dragon roar, phoenix screech) can't be synthesized well. Use Roblox's own licensed sound library in the Creator Store (Audio tab, made by Roblox; sounds have no scripts, so they're safe). Search "tiger roar", "dragon roar", "eagle screech" (for the phoenix), "ice crack", "coins", "bubbles". Mix each one under `boom.ogg` at the burst.

## Combo sound: do re mi... (owner, 2026-10-14)
`combo_1_do.ogg` … `combo_8_do2.ogg`: 8 **heavenly high piano** notes (C6 up to C7, with a soft octave shimmer above and a long airy reverb), going up the C major scale (do re mi fa so la ti do). `combo_demo.ogg` plays it twice so you can hear the idea.
- (Changed 2026-10-14: the owner wants a heavenly, very high-pitched piano. The current files are high piano C6–C7 with shimmer and reverb.)
- **Every punch (training and breaking) plays the next note:** do → re → mi → fa → so → la → ti → high do, then **back to do** and up again.
- If no punch for **1.2 s**, the scale restarts from do next time.
- On the 8th note (high do) add a tiny sparkle burst on the punch popup, as a small reward for finishing the scale.
- Volume follows the Sounds slider, about 0.35 so it doesn't get annoying at 8 punches/second. Only the punching player hears their own notes.
- Alternative if 8 files are a hassle: upload only `combo_1_do.ogg` and set `PlaybackSpeed` to 1, 1.125, 1.25, 1.333, 1.5, 1.667, 1.875, 2.
