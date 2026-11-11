# Modern SFX and Audio Direction for a Kids' Mobile/Roblox Underwater Shark Game (Nov 2026)

Scope: how pro teams build SFX (layering, frequency slots, variation, pitch-as-size, ducking, phone loudness), underwater audio, creature/ability/transformation/UI sounds, adaptive music, AI SFX prompting (Fish Audio) and processing, and the Roblox audio API as of Nov 2026. Research note: ~40 tool calls; several sources (Audiokinetic UI blog, A Sound Effect UI page, League SFX stories, a 2024 Roblox DevForum features thread) failed to load or had no body text. Hungry Shark and Supercell audio have no public deep-dive that I could find (see Gaps).

## 1. Recipes: transformation/evolve, sea-monster roar, bite/chomp, dash, shockwave, pickup, level-up, UI click/hover/open/close, reward reveal

### Takeaway
Every pro "big" sound uses the same 4-layer build: a bright transient (above 1 kHz), a tonal mid body (~200 Hz), a falling-sine sub (30-60 Hz, 200-400 ms), and a dark reverb tail on the body only. Game hits get trimmed to a few hundred ms so they don't tire players. Creatures are built from animal sources (big cats, pigs, dogs, alligators, elephants) plus breaths, and are pushed bigger than feels needed. Risers use an exponential curve that peaks exactly on the impact. UI cues are short (30-150 ms taps, up to ~500 ms chimes), use rising pitch for good outcomes, and all come from one shared patch.

