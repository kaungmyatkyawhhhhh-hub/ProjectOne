--[[
	Car roster. Names are fictional look-alikes of real cars so the game is safe to publish.

	Stats
	  TopSpeed   : mph
	  ZeroToSixty: seconds
	  Handling   : 0..1 (grip + steering response)
	  Price      : $ (0 = free starter)
]]

export type CarSpec = {
	Id: string,
	Name: string,
	Class: string,
	Tier: string, -- Starter, Mid or High
	TopSpeed: number,
	ZeroToSixty: number,
	Handling: number,
	Price: number,
	Color: Color3,
	Accent: Color3?,
	Order: number,
	Electric: boolean?, -- one gear, no engine sound
	Model: string?, -- uses another car's imported model (a trim without its own model yet)
}

local Cars = {}

Cars.Classes = { "Sedan", "Coupe", "SUV", "Supercar", "Hypercar" }

Cars.ClassLabels = {
	Sedan = "SEDAN",
	Coupe = "COUPE",
	SUV = "SUV",
	Supercar = "SUPERCAR",
	Hypercar = "HYPERCAR",
}

local list: { CarSpec } = {
	-- Starter cars (beginner)
	{ Id = "suzaki_swift", Name = "Suzaki Swiff", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 9.5, Handling = 0.62, Price = 0, Color = Color3.fromRGB(200, 30, 36), Order = 1 },
	{ Id = "toyoka_belta", Name = "Toyoka Belto", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 10.5, Handling = 0.55, Price = 6000, Color = Color3.fromRGB(196, 199, 204), Order = 2 },
	{ Id = "kio_ev6", Name = "Kio EV6", Class = "SUV", Tier = "Starter", TopSpeed = 93, ZeroToSixty = 9.5, Handling = 0.5, Price = 11000, Color = Color3.fromRGB(235, 236, 238), Order = 3, Electric = true },
	{ Id = "byt_seal", Name = "BYT Seal EV", Class = "Sedan", Tier = "Starter", TopSpeed = 100, ZeroToSixty = 7.3, Handling = 0.55, Price = 14000, Color = Color3.fromRGB(40, 90, 160), Order = 4, Electric = true },
	{ Id = "toyoka_camri", Name = "Toyoka Camri", Class = "Sedan", Tier = "Starter", TopSpeed = 135, ZeroToSixty = 7.6, Handling = 0.58, Price = 16000, Color = Color3.fromRGB(20, 21, 24), Order = 5 },
	{ Id = "toyoka_crown", Name = "Toyoka Crowne Athlete", Class = "Sedan", Tier = "Starter", TopSpeed = 143, ZeroToSixty = 6.9, Handling = 0.6, Price = 22000, Color = Color3.fromRGB(235, 236, 238), Order = 6 },
	{ Id = "toyoka_alfard", Name = "Toyoka Alfard", Class = "SUV", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 8.5, Handling = 0.45, Price = 28000, Color = Color3.fromRGB(20, 21, 24), Order = 7 },
	{ Id = "toyoka_lc200", Name = "Toyoka Land Cruzer 200", Class = "SUV", Tier = "Starter", TopSpeed = 130, ZeroToSixty = 6.9, Handling = 0.46, Price = 35000, Color = Color3.fromRGB(235, 236, 238), Order = 8 },
	{ Id = "nisun_350z", Name = "Nisun 350Z", Class = "Coupe", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.4, Handling = 0.72, Price = 38000, Color = Color3.fromRGB(220, 170, 30), Order = 9 },
	{ Id = "mazdo_rx7", Name = "Mazdo RX-7", Class = "Coupe", Tier = "Starter", TopSpeed = 156, ZeroToSixty = 5.0, Handling = 0.82, Price = 42000, Color = Color3.fromRGB(235, 236, 238), Order = 10 },
	{ Id = "mazdo_rx8", Name = "Mazdo RX-8", Class = "Coupe", Tier = "Starter", TopSpeed = 146, ZeroToSixty = 6.4, Handling = 0.8, Price = 45000, Color = Color3.fromRGB(190, 30, 35), Order = 11 },

	-- Mid tier
	{ Id = "bnw_530i", Name = "BNW 530i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.9, Handling = 0.66, Price = 52000, Color = Color3.fromRGB(20, 21, 24), Order = 12 },
	{ Id = "bnw_540i", Name = "BNW 540i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.7, Handling = 0.68, Price = 64000, Color = Color3.fromRGB(26, 44, 82), Order = 13 },
	{ Id = "bentz_e300", Name = "Mercer E300", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 6.1, Handling = 0.63, Price = 70000, Color = Color3.fromRGB(88, 92, 98), Order = 14 },
	{ Id = "bentz_e400", Name = "Mercer E400", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.9, Handling = 0.66, Price = 85000, Color = Color3.fromRGB(20, 21, 24), Order = 15 },
	{ Id = "bnw_330i_g20", Name = "BNW 330i M Sport", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.3, Handling = 0.7, Price = 60000, Color = Color3.fromRGB(40, 90, 160), Order = 16 },
	{ Id = "bnw_m3_e92", Name = "BNW M3 E92", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.6, Handling = 0.76, Price = 90000, Color = Color3.fromRGB(235, 236, 238), Order = 17 },
	{ Id = "bnw_m3_f80", Name = "BNW M3 F80", Class = "Sedan", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.0, Handling = 0.78, Price = 110000, Color = Color3.fromRGB(220, 170, 30), Order = 18 },
	{ Id = "bnw_m4_f82", Name = "BNW M4 F82", Class = "Coupe", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.1, Handling = 0.8, Price = 100000, Color = Color3.fromRGB(30, 80, 170), Order = 19 },
	{ Id = "bnw_m5_e60", Name = "BNW M5 E60 V10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.4, Handling = 0.72, Price = 125000, Color = Color3.fromRGB(165, 168, 172), Order = 20 },
	{ Id = "bnw_m6_v10", Name = "BNW M6 V10", Class = "Coupe", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.5, Handling = 0.73, Price = 135000, Color = Color3.fromRGB(26, 44, 82), Order = 21 },
	{ Id = "bnw_m8gc", Name = "BNW M8 Gran Coupe", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 3.0, Handling = 0.78, Price = 210000, Color = Color3.fromRGB(26, 44, 82), Order = 22 },
	{ Id = "bentz_cla45", Name = "Mercer CLA 45", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.0, Handling = 0.74, Price = 95000, Color = Color3.fromRGB(140, 145, 150), Order = 23 },
	{ Id = "bentz_cls63s", Name = "Mercer CLS 63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.6, Handling = 0.72, Price = 160000, Color = Color3.fromRGB(20, 21, 24), Order = 24 },
	{ Id = "toyoka_supra_mk4", Name = "Toyoka Supro MK4", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 4.6, Handling = 0.76, Price = 140000, Color = Color3.fromRGB(220, 100, 20), Order = 25 },
	{ Id = "nisun_r34", Name = "Nisun Skyline R34 GT-R", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.9, Handling = 0.8, Price = 180000, Color = Color3.fromRGB(40, 60, 150), Order = 26 },
	{ Id = "dodger_challenger", Name = "Dodger Challenjer", Class = "Coupe", Tier = "Mid", TopSpeed = 175, ZeroToSixty = 4.2, Handling = 0.66, Price = 115000, Color = Color3.fromRGB(176, 14, 18), Accent = Color3.fromRGB(16, 16, 18), Order = 27 },
	{ Id = "xiaomo_su7", Name = "Xiaomo SU7", Class = "Sedan", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 2.8, Handling = 0.78, Price = 120000, Color = Color3.fromRGB(40, 90, 160), Order = 28, Electric = true },
	{ Id = "bnw_x6", Name = "BNW X6 M Sport", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.2, Handling = 0.6, Price = 130000, Color = Color3.fromRGB(20, 21, 24), Order = 29 },
	{ Id = "bnw_x7", Name = "BNW X7", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.5, Handling = 0.56, Price = 175000, Color = Color3.fromRGB(235, 236, 238), Order = 30 },
	{ Id = "toyoka_lc300", Name = "Toyoka Land Cruzer 300", Class = "SUV", Tier = "Mid", TopSpeed = 130, ZeroToSixty = 6.5, Handling = 0.5, Price = 150000, Color = Color3.fromRGB(235, 236, 238), Order = 31 },
	{ Id = "lexis_lx700", Name = "Lexis LX700", Class = "SUV", Tier = "Mid", TopSpeed = 137, ZeroToSixty = 6.4, Handling = 0.5, Price = 245000, Color = Color3.fromRGB(12, 12, 14), Order = 32 },
	{ Id = "bentz_gle53", Name = "Mercer GLE 53", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.0, Handling = 0.62, Price = 250000, Color = Color3.fromRGB(165, 168, 172), Order = 33 },
	{ Id = "bentz_g63", Name = "Mercer G63", Class = "SUV", Tier = "Mid", TopSpeed = 149, ZeroToSixty = 4.4, Handling = 0.52, Price = 260000, Color = Color3.fromRGB(20, 21, 24), Order = 34 },
	{ Id = "byt_u8", Name = "BYT Yangwong U8", Class = "SUV", Tier = "Mid", TopSpeed = 124, ZeroToSixty = 3.6, Handling = 0.55, Price = 290000, Color = Color3.fromRGB(20, 21, 24), Order = 35, Electric = true },
	{ Id = "porsha_panamera", Name = "Porsha Panamera Turbo S", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.0, Handling = 0.8, Price = 300000, Color = Color3.fromRGB(88, 92, 98), Order = 36 },
	{ Id = "chevo_camaro", Name = "Chevo Camaro ZL1", Class = "Coupe", Tier = "Mid", TopSpeed = 184, ZeroToSixty = 3.9, Handling = 0.74, Price = 62000, Color = Color3.fromRGB(230, 180, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 37 },
	{ Id = "chevo_c6", Name = "Chevo Corvette C6", Class = "Coupe", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 4.2, Handling = 0.8, Price = 78000, Color = Color3.fromRGB(26, 44, 82), Order = 38 },
	{ Id = "porsha_boxster", Name = "Porsha Boxster 718", Class = "Coupe", Tier = "Mid", TopSpeed = 177, ZeroToSixty = 4.2, Handling = 0.9, Price = 92000, Color = Color3.fromRGB(200, 200, 206), Order = 39 },
	{ Id = "chevo_c7", Name = "Chevo Corvette C7", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 3.8, Handling = 0.84, Price = 112000, Color = Color3.fromRGB(200, 10, 20), Order = 40 },
	{ Id = "bentz_s63", Name = "Mercer S65 W222", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 3.9, Handling = 0.7, Price = 280000, Color = Color3.fromRGB(20, 21, 24), Order = 41 },
	{ Id = "bentz_gt63s", Name = "Dodger SRT", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.8, Price = 320000, Color = Color3.fromRGB(88, 92, 98), Order = 42 },

	-- High tier
	{ Id = "nisun_gtr", Name = "Nisun GT-R R35", Class = "Coupe", Tier = "High", TopSpeed = 196, ZeroToSixty = 2.9, Handling = 0.86, Price = 420000, Color = Color3.fromRGB(235, 236, 238), Order = 43 },
	{ Id = "astin_db9", Name = "Astin Marlin Vanquish", Class = "Coupe", Tier = "High", TopSpeed = 201, ZeroToSixty = 3.8, Handling = 0.76, Price = 450000, Color = Color3.fromRGB(26, 44, 82), Order = 44 },
	{ Id = "astin_vantage", Name = "Astin Marlin Vantage", Class = "Coupe", Tier = "High", TopSpeed = 195, ZeroToSixty = 3.5, Handling = 0.82, Price = 500000, Color = Color3.fromRGB(36, 70, 52), Order = 45 },
	{ Id = "ferrara_f430", Name = "Ferrara F430", Class = "Supercar", Tier = "High", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.86, Price = 600000, Color = Color3.fromRGB(200, 10, 20), Order = 46 },
	{ Id = "bentz_sl65bs", Name = "Mercer SL65 Black Series", Class = "Coupe", Tier = "High", TopSpeed = 199, ZeroToSixty = 3.8, Handling = 0.82, Price = 700000, Color = Color3.fromRGB(18, 18, 20), Order = 47 },
	{ Id = "lambrini_lp570", Name = "Lambrini Gallardo LP570-4 SL", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.88, Price = 750000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 48 },
	{ Id = "audy_r8", Name = "Audy R8 Type 42", Class = "Supercar", Tier = "High", TopSpeed = 188, ZeroToSixty = 4.4, Handling = 0.86, Price = 550000, Color = Color3.fromRGB(165, 168, 172), Accent = Color3.fromRGB(16, 16, 18), Order = 49 },
	{ Id = "mclaran_12c", Name = "McLaran MP4-12C", Class = "Supercar", Tier = "High", TopSpeed = 207, ZeroToSixty = 3.1, Handling = 0.9, Price = 800000, Color = Color3.fromRGB(226, 84, 8), Order = 50 },
	{ Id = "ferrara_599", Name = "Ferrara 599", Class = "Supercar", Tier = "High", TopSpeed = 205, ZeroToSixty = 3.5, Handling = 0.84, Price = 850000, Color = Color3.fromRGB(20, 21, 24), Order = 51 },
	{ Id = "ferrara_458", Name = "Ferrara 458 Itala", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.9, Price = 900000, Color = Color3.fromRGB(200, 10, 20), Order = 52 },
	{ Id = "bentz_sls", Name = "Mercer SLS", Class = "Supercar", Tier = "High", TopSpeed = 197, ZeroToSixty = 3.7, Handling = 0.86, Price = 950000, Color = Color3.fromRGB(235, 236, 238), Order = 53 },
	{ Id = "porsha_gt3", Name = "Porsha 911 GT3 991.2", Class = "Supercar", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.2, Handling = 0.95, Price = 1000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 54 },
	{ Id = "bentlee_contgt", Name = "Bentlee Continental GT", Class = "Coupe", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.6, Handling = 0.74, Price = 1100000, Color = Color3.fromRGB(26, 44, 82), Order = 55 },
	{ Id = "bentlee_bentayga", Name = "Bentlee Bentayga", Class = "SUV", Tier = "High", TopSpeed = 187, ZeroToSixty = 4.0, Handling = 0.6, Price = 1200000, Color = Color3.fromRGB(20, 21, 24), Order = 56 },
	{ Id = "lambrini_urus", Name = "Lambrini Urus", Class = "SUV", Tier = "High", TopSpeed = 190, ZeroToSixty = 3.5, Handling = 0.7, Price = 1500000, Color = Color3.fromRGB(220, 170, 30), Order = 57 },
	{ Id = "brabos_g63", Name = "Brabos G63", Class = "SUV", Tier = "High", TopSpeed = 149, ZeroToSixty = 3.9, Handling = 0.55, Price = 1600000, Color = Color3.fromRGB(12, 12, 14), Accent = Color3.fromRGB(255, 140, 0), Order = 58 },
	{ Id = "rolls_wraith", Name = "Rolls Royal Wraith", Class = "Coupe", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 2000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(165, 168, 172), Order = 59 },
	{ Id = "rolls_cullinan", Name = "Rolls Royal Phantom", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 5.1, Handling = 0.55, Price = 2500000, Color = Color3.fromRGB(235, 236, 238), Order = 60 },
	{ Id = "lambrini_lp700", Name = "Lambrini Aventador LP700-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.9, Handling = 0.88, Price = 2200000, Color = Color3.fromRGB(235, 236, 238), Order = 61 },
	{ Id = "lexis_lfa", Name = "Lexis LFA", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.6, Handling = 0.92, Price = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 62 },
	{ Id = "lambrini_lp750", Name = "Lambrini Aventador SV LP750-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.8, Handling = 0.92, Price = 3500000, Color = Color3.fromRGB(120, 200, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 63 },
	{ Id = "lambrini_lp640", Name = "Lambrini Murcielago LP640", Class = "Supercar", Tier = "High", TopSpeed = 211, ZeroToSixty = 3.3, Handling = 0.86, Price = 1800000, Color = Color3.fromRGB(255, 140, 0), Order = 64 },
	{ Id = "bnw_750li", Name = "BNW 750Li", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.64, Price = 150000, Color = Color3.fromRGB(20, 21, 24), Order = 66 },
	{ Id = "bentz_gls", Name = "Mercer Maybech GLS 600", Class = "SUV", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.58, Price = 1200000, Color = Color3.fromRGB(235, 235, 235), Order = 67 },
	{ Id = "bentz_s680", Name = "Mercer Maybech S680", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.62, Price = 1600000, Color = Color3.fromRGB(110, 20, 30), Accent = Color3.fromRGB(215, 200, 170), Order = 68 },
	{ Id = "lambrini_countach", Name = "Lambrini Countach LP400S", Class = "Supercar", Tier = "High", TopSpeed = 179, ZeroToSixty = 5.6, Handling = 0.78, Price = 2500000, Color = Color3.fromRGB(235, 235, 235), Order = 69 },
	-- the cars of 2026-10-18
	{ Id = "toyoka_chaser", Name = "Toyoka Chasor Tourer V", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.6, Handling = 0.76, Price = 55000, Color = Color3.fromRGB(200, 202, 206), Order = 71 },
	{ Id = "bentz_190e", Name = "Mercer 190E Evo II", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 7.1, Handling = 0.74, Price = 80000, Color = Color3.fromRGB(20, 21, 24), Order = 72 },
	{ Id = "bentz_s65_w221", Name = "Mercer S63 W221", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 140000, Color = Color3.fromRGB(235, 236, 238), Order = 73 },
	{ Id = "maseroti_levante", Name = "Maseroti Levanto GTS", Class = "SUV", Tier = "Mid", TopSpeed = 181, ZeroToSixty = 4.0, Handling = 0.64, Price = 190000, Color = Color3.fromRGB(88, 92, 98), Order = 74 },
	{ Id = "lexis_lc500", Name = "Lexis LC500", Class = "Coupe", Tier = "Mid", TopSpeed = 168, ZeroToSixty = 4.4, Handling = 0.78, Price = 240000, Color = Color3.fromRGB(190, 30, 35), Order = 75 },
	{ Id = "astin_dbx", Name = "Astin Marlin DBX", Class = "SUV", Tier = "High", TopSpeed = 181, ZeroToSixty = 4.3, Handling = 0.66, Price = 450000, Color = Color3.fromRGB(88, 92, 98), Order = 76 },
	{ Id = "ferrara_california", Name = "Ferrara Californa", Class = "Supercar", Tier = "High", TopSpeed = 193, ZeroToSixty = 3.8, Handling = 0.84, Price = 650000, Color = Color3.fromRGB(20, 21, 24), Order = 77 },
	{ Id = "bugotti_veyron", Name = "Bugotti Veyrun 16.4", Class = "Hypercar", Tier = "High", TopSpeed = 253, ZeroToSixty = 2.5, Handling = 0.86, Price = 5000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(110, 20, 30), Order = 78 },
	-- owner (2026-10-22): the 5 Series and E Series ladders; no models of their own yet (the M5s
	-- share the G30 5 Series body, the E63 S the E-Class body, which is an E63 S model)
	{ Id = "bnw_m5_f10", Name = "BNW M5 F10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.2, Handling = 0.74, Price = 145000, Color = Color3.fromRGB(26, 44, 82), Order = 80, Model = "bnw_540i" },
	{ Id = "bnw_m5_f90", Name = "BNW M5 F90", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 3.1, Handling = 0.79, Price = 165000, Color = Color3.fromRGB(88, 92, 98), Order = 81, Model = "bnw_540i" },
	{ Id = "bentz_e63s", Name = "Mercer E63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.3, Handling = 0.76, Price = 175000, Color = Color3.fromRGB(20, 21, 24), Order = 82, Model = "bentz_e400" },
}

Cars.List = list
Cars.ById = {} :: { [string]: CarSpec }
for _, spec in list do
	Cars.ById[spec.Id] = spec
end

Cars.StarterId = "suzaki_swift"

-- the car whose imported model a car uses (its own id unless it borrows one)
function Cars.modelOf(id: string): string
	local spec = Cars.ById[id]
	return if spec and spec.Model then spec.Model else id
end

---------------------------------------------------------------------
-- Series and how you get each car (owner, 2026-10-22)
--   * the dealer groups cars into series; the first car of a series is open from the start and
--     each next one needs 5 more levels (level 5, 10, 15 ...)
--   * from the Ferrara F430 up (dealer price $600k and over), cars come only from the car market,
--     and a car in a series can only be taken delivery of when you own the one before it
---------------------------------------------------------------------
export type Series = { Name: string, Ids: { string }, Brand: string? }

Cars.MarketFromPrice = 600000
Cars.LevelsPerTrim = 5

Cars.Series = {
	{ Name = "SUZAKI SWIFF", Ids = { "suzaki_swift" } },
	{ Name = "TOYOKA BELTO", Ids = { "toyoka_belta" } },
	{ Name = "KIO EV6", Ids = { "kio_ev6" } },
	{ Name = "BYT", Ids = { "byt_seal", "byt_u8" } },
	{ Name = "TOYOKA CAMRI", Ids = { "toyoka_camri" } },
	{ Name = "TOYOKA CROWNE", Ids = { "toyoka_crown" } },
	{ Name = "TOYOKA ALFARD", Ids = { "toyoka_alfard" } },
	{ Name = "TOYOKA LAND CRUZER", Ids = { "toyoka_lc200", "toyoka_lc300" } },
	{ Name = "NISUN Z & GT-R", Ids = { "nisun_350z", "nisun_r34", "nisun_gtr" } },
	{ Name = "MAZDO RX", Ids = { "mazdo_rx7", "mazdo_rx8" } },
	{ Name = "BNW 5 SERIES", Ids = { "bnw_530i", "bnw_540i", "bnw_m5_e60", "bnw_m5_f10", "bnw_m5_f90" } },
	{ Name = "BNW 3 & 4 SERIES", Ids = { "bnw_330i_g20", "bnw_m3_e92", "bnw_m3_f80", "bnw_m4_f82" } },
	{ Name = "BNW 6 & 8 SERIES", Ids = { "bnw_m6_v10", "bnw_m8gc" } },
	{ Name = "BNW 7 SERIES", Ids = { "bnw_750li" } },
	{ Name = "BNW X", Ids = { "bnw_x6", "bnw_x7" } },
	{ Name = "MERCER E SERIES", Ids = { "bentz_e300", "bentz_e400", "bentz_e63s" } },
	{ Name = "MERCER 190E", Ids = { "bentz_190e" } },
	{ Name = "MERCER CLA & CLS", Ids = { "bentz_cla45", "bentz_cls63s" } },
	{ Name = "MERCER S-CLASS", Ids = { "bentz_s65_w221", "bentz_s63", "bentz_s680" } },
	{ Name = "MERCER SUV", Ids = { "bentz_gle53", "bentz_g63", "bentz_gls", "brabos_g63" } },
	{ Name = "MERCER SL & SLS", Ids = { "bentz_sl65bs", "bentz_sls" } },
	{ Name = "TOYOKA SUPRO", Ids = { "toyoka_supra_mk4" } },
	{ Name = "TOYOKA CHASOR", Ids = { "toyoka_chaser" } },
	{ Name = "DODGER", Ids = { "dodger_challenger", "bentz_gt63s" } },
	{ Name = "XIAOMO SU7", Ids = { "xiaomo_su7" } },
	{ Name = "LEXIS", Ids = { "lexis_lc500", "lexis_lx700", "lexis_lfa" } },
	{ Name = "MASEROTI LEVANTO", Ids = { "maseroti_levante" } },
	{ Name = "CHEVO CAMARO", Ids = { "chevo_camaro" } },
	{ Name = "CHEVO CORVETTE", Ids = { "chevo_c6", "chevo_c7" } },
	{ Name = "PORSHA", Ids = { "porsha_boxster", "porsha_panamera", "porsha_gt3" } },
	{ Name = "ASTIN MARLIN", Ids = { "astin_dbx", "astin_db9", "astin_vantage" } },
	{ Name = "AUDY R8", Ids = { "audy_r8" } },
	{ Name = "FERRARA", Ids = { "ferrara_f430", "ferrara_california", "ferrara_599", "ferrara_458" } },
	{ Name = "LAMBRINI", Ids = { "lambrini_lp570", "lambrini_lp640", "lambrini_lp700", "lambrini_lp750" } },
	{ Name = "LAMBRINI URUS", Ids = { "lambrini_urus" } },
	{ Name = "LAMBRINI COUNTACH", Ids = { "lambrini_countach" } },
	{ Name = "MCLARAN", Ids = { "mclaran_12c" } },
	{ Name = "BENTLEE", Ids = { "bentlee_contgt", "bentlee_bentayga" } },
	{ Name = "ROLLS ROYAL", Ids = { "rolls_wraith", "rolls_cullinan" } },
	{ Name = "BUGOTTI", Ids = { "bugotti_veyron" } },
} :: { Series }

-- each series' brand (owner, 2026-10-22: "fit each car into the brands"): the make in its first
-- car's name; the garage lists brands, then their series
local TWO_WORD_BRANDS = { Rolls = "ROLLS ROYAL", Astin = "ASTIN MARLIN" }
local byIdEarly: { [string]: CarSpec } = {}
for _, spec in list do
	byIdEarly[spec.Id] = spec
end
for _, series in Cars.Series do
	local first = byIdEarly[series.Ids[1]]
	local word = if first then string.match(first.Name, "^(%S+)") or first.Name else series.Name
	series.Brand = TWO_WORD_BRANDS[word] or string.upper(word)
end

Cars.SeriesOf = {} :: { [string]: { series: Series, index: number } }
for _, series in Cars.Series do
	for i, id in series.Ids do
		Cars.SeriesOf[id] = { series = series, index = i }
	end
end
-- any car left out gets a series of its own
for _, spec in list do
	if not Cars.SeriesOf[spec.Id] then
		local word = string.match(spec.Name, "^(%S+)") or spec.Name
		local series = { Name = string.upper(spec.Name), Ids = { spec.Id }, Brand = TWO_WORD_BRANDS[word] or string.upper(word) }
		table.insert(Cars.Series, series)
		Cars.SeriesOf[spec.Id] = { series = series, index = 1 }
	end
end

-- from the F430 up: only from the car market
function Cars.isMarketOnly(id: string): boolean
	local spec = Cars.ById[id]
	return spec ~= nil and spec.Price >= Cars.MarketFromPrice
end

-- the level a dealer car opens at: the series' first car at once, each next one 5 levels on
function Cars.requiredLevel(id: string): number
	local at = Cars.SeriesOf[id]
	if not at or at.index <= 1 then
		return 1
	end
	return (at.index - 1) * Cars.LevelsPerTrim
end

-- the car before this one in its series (nil for the first)
function Cars.previous(id: string): string?
	local at = Cars.SeriesOf[id]
	if not at or at.index <= 1 then
		return nil
	end
	return at.series.Ids[at.index - 1]
end
Cars.CutsceneId = "lambrini_lp750"

-- Realistic paint palette for NPC traffic
Cars.TrafficColors = {
	Color3.fromRGB(235, 236, 238), -- white
	Color3.fromRGB(235, 236, 238),
	Color3.fromRGB(20, 21, 24), -- black
	Color3.fromRGB(20, 21, 24),
	Color3.fromRGB(165, 168, 172), -- silver
	Color3.fromRGB(165, 168, 172),
	Color3.fromRGB(88, 92, 98), -- gunmetal
	Color3.fromRGB(26, 44, 82), -- navy
	Color3.fromRGB(130, 20, 26), -- dark red
	Color3.fromRGB(190, 30, 35), -- red
	Color3.fromRGB(36, 70, 52), -- racing green
	Color3.fromRGB(150, 128, 98), -- champagne
	Color3.fromRGB(40, 90, 160), -- blue
}

function Cars.get(id: string): CarSpec
	return Cars.ById[id] or Cars.ById[Cars.StarterId]
end

return Cars
