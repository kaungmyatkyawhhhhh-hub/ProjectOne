--[[
	CarSkin (client)
	Replaces the part-built bodywork of a car with its generated meshes
	(CarMesh -> EditableMesh -> MeshPart): one MeshPart per material layer
	(paint, accent, black trim, chrome, glass, LED lamps, tail lamps, plate,
	interior) plus real wheels: tyre + spoked rim spinning on the wheel
	joint, and a brake caliper on a steering knuckle (it steers but does not
	spin).

	Meshes are generated once per car design and cloned, so a city of traffic
	costs one set per design. Traffic uses the lighter "lite" versions.

	Imported models: if ReplicatedStorage has a "CarModels" folder holding a
	model named after a car id (made by tools/make_glb.py and brought in with
	Studio's 3D Importer), that car uses those MeshParts instead of runtime
	meshes. The "Mark_*" parts in it give the car's frame and scale, so it
	doesn't matter where the importer put it. Player cars, the garage and the
	cutscene prefer imported models; traffic keeps the cheap runtime "lite"
	meshes and falls back to the imported ones when runtime meshes are not
	allowed. With neither, apply() returns false and the part bodies stay.
]]

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarMesh = require(Shared:WaitForChild("CarMesh"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local Cars = require(Shared:WaitForChild("Cars"))
local DialLooks = require(script.Parent:WaitForChild("DialLooks"))
local BrandMarks = require(script.Parent:WaitForChild("BrandMarks"))
local TailLights = require(script.Parent:WaitForChild("TailLights"))

local CarSkin = {}

-- cars with their own dashboard design (DashGauges styles), built from the owner's reference photos
CarSkin.CLUSTER_STYLE = {
	-- owner's photos (2026-10-13): BMW Live Cockpit for the G-series BMWs, the F80 M3 cluster for the
	-- M3 / M4 (all three in the M3 E92 cabin), and the LX700h's digital meter
	bnw_330i_g20 = "BMWLiveCockpit",
	bnw_530i = "BMWLiveCockpit",
	bnw_540i = "BMWLiveCockpit",
	bnw_x6 = "BMWLiveCockpit",
	bnw_x7 = "BMWLiveCockpit",
	bnw_m8gc = "BMWLiveCockpit",
	bnw_m3_e92 = "BMWF80",
	bnw_m3_f80 = "BMWF80",
	bnw_m4_f82 = "BMWF80",
	lexis_lx700 = "LexusLX700",
	ferrara_458 = "Ferrari",
	ferrara_f430 = "Ferrari599", -- owner: same cluster as the 599
	bentz_cla45 = "AMG",
	toyoka_supra_mk4 = "SupraTRD",
	toyoka_camri = "Toyota",
	toyoka_crown = "Toyota",
	toyoka_lc200 = "Toyota",
	toyoka_alfard = "Toyota", -- owner (2026-10-22): its own dials didn't work; the LC200's cluster
	lambrini_lp570 = "Gallardo",
	kio_ev6 = "EV6",
	lambrini_urus = "Urus",
	chevo_c6 = "C6",
	chevo_c7 = "C7",
	-- the Sketchfab cars of 2026-10-12 (the owner's list of looks, from the real cars)
	bentz_s63 = "W213", -- S 65 W222: wide glass screen
	xiaomo_su7 = "SU7",
	byt_u8 = "U8",
	lexis_lfa = "LFA",
	lambrini_lp750 = "AventadorSV", -- its own cluster (owner's photo)
	lambrini_lp700 = "AventadorLP700", -- owner (2026-10-17): its own, copied from an LP700-4 video
	-- the cars of the second Sketchfab batch (looks from the real cars, until the owner sends photos)
	rolls_cullinan = "Maybach57", -- Phantom: chrome-ringed luxury dials
	rolls_wraith = "Maybach57",
	byt_seal = "U8", -- wide electric screen
	bentz_s680 = "W213",
	bentz_e400 = "W213", -- the E63 S W213 model: its wide glass screen
	bentz_gls = "W213", -- Maybach GLS 600: wide glass screen
	bnw_750li = "BMWLiveCockpit", -- the 750Li G12 (2026-10-18 model)
	bentz_gle53 = "AMG", -- in the C63 coupe's cabin, like the CLA 45
	-- the cars of 2026-10-18 (looks from the real cars)
	ferrara_california = "Ferrari",
	bentz_s65_w221 = "Maybach57", -- W221: round chrome dials
	bentz_190e = "Maybach57",
	toyoka_chaser = "Toyota",
	lexis_lc500 = "LFA", -- the LC takes the LFA's moving-ring screen
	astin_dbx = "Aston",
	lambrini_lp640 = "Murcielago", -- the 2026-10-18 model
	maseroti_levante = "Modern",
	bugotti_veyron = "Maybach57",
} :: { [string]: string }

-- where a car's own cluster screen is (measured on the model): its middle from the middle of the
-- steering wheel part, in metres along the car's right / up / back, the way it faces (towards the
-- driver) and its width and height in metres. A cluster style is drawn right there, covering it
-- (owner, 2026-10-13: "place them right above the dashboard where it covers the old cluster")
CarSkin.CLUSTER_RECT = {
	bnw_m3_e92 = { at = Vector3.new(0.0017, 0.03, -0.3167), face = Vector3.new(0, 0.33, 0.94), w = 0.287, h = 0.143 }, -- its cluster hood (from the model)
	-- the Land Cruzer 200 and the Alfard: over their models' own dial panels (owner, 2026-10-22: the
	-- LC200's sat too high, above the dash; "bring it down and match it exactly")
	toyoka_lc200 = { at = Vector3.new(0, 0.02, -0.247), face = Vector3.new(0, 0.12, 0.993), w = 0.267, h = 0.112 },
	toyoka_alfard = { at = Vector3.new(0.008, 0.053, -0.262), face = Vector3.new(0, 0.18, 0.984), w = 0.3, h = 0.12 },
	bnw_330i_g20 = { at = Vector3.new(0.0138, 0.0203, -0.2368), face = Vector3.new(-0, 0.321, 0.9471), w = 0.3191, h = 0.1134 },
	bnw_530i = { at = Vector3.new(-0.003, 0.0057, -0.2492), face = Vector3.new(-0.007, 0.3171, 0.9484), w = 0.3461, h = 0.1269 },
	bnw_540i = { at = Vector3.new(0.0025, 0.0094, -0.2389), face = Vector3.new(0.006, 0.3482, 0.9374), w = 0.3791, h = 0.136 },
	bnw_m8gc = { at = Vector3.new(0.0106, 0.0113, -0.2609), face = Vector3.new(0, 0.5269, 0.8499), w = 0.3273, h = 0.1128 },
	bnw_x6 = { at = Vector3.new(0.0101, 0.0352, -0.1909), face = Vector3.new(0.034, 0.334, 0.942), w = 0.3494, h = 0.1211 },
	bnw_x7 = { at = Vector3.new(-0.0025, -0.0002, -0.257), face = Vector3.new(0.034, 0.334, 0.942), w = 0.3496, h = 0.1339 },
	lexis_lx700 = { at = Vector3.new(-0.011, 0.0755, -0.114), face = Vector3.new(-0.012, -0.069, 0.9975), w = 0.3288, h = 0.1511 },
	-- the LP700 in the LP750's cabin: the LP750's whole screen (rev counter and both side screens),
	-- so the LP750 itself keeps its own cluster where it was
	lambrini_lp700 = { at = Vector3.new(-0.0005, 0.0194, -0.2354), face = Vector3.new(-0.001, 0.113, 0.9936), w = 0.334, h = 0.1455 },
} :: { [string]: { at: Vector3, face: Vector3, w: number, h: number } }

-- live needles over a car's own dials, for models whose needles are only painted on (the
-- converted model has them painted out of its texture; owner: keep the car's own cluster, no
-- screen over it). Per dial: its middle from the middle of the steering wheel part, in metres
-- along the car's right / up / back, the way the dial face looks (towards the driver), the
-- needle length (m) and its scale: dial reading -> degrees clockwise from 12 o'clock, with more
-- points for an uneven scale (a rev counter squeezed below 3000). Units: kmh, mph or rpm.
-- kind "digits" is a live speed read-out instead (length = its width) where the model's own showed
-- a fixed number. Measured from the converted files (needle ends, labels) by tools in the notes.
-- part-needle cars whose needle came out too long from the model's needle part (owner,
-- 2026-10-22: the M5 E60 and M6 needles reached past the dials): times the measured length
CarSkin.NEEDLE_LENGTH = {
	bnw_m5_e60 = 0.66,
	bnw_m6_v10 = 0.66,
} :: { [string]: number }

export type DialSpec = { kind: string, unit: string, at: Vector3, face: Vector3, length: number, scale: string }
CarSkin.DIAL_NEEDLES = {
	lambrini_countach = { -- Countach
		{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0825, 0.0077, -0.2274), face = Vector3.new(0, 0.1961, 0.9806), length = 0.0309, scale = "0:-110,20:-98.2,100:-51.7,180:3.1,320:114.9" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0911, 0.0056, -0.227), face = Vector3.new(-0, 0.1961, 0.9806), length = 0.0329, scale = "0:-138,1000:-99.6,2000:-56.6,3000:-24.7,4000:0.7,5000:26.9,6000:53,7000:79,8000:105,9000:131" },
	},
	astin_vantage = { -- V12 Vantage
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0517, 0.0515, -0.2403), face = Vector3.new(-0.0001, 0.3108, 0.9505), length = 0.0495, scale = "0:162,200:377" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0591, 0.0515, -0.2403), face = Vector3.new(-0.0001, 0.3108, 0.9505), length = 0.0495, scale = "0:208,1000:181,2000:150,3000:119,4000:89,5000:61,6000:30,7000:-4,8000:-34" },
	},
	astin_db9 = { -- Vanquish
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0582, 0.0319, -0.2625), face = Vector3.new(-0, 0.3132, 0.9497), length = 0.045, scale = "0:162,206:383.5" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0492, 0.0319, -0.2625), face = Vector3.new(-0, 0.3132, 0.9497), length = 0.045, scale = "0:208,1000:181,2000:150,3000:119,4000:89,5000:61,6000:30,7000:-4,8000:-34" },
	},
	bentlee_bentayga = { -- Bentayga
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.1002, -0.0152, -0.263), face = Vector3.new(-0.012, 0.4411, 0.8974), length = 0.0394, scale = "0:-123.7,4000:6.8,7000:102.3,8000:133.7" },
		{ kind = "speed", unit = "mph", at = Vector3.new(0.0965, -0.0163, -0.2622), face = Vector3.new(0.0126, 0.4677, 0.8838), length = 0.0474, scale = "0:-136.2,100:5.7,200:134.6" },
	},
	bentz_cls63s = { -- CLS 63 S
		{ kind = "speed", unit = "kmh", at = Vector3.new(0.0002, 0.0271, -0.2274), face = Vector3.new(0.0033, 0.3457, 0.9384), length = 0.0562, scale = "0:-118.9,240:121.8" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.1286, 0.0137, -0.2229), face = Vector3.new(0.0033, 0.3457, 0.9384), length = 0.0422, scale = "0:-127.1,8000:126.5" },
	},
	bentz_g63 = { -- 2015 G63 (its own cluster, like the owner's photo)
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0944, 0.0168, -0.2315), face = Vector3.new(0, 0.4173, 0.9088), length = 0.0425, scale = "0:-179.0,40:-122.1,80:-57.7,120:16.8,160:76.5" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0946, 0.0168, -0.2315), face = Vector3.new(0, 0.4173, 0.9088), length = 0.0418, scale = "0:-177.1,3000:-80.0,8000:93.6" },
	},
	bentz_gle53 = { -- GLE coupe (labels too blurry to read: an even 240 degree sweep)
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0866, 0.0505, -0.2422), face = Vector3.new(0.0005, 0.1327, 0.9912), length = 0.0466, scale = "0:-120.0,200:120.0" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0682, 0.0505, -0.2422), face = Vector3.new(0.0002, 0.1326, 0.9912), length = 0.0467, scale = "0:-120.0,8000:120.0" },
	},
	bentz_gt63s = { -- Dodger SRT
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0959, 0.004, -0.2664), face = Vector3.new(-0.0179, 0.2773, 0.9606), length = 0.0439, scale = "0:-127.1,4000:20.1,7000:125.1" },
		{ kind = "speed", unit = "mph", at = Vector3.new(0.1096, 0.0033, -0.2624), face = Vector3.new(-0.0179, 0.2773, 0.9606), length = 0.0447, scale = "0:-122.2,200:123.0" },
	},
	bentz_sl65bs = { -- SL65
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0388, 0.0642, -0.2453), face = Vector3.new(0.0004, 0.2209, 0.9753), length = 0.0427, scale = "0:-116.6,220:141.9" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0909, 0.0704, -0.2466), face = Vector3.new(0.0014, 0.2203, 0.9754), length = 0.041, scale = "0:-113.3,8000:120.9" },
	},
	bentz_sls = { -- SLS
		{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0958, 0.0054, -0.2386), face = Vector3.new(0.0192, 0.2122, 0.977), length = 0.038, scale = "0:-178.8,30:-157.6,360:89.7" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.101, 0.0052, -0.2396), face = Vector3.new(-0.0196, 0.2122, 0.977), length = 0.0336, scale = "0:177.3,1000:206.2,9000:446.0" },
	},
	brabos_g63 = { -- Brabus G63 (screen dials)
		{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0921, 0.0647, -0.2335), face = Vector3.new(-0.0011, 0.2758, 0.9612), length = 0.0435, scale = "0:-125.2,150:5.8,300:122.8" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0698, 0.0673, -0.2341), face = Vector3.new(-0.0012, 0.2757, 0.9613), length = 0.0422, scale = "0:-127.7,4000:-0.9,8000:124.6" },
	},
	ferrara_599 = { -- 599 (its own cluster, like the owner's photo)
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0093, 0.0332, -0.2044), face = Vector3.new(-0, 0.3732, 0.9278), length = 0.0362, scale = "0:-179.4,5000:-46.3,10000:74.1" },
		{ kind = "speed", unit = "kmh", at = Vector3.new(0.1007, 0.0333, -0.2044), face = Vector3.new(-0, 0.3734, 0.9277), length = 0.0333, scale = "0:176.2,170:316.2,350:470.8" },
	},
	mazdo_rx8 = { -- RX-8 (rev counter and the speed read-out)
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0021, 0.0463, -0.2049), face = Vector3.new(0, 0.18, 0.9837), length = 0.043, scale = "0:178.5,1000:201.4,4000:269.9,7000:347.7,10000:424.0" },
		{ kind = "digits", unit = "kmh", at = Vector3.new(0.0286, 0.0321, -0.2023), face = Vector3.new(0, 0.18, 0.9837), length = 0.0242, scale = "" },
	},
	nisun_gtr = { -- GT-R
		{ kind = "speed", unit = "mph", at = Vector3.new(-0.0881, 0.0233, -0.2101), face = Vector3.new(-0.0032, 0.2483, 0.9687), length = 0.0331, scale = "0:125.2,100:253.0,220:406.0" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0009, 0.0267, -0.2107), face = Vector3.new(-0.0009, 0.2484, 0.9687), length = 0.0392, scale = "0:-134.5,4000:-30.1,8000:69.5" },
	},
	nisun_r34 = {
		{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0541, 0.0125, -0.1938), face = Vector3.new(0, 0.314, 0.949), length = 0.047, scale = "0:-125.6,180:125.6" },
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0656, 0.0126, -0.1935), face = Vector3.new(0, 0.314, 0.949), length = 0.047, scale = "0:-125.7,3000:-85.2,10000:125.3" },
	},
	porsha_boxster = { -- Boxster (labels too blurry to read: an even 243 degree sweep)
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0008, 0.0489, -0.227), face = Vector3.new(0.0031, 0.2556, 0.9668), length = 0.0432, scale = "0:-122.0,8000:121.0" },
		{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0894, 0.0323, -0.2277), face = Vector3.new(-0.0042, 0.2663, 0.9639), length = 0.0346, scale = "0:-122.0,300:121.0" },
	},
	toyoka_lc300 = { -- Land Cruzer 300
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0853, 0.0288, -0.266), face = Vector3.new(0.0001, 0.1741, 0.9847), length = 0.0394, scale = "0:-110.9,4000:19.8,7000:119.7" },
		{ kind = "speed", unit = "kmh", at = Vector3.new(0.091, 0.03, -0.2662), face = Vector3.new(-0.0001, 0.1735, 0.9848), length = 0.0385, scale = "0:-113.0,140:-6.8,260:96.0" },
		{ kind = "digits", unit = "kmh", at = Vector3.new(-0.0041, 0.0646, -0.2678), face = Vector3.new(0.0007, 0.174, 0.9848), length = 0.0131, scale = "" },
	},
} :: { [string]: { DialSpec } }

