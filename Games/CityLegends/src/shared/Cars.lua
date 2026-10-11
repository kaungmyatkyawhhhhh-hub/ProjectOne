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
	{ Id = "byt_dolphin", Name = "BYT Dolphin EV", Class = "Sedan", Tier = "Starter", TopSpeed = 100, ZeroToSixty = 8.0, Handling = 0.55, Price = 9000, Color = Color3.fromRGB(120, 190, 200), Order = 3 },
	{ Id = "kio_ev6", Name = "Kio EV6", Class = "SUV", Tier = "Starter", TopSpeed = 93, ZeroToSixty = 9.5, Handling = 0.5, Price = 11000, Color = Color3.fromRGB(235, 236, 238), Order = 4 },
	{ Id = "byt_seal", Name = "BYT Seal EV", Class = "Sedan", Tier = "Starter", TopSpeed = 100, ZeroToSixty = 7.3, Handling = 0.55, Price = 14000, Color = Color3.fromRGB(40, 90, 160), Order = 5 },
	{ Id = "toyoka_camri", Name = "Toyoka Camri", Class = "Sedan", Tier = "Starter", TopSpeed = 135, ZeroToSixty = 7.6, Handling = 0.58, Price = 16000, Color = Color3.fromRGB(20, 21, 24), Order = 6 },
	{ Id = "toyoka_crown", Name = "Toyoka Crowne Athlete", Class = "Sedan", Tier = "Starter", TopSpeed = 143, ZeroToSixty = 6.9, Handling = 0.6, Price = 22000, Color = Color3.fromRGB(235, 236, 238), Order = 7 },
	{ Id = "toyoka_alfard", Name = "Toyoka Alfard", Class = "SUV", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 8.5, Handling = 0.45, Price = 28000, Color = Color3.fromRGB(20, 21, 24), Order = 8 },
	{ Id = "toyoka_lc200", Name = "Toyoka Land Cruzer 200", Class = "SUV", Tier = "Starter", TopSpeed = 130, ZeroToSixty = 6.9, Handling = 0.46, Price = 35000, Color = Color3.fromRGB(235, 236, 238), Order = 9 },
	{ Id = "nisun_350z", Name = "Nisun 350Z", Class = "Coupe", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.4, Handling = 0.72, Price = 38000, Color = Color3.fromRGB(220, 170, 30), Order = 10 },

	-- Mid tier
	{ Id = "bnw_530i", Name = "BNW 530i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.9, Handling = 0.66, Price = 52000, Color = Color3.fromRGB(20, 21, 24), Order = 11 },
	{ Id = "bnw_540i", Name = "BNW 540i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.7, Handling = 0.68, Price = 64000, Color = Color3.fromRGB(26, 44, 82), Order = 12 },
	{ Id = "bentz_e200", Name = "Mercer E200", Class = "Sedan", Tier = "Mid", TopSpeed = 149, ZeroToSixty = 7.3, Handling = 0.62, Price = 58000, Color = Color3.fromRGB(235, 236, 238), Order = 13 },
	{ Id = "bentz_e300", Name = "Mercer E300", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 6.1, Handling = 0.63, Price = 70000, Color = Color3.fromRGB(88, 92, 98), Order = 14 },
	{ Id = "bentz_e400", Name = "Mercer E400", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.9, Handling = 0.66, Price = 85000, Color = Color3.fromRGB(20, 21, 24), Order = 15 },
	{ Id = "bnw_330i_g20", Name = "BNW 330i M Sport", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.3, Handling = 0.7, Price = 60000, Color = Color3.fromRGB(40, 90, 160), Order = 16 },
	{ Id = "bnw_m3_e92", Name = "BNW M3 E92", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.6, Handling = 0.76, Price = 90000, Color = Color3.fromRGB(235, 236, 238), Order = 17 },
	{ Id = "bnw_m3_f80", Name = "BNW M3 F80", Class = "Sedan", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.0, Handling = 0.78, Price = 110000, Color = Color3.fromRGB(220, 170, 30), Order = 18 },
	{ Id = "bnw_m5_e60", Name = "BNW M5 E60 V10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.4, Handling = 0.72, Price = 125000, Color = Color3.fromRGB(165, 168, 172), Order = 19 },
	{ Id = "bnw_m6_v10", Name = "BNW M6 V10", Class = "Coupe", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.5, Handling = 0.73, Price = 135000, Color = Color3.fromRGB(26, 44, 82), Order = 20 },
	{ Id = "bentz_cla45", Name = "Mercer CLA 45", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.0, Handling = 0.74, Price = 95000, Color = Color3.fromRGB(140, 145, 150), Order = 21 },
	{ Id = "bentz_cls550", Name = "Mercer CLS 550", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.0, Handling = 0.66, Price = 100000, Color = Color3.fromRGB(20, 21, 24), Order = 22 },
	{ Id = "bentz_cls55", Name = "Mercer CLS 55", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.5, Handling = 0.68, Price = 120000, Color = Color3.fromRGB(165, 168, 172), Order = 23 },
	{ Id = "bentz_cls63s", Name = "Mercer CLS 63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.6, Handling = 0.72, Price = 160000, Color = Color3.fromRGB(20, 21, 24), Order = 24 },
	{ Id = "toyoka_supra_mk4", Name = "Toyoka Supro MK4", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 4.6, Handling = 0.76, Price = 140000, Color = Color3.fromRGB(220, 100, 20), Order = 25 },
	{ Id = "dodger_challenger", Name = "Dodger Challenjer", Class = "Coupe", Tier = "Mid", TopSpeed = 175, ZeroToSixty = 4.2, Handling = 0.66, Price = 115000, Color = Color3.fromRGB(176, 14, 18), Accent = Color3.fromRGB(16, 16, 18), Order = 26 },
	{ Id = "bnw_x6", Name = "BNW X6 M Sport", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.2, Handling = 0.6, Price = 130000, Color = Color3.fromRGB(20, 21, 24), Order = 27 },
	{ Id = "toyoka_lc300", Name = "Toyoka Land Cruzer 300", Class = "SUV", Tier = "Mid", TopSpeed = 130, ZeroToSixty = 6.5, Handling = 0.5, Price = 150000, Color = Color3.fromRGB(235, 236, 238), Order = 28 },
	{ Id = "lexis_lx570", Name = "Lexis LX570 Kuro", Class = "SUV", Tier = "Mid", TopSpeed = 137, ZeroToSixty = 7.0, Handling = 0.48, Price = 170000, Color = Color3.fromRGB(12, 12, 14), Order = 29 },
	{ Id = "bentz_g63", Name = "Mercer G63 2019", Class = "SUV", Tier = "Mid", TopSpeed = 149, ZeroToSixty = 4.4, Handling = 0.52, Price = 260000, Color = Color3.fromRGB(20, 21, 24), Order = 30 },
	{ Id = "porsha_panamera", Name = "Porsha Panamera Turbo S", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.0, Handling = 0.8, Price = 300000, Color = Color3.fromRGB(88, 92, 98), Order = 31 },
	{ Id = "chevo_camaro", Name = "Chevo Camaro SS", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.0, Handling = 0.74, Price = 62000, Color = Color3.fromRGB(230, 180, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 32 },
	{ Id = "chevo_c6", Name = "Chevo Corvette C6", Class = "Coupe", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 4.2, Handling = 0.8, Price = 78000, Color = Color3.fromRGB(26, 44, 82), Order = 33 },
	{ Id = "porsha_boxster", Name = "Porsha Boxster 718", Class = "Coupe", Tier = "Mid", TopSpeed = 177, ZeroToSixty = 4.2, Handling = 0.9, Price = 92000, Color = Color3.fromRGB(200, 200, 206), Order = 34 },
	{ Id = "chevo_c7", Name = "Chevo Corvette C7", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 3.8, Handling = 0.84, Price = 112000, Color = Color3.fromRGB(200, 10, 20), Order = 35 },
	{ Id = "mazdo_rx7", Name = "Mazdo RX-7", Class = "Coupe", Tier = "Mid", TopSpeed = 156, ZeroToSixty = 5.0, Handling = 0.82, Price = 120000, Color = Color3.fromRGB(235, 236, 238), Order = 36 },
	{ Id = "bentz_s63", Name = "Mercer S63 W222", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 3.9, Handling = 0.7, Price = 280000, Color = Color3.fromRGB(20, 21, 24), Order = 37 },
	{ Id = "bentz_gt63s", Name = "Mercer GT63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.1, Handling = 0.8, Price = 320000, Color = Color3.fromRGB(88, 92, 98), Order = 38 },

	-- High tier
	{ Id = "nisun_gtr", Name = "Nisun GT-R R35", Class = "Coupe", Tier = "High", TopSpeed = 196, ZeroToSixty = 2.9, Handling = 0.86, Price = 420000, Color = Color3.fromRGB(235, 236, 238), Order = 39 },
	{ Id = "astin_db9", Name = "Astin Marlin DB9", Class = "Coupe", Tier = "High", TopSpeed = 183, ZeroToSixty = 4.6, Handling = 0.76, Price = 450000, Color = Color3.fromRGB(26, 44, 82), Order = 40 },
	{ Id = "astin_vantage", Name = "Astin Marlin Vantage", Class = "Coupe", Tier = "High", TopSpeed = 195, ZeroToSixty = 3.5, Handling = 0.82, Price = 500000, Color = Color3.fromRGB(36, 70, 52), Order = 41 },
	{ Id = "ferrara_f430", Name = "Ferrara F430", Class = "Supercar", Tier = "High", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.86, Price = 600000, Color = Color3.fromRGB(200, 10, 20), Order = 42 },
	{ Id = "lambrini_lp560", Name = "Lambrini Gallardo LP560-4", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.7, Handling = 0.85, Price = 650000, Color = Color3.fromRGB(220, 170, 30), Order = 43 },
	{ Id = "lambrini_lp570", Name = "Lambrini Gallardo LP570-4 SL", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.88, Price = 750000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 44 },
	{ Id = "audy_r8", Name = "Audy R8 Type 42", Class = "Supercar", Tier = "High", TopSpeed = 188, ZeroToSixty = 4.4, Handling = 0.86, Price = 550000, Color = Color3.fromRGB(165, 168, 172), Accent = Color3.fromRGB(16, 16, 18), Order = 45 },
	{ Id = "mclaran_12c", Name = "McLaran MP4-12C", Class = "Supercar", Tier = "High", TopSpeed = 207, ZeroToSixty = 3.1, Handling = 0.9, Price = 800000, Color = Color3.fromRGB(226, 84, 8), Order = 46 },
	{ Id = "ferrara_599", Name = "Ferrara 599", Class = "Supercar", Tier = "High", TopSpeed = 205, ZeroToSixty = 3.5, Handling = 0.84, Price = 850000, Color = Color3.fromRGB(20, 21, 24), Order = 47 },
	{ Id = "ferrara_458", Name = "Ferrara 458 Itala", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.9, Price = 900000, Color = Color3.fromRGB(200, 10, 20), Order = 48 },
	{ Id = "bentz_sls", Name = "Mercer SLS", Class = "Supercar", Tier = "High", TopSpeed = 197, ZeroToSixty = 3.7, Handling = 0.86, Price = 950000, Color = Color3.fromRGB(235, 236, 238), Order = 49 },
	{ Id = "porsha_gt3", Name = "Porsha 911 GT3 991.2", Class = "Supercar", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.2, Handling = 0.95, Price = 1000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 50 },
	{ Id = "bentlee_contgt", Name = "Bentlee Continental GT", Class = "Coupe", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.6, Handling = 0.74, Price = 1100000, Color = Color3.fromRGB(26, 44, 82), Order = 51 },
	{ Id = "bentlee_bentayga", Name = "Bentlee Bentayga", Class = "SUV", Tier = "High", TopSpeed = 187, ZeroToSixty = 4.0, Handling = 0.6, Price = 1200000, Color = Color3.fromRGB(20, 21, 24), Order = 52 },
	{ Id = "lambrini_urus", Name = "Lambrini Urus", Class = "SUV", Tier = "High", TopSpeed = 190, ZeroToSixty = 3.5, Handling = 0.7, Price = 1500000, Color = Color3.fromRGB(220, 170, 30), Order = 53 },
	{ Id = "brabos_g63", Name = "Brabos G63", Class = "SUV", Tier = "High", TopSpeed = 149, ZeroToSixty = 3.9, Handling = 0.55, Price = 1600000, Color = Color3.fromRGB(12, 12, 14), Accent = Color3.fromRGB(255, 140, 0), Order = 54 },
	{ Id = "rolls_wraith", Name = "Rolls Royal Wraith", Class = "Coupe", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 2000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(165, 168, 172), Order = 55 },
	{ Id = "rolls_cullinan", Name = "Rolls Royal Cullinan", Class = "SUV", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.55, Price = 2500000, Color = Color3.fromRGB(235, 236, 238), Order = 56 },
	{ Id = "lambrini_lp700", Name = "Lambrini Aventador LP700-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.9, Handling = 0.88, Price = 2200000, Color = Color3.fromRGB(235, 236, 238), Order = 57 },
	{ Id = "lexis_lfa", Name = "Lexis LFA", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.6, Handling = 0.92, Price = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 58 },
	{ Id = "lambrini_lp750", Name = "Lambrini Aventador SV LP750-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.8, Handling = 0.92, Price = 3500000, Color = Color3.fromRGB(120, 200, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 59 },
	{ Id = "lambrini_lp640", Name = "Lambrini Murcielago LP640", Class = "Supercar", Tier = "High", TopSpeed = 211, ZeroToSixty = 3.3, Handling = 0.86, Price = 1800000, Color = Color3.fromRGB(255, 140, 0), Order = 60 },
	{ Id = "bentz_maybach", Name = "Mercer Maybech S680", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.62, Price = 1400000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(165, 168, 172), Order = 61 },
}

Cars.List = list
Cars.ById = {} :: { [string]: CarSpec }
for _, spec in list do
	Cars.ById[spec.Id] = spec
end

Cars.StarterId = "suzaki_swift"
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
