# Sound

The genre is dense with sound: every visible action has its own effect, ambience fills every gap, a light music bed
runs under the cold open and cuts out at the turn. All of it is synthesised in code by `scripts/synth.py` (free, no account), cached in
`library/sfx/`, so a clip is made once and reused by every later episode. The shipped starter clips there are reused as they are.

## Writing the events

One event per visible action, cued to the shot it happens in, so retiming the voice never breaks the sync:

```json
"events": [
  ["S2+6", "glass_tink", 0.5],                    cue, clip, gain (0..1, clips are peak-levelled first)
  ["S3+2", "whoosh", 0.4, "peak"],                "peak": the clip's loudest moment lands on the cue (whooshes, booms)
  ["S1", "kitchen_tone", 0.12, "onset", "S6"],    an ambience from S1 cut (with a fade) where S6 starts
  ["paste+2", "pop", 0.5]                         or cue on a word
]
```

- **A hit that illustrates a word lands in the pause after it, never on it.** The copy-paste run first put each
  paste's pop on the word "Paste" and covered it; moved four to six frames later, into the gap, the word reads and
  the pop lands as the answer to it. Move the picture with it (the copy appears with its sound).
- **Align by the attack, not the file start:** `onset` (default) finds where the clip actually starts sounding. A hit
  on the frame of the visible impact; a whoosh with `peak` on the frame of the fastest movement.
- **Layers for each beat:** the action (a step, a catch), the power (its signature sound every time it's used), the
  reaction (a laugh, a gasp, a sparkle), and the room (an ambience per location, cut at the location change).
- **The power's sound** is the episode's signature: the same clip every time, so the viewer hears the rule.
- **The turn** gets a low hit (drone or boom) on its first frame, the music cut on the same frame, and one detail
  sound repeated (bulbs dying, lights switching off) through `repeats`.
- **Silence is a tool:** cut the music a beat before the title boom or the turn so the hit lands in a gap.

## Clips: the free synth bank

A clip is `"name": ["prompt", seconds]`, or `["prompt", seconds, "kind"]`, or `["prompt", seconds, "kind", {"param": v}]`.
The kind picks a generator; with none it is read from the name first, then the prompt (whole words). Kinds: hit boom
whoosh click pop tink ding sparkle buzzer drone hum room wind step crunch rewind glitch riser fall chirp laugh gasp
yowl swallow switch music. Name the clip for what it is (`door_slam`, not `thing3`) and pass the kind when the name
could mislead. Parameters worth knowing: `f` (pitch of tink, ding, buzzer, drone, hum), `f0`/`f1` (start and end of
hit, whoosh, pop), `bpm` (music). Durations: 0.5 to 1.6 s for hits, 2 to 12 s for ambiences, the episode's length for
the music bed. The prompt is only a cache key and a note to yourself, so change it (or the length) to force a remake.

Synth sounds are plainer than recorded ones, especially the voice-like clips (laugh, gasp, yowl): keep those short,
quiet and under the voice. Listen to every new clip once; if one is wrong, give it another kind or parameters.

## Levels

`sfx.py` measures the voice and each stem and sets their volumes in the mix:

- effects stem: `sfx_lu` LU against the voice, integrated. The default, +1.5, is about where the approved proof clip
  sat (+1.9); the copy-paste run settled at -1.5 after the mix check. The stem is sparse, so its gated loudness reads
  high: these numbers sound denser than they look.
- music bed: `music_lu` (default -9.5) LU against the voice.
- The whole effects stem is levelled to `sfx_lu`, so lowering one event's gain makes the others louder. Lower events
  to change the balance inside the stem; lower `sfx_lu` to give the voice more room overall.
- The final mix is brought to -14 LUFS with true peaks under -1 dBTP by `master.py`.

Then run `mixcheck.py`: it lists the spoken moments where effects or music come within 3 dB of the voice. Fix the
words that matter (the fact, the last line) by moving a hit into the pause after the word or lowering it; a title
boom or a drone on the turn can stay. The proof clip had 30 such moments at 0 dB; copy-paste shipped with 14.

## Costs

None: the voice and the sound are free and run offline.
