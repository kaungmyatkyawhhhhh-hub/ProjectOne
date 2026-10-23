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
`combo_1_do.ogg` … `combo_8_do2.ogg`: 8 **heavenly high piano** notes (C6 up to C7 with a soft octave shimmer; only a little reverb, changed after the owner said there was too much). `combo_demo.ogg` plays the scale with a pause between notes, like breaking beds in a row.
- **It plays on each bed BREAK, not on each punch (owner, 2026-10-14):** the 1st break plays **do**, the 2nd **re**, then mi, fa, so, la, ti and high **do**, then back to **do** and up again.
- It plays together with that bed's own break sound (below), a little quieter (volume ~0.5).
- If the player doesn't break a bed for **15 s** (or leaves the bed area), the scale restarts from do on the next break.
- On the high do (8th break), add a small sparkle burst and a "COMBO x8!" pop.
- Only the breaking player hears their own notes. Volume follows the Sounds slider.

## Unique break sound for every bed (owner, 2026-10-14)
`bed_breaks/bed01_cardboard.ogg` … `bed25_infinity.ogg`: **25 different break sounds**, one per bed, made with code to match each material. Play the bed's own sound when it breaks (instead of the shared one). Hits during chopping can keep the normal punch sound.

| # | Sound |
|---|---|
| 1 Cardboard | paper rip + soft box thuds |
| 2 Air Mattress | pop + air hissing out |
| 3 Sleeping Bag | fabric rip + soft thud |
| 4 Wooden | wood crack + wooden pieces knocking |
| 5 Bunk | big crack + boom + lots of wood pieces |
| 6 Water | pop + splash + drips |
| 7 Hospital | metal clank + rattles + monitor beeps |
| 8 Royal | wood crack + royal chime |
| 9 Gold | gold clang + raining coins |
| 10 Diamond | bright glass shatter + sparkle chime |
| 11 Emerald | gem shatter, lower + ring |
| 12 Ruby | deep gem shatter + boom |
| 13 Ice | ice crack + tinkling shards |
| 14 Lava | rock crunch + boom + sizzle |
| 15 Crystal | crystal shatter + magic chime + shimmer |
| 16 Neon | glass + electric buzz + zap |
| 17 Robot | metal crash + powering-down whine + sparks |
| 18 Alien | wobbly zap + goo splat + rising beep |
| 19 Lunar | muffled rock crumble + low boom (echo) |
| 20 Solar | fiery whoosh + big boom |
| 21 Galaxy | whoosh + star chime + boom |
| 22 Nebula | airy whoosh + soft chimes |
| 23 Black Hole | sucking-in rise + huge boom |
| 24 Cosmic | rising chime + boom + shimmer |
| 25 Infinity | heavenly chord + boom + shatter |
