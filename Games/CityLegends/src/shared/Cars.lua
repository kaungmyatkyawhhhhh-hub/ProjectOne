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
	Trim: string?, -- BASE / SPORT / TOP on a line that got the extra trims
	BaseId: string?, -- a SPORT / TOP trim: the car it is built on
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

-- the makes (owner, 2026-10-31: the new brand names; the model names stay for now)
Cars.Makes = {
	"Bavarica Werkz", "Tri-Star Silber", "Rocket", "Apex", "Stealth-Apex", "Horizon", "Ahura", "Sompact",
	"Orient", "Dream-Build Volt", "HyperSpeed Tech", "Golden", "Hemi", "Stuttgart", "Precision",
	"British Vanguard", "Rosso Rampante", "Enfurecido", "Trident Motors", "Speedmark", "Sovereign",
	"Ecstasy", "Velocité Noir",
}

-- string.upper that also does the accented letters in the makes (it only knows a-z)
function Cars.upper(s: string): string
	return (string.gsub(string.upper(s), "é", "É"))
end

-- the make a car name starts with (its first word if none)
function Cars.makeOf(name: string): string
	local best = ""
	for _, make in Cars.Makes do
		if #make > #best and string.sub(name, 1, #make + 1) == make .. " " then
			best = make
		end
	end
	return if best ~= "" then best else (string.match(name, "^(%S+)") or name)
end

