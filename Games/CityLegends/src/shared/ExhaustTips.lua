-- Exhaust tips for the flames and smoke (owner, 2026-11-21: "add exhaust flames and exhaust smoke for super cars and
-- only 5 cars for hyper cars, which is the 4 aventador and 1 revuelto", "find the exact exhaust area for it").
-- Measured from each car's own model file (imports/.../*.glb, rear view renders, the openings picked by eye, depth from
-- the mesh): { across, up, in } as a share of the car's LENGTH, from the middle of its width, its lowest point (tyre
-- bottom) and its rear-most point. Driving turns them into root space from the skin's own box, so they follow any scale.
-- Cars with no row here (no model file: Murcielago LP640 uses the LP650 roadster's file) get no flames.
-- (21 Nov, PC) every row checked in Studio with a marker at each tip, straight from behind: 19 right, 5 re-measured from
-- the car's own mesh in CarModels (loose round pieces low at the rear; tools/exhaust/ExhaustCheck.luau).
local Cars = require(script.Parent.Cars)

local ExhaustTips = {}

ExhaustTips.CARS = {
	audy_r8 = { { -0.1532, 0.0774, 0.0249 }, { 0.1532, 0.0774, 0.0249 } },
	audy_r8_4s = { { -0.1608, 0.0664, 0.0212 }, { -0.1332, 0.0664, 0.0121 }, { 0.1332, 0.0664, 0.0121 }, { 0.1608, 0.0664, 0.0212 } },
	audy_r8_lw = { { -0.152, 0.0769, 0.0284 }, { 0.152, 0.0769, 0.0284 } },
	bentz_sls = { { -0.1376, 0.0754, 0.0312 }, { -0.1086, 0.0754, 0.0248 }, { 0.1086, 0.0754, 0.0248 }, { 0.1376, 0.0754, 0.0312 } }, -- (21 Nov, measured in Studio from the mesh: the old row was the centre fog lamp)
	ferrara_458speciale = { { -0.0718, 0.0852, 0.0057 }, { 0.0718, 0.0852, 0.0057 } }, -- (21 Nov, measured: was 7 cm low)
	ferrara_458spider = { { -0.0255, 0.0749, 0.0004 }, { 0, 0.0749, 0 }, { 0.0255, 0.0749, 0.0004 } },
	ferrara_599 = { { -0.1356, 0.0742, 0.0266 }, { -0.1152, 0.0755, 0.0204 }, { 0.1152, 0.0755, 0.0204 }, { 0.1356, 0.0742, 0.0266 } }, -- (21 Nov, measured: was 3 cm low)
	ferrara_california = { { -0.156, 0.0892, 0.0239 }, { -0.156, 0.0669, 0.0231 }, { 0.156, 0.0892, 0.0231 }, { 0.156, 0.0669, 0.0239 } },
	lambrini_countach = { { -0.0818, 0.0881, 0 }, { -0.0638, 0.0881, 0 }, { 0.0638, 0.0881, 0 }, { 0.0818, 0.0881, 0 } },
	lambrini_huracan = { { -0.0788, 0.1254, 0.0082 }, { 0.0788, 0.1254, 0.0082 } },
	lambrini_lp560 = { { -0.1484, 0.0891, 0.0144 }, { -0.1243, 0.0891, 0.0095 }, { 0.1243, 0.0891, 0.0095 }, { 0.1484, 0.0891, 0.0144 } },
	lambrini_lp570 = { { -0.15, 0.094, 0.0184 }, { -0.1255, 0.094, 0.012 }, { 0.1255, 0.094, 0.012 }, { 0.15, 0.094, 0.0184 } }, -- (21 Nov, measured: the old row was the centre fog lamp)
	lambrini_lp640 = { { 0, 0.0947, 0.0042 } },
	lambrini_lp670 = { { 0, 0.0835, 0.0042 } },
	lambrini_lp700 = { { 0, 0.0692, 0.0043 } },
	lambrini_lp750 = { { -0.0287, 0.057, 0.0348 }, { -0.0099, 0.057, 0.0348 }, { 0.0099, 0.057, 0.0348 }, { 0.0287, 0.057, 0.0348 } },
	lambrini_performante = { { -0.0784, 0.1291, 0.0051 }, { 0.0784, 0.1291, 0.0051 } },
	lambrini_revuelto = { { -0.0368, 0.1653, 0.0117 }, { 0.0368, 0.1653, 0.0117 } },
	lambrini_sterrato = { { -0.0783, 0.1389, 0.0083 }, { 0.0783, 0.1389, 0.0083 } },
	lambrini_sto = { { -0.0779, 0.129, 0.0117 }, { 0.0779, 0.129, 0.0117 } },
	lambrini_svj = { { -0.0568, 0.118, 0.023 }, { 0.0568, 0.118, 0.023 } },
	lambrini_svj63 = { { -0.055, 0.1173, 0.0198 }, { 0.055, 0.1173, 0.0198 } },
	mclaran_12c = { { -0.0513, 0.1532, 0.0082 }, { 0.0513, 0.1532, 0.0082 } },
	porsha_gt3 = { { -0.0132, 0.0662, 0.0011 }, { 0.0132, 0.0662, 0.0011 } }, -- (21 Nov, measured: was 8 cm high, 3 cm wide)
}

-- the hypercars that get them (every other hypercar stays clean)
ExhaustTips.HYPER = { lambrini_lp700 = true, lambrini_lp750 = true, lambrini_svj = true, lambrini_svj63 = true, lambrini_revuelto = true }

local function base(id: string): string
	local spec = Cars.get(id) :: any
	return if spec and spec.BaseId then spec.BaseId else id
end

function ExhaustTips.allowed(id: string): boolean
	local b = base(id)
	local spec = Cars.get(b) :: any
	if not spec then
		return false
	end
	return spec.Class == "Supercar" or ExhaustTips.HYPER[b] == true
end

function ExhaustTips.tipsOf(id: string): { { number } }?
	return ExhaustTips.CARS[base(id)]
end

return ExhaustTips