### Cited Findings
**Impact layering (base for bite, shockwave, evolve hit, level-up thump)**
- Transient = the "click"/crack the ear latches onto, "lives mostly above 1 kHz" (snare, clap, stick hit, fast noise burst). Body = weight and tone, mid-range, around 200 Hz in their example (tom, kick, metal, synth stab, reversed gong). Sub = 30-60 Hz, a single sine with falling pitch. Tail = a long dark reverb on the body, with the sub kept dry. — [Violet Recording: impact sounds](https://violetrecording.com/how-to-make-impact-sounds/)
- Sub pitch drops high→low over about 200-400 ms with a fast decay. All layers start on the same downbeat. Trailer hits let the sub ring 800 ms or more, but "Game or UI hits: trim to a few hundred milliseconds so repeated triggers don't fatigue." — [Violet Recording](https://violetrecording.com/how-to-make-impact-sounds/)
- Process: build the sub, add the body, add the transient, saturate body and transient, add a dark reverb, EQ each layer into its own range, bus-compress to glue ("glue rather than squash"), and high-pass the sub below ~25 Hz to save headroom. — [Violet Recording](https://violetrecording.com/how-to-make-impact-sounds/)

**Risers / transformation build-ups**
- Three riser types: (1) a noise sweep (white/pink noise, band-pass or high-pass cutoff rising, volume swelling); (2) a pitch riser (sustained saw/wavetable note pitched up, or a Shepard-tone stack across octaves with the top and bottom layers fading); (3) a reversed cymbal or reversed reverb swell, stretched, with a filter opening. — [Violet Recording: risers](https://violetrecording.com/how-to-make-risers-and-sweeps/)
- Length: 1-2 beats for a quick lift, 4-8 bars for a big build. Use an exponential curve "so most of the change lands in the final beat or two"; a linear rise "feels mechanical." Peak "exactly on the downbeat," then cut or duck the riser, add a short down-sweep or a beat of silence, and high-pass the riser so energy doesn't pile up below 100 Hz. — [Violet Recording: risers](https://violetrecording.com/how-to-make-risers-and-sweeps/)
- "Braam" = a big brassy cinematic hit for epic moments. "Whoosh" = movement through air. "Drone" = continuous texture that builds suspense. "Glitch" = jittery malfunction for transitions. — [ElevenLabs SFX docs](https://elevenlabs.io/docs/overview/capabilities/sound-effects.md)

**Creatures (roar, growl)**
- David Farmer (The Hobbit) on sources: tigers and lions "provide a size and ragged aggressiveness" but lack a tonal bellow. Pigs and dogs are good bases. The Jurassic Park T-Rex roar reportedly came from a baby elephant ("you might just find that signature sound in a place you weren't looking for it"). — [A Sound Effect: creature sound design](https://asoundeffect.com/creature-sound-design/)
- Breaths, lip smacks and small sounds "stitch a creature together." For Smaug, alligator growls plus vocoded human breaths and hisses kept the creature present between lines. Pitch moves add expression. Compression and saturation add size but also add noise. Push processing too far, then pull back. Farmer's most common note: "it doesn't sound big enough." — [A Sound Effect](https://asoundeffect.com/creature-sound-design/)

**UI**
- "Most interface cues last under 300 milliseconds." Taps/clicks: 30-150 ms. Notifications and success chimes: up to ~500 ms. Trim leading silence so the cue starts on its transient. — [Violet Recording: UI sounds](https://violetrecording.com/how-to-design-ui-sounds/)
- Rising pitch = positive. Falling or dissonant = negative. Success = a consonant interval going up (major 3rd or perfect 5th). Neutral tap = one static tone. Confirm = two rising notes. Error = a lower, detuned or falling tone. Notification = a 2-3 note motif. Frequent actions get higher, brighter cues; rare, weighty events get lower, fuller ones. — [Violet Recording](https://violetrecording.com/how-to-design-ui-sounds/)
- Build every cue from one synth patch, changing only pitch and envelope, with shared reverb so the UI "sounds like one product." High-pass below ~120 Hz, tame 2-5 kHz harshness, avoid tones that pierce on small speakers. Match perceived loudness, not peak level, across the family. Use sine/triangle (Vital, free), FM for bells, and layer a real finger tap under the blip. — [Violet Recording](https://violetrecording.com/how-to-design-ui-sounds/)
- Informational ability audio: Mercy's heal beam in Overwatch "rises in tone as the healed player's health increases" (pitch = progress). — [PC Gamer on Overwatch GDC 2016](https://pcgamer.com/how-overwatch-uses-sound-to-pinpoint-threats-you-cant-see)

### Inferences (recipes I put together from the cited techniques; these are design proposals, not sourced recipes)
- **EVOLVE / transformation (~2.5-3.5 s total):** (a) A 1.5-2.5 s riser: filtered noise sweep plus a pitch riser or Shepard stack, plus bubble swirl and a reversed whale-ish swell, on an exponential curve. (b) A ~100-200 ms beat of near-silence or a suck-in reverse. (c) A layered impact on the reveal frame: bright transient, ~200 Hz body (gong or synth stab), a sub sine falling from ~120→40 Hz over 300 ms, and a braam-like brass/choir tone in a major key so it feels heroic, not scary. (d) Shimmer tail: high bell/glock arpeggio going up, plus a sparkle reverb, 0.8-1.5 s. (e) A creature "new form" roar of 0.5 s after. Duck music and ambience under it via sidechain.
- **Kid-friendly sea-monster roar:** keep it big (sub + low growl body, per Farmer) but cut the scary cues. Use a lower-mid "bellow" (walrus/elephant/whale-like tone) layered with a pitched-down lion for texture. Add a short upward pitch bend at the end (rising = playful). Use less harsh 2-5 kHz rasp and no screams. Wrap it in water: low-pass ~2-4 kHz, a bubble burst on the attack, and a short wet reverb. Bigger shark tier = the same roar played 2-4 semitones lower, with more sub and a longer tail (pitch-as-size).
- **Bite/chomp (≤300 ms):** transient (teeth clack or snap, wood/plastic snap, >1 kHz) + body (wet crunch: celery/lettuce or a squelch, 200-800 Hz) + a tiny sub thump on big prey only + a short bubble pop tail. Use 4-6 round-robin variations with random pitch ±5-10% (Sound.PlaybackSpeed 0.9-1.1). Combo bites step the pitch up by semitones.
- **Dash:** an underwater whoosh (filtered noise pass, high-pass rising), a bubble trail, and a short low "thrust" thump at the start, ~300-600 ms, with fast attack. A flanger (AudioFlanger) gives a sweep.
- **Shockwave:** pre-roll suck (reversed reverb, ~150 ms) → impact (transient + body + falling-sine sub) → a low-passed rumble tail plus a bubble burst cloud, ~1-1.5 s. Duck other SFX.
- **Pickup (coin/food/orb):** a bright 2-note rising chime or a single bell, 80-200 ms, high-passed at 120 Hz. Successive pickups within ~1 s step up the scale (C-D-E-G-A pentatonic, so it never goes sour), then reset.
- **Level-up:** a rising 3-4 note major arpeggio + a soft impact + a shimmer tail, ~1-1.5 s, ending on the tonic or the 5th.
- **UI click:** 30-80 ms, a soft tick plus a tiny pitched blip. **Hover:** quieter and higher, ~30-50 ms (on mobile, use it for press-down instead). **Open:** a rising "bloop" or swoosh, 150-250 ms. **Close:** the same patch falling, 120-200 ms. **Error:** a low falling 2-note.
- **Reward reveal (egg/chest/gacha):** shake ticks that speed up (riser) → reveal hit → a fanfare whose size scales with rarity (common: 2-note chime; rare: arpeggio; legendary: braam + choir + long shimmer + a confetti crackle). The rarity sound must be clear by ear alone.

### Gaps
- No primary source found for Pokémon/Nintendo UI sound specifics (interval choices, sound chip palettes); these are not covered here.
- No published recipe specifically for "kid-friendly roar"; the recipe above is an inference.

## 2. Prompt-writing for AI SFX generators (Fish Audio, ElevenLabs) to get usable results first try

### Takeaway
Generators handle one sound event per prompt best. Write prompts as action + source/material + environment + intensity/character + duration/loop, using audio terms (impact, whoosh, braam, drone, one-shot, loop). Generate each layer separately, then layer and process them in a DAW/Python. Fish Audio's public docs are thin: there are settings for duration, guidance and steps, MP3/WAV download, and commercial rights on paid plans.

### Cited Findings
- ElevenLabs: simple prompts work best for single SFX. Adding detail ("high-quality, professionally recorded footsteps on grass, sound effects foley") can help. Complex multi-event prompts "may not give the best results"; they recommend generating each sound individually and combining them in an editor. — [ElevenLabs help: prompting SFX](https://elevenlabs.io/docs/help-center/product/core-capabilities/sound-effects/how-do-i-prompt-for-sound-effects)
- ElevenLabs API: 0.1-30 s per generation. "Prompt influence" set high = literal, set low = creative with variations. Loop mode is available. `eleven_text_to_sound_v2` is deprecated (removal 1 Mar 2027); `eleven_text_to_sound_v3` follows multi-part prompts better. Output is MP3, or 48 kHz WAV for non-looping sounds. Exact repetition counts are "not always followed." Describe action, setting, atmosphere and performance, and for sequences describe the order of events. — [ElevenLabs SFX docs](https://elevenlabs.io/docs/overview/capabilities/sound-effects.md)
- Fish Audio SFX page: "fine-tune duration, guidance, and steps." Download as MP3 and WAV. SFX generated on paid plans "include full commercial rights" for games. The featured prompt layers character, motion and texture: "Powerful helicopter takeoff: rapidly building rotor blades whirring and chopping, increasing engine whine, ground vibrations." — [Fish Audio Sound Effects](https://fish.audio/sound-effects/)
- Fish Audio blog (general guidance): the model reads action, material, environment and emotional tone. An improved prompt example: "Deep cinematic explosion with low-frequency rumble and debris falling in the distance." Generate several variations, layer and polish in a DAW, and test in the scene. — [Fish Audio: how to generate SFX with AI](https://fish.audio/blog/how-to-generate-sound-effects-with-ai/)
- Fish Audio blog: be specific (adjectives plus context), because vague prompts give unusable results. Ask for loopable output for ambience. Layer generated sounds (e.g. a low boom plus a sub element). Busy environments may need hybrid design. WAV/AIFF are better for games than MP3. — [Fish Audio: SFX generator guide](https://fish.audio/blog/sound-effects-generator)
- Fish Audio's blog does not document numeric duration limits or what the guidance/steps settings do. — [Fish Audio blog](https://fish.audio/blog/sound-effects-generator)

### Inferences
- **Prompt template (one layer per prompt):** `[one-shot|seamless loop], [duration] seconds, [action] of [source/material], [character: deep/bright/wet/punchy/soft], [space: underwater, close-mic, dry | small reverb], [intensity], no music, no voice, clean start, no background noise.` Example layers for a bite: "One-shot, 0.3 seconds, close-mic sharp teeth snapping shut, bright crisp clack, dry, no reverb, no background noise"; "One-shot, 0.4 seconds, wet juicy crunch of biting into a fish, cartoonish, squelchy, dry"; "One-shot, 0.6 seconds, burst of underwater bubbles rising, close, bright pops." Ask for "dry" and "clean start" so you can add your own shared reverb and trim the start.
- Generate 3-6 takes per layer, pick the best transient, and build round-robins from the variants. Never ship a single AI take raw.
- **Processing chain (Python/pydub/pedalboard, or DAW):** trim leading silence → fade out tail → high-pass (UI 120 Hz; SFX 30-40 Hz; sub layer is synthesized, not AI) → EQ each layer into its slot → light saturation → glue compression → shared reverb per family → normalize to a consistent loudness per category (e.g. measure LUFS per one-shot and match within a family) → peak limit ≤ -1 dBTP → export mono 48 kHz WAV/OGG for Roblox upload (stereo only for music and ambience beds).
- AI generators are often weak at a clean, tight sub and transient. Synthesize the sub sine drop yourself and use AI for body/texture/creature layers.

### Gaps
- Fish Audio SFX model name, max duration and exact parameter semantics are not publicly documented in the pages I could fetch. Test in-app.

## 3. Mixing, loudness and phone-speaker rules

### Takeaway
Target about -18 LUFS integrated (±2) for mobile/portable per PlayStation's guidance, with true peak ≤ -1 dBTP and LRA ≤ 20. Real phone tests show around -16 LKFS is nearly the loudest phones play before their AGC squashes it. Phone speakers roll off below roughly 220-400 Hz, so bass must be "implied" by upper harmonics (200 Hz-1 kHz), and 2-5 kHz harshness must be controlled. Use a priority mix (Overwatch "importance") plus sidechain ducking so key gameplay sounds win, not just the loudest.

### Cited Findings
- PlayStation targets (per Audiokinetic, Feb 2024): console -24 LUFS ±2, mobile/portable -18 LUFS ±2, max true peak -1 dBTP, max LRA 20. Measure ≥30 min of representative gameplay. Hit the target in the mix without mastering gain, and use the limiter only as a safety net at -1 to -2 dBFS. Measure the actual device output. — [Audiokinetic: Mastering a game with Wwise pt 1](https://audiokinetic.com/en/mastering-a-game-with-wwise-part1)
- Phone tests (iPhone 7P, Huawei Mate 7, Vivo Y51A, Oppo R9 Plus): content louder than -12 LKFS doesn't get louder because of the phones' AGC/limiting, and "around -16 LKFS is nearly the maximum level for all phones tested." The loudest game measured was Arena of Valor at -14.8 LKFS. Speakers roll off from 1 kHz downward. Android starts rising at 220 Hz, iPhone 7P at 400 Hz. The author targets about -16 LKFS master, SFX at -16 dB RMS, and peaks ≤ -3 dBFS. Control 4-5 kHz, reduce around 11 kHz, and avoid over-bright sounds that "seem louder but sound aggressive." — [Audiokinetic: loudness and frequency response on smartphones](https://audiokinetic.com/en/blog/loudness-and-frequency-response-on-popular-smart-phones)
- Note the conflict: Sony says -18 ±2 (so -16 is the top of the range); the phone study author suggests ~-16. Both agree on about -16 to -18.
- Mobile LRA: use a lower loudness range so quiet content stays audible in noise (public transport). Phone speakers "have weak frequency response and distort easily." LRA over 20 LU "is probably excessive." — [Designing Sound: loudness ranges for console vs mobile](https://designingsound.org/2013/02/20/different-loudness-ranges-for-console-and-mobile-games)
- Overwatch's "importance" system: instead of HDR "loudest sound wins," the mix boosts threats (who is looking at or shooting you, and how close) and dims the rest. Spatial path muffling was "the most important feature." Friend and foe sounds are clearly distinct, and only the most informative voice lines play. — [PC Gamer on Overwatch GDC 2016](https://pcgamer.com/how-overwatch-uses-sound-to-pinpoint-threats-you-cant-see); [GDC Vault talk](https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play)
- Riot clarity: audio and visual boldness should match gameplay impact. Important spells get audio wind-ups or telegraphs (Zoe Q, Taric stun). "Noise should be kept minimal," with high-impact spells the exception. Skins must be "at least as clear as the base skin." — [League: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
- Roblox ducking recipe: put the high-priority group (GUI notifications, weapons) as the sidechain for a CompressorSoundEffect on the low-priority group (3D/2D ambience). Threshold -80 to 0 dB, Attack/Release 0.001-1 s, Ratio 1-50. — [Roblox Docs: Sound groups](https://create.roblox.com/docs/en-us/sound/groups.md)
- Roblox's own showcase (Mystery of Duvall Drive): progression-critical sounds are high priority and ambience is low priority, ducked by a compressor. Volumetric room tones form a constant bed so the space "is never silent," and an intriguing distant sound pulls exploration ("grass is always greener"). — [Roblox creator-docs: Designing dark soundscapes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/resources/the-mystery-of-duvall-drive/designing-dark-soundscapes.md)

### Inferences
- **Frequency slots:** Music bed 80 Hz-8 kHz, carved with a dip around 1-4 kHz when SFX play. Creature roars and impacts 150 Hz-2 kHz body, with the sub as a bonus that headphones only hear. Bites, pickups and UI 1-6 kHz (the phone-sensitive band). Ambience mostly low-passed (<2-3 kHz) underwater, so the gameplay band stays clear.
- **Phone "missing fundamental":** add saturation/harmonics to the sub and body layers so 100-400 Hz overtones imply bass the phone can't play. Test every sound on a real cheap Android at mid volume.
- **Priority tiers for a shark game:** P1 player bite/eat, danger warnings (bigger predator near), level-up/evolve. P2 abilities and other players' bites nearby. P3 pickups. P4 ambience and fish chatter. P5 music. Duck P4/P5 under P1 with fast attack (~10-30 ms) and medium release (~300-600 ms).
- **Voice limits:** cap at ~2-4 instances of the same sound at once, steal the oldest, and cull distant emitters. Roblox doesn't publish a hard limit (see Gaps), so build your own pool or cooldown in Luau (e.g. pickup sounds throttled to one per ~50-80 ms, pitch-stepping instead of stacking).
- Kids and phones: keep the LRA low (no huge quiet/loud jumps), avoid piercing highs, and keep fanfares rewarding but short so they don't get annoying on repeat.

### Gaps
- No official Roblox loudness target or documented maximum number of simultaneous sounds. A DevForum thread has only community guesses ("not a limit... beyond 100") about total sounds, not concurrent voices. — [DevForum: Limit to amount of sounds](https://devforum.roblox.com/t/limit-to-amount-of-sounds/776706)

## 4. Underwater audio (muffling, low-pass, bubbles, whale ambience, reverb)

### Takeaway
The standard technique is low-pass filtering world sounds when underwater, either baked into "underwater versions" or applied in real time. Real underwater ambience features frequent clicking (Subnautica's hydrophone recordings). In Roblox, AudioFilter (Lowpass 6/12/24/48 dB) or AudioEqualizer does the muffle, and Acoustic Simulation (out of beta Sep 2026) can add occlusion and reverb from geometry.

### Cited Findings
- Muffling: low-pass original SFX (baked in Audacity), or use a real-time LPF (FMOD), or swap in pre-muffled asset versions when underwater for full control. — [MonoGame forum: underwater sound tricks](https://community.monogame.net/t/underwater-sound-tricks/13775)
- Subnautica's team bought a dedicated hydrophone (they rejected the "mic in a condom" hack) and scuba dives with GoPro reference. Real underwater sound "differs noticeably from what most people imagine," with prominent frequent clicking (they speculate fish eating coral). — [Unknown Worlds: underwater sound recording for Subnautica](https://unknownworlds.com/news/underwater-sound-recording-subnautica)
- Roblox AudioFilter docs sample: Frequency 22000 = no audible effect, 500 = muffled. Q = sqrt(2)/2 gives a flat low-pass for the 12 dB slope. The sample raycasts to adjust the filter (occlusion-style). — [Roblox AudioFilter](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioFilter)
- Roblox docs name AudioEqualizer for "muffling audio underwater." — [Roblox Audio effects](https://create.roblox.com/docs/en-us/audio/effects.md)

### Inferences
- **Layered underwater bed (stereo loop, 60-120 s, seamless):** (1) a low drone "water pressure" room tone, low-passed ~800 Hz-1.5 kHz; (2) sparse clicks and crackles (snapping shrimp/coral, per Subnautica); (3) random one-shot bubble streams placed in 3D; (4) distant whale-like calls (long gliding tonal moans, pitched and heavily reverbed) every 20-60 s from random directions, gentle for kids; (5) a zone-specific signature (reef: bright fish chatter and clicks; deep trench: darker drone and occasional distant rumble; kelp: soft swaying swishes).
- **World SFX:** low-pass non-player sounds by distance (e.g. 8 kHz near → 1.5 kHz far) via AudioFilter on emitters. Keep the player's own bites and UI unfiltered so they stay crisp (readability beats realism). Use a medium-long, darkish reverb (AudioReverb) on world sounds only.
- **Surface transition:** when breaching, sweep the LPF from ~1 kHz up to open over ~200 ms, with a splash and an air whoosh. Reverse it on diving.

### Gaps
- No source found giving canonical underwater LPF cutoffs or reverb settings from a shipped game. The numbers above are inferences.
- Acoustic Simulation interaction with Terrain water was asked on the DevForum but not answered. — [DevForum: Acoustic Simulation full release](https://devforum.roblox.com/t/full-release-acoustic-simulation-emit-audio-with-presence/4307121)

## 5. Music direction (adaptive layers per zone, stingers)

### Takeaway
Use vertical layering (stems such as drums, bass, lead and pads fading in and out by intensity) and horizontal resequencing (loopable chunks that switch per zone or state), plus short stingers for rewards and events, with runtime filtering to embed music in the world (e.g. low-pass when deep).

### Cited Findings
- Sackboy: A Big Adventure (Sony/Sumo): horizontal resequencing splits tracks into loopable chunks that switch with player actions. Vertical layering adds or removes stems (drums, bass, lead, accompaniment, vocals) for tension. Stingers give "feedback to the player" for actions and collectibles (Joe Thwaites). Runtime filters and effects embed music in the world. — [Audiokinetic: interactive music to score gameplay](https://blog.audiokinetic.com/how-to-use-interactive-music-to-score-gameplay/)

### Inferences
- **Per zone:** one key/tempo family per zone (reef: bright major, marimba and plucks; open ocean: airy pads; deep: minor-ish but not scary, slow pulse; boss/apex zone: drums up). Layers: L0 pad (always), L1 bass and percussion (when moving or hunting), L2 lead (when chasing or in a frenzy), L3 boss drums (when a big predator is near). Crossfade layers over 1-2 s. Quantize zone changes to the bar if feasible, or crossfade 2-4 s.
- **Stingers in the music key:** evolve, rare catch, level-up, death, and a "danger near" swell. Duck music -6 to -10 dB under stingers.
- **On Roblox:** play stems as synced AudioPlayers into one AudioFader per layer (start them together and adjust volumes), or use Sound objects in a SoundGroup.

### Gaps
- No public detail found on Hungry Shark's music system (it's known for licensed/rock-style tracks, but I found no primary source).

## 6. Roblox audio API capabilities (2025-2026)

### Takeaway
The new "Audio API" (AudioPlayer → Wire → effects → AudioEmitter / AudioListener → AudioDeviceOutput) left beta in Sept 2024. It has per-emitter distance curves (up to 400 points), directional AngleAttenuation, AudioInteractionGroups, a full effect set (Filter with 12 shapes, EQ, Compressor with Sidechain pin, Limiter, Reverb, Echo, Chorus, Flanger, Distortion, PitchShifter, Tremolo, Fader, Analyzer), TTS/STT, and Acoustic Simulation (occlusion, diffraction, reverb), which left beta 22 Sep 2026. SoundGroups and legacy Sound effects still work but are "discouraged."

### Cited Findings
- The Audio API exited Studio beta on 10 Sep 2024. AudioPlayer gained a Volume property. AudioFilter was new (one band, selectable shape, visual editor). AudioEqualizer has 3 fixed bands and a visual editor. AudioEmitter has a roll-off curve editor. AudioCompressor got a visual editor. A community member reports AudioPitchShifter sounds better than the legacy PitchShiftSoundEffect. — [DevForum: Audio API exits beta](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454)
- Wiring: 2D = AudioPlayer → Wire → AudioDeviceOutput. 3D = AudioPlayer → Wire → AudioEmitter, plus AudioListener → Wire → AudioDeviceOutput. ListenerLocation can be Default, None, Character or Camera. AudioTextToSpeech has ~30 voices and a 300-character limit. AudioSpeechToText also exists. Example curve: half volume at 50 studs, zero at 70. — [Roblox Docs: Audio objects](https://create.roblox.com/docs/en-us/audio/objects.md)
- AudioEmitter: DistanceAttenuationMode (presets or Custom) with DistanceAttenuationBounds (default [4, 10000]). SetDistanceAttenuation takes up to 400 points, distance in studs → 0-1, linearly interpolated, and defaults to inverse-square. SetAngleAttenuation uses 0-180° from the LookVector, up to 400 points. AudioInteractionGroup (listener hears only the same group). GetAudibilityFor(listener). AcousticSimulationEnabled. — [Roblox AudioEmitter reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioEmitter.md)
- AudioFilterType: Peak, LowShelf, HighShelf, Lowpass6/12/24/48dB, Highpass12/24/48dB, Bandpass, Notch. — [Roblox AudioFilterType enum](https://create.roblox.com/docs/en-us/reference/engine/enums/AudioFilterType.md)
- AudioCompressor: Attack 0.0001-0.5 s, Release 0.01-5 s, Threshold -60 to 0 dB, Ratio 1-50, MakeupGain ±30 dB. Pins are Input, Sidechain and Output. To duck, wire the trigger to the compressor with `Wire.TargetName = "Sidechain"`. — [Roblox AudioCompressor](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioCompressor.md)
- AudioLimiter: MaxLevel -12 to 0 dB, Release 0.001-1 s. — [Roblox AudioLimiter](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioLimiter.md)
- The effects list (Equalizer, Compressor, Reverb, Chorus, Distortion, Echo, Flanger, PitchShifter, Tremolo, Fader, Analyzer). One effect can take many players, and chain order matters. — [Roblox Docs: Audio effects](https://create.roblox.com/docs/en-us/audio/effects.md)
- Acoustic Simulation: posted 28 Jan 2026, updated 22 Sep 2026 as "officially out of beta" (the post body is inconsistent, still mentioning Client Beta). Enable with `SoundService.AcousticSimulationEnabled`. It needs the new API (Sound support "planned"). Optional `SoundService.CharacterSoundsUseNewApi` and `VoiceChatService.UseAudioApi`. Part properties: `AudioCanCollide`, `PhysicalProperties.AcousticAbsorption` (echo) and `Density` (occlusion). It "does consume some resources" (physics queries), and quality may drop or turn off on weaker devices. — [DevForum: Acoustic Simulation full release](https://devforum.roblox.com/t/full-release-acoustic-simulation-emit-audio-with-presence/4307121)
- Legacy: SoundGroup is "now discouraged in favor of... audio objects." Volume multiplier 0-10. Sounds are assigned by property, not by parenting. — [Roblox Docs: Sound groups](https://create.roblox.com/docs/en-us/sound/groups.md)
- Legacy Sound: RollOffMode is Inverse/InverseTapered (MaxDistance doesn't shape the falloff, so a low value cuts abruptly) or Linear/LinearSquared (falls to 0 at MaxDistance). PlaybackSpeed changes pitch and speed together. PlaybackRegion (with PlaybackRegionsEnabled) can play slices of one asset. PlayOnRemove plays on destroy. — [Roblox Sound reference](https://create.roblox.com/docs/en-us/reference/engine/classes/Sound.md)
- A Nov 2024 DevForum thread titled "New Audio API Features: Directional Audio, AudioLimiter and More" exists, but I couldn't fetch it (redirected to maintenance). — [DevForum thread](https://devforum.roblox.com/t/new-audio-api-features-directional-audio-audiolimiter-and-more/3282100)

### Inferences
- **Recommended graph for the shark game:** a per-category AudioFader bus (SFX, Creatures, UI, Ambience, Music) → a master AudioCompressor (glue) → an AudioLimiter (MaxLevel -1) → AudioDeviceOutput. The Ambience and Music faders feed a compressor whose Sidechain is wired from the SFX-P1 bus (ducking). An "Underwater" AudioFilter (Lowpass24dB) sits on the world/ambience bus. Pitch-as-size: AudioPitchShifter per shark tier on roars, so the same asset scales by tier.
- Use Linear or Custom distance curves so other players' bites fade cleanly. Cull with GetAudibilityFor() < ~0.05.
- Consider Acoustic Simulation only if caves or wrecks matter. Open water has nothing to occlude, and it has a device cost, so test on low-end phones first.
- Use PlaybackRegion to pack many short UI blips into one uploaded asset (fewer uploads/moderation), or use separate assets for simplicity.

### Gaps
- No official max concurrent voice count, and no mobile CPU numbers for Acoustic Simulation.
- AudioReverb, AudioEqualizer, AudioFader and AudioPitchShifter property ranges weren't fetched (individual reference pages exist on create.roblox.com).

## 7. Reference games: Hungry Shark, Supercell, Overwatch, League, Pokémon/Nintendo

### Takeaway
Overwatch and League give the strongest public principles: audio must carry gameplay information, important or high-impact abilities get bigger sounds and wind-ups, noise stays minimal, friend vs foe is distinct, and pitch can encode progress. I found no primary audio talks or articles for Hungry Shark, Supercell or Pokémon UI.

### Cited Findings
- Overwatch, "play by sound": Kaplan wanted it playable with the monitor "practically turned off." Each of the 21 heroes has distinct footsteps, and layered cues should create near-instinctive reactions so deaths never feel cheap. — [PC Gamer](https://pcgamer.com/how-overwatch-uses-sound-to-pinpoint-threats-you-cant-see); [GDC Vault](https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play)
- League: Kayle's ultimate gets bold audio and visuals because its impact is high; Zoe Q and Taric stun get audio wind-ups. — [League: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)

### Inferences
- For the shark game: give each shark tier a unique "signature" (bite timbre plus roar pitch), so kids can tell by ear when a bigger shark is near. Give a danger telegraph (a low swell or heartbeat) 1-2 s before a bigger predator arrives. Scale ability audio by gameplay impact.

### Gaps
- Hungry Shark (Future Games of London/Ubisoft) audio: searches turned up only store and review pages, with no designer interview or GDC talk.
- Supercell audio: GDC search turned up only design/economy talks, with no audio talk found.
- Pokémon/Nintendo UI sound: no primary source fetched.