local list: { CarSpec } = {
	-- Starter cars (beginner)
	{ Id = "suzaki_swift", Name = "Sompact Swiff", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 9.5, Handling = 0.62, Price = 0, Color = Color3.fromRGB(200, 30, 36), Order = 1 },
	{ Id = "toyoka_belta", Name = "Apex Belto", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 10.5, Handling = 0.55, Price = 6000, Color = Color3.fromRGB(196, 199, 204), Order = 2 },
	{ Id = "kio_ev6", Name = "Orient EV6", Class = "SUV", Tier = "Starter", TopSpeed = 93, ZeroToSixty = 9.5, Handling = 0.5, Price = 11000, Color = Color3.fromRGB(235, 236, 238), Order = 3, Electric = true },
	{ Id = "byt_seal", Name = "Dream-Build Volt Seal EV", Class = "Sedan", Tier = "Starter", TopSpeed = 100, ZeroToSixty = 7.3, Handling = 0.55, Price = 14000, Color = Color3.fromRGB(40, 90, 160), Order = 4, Electric = true },
	{ Id = "toyoka_camri", Name = "Apex Camri", Class = "Sedan", Tier = "Starter", TopSpeed = 135, ZeroToSixty = 7.6, Handling = 0.58, Price = 16000, Color = Color3.fromRGB(20, 21, 24), Order = 5 },
	{ Id = "toyoka_crown", Name = "Apex Crowne Athlete", Class = "Sedan", Tier = "Starter", TopSpeed = 143, ZeroToSixty = 6.9, Handling = 0.6, Price = 22000, Color = Color3.fromRGB(235, 236, 238), Order = 6 },
	{ Id = "toyoka_alfard", Name = "Apex Alfard", Class = "SUV", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 8.5, Handling = 0.45, Price = 28000, Color = Color3.fromRGB(20, 21, 24), Order = 7 },
	{ Id = "toyoka_lc200", Name = "Apex Land Cruzer 200", Class = "SUV", Tier = "Starter", TopSpeed = 130, ZeroToSixty = 6.9, Handling = 0.46, Price = 35000, Color = Color3.fromRGB(235, 236, 238), Order = 8 },
	{ Id = "nisun_350z", Name = "Horizon 350Z", Class = "Coupe", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.4, Handling = 0.72, Price = 38000, Color = Color3.fromRGB(220, 170, 30), Order = 9 },
	{ Id = "mazdo_rx7", Name = "Ahura RX-7", Class = "Coupe", Tier = "Starter", TopSpeed = 156, ZeroToSixty = 5.0, Handling = 0.82, Price = 42000, Color = Color3.fromRGB(235, 236, 238), Order = 10 },
	{ Id = "mazdo_rx8", Name = "Ahura RX-8", Class = "Coupe", Tier = "Starter", TopSpeed = 146, ZeroToSixty = 6.4, Handling = 0.8, Price = 45000, Color = Color3.fromRGB(190, 30, 35), Order = 11 },

	-- Mid tier
	{ Id = "bnw_530i", Name = "Bavarica Werkz 530i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.9, Handling = 0.66, Price = 52000, Color = Color3.fromRGB(20, 21, 24), Order = 12 },
	{ Id = "bnw_540i", Name = "Bavarica Werkz 540i G30", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.7, Handling = 0.68, Price = 64000, Color = Color3.fromRGB(26, 44, 82), Order = 13 },
	{ Id = "bentz_e300", Name = "Tri-Star Silber E300", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 6.1, Handling = 0.63, Price = 70000, Color = Color3.fromRGB(88, 92, 98), Order = 14 },
	{ Id = "bentz_e400", Name = "Tri-Star Silber E400", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.9, Handling = 0.66, Price = 85000, Color = Color3.fromRGB(20, 21, 24), Order = 15 },
	{ Id = "bnw_330i_g20", Name = "Bavarica Werkz 330i M Sport", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.3, Handling = 0.7, Price = 60000, Color = Color3.fromRGB(40, 90, 160), Order = 16 },
	{ Id = "bnw_m3_e92", Name = "Bavarica Werkz M3 E92", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.6, Handling = 0.76, Price = 90000, Color = Color3.fromRGB(235, 236, 238), Order = 17 },
	{ Id = "bnw_m3_f80", Name = "Bavarica Werkz M3 F80", Class = "Sedan", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.0, Handling = 0.78, Price = 110000, Color = Color3.fromRGB(220, 170, 30), Order = 18 },
	{ Id = "bnw_m4_f82", Name = "Bavarica Werkz M4 F82", Class = "Coupe", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.1, Handling = 0.8, Price = 100000, Color = Color3.fromRGB(30, 80, 170), Order = 19 },
	{ Id = "bnw_m5_e60", Name = "Bavarica Werkz M5 E60 V10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.4, Handling = 0.72, Price = 125000, Color = Color3.fromRGB(165, 168, 172), Order = 20 },
	{ Id = "bnw_m6_v10", Name = "Bavarica Werkz M6 V10", Class = "Coupe", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.5, Handling = 0.73, Price = 135000, Color = Color3.fromRGB(26, 44, 82), Order = 21 },
	{ Id = "bnw_m8gc", Name = "Bavarica Werkz M8 Gran Coupe", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 3.0, Handling = 0.78, Price = 210000, Color = Color3.fromRGB(26, 44, 82), Order = 22 },
	{ Id = "bentz_cla45", Name = "Tri-Star Silber CLA 45", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.0, Handling = 0.74, Price = 95000, Color = Color3.fromRGB(140, 145, 150), Order = 23 },
	{ Id = "bentz_cls63s", Name = "Tri-Star Silber CLS 63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.6, Handling = 0.72, Price = 160000, Color = Color3.fromRGB(20, 21, 24), Order = 24 },
	{ Id = "toyoka_supra_mk4", Name = "Apex Supro MK4", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 4.6, Handling = 0.76, Price = 140000, Color = Color3.fromRGB(220, 100, 20), Order = 25 },
	{ Id = "nisun_r34", Name = "Horizon Skyline R34 GT-R", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.9, Handling = 0.8, Price = 180000, Color = Color3.fromRGB(40, 60, 150), Order = 26 },
	{ Id = "dodger_challenger", Name = "Hemi Challenjer", Class = "Coupe", Tier = "Mid", TopSpeed = 175, ZeroToSixty = 4.2, Handling = 0.66, Price = 115000, Color = Color3.fromRGB(176, 14, 18), Accent = Color3.fromRGB(16, 16, 18), Order = 27 },
	{ Id = "xiaomo_su7", Name = "HyperSpeed Tech SU7", Class = "Sedan", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 2.8, Handling = 0.78, Price = 120000, Color = Color3.fromRGB(40, 90, 160), Order = 28, Electric = true },
	{ Id = "bnw_x6", Name = "Bavarica Werkz X6 M Sport", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.2, Handling = 0.6, Price = 130000, Color = Color3.fromRGB(20, 21, 24), Order = 29 },
	{ Id = "bnw_x7", Name = "Bavarica Werkz X7", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.5, Handling = 0.56, Price = 175000, Color = Color3.fromRGB(235, 236, 238), Order = 30 },
	{ Id = "toyoka_lc300", Name = "Apex Land Cruzer 300", Class = "SUV", Tier = "Mid", TopSpeed = 130, ZeroToSixty = 6.5, Handling = 0.5, Price = 150000, Color = Color3.fromRGB(235, 236, 238), Order = 31 },
	{ Id = "lexis_lx700", Name = "Stealth-Apex LX700", Class = "SUV", Tier = "Mid", TopSpeed = 137, ZeroToSixty = 6.4, Handling = 0.5, Price = 245000, Color = Color3.fromRGB(12, 12, 14), Order = 32 },
	{ Id = "bentz_gle53", Name = "Tri-Star Silber GLE 53", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.0, Handling = 0.62, Price = 250000, Color = Color3.fromRGB(165, 168, 172), Order = 33 },
	{ Id = "bentz_g63", Name = "Tri-Star Silber G63", Class = "SUV", Tier = "Mid", TopSpeed = 149, ZeroToSixty = 4.4, Handling = 0.52, Price = 260000, Color = Color3.fromRGB(20, 21, 24), Order = 34 },
	{ Id = "byt_u8", Name = "Dream-Build Volt Yangwong U8", Class = "SUV", Tier = "Mid", TopSpeed = 124, ZeroToSixty = 3.6, Handling = 0.55, Price = 290000, Color = Color3.fromRGB(20, 21, 24), Order = 35, Electric = true },
	{ Id = "porsha_panamera", Name = "Stuttgart Panamera Turbo S", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.0, Handling = 0.8, Price = 300000, Color = Color3.fromRGB(88, 92, 98), Order = 36 },
	{ Id = "chevo_camaro", Name = "Golden Camaro ZL1", Class = "Coupe", Tier = "Mid", TopSpeed = 184, ZeroToSixty = 3.9, Handling = 0.74, Price = 62000, Color = Color3.fromRGB(230, 180, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 37 },
	{ Id = "chevo_c6", Name = "Golden Corvette C6", Class = "Coupe", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 4.2, Handling = 0.8, Price = 78000, Color = Color3.fromRGB(26, 44, 82), Order = 38 },
	{ Id = "porsha_boxster", Name = "Stuttgart Boxster 718", Class = "Coupe", Tier = "Mid", TopSpeed = 177, ZeroToSixty = 4.2, Handling = 0.9, Price = 92000, Color = Color3.fromRGB(200, 200, 206), Order = 39 },
	{ Id = "chevo_c7", Name = "Golden Corvette C7", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 3.8, Handling = 0.84, Price = 112000, Color = Color3.fromRGB(200, 10, 20), Order = 40 },
	{ Id = "bentz_s63", Name = "Tri-Star Silber S65 W222", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 3.9, Handling = 0.7, Price = 280000, Color = Color3.fromRGB(20, 21, 24), Order = 41 },
	{ Id = "bentz_gt63s", Name = "Hemi SRT", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.8, Price = 320000, Color = Color3.fromRGB(88, 92, 98), Order = 42 },

	-- High tier
	{ Id = "nisun_gtr", Name = "Horizon GT-R R35", Class = "Coupe", Tier = "High", TopSpeed = 196, ZeroToSixty = 2.9, Handling = 0.86, Price = 420000, Color = Color3.fromRGB(235, 236, 238), Order = 43 },
	{ Id = "astin_db9", Name = "British Vanguard Vanquish", Class = "Coupe", Tier = "High", TopSpeed = 201, ZeroToSixty = 3.8, Handling = 0.76, Price = 450000, Color = Color3.fromRGB(26, 44, 82), Order = 44 },
	{ Id = "astin_vantage", Name = "British Vanguard Vantage", Class = "Coupe", Tier = "High", TopSpeed = 195, ZeroToSixty = 3.5, Handling = 0.82, Price = 500000, Color = Color3.fromRGB(36, 70, 52), Order = 45 },
	{ Id = "ferrara_f430", Name = "Rosso Rampante F430", Class = "Supercar", Tier = "High", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.86, Price = 600000, Color = Color3.fromRGB(200, 10, 20), Order = 46 },
	{ Id = "bentz_sl65bs", Name = "Tri-Star Silber SL65 Black Series", Class = "Coupe", Tier = "High", TopSpeed = 199, ZeroToSixty = 3.8, Handling = 0.82, Price = 700000, Color = Color3.fromRGB(18, 18, 20), Order = 47 },
	{ Id = "lambrini_lp570", Name = "Enfurecido Gallardo LP570-4 SL", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.88, Price = 750000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 48 },
	{ Id = "audy_r8", Name = "Precision R8 Type 42", Class = "Supercar", Tier = "High", TopSpeed = 188, ZeroToSixty = 4.4, Handling = 0.86, Price = 550000, Color = Color3.fromRGB(165, 168, 172), Accent = Color3.fromRGB(16, 16, 18), Order = 49 },
	{ Id = "mclaran_12c", Name = "Speedmark MP4-12C", Class = "Supercar", Tier = "High", TopSpeed = 207, ZeroToSixty = 3.1, Handling = 0.9, Price = 800000, Color = Color3.fromRGB(226, 84, 8), Order = 50 },
	{ Id = "ferrara_599", Name = "Rosso Rampante 599", Class = "Supercar", Tier = "High", TopSpeed = 205, ZeroToSixty = 3.5, Handling = 0.84, Price = 850000, Color = Color3.fromRGB(20, 21, 24), Order = 51 },
	{ Id = "ferrara_458", Name = "Rosso Rampante 458 Itala", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.9, Price = 900000, Color = Color3.fromRGB(200, 10, 20), Order = 52 },
	{ Id = "bentz_sls", Name = "Tri-Star Silber SLS", Class = "Supercar", Tier = "High", TopSpeed = 197, ZeroToSixty = 3.7, Handling = 0.86, Price = 950000, Color = Color3.fromRGB(235, 236, 238), Order = 53 },
	{ Id = "porsha_gt3", Name = "Stuttgart 911 GT3 991.2", Class = "Supercar", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.2, Handling = 0.95, Price = 1000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 54 },
	{ Id = "bentlee_contgt", Name = "Sovereign Continental GT", Class = "Coupe", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.6, Handling = 0.74, Price = 1100000, Color = Color3.fromRGB(26, 44, 82), Order = 55 },
	{ Id = "bentlee_bentayga", Name = "Sovereign Bentayga", Class = "SUV", Tier = "High", TopSpeed = 187, ZeroToSixty = 4.0, Handling = 0.6, Price = 1200000, Color = Color3.fromRGB(20, 21, 24), Order = 56 },
	{ Id = "lambrini_urus", Name = "Enfurecido Urus", Class = "SUV", Tier = "High", TopSpeed = 190, ZeroToSixty = 3.5, Handling = 0.7, Price = 1500000, Color = Color3.fromRGB(220, 170, 30), Order = 57 },
	{ Id = "brabos_g63", Name = "Rocket G63", Class = "SUV", Tier = "High", TopSpeed = 149, ZeroToSixty = 3.9, Handling = 0.55, Price = 1600000, Color = Color3.fromRGB(12, 12, 14), Accent = Color3.fromRGB(255, 140, 0), Order = 58 },
	{ Id = "rolls_wraith", Name = "Ecstasy Wraith", Class = "Coupe", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 2000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(165, 168, 172), Order = 59 },
	{ Id = "rolls_cullinan", Name = "Ecstasy Phantom", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 5.1, Handling = 0.55, Price = 2500000, Color = Color3.fromRGB(235, 236, 238), Order = 60 },
	{ Id = "lambrini_lp700", Name = "Enfurecido Aventador LP700-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.9, Handling = 0.88, Price = 2200000, Color = Color3.fromRGB(235, 236, 238), Order = 61 },
	{ Id = "lexis_lfa", Name = "Stealth-Apex LFA", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.6, Handling = 0.92, Price = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 62 },
	{ Id = "lambrini_lp750", Name = "Enfurecido Aventador SV LP750-4", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.8, Handling = 0.92, Price = 3500000, Color = Color3.fromRGB(120, 200, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 63 },
	-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of the Aventador line, on their own new models
	{ Id = "lambrini_svj", Name = "Enfurecido Aventador SVJ", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.7, Handling = 0.95, Price = 4200000, Color = Color3.fromRGB(150, 112, 78), Accent = Color3.fromRGB(16, 16, 18), Order = 83 },
	{ Id = "lambrini_svj63", Name = "Enfurecido Aventador SVJ 63", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.7, Handling = 0.96, Price = 5500000, Color = Color3.fromRGB(64, 67, 72), Accent = Color3.fromRGB(200, 16, 16), Order = 84 },
	{ Id = "lambrini_lp640", Name = "Enfurecido Murcielago LP640", Class = "Supercar", Tier = "High", TopSpeed = 211, ZeroToSixty = 3.3, Handling = 0.86, Price = 1800000, Color = Color3.fromRGB(255, 140, 0), Order = 64 },
	{ Id = "bnw_750li", Name = "Bavarica Werkz 750Li", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.64, Price = 150000, Color = Color3.fromRGB(20, 21, 24), Order = 66 },
	{ Id = "bentz_gls", Name = "Tri-Star Silber Maybech GLS 600", Class = "SUV", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.58, Price = 1200000, Color = Color3.fromRGB(235, 235, 235), Order = 67 },
	{ Id = "bentz_s680", Name = "Tri-Star Silber Maybech S680", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.62, Price = 1600000, Color = Color3.fromRGB(110, 20, 30), Accent = Color3.fromRGB(215, 200, 170), Order = 68 },
	{ Id = "lambrini_countach", Name = "Enfurecido Countach LP400S", Class = "Supercar", Tier = "High", TopSpeed = 179, ZeroToSixty = 5.6, Handling = 0.78, Price = 2500000, Color = Color3.fromRGB(235, 235, 235), Order = 69 },
	-- the cars of 2026-10-18
	{ Id = "toyoka_chaser", Name = "Apex Chasor Tourer V", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.6, Handling = 0.76, Price = 55000, Color = Color3.fromRGB(200, 202, 206), Order = 71 },
	{ Id = "bentz_190e", Name = "Tri-Star Silber 190E Evo II", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 7.1, Handling = 0.74, Price = 80000, Color = Color3.fromRGB(20, 21, 24), Order = 72 },
	{ Id = "bentz_s65_w221", Name = "Tri-Star Silber S63 W221", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 140000, Color = Color3.fromRGB(235, 236, 238), Order = 73 },
	{ Id = "maseroti_levante", Name = "Trident Motors Levanto GTS", Class = "SUV", Tier = "Mid", TopSpeed = 181, ZeroToSixty = 4.0, Handling = 0.64, Price = 190000, Color = Color3.fromRGB(88, 92, 98), Order = 74 },
	{ Id = "lexis_lc500", Name = "Stealth-Apex LC500", Class = "Coupe", Tier = "Mid", TopSpeed = 168, ZeroToSixty = 4.4, Handling = 0.78, Price = 240000, Color = Color3.fromRGB(190, 30, 35), Order = 75 },
	{ Id = "astin_dbx", Name = "British Vanguard DBX", Class = "SUV", Tier = "High", TopSpeed = 181, ZeroToSixty = 4.3, Handling = 0.66, Price = 450000, Color = Color3.fromRGB(88, 92, 98), Order = 76 },
	{ Id = "ferrara_california", Name = "Rosso Rampante Californa", Class = "Supercar", Tier = "High", TopSpeed = 193, ZeroToSixty = 3.8, Handling = 0.84, Price = 650000, Color = Color3.fromRGB(20, 21, 24), Order = 77 },
	{ Id = "bugotti_veyron", Name = "Velocité Noir Veyrun 16.4", Class = "Hypercar", Tier = "High", TopSpeed = 253, ZeroToSixty = 2.5, Handling = 0.86, Price = 5000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(110, 20, 30), Order = 78 },
	-- owner (2026-10-22): the 5 Series and E Series ladders; no models of their own yet (the M5s
	-- share the G30 5 Series body, the E63 S the E-Class body, which is an E63 S model)
	{ Id = "bnw_m5_f10", Name = "Bavarica Werkz M5 F10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.2, Handling = 0.74, Price = 145000, Color = Color3.fromRGB(26, 44, 82), Order = 80, Model = "bnw_540i" },
	{ Id = "bnw_m5_f90", Name = "Bavarica Werkz M5 F90", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 3.1, Handling = 0.79, Price = 165000, Color = Color3.fromRGB(88, 92, 98), Order = 81, Model = "bnw_540i" },
	{ Id = "bentz_e63s", Name = "Tri-Star Silber E63 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.3, Handling = 0.76, Price = 175000, Color = Color3.fromRGB(20, 21, 24), Order = 82, Model = "bentz_e400" },
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
-- Series, trims and levels (owner, 2026-10-30: "dealership with trims like Midnight Racing")
--   * a series is one car line; its cars are the trims, cheapest first (the dealer's trim chips)
--   * every car is sold at Legends Motors once you reach its level (Cars.Levels); no car is market
--     only any more and you don't need the trim before (levels only). The car market is a second
--     way to get cars.
--   * a line with one car gets a SPORT and a TOP trim (owner: "add extra trims"): the same body,
--     a little faster and dearer, 5 and 10 levels on
---------------------------------------------------------------------
export type Series = { Name: string, Ids: { string }, Brand: string? }

Cars.TrimSteps = {
	{ Key = "sport", Trim = "SPORT", Label = "Sport", Levels = 5, Price = 1.3, Speed = 1.05, Accel = 0.92, Grip = 0.03, FreePrice = 8000 },
	{ Key = "top", Trim = "TOP", Label = "Top", Levels = 10, Price = 1.7, Speed = 1.1, Accel = 0.85, Grip = 0.06, FreePrice = 15000 },
}

-- the level each car opens at the dealer (by price; each better trim at least 5 levels on; the top
-- cars at 40 - 60, nothing above 60 for now: the owner will add cars above the Veyrun later)
Cars.Levels = {
	suzaki_swift = 1, toyoka_belta = 1, toyoka_camri = 1, toyoka_crown = 1, toyoka_alfard = 1,
	toyoka_lc200 = 1, toyoka_lc300 = 6, toyoka_chaser = 3, toyoka_supra_mk4 = 6,
	kio_ev6 = 1, byt_seal = 1, byt_u8 = 10,
	nisun_350z = 1, nisun_r34 = 6, nisun_gtr = 15,
	mazdo_rx7 = 1, mazdo_rx8 = 1,
	bnw_330i_g20 = 3, bnw_m3_f80 = 8, bnw_m3_e92 = 3, bnw_m4_f82 = 8,
	bnw_530i = 3, bnw_540i = 8, bnw_m5_e60 = 13, bnw_m5_f10 = 18, bnw_m5_f90 = 23,
	bnw_m6_v10 = 6, bnw_m8gc = 11, bnw_750li = 6, bnw_x6 = 6, bnw_x7 = 6,
	bentz_190e = 3, bentz_cla45 = 3, bentz_cls63s = 6,
	bentz_e300 = 3, bentz_e400 = 8, bentz_e63s = 13,
	bentz_s65_w221 = 6, bentz_s63 = 11, bentz_s680 = 32,
	bentz_gle53 = 10, bentz_g63 = 10, brabos_g63 = 32, bentz_gls = 25, bentz_sl65bs = 20, bentz_sls = 25,
	dodger_challenger = 6, bentz_gt63s = 10,
	chevo_camaro = 3, chevo_c6 = 3, chevo_c7 = 8,
	xiaomo_su7 = 6,
	lexis_lc500 = 10, lexis_lx700 = 10, lexis_lfa = 40,
	maseroti_levante = 6,
	porsha_boxster = 3, porsha_panamera = 10, porsha_gt3 = 25,
	astin_dbx = 15, astin_db9 = 15, astin_vantage = 15,
	audy_r8 = 15,
	ferrara_f430 = 20, ferrara_california = 20, ferrara_599 = 20, ferrara_458 = 25,
	lambrini_lp570 = 20, lambrini_lp640 = 32, lambrini_lp700 = 37, lambrini_lp750 = 48, lambrini_svj = 53, lambrini_svj63 = 58,
	lambrini_urus = 32, lambrini_countach = 40,
	mclaran_12c = 20,
	bentlee_contgt = 25, bentlee_bentayga = 25,
	rolls_wraith = 32, rolls_cullinan = 40,
	bugotti_veyron = 50, -- (its SPORT is 55 and TOP 60: owner, 2026-10-31, "cap it at 60")
} :: { [string]: number }

Cars.Series = {
	{ Name = "SOMPACT SWIFF", Ids = { "suzaki_swift" } },
	{ Name = "APEX BELTO", Ids = { "toyoka_belta" } },
	{ Name = "APEX CAMRI", Ids = { "toyoka_camri" } },
	{ Name = "APEX CROWNE", Ids = { "toyoka_crown" } },
	{ Name = "APEX ALFARD", Ids = { "toyoka_alfard" } },
	{ Name = "APEX LAND CRUZER", Ids = { "toyoka_lc200", "toyoka_lc300" } },
	{ Name = "APEX CHASOR", Ids = { "toyoka_chaser" } },
	{ Name = "APEX SUPRO", Ids = { "toyoka_supra_mk4" } },
	{ Name = "ORIENT EV6", Ids = { "kio_ev6" } },
	{ Name = "DREAM-BUILD VOLT SEAL", Ids = { "byt_seal" } },
	{ Name = "DREAM-BUILD VOLT YANGWONG U8", Ids = { "byt_u8" } },
	{ Name = "HORIZON 350Z", Ids = { "nisun_350z" } },
	{ Name = "HORIZON GT-R", Ids = { "nisun_r34", "nisun_gtr" } },
	{ Name = "AHURA RX-7", Ids = { "mazdo_rx7" } },
	{ Name = "AHURA RX-8", Ids = { "mazdo_rx8" } },
	{ Name = "BAVARICA WERKZ 3 SERIES", Ids = { "bnw_330i_g20", "bnw_m3_f80" } },
	{ Name = "BAVARICA WERKZ M3 COUPE & M4", Ids = { "bnw_m3_e92", "bnw_m4_f82" } },
	{ Name = "BAVARICA WERKZ 5 SERIES", Ids = { "bnw_530i", "bnw_540i", "bnw_m5_e60", "bnw_m5_f10", "bnw_m5_f90" } },
	{ Name = "BAVARICA WERKZ M6 & M8", Ids = { "bnw_m6_v10", "bnw_m8gc" } },
	{ Name = "BAVARICA WERKZ 7 SERIES", Ids = { "bnw_750li" } },
	{ Name = "BAVARICA WERKZ X6", Ids = { "bnw_x6" } },
	{ Name = "BAVARICA WERKZ X7", Ids = { "bnw_x7" } },
	{ Name = "TRI-STAR SILBER 190E", Ids = { "bentz_190e" } },
	{ Name = "TRI-STAR SILBER CLA", Ids = { "bentz_cla45" } },
	{ Name = "TRI-STAR SILBER CLS", Ids = { "bentz_cls63s" } },
	{ Name = "TRI-STAR SILBER E-CLASS", Ids = { "bentz_e300", "bentz_e400", "bentz_e63s" } },
	{ Name = "TRI-STAR SILBER S-CLASS", Ids = { "bentz_s65_w221", "bentz_s63", "bentz_s680" } },
	{ Name = "TRI-STAR SILBER GLE", Ids = { "bentz_gle53" } },
	{ Name = "TRI-STAR SILBER G-CLASS", Ids = { "bentz_g63", "brabos_g63" } },
	{ Name = "TRI-STAR SILBER MAYBECH GLS", Ids = { "bentz_gls" } },
	{ Name = "TRI-STAR SILBER SL", Ids = { "bentz_sl65bs" } },
	{ Name = "TRI-STAR SILBER SLS", Ids = { "bentz_sls" } },
	{ Name = "HEMI CHALLENJER", Ids = { "dodger_challenger" } },
	{ Name = "HEMI SRT", Ids = { "bentz_gt63s" } },
	{ Name = "GOLDEN CAMARO", Ids = { "chevo_camaro" } },
	{ Name = "GOLDEN CORVETTE", Ids = { "chevo_c6", "chevo_c7" } },
	{ Name = "HYPERSPEED TECH SU7", Ids = { "xiaomo_su7" } },
	{ Name = "STEALTH-APEX LC500", Ids = { "lexis_lc500" } },
	{ Name = "STEALTH-APEX LX700", Ids = { "lexis_lx700" } },
	{ Name = "STEALTH-APEX LFA", Ids = { "lexis_lfa" } },
	{ Name = "TRIDENT MOTORS LEVANTO", Ids = { "maseroti_levante" } },
	{ Name = "STUTTGART BOXSTER", Ids = { "porsha_boxster" } },
	{ Name = "STUTTGART PANAMERA", Ids = { "porsha_panamera" } },
	{ Name = "STUTTGART 911 GT3", Ids = { "porsha_gt3" } },
	{ Name = "BRITISH VANGUARD DBX", Ids = { "astin_dbx" } },
	{ Name = "BRITISH VANGUARD VANQUISH", Ids = { "astin_db9" } },
	{ Name = "BRITISH VANGUARD VANTAGE", Ids = { "astin_vantage" } },
	{ Name = "PRECISION R8", Ids = { "audy_r8" } },
	{ Name = "ROSSO RAMPANTE F430", Ids = { "ferrara_f430" } },
	{ Name = "ROSSO RAMPANTE CALIFORNA", Ids = { "ferrara_california" } },
	{ Name = "ROSSO RAMPANTE 599", Ids = { "ferrara_599" } },
	{ Name = "ROSSO RAMPANTE 458", Ids = { "ferrara_458" } },
	{ Name = "ENFURECIDO GALLARDO", Ids = { "lambrini_lp570" } },
	{ Name = "ENFURECIDO MURCIELAGO", Ids = { "lambrini_lp640" } },
	{ Name = "ENFURECIDO AVENTADOR", Ids = { "lambrini_lp700", "lambrini_lp750", "lambrini_svj", "lambrini_svj63" } },
	{ Name = "ENFURECIDO URUS", Ids = { "lambrini_urus" } },
	{ Name = "ENFURECIDO COUNTACH", Ids = { "lambrini_countach" } },
	{ Name = "SPEEDMARK 12C", Ids = { "mclaran_12c" } },
	{ Name = "SOVEREIGN CONTINENTAL", Ids = { "bentlee_contgt" } },
	{ Name = "SOVEREIGN BENTAYGA", Ids = { "bentlee_bentayga" } },
	{ Name = "ECSTASY WRAITH", Ids = { "rolls_wraith" } },
	{ Name = "ECSTASY PHANTOM", Ids = { "rolls_cullinan" } },
	{ Name = "VELOCITÉ NOIR VEYRUN", Ids = { "bugotti_veyron" } },
} :: { Series }

-- a car left out of the series list gets one of its own
for _, spec in list do
	local found = false
	for _, series in Cars.Series do
		if table.find(series.Ids, spec.Id) then
			found = true
			break
		end
	end
	if not found then
		table.insert(Cars.Series, { Name = Cars.upper(spec.Name), Ids = { spec.Id } })
	end
end

-- the SPORT and TOP trims of every one-car line (the same body: Model is the base car's)
local function round(n: number, step: number): number
	return math.floor(n / step + 0.5) * step
end
for _, series in Cars.Series do
	if #series.Ids ~= 1 then
		continue
	end
	local base = Cars.ById[series.Ids[1]]
	base.Trim = "BASE"
	local baseLevel = Cars.Levels[base.Id] or 1
	for i, step in Cars.TrimSteps do
		local spec: CarSpec = {
			Id = base.Id .. "_" .. step.Key,
			Name = base.Name .. " " .. step.Label,
			Class = base.Class,
			Tier = base.Tier,
			TopSpeed = math.floor(base.TopSpeed * step.Speed + 0.5),
			ZeroToSixty = math.max(2, round(base.ZeroToSixty * step.Accel, 0.1)),
			Handling = math.min(0.98, base.Handling + step.Grip),
			Price = if base.Price > 0 then round(base.Price * step.Price, 1000) else step.FreePrice,
			Color = base.Color,
			Accent = base.Accent,
			Order = base.Order + i / 10,
			Electric = base.Electric,
			Model = base.Model or base.Id,
			Trim = step.Trim,
			BaseId = base.Id,
		}
		table.insert(list, spec)
		Cars.ById[spec.Id] = spec
		Cars.Levels[spec.Id] = baseLevel + step.Levels
		table.insert(series.Ids, spec.Id)
	end
end

-- brand XP is saved by brand name: the old names it was saved under (Brands.lua moves them)
Cars.OldBrands = {
	BNW = "BAVARICA WERKZ", MERCER = "TRI-STAR SILBER", BRABOS = "ROCKET", TOYOKA = "APEX",
	LEXIS = "STEALTH-APEX", NISUN = "HORIZON", MAZDO = "AHURA", SUZAKI = "SOMPACT", KIO = "ORIENT",
	BYT = "DREAM-BUILD VOLT", XIAOMO = "HYPERSPEED TECH", CHEVO = "GOLDEN", DODGER = "HEMI",
	PORSHA = "STUTTGART", AUDY = "PRECISION", ["ASTIN MARLIN"] = "BRITISH VANGUARD",
	FERRARA = "ROSSO RAMPANTE", LAMBRINI = "ENFURECIDO", MASEROTI = "TRIDENT MOTORS",
	MCLARAN = "SPEEDMARK", BENTLEE = "SOVEREIGN", ["ROLLS ROYAL"] = "ECSTASY",
	BUGOTTI = "VELOCITÉ NOIR",
} :: { [string]: string }

-- each series' brand (owner, 2026-10-22: "fit each car into the brands"): the make its first
-- car's name starts with (Cars.Makes); the garage and the dealer list brands, then their series
for _, series in Cars.Series do
	local first = Cars.ById[series.Ids[1]]
	series.Brand = Cars.upper(if first then Cars.makeOf(first.Name) else series.Name)
end

Cars.SeriesOf = {} :: { [string]: { series: Series, index: number } }
for _, series in Cars.Series do
	for i, id in series.Ids do
		Cars.SeriesOf[id] = { series = series, index = i }
	end
end

-- the short name of a car's trim for the dealer's trim chips (BASE / SPORT / TOP, or what its
-- name adds to the brand: "M5 F90", "AVENTADOR SV LP750-4")
function Cars.trimLabel(id: string): string
	local spec = Cars.ById[id]
	if not spec then
		return ""
	end
	if spec.Trim then
		return spec.Trim
	end
	local at = Cars.SeriesOf[id]
	local brand = if at and at.series.Brand then at.series.Brand else ""
	local name = Cars.upper(spec.Name)
	if string.sub(name, 1, #brand + 1) == brand .. " " then
		name = string.sub(name, #brand + 2)
	end
	return name
end

-- every car is sold at the dealer now (kept so old callers still work)
function Cars.isMarketOnly(_id: string): boolean
	return false
end

-- the level a car opens at the dealer (`bonus`: levels off for the player's brand level,
-- Config.brandTrimBonus; never below 1)
function Cars.requiredLevel(id: string, bonus: number?): number
	local need = Cars.Levels[id] or 1
	if need <= 1 then
		return 1
	end
	return math.max(1, need - (bonus or 0))
end

-- the trim before this one in its series (nil for the first)
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
