# Sound Design (SFX and Music) for Roblox Kids' Simulators, 2025-2026: Deep Dive

Scope note: this builds on /home/claude/research_notes/Making Roblox games better/ui_feel_art_sound.md, section 5. That section already covers SoundGroups for volume sliders, the 2022 audio privacy change, the "100,000+ Creator Store tracks" figure, pitch variation of about ±5-10%, and visual twins for sound. Those points are not repeated here.

Research date: 2026-10-28. Sources are marked [official], [industry] or [secondary/low reliability].

## 1. Roblox audio technology now (Sound vs Audio API, SoundService, spatial, loading, limits, mobile)

### Takeaway
The graph-based Audio API (AudioPlayer, Wire, AudioDeviceOutput, AudioEmitter, AudioListener plus effect nodes) left beta on 10 Sep 2024 and is the officially recommended path. Roblox docs now say Sound, SoundGroup and SoundEffect are "discouraged in favor of" audio objects. A solo developer can build a full mixer graph (UI bus, SFX bus, music bus, each through an AudioFader and into one AudioDeviceOutput) and duck the music by tweening a fader. Legacy `Sound` still works and is simpler for one-off 3D sounds. No official numbers for simultaneous-voice or memory limits were found.

### Cited Findings
**Audio API objects and wiring**
- Object roles:
  - AudioPlayer loads and plays an asset.
  - AudioEmitter is a "virtual speaker" positioned by its parent.
  - AudioListener is a "virtual microphone".
  - AudioDeviceOutput is the player's speakers or headphones.
  - Wire connects a `SourceInstance` to a `TargetInstance`.
  - The effects AudioEqualizer, AudioCompressor and AudioReverb are non-destructive.
  - The docs say Sound, SoundGroup and SoundEffect are "discouraged in favor of" audio objects. [official] — [Audio objects](https://create.roblox.com/docs/en-us/audio/objects)
- 2D recipe (UI and music): place an AudioPlayer, an AudioDeviceOutput and a Wire under SoundService, then wire the player to the output. [official] — [Audio objects](https://create.roblox.com/docs/en-us/audio/objects)
- 3D recipe:
  - Set `SoundService.ListenerLocation` to Default, None, Character or Camera.
  - Under the part, add AudioPlayer → Wire → AudioEmitter.
  - Shape the emitter's `DistanceAttenuation` curve. The docs' example is half volume at 50 studs and silence at 70 studs.
  - With Character or Camera, the engine creates the listener and the AudioDeviceOutput.
  - [official] — [Audio objects](https://create.roblox.com/docs/en-us/audio/objects)
- Release history:
  - The Audio API "has officially exited Studio Beta" on 10 Sep 2024. The beta started Feb 2024.
  - The exit announcement added a `Volume` property on AudioPlayer, so an AudioFader is no longer needed just to set volume.
  - It also added AudioFilter (one band, several shapes), visual editors for the EQ and filter, and `AudioAnalyzer.SpectrumEnabled`. Turning spectrum analysis off improves performance.
  - [official] — [DevForum: Audio API exits beta](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454)
- Occlusion and diffraction status:
  - At Sep 2024 these were not automatic. Roblox said "We're actively working on these as automatic simulation features."
  - The current SoundService reference now lists `AcousticSimulationEnabled`, a global switch for automatic occlusion, diffraction and reverb on AudioEmitters and AudioListeners. This indicates the feature has since shipped.
  - [official] — [DevForum](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454); [SoundService](https://create.roblox.com/docs/en-us/reference/engine/classes/SoundService.md)
- A community reply in the exit thread says the legacy PitchShiftSoundEffect "seems to be lower quality than AudioPitchShifter". [community] — [DevForum](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454)
- AudioFader has only `Volume` and `Bypass`, plus pin and wire methods. It is a gain node, and you use it as a bus. [official] — [AudioFader](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioFader)

**AudioPlayer details**
- Properties:
  - `Asset`, `AutoLoad`, `IsReady`, `Looping`.
  - `LoopRegion` and `PlaybackRegion` (NumberRange, seconds). These let you play one region of a sound sheet, or loop a music body after an intro.
  - `PlaybackSpeed` (0-20; it also changes pitch).
  - `TimePosition` and `Volume` (0-10).
  - [official] — [AudioPlayer](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPlayer.md)
- Methods and events:
  - `Play(atTime)` and `Stop(atTime)` can be scheduled against `GetMixerTime()` for sample-accurate timing, which helps beat-synced music transitions. They return an id that `Cancel()` accepts.
  - `Ended` does not fire on looping or early-stopped audio.
  - `Looped` fires each loop.
  - `GetWaveformAsync` samples the waveform.
  - [official] — [AudioPlayer](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPlayer.md)
- Loading and memory:
  - With `AutoLoad` false, loading is deferred to the first play, which risks a delay on the first click.
  - `IsReady` can go false if "memory pressure" unloads the asset. The docs call this uncommon.
  - [official] — [AudioPlayer](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPlayer.md)
- The Creator Store docs say clicking an audio asset in the Toolbox inserts a legacy `Sound`. The recommended route is to copy the ID into an AudioPlayer. [official] — [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)

**Legacy Sound and SoundService**
- Sound basics:
  - `Volume` ranges 0-10 with a default of 0.5.
  - RollOffMode options are Inverse, InverseTapered, Linear and LinearSquared, with `RollOffMinDistance` and `RollOffMaxDistance` in studs.
  - A sound parented to a BasePart or Attachment is 3D, with Doppler and distance falloff. A sound elsewhere (e.g. in SoundService or PlayerGui) is global at constant volume.
  - `PlaybackLoudness` reports 0-1000 and can drive music visualizers or pulsing UI.
  - `PlayOnRemove` exists.
  - `Pitch` is deprecated; use `PlaybackSpeed`.
  - [official] — [Sound](https://create.roblox.com/docs/en-us/reference/engine/classes/Sound.md)
- SoundService properties:
  - `AmbientReverb` (ReverbType preset) applies only to legacy Sounds, not AudioPlayers or AudioEmitters.
  - `DistanceFactor` defaults to 3.33 studs per metre and `DopplerScale` to 1.
  - `RolloffScale`: higher values make spatialized sounds fall off faster.
  - `RespectFilteringEnabled` defaults to true, so a LocalScript-played sound plays only on that client.
  - `VolumetricAudio` makes a sound emit from a part's whole volume.
  - `CharacterSoundsUseNewApi` is a read-only RolloutState showing whether default character sounds use the new API.
  - `PlayLocalSound(sound)` plays a client-only copy (Looped and AmbientReverb are not carried over).
  - [official] — [SoundService](https://create.roblox.com/docs/en-us/reference/engine/classes/SoundService.md)
- Later additions (secondary source, not verified on an official page):
  - `AudioLimiter`, `AngleAttenuation` and `AudioEmitter:GetAudibilityFor(listener)` were reportedly added around Dec 2024.
  - The same article suggests about 30 simultaneous spatial sources as a practical ceiling on older hardware.
  - [secondary/low reliability] — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)

### Inferences
- A suggested graph for a phone simulator:
  - Use one AudioDeviceOutput, fed by an AudioFader bus per category (Music, SFX, UI, Ambience).
  - Feed every bus through a shared AudioCompressor or AudioLimiter before the output, as a safety net against stacked coin sounds clipping.
  - Settings sliders set the bus fader volumes.
  - Duck the music by tweening the Music fader to about 0.5-0.6 for roughly 1-2 s during a rarity stinger.
  - Because AudioPlayer `Volume` is a property, TweenService works on it directly.
- Pool AudioPlayers for high-frequency sounds (coin pickup, click), for example 4-8 per sound, instead of creating one per event. Round-robin through the pool and set `PlaybackSpeed` per play for pitch variation. (Pooling is also advised by the low-reliability RoWatcher piece. It is standard engine practice, not a documented Roblox requirement.)
- Keep `AutoLoad` true for UI and reward sounds, and preload them while the game loads. ContentProvider:PreloadAsync on the instances is the conventional route. It was not re-verified for AudioPlayer in this pass.
- Most simulator sounds (UI, rewards, music) should be 2D and client-side. Make 3D only world objects such as eggs, machines and other players' actions. Client-side playing also avoids network lag on feedback.
- A rising coin-combo pitch is easy: `PlaybackSpeed = 1 + 0.05 * comboIndex`, capped around 1.5 and reset after about 1 s idle.

### Gaps
- No official document states a limit on simultaneous sounds, voices or audio memory per client, or a mobile-specific audio budget. The "~30 sources" figure is from a secondary article only.
- No official mobile-specific behaviour notes were found (for example, audio when the app is backgrounded, or iOS silent switch handling).
- The full list of Audio API effect classes (AudioChorus, AudioDistortion, AudioEcho, AudioFlanger, AudioPitchShifter, AudioLimiter, AudioAnalyzer and others) was not confirmed from a single official index page in this pass.
- The original Feb 2024 beta announcement (devforum.roblox.com/t/2848873) returned empty content.

## 2. Licensing and sourcing (Creator Store, upload limits, group permissions, copyright)

### Takeaway
ID-verified creators can import 2,000 free audio assets per 30 days (100 if unverified). Files must be under 20 MB, under 7 minutes, and at most 48 kHz. Uploaded audio is private to the uploader until shared. For a group-owned game, upload the audio as a group asset (pass the group ID) so the universe can use it. Creator Store partner audio is the safe default. Never use community-uploaded tracks you don't own.

### Cited Findings
- Import limits and file requirements:
  - "you can import 2,000 free audio assets per 30 days" if ID-verified, and 100 if unverified. Any old daily limit was replaced by this monthly one.
  - Formats: .mp3, .ogg, .wav or .flac, under 20 MB and under 7 minutes.
  - Sample rate at most 48 kHz. Channels: mono, stereo, 3.0 or 5.1.
  - You "must hold the legal rights".
  - [official] — [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)
- Privacy and permissions:
  - New private audio is usable only by the uploader at first.
  - The privacy system grants use to specific friends and experiences.
  - Audio can be created as a group asset by supplying a group ID in the upload request.
  - [official] — [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)
- Song versus sound effect:
  - Uploads are auto-classified as sound effect or song.
  - Songs can appear on the game details page (with a 15 s preview) only if they pass copyright checks, come from an ID-verified uploader, and meet duration and play thresholds. The page gives no specific thresholds.
  - [official] — [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)
- Background and partner libraries (secondary source):
  - The privacy change made audio over 6 s private by default on 22 Mar 2022.
  - Roblox licenses its partner catalogue so developers don't clear rights themselves.
  - Partners include APM Music (since May 2018), Monstercat (since July 2020, electronic) and Pro Sound Effects (SFX).
  - The article also claims an "up to 250 licensed tracks per experience" cap, which could not be verified.
  - [secondary/low reliability] — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)
- Original policy thread: [DevForum: Upcoming Changes to Asset Privacy for Audio (2022)](https://devforum.roblox.com/t/1701697) [official, older 2022].
- A 2025 DevForum feature request complains that music upload permissions limit UGC. [community] — [DevForum](https://devforum.roblox.com/t/music-upload-permissions-are-limiting-ugc/4022136)

### Inferences
- Practical sourcing ladder for a solo kids' simulator:
  1. Creator Store audio by Roblox or partners (filter by creator "Roblox" or partner names).
  2. Your own sounds, or sounds licensed under CC0 / royalty-free terms that allow redistribution inside games. Read each licence; some royalty-free SFX licences forbid re-uploading the raw files to platforms where others can extract them.
  3. Commissioned music with a written licence.
- If the game will move to a group, upload the audio to the group from the start. Otherwise you must re-upload it or grant the universe permission.
- Copyright risk sits mainly with music: popular songs get taken down or muted, and repeated violations risk the account. Kids' games often use trending-song names in titles, so avoid that.

### Gaps
- The exact rules for whether a user-owned private audio asset can be granted to a group-owned experience (and how) were not documented on the fetched page beyond "grant to experiences".
- No 2025-2026 official statement on the current size of the licensed catalogue or the partner list was found beyond the "100,000+" figure.

## 3. Sound design craft (layering, variation, priority/ducking, loudness, UI vocabulary, reward escalation, silence, music)

### Takeaway
Use these loudness targets:
- Mobile: about -16 to -18 LUFS integrated (IESD: -16 ±2 LU, LRA 10-15 LU; Sony mobile -18 LUFS).
- Console/PC: -24 LUFS with a true peak of -1 dBTP or lower.
- Kids' educational apps: as quiet as about -28 to -24 LUFS.

Keep the loudness range narrow on phones. Vary sounds that repeat (footsteps, hits) with near-identical variations. Do not randomize "identity" sounds like the coin pickup much. Keep UI sounds in the music's key.

### Cited Findings
- Loudness targets:
  - Console/home: integrated loudness "normalized to -24 LUFS" ±2 LU, true peak not above -1 dBTP.
  - Mobile/handheld: "normalized to -16 LUFS" ±2 LU, LRA 10-15 LU.
  - Measure per ITU-R BS.1770-3.
  - [industry, 2015] — [IESD Mix Reference Levels v03.02, Audio Gang](https://www.audiogang.org/wp-content/uploads/2015/04/IESD-Mix-Ref-Levels-v03.02.pdf)
- Adaptive mobile approach (Rob Bridgett, 2015):
  - Sony ASWG-R001 adopted -24 LUFS. Sony's mobile target is -18 LUFS.
  - Device-speaker benchmark: -16.2 LUFS (iTunes Soundcheck).
  - Mix the reference on headphones in a quiet room, then check the other states.
  - Children's educational apps: about -28 LUFS base, raised toward -24 in noisy places.
  - [industry, older 2015] — [Audio Media International](https://audiomediainternational.com/mobile-loudness-an-adaptive-approach/)
- Mobile games should use a lower loudness range than console. EBU R128 calls 5-10 LU "low" and 15-20 LU "high", and over 20 LU is probably excessive. Suggested gentle compression: threshold below -40 dBFS, ratio 1:1.2-1:1.5, release over 1 s. [industry, older 2013] — [Designing Sound](https://designingsound.org/2013/02/20/different-loudness-ranges-for-console-and-mobile-games)
- Variation and repetition (Bjørn Jacobsen):
  - Aim for "the sweet spot between the boredom of monotony and the safety of recognition."
  - Keep coin pickups and alerts consistent.
  - Frequent sounds need "ten variations that are almost indistinguishable".
  - Layered systems: four layers × five variations each gave 125-625 combinations, but more variations made odd samples easier to spot.
  - Voice-limit loud layers so they don't stack; his generic boom could not overlap itself.
  - [industry] — [A Sound Effect: Game audio immersion](https://www.asoundeffect.com/game-audio-immersion/)
- Musical key and silence (same source):
  - UI sounds in a different key from the music cause dissonance. His example was A# UI over A-minor music.
  - Fix it by re-pitching or recreating the asset.
  - In an informal, admittedly unscientific 19-player test, those who heard out-of-tune UI quit a minute or two earlier.
  - Silence is noticed like a fridge switching off, so use it deliberately.
  - [industry, anecdotal] — [A Sound Effect](https://www.asoundeffect.com/game-audio-immersion/)
- Common mistakes listed by a secondary source:
  - Testing only on headphones instead of laptop or phone speakers, where the low end is lost.
  - No signature sound.
  - Filling every moment instead of using silence before big events.
  - One attenuation curve for everything.
  - Creating a new player per event instead of pooling.
  - [secondary/low reliability] — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)

### Inferences
These are craft practice synthesized from standard game-audio practice; they are not individually sourced.

- **Layering**
  - Build a reward sound from three layers:
    - Transient (click or snap, 0-30 ms) sells the "hit".
    - Body (tonal chime or whoosh, 100-400 ms) carries the identity and pitch.
    - Tail (sparkle or reverb, 0.3-1.5 s) adds the "premium" feel.
  - Phone speakers roll off below roughly 200-300 Hz. Put the identity of every important sound in about 1-5 kHz and treat sub-bass as a bonus for headphones.
- **Variation**
  - Use ±3-8% `PlaybackSpeed` and ±1-2 dB volume jitter on high-repeat sounds (footsteps, punches, clicks).
  - Use 3-5 sample variants for hits.
  - Keep the coin, level-up and egg-hatch "signature" sounds fixed. Vary them only through deliberate escalation, such as rising pitch.
- **Voice limiting**
  - Cap each sound to a few simultaneous instances and a minimum retrigger gap (e.g. 40-60 ms for coin ticks).
  - Batch large coin pickups into a short "cash roll" plus a final ding rather than 100 dings.
- **Priority and ducking.** Priority order: reward or rarity stinger, then error or confirm, then gameplay SFX, then UI hover, then ambience, then music. Duck the music 4-8 dB under big stingers, with roughly a 50-100 ms attack and 0.5-1.5 s release.
- **Relative levels for a kids' simulator mix**
  - Music sits clearly below SFX, for example music bus around 0.3-0.5 relative to an SFX bus at 1.0.
  - Avoid harsh 2-5 kHz peaks and sharp high-pitched squeaks, which are fatiguing on phones and to children.
  - Loudness-match every imported asset before upload. Creator Store assets vary widely in level.
- **UI sound vocabulary.** One sound family (same timbre and key):
  - Tap/click: short, dry.
  - Open panel: soft rising whoosh.
  - Close panel: falling whoosh.
  - Confirm/purchase: two-note rising, major interval.
  - Error/denied: low dull thud or two-note falling. Never a harsh buzzer for kids.
  - Toggle: two distinct pitches for on and off.
  - Notification: gentle bell.
  - Reward: chime with sparkle tail.
  - On mobile there is no hover, so skip hover sounds or keep them PC-only.
- **Reward escalation**
  - Coin ticks rise in pitch within a combo, stepping semitones in a pentatonic scale so the steps always sound musical.
  - Pick a rarity ladder:
    - Common: single pop.
    - Uncommon: pop plus chime.
    - Rare: rising arpeggio.
    - Epic: arpeggio plus whoosh plus music duck.
    - Legendary/secret: about 0.5-1 s of silence or drum-roll anticipation (egg shake), then a big stinger, music duck, and an optional server-wide announcement sound.
  - The silence or rumble before a reveal is the anticipation; it makes the payoff feel bigger.
- **Music**
  - Use 1-3 looping tracks per zone. Use `LoopRegion` to skip intros on repeat.
  - Crossfade over 1-2 s on zone change.
  - Schedule `Play(atTime)` on bar boundaries for musical transitions.
  - Simple adaptive layers: start a percussion stem when a boss or event begins, and fade it with a fader.
  - Lower music during shops and menus, or swap to a lighter shop loop.
- **Kids on phones.** Provide music and SFX toggles. Default to moderate levels. Many children play muted, so every audio cue also needs a visual cue (covered in the earlier notes).

### Gaps
- No current (2023-2026) published, platform-official loudness spec for Roblox or for iOS/Android games was found. The ASWG and IESD figures date from 2013-2015 but remain the industry references.
- No authoritative source was fetched for specific ducking dB values, retrigger windows or the layering millisecond ranges. These are practitioner conventions and are marked as inference.

## 4. Psychology and evidence (audio and perceived quality, satisfaction, retention)

### Takeaway
Controlled evidence is limited but positive. In a 2024 lab study, character/action sounds (the closest analogue to a simulator's "click, punch, coin" feedback) significantly raised immersion, avatar identification and fun. Ambient sound mattered less. No Roblox-specific retention data exists.

### Cited Findings
- A 2×2 within-subjects study tested character sounds and ambient sounds on/off in League of Legends, with two experiments of n=32 each. Character sounds significantly increased:
  - immersion (p=.01; M 3.13 vs 2.83)
  - avatar identification (p=.01; 2.73 vs 2.37)
  - fun (p=.03; 3.92 vs 3.66)

  Ambient sounds showed only trends (flow p=.09, fun p=.07), and raised fun only when character sounds were off. Published in Applied Sciences (2024). — [Preprints.org 202312.0324](https://www.preprints.org/manuscript/202312.0324); [DOAJ record, Applied Sciences Jan 2024](https://doaj.org/article/ddde88ba732a4177853dd2f4b4cbd6a6)
- Anecdotal: out-of-key UI sounds coincided with players quitting 1-2 minutes earlier (n=19, informal). — [A Sound Effect](https://www.asoundeffect.com/game-audio-immersion/)
- A secondary article claims "80% of players" enjoy games more with synchronized audio-visual feedback, but cites no study. Treat it as unverified. — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)

### Inferences
- The strongest evidence-backed priority for a simulator is feedback sounds tied to the player's own actions (train click, hit, pickup, hatch). Ambient beds and music come second.
- Small effect sizes (about 0.3 on a 5-point scale) suggest sound is a polish multiplier, not a substitute for core loop quality.

### Gaps
- No peer-reviewed study linking game audio to D1/D7 retention, or to monetization, was found in this pass.
- No GDC talk was fetched (e.g., on "juice" or reward audio); search budget was exhausted.

## 5. What top Roblox games do with sound, and common mistakes

### Takeaway
The best-known Roblox audio examples are horror and shooter games (Doors, Piggy, Arsenal), which use distinct signature sounds, silence and intensity-scaling music. For simulators, the transferable lessons are a signature sound per key event, escalation and contrast. No sourced breakdown of specific simulator audio (Pet Simulator 99, Bee Swarm, etc.) was found.

### Cited Findings
- Examples from a secondary source:
  - **Doors:** custom distorted vocalization for Screech, a near-subliminal hard-to-locate sound for an entity, and silence to build dread.
  - **Piggy:** each character has a distinct sound profile, and chase music intensifies as the enemy nears.
  - **Arsenal:** won Best Sound Design at the 7th Bloxys, with a soundtrack by Campyfire and nine distinct victory themes.
  - **Natural Disaster Survival:** lost its original theme to the 2022 privatization, which changed its identity.
  - [secondary/low reliability] — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)
- Mistakes from the same source:
  - Neglecting audio relative to visuals and monetization.
  - Using community tracks you don't own.
  - Building new work on legacy `Sound`.
  - Leaving inaudible looping legacy sounds running (bound them with RollOffMaxDistance).
  - Mismatched reverb presets.
  - Speaker-untested mixes.
  - [secondary/low reliability] — [RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge)
- Roblox's own audio overview frames audio's jobs as immersion, feedback on player actions, and directing attention to objectives. [official] — [Audio](https://create.roblox.com/docs/en-us/audio.md)

### Inferences
Common mistakes in kids' simulators, from observation of genre conventions (not sourced):
- Ear-piercing high squeaks or a loud "denied" buzzer.
- Clipping from dozens of simultaneous coin dings.
- Music louder than feedback.
- One click sound for everything.
- No sound on the core action loop (training, tapping).
- Music that restarts on every respawn.
- Mismatched loudness between Toolbox assets.
- No mute or volume options.

Quick wins, in order:
1. A master limiter/compressor.
2. Per-bus faders and settings.
3. Pooled, voice-limited coin and click sounds with pitch steps.
4. A rarity stinger ladder with a music duck.
5. Loop music with crossfades.

### Gaps
- No sourced teardown of sound in top 2025-2026 simulators (Pet Simulator 99, Grow a Garden, Bee Swarm Simulator, Muscle Legends) was found. Hands-on observation in those games would fill this gap.
