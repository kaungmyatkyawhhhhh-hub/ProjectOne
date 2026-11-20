--[[
	ExhaustRB26 (shared, 21 Nov 2026): the Nissan RB26DETT sound set (2.6 twin-turbo straight-six, the
	BNR34). Config's supercar exhaust FAMILY table takes it as I6_RB26 (moved out of Config, which is at
	its Source size limit). Called with Config.Sounds for the shared turbo / pops.
	All public Creator Store uploads (name, uploader). Firing measured with AudioPlayer:GetWaveformAsync +
	FFT: a straight-six fires at the 3rd order (rpm / 20 Hz), the turbo pair adds the 1.5 / 4.5.
]]
return function(sounds: { [string]: string }): { [string]: any }
	local function id(n: number): string
		return "rbxassetid://" .. tostring(n)
	end
	return {
		sounds = {
			Start = id(17664136845), -- "RB26 startup" (lutzywins): cranks 2.2 s, catches, idles
			Idle = id(134505405878971), -- "RB26_IDLE" (aclausypr), 1,188 rpm (a lumpy cam: strong half orders)
			Low = id(87793817413007), -- "rb26 2k on eng" (Crust_thug), 2,024 rpm
			Mid = id(112284479742965), -- "rb26 5k on exh" (Crust_thug), 4,984 rpm
			High = id(87446415279638), -- "rb26 7k on exh" (Crust_thug), 7,010 rpm
			Redline = id(125693689836374), -- "rb26 redline" (Crust_thug): the limiter, ~8,000
			Turbo = sounds.SharedTurbo,
			BlowOff = id(18609462234), -- "RB26 TURBO BOV" (ManedWolfMenace)
			Pops = sounds.SharedPops,
			Crackle = sounds.SharedCrackle,
		},
		bands = {
			bands = { Idle = 1188, Low = 2024, Mid = 4984, High = 7010 },
			gains = { Idle = 0.46, Low = 0.91, Mid = 0.5, High = 0.46, Redline = 0.6 },
			loopRpm = { Redline = 8000 },
			reachDown = { Mid = 0.5 }, whine = 0.55, bov = 1.1, turbo = 0.6,
			coast = { mid = -3, high = -10 }, shiftCut = 0.1, shiftPops = false, -- (a manual gearbox)
			shots = { Pops = 0.7 },
		},
		start = { idleAt = 3.5, fade = 0.5, out = 3.9, ends = 4.6, settleFrom = 1190, settle = 1.0, gain = 0.6 },
	}
end
