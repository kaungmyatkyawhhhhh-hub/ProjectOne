-- The models' own number-plate holders (owner, 2026-11-21: "make the license plates in the proper place? Some cars
-- already have an license plate thing"). Measured in Studio from each model's own plate piece (Body_Plate ..., or a
-- plate-sized loose piece in the middle of the tail): { up, in, tilt, w, h } with up / in / w / h as a share of the car's
-- LENGTH (up from its lowest point, in from that end's outer-most point to the plate face's middle) and tilt in degrees
-- (the face leaning back, + = looking up). CarSkin puts our plate on it, sized to cover the holder. An end with no row
-- keeps the old way (a ray at bumper height). Tool: tools/plates/PlateScan.luau.
local Cars = require(script.Parent.Cars)

local PlateSpots = {}

PlateSpots.CARS = {
	astin_dbx = { rear = { 0.1232, 0.0202, 12.1, 0.0600, 0.0293 } },
	audy_r8_4s = { rear = { 0.1307, 0.0221, 15.7, 0.0689, 0.0332 } },
	bentlee_bentayga = { rear = { 0.1720, 0.0435, 15.0, 0.0584, 0.0282 } },
	bentz_s680 = { rear = { 0.1523, 0.0219, 12.1, 0.0565, 0.0273 } },
	bentz_sl65bs = { rear = { 0.1552, 0.0270, 17.4, 0.0669, 0.0318 } },
	bnw_m3_e92 = { rear = { 0.1787, 0.0263, 12.1, 0.0940, 0.0293 } },
	bnw_m4_f82 = { rear = { 0.1678, 0.0303, 15.0, 0.0644, 0.0322 } },
	bnw_m5_f90 = { rear = { 0.1608, 0.0255, 13.3, 0.0609, 0.0297 } },
	ferrara_458speciale = { rear = { 0.1230, 0.0084, 15.0, 0.0668, 0.0323 } },
	lambrini_countach = { rear = { 0.1186, 0.0366, 0.6, 0.0724, 0.0363 } },
	lambrini_huracan = { rear = { 0.1287, 0.0210, 6.3, 0.0675, 0.0334 } },
	lambrini_lp640 = { rear = { 0.1323, 0.0197, 21.2, 0.0654, 0.0307 } },
	lambrini_lp670 = { rear = { 0.1255, 0.0301, 23.0, 0.0644, 0.0298 } },
	lambrini_lp700 = { rear = { 0.1314, 0.0311, 19.3, 0.0639, 0.0303 } },
	lambrini_lp750 = { rear = { 0.1273, 0.0366, 18.1, 0.0621, 0.0290 } },
	lambrini_performante = { rear = { 0.0913, 0.0164, 6.3, 0.0665, 0.0332 } },
	lambrini_revuelto = { rear = { 0.0911, 0.0159, 18.6, 0.0617, 0.0292 } },
	lambrini_sto = { rear = { 0.0938, 0.0209, 5.1, 0.0660, 0.0330 } },
	lambrini_svj63 = { rear = { 0.0751, 0.0280, -10.4, 0.0618, 0.0304 } },
	lambrini_urusp = { rear = { 0.1663, 0.0279, 13.3, 0.0593, 0.0289 } },
	lexis_lfa = { rear = { 0.1529, 0.0212, 16.3, 0.0671, 0.0321 } },
	lexis_lfa_circuit = { rear = { 0.1513, 0.0211, 16.3, 0.0669, 0.0320 } },
	nisun_gtr = { rear = { 0.1362, 0.0108, 11.0, 0.0650, 0.0321 }, front = { 0.0948, 0.0065, -0.6, 0.0650, 0.0325 } },
	porsha_gt3 = { rear = { 0.1131, 0.0087, 12.1, 0.0671, 0.0327 } },
	toyoka_supra_mk4 = { rear = { 0.1341, 0.0133, 1.1, 0.0675, 0.0337 } },
} :: { [string]: { rear: { number }?, front: { number }? } }

function PlateSpots.of(id: string): { rear: { number }?, front: { number }? }?
	local m = Cars.modelOf(id)
	local row = PlateSpots.CARS[m] or PlateSpots.CARS[id]
	if not row then
		local spec = Cars.get(id) :: any
		if spec and spec.BaseId then
			row = PlateSpots.CARS[Cars.modelOf(spec.BaseId)] or PlateSpots.CARS[spec.BaseId]
		end
	end
	return row
end

return PlateSpots
