-- Sounds (Galaxy Incremental, alpha part 2, 3 Nov): EVERY sound id in the game, in one place (UIKit's Kit.sound / Kit.music
-- play them). All of them are Roblox's licensed Creator Store audio, free to use in any experience, nothing to upload:
--   * Roblox's own UI pack (creator "Roblox")
--   * Pro Sound Effects' library on Roblox (creator "ProSoundEffects", licensed to Roblox)
--   * APM Music on Roblox (creator "APMOfficial", licensed to Roblox) for the music
-- No copyrighted music, nothing ripped. To swap a sound: change its id here (and only here).
-- volume = the base volume (the player's SFX / MUSIC sliders multiply it), pitch = playback speed, vary = +- random pitch
-- (frequent sounds get a few % so they never sound the same twice), start = seconds to skip at the start of the file.
-- The volumes are balanced by ear-free measurement (Studio PlaybackLoudness, 3 Nov): UI ~120-230 peak, rewards ~200-350,
-- the Supernova riser / boom the loudest; some files are much quieter than others, hence volumes above 1.
local Sounds = {}

Sounds.List = {
	-- UI
	click = { id = 15675059323, volume = 0.5, pitch = 1, vary = 0.05 },       -- Roblox_UI_Bright_Click: every BUY press
	tab = { id = 15675032796, volume = 1.5, pitch = 1, vary = 0.05 },         -- Roblox_UI_Small_Click: tabs, list picks
	open = { id = 15675024286, volume = 0.4, pitch = 1.1, vary = 0.03 },       -- Roblox_UI_Whoosh_01: a window opens
	close = { id = 15675028888, volume = 0.35, pitch = 0.9, vary = 0.03 },     -- Roblox_UI_Whoosh_02: a window closes
	error = { id = 17208353912, volume = 0.5, pitch = 1, vary = 0.02 },        -- Roblox GUI - Negative: can't afford / locked (a soft thud, no buzzer)
	-- the economy
	buyBody = { id = 9126073001, volume = 1.4, pitch = 1, vary = 0.06 },      -- Synth Sparkle Tone High Pitch Bell Tone Ding: a new body
	milestone = { id = 15675043410, volume = 0.6, pitch = 1, vary = 0 },       -- Roblox_UI_Tonal_Stinger: a body's x2 milestone, TUTORIAL COMPLETE
	-- comets
	cometAppear = { id = 9113853873, volume = 1.8, pitch = 1, vary = 0.06 },   -- Comet Trail Hissy Pass Bys Fast Wispy 1: heard as it streaks in
	cometCatch = { id = 9126076030, volume = 0.8, pitch = 1, vary = 0.05 },    -- Synth Sparkle Tone High Pitch Tone Burst Pin: caught
	-- the island
	piecePop = { id = 15675055424, volume = 0.4, pitch = 1, vary = 0.08, range = 140 }, -- Roblox_UI_Cute_Pop: a new piece pops in (3D, at the piece)
	-- the Supernova (same beats as the VFX: wind-up = riser, impact = boom, then the shards land one by one)
	windup = { id = 9126102694, volume = 0.8, pitch = 1, vary = 0 },           -- Time Warp Searing Build Up Large Suck Rumble
	boom = { id = 9126102254, volume = 0.7, pitch = 1, vary = 0 },             -- Time Warp Big Explosion Blast Boom Tonal Tail
	shardIn = { id = 9125530803, volume = 0.35, pitch = 1, vary = 0 },         -- Electronic Blips Sharp Crystalline Beeps (pitch climbs per shard)
}

-- THE MUSIC PLAYLIST (owner 5 Nov: the old loop, APM "Ethereal Drone" 1837463526, was too chill). All APM Music on Roblox.
-- UIKit plays it: shuffled each session, each track once per shuffle, never the same track twice in a row, 2 s crossfades.
-- volume = the track's loudness match (x MusicBus): Studio PlaybackLoudness, the average of 7 points through each track
-- (5 Nov: Final Frontier 116, Into the Sun 139, Go! 144, Future Plans 187, Full Contact 326 -> all ~130).
-- stop = where the track's silent tail starts (PlaybackRegion; the intros are all under 0.5 s, so they play from 0)
Sounds.MusicBus = 0.4
Sounds.MusicCrossfade = 2
-- (7 Nov, launch day, owner: "music should have more hype, rn it feels depressing". Measured in Studio (PlaybackLoudness at
-- 60 Hz, 25 s from 0:30; beat = the autocorrelation of the loudness onsets at 100-160 BPM, ~ = the tempo it found): the
-- old 5 had a weak beat (0.06-0.19) except Go! (0.33), two at ~102 BPM. The new 4: all APM Music (APMOfficial, licensed to
-- Roblox), instrumental, a clear beat at 119-137 BPM, upbeat titles / library notes. volume = the loudness match (as before);
-- start = where the beat comes in (LoopRegion skips the intro), stop = where the silent tail starts)
--   OLD: Final Frontier 1844631856 (beat 0.06, ~152), Into the Sun (b) 1840016117 (0.19, ~102), Go! 1840300465 (0.33, ~160),
--        Future Plans (A) 1840772819 (0.15, ~102), Full Contact (a) 1841008234 (0.07, ~160)
Sounds.Playlist = {
	{ id = 1847078335, name = "Get Going B", volume = 0.55, start = 2, stop = 101 },              -- beat 0.43, ~137 BPM
	{ id = 1839889971, name = "Back to the Scoreboard", volume = 0.55, start = 0, stop = 137 },   -- 0.21, ~125 (Juice Music "PUMPED UP", Club/Electronica)
	{ id = 1836702723, name = "Uplighter", volume = 0.43, start = 0, stop = 154 },                -- 0.21, ~125
	{ id = 1844486984, name = "Saturday Special", volume = 1.3, start = 3, stop = 88 },           -- 0.26, ~119
}
-- the 2x STARDUST EVENT's track: crossfades in while an event runs (GalaxyLive -> Kit.musicEvent), loops, then back to the
-- playlist
Sounds.EventTrack = { id = 1846696220, name = "Turbo Trance B", volume = 0.67, start = 0, stop = 149 } -- 0.22, ~137
-- the mix: the music is 0.25 (MusicBus x WindowDuck) while a shop / window is open; a big stinger ducks it -6 dB (x0.5),
-- 80 ms in, 1 s back (Kit.sound plays these names). The Supernova cuts it for its riser and brings it back after (as before)
Sounds.WindowDuck = 0.625
Sounds.StingerDuck = { k = 0.5, attack = 0.08, release = 1, names = { milestone = true, buyBody = true } }

-- the Settings sliders start here (0..1)
Sounds.Default = { music = 0.6, sfx = 0.8 }

return Sounds
