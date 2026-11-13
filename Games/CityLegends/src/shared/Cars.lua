--[[
	Car roster. Names are fictional look-alikes of real cars so the game is safe to publish.

	Stats
	  TopSpeed   : mph
	  ZeroToSixty: seconds
	  Handling   : 0..1 (grip + steering response)
	  Price      : $ (0 = free starter)

	(2026-11-03, owner: "car class grades and car levels") Cars no longer open by player level: each
	car has a class from its Performance Index (CarStats.pi, the ranges in Config.CarClasses) and only
	class X needs a player level (Config.CarClasses.XLevel). Ten cars were retired from sale (Retired:
	owners keep and drive them) and the A45 S waits for its model (Pending: not sold until imported).
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
	Retired: boolean?, -- no longer sold (owners keep it, it still drives; not in the dealer, market, traffic)
	Pending: boolean?, -- not sold yet: waits for its 3D model (no blocky placeholder in the dealer)
	-- (owner, 2026-11-07: the cheapest class S2 and R cars went up on purpose, over their real price, so
	-- the fast cars aren't cheap: S2 from $350,000, R from $850,000. Trims: Cars.TrimPrices;
	-- tools/carlevels_test.luau checks both)
	PriceSource: string?, -- what Price is (2026-11-07, real prices, table in City Legends.md): "new" the US dealer
	-- price, "used" the US used market, "collector" the market value
	StatPrice: number?, -- the old game price: the show numbers worked from it stay the same (CarStats)
	RearBias: boolean?, -- an all-wheel-drive car that sends more to the rear and slides like a rear-drive one
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

-- the makes (owner, 2026-10-31: the new brand names; 2026-11-06: fake model names too, ids stay)
Cars.Makes = {
	"Bavarica Werkz", "Tri-Star Silber", "Rocket", "Apex", "Stealth-Apex", "Horizon", "Ahura", "Sompact",
	"Orient", "Dream-Build Volt", "HyperSpeed Tech", "Golden", "Ironclad", "Stuttgart", "Precision",
	"British Vanguard", "Rosso Rampante", "Enfurecido", "Trident Motors", "Speedmark", "Sovereign",
	"Ecstasy", "Velocité Noir", "Dearborn",
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
	{ Id = "suzaki_swift", Name = "Sompact Zippa", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 9.5, Handling = 0.62, Price = 0, Color = Color3.fromRGB(200, 30, 36), Order = 1 },
	{ Id = "toyoka_belta", Name = "Apex Metro", Class = "Sedan", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 10.5, Handling = 0.55, Price = 6000, Color = Color3.fromRGB(196, 199, 204), Order = 2 },
	{ Id = "kio_ev6", Name = "Orient Voltra", Class = "SUV", Tier = "Starter", TopSpeed = 93, ZeroToSixty = 9.5, Handling = 0.5, Price = 38000, PriceSource = "new", StatPrice = 0, Color = Color3.fromRGB(235, 236, 238), Order = 3, Electric = true },
	{ Id = "byt_seal", Name = "Dream-Build Volt Orca EV", Class = "Sedan", Tier = "Starter", TopSpeed = 100, ZeroToSixty = 7.3, Handling = 0.55, Price = 14000, Color = Color3.fromRGB(40, 90, 160), Order = 4, Electric = true },
	{ Id = "toyoka_camri", Name = "Apex Cambria", Class = "Sedan", Tier = "Starter", TopSpeed = 135, ZeroToSixty = 7.6, Handling = 0.58, Price = 29500, PriceSource = "new", StatPrice = 16000, Color = Color3.fromRGB(20, 21, 24), Order = 5 },
	{ Id = "toyoka_crown", Name = "Apex Regent Sport", Class = "Sedan", Tier = "Starter", TopSpeed = 143, ZeroToSixty = 6.9, Handling = 0.6, Price = 22000, Color = Color3.fromRGB(235, 236, 238), Order = 6 },
	{ Id = "toyoka_alfard", Name = "Apex Grand Lounge", Class = "SUV", Tier = "Starter", TopSpeed = 112, ZeroToSixty = 8.5, Handling = 0.45, Price = 40500, PriceSource = "new", StatPrice = 28000, Color = Color3.fromRGB(20, 21, 24), Order = 7 },
	{ Id = "toyoka_lc200", Name = "Apex J200", Class = "SUV", Tier = "Starter", TopSpeed = 130, ZeroToSixty = 6.9, Handling = 0.46, Price = 75000, PriceSource = "used", StatPrice = 35000, Color = Color3.fromRGB(235, 236, 238), Order = 8 },
	{ Id = "nisun_350z", Name = "Horizon Z33", Class = "Coupe", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.4, Handling = 0.72, Price = 12000, PriceSource = "used", StatPrice = 38000, Color = Color3.fromRGB(220, 170, 30), Order = 9 },
	{ Id = "mazdo_rx7", Name = "Ahura FD Rotary", Class = "Coupe", Tier = "Starter", TopSpeed = 156, ZeroToSixty = 5.0, Handling = 0.82, Price = 42500, PriceSource = "used", StatPrice = 42000, Color = Color3.fromRGB(235, 236, 238), Order = 10 },
	{ Id = "mazdo_rx8", Name = "Ahura SE3P Rotary", Class = "Coupe", Tier = "Starter", TopSpeed = 146, ZeroToSixty = 6.4, Handling = 0.8, Price = 45000, Color = Color3.fromRGB(190, 30, 35), Order = 11 },

	-- Mid tier
	{ Id = "bnw_530i", Name = "Bavarica Werkz G30 2.0", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.9, Handling = 0.66, Price = 52000, Color = Color3.fromRGB(20, 21, 24), Order = 12 },
	{ Id = "bnw_540i", Name = "Bavarica Werkz G30 3.0", Class = "Sedan", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 4.7, Handling = 0.68, Price = 26500, PriceSource = "used", StatPrice = 42000, Color = Color3.fromRGB(26, 44, 82), Order = 13 },
	{ Id = "bentz_e300", Name = "Tri-Star Silber W213 2.0", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 6.1, Handling = 0.63, Price = 70000, Color = Color3.fromRGB(88, 92, 98), Order = 14 },
	{ Id = "bentz_e400", Name = "Tri-Star Silber W213 3.0", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.9, Handling = 0.66, Price = 20000, PriceSource = "used", StatPrice = 85000, Color = Color3.fromRGB(20, 21, 24), Order = 15 },
	{ Id = "bnw_330i_g20", Name = "Bavarica Werkz G20 Sport", Class = "Sedan", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.3, Handling = 0.7, Price = 47500, PriceSource = "new", StatPrice = 40000, Color = Color3.fromRGB(40, 90, 160), Order = 16 },
	{ Id = "bnw_m3_e92", Name = "Bavarica Werkz E92 V8", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.4, Handling = 0.76, Price = 34000, PriceSource = "used", StatPrice = 90000, Color = Color3.fromRGB(235, 236, 238), Order = 17 },
	{ Id = "bnw_m3_f80", Name = "Bavarica Werkz F80", Class = "Sedan", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 4.0, Handling = 0.78, Price = 42500, PriceSource = "used", StatPrice = 110000, Color = Color3.fromRGB(220, 170, 30), Order = 18 },
	{ Id = "bnw_m4_f82", Name = "Bavarica Werkz F82", Class = "Coupe", Tier = "Mid", TopSpeed = 174, ZeroToSixty = 3.9, Handling = 0.8, Price = 42500, PriceSource = "used", StatPrice = 100000, Color = Color3.fromRGB(30, 80, 170), Order = 19 },
	{ Id = "bnw_m5_e60", Name = "Bavarica Werkz E60 V10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.4, Handling = 0.72, Price = 23000, PriceSource = "used", StatPrice = 125000, Color = Color3.fromRGB(165, 168, 172), Order = 20 },
	{ Id = "bnw_m6_v10", Name = "Bavarica Werkz E63 V10", Class = "Coupe", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.5, Handling = 0.73, Price = 25000, PriceSource = "used", StatPrice = 135000, Color = Color3.fromRGB(26, 44, 82), Order = 21 },
	{ Id = "bnw_m8gc", Name = "Bavarica Werkz F93 Fastback", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 3.0, Handling = 0.78, Price = 140000, PriceSource = "new", StatPrice = 210000, Color = Color3.fromRGB(26, 44, 82), Order = 22 },
	{ Id = "bentz_cla45", Name = "Tri-Star Silber C118 Turbo", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.0, Handling = 0.74, Price = 95000, Color = Color3.fromRGB(140, 145, 150), Order = 23 },
	{ Id = "bentz_cls63s", Name = "Tri-Star Silber C218 V8 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.6, Handling = 0.72, Price = 42500, PriceSource = "used", StatPrice = 160000, Color = Color3.fromRGB(20, 21, 24), Order = 24 },
	{ Id = "toyoka_supra_mk4", Name = "Apex JZA80", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 4.6, Handling = 0.76, Price = 100000, PriceSource = "collector", StatPrice = 140000, Color = Color3.fromRGB(220, 100, 20), Order = 25 },
	{ Id = "nisun_r34", Name = "Horizon BNR34", Class = "Coupe", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 4.9, Handling = 0.8, Price = 165000, PriceSource = "collector", StatPrice = 180000, Color = Color3.fromRGB(40, 60, 150), Order = 26 },
	{ Id = "dodger_challenger", Name = "Ironclad LC V8", Class = "Coupe", Tier = "Mid", TopSpeed = 175, ZeroToSixty = 4.2, Handling = 0.66, Price = 44500, PriceSource = "used", StatPrice = 115000, Color = Color3.fromRGB(176, 14, 18), Accent = Color3.fromRGB(16, 16, 18), Order = 27 },
	{ Id = "xiaomo_su7", Name = "HyperSpeed Tech S7", Class = "Sedan", Tier = "Mid", TopSpeed = 165, ZeroToSixty = 2.8, Handling = 0.78, Price = 32500, PriceSource = "new", StatPrice = 120000, Color = Color3.fromRGB(40, 90, 160), Order = 28, Electric = true },
	{ Id = "bnw_x6", Name = "Bavarica Werkz G06 Sport", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.2, Handling = 0.6, Price = 77500, PriceSource = "new", StatPrice = 130000, Color = Color3.fromRGB(20, 21, 24), Order = 29 },
	{ Id = "bnw_x7", Name = "Bavarica Werkz G07", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.5, Handling = 0.56, Price = 86500, PriceSource = "new", StatPrice = 175000, Color = Color3.fromRGB(235, 236, 238), Order = 30 },
	{ Id = "toyoka_lc300", Name = "Apex J300", Class = "SUV", Tier = "Mid", TopSpeed = 130, ZeroToSixty = 6.5, Handling = 0.5, Price = 79000, PriceSource = "new", StatPrice = 150000, Color = Color3.fromRGB(235, 236, 238), Order = 31 },
	{ Id = "lexis_lx700", Name = "Stealth-Apex J310", Class = "SUV", Tier = "Mid", TopSpeed = 137, ZeroToSixty = 6.4, Handling = 0.5, Price = 117000, PriceSource = "new", StatPrice = 245000, Color = Color3.fromRGB(12, 12, 14), Order = 32 },
	{ Id = "bentz_gle53", Name = "Tri-Star Silber C167 3.0", Class = "SUV", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 5.0, Handling = 0.62, Price = 93500, PriceSource = "new", StatPrice = 250000, Color = Color3.fromRGB(165, 168, 172), Order = 33 },
	{ Id = "bentz_g63", Name = "Tri-Star Silber W463 V8", Class = "SUV", Tier = "Mid", TopSpeed = 149, ZeroToSixty = 4.4, Handling = 0.52, Price = 197000, PriceSource = "new", StatPrice = 260000, Color = Color3.fromRGB(20, 21, 24), Order = 34 },
	{ Id = "byt_u8", Name = "Dream-Build Volt Titan", Class = "SUV", Tier = "Mid", TopSpeed = 124, ZeroToSixty = 3.6, Handling = 0.55, Price = 148000, PriceSource = "new", StatPrice = 290000, Color = Color3.fromRGB(20, 21, 24), Order = 35, Electric = true },
	{ Id = "porsha_panamera", Name = "Stuttgart 971 Turbo S", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.0, Handling = 0.8, Price = 245000, PriceSource = "new", StatPrice = 300000, Color = Color3.fromRGB(88, 92, 98), Order = 36 },
	{ Id = "chevo_camaro", Name = "Golden Six Supercharged", Class = "Coupe", Tier = "Starter", TopSpeed = 184, ZeroToSixty = 3.9, Handling = 0.74, Price = 45000, PriceSource = "used", StatPrice = 36000, Color = Color3.fromRGB(230, 180, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 37 },
	{ Id = "chevo_c6", Name = "Golden Sting 6", Class = "Coupe", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 4.2, Handling = 0.8, Price = 78000, Color = Color3.fromRGB(26, 44, 82), Order = 38 },
	{ Id = "porsha_boxster", Name = "Stuttgart 982", Class = "Coupe", Tier = "Mid", TopSpeed = 177, ZeroToSixty = 4.2, Handling = 0.9, Price = 76500, PriceSource = "new", StatPrice = 92000, Color = Color3.fromRGB(200, 200, 206), Order = 39 },
	{ Id = "chevo_c7", Name = "Golden Sting 7", Class = "Coupe", Tier = "Mid", TopSpeed = 180, ZeroToSixty = 3.8, Handling = 0.84, Price = 67500, PriceSource = "used", StatPrice = 112000, Color = Color3.fromRGB(200, 10, 20), Order = 40 },
	{ Id = "bentz_s63", Name = "Tri-Star Silber W222 V12", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 3.9, Handling = 0.7, Price = 85000, PriceSource = "used", StatPrice = 280000, Color = Color3.fromRGB(20, 21, 24), Order = 41 },
	{ Id = "bentz_gt63s", Name = "Ironclad Supercharged", Class = "Sedan", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.8, Price = 72500, PriceSource = "used", StatPrice = 320000, Color = Color3.fromRGB(88, 92, 98), Order = 42 },

	-- High tier
	{ Id = "nisun_gtr", Name = "Horizon R35", Class = "Coupe", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 2.9, Handling = 0.86, Price = 105000, PriceSource = "used", StatPrice = 420000, Color = Color3.fromRGB(235, 236, 238), Order = 43 },
	{ Id = "astin_db9", Name = "British Vanguard Vanta V12", Class = "Coupe", Tier = "Mid", TopSpeed = 201, ZeroToSixty = 3.8, Handling = 0.76, Price = 50000, PriceSource = "used", StatPrice = 450000, Color = Color3.fromRGB(26, 44, 82), Order = 44 },
	{ Id = "astin_vantage", Name = "British Vanguard Vela V12", Class = "Coupe", Tier = "Mid", TopSpeed = 195, ZeroToSixty = 3.5, Handling = 0.82, Price = 125000, PriceSource = "used", StatPrice = 500000, Color = Color3.fromRGB(36, 70, 52), Order = 45 },
	{ Id = "ferrara_f430", Name = "Rosso Rampante F131", Class = "Supercar", Tier = "Mid", TopSpeed = 196, ZeroToSixty = 3.6, Handling = 0.86, Price = 130000, PriceSource = "used", StatPrice = 600000, Color = Color3.fromRGB(200, 10, 20), Order = 46 },
	{ Id = "bentz_sl65bs", Name = "Tri-Star Silber R230 V12 Track", Class = "Coupe", Tier = "High", TopSpeed = 199, ZeroToSixty = 3.8, Handling = 0.82, Price = 350000, PriceSource = "collector", StatPrice = 700000, Color = Color3.fromRGB(18, 18, 20), Order = 47 },
	{ Id = "lambrini_lp570", Name = "Enfurecido L140 Leggera", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.88, Price = 350000, PriceSource = "collector", StatPrice = 750000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 48 },
	{ Id = "audy_r8", Name = "Precision Type 42 V10", Class = "Supercar", Tier = "Mid", TopSpeed = 188, ZeroToSixty = 4.4, Handling = 0.86, Price = 110000, PriceSource = "used", StatPrice = 550000, Color = Color3.fromRGB(165, 168, 172), Accent = Color3.fromRGB(16, 16, 18), Order = 49 },
	-- (2026-11-09) the lighter track version of the first Type 42, its own model (the 2011 car, 333 built)
	{ Id = "audy_r8_lw", Name = "Precision Type 42 V10 Lightweight", Class = "Supercar", Tier = "Mid", TopSpeed = 199, ZeroToSixty = 3.5, Handling = 0.9, Price = 120000, PriceSource = "collector", StatPrice = 600000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 49.5 },
	-- (2026-11-09) the second-generation Type 42 (the 2016 car), its own line; class S2, so the S2 floor price
	{ Id = "audy_r8_4s", Name = "Precision 4S V10", Class = "Supercar", Tier = "High", TopSpeed = 205, ZeroToSixty = 2.9, Handling = 0.9, Price = 350000, PriceSource = "used", StatPrice = 700000, Color = Color3.fromRGB(200, 28, 24), Accent = Color3.fromRGB(16, 16, 18), Order = 49.7 },
	{ Id = "mclaran_12c", Name = "Speedmark P11 Spider", Class = "Supercar", Tier = "High", TopSpeed = 207, ZeroToSixty = 3.1, Handling = 0.9, Price = 350000, PriceSource = "used", StatPrice = 800000, Color = Color3.fromRGB(226, 84, 8), Order = 50 },
	{ Id = "ferrara_599", Name = "Rosso Rampante F141", Class = "Supercar", Tier = "High", TopSpeed = 205, ZeroToSixty = 3.5, Handling = 0.84, Price = 165000, PriceSource = "used", StatPrice = 850000, Color = Color3.fromRGB(20, 21, 24), Order = 51 },
	{ Id = "ferrara_458", Name = "Rosso Rampante F142", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.3, Handling = 0.9, Price = 900000, Color = Color3.fromRGB(200, 10, 20), Order = 52 },
	{ Id = "bentz_sls", Name = "Tri-Star Silber C197 Wingdoor", Class = "Supercar", Tier = "High", TopSpeed = 197, ZeroToSixty = 3.7, Handling = 0.86, Price = 250000, PriceSource = "collector", StatPrice = 950000, Color = Color3.fromRGB(235, 236, 238), Order = 53 },
	{ Id = "porsha_gt3", Name = "Stuttgart 991.2 Track", Class = "Supercar", Tier = "High", TopSpeed = 193, ZeroToSixty = 3.2, Handling = 0.95, Price = 190000, PriceSource = "used", StatPrice = 1000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 54 },
	{ Id = "bentlee_contgt", Name = "Sovereign Grand Tourer", Class = "Coupe", Tier = "High", TopSpeed = 198, ZeroToSixty = 3.6, Handling = 0.74, Price = 345000, PriceSource = "new", StatPrice = 1100000, Color = Color3.fromRGB(26, 44, 82), Order = 55 },
	{ Id = "bentlee_bentayga", Name = "Sovereign Highlands", Class = "SUV", Tier = "High", TopSpeed = 187, ZeroToSixty = 4.0, Handling = 0.6, Price = 227000, PriceSource = "new", StatPrice = 1200000, Color = Color3.fromRGB(20, 21, 24), Order = 56 },
	{ Id = "lambrini_urus", Name = "Enfurecido Brava (old)", Class = "SUV", Tier = "High", TopSpeed = 190, ZeroToSixty = 3.5, Handling = 0.7, Price = 1500000, Color = Color3.fromRGB(220, 170, 30), Order = 57 },
	{ Id = "brabos_g63", Name = "Rocket W463 800", Class = "SUV", Tier = "High", TopSpeed = 149, ZeroToSixty = 3.9, Handling = 0.55, Price = 390000, PriceSource = "new", StatPrice = 1600000, Color = Color3.fromRGB(12, 12, 14), Accent = Color3.fromRGB(255, 140, 0), Order = 58 },
	{ Id = "rolls_wraith", Name = "Ecstasy Nocturne", Class = "Coupe", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 175000, PriceSource = "used", StatPrice = 2000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(165, 168, 172), Order = 59 },
	{ Id = "rolls_cullinan", Name = "Ecstasy Grandeur", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 5.1, Handling = 0.55, Price = 432000, PriceSource = "new", StatPrice = 2500000, Color = Color3.fromRGB(235, 236, 238), Order = 60 },
	{ Id = "lambrini_lp700", Name = "Enfurecido LB834", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.9, Handling = 0.88, Price = 550000, PriceSource = "used", StatPrice = 2200000, Color = Color3.fromRGB(235, 236, 238), Order = 61 },
	{ Id = "lexis_lfa", Name = "Stealth-Apex V10 Halo", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.6, Handling = 0.92, Price = 900000, PriceSource = "collector", StatPrice = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 62 },
	{ Id = "lexis_lfa_circuit", Name = "Stealth-Apex V10 Halo Circuit", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.5, Handling = 0.95, Price = 1700000, PriceSource = "collector", StatPrice = 3600000, Color = Color3.fromRGB(240, 110, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 62.5 },
	{ Id = "lambrini_lp750", Name = "Enfurecido LB834 ZV", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.8, Handling = 0.92, Price = 900000, PriceSource = "used", StatPrice = 3500000, Color = Color3.fromRGB(120, 200, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 63 },
	-- the Lamborghini imports (2026-11-04): the Gallardo Spyder, the Huracan line, the Revuelto
	{ Id = "lambrini_lp560", Name = "Enfurecido L140 Spyder", Class = "Supercar", Tier = "Mid", TopSpeed = 201, ZeroToSixty = 3.9, Handling = 0.85, Price = 120000, PriceSource = "used", StatPrice = 680000, Color = Color3.fromRGB(236, 214, 40), Accent = Color3.fromRGB(16, 16, 18), Order = 47.5 },
	{ Id = "lambrini_huracan", Name = "Enfurecido LB724", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 2.9, Handling = 0.92, Price = 550000, PriceSource = "used", StatPrice = 1300000, Color = Color3.fromRGB(226, 74, 24), Accent = Color3.fromRGB(16, 16, 18), Order = 85 },
	{ Id = "lambrini_performante", Name = "Enfurecido LB724 Aero Spyder", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.1, Handling = 0.93, Price = 600000, PriceSource = "used", StatPrice = 1550000, Color = Color3.fromRGB(196, 18, 28), Accent = Color3.fromRGB(16, 16, 18), Order = 86 },
	{ Id = "lambrini_sto", Name = "Enfurecido LB724 VTZ", Class = "Supercar", Tier = "High", TopSpeed = 193, ZeroToSixty = 3.0, Handling = 0.95, Price = 850000, PriceSource = "used", StatPrice = 1800000, Color = Color3.fromRGB(190, 26, 16), Accent = Color3.fromRGB(16, 16, 18), Order = 87 },
	{ Id = "lambrini_sterrato", Name = "Enfurecido LB724 Rally", Class = "Supercar", Tier = "High", TopSpeed = 162, ZeroToSixty = 3.4, Handling = 0.8, Price = 320000, PriceSource = "used", StatPrice = 1450000, Color = Color3.fromRGB(84, 118, 62), Accent = Color3.fromRGB(16, 16, 18), Order = 88 },
	{ Id = "lambrini_revuelto", Name = "Enfurecido LB744", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.5, Handling = 0.96, Price = 1200000, PriceSource = "new", StatPrice = 6000000, Color = Color3.fromRGB(232, 234, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 89 },
	-- the second import job (2026-11-06): the LP670-4 SV, the Urus Performante, the 458 Spider and Speciale
	{ Id = "lambrini_lp670", Name = "Enfurecido L147 ZV", Class = "Supercar", Tier = "High", TopSpeed = 212, ZeroToSixty = 3.2, Handling = 0.9, Price = 700000, PriceSource = "collector", StatPrice = 2400000, Color = Color3.fromRGB(236, 74, 16), Accent = Color3.fromRGB(16, 16, 18), Order = 64.5 },
	{ Id = "lambrini_urusp", Name = "Enfurecido Brava", Class = "SUV", Tier = "High", TopSpeed = 190, ZeroToSixty = 3.2, Handling = 0.74, Price = 285000, PriceSource = "used", StatPrice = 1900000, Color = Color3.fromRGB(226, 190, 96), Accent = Color3.fromRGB(16, 16, 18), Order = 57.5 },
	{ Id = "ferrara_458spider", Name = "Rosso Rampante F142 Spider", Class = "Supercar", Tier = "High", TopSpeed = 199, ZeroToSixty = 3.3, Handling = 0.89, Price = 250000, PriceSource = "used", StatPrice = 1000000, Color = Color3.fromRGB(232, 196, 60), Accent = Color3.fromRGB(16, 16, 18), Order = 52.2 },
	{ Id = "ferrara_458speciale", Name = "Rosso Rampante F142 Speciale", Class = "Supercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.0, Handling = 0.94, Price = 520000, PriceSource = "collector", StatPrice = 1250000, Color = Color3.fromRGB(226, 40, 22), Accent = Color3.fromRGB(16, 16, 18), Order = 52.5 },
	-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of the Aventador line, on their own new models
	{ Id = "lambrini_svj", Name = "Enfurecido LB834 ZVX", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.7, Handling = 0.95, Price = 1200000, PriceSource = "used", StatPrice = 4200000, Color = Color3.fromRGB(150, 112, 78), Accent = Color3.fromRGB(16, 16, 18), Order = 83 },
	{ Id = "lambrini_svj63", Name = "Enfurecido LB834 ZVX 63", Class = "Hypercar", Tier = "High", TopSpeed = 217, ZeroToSixty = 2.7, Handling = 0.96, Price = 1250000, PriceSource = "collector", StatPrice = 5500000, Color = Color3.fromRGB(64, 67, 72), Accent = Color3.fromRGB(200, 16, 16), Order = 84 },
	{ Id = "lambrini_lp640", Name = "Enfurecido L147 Roadster", Class = "Supercar", Tier = "High", TopSpeed = 211, ZeroToSixty = 3.3, Handling = 0.86, Price = 500000, PriceSource = "collector", StatPrice = 1800000, Color = Color3.fromRGB(255, 140, 0), Order = 64 },
	{ Id = "bnw_750li", Name = "Bavarica Werkz G12 Long", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.64, Price = 27500, PriceSource = "used", StatPrice = 150000, Color = Color3.fromRGB(20, 21, 24), Order = 66 },
	{ Id = "bentz_gls", Name = "Tri-Star Silber X167 Royale", Class = "SUV", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.8, Handling = 0.58, Price = 180000, PriceSource = "new", StatPrice = 1200000, Color = Color3.fromRGB(235, 235, 235), Order = 67 },
	{ Id = "bentz_s680", Name = "Tri-Star Silber Z223 Royale V12", Class = "Sedan", Tier = "High", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.62, Price = 245000, PriceSource = "new", StatPrice = 1600000, Color = Color3.fromRGB(110, 20, 30), Accent = Color3.fromRGB(215, 200, 170), Order = 68 },
	{ Id = "lambrini_countach", Name = "Enfurecido Classico 5000", Class = "Supercar", Tier = "High", TopSpeed = 179, ZeroToSixty = 5.6, Handling = 0.78, Price = 600000, PriceSource = "collector", StatPrice = 2500000, Color = Color3.fromRGB(235, 235, 235), Order = 69 },
	-- the cars of 2026-10-18
	{ Id = "toyoka_chaser", Name = "Apex JZX100 Tourer", Class = "Sedan", Tier = "Starter", TopSpeed = 155, ZeroToSixty = 5.6, Handling = 0.76, Price = 27500, PriceSource = "used", StatPrice = 30000, Color = Color3.fromRGB(200, 202, 206), Order = 71 },
	{ Id = "bentz_190e", Name = "Tri-Star Silber W201 Evo II", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 7.1, Handling = 0.74, Price = 280000, PriceSource = "collector", StatPrice = 80000, Color = Color3.fromRGB(20, 21, 24), Order = 72 },
	{ Id = "bentz_s65_w221", Name = "Tri-Star Silber W221 V8", Class = "Sedan", Tier = "Mid", TopSpeed = 155, ZeroToSixty = 4.4, Handling = 0.66, Price = 20000, PriceSource = "used", StatPrice = 140000, Color = Color3.fromRGB(235, 236, 238), Order = 73 },
	{ Id = "maseroti_levante", Name = "Trident Motors Maestrale GTS", Class = "SUV", Tier = "Mid", TopSpeed = 181, ZeroToSixty = 4.0, Handling = 0.64, Price = 42000, PriceSource = "used", StatPrice = 190000, Color = Color3.fromRGB(88, 92, 98), Order = 74 },
	{ Id = "lexis_lc500", Name = "Stealth-Apex Z100 V8", Class = "Coupe", Tier = "Mid", TopSpeed = 168, ZeroToSixty = 4.4, Handling = 0.78, Price = 101000, PriceSource = "new", StatPrice = 240000, Color = Color3.fromRGB(190, 30, 35), Order = 75 },
	{ Id = "astin_dbx", Name = "British Vanguard Highland", Class = "SUV", Tier = "High", TopSpeed = 181, ZeroToSixty = 4.3, Handling = 0.66, Price = 257000, PriceSource = "new", StatPrice = 450000, Color = Color3.fromRGB(88, 92, 98), Order = 76 },
	{ Id = "ferrara_california", Name = "Rosso Rampante F149 Riviera", Class = "Supercar", Tier = "Mid", TopSpeed = 193, ZeroToSixty = 3.8, Handling = 0.84, Price = 110000, PriceSource = "used", StatPrice = 650000, Color = Color3.fromRGB(20, 21, 24), Order = 77 },
	{ Id = "bugotti_veyron", Name = "Velocité Noir Origine", Class = "Hypercar", Tier = "High", TopSpeed = 253, ZeroToSixty = 2.5, Handling = 0.86, Price = 2100000, PriceSource = "collector", StatPrice = 5000000, Color = Color3.fromRGB(20, 21, 24), Accent = Color3.fromRGB(110, 20, 30), Order = 78 },
	-- the Chiroun line (owner, 2026-11-03): above the Veyrun, the most expensive cars; class X: player
	-- level 60 opens them (Config.CarClasses.XLevel), then they only cost money
	{ Id = "bugotti_chiron", Name = "Velocité Noir Éclair", Class = "Hypercar", Tier = "High", TopSpeed = 261, ZeroToSixty = 2.4, Handling = 0.88, Price = 3250000, PriceSource = "collector", StatPrice = 9500000, Color = Color3.fromRGB(28, 86, 190), Accent = Color3.fromRGB(20, 21, 24), Order = 85 },
	{ Id = "bugotti_chiron_pursport", Name = "Velocité Noir Éclair Pure", Class = "Hypercar", Tier = "High", TopSpeed = 218, ZeroToSixty = 2.3, Handling = 0.93, Price = 4000000, PriceSource = "collector", StatPrice = 11000000, Color = Color3.fromRGB(30, 100, 220), Accent = Color3.fromRGB(20, 21, 24), Order = 86 },
	{ Id = "bugotti_chiron_supersport", Name = "Velocité Noir Éclair Super Sport", Class = "Hypercar", Tier = "High", TopSpeed = 273, ZeroToSixty = 2.4, Handling = 0.87, Price = 4450000, PriceSource = "collector", StatPrice = 13000000, Color = Color3.fromRGB(236, 236, 238), Accent = Color3.fromRGB(20, 21, 24), Order = 87 },
	-- owner (2026-10-22): the 5 Series and E Series ladders; no models of their own yet (the M5s
	-- share the G30 5 Series body, the E63 S the E-Class body, which is an E63 S model)
	{ Id = "bnw_m5_f10", Name = "Bavarica Werkz F10", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 4.2, Handling = 0.74, Price = 35000, PriceSource = "used", StatPrice = 145000, Color = Color3.fromRGB(26, 44, 82), Order = 80, Model = "bnw_540i" },
	{ Id = "bnw_m5_f90", Name = "Bavarica Werkz F90", Class = "Sedan", Tier = "Mid", TopSpeed = 190, ZeroToSixty = 2.9, Handling = 0.79, Price = 67000, PriceSource = "used", StatPrice = 165000, Color = Color3.fromRGB(88, 92, 98), Order = 81 }, -- (its own model since 2026-11-10: the 2022 one; it used bnw_540i's)
	{ Id = "bentz_e63s", Name = "Tri-Star Silber W213 V8 S", Class = "Sedan", Tier = "Mid", TopSpeed = 186, ZeroToSixty = 3.3, Handling = 0.76, Price = 67500, PriceSource = "used", StatPrice = 175000, Color = Color3.fromRGB(20, 21, 24), Order = 82, Model = "bentz_e400" },
	-- owner (2026-11-03): the A45 S hot hatch, the small fast Tri-Star Silber in place of the CLA 45; a
	-- starter-pick car. Pending until the owner imports its model (then take Pending off)
	-- owner (2026-11-06): the third starter pick, an all-wheel-drive hot hatch that lets its tail out
	-- (`RearBias`)
	{ Id = "dearb_focus_rs", Name = "Dearborn C346 Rallye", Class = "Sedan", Tier = "Starter", TopSpeed = 165, ZeroToSixty = 4.5, Handling = 0.76, Price = 30000, PriceSource = "used", StatPrice = 42000, Color = Color3.fromRGB(60, 120, 200), Order = 7, RearBias = true },
	{ Id = "bentz_a45s", Name = "Tri-Star Silber W177 Turbo S", Class = "Sedan", Tier = "Starter", TopSpeed = 168, ZeroToSixty = 3.9, Handling = 0.79, Price = 86000, PriceSource = "new", StatPrice = 38000, Color = Color3.fromRGB(238, 190, 20), Order = 88, Pending = true },
}

-- the ten cars taken out of the game (owner, 2026-11-03): no longer sold anywhere, but a player who
-- owns one keeps it in the garage and can still drive and tune it
Cars.RETIRED = {
	suzaki_swift = true, toyoka_belta = true, toyoka_crown = true, byt_seal = true, mazdo_rx8 = true,
	bentz_e300 = true, bnw_530i = true, bentz_cla45 = true, chevo_c6 = true, -- (2026-11-06: the G20 is back, a starter pick)
	ferrara_458 = true, -- owner (2026-11-05): "remove 458 italia"
	lambrini_urus = true, -- owner (2026-11-06): one Urus only, see Cars.Swapped
} :: { [string]: boolean }

-- a retired car whose owners get another car instead (owner, 2026-11-06: "the one and only Urus"):
-- PlayerData moves everything saved on the old id to the new one on load, so nobody owns the old car
Cars.Swapped = {
	lambrini_urus = "lambrini_urusp",
} :: { [string]: string }
for _, spec in list do
	if Cars.RETIRED[spec.Id] then
		spec.Retired = true
	end
end

Cars.ById = {} :: { [string]: CarSpec }
for _, spec in list do
	Cars.ById[spec.Id] = spec
end

-- the free car and the fallback for an unknown id (owner, 2026-11-03: the Orient EV6, $0; it was the
-- Sompact Swiff)
Cars.StarterId = "kio_ev6"

-- the car whose imported model a car uses (its own id unless it borrows one)
function Cars.modelOf(id: string): string
	local spec = Cars.ById[id]
	return if spec and spec.Model then spec.Model else id
end

---------------------------------------------------------------------
-- Series, trims and levels (owner, 2026-10-30: "dealership with trims like Midnight Racing")
--   * a series is one car line; its cars are the trims, cheapest first (the dealer's trim chips)
--   * every car is sold at Legends Motors for its price (2026-11-03: no level locks, only class X
--     needs Config.CarClasses.XLevel); you don't need the trim before. The car market is a second
--     way to get cars.
--   * a line with one car gets a SPORT and a TOP trim (owner: "add extra trims"): the same body,
--     a little faster and dearer
---------------------------------------------------------------------
-- (TrimBase: a line of several cars whose first car keeps the SPORT / TOP trims it had as a one-car
-- line, so their owners keep them: the Type 42 V10 when the Lightweight joined, 2026-11-09)
-- (OldTrims: owner, 2026-11-13, "remove the 2 high trims of the lambo contach and gt3rs": the line's
-- SPORT / TOP trims are off sale; they still exist, retired, in a line of their own, so a player who
-- bought one keeps it and it still drives)
export type Series = { Name: string, Ids: { string }, Brand: string?, Hidden: boolean?, NoTrims: boolean?, TrimBase: string?, OldTrims: boolean? }

Cars.TrimSteps = {
	{ Key = "sport", Trim = "SPORT", Label = "Sport", Price = 1.3, Speed = 1.05, Accel = 0.92, Grip = 0.03, FreePrice = 8000 },
	{ Key = "top", Trim = "TOP", Label = "Top", Price = 1.7, Speed = 1.1, Accel = 0.85, Grip = 0.06, FreePrice = 15000 },
}

Cars.Series = {
	{ Name = "APEX CAMBRIA", Ids = { "toyoka_camri" } },
	{ Name = "APEX GRAND LOUNGE", Ids = { "toyoka_alfard" } },
	{ Name = "APEX J-SERIES", Ids = { "toyoka_lc200", "toyoka_lc300" } },
	{ Name = "APEX JZX100", Ids = { "toyoka_chaser" } },
	{ Name = "APEX JZA80", Ids = { "toyoka_supra_mk4" } },
	{ Name = "ORIENT VOLTRA", Ids = { "kio_ev6" } },
	{ Name = "DREAM-BUILD VOLT TITAN", Ids = { "byt_u8" } },
	{ Name = "HORIZON Z33", Ids = { "nisun_350z" } },
	{ Name = "HORIZON BNR34 & R35", Ids = { "nisun_r34", "nisun_gtr" } },
	{ Name = "AHURA FD ROTARY", Ids = { "mazdo_rx7" } },
	{ Name = "BAVARICA WERKZ F80", Ids = { "bnw_m3_f80" } },
	{ Name = "BAVARICA WERKZ E92 & F82", Ids = { "bnw_m3_e92", "bnw_m4_f82" } },
	{ Name = "BAVARICA WERKZ G20", Ids = { "bnw_330i_g20" }, NoTrims = true },
	{ Name = "DEARBORN C346", Ids = { "dearb_focus_rs" }, NoTrims = true },
	{ Name = "BAVARICA WERKZ SALOON", Ids = { "bnw_540i", "bnw_m5_e60", "bnw_m5_f10", "bnw_m5_f90" } },
	{ Name = "BAVARICA WERKZ E63 & F93", Ids = { "bnw_m6_v10", "bnw_m8gc" } },
	{ Name = "BAVARICA WERKZ G12", Ids = { "bnw_750li" } },
	{ Name = "BAVARICA WERKZ G06", Ids = { "bnw_x6" } },
	{ Name = "BAVARICA WERKZ G07", Ids = { "bnw_x7" } },
	{ Name = "TRI-STAR SILBER W201", Ids = { "bentz_190e" } },
	{ Name = "TRI-STAR SILBER W177", Ids = { "bentz_a45s" } },
	{ Name = "TRI-STAR SILBER C218", Ids = { "bentz_cls63s" } },
	{ Name = "TRI-STAR SILBER W213", Ids = { "bentz_e400", "bentz_e63s" } },
	{ Name = "TRI-STAR SILBER FLAGSHIP", Ids = { "bentz_s65_w221", "bentz_s63", "bentz_s680" } },
	{ Name = "TRI-STAR SILBER C167", Ids = { "bentz_gle53" } },
	{ Name = "TRI-STAR SILBER W463", Ids = { "bentz_g63", "brabos_g63" } },
	{ Name = "TRI-STAR SILBER X167", Ids = { "bentz_gls" } },
	{ Name = "TRI-STAR SILBER R230", Ids = { "bentz_sl65bs" } },
	{ Name = "TRI-STAR SILBER C197", Ids = { "bentz_sls" } },
	{ Name = "IRONCLAD LC", Ids = { "dodger_challenger" } },
	{ Name = "IRONCLAD SUPERCHARGED", Ids = { "bentz_gt63s" } },
	{ Name = "GOLDEN SIX", Ids = { "chevo_camaro" } },
	{ Name = "GOLDEN STING", Ids = { "chevo_c7" } },
	{ Name = "HYPERSPEED TECH S7", Ids = { "xiaomo_su7" } },
	{ Name = "STEALTH-APEX Z100", Ids = { "lexis_lc500" } },
	{ Name = "STEALTH-APEX J310", Ids = { "lexis_lx700" } },
	{ Name = "STEALTH-APEX V10 HALO", Ids = { "lexis_lfa", "lexis_lfa_circuit" } },
	{ Name = "TRIDENT MOTORS MAESTRALE", Ids = { "maseroti_levante" } },
	{ Name = "STUTTGART 982", Ids = { "porsha_boxster" } },
	{ Name = "STUTTGART 971", Ids = { "porsha_panamera" } },
	{ Name = "STUTTGART 991.2", Ids = { "porsha_gt3" }, OldTrims = true },
	{ Name = "BRITISH VANGUARD HIGHLAND", Ids = { "astin_dbx" } },
	{ Name = "BRITISH VANGUARD VANTA", Ids = { "astin_db9" } },
	{ Name = "BRITISH VANGUARD VELA", Ids = { "astin_vantage" } },
	{ Name = "PRECISION TYPE 42", Ids = { "audy_r8", "audy_r8_lw" }, TrimBase = "audy_r8" },
	-- (2026-11-09: a two-car line once the Finale RWD joins, so no SPORT / TOP trims meanwhile)
	{ Name = "PRECISION 4S", Ids = { "audy_r8_4s" }, NoTrims = true },
	{ Name = "ROSSO RAMPANTE F131", Ids = { "ferrara_f430" } },
	{ Name = "ROSSO RAMPANTE F149", Ids = { "ferrara_california" } },
	{ Name = "ROSSO RAMPANTE F141", Ids = { "ferrara_599" } },
	{ Name = "ROSSO RAMPANTE F142", Ids = { "ferrara_458spider", "ferrara_458speciale" } },
	{ Name = "ENFURECIDO L140", Ids = { "lambrini_lp560", "lambrini_lp570" } },
	{ Name = "ENFURECIDO LB724", Ids = { "lambrini_huracan", "lambrini_performante", "lambrini_sto", "lambrini_sterrato" } },
	{ Name = "ENFURECIDO L147", Ids = { "lambrini_lp640", "lambrini_lp670" } },
	{ Name = "ENFURECIDO LB834", Ids = { "lambrini_lp700", "lambrini_lp750", "lambrini_svj", "lambrini_svj63" } },
	{ Name = "ENFURECIDO LB744", Ids = { "lambrini_revuelto" } },
	{ Name = "ENFURECIDO BRAVA", Ids = { "lambrini_urusp" }, NoTrims = true },
	{ Name = "ENFURECIDO CLASSICO", Ids = { "lambrini_countach" }, OldTrims = true },
	{ Name = "SPEEDMARK P11", Ids = { "mclaran_12c" } },
	{ Name = "SOVEREIGN GRAND TOURER", Ids = { "bentlee_contgt" } },
	{ Name = "SOVEREIGN HIGHLANDS", Ids = { "bentlee_bentayga" } },
	{ Name = "ECSTASY NOCTURNE", Ids = { "rolls_wraith" } },
	{ Name = "ECSTASY GRANDEUR", Ids = { "rolls_cullinan" } },
	{ Name = "VELOCITÉ NOIR ORIGINE", Ids = { "bugotti_veyron" } },
	{ Name = "VELOCITÉ NOIR ÉCLAIR", Ids = { "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport" } },
} :: { Series }

-- the retired cars' own lines (owners still see them in their garage; the one-car lines kept their
-- SPORT / TOP trims, the cars that were part of a ladder get none: NoTrims)
local RETIRED_SERIES = {
	{ Name = "SOMPACT ZIPPA", Ids = { "suzaki_swift" } },
	{ Name = "APEX METRO", Ids = { "toyoka_belta" } },
	{ Name = "APEX REGENT", Ids = { "toyoka_crown" } },
	{ Name = "DREAM-BUILD VOLT ORCA", Ids = { "byt_seal" } },
	{ Name = "AHURA SE3P ROTARY", Ids = { "mazdo_rx8" } },
	{ Name = "TRI-STAR SILBER C118", Ids = { "bentz_cla45" } },
	{ Name = "BAVARICA WERKZ G30", Ids = { "bnw_530i" }, NoTrims = true },
	{ Name = "TRI-STAR SILBER W213 2.0", Ids = { "bentz_e300" }, NoTrims = true },
	{ Name = "GOLDEN STING 6", Ids = { "chevo_c6" }, NoTrims = true },
	{ Name = "ROSSO RAMPANTE F142 COUPE", Ids = { "ferrara_458" } },
	{ Name = "ENFURECIDO BRAVA OLD", Ids = { "lambrini_urus" }, NoTrims = true },
}

-- every line, the retired ones too (Cars.Series is cut down to the ones on sale further on)
local allSeries: { Series } = table.clone(Cars.Series)
for _, series in RETIRED_SERIES do
	table.insert(allSeries, series :: Series)
end

-- a car left out of the series list gets one of its own
for _, spec in list do
	local found = false
	for _, series in allSeries do
		if table.find(series.Ids, spec.Id) then
			found = true
			break
		end
	end
	if not found then
		table.insert(allSeries, { Name = Cars.upper(spec.Name), Ids = { spec.Id } })
	end
end

-- the SPORT and TOP trims of every one-car line (the same body: Model is the base car's)
local function round(n: number, step: number): number
	return math.floor(n / step + 0.5) * step
end
local oldTrimSeries: { Series } = {}
for _, series in allSeries do
	if (#series.Ids ~= 1 and not series.TrimBase) or series.NoTrims then
		continue
	end
	local base = Cars.ById[series.TrimBase or series.Ids[1]]
	local at = table.find(series.Ids, base.Id) :: number -- (the trims go right after their base car)
	local oldIds: { string }? = if series.OldTrims then {} else nil
	if not oldIds then
		base.Trim = "BASE"
	end
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
			PriceSource = base.PriceSource,
			StatPrice = if (base.StatPrice or base.Price) > 0 then round((base.StatPrice or base.Price) * step.Price, 1000) else step.FreePrice,
			Color = base.Color,
			Accent = base.Accent,
			Order = base.Order + i / 10,
			Electric = base.Electric,
			Model = base.Model or base.Id,
			Trim = step.Trim,
			BaseId = base.Id,
			Retired = base.Retired or series.OldTrims,
			Pending = base.Pending,
		}
		table.insert(list, spec)
		Cars.ById[spec.Id] = spec
		if oldIds then
			table.insert(oldIds, spec.Id)
		else
			table.insert(series.Ids, at + i, spec.Id)
		end
	end
	if oldIds then
		table.insert(oldTrimSeries, { Name = series.Name .. " OLD TRIMS", Ids = oldIds, NoTrims = true })
	end
end
for _, series in oldTrimSeries do
	table.insert(allSeries, series)
end

-- trims that land in class S2 or R on a cheap base car (owner, 2026-11-07, see PriceSource above)
Cars.TrimPrices = {
	mclaran_12c_sport = 850000, mclaran_12c_top = 950000,
	porsha_gt3_sport = 350000, porsha_gt3_top = 850000,
	ferrara_599_top = 350000, ferrara_f430_top = 350000,
} :: { [string]: number }
for id, price in Cars.TrimPrices do
	Cars.ById[id].Price = price
end

-- the Origine's trims got their own models (owner, 2026-11-03: the 2010 Super Sport and the 2013
-- Roadster Vitesse replace the SPORT and TOP on the base car's body): same ids, levels and prices,
-- so owners keep them; the dealer shows their own names
do
	local ss, gsv = Cars.ById.bugotti_veyron_sport, Cars.ById.bugotti_veyron_top
	if ss then
		ss.Model = nil
		ss.Name = "Velocité Noir Origine Super Sport"
		ss.Trim = "SUPER SPORT"
		-- (2026-11-03, the classes: the real road cars' numbers in place of the SPORT / TOP steps,
		-- so the Origines sit in class R under the Éclairs in X; the Super Sport's road cars were
		-- limited to 258 mph)
		ss.TopSpeed, ss.ZeroToSixty, ss.Handling = 258, 2.5, 0.88
	end
	if gsv then
		gsv.Model = nil
		gsv.Name = "Velocité Noir Origine Roadster Vitesse"
		gsv.Trim = "ROADSTER VITESSE"
		gsv.TopSpeed, gsv.ZeroToSixty, gsv.Handling = 254, 2.6, 0.87
	end
end

-- brand XP is saved by brand name: the old names it was saved under (Brands.lua moves them)
Cars.OldBrands = {
	BNW = "BAVARICA WERKZ", MERCER = "TRI-STAR SILBER", BRABOS = "ROCKET", TOYOKA = "APEX",
	LEXIS = "STEALTH-APEX", NISUN = "HORIZON", MAZDO = "AHURA", SUZAKI = "SOMPACT", KIO = "ORIENT",
	BYT = "DREAM-BUILD VOLT", XIAOMO = "HYPERSPEED TECH", CHEVO = "GOLDEN", DODGER = "IRONCLAD", HEMI = "IRONCLAD",
	PORSHA = "STUTTGART", AUDY = "PRECISION", ["ASTIN MARLIN"] = "BRITISH VANGUARD",
	FERRARA = "ROSSO RAMPANTE", LAMBRINI = "ENFURECIDO", MASEROTI = "TRIDENT MOTORS",
	MCLARAN = "SPEEDMARK", BENTLEE = "SOVEREIGN", ["ROLLS ROYAL"] = "ECSTASY",
	BUGOTTI = "VELOCITÉ NOIR",
} :: { [string]: string }

-- each series' brand (owner, 2026-10-22: "fit each car into the brands"): the make its first
-- car's name starts with (Cars.Makes); the garage and the dealer list brands, then their series
for _, series in allSeries do
	local first = Cars.ById[series.Ids[1]]
	series.Brand = Cars.upper(if first then Cars.makeOf(first.Name) else series.Name)
end

Cars.SeriesOf = {} :: { [string]: { series: Series, index: number } }
for _, series in allSeries do
	for i, id in series.Ids do
		Cars.SeriesOf[id] = { series = series, index = i }
	end
end

-- a car you can buy (not retired, not waiting for its model)
function Cars.forSale(id: string): boolean
	local spec = Cars.ById[id]
	return spec ~= nil and not spec.Retired and not spec.Pending
end

-- Cars.All: every car, the retired and pending ones too (saves, garages, lookups by id);
-- Cars.List: the cars on sale (the dealer, the market, traffic, rewards, "own every car")
-- Cars.AllSeries: every line; Cars.Series: the lines on sale (Hidden: none of its cars on sale)
Cars.All = list
Cars.List = {} :: { CarSpec }
for _, spec in list do
	if Cars.forSale(spec.Id) then
		table.insert(Cars.List, spec)
	end
end
Cars.AllSeries = allSeries
Cars.Series = {} :: { Series }
for _, series in allSeries do
	local onSale = false
	for _, id in series.Ids do
		if Cars.forSale(id) then
			onSale = true
		end
	end
	series.Hidden = not onSale
	if onSale then
		table.insert(Cars.Series, series)
	end
end

-- the short name of a car's trim for the dealer's trim chips (BASE / SPORT / TOP, or what its
-- name adds to the brand: "F90", "LB834 ZV")
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

-- (the level a car needs is CarStats.requiredLevel: by its class, 2026-11-03)

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
