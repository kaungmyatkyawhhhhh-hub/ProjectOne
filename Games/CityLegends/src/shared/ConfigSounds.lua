--[[
	CITY LEGENDS - Config.Sounds, the exhaust sets (Config.Exhaust*, SupercarExhaust)
	Moved out of Config.lua (2026-11-26: Studio caps a script at 200,000 characters).
	Config.lua calls this with its table at the same spot, so the load order is unchanged.
]]

return function(Config)
	---------------------------------------------------------------------
	-- Sounds
	-- The game ships with a full built-in soundscape (engine, wind, tyres,
	-- cut-ups, crashes, backfires, UI, ambience) made from audio inside the
	-- Roblox client, so it always works. On top of that the ids below are real
	-- recordings from the Creator Store (all checked: audio + public domain).
	-- Every id is test-loaded at startup and only used if it loads; anything that
	-- fails falls back to the built-in sound. Swap in your own ids any time.
	---------------------------------------------------------------------
	Config.Sounds = {
		-- engine set by the verified "Roblox Resources" group (public domain)
		Engine = "rbxassetid://80317022777602", -- Car-Engine-Loop (pitch follows RPM)
		EngineStart = "rbxassetid://78270463799678", -- Engine-Start
		-- (2026-11-06) parts' sounds, all already in the game: pops and crackles for a car with none of its
		-- own (the SVJ's), a turbo's whine and a blow-off (the Bugattis')
		SharedPops = "rbxassetid://125121319222420",
		SharedCrackle = "rbxassetid://128716617727916",
		SharedTurbo = "rbxassetid://72711797703242",
		SharedBlowOff = "rbxassetid://95497630494219",
		-- per-car engines (verified creators); a car without one uses Engine above
		Engine_ferrara_458 = "rbxassetid://130398079560929", -- "Ferrari Engine", Roblox Sim Racing League
		-- ProSoundEffects (Roblox's official SFX partner, public domain)
		Crash = { "rbxassetid://9116546593", "rbxassetid://9116546326" }, -- Metal Crash 4 / 2
		TyreSqueal = "rbxassetid://9120399077", -- Vehicle Skids Long Heavy Tire Squeal 3
		CutUp = "rbxassetid://9126229255", -- Whoosh By Fast Airy Swooshing
		PassBy = "rbxassetid://9113003539", -- Race Car Pass By (cutscene)
		Impact = "rbxassetid://9120769331", -- Sonic Boom Low End Impact (title hit)
		-- (27 Nov) street sounds, code-made (tools/street_sounds/cl_street.py; vault City Legends/2026-11-27 Traffic
		-- pass-by and footstep sounds.md): traffic roar loop, horns, slipper steps, a person bumped by a car
		StreetRoar = "rbxassetid://118487038419336",
		HornCar = "rbxassetid://123306159679736",
		HornBus = "rbxassetid://134615287932247",
		Step = { "rbxassetid://96298460174140", "rbxassetid://78290550392105", "rbxassetid://124790381652670", "rbxassetid://73974542726865" },
		ThudSoft = "rbxassetid://95173200422307",
		ThudHeavy = "rbxassetid://98925219324457",
		Tumble = "rbxassetid://123280563435719",
		-- (2026-11-26) the UI sound family "night drive" (code-made: tools/ui_sounds/cl_ui.py; vault
		-- City Legends/2026-11-26 UI pass - sounds, HUD buttons, guide pill.md). Before: one built-in tick for everything
		UIClick = { "rbxassetid://86747139108751", "rbxassetid://125513135454735", "rbxassetid://126667847847217" },
		UITab = "rbxassetid://115513551178968",
		UIOpen = "rbxassetid://95577240285283",
		UIClose = "rbxassetid://107719827280501",
		UIConfirm = "rbxassetid://79545227579857",
		UICash = "rbxassetid://133517145681997",
		UILevelUp = "rbxassetid://124355330848730",
		UIError = "rbxassetid://100566362650239",
		-- night-drive playlist from Roblox's licensed music partners (public domain)
		Music = {
			"rbxassetid://140215257631273", -- Eclipse Drift (DistroKid)
			"rbxassetid://139904111224548", -- Urban Mirage - Night Drive Edit (DistroKid)
			"rbxassetid://140486290054589", -- Insert Coin (DistroKid)
			"rbxassetid://138826080188438", -- Escape the Night (DistroKid)
			"rbxassetid://1842960025", -- Infinite Void (APM)
		},
		MusicVolume = 0.22,
		-- per-car exhaust sets (owner's uploads): Exhaust_<car id>_<Start | Idle | Low | Mid | High |
		-- Launch | Crackle | Redline | Shift | Downshift | ShiftPop | Pops> (Low and the one-shots since
		-- 2026-11-03). Idle / Mid / High are loops blended by rpm; a car with them uses these
		-- instead of the shared engine sound (owner, 2026-10-22: the LP750 first, as a test)
		-- (the Aventador SV: the SVJ's set, copied after this table at half volume, owner 2026-11-03)
		-- (owner, 2026-11-03: "exhaust sounds for SVJ and SVJ 63"; the limiter is the SV's)
		Exhaust_lambrini_svj_Start = "rbxassetid://70853763868958",
		Exhaust_lambrini_svj_Idle = "rbxassetid://86888239641129",
		Exhaust_lambrini_svj_Low = "rbxassetid://119404279673406",
		Exhaust_lambrini_svj_Mid = "rbxassetid://70783605428332",
		Exhaust_lambrini_svj_High = "rbxassetid://129073457954629",
		Exhaust_lambrini_svj_Redline = "rbxassetid://15989284563",
		Exhaust_lambrini_svj_Shift = "rbxassetid://116713101274714",
		Exhaust_lambrini_svj_Downshift = "rbxassetid://109515735710638",
		Exhaust_lambrini_svj_ShiftPop = "rbxassetid://128716617727916",
		Exhaust_lambrini_svj_Pops = "rbxassetid://125121319222420",
		Exhaust_lambrini_svj_Launch = "rbxassetid://100034849111835",
		-- (owner, 2026-11-03: "exhaust sounds for SVJ and SVJ 63"; the limiter is the SV's)
		Exhaust_lambrini_svj63_Start = "rbxassetid://70853763868958",
		Exhaust_lambrini_svj63_Idle = "rbxassetid://86888239641129",
		Exhaust_lambrini_svj63_Low = "rbxassetid://119404279673406",
		Exhaust_lambrini_svj63_Mid = "rbxassetid://70783605428332",
		Exhaust_lambrini_svj63_High = "rbxassetid://129073457954629",
		Exhaust_lambrini_svj63_Redline = "rbxassetid://15989284563",
		Exhaust_lambrini_svj63_Shift = "rbxassetid://116713101274714",
		Exhaust_lambrini_svj63_Downshift = "rbxassetid://109515735710638",
		Exhaust_lambrini_svj63_ShiftPop = "rbxassetid://128716617727916",
		Exhaust_lambrini_svj63_Pops = "rbxassetid://125121319222420",
		Exhaust_lambrini_svj63_Launch = "rbxassetid://100034849111835",
		-- police and the bank (verified creators / ProSoundEffects)
		Siren = "rbxassetid://9056622054", -- Yelp-Police-Siren (loops)
		CameraFlash = "rbxassetid://9113678227", -- Camera Shutter 1 (SFX)
		Alarm = "rbxassetid://9113084849", -- Alarm Bell Constant Ring (SFX)
	}

	-- the Bugattis' W16 (owner, 2026-11-03: "add the exhaust sounds, make it super realistic and search
	-- from Toolbox ... a Veyron and Chiron exhaust sounds and don't forget the quad turbos blow-off and
	-- whine, it's the most important of a Bugatti"). Public Creator Store audio (checked: all load and
	-- play in Studio). Bands are crossfaded by rpm and each one pitched from the rpm it was recorded at
	-- (Config.ExhaustBands); the *Off bands are the coast (off-throttle) recordings. Turbo = the turbo
	-- whine loop (pitch and loudness follow the boost), Turbo2 = the second pair of the Chiron's
	-- sequential turbos (comes in at 3,800 rpm), BlowOff = the blow-off on lifting off under boost.
	do
		local CHIRON = {
			Start = "rbxassetid://119176690907106", -- "Bugatti Chiron W16 Startup" (EfiniRX)
			Idle = "rbxassetid://125444595831615", -- "Bugatti_Chiron_exh_on_Idle" (chazdoest0pic)
			Low = "rbxassetid://78106546390247", -- "Bugatti_Chiron_on3500_ext": on throttle at 3,500 rpm
			LowOff = "rbxassetid://102979441052957", -- "Bugatti_Chiron_off3500_ext": coasting at 3,500
			High = "rbxassetid://101082286464059", -- "Bugatti_Chiron_on6500_ext"
			HighOff = "rbxassetid://79069154574207", -- "Bugatti_Chiron_off6500_ext"
			Turbo = "rbxassetid://72711797703242", -- "bugatti_turbo" (schaefchen_17): the whine
			Turbo2 = "rbxassetid://72711797703242",
			BlowOff = "rbxassetid://101097691662187", -- a big twin-turbo blow-off (McLaren 650S, from a racing game)
		}
		local VEYRON = {
			Start = "rbxassetid://117970941785090", -- "Bugatti Veyron Startup Sound" (T0RQUES)
			Idle = "rbxassetid://82099770713185", -- "Bugatti Chiron Idle" (Tyudogg5): the same W16 at idle
			-- (owner, 2026-11-03: "the Veyron rev sound isn't good, switch it to this": the W16 bank's
			-- 3,500 rpm loop, pitched across the whole rev range; was the Asphalt and CSR2 loops)
			Low = "rbxassetid://102979441052957", -- "Bugatti_Chiron_off3500_ext" (chazdoest0pic)
			Turbo = "rbxassetid://72711797703242",
			BlowOff = "rbxassetid://95497630494219", -- a large blow-off ("toyotasupra_large", from a racing game)
		}
		local PUR_SPORT = table.clone(CHIRON)
		PUR_SPORT.Start = "rbxassetid://14130290830" -- "Bugatti Chiron Pur Sport Startup" (R5ist)
		local sets = {
			bugotti_veyron = VEYRON, bugotti_veyron_sport = VEYRON, bugotti_veyron_top = VEYRON,
			bugotti_chiron = CHIRON, bugotti_chiron_pursport = PUR_SPORT, bugotti_chiron_supersport = CHIRON,
		}
		for carId, set in sets do
			for part, id in set do
				Config.Sounds["Exhaust_" .. carId .. "_" .. part] = id
			end
		end
	end

	-- (owner, 2026-11-03: "use the SVJ exhaust sound and share it with the SV, but make the SV 2x
	-- quieter") the Aventador SV plays the SVJ's whole exhaust set at half volume (Config.ExhaustVolume).
	-- Tried the same day and dropped: the L539 V12 at 2,000 / 4,000 / 6,500 rpm ("l539-eng-acc-2000"
	-- 119081006371451, "-4000" 82866280346883, "-6500" 138629257229746) with the SV's idle
	-- 73235710388670, one ~4,700 rpm loop (72275841063718) and the "Aventador SVJ Revloop" bank
	do
		for _, part in { "Start", "Idle", "Low", "Mid", "High", "Launch", "Crackle", "Redline", "Shift", "Downshift", "ShiftPop", "Pops" } do
			Config.Sounds["Exhaust_lambrini_lp750_" .. part] = Config.Sounds["Exhaust_lambrini_svj_" .. part]
		end
	end

	-- (owner, 2026-11-05: "replace the lp 700 exhaust sound with the SV's exhaust but make it 1.6 times
	-- quieter and replace the start up with sound 6718630582, also make the exhaust sound realistic") the
	-- LP700-4 plays the SV's loops and one-shots with its own start-up; quieter in Config.ExhaustVolume,
	-- pitched from each loop's real engine speed in Config.ExhaustBands, timed in Config.ExhaustStart
	-- (owner, 2026-11-05: "remove the pop and bangs on the lp700") so not the SV's Crackle, ShiftPop or
	-- Pops, or its Shift clip (a bang at 0.4 s, 5 times the clip's level and louder than Pops: the upshift
	-- is the note dropping, `shiftCut`); `noPops` in Config.ExhaustBands stops the shared backfire too
	do
		for _, part in { "Idle", "Low", "Mid", "High", "Launch", "Redline", "Downshift" } do
			Config.Sounds["Exhaust_lambrini_lp700_" .. part] = Config.Sounds["Exhaust_lambrini_lp750_" .. part]
		end
		Config.Sounds.Exhaust_lambrini_lp700_Start = "rbxassetid://6718630582" -- "Lamborghini Aventador SVJ Startup" (1Rhymastic)
	end

	-- per-car exhaust loudness (every loop and one-shot of the car's set), 1 = as recorded
	Config.ExhaustVolume = { lambrini_lp750 = 0.5, lambrini_lp700 = 0.5 / 1.6 } :: { [string]: number }

	-- a car's own start-up clip, in seconds from pressing start: `idleAt` + `fade` the idle comes in,
	-- `out` to `ends` the clip fades away (touching the throttle jumps to `out`), `settleFrom` the rpm the
	-- clip ends on: the idle starts there and falls to its own rpm over `settle`. The LP700's clip: starter
	-- to 0.8 s (when the engine catches in Driving), flare 4,700 rpm, 2,800 by 1.3 s, 1,340 at its end
	-- (`gain`: the clip's loudness, 2026-11-09)
	Config.ExhaustStart = {
		lambrini_lp700 = { idleAt = 1.9, fade = 0.5, out = 2.2, ends = 2.6, settleFrom = 1340, settle = 2.5 },
	} :: { [string]: { idleAt: number, fade: number, out: number, ends: number, settleFrom: number?, settle: number?, gain: number? } }

	-- the engine speed a one-shot was recorded at (by asset), so it's pitched to the revs it plays at: the
	-- SVJ's downshift blip settles at ~4,200 rpm (its firing note)
	Config.ExhaustShotRpm = { ["rbxassetid://109515735710638"] = 4200 } :: { [string]: number }

	-- per-car exhaust bands: the rpm each loop was recorded at (the loop's pitch is the car's rpm over
	-- this; bands crossfade between their rpms), and the turbos: `whine` the whine's pitch at full boost,
	-- `seq` the rpm the second turbo pair comes in (sequential, the Chiron), `bov` the blow-off loudness;
	-- `gain` all the loops' loudness, `gains` one band's on top (to level loops recorded louder or softer),
	-- `width` how far each band reaches round its rpm (default 0.4; narrower = one recording heard at a time),
	-- `reachDown` a band's own reach below its rpm, `coast` the EQ (dB) with the throttle shut: the note goes
	-- dark and quiet on a lift, `shiftCut` seconds the note drops on an upshift (the ignition cut),
	-- `loopRpm` the rpm the Launch and Redline loops were recorded at, `idleReach` / `idleTop` how far above
	-- its rpm the idle loop lasts (default 0.28) and the highest it's pitched (default 1.45), `noPops` no
	-- pops or bangs: none of the sounds and none of the exhaust flames that go with them (nitro keeps its own)
	-- (2026-11-09) `gains.Redline` the limiter loop's loudness, `shots` each one-shot's loudness (Shift,
	-- Downshift, Pops, BlowOff, EWhine), `turbo` the turbo whine's loudness, `liftPops = false` no pops when
	-- you lift off (the car's own engine; a pop / crackle tune from the Part Shop still pops), `shiftPops =
	-- false` no bang or flame on a hard upshift (a smooth dual-clutch car)
	Config.ExhaustBands = {} :: { [string]: { bands: { [string]: number }, whine: number?, seq: number?, bov: number?, gain: number?, gains: { [string]: number }?, width: number?, reachDown: { [string]: number }?, coast: { mid: number, high: number }?, shiftCut: number?, loopRpm: { [string]: number }?, idleReach: number?, idleTop: number?, noPops: boolean?, shots: { [string]: number }?, turbo: number?, liftPops: boolean?, shiftPops: boolean? } }
	do
		local chiron = { bands = { Idle = 950, Low = 3500, High = 6500 }, whine = 0.62, seq = 3800, bov = 1.0 }
		local veyron = { bands = { Idle = 950, Low = 3500 }, whine = 0.7, bov = 1.0 }
		for _, id in { "bugotti_veyron", "bugotti_veyron_sport", "bugotti_veyron_top" } do
			Config.ExhaustBands[id] = veyron
		end
		for _, id in { "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport" } do
			Config.ExhaustBands[id] = chiron
		end
		-- the LP700-4: the SV's loops, each pitched from its real engine speed, measured from its firing
		-- note in Studio (a V12 fires at rpm / 10 Hz: Idle 100 Hz, Low 502, Mid 600, High ~790, Launch 504,
		-- limiter 820), so every loop plays the same note at any revs. `gains` keep the SV's loudness of
		-- each loop (with ExhaustVolume: the SV's, 1.6 times quieter)
		Config.ExhaustBands.lambrini_lp700 = {
			bands = { Idle = 1000, Low = 5020, Mid = 6000, High = 7900 },
			-- (nothing is recorded between 1,000 and 5,000 rpm: Low reaches down and the idle reaches up,
			-- they meet near 2,200, where each is at the end of its pitch)
			width = 0.2, reachDown = { Low = 0.55 }, idleReach = 0.45, idleTop = 2.2,
			gains = { Idle = 0.53, Low = 1.4, Mid = 1.4, High = 0.83 },
			coast = { mid = -3, high = -12 },
			shiftCut = 0.09,
			loopRpm = { Launch = 5040, Redline = 8200 },
			noPops = true,
		}
	end

	---------------------------------------------------------------------
	-- Supercar exhaust sounds by real engine (owner, 2026-11-09, Prompts/Realistic exhaust sounds for the
	-- supercars (real engines).md: "find their actual engine; for example the Ferrari 458 will be a
	-- flat-plane crank V8, naturally aspirated"). One sound set per engine family; each car on it gets small
	-- changes (`volume`, `tone`: `pitch`, EQ `low` / `mid` / `high` in dB, `drive` = rawness). The Bugattis and
	-- the ZV / ZVX / ZVX 63 keep their sounds (owner). A trim (SPORT / TOP) plays its base car's set.
	--
	-- Every id is public Creator Store audio (uploader in the comment; credits in City Legends.md). Each loop
	-- was measured in Studio (AudioPlayer:GetWaveformAsync): its engine speed from the spacing of its
	-- half-order lines (rpm / 120 Hz; checked on loops whose rpm is in their name: right to within 1%), its
	-- loudness (the `gains` level each loop to the same step from idle to redline) and its loop point (no
	-- click or jump in level). Clips that name a game, or look cut from one (on / off + rpm banks, "ext_on",
	-- "[31]"), were left out.
	--
	-- To put a car back on its old sound: Config.SupercarExhaust.Off.<car id> = true (the LP700-4 then plays
	-- the SV's loops again, the others the shared engine sound).
	-- (`Cars` is filled below: the cars now on these sets)
	Config.SupercarExhaust = { Enabled = true, Off = {} :: { [string]: boolean }, Cars = {} :: { [string]: boolean } }
	-- per-car tone on top of its set: `pitch`, EQ `low` / `mid` / `high` (dB), `drive` (0..0.3 distortion)
	Config.ExhaustTone = {} :: { [string]: { pitch: number?, low: number?, mid: number?, high: number?, drive: number? } }
	-- (in a function of its own: its many constants in the main chunk crashed Lune's Luau)
	local function supercarExhaust()
		local function id(n: number): string
			return "rbxassetid://" .. tostring(n)
		end
		local SVJ_POPS, SVJ_CRACKLE = Config.Sounds.SharedPops, Config.Sounds.SharedCrackle
		local V12_BLIP = "rbxassetid://109515735710638" -- the SVJ's downshift blip (in the game since 2026-11-03)
		local COAST = { mid = -3, high = -10 }
		local FAMILY: { [string]: any } = {
			-- Ferrari F136 V8, NA, flat-plane crank (458 4.5, F430 / California 4.3): high, sharp, to 9,000
			V8_FLATPLANE = {
				sounds = {
					Start = id(117250121821594), -- "458 startup" (SuperJMTABO): catches at once, flare ~2,500, settles ~720
					Idle = id(84053009150735), -- "458 idle" (xVlbez), 735 rpm
					Low = id(133285489196557), -- "458 Rev A_01" (xVlbez), 3,025 rpm
					Mid = id(100105615776941), -- "458 Rev B" (xVlbez), 5,090 rpm
					High = id(131194279941747), -- "458 Rev C" (xVlbez), 9,060 rpm
				},
				bands = {
					bands = { Idle = 735, Low = 3025, Mid = 5090, High = 9060 },
					gains = { Idle = 2.65, Low = 1.0, Mid = 1.31, High = 1.36 },
					width = 0.38, reachDown = { Low = 0.5 }, idleReach = 0.35, idleTop = 1.7,
					coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 2.6, fade = 0.8, out = 3.0, ends = 4.2, settleFrom = 720, settle = 1.0, gain = 1.5 },
			},
			-- Ferrari F140 V12, 6.0 NA (599 GTO; the Enzo has the same engine family): a smooth, rising wail
			V12_F140 = {
				sounds = {
					Start = id(126951297346788), -- "Ferrari 599 GTO startup" (Noobsttkill): catches at 1.35 s, ~1,400 at its end
					Idle = id(132538972175033), -- "Ferrari Enzo Idle" (Tyudogg5), 1,240 rpm
					Low = id(106444431622928), -- "Ferrari 599 GTB Revloop" (e92nic), 4,690 rpm
					Mid = id(110907563356979), -- "599ex" (zonda_collector), 5,600 rpm
					High = id(77826592795280), -- "Ferrari Enzo Revloop" (Tyudogg5), 6,850 rpm
					Downshift = V12_BLIP,
				},
				bands = {
					bands = { Idle = 1240, Low = 4690, Mid = 5600, High = 6850 },
					gains = { Idle = 0.34, Low = 2.12, Mid = 0.47, High = 0.92 },
					width = 0.32, -- (close bands: one recording at a time)
					coast = COAST, shiftCut = 0.08, liftPops = false, shiftPops = false,
					shots = { Downshift = 2.0 },
				},
				start = { idleAt = 4.4, fade = 0.8, out = 4.8, ends = 6.0, settleFrom = 1400, settle = 1.5, gain = 1.64 },
			},
			-- Lamborghini 6.5 V12, NA (Murcielago LP650-4 / LP670-4 SV): deep, raw, old-school
			V12_MURCIELAGO = {
				sounds = {
					Start = id(120002975599821), -- "Lamborghini Murcielago Startup" (Tyudogg5)
					Idle = id(132862605780028), -- "Lamborghini Murcielago Idle" (Tyudogg5), 1,185 rpm
					Low = id(135017534787316), -- "Lamborghini Murcielago Revloop" (Tyudogg5), 3,740 rpm
					Mid = id(95944505132247), -- "LAMBORGHINI MURCIELAGO REV 55" (alakatz), 5,500 rpm
					High = id(71771238598620), -- "Lamborghini Murcielago Revloop" (Tyudogg5), 7,450 rpm
					Downshift = V12_BLIP,
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1185, Low = 3740, Mid = 5500, High = 7450 },
					gains = { Idle = 0.29, Low = 0.79, Mid = 0.38, High = 0.45 },
					coast = COAST, shiftCut = 0.12,
					shots = { Downshift = 2.0, Pops = 1.3 },
				},
				start = { idleAt = 2.2, fade = 0.4, out = 2.4, ends = 2.74, settleFrom = 1530, settle = 2.0, gain = 0.66 },
			},
			-- Lamborghini L539 6.5 V12, NA (Aventador LP700-4): a screaming V12; the single-clutch ISR gearbox
			-- cracks on every upshift
			V12_AVENTADOR = {
				sounds = {
					Start = id(103478790721598), -- "Lamborghini Aventador Startup" (Tyudogg5): flare ~4,900, ~1,740 at its end
					Idle = id(91209556236511), -- "Lamborghini Aventador Idle" (Tyudogg5), 850 rpm
					Low = id(10006383812), -- "Aventador S Revloop fixed" (AmikkuHedgehog), 3,905 rpm
					High = id(80757676040270), -- "Lamborghini Aventador Rev" (Tyudogg5), 7,880 rpm
					Redline = id(137849905001581), -- "Limiter (Red) Aventador (1)" (KVERTH): the limiter, ~8,300
					Shift = id(97354969724257), -- "Aventador SVJ Crackle1" (Adhamkhedrhuman): the ISR crack
					Downshift = V12_BLIP,
				},
				bands = {
					bands = { Idle = 850, Low = 3905, High = 7880 },
					gains = { Idle = 0.62, Low = 0.43, High = 0.81, Redline = 0.69 },
					width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
					loopRpm = { Redline = 8300 },
					coast = COAST, shiftCut = 0.12,
					-- (owner, 2026-11-05: no pops and bangs on the LP700 when you lift; the shift crack is the gearbox)
					noPops = true,
					shots = { Shift = 3.6, Downshift = 2.0 },
				},
				start = { idleAt = 4.4, fade = 0.6, out = 4.8, ends = 5.3, settleFrom = 1740, settle = 2.5, gain = 1.56 },
			},
			-- Lamborghini L545 6.5 V12 + 3 electric motors (Revuelto): V12 to 9,500, a soft electric whine pulling away
			V12_REVUELTO = {
				sounds = {
					Start = id(80946715098566), -- "Revuelto Startup" (noobsttkillsounds), ~1,550 at its end
					Idle = id(91209556236511), -- the Aventador's idle (same V12 family; no clean Revuelto idle loop)
					Low = id(10006383812), -- "Aventador S Revloop fixed" (AmikkuHedgehog), 3,905 rpm
					High = id(138122265243234), -- "Revuelto Rev" (Cotten_Hill), 7,970 rpm
					Downshift = V12_BLIP,
					EWhine = id(9116980190), -- "Motor Whine Electric Whirring Buzzing 8 (SFX)" (ProSoundEffects)
				},
				bands = {
					bands = { Idle = 850, Low = 3905, High = 7970 },
					gains = { Idle = 0.62, Low = 0.43, High = 0.40 },
					width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
					coast = COAST, shiftCut = 0.05, shiftPops = false,
					shots = { Downshift = 2.0, EWhine = 1.0 },
				},
				start = { idleAt = 3.0, fade = 0.5, out = 3.2, ends = 3.76, settleFrom = 1550, settle = 2.0, gain = 0.94 },
			},
			-- Lamborghini 5.2 V12 with carburettors (Countach 5000 QV): intake roar, lots of character
			V12_COUNTACH = {
				sounds = {
					Start = id(88964621513263), -- "countach startup" (RSSUPER56), ~1,040 at its end
					Idle = id(18326228444), -- "Countach_idle" (ProGamersCh2), 1,030 rpm
					Low = id(135017534787316), -- the Murcielago's 3,740 rpm loop (the same Lamborghini V12 line)
					High = id(82845556133822), -- "LAMBORGHINI_COUNTACH_REVLOOP_22" (Chxvrxlet), 7,720 rpm
					Downshift = V12_BLIP,
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1030, Low = 3740, High = 7720 },
					gains = { Idle = 0.77, Low = 0.79, High = 3.22 },
					width = 0.42, coast = COAST, shiftCut = 0.15,
					shots = { Downshift = 1.6, Pops = 1.2 },
				},
				start = { idleAt = 3.3, fade = 0.6, out = 3.6, ends = 4.6, settleFrom = 1040, settle = 0.5, gain = 0.88 },
			},
			-- Lamborghini / Audi 5.2 V10, NA (Gallardo, Huracan, R8): a hard-edged howl
			V10 = {
				sounds = {
					Start = id(120452275990108), -- "Lamborghini Huracan Startup" (Tyudogg5), ~1,470 at its end
					Idle = id(87192192605296), -- "r8 idle" (TBWK128), 1,166 rpm
					Low = id(967630175), -- "Huracan Rev" (imawsome220), 4,080 rpm
					High = id(107508835832190), -- "2023 Lamborghini Huracan Tecnica_REDLINE" (w3xoq), 7,780 rpm
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1166, Low = 4080, High = 7780 },
					gains = { Idle = 0.53, Low = 0.39, High = 1.39 },
					width = 0.36, reachDown = { Low = 0.5 },
					coast = COAST, shiftCut = 0.06, shiftPops = false,
				},
				start = { idleAt = 2.2, fade = 0.5, out = 2.4, ends = 2.85, settleFrom = 1470, settle = 1.5, gain = 0.61 },
			},
			-- (owner, 2026-11-10: "Change all the R8 and hurcan rev loop to this: 77659121594090") the Huracans and the
			-- R8s: the V10 set with that one rev loop in place of the two Huracan loops (the Gallardos keep V10)
			V10_REV = {
				sounds = {
					Start = id(120452275990108), -- "Lamborghini Huracan Startup" (Tyudogg5), ~1,470 at its end
					Idle = id(87192192605296), -- "r8 idle" (TBWK128), 1,166 rpm
					High = id(77659121594090), -- "V10_rev" (Simonko9955), 6,920 rpm (steady over its 7.2 s, no jump at the seam)
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1166, High = 6920 },
					gains = { Idle = 0.53, High = 0.27 }, -- (a loud clip: rms 0.61, the old 7,780 loop's 0.12 at 1.39)
					width = 0.42, reachDown = { High = 0.6 }, idleReach = 0.4, idleTop = 1.8,
					coast = COAST, shiftCut = 0.06, shiftPops = false,
				},
				start = { idleAt = 2.2, fade = 0.5, out = 2.4, ends = 2.85, settleFrom = 1470, settle = 1.5, gain = 0.61 },
			},
			-- Toyota 1LR-GUE 4.8 V10, NA (LFA): the high, very fast F1-like scream
			LFA = {
				sounds = {
					Start = id(113328555788876), -- "lfa startup" (HaruHado), ~1,150 at its end
					Idle = id(105486944192315), -- "LFA Idle" (zonda_collector), 1,156 rpm
					Low = id(6927392752), -- "LFA Exhaust" (Basic42), 3,760 rpm
					Mid = id(6486544609), -- "Lexus LFA Revloop1" (Basic42), 7,990 rpm
					High = id(6486438800), -- "Lexus V10" (Basic42), 9,470 rpm
				},
				bands = {
					bands = { Idle = 1156, Low = 3760, Mid = 7990, High = 9470 },
					gains = { Idle = 0.50, Low = 1.97, Mid = 0.45, High = 0.66 },
					reachDown = { Low = 0.5 },
					coast = COAST, shiftCut = 0.1, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 3.6, fade = 0.6, out = 4.0, ends = 5.0, settleFrom = 1150, settle = 0.6, gain = 0.55 },
			},
			-- McLaren 3.8 twin-turbo V8, flat-plane (12C): a rasp with the turbos' whoosh and flutter. No clean
			-- 12C loops: these are the 720S's (its 4.0 is the same engine grown)
			V8_TWINTURBO = {
				sounds = {
					Start = id(136200211585476), -- "Startup 720S" (KVERTH), ~1,450 at its end
					Idle = id(78621869530140), -- "Idle 720s" (KVERTH), 1,430 rpm
					Low = id(102329538428291), -- "mclaren_720s_spider_middle" (ieu1713), 4,960 rpm
					High = id(74484380782795), -- "RevA 720s" (KVERTH), 8,070 rpm
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(117842945197592), -- "sfx_super-car-turbo-flutter-01" (AmikkuHedgehog)
					Downshift = id(114401892748128), -- "MCLARENV8DOWNSHIFT1" (YaBoyZenvo)
				},
				bands = {
					bands = { Idle = 1430, Low = 4960, High = 8070 },
					gains = { Idle = 0.47, Low = 0.39, High = 0.39 },
					width = 0.42, whine = 0.55, bov = 0.8, turbo = 0.6,
					coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
					shots = { Downshift = 0.85 },
				},
				start = { idleAt = 1.45, fade = 0.4, out = 1.6, ends = 2.03, settleFrom = 1450, settle = 0.3, gain = 1.04 },
			},
			-- Mercedes-AMG M159 6.2 V8, NA, cross-plane crank (SLS): deep muscle-car thunder, loud crackles
			V8_CROSSPLANE = {
				sounds = {
					Start = id(122484115722819), -- "SLS start" (B0tzep), ~1,150 at its end
					Idle = id(86966846628695), -- "Idle SLS" (B0tzep), 1,121 rpm
					Low = id(82458196515450), -- "SLS Engine RPM3" (lontanyl), 3,260 rpm
					High = id(124254451477176), -- "SLS Engine RPM10" (lontanyl), 5,415 rpm
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1121, Low = 3260, High = 5415 },
					gains = { Idle = 0.24, Low = 1.96, High = 2.90 },
					coast = COAST, shiftCut = 0.08,
					shots = { Pops = 1.6 },
				},
				start = { idleAt = 3.0, fade = 0.5, out = 3.3, ends = 4.0, settleFrom = 1150, settle = 0.5, gain = 0.81 },
			},
			-- Porsche 4.0 flat-6, NA (911 GT3): metallic, rising howl to 9,000, PDK blips on the way down
			FLAT6 = {
				sounds = {
					Start = id(131868759155566), -- "Porsche 911 GT3 Startup" (Tyudogg5), ~1,300 at its end
					Idle = id(90645713888895), -- "Idle GT3RS" (KVERTH), 1,302 rpm
					Low = id(123035578761975), -- "Porsche 911 GT3 Rev" (Tyudogg5), 4,610 rpm
					Mid = id(83330624942853), -- "Porsche 911 GT3 Rev" (Tyudogg5), 6,610 rpm
					High = id(107579237097468), -- "Porsche 911 GT3 Revloop" (Tyudogg5), 7,780 rpm
					Redline = id(91195272918788), -- "Porsche 911 GT3 Redline Rev-Limiter" (Tyudogg5), ~8,650
					Downshift = id(17552549922), -- "downshift flat six redo" (Thirty3Works): the blip, settles ~5,150
				},
				bands = {
					bands = { Idle = 1302, Low = 4610, Mid = 6610, High = 7780 },
					gains = { Idle = 0.40, Low = 0.48, Mid = 0.67, High = 1.22, Redline = 0.82 },
					loopRpm = { Redline = 8645 },
					coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
					shots = { Downshift = 0.48 },
				},
				start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 4.0, settleFrom = 1330, settle = 0.5, gain = 0.89 },
			},
			-- (owner, 2026-11-10: "don't forget to add exhaust sounds for them if they don't have": the six
			-- imports of Prompts/Finish the 7 waiting imports that had no set; found, measured and levelled the
			-- same way as the sets above. Not heard by ear.)
			-- BMW S85 5.0 V10, NA (E60 M5): odd-firing, so a strong 2.5 order under the 5th; to 8,250
			V10_S85 = {
				sounds = {
					Start = id(92477496018635), -- "e60 m5 start" (313Dday): catches at 1.05 s, ~930 at its end
					Idle = id(91710929912172), -- "e60_m5_exh_idle" (imziIo), 905 rpm
					Low = id(81767984377994), -- "RevB & RelB M5 E60 New" (KVERTH), 5,617 rpm
					High = id(72998982295293), -- "RevA & RelA M5 E60 New" (KVERTH), 8,287 rpm
				},
				bands = {
					bands = { Idle = 905, Low = 5617, High = 8287 },
					gains = { Idle = 0.34, Low = 0.43, High = 0.57 },
					-- (nothing is recorded between 905 and 5,617 rpm: Low reaches down and the idle reaches up)
					width = 0.42, reachDown = { Low = 0.6 }, idleReach = 0.45, idleTop = 2.2,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (the SMG's cut)
				},
				start = { idleAt = 1.7, fade = 0.5, out = 2.0, ends = 2.5, settleFrom = 930, settle = 0.5, gain = 0.77 },
			},
			-- BMW S65 4.0 / 4.4 V8, NA, cross-plane (E92 M3 / GTS): to 8,300
			V8_S65 = {
				sounds = {
					Start = id(18527193586), -- "M3 E92 STRAIGHTPIPE IGNITION" (r3_vl): catches at 0.75 s, ~1,180 at its end
					Idle = id(73671901945692), -- "M3 E92 idle crossplaned" (metius311), 1,430 rpm
					Low = id(100211620676087), -- "RevB E92 Gintani" (omega123058), 5,239 rpm
					High = id(123715831140370), -- "RevA and RelA E92 Gintani" (omega123058), 8,109 rpm
				},
				bands = {
					-- (tried and dropped: metius311's 2,019 rpm loop 111331460009411 as a band right above the idle:
					-- coasting down through 1,700 rpm the note went 2 times quieter between the two)
					bands = { Idle = 1430, Low = 5239, High = 8109 },
					gains = { Idle = 0.78, Low = 0.74, High = 0.61 },
					reachDown = { Low = 0.5 },
					coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 3.3, fade = 0.5, out = 3.6, ends = 4.3, settleFrom = 1180, settle = 1.0, gain = 0.81 },
			},
			I6_RB26 = if script then require(script.Parent.ExhaustRB26)(Config.Sounds) else nil,
			-- BMW S55 3.0 twin-turbo straight-6 (F82 M4): firing at the 3rd order with the 1.5 / 4.5 of its two
			-- turbos; whine, a blow-off on the lift, a few burbles
			I6_TWINTURBO = {
				sounds = {
					Start = id(94137111764818), -- "S55Startup" (YaBoyZenvo), ~1,210 at its end
					Idle = id(81564166436366), -- "S55 idle crossfade" (metius311), 1,190 rpm
					Low = id(111740167050459), -- "s55.low" (ObIiveracy), 4,101 rpm
					Mid = id(85381791243117), -- "RevB S55" (KVERTH), 5,773 rpm
					High = id(127910564907665), -- "RevA S55" (KVERTH), 7,129 rpm
					Redline = id(92088361930636), -- "Red S55" (KVERTH): the limiter, ~7,430
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(108432076069136), -- "turbo bov s58" (RedfieldBSAA): the S55's successor
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1190, Low = 4101, Mid = 5773, High = 7129 },
					gains = { Idle = 1.10, Low = 0.39, Mid = 0.42, High = 0.48, Redline = 0.61 },
					loopRpm = { Redline = 7432 },
					reachDown = { Low = 0.5 }, whine = 0.55, bov = 1.1, turbo = 0.6,
					coast = COAST, shiftCut = 0.05, shiftPops = false,
					shots = { Pops = 0.7 },
				},
				start = { idleAt = 1.5, fade = 0.4, out = 1.8, ends = 2.38, settleFrom = 1210, settle = 0.5, gain = 0.86 },
			},
			-- BMW S63 4.4 twin-turbo V8, cross-plane, turbos in the V (F90 M5 / M5 CS): a strong 2nd order
			V8_S63 = {
				sounds = {
					Start = id(103612899870303), -- "Startup M5" (KVERTH): catches at 0.6 s, ~1,460 at its end
					Idle = id(92369296738404), -- "F90CSIDLE2" (Rezixtxc), 900 rpm
					Low = id(86560702684802), -- "F90CSMID_012" (Rezixtxc), 4,602 rpm
					High = id(123277157456191), -- "F90CSHIGH_012" (Rezixtxc), 6,402 rpm
					Redline = id(112552469972463), -- "F90CSLIMITER_012" (Rezixtxc): the limiter, ~6,610
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(108749717618927), -- "TURBO FLUTTER M5 F90" (ThisIsGrandee)
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 900, Low = 4602, High = 6402 },
					gains = { Idle = 0.83, Low = 0.57, High = 0.58, Redline = 1.43 },
					loopRpm = { Redline = 6608 },
					width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
					whine = 0.55, bov = 1.1, turbo = 0.6,
					coast = COAST, shiftCut = 0.08, shiftPops = false,
					shots = { Pops = 0.7 },
				},
				start = { idleAt = 1.2, fade = 0.5, out = 1.5, ends = 2.4, settleFrom = 1460, settle = 1.5, gain = 0.67 },
			},
			-- VW group 4.0 twin-turbo V8 (Bentayga V8). No clean Bentayga V8 loops (the "bentayga" idle and
			-- start-up in the store are the W12): these are an Audi RS7's, the same engine, their rpm given by
			-- the uploader and measured the same
			V8_VW40 = {
				sounds = {
					Start = id(114174944994309), -- "Audi RS7 MNSRY Startup" (FinanceTrend): catches at 1.05 s, ~1,470 at its end
					Idle = id(100620796837132), -- "Audi RS7 MNSRY Idle" (FinanceTrend), ~1,050 rpm
					Low = id(107993163342852), -- "Audi RS7 MNSRY RevA" (FinanceTrend), 2,999 rpm
					High = id(135208328060016), -- "Audi RS7 MNSRY RevB" (FinanceTrend), 5,494 rpm
					Redline = id(105083828781421), -- "Audi RS7 MNSRY Redline" (FinanceTrend): the limiter, 6,994
					Turbo = Config.Sounds.SharedTurbo,
				},
				bands = {
					bands = { Idle = 1050, Low = 2999, High = 5494 },
					gains = { Idle = 0.25, Low = 0.41, High = 0.56, Redline = 0.64 },
					loopRpm = { Redline = 6994 },
					width = 0.42, reachDown = { Low = 0.5 }, whine = 0.5, turbo = 0.3,
					coast = COAST, shiftCut = 0.1, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 2.4, fade = 0.6, out = 2.8, ends = 3.9, settleFrom = 1470, settle = 1.5, gain = 0.96 },
			},
			-- Nissan VR38DETT 3.8 twin-turbo V6 (R35 GT-R): firing at the 3rd order, the turbos' whoosh and flutter
			V6_TWINTURBO = {
				sounds = {
					Start = id(8393134777), -- "Nissan GTR R35 (VR38DETT) Startup" (EfiniRX): catches at 0.75 s, ~1,290 at its end
					Idle = id(119747324235535), -- "nissan gtr idle" (jeemuzujamin), 1,255 rpm
					-- (owner, 2026-11-21: "add new exhaust sounds for the GTR r35") one recordist's exterior set (FROZENSOLlD,
					-- "GTR_<rpm>_<ON / OFF / RED>_OUT"): on-throttle loops, the redline, and coast recordings. The rpm is the
					-- file's own name, not measured here. Old loops: 86018842069517 / 130132947354022 / 106611475215254
					Low = id(110671849807653), -- "GTR_2500_ON_OUT"
					Mid = id(114724502959075), -- "GTR_5500_ONLOOP_OUT"
					High = id(78215344919914), -- "GTR_7200_RED_OUT"
					LowOff = id(100077226098132), -- "GTR_2500_OFF_OUT": coasting
					MidOff = id(84339007449917), -- "GTR_5500_OFF_OUT"
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(130283408353912), -- "VR38 Pop Off Flutter" (cezuuya)
				},
				bands = {
					bands = { Idle = 1255, Low = 2500, Mid = 5500, High = 7200 },
					gains = { Idle = 0.48, Low = 0.69, Mid = 0.74, High = 0.57 },
					reachDown = { Low = 0.5 }, whine = 0.6, bov = 0.5, turbo = 0.7,
					coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 1.9, fade = 0.5, out = 2.2, ends = 2.9, settleFrom = 1290, settle = 0.5, gain = 1.2 },
			},
			-- (owner, 2026-11-13: "also insert good exhaust sounds for all of the new imports model cars": the nine
			-- imports that still had no set; found, measured and levelled the same way as the sets above. Not
			-- heard by ear and not played in the game: checked in Edit only. Where the store has no clean loop of
			-- the engine itself the comment says STAND-IN and what was taken instead.)
			-- Mercedes-AMG M177 4.0 twin-turbo V8, cross-plane, turbos in the V (DBX707, Maybach GLS 600): a deep
			-- burble, its 1.5 order as strong as the firing 4th. The loops are an AMG GT's and an E 63 S's (M178 /
			-- M177: one engine family)
			V8_M177 = {
				sounds = {
					Start = id(122992068282919), -- "Mercedes M177 Startup G63 S63 C63 E63 GT63 V8" (VeryWideSupra): catches at 0.35 s, ~1,200 at its end
					Idle = id(111360463876410), -- "Mercedes AMG GT Idle" (cezuuya), 1,394 rpm
					Low = id(119346653900828), -- "Mercedes AMG GT OnRev" (cezuuya), 3,985 rpm
					High = id(122177474643880), -- "e63s - rev" (llIIlIlIIlIIIllIllI), 6,040 rpm
					Turbo = Config.Sounds.SharedTurbo,
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1394, Low = 3985, High = 6040 },
					gains = { Idle = 0.32, Low = 0.52, High = 0.97 },
					width = 0.42, reachDown = { Low = 0.5 }, idleReach = 0.3, idleTop = 1.7,
					whine = 0.5, turbo = 0.3,
					coast = COAST, shiftCut = 0.08, shiftPops = false,
					shots = { Pops = 0.7 },
				},
				start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 3.9, settleFrom = 1200, settle = 1.5, gain = 0.96 },
			},
			-- Mercedes-AMG M275 / M279 6.0 twin-turbo V12 (SL 65 Black Series, Maybach S 680). The start-up and the
			-- idle are an SL 65's. STAND-IN for the revs: the store's clips named "M275" fire like a V8 (4th order),
			-- so the two rev loops are an Aston Martin DB11's 5.2 twin-turbo V12 (the same layout: a 60-degree
			-- V12 with two turbos, firing at the 6th order)
			V12_BITURBO = {
				sounds = {
					Start = id(129810580933923), -- "sl65start" (XXXEDGARZXXX): catches at 0.6 s, ~1,170 at its end
					Idle = id(90248945881277), -- "sl65idle" (XXXEDGARZXXX), ~1,190 rpm
					Low = id(123472507046073), -- "DB11 REV" (Hack_apocalypse), 3,638 rpm
					High = id(125662546814285), -- "DB11 High REV" (Hack_apocalypse), 6,450 rpm
					Turbo = Config.Sounds.SharedTurbo,
				},
				bands = {
					bands = { Idle = 1190, Low = 3638, High = 6450 },
					gains = { Idle = 0.32, Low = 0.31, High = 0.39 },
					width = 0.42, reachDown = { Low = 0.5 }, idleReach = 0.35, idleTop = 1.9,
					whine = 0.5, turbo = 0.3,
					coast = COAST, shiftCut = 0.15, liftPops = false, shiftPops = false, -- (the old 5-speed automatic)
				},
				start = { idleAt = 1.0, fade = 0.4, out = 1.2, ends = 1.7, settleFrom = 1170, settle = 0.5, gain = 0.71 },
			},
			-- Bentley 6.0 twin-turbo W12 (Continental): low, smooth, a muffled roar. The start-up, the idle and the
			-- top loop are a W12's (the top loop's 1.5 and 4.5 orders are its four rows of three; read as 6,776 rpm,
			-- half of that also fits its lines: if it sounds an octave low, make it `Low = 3388`). STAND-IN for
			-- the middle, where the store has nothing: the DB11's twin-turbo V12 loop (12 cylinders firing evenly)
			W12_BITURBO = {
				sounds = {
					Start = id(4524973661), -- "W12 Startup" (Scidelistia, "from a 2019 Bentley Continental GT"): catches at 0.45 s, fades from 1.5 s
					Idle = id(107118476589810), -- "w12 idle" (3M0B), 1,100 rpm
					Low = id(123472507046073), -- "DB11 REV" (Hack_apocalypse), 3,638 rpm: the stand-in
					High = id(101979518471250), -- "Bentley W12_1" (Bayview County, USA), 6,776 rpm
					Turbo = Config.Sounds.SharedTurbo,
				},
				bands = {
					bands = { Idle = 1100, Low = 3638, High = 6776 },
					gains = { Idle = 0.37, Low = 0.31, High = 0.48 },
					width = 0.42, reachDown = { Low = 0.5 }, idleReach = 0.4, idleTop = 2.0,
					whine = 0.5, turbo = 0.25,
					coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 1.0, fade = 0.5, out = 1.3, ends = 2.0, settleFrom = 1100, settle = 0.5, gain = 1.43 },
			},
			-- BMW B48 2.0 turbo four (G20 330i): firing at the 2nd order, a quiet turbo
			I4_B48 = {
				sounds = {
					Start = id(124759903946683), -- "330i-cold-start" (aboba_rblx22): catches at 0.45 s, ~1,250 at its end
					Idle = id(72682157866475), -- "b48idle" (bobthebreadeater45), 1,178 rpm
					Mid = id(101713305935312), -- "B48" (Iconicc_Sam), 5,520 rpm
					High = id(2101020049), -- "BMW B48" (cat1425), 6,940 rpm
					Turbo = Config.Sounds.SharedTurbo,
				},
				bands = {
					bands = { Idle = 1178, Mid = 5520, High = 6940 },
					gains = { Idle = 0.41, Mid = 0.38, High = 1.26 },
					-- (nothing is recorded between 1,178 and 5,520 rpm: Mid reaches down and the idle reaches up, they
					-- meet near 2,550, each at the end of its pitch; narrow reaches so neither is heard off its note)
					width = 0.42, reachDown = { Mid = 0.36, High = 0.3 }, idleReach = 0.36, idleTop = 2.25,
					whine = 0.6, turbo = 0.4,
					coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 3.3, fade = 0.6, out = 3.7, ends = 4.5, settleFrom = 1250, settle = 0.8, gain = 0.68 },
			},
			-- Ford 2.3 EcoBoost turbo four (Focus RS): raspy, pops on the overrun
			I4_ECOBOOST = {
				sounds = {
					Start = id(126813484338369), -- "RS 2016 Resonator Startup" (bburneddd): ~1,470 at its end
					Idle = id(104051998441716), -- "focusrs idle" (irrelevantspacee), 1,200 rpm
					High = id(129854379340123), -- "exhausthighrev focusrs" (irrelevantspacee), 6,050 rpm
					Redline = id(97881098917023), -- "ecoboost 4cylinder redline" (irrelevantspacee): held at the limit, 6,880
					Turbo = Config.Sounds.SharedTurbo,
					Pops = SVJ_POPS,
					Crackle = SVJ_CRACKLE,
				},
				bands = {
					bands = { Idle = 1200, High = 6050 },
					gains = { Idle = 0.31, High = 0.76, Redline = 1.01 },
					loopRpm = { Redline = 6880 },
					-- (nothing is recorded between 1,200 and 6,050 rpm: as the B48 above, they meet near 2,700)
					width = 0.42, reachDown = { High = 0.36 }, idleReach = 0.36, idleTop = 2.4,
					whine = 0.6, turbo = 0.5,
					coast = COAST, shiftCut = 0.12, -- (a manual gearbox: the lift between gears)
					shots = { Pops = 0.9 },
				},
				start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 3.8, settleFrom = 1470, settle = 1.5, gain = 0.98 },
			},
			-- Nissan VQ35 3.5 V6, NA (350Z): the VQ's trumpet, firing at the 3rd order with the 1.5 of its two banks
			V6_VQ = {
				sounds = {
					Start = id(79112988867667), -- "VQ35 350z Startup" (Orcasauruss): catches at 0.9 s, ~1,720 at its end
					Idle = id(119503765090845), -- "350z idle" (FoxZachkFan), ~1,090 rpm
					Low = id(95217919058169), -- "VQ35 350z Rev" (Orcasauruss), 3,712 rpm
					Mid = id(111830038089152), -- "350Z Rev" (Yakimo_H), 5,015 rpm
					High = id(96383283439833), -- "Nissan 350Z Rev1" (kennu_hdgamer), 6,340 rpm
				},
				bands = {
					bands = { Idle = 1090, Low = 3712, Mid = 5015, High = 6340 },
					gains = { Idle = 0.19, Low = 0.59, Mid = 0.47, High = 0.81 },
					width = 0.36, reachDown = { Low = 0.5 }, idleReach = 0.4, idleTop = 2.0,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 2.9, fade = 0.6, out = 3.3, ends = 4.0, settleFrom = 1720, settle = 2.0, gain = 1.05 },
			},
			-- (2026-11-14, Prompts/New imports - JDM: the 10 JDM cars; found, measured and levelled the same way as
			-- the sets above. Not heard by ear and not played in the game: checked in Edit only. Where the store has
			-- no clean loop of the engine itself the comment says STAND-IN and what was taken instead.)
			-- Toyota 2JZ 3.0 straight-six (Supra JZA80; the model is the SZ-R, the 2JZ-GE without turbos): smooth,
			-- firing at the 3rd order. The store's 2JZ loops are mostly of the turbo engine (same block, same firing);
			-- no turbo whine on this car. STAND-IN for the 2,712 loop: a 1JZ's (the 2.5 of the same JZ family)
			I6_2JZ = {
				sounds = {
					Start = id(8993055529), -- "Supra Mk4 Startup" (playermathislam): catches at 2.1 s, ~1,390 at its end
					Idle = id(93419682840865), -- "TRD SUPRA IDLE" (maronseo), 1,043 rpm
					Low = id(16971374937), -- "1JZ REV 8K" (Schzercro), 2,712 rpm (3rd order, its 1.5 family: a 1JZ, the stand-in)
					Mid = id(115536253810390), -- "2jz high" (imkn32), 5,149 rpm
					High = id(80023317803769), -- "2JZ rev" (OHM555_TH3), 6,275 rpm
				},
				bands = {
					bands = { Idle = 1043, Low = 2712, Mid = 5149, High = 6275 },
					gains = { Idle = 0.38, Low = 1.0, Mid = 0.6, High = 0.67 },
					width = 0.36, idleReach = 0.36, idleTop = 2.0,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 3.9, fade = 0.5, out = 4.3, ends = 4.95, settleFrom = 1400, settle = 1.5, gain = 0.54 },
			},
			-- Toyota 1JZ-GTE 2.5 turbo straight-six (Chaser JZX100 Tourer V): the 3rd order with the 1.5 / 4.5 of the
			-- turbo engine, a turbo whistle and a blow-off when you lift. The middle and top loops are a JZX90's (the
			-- Chaser before it, the same 1JZ-GTE)
			I6_1JZ = {
				sounds = {
					Start = id(83092780103696), -- "1JZ Startup" (xVlbez): catches at 0.6 s, ~1,570 at its end
					Idle = id(138396109625053), -- "1JZ Idle" (xVlbez), ~1,360 rpm (wanders a little)
					Low = id(16971374937), -- "1JZ REV 8K" (Schzercro), 2,712 rpm
					Mid = id(125731576761353), -- "jzx90 higher rev" (FoxZachkFan), 5,196 rpm
					High = id(115409529133660), -- "jzx90 rev high" (FoxZachkFan), 6,506 rpm
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(81615532180604), -- "toyota altezza 2jz turbo BOV" (Doda_66)
				},
				bands = {
					bands = { Idle = 1360, Low = 2712, Mid = 5196, High = 6506 },
					gains = { Idle = 0.25, Low = 1.0, Mid = 0.49, High = 0.66 },
					width = 0.36, idleReach = 0.34, idleTop = 1.85,
					whine = 0.6, bov = 2.0, turbo = 0.6,
					coast = COAST, shiftCut = 0.1, liftPops = false, shiftPops = false,
				},
				start = { idleAt = 4.6, fade = 0.6, out = 5.0, ends = 6.0, settleFrom = 1600, settle = 1.5, gain = 0.65 },
			},
			-- Toyota 4A-GE 1.6 four, no turbo (AE86): light, raspy, to 7,600, firing at the 2nd order. One 4A-G's set
			-- (it wears FCR carburettors: a little rawer than a stock AE86); its lumpy idle has half orders
			I4_4AGE = {
				sounds = {
					Start = id(111046349248842), -- "Toyota Sprinter Trueno AE86 4AGE Startup" (EfiniRX): catches at 0.9 s, ~1,270 at 2.4 s
					Idle = id(128396095394889), -- "AE86_4AG_FCR_Idle" (Easton00023), 831 rpm
					Low = id(111313095004466), -- "AE86_4AG_FCR_RevA" (Easton00023), 3,529 rpm
					Mid = id(122125607047063), -- "AE86_4AG_FCR_RevB" (Easton00023), 6,117 rpm
					High = id(92613380190086), -- "AE86_4AG_FCR_RevC" (Easton00023), 8,330 rpm
				},
				bands = {
					bands = { Idle = 831, Low = 3529, Mid = 6117, High = 8330 },
					gains = { Idle = 1.35, Low = 0.7, Mid = 0.83, High = 0.93 },
					width = 0.36, reachDown = { Low = 0.34 }, idleReach = 0.36, idleTop = 2.5,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 3.9, settleFrom = 1300, settle = 1.0, gain = 0.45 },
			},
			-- Mitsubishi 4G63T 2.0 turbo four (Lancer Evolution VI / VI TME / IX): boosty, firing at the 2nd order, a
			-- turbo whine, the blow-off's chatter when you lift, the limiter loop at the top
			I4_4G63 = {
				sounds = {
					Start = id(125720177856888), -- "evo 6 start" (ShaddiSFM): catches at 1.2 s, ~1,800 at its end
					Idle = id(92129694864788), -- "4G63 Idle" (satdun20990), 1,251 rpm
					Low = id(71796737353158), -- "4G63 Rev" (satdun20990), 4,000 rpm
					High = id(117609929046977), -- "evo low rev" (Jaskka221), 6,130 rpm
					Redline = id(18659132455), -- "4g63 redline" (oatm1ilk): bouncing on the limiter, ~7,685
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(17828427222), -- "4G63T BOV" (Chhil): a chattering blow-off
				},
				bands = {
					bands = { Idle = 1251, Low = 4000, High = 6130 },
					gains = { Idle = 0.27, Low = 0.27, High = 0.92, Redline = 0.57 },
					loopRpm = { Redline = 7685 },
					width = 0.36, reachDown = { Low = 0.36 }, idleReach = 0.34, idleTop = 2.05,
					whine = 0.6, bov = 0.6, turbo = 0.5,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 3.0, fade = 0.6, out = 3.4, ends = 4.3, settleFrom = 1800, settle = 1.5, gain = 0.52 },
			},
			-- Subaru EJ 2.2 / 2.5 turbo flat-4, unequal-length headers (Impreza 22B, GD STI): the boxer burble (strong
			-- half orders round the 2nd), a turbo spool, a blow-off, the limiter loop at the top
			B4_EJ = {
				sounds = {
					Start = id(8173556175), -- "Subaru 22B EJ22G H4 Startup" (EfiniRX): catches at 0.45 s, ~1,150 at its end
					Idle = id(3126352575), -- "Subaru GC8 Idle" (Keytoff), 990 rpm, lumpy (half orders)
					Low = id(90312613549608), -- "rpm_3,7k_ej22" (lontanyl), 3,432 rpm
					Mid = id(75777630381967), -- "Subaru 22b Rev1" (kennu_hdgamer), 5,584 rpm
					High = id(83409057523942), -- "STI Rev C" (xVlbez), 7,439 rpm
					Redline = id(79261274665830), -- "GC8 Exhaust Redline" (lontanyl): on the limiter, ~6,950
					Turbo = Config.Sounds.SharedTurbo,
					BlowOff = id(110690215236760), -- "22B Turbo Bov" (zx8129l)
				},
				bands = {
					bands = { Idle = 990, Low = 3432, Mid = 5584, High = 7439 },
					gains = { Idle = 0.2, Low = 0.32, Mid = 0.59, High = 0.35, Redline = 0.82 },
					loopRpm = { Redline = 6949 },
					width = 0.36, reachDown = { Low = 0.4 }, idleReach = 0.36, idleTop = 2.15,
					whine = 0.55, bov = 0.83, turbo = 0.5,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 1.9, fade = 0.5, out = 2.3, ends = 3.0, settleFrom = 1150, settle = 1.0, gain = 0.47 },
			},
			-- Subaru / Toyota FA20 2.0 flat-4, no turbo (BRZ / 86): thrummy and smooth (even orders round the 2nd).
			-- Only one clean rev loop in the store: nothing recorded between the idle and 5,543 rpm
			B4_FA20 = {
				sounds = {
					Start = id(124256013065540), -- "FA20start" (offtracke): catches at 0.9 s, ~1,700 at 2.2-3.5 s
					Idle = id(17755587127), -- "86 Idle" (xVlbez), 1,351 rpm
					High = id(108887066423163), -- "FA20rev" (offtracke), 5,543 rpm
				},
				bands = {
					bands = { Idle = 1351, High = 5543 },
					gains = { Idle = 0.63, High = 1.41 },
					-- (the idle reaches up and the loop down, they meet near 2,900, each inside its pitch)
					width = 0.42, reachDown = { High = 0.36 }, idleReach = 0.36, idleTop = 2.2,
					coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (a manual gearbox)
				},
				start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 4.2, settleFrom = 1700, settle = 1.5, gain = 0.55 },
			},
		}
		local GALLARDO = {
			sounds = {
				Start = id(104916533556412), -- "GallardoStartup" (YaBoyZenvo), ~1,490 at its end
				Idle = id(118435710042398), -- "GallardoEngineIdle" (YaBoyZenvo), 1,030 rpm
			},
			bands = { bands = { Idle = 1030 }, gains = { Idle = 0.27 }, shiftCut = 0.12 },
			start = { idleAt = 3.9, fade = 0.6, out = 4.2, ends = 4.98, settleFrom = 1490, settle = 2.0, gain = 0.55 },
		}
		local R8_START = {
			sounds = { Start = id(94856442609554) }, -- "V10R8Startup" (Teslaprodriv), ~1,400 at its end
			start = { idleAt = 3.6, fade = 0.5, out = 3.9, ends = 4.7, settleFrom = 1400, settle = 1.5, gain = 1.08 },
		}
		local F430_START = {
			sounds = { Start = id(133124486022122) }, -- "F430ScudStart" (FreeIsaacbolarini), ~1,750 at its end
			start = { idleAt = 2.9, fade = 0.6, out = 3.2, ends = 3.8, settleFrom = 1750, settle = 2.0, gain = 0.62 },
		}
		-- (2026-11-13) the Brava: the VW group V8 set with its own start-up, and the crackles it makes when you lift
		local URUS = {
			sounds = {
				Start = id(131425032768106), -- "Urus Start Up" (Karazu56): catches at 0.45 s, ~1,150 at its end
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = { liftPops = true, shots = { Pops = 0.8 } },
			start = { idleAt = 2.0, fade = 0.5, out = 2.3, ends = 3.2, settleFrom = 1150, settle = 1.0, gain = 1.13 },
		}
		-- (2026-11-13) the Z223 Royale V12: a V12 S-class's own quiet start-up
		local S600_START = {
			sounds = { Start = id(91901380785370) }, -- "S600Startup" (FreeIsaacbolarini): catches at 0.75 s, ~1,350 at its end
			start = { idleAt = 3.0, fade = 0.6, out = 3.4, ends = 4.3, settleFrom = 1350, settle = 0.5, gain = 2.1 },
		}
		-- (2026-11-14) the rally cars (CP9A Champion, GC8 Wide): anti-lag-style bangs and crackles when you lift and
		-- on the upshifts (a rally car's anti-lag, then the shared crackle)
		local RALLY = {
			sounds = {
				Pops = id(116465852621701), -- "Citroen r5 antilag 2" (FoxZachkFan)
				Crackle = SVJ_CRACKLE,
			},
			bands = { liftPops = true, shiftPops = true, shots = { Pops = 1.2 } },
		}
		-- (2026-11-14) the CT9A: an Evo IX's own start-up and a fluttering blow-off
		local CT9A = {
			sounds = {
				Start = id(4839254661), -- "Mitsubishi Lancer Evolution IX startup" (Clxbsport): catches at 1.8 s, ~1,860 at its end
				BlowOff = id(8064513314), -- "Turbo Flutter" (Kwerke_Individual)
			},
			bands = { bov = 0.77 },
			start = { idleAt = 2.6, fade = 0.5, out = 2.9, ends = 3.6, settleFrom = 1860, settle = 1.5, gain = 0.62 },
		}
		-- (2026-11-14) the CZ4A (Mitsubishi 4B11T 2.0 turbo four): an Evo X's own start-up and a soft flutter.
		-- STAND-IN for the loops: the store has no clean 4B11 loops (the "Evo X" clips there start in silence and
		-- come from an uploader of game rips), so it plays the 4G63 set, deeper and smoother (the car's `tone`)
		local CZ4A = {
			sounds = {
				Start = id(651110603), -- "Lancer Evolution X GSR Startup" (Truenus): catches at 0.6 s, ~1,870 at 3 s
				BlowOff = id(74179218220791), -- "turbo flutter 1" (lontanyl)
			},
			bands = { bov = 1.8, turbo = 0.35, whine = 0.5 },
			start = { idleAt = 2.8, fade = 0.6, out = 3.2, ends = 4.0, settleFrom = 1870, settle = 1.5, gain = 1.56 },
		}
		-- (2026-11-14) the GDB: the GD STI's fluttering blow-off
		local GDB = {
			sounds = { BlowOff = id(131145970580755) }, -- "Turbo flutter Subaru" (mzz_123456)
			bands = { bov = 0.77 },
		}
		-- each car: its family, then its own changes (`with`: shared extra parts, `volume`, `tone`, `bands`)
		local CARS: { [string]: any } = {
			ferrara_458 = { family = "V8_FLATPLANE" },
			ferrara_458spider = { family = "V8_FLATPLANE", volume = 1.05, tone = { high = 1 } },
			ferrara_458speciale = { family = "V8_FLATPLANE", volume = 1.15, tone = { drive = 0.1, high = 2 } }, -- rawer
			ferrara_f430 = { family = "V8_FLATPLANE", with = F430_START, tone = { high = 2 }, bands = { shiftCut = 0.1 } }, -- F1 gearbox
			ferrara_california = { family = "V8_FLATPLANE", volume = 0.72, tone = { high = -3 }, bands = { coast = { mid = -5, high = -14 } } }, -- smoother, quieter
			ferrara_599 = { family = "V12_F140" },
			lambrini_lp640 = { family = "V12_MURCIELAGO" },
			lambrini_lp670 = { family = "V12_MURCIELAGO", volume = 1.15, tone = { drive = 0.1, high = 1.5 } }, -- the SV: rawer
			-- (owner, 2026-11-05: the LP700 quieter than the SV: about as loud as it was)
			lambrini_lp700 = { family = "V12_AVENTADOR", volume = 0.47 },
			lambrini_revuelto = { family = "V12_REVUELTO" },
			lambrini_countach = { family = "V12_COUNTACH", tone = { low = 3, drive = 0.06 } }, -- the carburettors' roar
			lambrini_lp570 = { family = "V10", with = GALLARDO, volume = 1.05, tone = { drive = 0.08, high = 1 } },
			lambrini_lp560 = { family = "V10", with = GALLARDO, tone = { drive = 0.05 } },
			lambrini_huracan = { family = "V10_REV" },
			lambrini_performante = { family = "V10_REV", volume = 1.2, tone = { drive = 0.08, high = 1 }, bands = { shots = { Pops = 1.5 } } },
			lambrini_sto = { family = "V10_REV", volume = 1.25, tone = { drive = 0.1, high = 1.5 }, bands = { shots = { Pops = 1.6 } } },
			lambrini_sterrato = { family = "V10_REV", volume = 0.95, tone = { low = 1 } },
			-- the Audis: a bit more muffled than the Lamborghinis (1st generation), the 2nd generation sharper
			audy_r8 = { family = "V10_REV", with = R8_START, volume = 0.9, tone = { high = -4 }, bands = { shiftCut = 0.15, shots = { Pops = 0.7 } } },
			audy_r8_lw = { family = "V10_REV", with = R8_START, volume = 0.95, tone = { high = -3 }, bands = { shiftCut = 0.12, shots = { Pops = 0.7 } } },
			audy_r8_4s = { family = "V10_REV", with = R8_START, tone = { high = 1.5 }, bands = { shots = { Pops = 0.8 } } },
			audy_r8_4s_rwd = { family = "V10_REV", with = R8_START, tone = { high = 1.5 }, bands = { shots = { Pops = 0.8 } } }, -- (not in the game yet)
			lexis_lfa = { family = "LFA" },
			lexis_lfa_circuit = { family = "LFA", volume = 1.1, tone = { high = 1 } },
			mclaran_12c = { family = "V8_TWINTURBO" },
			bentz_sls = { family = "V8_CROSSPLANE" },
			porsha_gt3 = { family = "FLAT6" },
			-- (2026-11-10) the imports that had no set
			bnw_m5_e60 = { family = "V10_S85" },
			bnw_m3_e92 = { family = "V8_S65" },
			bnw_m4_f82 = { family = "I6_TWINTURBO" },
			bnw_m5_f90 = { family = "V8_S63" },
			bentlee_bentayga = { family = "V8_VW40", volume = 0.8, tone = { high = -4 } }, -- quieter and softer than the tuned RS7
			nisun_gtr = { family = "V6_TWINTURBO" },
			nisun_r34 = { family = "I6_RB26" },
			-- (2026-11-13) the last nine imports with no set
			astin_dbx = { family = "V8_M177", volume = 1.1, tone = { low = 2, drive = 0.06 }, bands = { shots = { Pops = 1.0 } } }, -- loud, a deep burble
			bentz_gls = { family = "V8_M177", volume = 0.6, tone = { high = -5 }, bands = { turbo = 0.2, liftPops = false, coast = { mid = -5, high = -14 } } }, -- quiet, smooth, no pops
			-- (the same VW group 4.0 V8 as the Highlands: its set, sharper and louder)
			lambrini_urusp = { family = "V8_VW40", with = URUS, volume = 1.1, tone = { high = 1.5, drive = 0.08 }, bands = { turbo = 0.4 } },
			bentz_sl65bs = { family = "V12_BITURBO", volume = 1.15, tone = { drive = 0.1, high = 2 } }, -- loud, hard-edged
			bentz_s680 = { family = "V12_BITURBO", with = S600_START, volume = 0.55, tone = { high = -6 }, bands = { turbo = 0.15, shiftCut = 0.05, coast = { mid = -5, high = -14 } } }, -- very quiet, silky
			bentlee_contgt = { family = "W12_BITURBO", volume = 0.9, tone = { low = 2, high = -4 } }, -- low, smooth, muffled
			bnw_330i_g20 = { family = "I4_B48", volume = 0.85 },
			dearb_focus_rs = { family = "I4_ECOBOOST", tone = { drive = 0.08, high = 1 } }, -- raspy
			nisun_350z = { family = "V6_VQ" },
			-- (2026-11-14) the 10 JDM cars
			toyoka_supra_mk4 = { family = "I6_2JZ" },
			toyoka_chaser = { family = "I6_1JZ" },
			toyoka_ae86 = { family = "I4_4AGE", volume = 0.95, tone = { high = 1.5, drive = 0.06 } }, -- raspy
			ronin_cp9a = { family = "I4_4G63" },
			ronin_cp9a_champ = { family = "I4_4G63", with = RALLY, volume = 1.2, tone = { drive = 0.1, high = 1 } }, -- louder, rally bangs
			ronin_ct9a = { family = "I4_4G63", with = CT9A, tone = { high = 2, drive = 0.05 } }, -- a bit sharper
			ronin_cz4a = { family = "I4_4G63", with = CZ4A, volume = 0.9, tone = { low = 3, high = -3 } }, -- deeper, smoother (stand-in loops)
			pleiad_gc8 = { family = "B4_EJ", with = RALLY, volume = 1.15, tone = { low = 1, drive = 0.08 }, bands = { shots = { Pops = 1.3 } } }, -- loud, rally bangs
			pleiad_gdb = { family = "B4_EJ", with = GDB },
			pleiad_zc6 = { family = "B4_FA20", volume = 0.95 },
		}
		local PARTS = { "Start", "Idle", "Low", "Mid", "High", "Launch", "Crackle", "Redline", "Shift", "Downshift", "ShiftPop", "Pops", "LowOff", "MidOff", "HighOff", "Turbo", "Turbo2", "BlowOff", "EWhine" }
		local function merged(a: any, b: any): any
			local out = table.clone(a or {})
			for k, v in b or {} do
				out[k] = if type(v) == "table" and type(out[k]) == "table" then merged(out[k], v) else v
			end
			return out
		end
		for carId, car in CARS do
			if not Config.SupercarExhaust.Enabled or Config.SupercarExhaust.Off[carId] then
				continue
			end
			local fam = FAMILY[car.family]
			if not fam then
				continue
			end
			local with = car.with or {}
			local sounds = merged(fam.sounds, with.sounds)
			local bands = merged(merged(fam.bands, with.bands), car.bands)
			for _, part in PARTS do
				Config.Sounds["Exhaust_" .. carId .. "_" .. part] = sounds[part] -- (clears the old set's parts)
			end
			bands.twin = string.find(car.family, "TWIN") ~= nil -- (2026-11-21: the flutter's pitch, Audio)
			Config.ExhaustBands[carId] = bands
			Config.ExhaustStart[carId] = merged(fam.start, with.start)
			Config.ExhaustVolume[carId] = car.volume or 1
			Config.ExhaustTone[carId] = car.tone
			Config.SupercarExhaust.Cars[carId] = true
		end
		-- the downshift blips' engine speed (their pitch follows the gear they land in)
		Config.ExhaustShotRpm["rbxassetid://17552549922"] = 5150
	end
	supercarExhaust()
end