-- cars that take another model's cabin (dash, seats, steering wheel, gauges), lined up on the
-- driver's eye; rear: how far behind the eye the swap reaches (studs: front seats only, or rear too)
CarSkin.INTERIOR_DONOR = {
	porsha_gt3 = { from = "porsha_boxster", rear = 1.8 }, -- owner (2026-10-16): the 718 cockpit, like the Panamera
	-- owner (2026-10-13): the M3 F80 and M4 F82 files' own cabins look bad; the M3 E92's goes in
	bnw_m3_f80 = { from = "bnw_m3_e92", rear = 1.8 },
	bnw_m4_f82 = { from = "bnw_m3_e92", rear = 1.8 },
	-- owner (2026-10-13): the Panamera's own cluster is broken; the 718 Boxster's cockpit goes in
	porsha_panamera = { from = "porsha_boxster", rear = 1.8 },
	-- owner (2026-10-13): the 458 Italia keeps its body and takes the 458 Speciale's cabin (a cabin
	-- donor only, not a car in the roster); its own Ferrari cluster design stays
	ferrara_458 = { from = "ferrara_458s", rear = 1.8 },
	-- owner (2026-10-17): the LP700's own cabin looks off and blocky; the LP750's goes in, with the
	-- LP700's own cluster design over its screen (not the LP750's)
	lambrini_lp700 = { from = "lambrini_lp750", rear = 1.8 },
	-- owner (2026-10-18): the CLA 45 and the GLE take the 2017 C63 AMG coupe's cockpit (a cabin
	-- donor only, not a car in the roster)
	bentz_cla45 = { from = "bentz_c63c", rear = 1.8 },
	bentz_gle53 = { from = "bentz_c63c", rear = 1.8 },
} :: { [string]: { from: string, rear: number } }

-- cars that take only another model's steering wheel, put where their own one sits
CarSkin.STEER_DONOR = {
	ferrara_599 = "ferrara_f430", -- owner: the F430's wheel in the 599
	bnw_x6 = "bnw_750li", -- owner (2026-10-22): the X6's own wheel looked bad; the 7 Series' one
	toyoka_alfard = "toyoka_lc300", -- its own wheel has the maker's logo printed on (owner: no logos)
} :: { [string]: string }

type Template = { part: MeshPart, offset: CFrame }
type GenericWheel = { x: number, parts: { Template }, fixed: { Template }? }
type Imported = {
	body: { [string]: Template },
	wheel: { [string]: Template },
	plate: CFrame?,
	exhausts: { Vector3 },
	-- set for any other car model (Creator Store, bought, hand-made): parts keep
	-- their own look and each corner's wheel parts ride on our wheel
	generic: { [string]: GenericWheel }?,
	-- the model's own steering wheel (turns with the steering) and driver's eye, in ground space
	steer: { mount: CFrame, parts: { Template }, radius: number }?,
	eye: Vector3?,
	-- where the live gauges go: on the dash surface behind the wheel, facing the driver (ground space)
	cluster: CFrame?,
	-- the model's own gauge needles (parts), turned by Driving; ownGauges also counts on-screen needles
	gauges: { { kind: string, pivot: CFrame, parts: { Template } } }?,
	ownGauges: boolean?,
	clusterSize: Vector2?,
	-- where the red glow behind the tail lamps goes (ground space)
	tailGlow: Vector3?,
}
type Look = { material: Enum.Material, color: Color3?, reflectance: number, transparency: number, shadow: boolean }

local TRIM = Color3.fromRGB(16, 16, 18)
local LOOKS: { [string]: Look } = {
	Paint = { material = Enum.Material.SmoothPlastic, reflectance = 0.2, transparency = 0, shadow = true },
	Accent = { material = Enum.Material.SmoothPlastic, reflectance = 0.2, transparency = 0, shadow = true },
	Trim = { material = Enum.Material.SmoothPlastic, color = TRIM, reflectance = 0.05, transparency = 0, shadow = true },
	Chrome = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(196, 200, 208), reflectance = 0.45, transparency = 0, shadow = false },
	Glass = { material = Enum.Material.Glass, color = Color3.fromRGB(12, 16, 22), reflectance = 0.25, transparency = 0.25, shadow = false },
	Lamp = { material = Enum.Material.Neon, color = Color3.fromRGB(236, 243, 255), reflectance = 0, transparency = 0, shadow = false },
	Tail = { material = Enum.Material.Neon, color = Color3.fromRGB(150, 0, 6), reflectance = 0, transparency = 0, shadow = false },
	Drl = { material = Enum.Material.Neon, reflectance = 0, transparency = 0, shadow = false },
	Plate = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(232, 232, 228), reflectance = 0, transparency = 0, shadow = false },
	Interior = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(22, 22, 26), reflectance = 0, transparency = 0, shadow = false },
	Tire = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(20, 20, 22), reflectance = 0, transparency = 0, shadow = true },
	Rim = { material = Enum.Material.SmoothPlastic, reflectance = 0.3, transparency = 0, shadow = true },
	Caliper = { material = Enum.Material.SmoothPlastic, reflectance = 0.1, transparency = 0, shadow = false },
}

local bodyCache: { [string]: { [string]: Template } | false } = {}
local bodyMeta: { [string]: { [string]: any } } = {}
local importCache: { [string]: Imported | false } = {}
local wheelCache: { [string]: { [string]: Template } | false } = {}
local keepAlive: { any } = {} -- EditableMeshes must stay alive while their MeshParts render
local warned = false

