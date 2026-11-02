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

-- one calm space loop (design 10: "Stardust: calm dreamy synth"), quieter than the effects
Sounds.Music = { id = 1837463526, volume = 0.35 } -- APM "Ethereal Drone": celestial ambient synth textures, steady

-- the Settings sliders start here (0..1)
Sounds.Default = { music = 0.6, sfx = 0.8 }

return Sounds