local function build(layer: CarMesh.Layer): Template
	local minV = Vector3.one * math.huge
	local maxV = -Vector3.one * math.huge
	for _, v in layer.verts do
		minV = minV:Min(v)
		maxV = maxV:Max(v)
	end
	local center = (minV + maxV) / 2
	local em = AssetService:CreateEditableMesh()
	local vids = table.create(#layer.verts, 0)
	local nids = table.create(#layer.verts, 0)
	for i, v in layer.verts do
		vids[i] = em:AddVertex(v - center)
		nids[i] = em:AddNormal(layer.normals[i])
	end
	local tris = layer.tris
	for i = 1, #tris, 3 do
		local a, b, c = tris[i], tris[i + 1], tris[i + 2]
		local face = em:AddTriangle(vids[a], vids[b], vids[c])
		em:SetFaceNormals(face, { nids[a], nids[b], nids[c] })
	end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	part.Size = (maxV - minV):Max(Vector3.one * 0.05)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	table.insert(keepAlive, em)
	return { part = part, offset = CFrame.new(center) }
end

local function fail(err: any)
	if not warned then
		warned = true
		warn("[CityLegends] Runtime car meshes unavailable (allow Mesh / Image APIs, or import CarModels):", err)
	end
end

local function bodyFor(id: string, class: string, lite: boolean): { [string]: Template }?
	local key = id .. (if lite then "/lite" else "")
	local cached = bodyCache[key]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, result = pcall(function()
		local layers, meta = CarMesh.build(id, class, CarBuilder.getDims(class, id) :: any, lite)
		bodyMeta[key] = meta
		local out = {}
		for name, layer in layers do
			out[name] = build(layer)
		end
		return out
	end)
	if ok then
		bodyCache[key] = result
		return result
	end
	bodyCache[key] = false
	fail(result)
	return nil
end

local function wheelFor(style: string, R: number, width: number, rimFrac: number, lite: boolean): { [string]: Template }?
	local key = string.format("%s/%.3f/%.3f/%.3f/%s", style, R, width, rimFrac, tostring(lite))
	local cached = wheelCache[key]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, result = pcall(function()
		local out = {}
		for name, layer in CarMesh.wheel(style, R, width, rimFrac, lite) do
			out[name] = build(layer)
		end
		return out
	end)
	if ok then
		wheelCache[key] = result
		return result
	end
	wheelCache[key] = false
	fail(result)
	return nil
end

-- Imported model for a car (see header), read once
local readGeneric: (src: Instance, dims: { [string]: number }) -> Imported -- defined below
local transplantInterior: (out: Imported, donor: Imported, rear: number) -> () -- defined below
local MARK_REF = 4 -- Mark_RefX / Mark_RefZ sit this many studs from Mark_Origin
local function readImported(src: Instance): Imported
	local function mark(name: string): Vector3?
		local m = src:FindFirstChild(name, true)
		return if m and m:IsA("BasePart") then m.Position else nil
	end
	local o, rx, rz = mark("Mark_Origin"), mark("Mark_RefX"), mark("Mark_RefZ")
	if not (o and rx and rz) then
		local spec = Cars.get((src:GetAttribute("CarId") :: string?) or src.Name)
		local dims = CarBuilder.getDims(spec.Class, spec.Id) :: any
		local out = readGeneric(src, dims)
		-- another model's cabin (dash, seats, wheel, gauges) swapped in: see INTERIOR_DONOR
		local swap = CarSkin.INTERIOR_DONOR[src.Name]
		local folder = ReplicatedStorage:FindFirstChild("CarModels", true)
		local donorSrc = if swap and folder then folder:FindFirstChild(swap.from, true) else nil
		if swap and donorSrc then
			local dspec = Cars.ById[swap.from]
			local ok, err = pcall(function()
				-- a donor not in the roster: the car's class at the donor's own wheelbase (REAL_WB)
				local donorDims = if dspec then CarBuilder.getDims(dspec.Class, dspec.Id) :: any else CarBuilder.getDims(spec.Class, swap.from) :: any
				transplantInterior(out, readGeneric(donorSrc :: Instance, donorDims), swap.rear)
			end)
			if not ok then
				warn("[CityLegends] interior from " .. swap.from .. " could not be used:", err)
			end
		end
		local steerFrom = CarSkin.STEER_DONOR[src.Name]
		local steerSrc = if steerFrom and folder then folder:FindFirstChild(steerFrom, true) else nil
		if steerFrom and steerSrc and out.steer then
			local dspec = Cars.ById[steerFrom]
			local ok, err = pcall(function()
				local donorDims = if dspec then CarBuilder.getDims(dspec.Class, dspec.Id) :: any else dims
				local donor = readGeneric(steerSrc :: Instance, donorDims)
				local own = out.steer
				if donor.steer and own then
					-- same spot and tilt as the car's own wheel, the donor's rim, spokes and size
					out.steer = { mount = own.mount, parts = donor.steer.parts, radius = donor.steer.radius }
				end
			end)
			if not ok then
				warn("[CityLegends] steering wheel from " .. steerFrom .. " could not be used:", err)
			end
		end
		return out
	end
	local ex, ez = rx - o, rz - o
	local scale = MARK_REF / ex.Magnitude
	local frame = CFrame.fromMatrix(o, ex.Unit, ez.Unit:Cross(ex.Unit), ez.Unit)
	local function local_(p: Vector3): Vector3
		return frame:PointToObjectSpace(p) * scale
	end
	local hubW = mark("Mark_Hub")
	local hub = if hubW then local_(hubW) else Vector3.zero
	local out: Imported = { body = {}, wheel = {}, exhausts = {} }
	for _, d in src:GetDescendants() do
		if not d:IsA("MeshPart") or d.Name:sub(1, 5) == "Mark_" then
			continue
		end
		local rel = frame:ToObjectSpace(d.CFrame)
		local isWheel = d.Name:sub(1, 5) == "Wheel"
		local part = d:Clone()
		part:ClearAllChildren() -- importer SurfaceAppearances etc.; LOOKS styles the parts
		part.Size = d.Size * scale
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		local pos = rel.Position * scale - (if isWheel then hub else Vector3.zero)
		local t = { part = part, offset = CFrame.new(pos) * rel.Rotation }
		if isWheel then
			out.wheel[d.Name:sub(6)] = t
		else
			out.body[d.Name] = t
		end
	end
	local plate = mark("Mark_Plate")
	if plate then
		local p = local_(plate)
		out.plate = CFrame.lookAt(p, p + Vector3.zAxis)
	end
	local i = 1
	while true do
		local e = mark("Mark_Exhaust" .. i)
		if not e then
			break
		end
		table.insert(out.exhausts, local_(e))
		i += 1
	end
	if next(out.body) == nil then
		error("no body parts")
	end
	return out
end

--[[
	Any other car model (Toolbox / Creator Store, bought, made in Blender):
	  * forward = its VehicleSeat (A-Chassis "DriveSeat"), else its PrimaryPart,
	    else the longest side. Set a Reverse = true attribute on the model if
	    it comes out backwards.
	  * wheels = the FL / FR / RL / RR children of a "Wheels" folder (A-Chassis),
	    else parts named wheel / tire / tyre / rim, split into four corners
	  * scaled so its wheelbase matches ours; its wheels spin on our wheels
	  * only visible parts are used, and only their looks are copied (mesh,
	    colour, material, textures): scripts and everything else stay behind
]]
local KEEP_CHILD = { SurfaceAppearance = true, SpecialMesh = true, Decal = true, Texture = true, SurfaceGui = true }

-- real makers' badges, logos and names come off every car (owner, 2026-10-17): parts and decals
-- named as badges or logos, at any depth ("BMW SIGN" models, "MAZDA LOGO" decals, "Trunk Badge")
local MARK_WORDS = { "badge", "logo", "emblem", "bmw sign", "шильд" }
local function isMarkName(name: string): boolean
	local n = name:lower()
	for _, w in MARK_WORDS do
		if n:find(w, 1, true) then
			return true
		end
	end
	return false
end

-- owner (2026-10-22): "remove all of the logo in the game": badge spots get plain covers, no
-- fictional emblems either (set true to bring them back)
local SHOW_EMBLEMS = false

-- our fictional emblems (similar to the real makers', not the same), drawn on a SurfaceGui
local EMBLEM_SILVER = Color3.fromRGB(206, 210, 218)
local function ring(parent: Instance, size: UDim2, aspect: number, color: Color3, thickness: number, fill: Color3?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = size
	f.BackgroundColor3 = fill or Color3.new()
	f.BackgroundTransparency = if fill then 0 else 1
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	local st = Instance.new("UIStroke")
	st.Color = color
	st.Thickness = thickness
	st.Parent = f
	if aspect ~= 1 then
		local a = Instance.new("UIAspectRatioConstraint")
		a.AspectRatio = aspect
		a.Parent = f
	end
	f.Parent = parent
	return f
end
local function bar(parent: Instance, x: number, y: number, w: number, h: number, rot: number, color: Color3, z: number?)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.Rotation = rot
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z or 2
	f.Parent = parent
	return f
end
-- BNW: a black roundel with a silver edge, the name round the top and a blue and white centre
-- quartered on the diagonal (the real one is quartered straight). Mercer: a silver ring round a
-- three-pointed star standing on one point. Lexis: a silver oval round a slanted, mirrored L.
local function drawEmblem(part: BasePart, brand: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Emblem"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(200, 200)
	gui.LightInfluence = 1
	gui.Parent = part
	if brand == "BNW" then
		ring(gui, UDim2.fromScale(0.96, 0.96), 1, EMBLEM_SILVER, 4, Color3.fromRGB(14, 14, 16))
		local inner = Instance.new("CanvasGroup")
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.Position = UDim2.fromScale(0.5, 0.5)
		inner.Size = UDim2.fromScale(0.56, 0.56)
		inner.BackgroundColor3 = Color3.fromRGB(245, 246, 248)
		inner.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = inner
		inner.Parent = gui
		-- two blue quarters, top and bottom, on the diagonal
		for _, y in { 0.25, 0.75 } do
			local q = bar(inner, 0.5, y, 0.72, 0.72, 45, Color3.fromRGB(38, 122, 206), 3)
			q.Position = UDim2.fromScale(0.5, if y < 0.5 then -0.01 else 1.01)
		end
		local st = Instance.new("UIStroke")
		st.Color = EMBLEM_SILVER
		st.Thickness = 2
		st.Parent = inner
		for i, l in { "B", "N", "W" } do
			local a = math.rad((i - 2) * 34)
			local t = Instance.new("TextLabel")
			t.AnchorPoint = Vector2.new(0.5, 0.5)
			t.Position = UDim2.fromScale(0.5 + math.sin(a) * 0.37, 0.5 - math.cos(a) * 0.37)
			t.Size = UDim2.fromScale(0.13, 0.13)
			t.Rotation = math.deg(a)
			t.BackgroundTransparency = 1
			t.Text = l
			t.TextScaled = true
			t.Font = Enum.Font.GothamBold
			t.TextColor3 = EMBLEM_SILVER
			t.ZIndex = 4
			t.Parent = gui
		end
	elseif brand == "Mercer" then
		ring(gui, UDim2.fromScale(0.92, 0.92), 1, EMBLEM_SILVER, 9)
		-- points at 6, 10 and 2 o'clock (the real star stands on two)
		for _, a in { 180, 300, 60 } do
			local r = math.rad(a)
			bar(gui, 0.5 + math.sin(r) * 0.23, 0.5 - math.cos(r) * 0.23, 0.07, 0.46, a, EMBLEM_SILVER)
			bar(gui, 0.5 + math.sin(r) * 0.12, 0.5 - math.cos(r) * 0.12, 0.13, 0.22, a, EMBLEM_SILVER)
		end
		ring(gui, UDim2.fromScale(0.13, 0.13), 1, EMBLEM_SILVER, 3, EMBLEM_SILVER)
	elseif brand == "Lexis" then
		ring(gui, UDim2.fromScale(0.94, 0.94), 1.42, EMBLEM_SILVER, 7)
		bar(gui, 0.56, 0.48, 0.07, 0.48, -16, EMBLEM_SILVER)
		bar(gui, 0.45, 0.715, 0.32, 0.07, -8, EMBLEM_SILVER)
	end
end

-- a thin cover over a badge spot (base colour) with, for emblems, ours drawn on top; its back
-- face sits on the car's surface, `cf` looking out of it
local function coverParts(cf: CFrame, w: number, h: number, color: Color3, disc: boolean, brand: string?): { Template }
	local thick = math.max(0.004, w * 0.04)
	local base = Instance.new("Part")
	base.Name = "MarkCover"
	base.Color = color
	base.Material = Enum.Material.SmoothPlastic
	base.CastShadow = false
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Massless = true
	local out: { Template } = {}
	if disc then
		base.Shape = Enum.PartType.Cylinder
		base.Size = Vector3.new(thick, w, w)
		table.insert(out, { part = base, offset = cf * CFrame.new(0, 0, -thick / 2) * CFrame.Angles(0, math.pi / 2, 0) })
	else
		base.Size = Vector3.new(w, h, thick)
		table.insert(out, { part = base, offset = cf * CFrame.new(0, 0, -thick / 2) })
	end
	if brand and SHOW_EMBLEMS then
		local e = Instance.new("Part")
		e.Name = "MarkEmblem"
		e.Transparency = 1
		e.Size = Vector3.new(w * 0.94, w * 0.94, 0.01)
		e.CastShadow = false
		e.CanCollide = false
		e.CanQuery = false
		e.CanTouch = false
		e.Massless = true
		drawEmblem(e, brand)
		table.insert(out, { part = e, offset = cf * CFrame.new(0, 0, -thick - 0.006) })
	end
	return out
end

-- tail lamps (owner, 2026-10-17: "add rear tail light for all cars"): a lamp part of the model gets
-- a red glowing copy over it, a hair bigger; Driving and Traffic brighten it when braking
local TAIL_COLOR = Color3.fromRGB(150, 0, 6)
local TAIL_WORDS = { "taillight", "tail light", "tail_light", "brakelight", "brake light", "brake_light", "rearlight", "rear light", "rear_light", "stoplight", "stop light" }
local function isTailName(name: string): boolean
	local n = name:lower()
	for _, w in TAIL_WORDS do
		if n:find(w, 1, true) then
			return n:find("cover", 1, true) == nil and n:find("frame", 1, true) == nil and n:find("bucket", 1, true) == nil
		end
	end
	return false
end
local function hasTexture(m: MeshPart): boolean
	local ok, id = pcall(function()
		return m.TextureID
	end)
	return not ok or id ~= ""
end
local function tailShell(p: BasePart, grow: number, transparency: number)
	for _, c in p:GetChildren() do
		if c:IsA("SurfaceAppearance") or c:IsA("Decal") or c:IsA("SurfaceGui") then
			c:Destroy()
		elseif c:IsA("SpecialMesh") then
			c.TextureId = ""
			c.Scale *= grow
		end
	end
	if p:IsA("MeshPart") then
		pcall(function()
			(p :: MeshPart).TextureID = ""
		end)
	end
	p.Size *= grow
	p.Material = Enum.Material.Neon
	p.Color = TAIL_COLOR
	p.Transparency = transparency
	p.CastShadow = false
	p:SetAttribute("TailLight", true)
	p:SetAttribute("TailOff", transparency)
end

local function visualClone(d: BasePart, scale: number): BasePart
	local p = d:Clone()
	for _, c in p:GetChildren() do
		if not KEEP_CHILD[c.ClassName] or ((c:IsA("Decal") or c:IsA("SurfaceGui")) and isMarkName(c.Name)) then
			c:Destroy()
		end
	end
	p.Size = d.Size * scale
	local sm = p:FindFirstChildOfClass("SpecialMesh")
	if sm then
		if sm.MeshType == Enum.MeshType.FileMesh then
			sm.Scale *= scale -- file meshes don't follow the part size
		end
		sm.Offset *= scale
	end
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	return p
end

function readGeneric(src: Instance, dims: { [string]: number }): Imported
	-- several cars imported from one file carry Blender's ".001" name endings (Wheels.001, FL.001,
	-- SteeringWheel_t21.001): take them off so the names below are found
	for _, d in src:GetDescendants() do
		local base = d.Name:match("^(.-)%.%d%d%d$")
		if base and base ~= "" then
			d.Name = base
		end
	end
	-- the model's steering wheel: an "SW" group (A-Chassis) or anything named steering wheel
	local steerRoots: { Instance } = {}
	local function isSteerName(n: string): boolean
		-- importer names like "Meshes/sw9 (1)" count too
		local k = n:lower():gsub("^meshes/", ""):gsub("%(%d+%)", ""):gsub("[%s_%-]", "")
		return k:match("^sw%d*$") ~= nil or k:find("steeringwheel") ~= nil
	end
	-- some kits call it just "Wheel", inside Misc (road wheels live in "Wheels")
	local function isMiscWheel(d: Instance): boolean
		return d.Name:lower() == "wheel" and d.Parent ~= nil and d.Parent.Name:lower() == "misc"
	end
	for _, d in src:GetDescendants() do
		if isSteerName(d.Name) or isMiscWheel(d) then
			local nested = false
			for _, r in steerRoots do
				if d:IsDescendantOf(r) then
					nested = true
					break
				end
			end
			if not nested then
				table.insert(steerRoots, d)
			end
		end
	end
	-- our converted cars name the wheel "SteeringWheel_t<tilt>": then that is the wheel, and other
	-- names with "steering wheel" in them (the column left in the dash) stay put
	local tagged: { Instance } = {}
	for _, r in steerRoots do
		if r.Name:match("^SteeringWheel_t%d+") then
			table.insert(tagged, r)
		end
	end
	if #tagged > 0 then
		steerRoots = tagged
	end
	-- nothing named: the round, thin part right in front of the driver's seat
	if #steerRoots == 0 then
		local ds = src:FindFirstChild("DriveSeat", true)
		if ds and ds:IsA("BasePart") then
			local best: BasePart? = nil
			local bestScore = math.huge
			for _, d in src:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") then
					local rel = ds.CFrame:PointToObjectSpace(d.Position)
					local sz = { d.Size.X, d.Size.Y, d.Size.Z }
					table.sort(sz)
					-- a flat disc, or a disc joined to its column (two sides equal, the third different)
					local disc = sz[2] >= 0.8 and sz[3] <= 2.4 and sz[3] / sz[2] < 1.35 and sz[1] < sz[2] * 0.6
					local onColumn = sz[1] >= 0.9 and sz[2] <= 2.0 and sz[2] / sz[1] < 1.15 and sz[3] <= 2.6 and sz[3] > sz[2] * 1.2
					local round = disc or onColumn
					if round and math.abs(rel.X) < 0.8 and rel.Y > 0.6 and rel.Y < 3.5 and rel.Z < -0.5 and rel.Z > -3.5 then
						local score = math.abs(rel.X) + math.abs(rel.Z + 1.6) * 0.5
						if score < bestScore then
							best, bestScore = d, score
						end
					end
				end
			end
			if best then
				table.insert(steerRoots, best)
				-- the other pieces of the same wheel (spokes, centre, buttons) sit right around it
				local bigSide = math.max(best.Size.X, best.Size.Y, best.Size.Z)
				for _, d in src:GetDescendants() do
					if d ~= best and d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") then
						local close = (d.Position - best.Position).Magnitude < bigSide * 0.35
						if close and math.max(d.Size.X, d.Size.Y, d.Size.Z) <= bigSide * 1.1 then
							table.insert(steerRoots, d)
						end
					end
				end
			end
		end
	end
	local function inSteer(d: Instance): boolean
		for _, r in steerRoots do
			if d == r or d:IsDescendantOf(r) then
				return true
			end
		end
		return false
	end

	-- makers' badges and logos stay behind: by name (the part or a group it is in), and the ones
	-- measured on our converted cars (BrandMarks: by name, and by size where the name is shared)
	local marks = BrandMarks[src.Name]
	local function isMark(d: BasePart): boolean
		if marks then
			if marks.keep and table.find(marks.keep, d.Name) then
				return false
			end
			for _, h in marks.hide do
				if d.Name == h.name and (h.size == nil or (d.Size - h.size).Magnitude < 0.01) then
					return true
				end
			end
		end
		local a: Instance? = d
		while a and a ~= src do
			if isMarkName(a.Name) then
				return true
			end
			a = a.Parent
		end
		return false
	end
	-- tail lamps: parts named as tail / brake lights, the converted cars' measured lamp parts
	-- (TailLights), and A-Chassis brake-light glow meshes (a "Brake" group, invisible when off)
	local tails = TailLights[src.Name]
	local function isTail(d: BasePart): boolean
		if tails then
			for _, sh in tails.shells do
				if d.Name == sh.name and (sh.size == nil or (d.Size - sh.size).Magnitude < 0.01) then
					return true
				end
			end
		end
		return isTailName(d.Name) or (d.Parent ~= nil and d.Parent ~= src and isTailName(d.Parent.Name))
	end
	local lampGlows: { BasePart } = {}
	for _, d in src:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency >= 0.98 and d.Parent then
			local n, pn = d.Name:lower(), d.Parent.Name:lower()
			local lampGroup = pn == "brake" or pn == "lights" or isTailName(pn)
			if (d:IsA("MeshPart") and (pn == "brake" or isTailName(pn))) or (lampGroup and (isTailName(n) or n:match("^brake%d*$") ~= nil or n == "tail")) then
				table.insert(lampGlows, d)
			end
		end
	end
	local visible: { BasePart } = {}
	for _, d in src:GetDescendants() do
		-- HideInGame: a piece we replace ourselves (e.g. a wheel centre fused with the gauge pod)
		if d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") and not d:GetAttribute("HideInGame") and not isMark(d) then
			table.insert(visible, d)
		end
	end
	if #visible == 0 then
		error("no visible parts")
	end
	local minV, maxV = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in visible do
		minV = minV:Min(d.Position)
		maxV = maxV:Max(d.Position)
	end
	-- forward direction
	local driveSeat = src:FindFirstChild("DriveSeat", true)
	local seat = if driveSeat and driveSeat:IsA("VehicleSeat") then driveSeat else src:FindFirstChildWhichIsA("VehicleSeat", true)
	local primary = if src:IsA("Model") then src.PrimaryPart else nil
	local f: Vector3
	if seat then
		f = seat.CFrame.LookVector
	elseif primary then
		f = primary.CFrame.LookVector
	else
		-- chassis corner parts (FL / FR / RL / RR, on their own or in "Wheels") tell the front from the back
		local wheelsGroup = src:FindFirstChild("Wheels", true)
		local function corner(n: string): Vector3?
			local p = src:FindFirstChild(n) or (if wheelsGroup then wheelsGroup:FindFirstChild(n) else nil)
			return if p and p:IsA("BasePart") then p.Position else nil
		end
		local fl, fr, rl, rr = corner("FL"), corner("FR"), corner("RL"), corner("RR")
		if fl and fr and rl and rr then
			f = (fl + fr - rl - rr) / 2
		else
			local ext = maxV - minV
			f = if ext.X > ext.Z then Vector3.xAxis else -Vector3.zAxis
		end
	end
	f = Vector3.new(f.X, 0, f.Z)
	if f.Magnitude < 1e-3 then
		error("can't tell which way the car faces")
	end
	f = f.Unit
	if src:GetAttribute("Reverse") == true then
		f = -f
	end
	local right = f:Cross(Vector3.yAxis)

	-- wheel groups
	type Group = { parts: { BasePart }, center: Vector3 }
	local groups: { Group } = {}
	local inWheel: { [BasePart]: boolean } = {}
	local function centerOf(list: { BasePart }): Vector3
		local a, b = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in list do
			a = a:Min(d.Position - d.Size / 2)
			b = b:Max(d.Position + d.Size / 2)
		end
		return (a + b) / 2
	end
	local wheelsNode = src:FindFirstChild("Wheels", true)
	if wheelsNode then
		for _, c in wheelsNode:GetChildren() do
			local list: { BasePart } = {}
			for _, d in visible do
				if d == c or d:IsDescendantOf(c) then
					table.insert(list, d)
				end
			end
			if #list > 0 then
				table.insert(groups, { parts = list, center = if c:IsA("BasePart") then c.Position else centerOf(list) })
			end
		end
	end
	if #groups ~= 4 then
		groups = {}
		local cand: { BasePart } = {}
		for _, d in visible do
			local n = d.Name:lower():gsub("trim", "") -- "trims" is not a rim
			if (n:find("wheel") or n:find("tire") or n:find("tyre") or n:find("rim")) and not n:find("steer") and not inSteer(d) then
				table.insert(cand, d)
			end
		end
		if #cand >= 4 then
			local c0 = centerOf(cand)
			local quads: { [string]: { BasePart } } = {}
			for _, d in cand do
				local rel = d.Position - c0
				local key = (if rel:Dot(f) > 0 then "F" else "R") .. (if rel:Dot(right) > 0 then "R" else "L")
				quads[key] = quads[key] or {}
				table.insert(quads[key], d)
			end
			for _, list in quads do
				table.insert(groups, { parts = list, center = centerOf(list) })
			end
		end
	end
	if #groups ~= 4 then
		error("couldn't find 4 wheels: put them in a 'Wheels' folder as FL, FR, RL, RR")
	end
	for _, g in groups do
		for _, d in g.parts do
			inWheel[d] = true
		end
	end
	-- the rest of each wheel: a tyre found by name often shares its own small group with the rim
	-- and hub (named anything); those parts spin with it too
	for _, g in groups do
		local size = 0
		for _, d in g.parts do
			size = math.max(size, d.Size.X, d.Size.Y, d.Size.Z)
		end
		local seen: { [Instance]: boolean } = {}
		for _, d in table.clone(g.parts) do
			local holder = d.Parent
			if not holder or holder == src or seen[holder] or not (holder:IsA("Model") or holder:IsA("Folder")) then
				continue
			end
			seen[holder] = true
			local all: { BasePart } = {}
			local tight = true
			for _, x in visible do
				if x:IsDescendantOf(holder) then
					table.insert(all, x)
					if (x.Position - g.center).Magnitude > size * 0.75 then
						tight = false
					end
				end
			end
			if tight and #all <= 16 then
				for _, x in all do
					if not inWheel[x] then
						inWheel[x] = true
						table.insert(g.parts, x)
					end
				end
			end
		end
	end
	local mid = Vector3.zero
	for _, g in groups do
		mid += g.center / 4
	end
	local frontZ, rearZ, nf, nr = 0, 0, 0, 0
	for _, g in groups do
		local a = (g.center - mid):Dot(f)
		if a > 0 then
			frontZ += a
			nf += 1
		else
			rearZ += a
			nr += 1
		end
	end
	if nf ~= 2 or nr ~= 2 then
		error("wheels are not two at the front and two at the back")
	end
	local wheelbase = (frontZ - rearZ) / 2
	local scale = math.clamp(dims.wb / math.max(wheelbase, 1e-3), 0.02, 50)
	-- wheel radius in the model's own studs (dims.wheelR is the same wheel at our scale)
	local modelR = dims.wheelR / scale
	-- stray props shipped with some models (stands, spare parts beside the car): anything whose
	-- centre is well outside the body around the wheels is left out
	do
		local track = 0
		for _, g in groups do
			track = math.max(track, math.abs((g.center - mid):Dot(right)))
		end
		local kept: { BasePart } = {}
		for _, d in visible do
			local rel = d.Position - mid
			local along, side, up = math.abs(rel:Dot(f)), math.abs(rel:Dot(right)), rel.Y
			if inWheel[d] or (along <= wheelbase * 1.0 and side <= track + wheelbase * 0.25 and up <= wheelbase * 0.8 and up >= -wheelbase * 0.3) then
				table.insert(kept, d)
			end
		end
		visible = kept
	end
	-- ground frame: its wheel centres land at our wheel height
	local origin = Vector3.new(mid.X, mid.Y - modelR, mid.Z)
	local frame = CFrame.lookAt(origin, origin + f)
	local function tmpl(d: BasePart, about: Vector3): Template
		local rel = frame:ToObjectSpace(d.CFrame)
		return { part = visualClone(d, scale) :: any, offset = CFrame.new(rel.Position * scale - about) * rel.Rotation }
	end
	local out: Imported = { body = {}, wheel = {}, exhausts = {}, generic = {} }

	-- steering wheel: turns about its own thinnest axis, pointing into the dash
	local steerParts: { BasePart } = {}
	local biggest: BasePart? = nil
	for _, d in visible do
		if not inWheel[d] and inSteer(d) then
			table.insert(steerParts, d)
			if not biggest or d.Size.Magnitude > biggest.Size.Magnitude then
				biggest = d
			end
		end
	end
	if biggest then
		-- the whole wheel's extent along the biggest piece's own sides (one piece can be just part
		-- of the rim, e.g. the Urus's flat-bottomed wheel)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in steerParts do
			local h = d.Size / 2
			for _, c in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
				local q = biggest.CFrame:PointToObjectSpace(d.CFrame:PointToWorldSpace(h * c))
				lo = lo:Min(q)
				hi = hi:Max(q)
			end
		end
		local sz = hi - lo
		-- the turning axis is the side that differs most from the other two (thin disc, or long column)
		local ex = { sz.X, sz.Y, sz.Z }
		local vecs = { biggest.CFrame.RightVector, biggest.CFrame.UpVector, biggest.CFrame.LookVector }
		local odd, oddScore = 1, -1
		for i = 1, 3 do
			local a2, b2 = ex[i % 3 + 1], ex[(i + 1) % 3 + 1]
			local score = math.min(math.abs(ex[i] - a2), math.abs(ex[i] - b2))
			if score > oddScore then
				odd, oddScore = i, score
			end
		end
		-- a steering wheel turns about an axis running down the car: a side that points sideways or
		-- up can't be it (a tilted wheel whose part isn't turned with it), so take the most forward one
		if math.abs(vecs[odd]:Dot(f)) < 0.5 then
			local bestDot = -1
			for i = 1, 3 do
				local dot = math.abs(vecs[i]:Dot(f))
				if dot > bestDot then
					odd, bestDot = i, dot
				end
			end
		end
		local axis = vecs[odd]
		local discSize = math.max(ex[odd % 3 + 1], ex[(odd + 1) % 3 + 1])
		if axis:Dot(f) < 0 then
			axis = -axis
		end
		-- our converted cars carry the wheel's tilt in its name ("SteeringWheel_t21"): Studio's
		-- importer flattens the part's own turn, so the tilt can't be read from the part
		local tiltTag = tonumber(biggest.Name:match("^SteeringWheel_t(%d+)") or "")
		if tiltTag then
			local t = math.rad(tiltTag)
			axis = (f * math.cos(t) - Vector3.yAxis * math.sin(t)).Unit
		elseif biggest.Name:match("^SteeringWheel") then
			-- the importer keeps the part's own turn in its pivot: its look is the turning axis
			local look = (biggest.CFrame * biggest.PivotOffset).LookVector
			local along = look:Dot(f)
			if math.abs(along) > 0.6 and math.abs(along) < 0.9999 then
				axis = if along > 0 then look else -look
			end
		end
		local a, b = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in steerParts do
			a = a:Min(d.Position)
			b = b:Max(d.Position)
		end
		local center = (a + b) / 2
		if tiltTag then
			-- our converted wheel, one piece per material (buttons and badge sit off to one side):
			-- the middle of all the pieces' extents
			center = biggest.CFrame:PointToWorldSpace((lo + hi) / 2)
		end
		if ex[odd] > discSize and #steerParts == 1 then
			-- wheel and column in one piece: the rim is at the driver's end
			center -= axis * (ex[odd] / 2 - 0.2)
		end
		local mountWorld = CFrame.lookAt(center, center + axis)
		local mountRel = frame:ToObjectSpace(mountWorld)
		local mount = CFrame.new(mountRel.Position * scale) * mountRel.Rotation
		local parts = {}
		for _, d in steerParts do
			local t = tmpl(d, Vector3.zero)
			t.offset = mount:Inverse() * t.offset
			table.insert(parts, t)
		end
		local radius = discSize / 2 * scale * 0.9
		if not (marks and marks.hub) then
			-- a maker's logo as its own little piece in the middle of the hub goes (owner,
			-- 2026-10-22: no logos); buttons sit out on the spokes and stay
			local kept = {}
			for _, t in parts do
				local p = t.offset.Position
				local s = t.part.Size
				if Vector2.new(p.X, p.Y).Magnitude < radius * 0.3 and math.max(s.X, s.Y, s.Z) < radius * 0.45 then
					continue
				end
				table.insert(kept, t)
			end
			parts = kept
		end
		if src:GetAttribute("AddSteerHub") then
			-- the model's wheel centre is fused with something else and hidden: build one
			local function hubPiece(size: Vector3, color: Color3, material: Enum.Material, z: number): Template
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Cylinder
				p.Size = size
				p.Color = color
				p.Material = material
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Massless = true
				p.CastShadow = false
				return { part = p, offset = CFrame.new(0, 0, z) * CFrame.Angles(0, math.pi / 2, 0) }
			end
			table.insert(parts, hubPiece(Vector3.new(0.18, radius * 0.95, radius * 0.95), Color3.fromRGB(16, 16, 18), Enum.Material.SmoothPlastic, 0.02))
			table.insert(parts, hubPiece(Vector3.new(0.04, radius * 0.2, radius * 0.2), Color3.fromRGB(235, 190, 20), Enum.Material.SmoothPlastic, 0.12)) -- small yellow dot, no glow
			for _, ang in { 0, math.pi } do
				local spoke = Instance.new("Part")
				spoke.Size = Vector3.new(radius * 0.75, 0.16, 0.08)
				spoke.Color = Color3.fromRGB(232, 232, 236)
				spoke.Material = Enum.Material.SmoothPlastic
				spoke.CanCollide = false
				spoke.CanQuery = false
				spoke.CanTouch = false
				spoke.Massless = true
				spoke.CastShadow = false
				table.insert(parts, { part = spoke, offset = CFrame.Angles(0, 0, ang) * CFrame.new(radius * 0.55, -0.04, 0) })
			end
		end
		-- the maker's logo on the hub: covered, with our emblem for the brands that have one
		local hub = marks and marks.hub
		if marks and hub then
			local spm = dims.wb / marks.wb -- game studs per metre of the converted file
			local face = hub.face.Unit
			local pos = hub.at * spm + face * 0.008 * spm
			for _, t in coverParts(CFrame.lookAt(pos, pos + face), hub.r * 2 * spm, hub.r * 2 * spm, hub.color, true, marks.brand) do
				table.insert(parts, t)
			end
		end
		out.steer = { mount = mount, parts = parts, radius = radius }
	end

	local roofTop: number? = nil
	local generatedWheel = false
	-- driver's eye: above the driver's seat, at 80% of the roof height there
	local seatPart = seat or src:FindFirstChildWhichIsA("Seat", true)
	local sp: Vector3? = if seatPart then frame:PointToObjectSpace(seatPart.Position) else nil
	if not sp then
		-- no seat in the model: put the driver where a real one sits, left of centre
		-- (left-hand drive) and a little behind the front axle (sports coupe: ~1.35 m)
		local m = 3 / scale -- model studs per metre (game is 3 studs per metre)
		local axleZ, n = 0, 0
		for _, g in groups do
			local c = frame:PointToObjectSpace(g.center)
			if c.Z < 0 then
				axleZ += c.Z
				n += 1
			end
		end
		if n > 0 then
			sp = Vector3.new(-0.37 * m, 0.35 * m, axleZ / n + 1.35 * m)
		end
		-- with the model's own steering wheel found, the driver sits a real reach behind it
		-- (~63 cm), in line with it
		if out.steer and sp then
			local w = out.steer.mount.Position / scale
			sp = Vector3.new(w.X, sp.Y, w.Z + 0.53 * m) -- (the eye goes 0.1 m further back below)
		end
	end
	if sp then
		local roof = 0
		-- (roofTop below keeps the levelled eye under the roof)
		for _, d in visible do
			if inWheel[d] then
				continue
			end
			local rel = frame:ToObjectSpace(d.CFrame)
			local h = d.Size / 2
			local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
			for _, c in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
				local q = rel * (h * c)
				lo = lo:Min(q)
				hi = hi:Max(q)
			end
			if sp.X >= lo.X and sp.X <= hi.X and sp.Z >= lo.Z and sp.Z <= hi.Z then
				roof = math.max(roof, hi.Y)
			end
		end
		if roof > 0 then
			local lift = (src:GetAttribute("EyeHeight") :: number?) or 0 -- per-car tweak, in studs
			out.eye = Vector3.new(sp.X * scale, roof * scale * 0.8 + lift, sp.Z * scale + 0.3)
			roofTop = roof * scale
		end
	end

	-- no separate steering wheel in the model (fused into one interior mesh, or none at all):
	-- build our own round wheel where a real one sits, a short reach in front of the driver
	if not out.steer and out.eye then
		local R, tube = 0.56, 0.14 -- real wheel: ~37 cm across, ~4.5 cm thick grip
		local center = out.eye + Vector3.new(0, -1.05, -1.75)
		local tilt = math.rad(24)
		local mount = CFrame.lookAt(center, center + Vector3.new(0, -math.sin(tilt), -math.cos(tilt)))
		local function piece(shape: Enum.PartType, size: Vector3, color: Color3, material: Enum.Material): Part
			local p = Instance.new("Part")
			p.Shape = shape
			p.Size = size
			p.Color = color
			p.Material = material
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			return p
		end
		local leather = Color3.fromRGB(24, 24, 27)
		local silver = Color3.fromRGB(196, 200, 208)
		-- Mercer: flat-bottomed rim, silver spokes and a three-pointed star (ours, upside down)
		local merc = src.Name:sub(1, 6) == "bentz_" or src.Name:sub(1, 7) == "brabos_"
		local parts: { Template } = {}
		local segs = 28
		for i = 0, segs - 1 do
			local ang = i / segs * math.pi * 2
			if merc and math.abs(ang - math.pi * 1.5) < math.rad(32) then
				continue -- the flat bottom goes here
			end
			local seg = piece(Enum.PartType.Cylinder, Vector3.new(2 * math.pi * R / segs * 1.18, tube, tube), leather, Enum.Material.SmoothPlastic)
			table.insert(parts, { part = seg :: any, offset = CFrame.new(R * math.cos(ang), R * math.sin(ang), 0) * CFrame.Angles(0, 0, ang + math.pi / 2) })
		end
		if merc then
			local half = R * math.sin(math.rad(36))
			local flat = piece(Enum.PartType.Cylinder, Vector3.new(half * 2, tube, tube), leather, Enum.Material.SmoothPlastic)
			table.insert(parts, { part = flat :: any, offset = CFrame.new(0, -R * math.cos(math.rad(36)), 0) })
		end
		-- three spokes (left, right, bottom) and a round airbag hub
		for _, ang in { 0, math.pi, -math.pi / 2 } do
			local spoke = piece(Enum.PartType.Block, Vector3.new(R * 0.9, 0.13, 0.07), if merc then silver else Color3.fromRGB(46, 46, 52), if merc then Enum.Material.Metal else Enum.Material.SmoothPlastic)
			table.insert(parts, { part = spoke :: any, offset = CFrame.Angles(0, 0, ang) * CFrame.new(R * 0.5, 0, 0.03) })
		end
		local hub = piece(Enum.PartType.Cylinder, Vector3.new(0.16, R * 0.78, R * 0.78), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic)
		table.insert(parts, { part = hub :: any, offset = CFrame.new(0, 0, 0.06) * CFrame.Angles(0, math.pi / 2, 0) })
		if merc then
			-- the star: a thin silver ring with three points
			local ring = R * 0.13
			for i = 0, 15 do
				local ang = i / 16 * math.pi * 2
				local seg = piece(Enum.PartType.Block, Vector3.new(2 * math.pi * ring / 16 * 1.2, 0.012, 0.02), silver, Enum.Material.Metal)
				table.insert(parts, { part = seg :: any, offset = CFrame.new(ring * math.cos(ang), ring * math.sin(ang), 0.15) * CFrame.Angles(0, 0, ang + math.pi / 2) })
			end
			-- (standing on one point, not the real star's two: owner, 2026-10-17, no real badges)
			for _, ang in { -math.pi / 2, -math.pi / 2 + math.pi * 2 / 3, -math.pi / 2 - math.pi * 2 / 3 } do
				local point = piece(Enum.PartType.Block, Vector3.new(ring, 0.014, 0.02), silver, Enum.Material.Metal)
				table.insert(parts, { part = point :: any, offset = CFrame.Angles(0, 0, ang) * CFrame.new(ring / 2, 0, 0.15) })
			end
		else
			local badge = piece(Enum.PartType.Cylinder, Vector3.new(0.02, R * 0.22, R * 0.22), silver, Enum.Material.Metal)
			table.insert(parts, { part = badge :: any, offset = CFrame.new(0, 0, 0.15) * CFrame.Angles(0, math.pi / 2, 0) })
		end
		local column = piece(Enum.PartType.Cylinder, Vector3.new(0.9, 0.26, 0.26), leather, Enum.Material.SmoothPlastic)
		table.insert(parts, { part = column :: any, offset = CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi / 2, 0) })
		out.steer = { mount = mount, parts = parts, radius = R * 0.95 }
		generatedWheel = true
	end

	-- the driver sits a real reach behind the wheel (~60 cm): some models' seats put the eye too close
	if out.steer and out.eye then
		local wz = out.steer.mount.Position.Z
		local eye = out.eye :: Vector3
		if eye.Z - wz < 1.4 then
			out.eye = Vector3.new(eye.X, eye.Y, math.min(wz + 1.4, eye.Z + 0.3))
		end
	end
	-- every car the same view (owner): the eye sits the same height above the steering wheel
	-- (0.8 studs, ~27 cm), kept under the roof; an EyeHeight attribute still nudges it
	if out.steer and out.eye and not generatedWheel then
		local eye = out.eye :: Vector3
		local lift = (src:GetAttribute("EyeHeight") :: number?) or 0
		local y = out.steer.mount.Position.Y + 0.8 + lift
		if roofTop then
			y = math.min(y, roofTop - 0.35)
		end
		out.eye = Vector3.new(eye.X, y, eye.Z)
	end

	-- gauges: look from the eye through the top half of the wheel and stop at the first
	-- dash surface past it (that's where the car's own instrument cluster is)
	if out.eye then
		local eyeW = frame:PointToWorldSpace(out.eye / scale)
		local fwdW = frame.LookVector
		local target: Vector3
		local minDist: number
		local rm: number -- wheel radius, model studs
		if out.steer then
			local mountW = frame * CFrame.new(out.steer.mount.Position / scale)
			rm = out.steer.radius / scale
			target = mountW.Position + Vector3.yAxis * rm * 0.35
			minDist = (target - eyeW).Magnitude + 0.15 / scale
		else
			rm = 0.5 / scale
			target = eyeW + fwdW * (2.2 / scale) - Vector3.yAxis * (0.75 / scale)
			minDist = 1.2 / scale
		end
		local dir = (target - eyeW).Unit
		local best = math.huge
		for _, d in visible do
			if inWheel[d] or inSteer(d) then
				continue
			end
			local o = d.CFrame:PointToObjectSpace(eyeW)
			local h = d.Size / 2
			if math.abs(o.X) <= h.X and math.abs(o.Y) <= h.Y and math.abs(o.Z) <= h.Z then
				continue -- a shell around the driver (whole-cabin mesh): not a dash surface
			end
			local v = d.CFrame:VectorToObjectSpace(dir)
			local tmin, tmax = -math.huge, math.huge
			local hit = true
			for _, ax in { "X", "Y", "Z" } do
				local oa, va, ha = (o :: any)[ax], (v :: any)[ax], (h :: any)[ax]
				if math.abs(va) < 1e-6 then
					if math.abs(oa) > ha then
						hit = false
						break
					end
				else
					local t1, t2 = (-ha - oa) / va, (ha - oa) / va
					tmin = math.max(tmin, math.min(t1, t2))
					tmax = math.min(tmax, math.max(t1, t2))
				end
			end
			if hit and tmax >= tmin and tmin > minDist and tmin < best then
				best = tmin
			end
		end
		local ownDesign = CarSkin.CLUSTER_STYLE[src.Name] ~= nil
		-- how far past the wheel the car's real cluster sits (studs); the Aventador's is deep in its hood
		local depth = if src.Name == "lambrini_lp700" then 1.0 else 0.45
		local t = if best < 4 / scale * 3 and not ownDesign then best - 0.03 / scale else (target - eyeW).Magnitude + depth / scale
		local posW = eyeW + dir * t
		local pos = frame:PointToObjectSpace(posW) * scale
		local eyeG = out.eye
		out.cluster = CFrame.lookAt(pos, pos + (pos - eyeG).Unit) -- back face looks at the driver
		local r = rm * scale
		-- full-width clusters (rev counter + two side screens) are about as wide as the wheel
		out.clusterSize = if ownDesign then Vector2.new(r * 2.3, r * 0.85) else Vector2.new(r * 1.7, r * 0.62)
	end

	-- the model's own gauge needles: turned live by Driving (speed / revs)
	local gaugeOf: { [BasePart]: boolean } = {}
	if out.eye then
		local function kindOf(d: Instance): string?
			local a: Instance? = d.Parent
			while a and a ~= src do
				local n = a.Name:lower()
				if n == "spdn" or n == "tacn" then
					return nil -- tick marks, not needles
				end
				if n:find("speed") or n:find("spd") then
					return "speed"
				end
				if n:find("tach") or n:find("tac") or n:find("rpm") then
					return "rpm"
				end
				a = a.Parent
			end
			local n = d.Name:lower()
			return if n:find("speed") then "speed" elseif n:find("rpm") or n:find("tach") then "rpm" else nil
		end
		local gauges = {}
		local pivots: { { pos: Vector3, kind: string } } = {}
		for _, d in visible do
			local n = d.Name:lower()
			if not inWheel[d] and not inSteer(d) and (n:find("needle") or n:find("arrow")) and not n:find("blinker") then
				local kind = kindOf(d)
				-- one needle per dial: a second piece of the same dial only hides
				local dup = false
				if kind then
					for _, pv in pivots do
						if pv.kind == kind and (pv.pos - d.Position).Magnitude < 0.5 then
							dup = true
						end
					end
				end
				if dup or (kind and CarSkin.CLUSTER_STYLE[src.Name]) then
					gaugeOf[d] = true
				elseif kind then
					-- turns about the small hub part next to it, else about itself
					local pivotPos = d.Position
					for _, sib in (d.Parent :: Instance):GetChildren() do
						if sib ~= d and sib:IsA("BasePart") and not sib.Name:lower():find("needle") and (sib.Position - d.Position).Magnitude < 0.6 then
							pivotPos = sib.Position
							break
						end
					end
					table.insert(pivots, { pos = pivotPos, kind = kind })
					local pv = frame:PointToObjectSpace(pivotPos) * scale
					local eyeG = out.eye :: Vector3
					local pivot = CFrame.lookAt(pv, pv + (pv - eyeG).Unit) -- +Z looks at the driver
					-- a slim red needle from the hub, pointing where the model's needle rests
					local tip = pivot:PointToObjectSpace(frame:PointToObjectSpace(d.Position) * scale)
					local rest = Vector3.new(tip.X, tip.Y, 0)
					local len: number
					if rest.Magnitude > 0.02 then
						len = rest.Magnitude * 2
						rest = rest.Unit
					else
						len = math.max(d.Size.X, d.Size.Y, d.Size.Z) * scale
						rest = Vector3.new(-0.7, -0.7, 0).Unit -- needle at rest: about 7 o'clock
					end
					len = math.clamp(len, 0.2, 0.6) * (CarSkin.NEEDLE_LENGTH[src.Name] or 1)
					-- a thin red line (no neon glow: it made the needle look thick)
					local needle = Instance.new("Part")
					needle.Size = Vector3.new(0.016, 0.016, len)
					needle.Color = Color3.fromRGB(235, 30, 30)
					needle.Material = Enum.Material.SmoothPlastic
					needle.CanCollide = false
					needle.CanQuery = false
					needle.CanTouch = false
					needle.Massless = true
					needle.CastShadow = false
					local offset = CFrame.lookAt(rest * len / 2 + Vector3.new(0, 0, 0.01), rest * len + Vector3.new(0, 0, 0.01))
					gaugeOf[d] = true
					table.insert(gauges, { kind = kind, pivot = pivot, parts = { { part = needle, offset = offset } } })
				end
			end
		end
		-- the model's own static needles next to a dial we drive (e.g. "Gauge Arrows") are hidden
		for _, d in visible do
			local n = d.Name:lower()
			if not gaugeOf[d] and (n:find("needle") or n:find("arrow")) and not n:find("blinker") then
				for _, pv in pivots do
					if (pv.pos - d.Position).Magnitude < 0.6 then
						gaugeOf[d] = true
						break
					end
				end
			end
		end
		out.gauges = gauges
		out.ownGauges = #gauges > 0
		for _, d in visible do
			local gui = d:FindFirstChildWhichIsA("SurfaceGui")
			if gui and gui:FindFirstChild("Needle", true) then
				out.ownGauges = true
				break
			end
		end
	end

	-- every rough surface becomes smooth: Roblox's Sand / Fabric / Leather / Concrete etc. carry a
	-- bumpy pattern that makes interiors look grainy up close
	local ROUGH = {
		Sand = true, Fabric = true, Leather = true, Concrete = true, Granite = true, Slate = true,
		Cobblestone = true, Pebble = true, Brick = true, Wood = true, WoodPlanks = true, Marble = true,
		CorrodedMetal = true, DiamondPlate = true, Foil = true, Plastic = true, Rubber = true, Asphalt = true,
		Basalt = true, Rock = true, Ground = true,
	}
	local function cabinMaterial(d: BasePart, p: BasePart)
		if ROUGH[d.Material.Name] then
			p.Material = Enum.Material.SmoothPlastic
			p:SetAttribute("Trim", true) -- upholstery-like: a cabin swap can take out bigger pieces of it
		end
	end

	local k = 0
	local redParts: { { d: BasePart, t: Template } } = {}
	for _, d in visible do
		if not inWheel[d] and not (out.steer and inSteer(d)) and not gaugeOf[d] then
			k += 1
			local t = tmpl(d, Vector3.zero)
			t.part:SetAttribute("SrcName", d.Name) -- on-screen gauges are found by these names
			cabinMaterial(d, t.part)
			if d.Name:sub(1, 10) == "SeeThrough" then
				-- windows of a converted Sketchfab model: an import can make the glass solid
				t.part.Transparency = math.max(t.part.Transparency, 0.6)
			end
			out.body["Part" .. k] = t
			if isTail(d) then
				local sh = tmpl(d, Vector3.zero)
				tailShell(sh.part, 1.012, 0.45)
				out.body["Tail" .. k] = sh
			elseif not d:IsA("MeshPart") or not hasTexture(d :: MeshPart) then
				-- plain red parts at the back may be the lamps of a car with nothing named (below)
				local c = d.Color
				if c.R > 0.45 and c.R > c.G * 2.2 and c.R > c.B * 2.2 and d.Transparency < 0.6 then
					table.insert(redParts, { d = d, t = t })
				end
			end
		end
	end
	for i, d in lampGlows do
		local sh = tmpl(d, Vector3.zero)
		tailShell(sh.part, 1, 0.3)
		out.body["TailGlow" .. i] = sh
	end
	if tails and tails.wb then
		local spm = dims.wb / tails.wb
		for i, spot in tails.spots do
			local face = spot.face.Unit
			local pos = Vector3.new(spot.at.X * spm, spot.at.Y * spm + modelR * scale, spot.at.Z * spm) + face * 0.006 * spm
			local p = Instance.new("Part")
			p.Name = "TailSpot"
			p.Size = Vector3.new(spot.w * spm, spot.h * spm, 0.02)
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			tailShell(p, 1, 0.3)
			local up = if math.abs(face.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
			out.body["TailSpot" .. i] = { part = p, offset = CFrame.lookAt(pos, pos + face, up) }
		end
	end
	-- the red glow behind the lamps: level with them, just behind the car
	do
		local back, ySum, n = -math.huge, 0, 0
		for name, t in out.body do
			local ocf = t.offset
			local h = t.part.Size / 2
			local ext = math.abs(ocf.RightVector.Z) * h.X + math.abs(ocf.UpVector.Z) * h.Y + math.abs(ocf.LookVector.Z) * h.Z
			back = math.max(back, ocf.Position.Z + ext)
			if t.part:GetAttribute("TailLight") then
				ySum += ocf.Position.Y
				n += 1
			end
		end
		-- nothing named or measured: plain red parts in the last sixth of the car, above the axles
		if n == 0 and back > -math.huge then
			local front = math.huge
			for _, t in out.body do
				front = math.min(front, t.offset.Position.Z)
			end
			local len = back - front
			for i, rp in redParts do
				local o = rp.t.offset.Position
				local sz = rp.t.part.Size
				if o.Z > back - len / 6 and o.Y > dims.wheelR * 0.9 and math.max(sz.X, sz.Y, sz.Z) < 2.4 then
					local sh = tmpl(rp.d, Vector3.zero)
					tailShell(sh.part, 1.012, 0.45)
					out.body["TailRed" .. i] = sh
					ySum += o.Y
					n += 1
				end
			end
		end
		if back > -math.huge then
			out.tailGlow = Vector3.new(0, if n > 0 then ySum / n else dims.wheelR * 1.6, back + 0.8)
		end
	end
	local generic = out.generic :: { [string]: GenericWheel }
	for _, g in groups do
		local c = frame:PointToObjectSpace(g.center) * scale
		local key = (if c.Z < 0 then "F" else "R") .. (if c.X < 0 then "L" else "R")
		local parts = {}
		-- our converted cars: "<corner>_static_*" pieces (calipers) steer with the wheel but don't spin
		local fixed = {}
		for _, d in g.parts do
			table.insert(if d.Name:lower():find("_static_", 1, true) then fixed else parts, tmpl(d, c))
		end
		-- the maker's logo on the wheel's centre cap: covered (our emblem for the brands with one)
		local cap = marks and marks.caps[key]
		if marks and cap then
			local spm = dims.wb / marks.wb
			local side = if c.X < 0 then -1 else 1
			local pos = Vector3.new(side * (cap.surface + 0.003) * spm, 0, 0)
			local look = Vector3.new(side, 0, 0)
			for _, t in coverParts(CFrame.lookAt(pos, pos + look), cap.r * 2 * spm, cap.r * 2 * spm, cap.color, true, marks.brand) do
				table.insert(parts, t)
			end
		end
		generic[key] = { x = c.X, parts = parts, fixed = if #fixed > 0 then fixed else nil }
	end
	-- logos printed on the paint or a plate: covered in the colour round them, or with our emblem
	if marks then
		local spm = dims.wb / marks.wb
		local n = 0
		for _, cv in marks.covers do
			local face = cv.face.Unit
			-- (the frame's origin is on the ground, the measures from the wheel centres' height)
			local pos = Vector3.new(cv.at.X * spm, cv.at.Y * spm + modelR * scale, cv.at.Z * spm) + face * 0.003 * spm
			local up = if math.abs(face.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
			for _, t in coverParts(CFrame.lookAt(pos, pos + face, up), cv.w * spm, cv.h * spm, cv.color, cv.disc, if cv.emblem then marks.brand else nil) do
				n += 1
				out.body["Mark" .. n] = t
			end
		end
	end
	return out
end

-- cabin parts: inside the body around the driver, not glass, and not a whole-body shell (big
-- upholstered shells narrower than the body are the old cabin's lining and seats: they go too)
local function inCabin(t: Template, eye: Vector3, halfW: number, rear: number): boolean
	local p, s = t.offset.Position, t.part.Size
	if t.part.Transparency >= 0.3 or t.part.Material == Enum.Material.Glass then
		return false
	end
	if math.max(s.X, s.Y, s.Z) > 9 then
		local cf = t.offset
		local width = math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z
		if not (t.part:GetAttribute("Trim") and width <= halfW * 2.64 and math.max(s.X, s.Y, s.Z) <= 12) then
			return false
		end
	end
	return math.abs(p.X) < halfW and p.Z > eye.Z - 3.4 and p.Z < eye.Z + rear and p.Y > 0.3 and p.Y < eye.Y + 0.4
end

local function cabinHalfWidth(out: Imported): number
	local w = math.huge
	local generic = out.generic
	if generic then
		for _, g in generic do
			w = math.min(w, math.abs(g.x))
		end
	end
	return if w < math.huge then w * 0.85 else 2
end

function transplantInterior(out: Imported, donor: Imported, rear: number)
	local eye, deye = out.eye, donor.eye
	if not (eye and deye) then
		error("no driver's seat to line the cabins up on")
	end
	local halfW = math.min(cabinHalfWidth(out), cabinHalfWidth(donor))
	-- lined up on the eye's height and seat position; sideways the donor's own layout is kept
	-- (both are centred on the car), and the camera moves to its driver's seat
	local shift = CFrame.new(0, eye.Y - deye.Y, eye.Z - deye.Z)
	out.eye = Vector3.new(deye.X, eye.Y, eye.Z)
	local body: { [string]: Template } = {}
	for name, t in out.body do
		if not inCabin(t, eye, halfW, rear) then
			body[name] = t
		end
	end
	local k = 0
	for _, t in donor.body do
		if inCabin(t, deye, halfW, rear) then
			k += 1
			body["Cabin" .. k] = { part = t.part, offset = shift * t.offset }
		end
	end
	out.body = body
	out.steer = if donor.steer then { mount = shift * donor.steer.mount, parts = donor.steer.parts, radius = donor.steer.radius } else nil
	local gauges = {}
	if donor.gauges then
		for _, gauge in donor.gauges do
			table.insert(gauges, { kind = gauge.kind, pivot = shift * gauge.pivot, parts = gauge.parts })
		end
	end
	out.gauges = gauges
	out.ownGauges = donor.ownGauges
	out.cluster = if donor.cluster then shift * donor.cluster else nil
	out.clusterSize = donor.clusterSize
end

local function importedFor(id: string): Imported?
	local cached = importCache[id]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CarModels", true) -- anywhere in ReplicatedStorage
	local alias = CarBuilder.MODEL_ALIAS[id]
	local src = if folder then folder:FindFirstChild(id, true) or (if alias then folder:FindFirstChild(alias, true) else nil) else nil
	local result: Imported? = nil
	if src then
		local ok, res = pcall(readImported, src)
		if ok then
			result = res
		else
			warn("[CityLegends] CarModels/" .. id .. " could not be used:", res)
		end
	end
	importCache[id] = result or false
	return result
end

-- Build the meshes ahead of time (loading screen): every traffic design plus the given full ones
function CarSkin.preload(fullIds: { string }?)
	-- lite meshes only for the cars traffic uses (all 55 would exceed the mesh memory budget)
	for _, id in CarBuilder.TRAFFIC_POOL do
		local spec = Cars.get(id)
		bodyFor(spec.Id, spec.Class, true)
		task.wait()
	end
	-- read every imported model in the background, so opening one in the garage doesn't hitch
	task.spawn(function()
		for _, spec in Cars.List do
			importedFor(spec.Id)
			task.wait(0.05)
		end
	end)
	local full: { string } = fullIds or {}
	for _, id in full do
		local spec = Cars.get(id)
		if not importedFor(spec.Id) then
			bodyFor(spec.Id, spec.Class, false)
			task.wait()
		end
	end
end

-- The knuckle joint for a wheel joint (steer only), if the car is skinned
function CarSkin.knuckleFor(wheelMotor: Motor6D): Motor6D?
	local root = wheelMotor.Part0
	if not root then
		return nil
	end
	return root:FindFirstChild("Knuckle_" .. wheelMotor.Name:sub(7)) :: Motor6D?
end

local function place(t: Template, name: string, look: Look, color: Color3, cf: CFrame, weldTo: BasePart, parent: Instance, scale: number?): MeshPart
	local p = t.part:Clone()
	local k = scale or 1
	p.Name = name
	p.Material = look.material
	p.Color = look.color or color
	p.Reflectance = look.reflectance
	p.Transparency = look.transparency
	p.CastShadow = look.shadow
	if k ~= 1 then
		p.Size *= k
		p.CFrame = cf * CFrame.new(t.offset.Position * k) * t.offset.Rotation
	else
		p.CFrame = cf * t.offset
	end
	p.Parent = parent
	local w = Instance.new("WeldConstraint")
	w.Part0 = weldTo
	w.Part1 = p
	w.Parent = p
	return p
end

--[[
	destroyReplaced: true for local-only models (traffic, cutscene, garage
	preview) - the old bodywork is deleted. For replicated player cars it is
	hidden with LocalTransparencyModifier instead.
	lite: lighter meshes (traffic)
]]
local DEFAULT_LOOK = {
	r = 115, face = Color3.fromRGB(12, 12, 14), bezel = Color3.fromRGB(170, 174, 184), bezelW = 4, tick = Color3.fromRGB(235, 238, 245),
	tickR = 110, major = { 13, 3 }, minor = { 7, 1.5 }, minors = 1, num = Color3.fromRGB(240, 242, 248), numR = 84, size = 20,
	font = "GothamBold", step = 20, needle = Color3.fromRGB(235, 40, 30), needleW = 6, hub = Color3.fromRGB(24, 24, 26), hubR = 14,
}

-- our own dial over one of the car's dials, drawn like the real one (DialLooks: colours, numbers,
-- red zone, needle, logos), in canvas pixels where 100 is the needle length. Returns the canvas
-- radius in those pixels.
local function drawDialFace(sg: SurfaceGui, dl: DialSpec, look: { [string]: any }): number
	local pts: { { number } } = {}
	for v, a in string.gmatch(dl.scale, "(%-?[%d%.]+):(%-?[%d%.]+)") do
		table.insert(pts, { tonumber(v) :: number, tonumber(a) :: number })
	end
	local R = look.r + (look.bezelW or 0) + 4
	sg.CanvasSize = Vector2.new(2 * R, 2 * R)
	if #pts < 2 then
		return R
	end
	local function angleOf(v: number): number
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			if v <= b[1] or i == #pts - 1 then
				return a[2] + (b[2] - a[2]) * (v - a[1]) / (b[1] - a[1])
			end
		end
		return pts[#pts][2]
	end
	local function frame(z: number, color: Color3?): Frame
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = color or Color3.new()
		f.BackgroundTransparency = if color then 0 else 1
		f.ZIndex = z
		f.Parent = sg
		return f
	end
	local function circle(x: number, y: number, r: number, fill: Color3?, stroke: Color3?, w: number?, z: number)
		local f = frame(z, fill)
		f.Position = UDim2.fromOffset(R + x, R + y)
		f.Size = UDim2.fromOffset(2 * r, 2 * r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		if stroke then
			local st = Instance.new("UIStroke")
			st.Color = stroke
			st.Thickness = w or 2
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			st.Parent = f
		end
	end
	-- a bar along the radius at angle a (degrees clockwise from 12), from r0 to r1
	local function bar(a: number, r0: number, r1: number, w: number, color: Color3, z: number)
		local t = math.rad(a)
		local mid = (r0 + r1) / 2
		local f = frame(z, color)
		f.Position = UDim2.fromOffset(R + mid * math.sin(t), R - mid * math.cos(t))
		f.Size = UDim2.fromOffset(w, r1 - r0)
		f.Rotation = a
	end
	local function text(t: string, x: number, y: number, size: number, color: Color3, font: string?, z: number)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromOffset(R + x, R + y)
		l.Size = UDim2.fromOffset(math.max(40, size * #t), size + 6)
		local okFont, f = pcall(function()
			return (Enum.Font :: any)[font or "GothamMedium"]
		end)
		l.Font = if okFont and f then f else Enum.Font.GothamMedium
		l.TextSize = size
		l.TextColor3 = color
		l.Text = t
		l.ZIndex = z
		l.Parent = sg
	end
	-- numbers never touch: at most the gap to their neighbour along the arc
	local function fitSize(size: number, r: number, vals: { number }, labels: { string }, toMain: (number) -> number): number
		local gap, chars = math.huge, 1
		for i, v in vals do
			chars = math.max(chars, #labels[i])
			if i > 1 then
				gap = math.min(gap, math.abs(angleOf(toMain(v)) - angleOf(toMain(vals[i - 1]))) * math.pi / 180 * r)
			end
		end
		return if gap < math.huge then math.min(size, gap * 0.92 / (0.62 * chars)) else size
	end
	local top = pts[#pts][1]
	if look.bezelW then
		circle(0, 0, look.r + look.bezelW, look.bezel, nil, nil, 1)
	end
	circle(0, 0, look.r, look.face, nil, nil, 2)
	if look.inner then
		circle(0, 0, look.innerR, look.inner, nil, nil, 3)
	end
	for _, l in look.lines or {} do
		circle(0, 0, l.r, nil, l.c, l.w, 4)
	end
	for _, c in look.circles or {} do
		circle(c.x, c.y, c.r, c.fill, c.stroke, c.w, 4)
	end
	for _, b in look.bands or {} do
		local a0, a1 = angleOf(b.from), angleOf(b.to)
		local n = math.max(2, math.floor(math.abs(a1 - a0) / 3))
		for i = 0, n - 1 do
			local a = a0 + (a1 - a0) * (i + 0.5) / n
			bar(a, b.r - b.w / 2, b.r + b.w / 2, math.abs(a1 - a0) / n * math.pi / 180 * b.r + 1.5, b.c, 5)
		end
	end
	for _, rc in look.rects or {} do
		local f = frame(6, rc.c)
		f.Position = UDim2.fromOffset(R + rc.x, R + rc.y)
		f.Size = UDim2.fromOffset(rc.w, rc.h)
	end
	-- ticks and numbers
	local step = look.step
	local v0 = look.start or math.ceil(pts[1][1] / step) * step
	local vals, labels = {}, {}
	local v = v0
	while v <= top + 1e-6 do
		table.insert(vals, v)
		table.insert(labels, tostring(math.floor(v / (look.div or 1) + 0.5)))
		v += step
	end
	local size = fitSize(look.size, look.numR, vals, labels, function(x)
		return x
	end)
	local minors = look.minors or 1
	for i, val in vals do
		for k = 0, minors do
			local vv = val + step * k / (minors + 1)
			if vv <= top + 1e-6 and not (k > 0 and i == #vals and vv > val) then
				local major = k == 0
				local dims = if major then look.major else look.minor
				local red = look.red ~= nil and vv >= look.red
				bar(angleOf(vv), look.tickR - dims[1], look.tickR, dims[2], if red then look.redC or Color3.fromRGB(225, 35, 28) else look.tick, 6)
			end
		end
		local t = math.rad(angleOf(val))
		local red = look.numRed ~= nil and look.red ~= nil and val >= look.red
		text(labels[i], look.numR * math.sin(t), -look.numR * math.cos(t), size, if red then look.numRed else look.num, look.font, 7)
	end
	-- a second scale in another unit (km/h round the outside of a mph dial)
	local alt = look.alt
	if alt then
		local avals, alabels = {}, {}
		local av = alt.start or 0
		while av <= top * alt.mul + 1e-6 do
			table.insert(avals, av)
			table.insert(alabels, tostring(math.floor(av + 0.5)))
			av += alt.step
		end
		local function toMain(x: number): number
			return x / alt.mul
		end
		local asize = fitSize(alt.size, alt.numR, avals, alabels, toMain)
		for i, x in avals do
			local t = math.rad(angleOf(toMain(x)))
			text(alabels[i], alt.numR * math.sin(t), -alt.numR * math.cos(t), asize, alt.c, look.font, 7)
		end
	end
	for _, tx in look.texts or {} do
		text(tx.t, tx.x, tx.y, tx.size, tx.c, tx.font, 7)
	end
	return R
end

function CarSkin.apply(model: Model, destroyReplaced: boolean?, lite: boolean?): boolean
	if model:GetAttribute("Skinned") then
		return true
	end
	local rawId = model:GetAttribute("CarId")
	local class = model:GetAttribute("Class")
	local root = model.PrimaryPart
	if type(rawId) ~= "string" or type(class) ~= "string" or not root then
		return false
	end
	-- a trim on another car's model looks exactly like that car
	local id = Cars.modelOf(rawId)
	local liteMode = lite == true
	-- imported models first for the cars you look at; runtime lite meshes first for traffic
	local imported = if liteMode then nil else importedFor(id)
	local body = if imported then imported.body else bodyFor(id, class, liteMode)
	if not body then
		imported = importedFor(id)
		body = if imported then imported.body else nil
	end
	if not body then
		return false
	end
	local meta = if imported then { plate = imported.plate, exhausts = imported.exhausts } else bodyMeta[id .. (if liteMode then "/lite" else "")]
	local spec = Cars.get(id)
	local dims = CarBuilder.getDims(class, id)
	local design = CarMesh.design(id, class, dims :: any)
	local height = (model:GetAttribute("Height") :: number?) or dims.H
	local groundCF = root.CFrame * CFrame.new(0, -height / 2, 0)

	-- paint comes from the built car (traffic gets random colours)
	local paintSrc = model:FindFirstChild("DoorL") or model:FindFirstChild("Tail")
	local paint = if paintSrc and paintSrc:IsA("BasePart") then paintSrc.Color else spec.Color
	local accent = spec.Accent or Color3.fromRGB(18, 18, 20)

	local skin = Instance.new("Model")
	skin.Name = "Skin"
	skin.Parent = model
	local drl = if design.drl then Color3.fromRGB(design.drl[1], design.drl[2], design.drl[3]) else Color3.new(1, 1, 1)
	local generic = if imported then imported.generic else nil
	for name, t in body do
		if generic then
			local p = t.part:Clone()
			p.Name = "Skin" .. name
			p.CFrame = groundCF * t.offset
			p.Parent = skin
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			continue
		end
		local base = name:match("^%a+") or name -- "Paint2" is the second half of a big layer
		local look = LOOKS[base] or LOOKS.Paint
		local color = if base == "Accent" then accent elseif base == "Drl" then drl else paint
		local p = place(t, "Skin" .. name, look, color, groundCF, root, skin)
		if base == "Tail" then
			p:SetAttribute("TailLight", true)
		end
	end

	if generic and imported and imported.tailGlow and not liteMode then
		-- a soft red glow on the road and bumper behind the tail lamps (brighter when braking)
		local att = Instance.new("Attachment")
		att.Name = "RearGlow"
		att.Position = root.CFrame:PointToObjectSpace((groundCF * CFrame.new(imported.tailGlow)).Position)
		att.Parent = root
		local glow = Instance.new("PointLight")
		glow.Name = "RearGlow"
		glow.Color = Color3.fromRGB(255, 30, 20)
		glow.Brightness = 0.6
		glow.Range = 9
		glow.Shadows = false
		glow.Parent = att
	end
	if generic and imported then
		-- the model's own steering wheel: welded still here; Driving turns it on the local player's car
		local steer = imported.steer
		local eyeRoot = if imported.eye then imported.eye - Vector3.new(0, height / 2, 0) else nil
		if steer then
			local mountRoot = root.CFrame:Inverse() * groundCF * steer.mount
			model:SetAttribute("SteerMount", mountRoot)
			for i, t in steer.parts do
				local p = t.part:Clone()
				p.Name = "SkinSteer" .. i
				p.CFrame = groundCF * steer.mount * t.offset
				p:SetAttribute("SteerOffset", t.offset)
				p.Parent = skin
				local w = Instance.new("Weld")
				w.Part0 = root
				w.Part1 = p
				w.C0 = mountRoot * t.offset
				w.Parent = p
			end
			-- where Driving's arms grip (10 and 2) and where the shoulders sit
			if eyeRoot then
				local r = steer.radius
				model:SetAttribute("SteerRadius", r)
				for side, ang in { L = math.rad(160), R = math.rad(20) } do
					local sx = if side == "L" then -1 else 1
					model:SetAttribute("Grip" .. side, Vector3.new(r * 0.9 * math.cos(ang), r * 0.9 * math.sin(ang), 0.24))
					model:SetAttribute("Shoulder" .. side, eyeRoot + Vector3.new(sx * 0.62, -0.7, 0.43))
				end
				model:SetAttribute("ArmsFitted", true)
			end
		end
		-- the model's own needles: welded still here; Driving turns them on the local player's car
		for gi, gauge in imported.gauges or {} do
			local pivotRoot = root.CFrame:Inverse() * groundCF * gauge.pivot
			for i, t in gauge.parts do
				local p = t.part:Clone()
				p.Name = "SkinGauge" .. gi .. "_" .. i
				p.CFrame = groundCF * gauge.pivot * t.offset
				p:SetAttribute("GaugeKind", gauge.kind)
				p:SetAttribute("GaugePivot", pivotRoot)
				p:SetAttribute("GaugeOffset", t.offset)
				p.Parent = skin
				local w = Instance.new("Weld")
				w.Part0 = root
				w.Part1 = p
				w.C0 = pivotRoot * t.offset
				w.Parent = p
			end
		end
		-- live instrument cluster on the car's own gauge spot, when it has no working gauges of its own
		-- (cars with their own design here, like the Ferrari, always get it)
		local ownDesign = CarSkin.CLUSTER_STYLE[id] ~= nil
		-- a car with another model's cabin uses that cabin's dials and cluster spot
		local swap = CarSkin.INTERIOR_DONOR[id]
		local cabinId = if swap then swap.from else id
		local dials = CarSkin.DIAL_NEEDLES[cabinId]
		local rect = CarSkin.CLUSTER_RECT[id] or CarSkin.CLUSTER_RECT[cabinId]
		if (rect or (imported.cluster and imported.clusterSize)) and not liteMode and not dials and (ownDesign or not imported.ownGauges) then
			local cluster = Instance.new("Part")
			cluster.Name = "DashCluster"
			local cs = imported.clusterSize or Vector2.new(1, 0.4)
			cluster.Size = Vector3.new(cs.X, cs.Y, 0.02)
			cluster.Transparency = 1
			cluster.CanCollide = false
			cluster.CanQuery = false
			cluster.CanTouch = false
			cluster.Massless = true
			cluster.CastShadow = false
			-- per-car nudges set in Studio on the model: ClusterUp / ClusterForward (studs), ClusterSize (x)
			local src = (ReplicatedStorage:FindFirstChild("CarModels", true) :: Instance):FindFirstChild(id, true)
			local up = if src then (src:GetAttribute("ClusterUp") :: number?) or 0 else 0
			local fwd = if src then (src:GetAttribute("ClusterForward") :: number?) or 0 else 0
			local k = if src then (src:GetAttribute("ClusterSize") :: number?) or 1 else 1
			cluster.Size = Vector3.new(cluster.Size.X * k, cluster.Size.Y * k, cluster.Size.Z)
			if rect and imported.steer then
				-- right over the car's own cluster screen, just in front of it
				local m = CarBuilder.STUDS_PER_METRE
				local face = rect.face.Unit
				local upV = (Vector3.yAxis - face * face.Y).Unit
				local pos = imported.steer.mount.Position + rect.at * m + face * 0.004 * m
				cluster.Size = Vector3.new(rect.w * m * k, rect.h * m * k, 0.02)
				cluster.CFrame = groundCF * CFrame.lookAt(pos, pos - face, upV) * CFrame.new(0, up, -fwd) -- back face looks at the driver
				cluster:SetAttribute("Placed", true) -- Driving leaves it where it is
			else
				cluster.CFrame = groundCF * (imported.cluster :: CFrame) * CFrame.new(0, up, -fwd)
			end
			cluster.Parent = skin
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = cluster
			w.Parent = cluster
			cluster:SetAttribute("Style", CarSkin.CLUSTER_STYLE[id] or (if id:sub(1, 8) == "lambrini" then "Lambo" else "Modern"))
			if ownDesign then
				model:SetAttribute("OwnCluster", true) -- the model's own gauge screens stay off
			end
		end
		-- our own dial over each of the car's dials (owner: "create your own cluster and replace that
		-- old cluster"): a solid face with the car's scale, numbers and a red needle, so the old needle
		-- and any washed-out print are covered (Driving turns the needles)
		if dials and imported.steer and not liteMode then
			local m = CarBuilder.STUDS_PER_METRE
			for i, dl in dials do
				local face = dl.face.Unit
				local up = (Vector3.yAxis - face * face.Y).Unit
				local digits = dl.kind == "digits"
				local pos = imported.steer.mount.Position + dl.at * m + face * (if digits then 0.004 else 0.002) * m
				local size = if digits then dl.length * m else dl.length * 2.3 * m
				local p = Instance.new("Part")
				p.Name = "DialPanel" .. i
				p.Size = if digits then Vector3.new(size, size * 0.45, 0.01) else Vector3.new(size, size, 0.01)
				p.Transparency = 1
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Massless = true
				p.CastShadow = false
				p.CFrame = groundCF * CFrame.lookAt(pos, pos - face, up) -- back face looks at the driver
				p.Parent = skin
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = p
				w.Parent = p
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Back
				sg.LightInfluence = 1
				sg.MaxDistance = 40
				sg.Parent = p
				if digits then
					-- the speed in the dial's own unit, like the car's display (Driving fills it in), on
					-- a dark plate over the fixed number
					sg.CanvasSize = Vector2.new(200, 90)
					local label = Instance.new("TextLabel")
					label.Name = "Speed"
					label.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
					label.BackgroundTransparency = 0
					label.BorderSizePixel = 0
					label.Size = UDim2.fromScale(1, 1)
					label.Font = Enum.Font.GothamBold
					label.TextScaled = true
					label.TextColor3 = Color3.fromRGB(235, 240, 255)
					label.TextXAlignment = Enum.TextXAlignment.Right
					label.Text = "0"
					label:SetAttribute("GaugeUnit", dl.unit)
					label.Parent = sg
					continue
				end
				-- our dial, drawn like the real one; the panel grows to the dial's size (100 px = one
				-- needle length)
				local look = DialLooks[cabinId] and DialLooks[cabinId][i] or nil
				if type(look) ~= "table" then
					look = DEFAULT_LOOK
				end
				local R = drawDialFace(sg, dl, look :: any)
				local side = 2 * R / 100 * dl.length * m
				p.Size = Vector3.new(side, side, 0.01)
				-- the needle turns about its own middle, which sits on the hub: it runs 100 px up to
				-- the tip, and of the lower half only a 22 px tail shows
				local needle = Instance.new("Frame")
				needle.Name = "DialNeedle"
				needle.BorderSizePixel = 0
				needle.BackgroundColor3 = look.needle
				needle.AnchorPoint = Vector2.new(0.5, 0.5)
				needle.Position = UDim2.fromScale(0.5, 0.5)
				needle.Size = UDim2.fromOffset(look.needleW or 6, 200)
				needle.Rotation = -125
				needle.ZIndex = 8
				needle:SetAttribute("GaugeKind", dl.kind)
				needle:SetAttribute("GaugeUnit", dl.unit)
				needle:SetAttribute("GaugeScale", dl.scale)
				needle.Parent = sg
				local fade = Instance.new("UIGradient")
				fade.Rotation = 90 -- top to bottom
				fade.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.61, 0),
					NumberSequenceKeypoint.new(0.615, 1),
					NumberSequenceKeypoint.new(1, 1),
				})
				fade.Parent = needle
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.5, 0)
				corner.Parent = needle
				local hubR = look.hubR or 14
				for k, c in { look.hubRing or false, look.hub or Color3.fromRGB(24, 24, 26) } do
					if c then
						local cap = Instance.new("Frame")
						cap.BorderSizePixel = 0
						cap.BackgroundColor3 = c
						cap.AnchorPoint = Vector2.new(0.5, 0.5)
						cap.Position = UDim2.fromScale(0.5, 0.5)
						local r = if k == 1 then hubR + 3 else hubR
						cap.Size = UDim2.fromOffset(2 * r, 2 * r)
						cap.ZIndex = 8 + k
						cap.Parent = sg
						local round = Instance.new("UICorner")
						round.CornerRadius = UDim.new(0.5, 0)
						round.Parent = cap
					end
				end
			end
		end
		-- the camera sits at the model's own driver's seat
		if imported.eye then
			model:SetAttribute("Eye", imported.eye - Vector3.new(0, height / 2, 0))
		end
		-- the model has its own cabin: ours (dash, seats, wheel, driver, arms) is hidden below
		model:SetAttribute("OwnInterior", true)
	end

	-- licence plate text (the plate itself is part of the mesh)
	if meta and meta.plate and not liteMode then
		local plate = Instance.new("Part")
		plate.Name = "PlateText"
		plate.Size = Vector3.new(1.16, 0.36, 0.02)
		plate.Transparency = 1
		plate.CanCollide = false
		plate.CanQuery = false
		plate.CanTouch = false
		plate.Massless = true
		plate.CastShadow = false
		plate.CFrame = groundCF * (meta.plate :: CFrame) -- front face looks out of the car
		plate.Parent = skin
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = plate
		weld.Parent = plate
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(232, 72)
		sg.LightInfluence = 1
		sg.MaxDistance = 90
		sg.Parent = plate
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(20, 26, 60)
		local plateText = model:GetAttribute("Plate")
		text.Text = if type(plateText) == "string" then plateText else "CTYLGND"
		text.Parent = sg
	end

	-- exhaust tips in root space (Driving puts the backfire flames there)
	if meta and meta.exhausts then
		for i, p in meta.exhausts :: { Vector3 } do
			model:SetAttribute("Exhaust" .. i, p - Vector3.new(0, height / 2, 0))
		end
	end

	-- wheels
	local rim = Color3.fromRGB(design.rim[1], design.rim[2], design.rim[3])
	local caliper = Color3.fromRGB(design.caliper[1], design.caliper[2], design.caliper[3])
	for _, j in root:GetChildren() do
		if not (j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_") then
			continue
		end
		local tire = j.Part1
		if not tire then
			continue
		end
		local R = (j:GetAttribute("Radius") :: number?) or dims.wheelR
		local front = j:GetAttribute("Front") == true
		if generic then
			-- the model's own wheel for this corner, spinning with ours (kept at its own track width)
			local gw = generic[(if front then "F" else "R") .. (if j.C0.Position.X < 0 then "L" else "R")]
			if gw then
				local base = tire.CFrame * CFrame.new(gw.x - j.C0.Position.X, 0, 0)
				for i, t in gw.parts do
					local p = t.part:Clone()
					p.Name = "SkinWheel" .. i
					p.CFrame = base * t.offset
					p.Parent = skin
					local w = Instance.new("WeldConstraint")
					w.Part0 = tire
					w.Part1 = p
					w.Parent = p
				end
				local fixed = gw.fixed
				if fixed then
					-- calipers ride on a knuckle: it steers with the wheel (Driving turns the front
					-- ones) but doesn't spin
					local knuckle = Instance.new("Part")
					knuckle.Name = "Knuckle" .. j.Name:sub(6)
					knuckle.Size = Vector3.one * 0.2
					knuckle.Transparency = 1
					knuckle.CanCollide = false
					knuckle.CanQuery = false
					knuckle.CanTouch = false
					knuckle.Massless = true
					knuckle.CFrame = root.CFrame * j.C0
					knuckle.Parent = skin
					local km = Instance.new("Motor6D")
					km.Name = "Knuckle" .. j.Name:sub(6)
					km.Part0 = root
					km.Part1 = knuckle
					km.C0 = j.C0
					km.Parent = root
					for i, t in fixed do
						local p = t.part:Clone()
						p.Name = "SkinCaliper" .. i
						p.CFrame = base * t.offset
						p.Parent = skin
						local w = Instance.new("WeldConstraint")
						w.Part0 = knuckle
						w.Part1 = p
						w.Parent = p
					end
				end
			end
			continue
		end
		-- imported wheels were exported at the front radius: scale to this one
		local wheel = if imported and next(imported.wheel) then imported.wheel else wheelFor(design.wheel, R, dims.wheelW, design.rimFrac, liteMode)
		local wheelScale = if imported and wheel == imported.wheel then R / dims.wheelR else 1
		if not wheel then
			break
		end
		local rest = root.CFrame * j.C0
		local left = j.C0.Position.X < 0
		local turn = if left then CFrame.Angles(0, math.pi, 0) else CFrame.new()
		local spinCF = tire.CFrame * turn
		-- knuckle: follows steering only, carries the caliper
		local knuckle = Instance.new("Part")
		knuckle.Name = "Knuckle" .. j.Name:sub(6)
		knuckle.Size = Vector3.one * 0.2
		knuckle.Transparency = 1
		knuckle.CanCollide = false
		knuckle.CanQuery = false
		knuckle.CanTouch = false
		knuckle.Massless = true
		knuckle.CFrame = rest
		knuckle.Parent = skin
		local km = Instance.new("Motor6D")
		km.Name = "Knuckle" .. j.Name:sub(6)
		km.Part0 = root
		km.Part1 = knuckle
		km.C0 = j.C0
		km.Parent = root
		for name, t in wheel do
			local base = name:match("^%a+") or name
			local look = LOOKS[base] or LOOKS.Rim
			if base == "Caliper" then
				-- sit the caliper towards the middle of the car
				local towards = (if front then 1 else -1) * (if left then -1 else 1)
				local cf = rest * turn * (if towards < 0 then CFrame.Angles(math.rad(-86), 0, 0) else CFrame.new())
				place(t, "SkinCaliper", look, caliper, cf, knuckle, skin, wheelScale)
			else
				place(t, "Skin" .. name, look, if base == "Rim" then rim else look.color or rim, spinCF, tire, skin, wheelScale)
			end
		end
	end

	-- hide the part bodywork (and, under an imported model, our whole cabin)
	local ownInterior = generic ~= nil
	local function hide(d: Instance)
		if not d:IsA("BasePart") or d == root or d:IsDescendantOf(skin) or d.Name == "Underglow" then
			return
		end
		if not (d:GetAttribute("Ext") or ownInterior) then
			return
		end
		if ownInterior then
			-- screens drawn on our hidden dash (old cluster, infotainment) go too, and the hidden
			-- body's red tail glow: it shone into the model's cabin (pink mirrors, a red screen)
			for _, g in d:GetChildren() do
				if g:IsA("SurfaceGui") then
					g.Enabled = false
				elseif g:IsA("PointLight") and g.Name == "TailGlow" then
					g.Enabled = false
				end
			end
		end
		local isWheel = d.Name:sub(1, 5) == "Wheel" and d.Parent == model
		if destroyReplaced and d:GetAttribute("Ext") and not isWheel and not d:FindFirstChildWhichIsA("Light") then
			d:Destroy()
		elseif destroyReplaced or ownInterior then
			-- a local change: the server never touches these parts again, so it sticks
			d.Transparency = 1
		else
			d.LocalTransparencyModifier = 1
		end
	end
	for _, d in model:GetDescendants() do
		hide(d)
	end
	-- parts that replicate after the skin went on
	model.DescendantAdded:Connect(function(d)
		task.defer(function()
			if d:IsA("SurfaceGui") and d.Parent and d.Parent:IsA("BasePart") and not d:IsDescendantOf(skin) then
				hide(d.Parent)
			else
				hide(d)
			end
		end)
	end)
	model:SetAttribute("Skinned", true)
	return true
end

return CarSkin
