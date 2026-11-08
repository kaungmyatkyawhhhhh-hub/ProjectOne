--!strict
--[[
	Real numbers for each car's physics and wheels (2026-11-08, Prompts/A million times better wheels (new models).md,
	Part 2). From the real car each one is modelled on (close enough). Used by CarPhysics and the wheel kit.
]]

export type Phys = {
	front: number, -- static share of weight on the front axle (0..1)
	drive: string, -- "RWD" | "AWD" | "FWD"
	rear: number?, -- AWD only: nominal share of drive torque to the rear axle (0..1; e.g. 0.6 for 40:60)
	gears: number, -- forward gears (1 for an EV)
	box: string, -- "dct" | "auto" | "amt" | "manual" | "ev" (amt = single-clutch automated manual: Lamborghini ISR / e-gear, Ferrari F1, BMW SMG, Lexus LFA ASG)
	shift: number, -- typical upshift time, seconds, for that gearbox (dct ~0.08-0.15, modern auto ~0.2-0.35, old torque-converter auto ~0.4-0.6, amt ~0.05-0.3, manual ~0.45)
	tyreF: number, tyreR: number, -- stock tyre section width, mm
	aspectF: number, aspectR: number, -- stock tyre profile, %
	rimF: number, rimR: number, -- stock rim diameter, inches
	tyre: string, -- stock tyre type: "allseason" | "touring" | "sport" | "cup" (semi-slick, e.g. Cup 2 / Trofeo R) | "offroad"
	brakes: string, -- stock front discs: "steel" | "drilled" | "slotted" | "ceramic" (carbon-ceramic)
	pistons: number, -- front caliper pistons
	caliper: string, -- stock caliper colour: "black" | "silver" | "grey" | "red" | "yellow" | "blue" | "orange" | "green" | "gold" | "bronze"
	centerLock: boolean?, -- true if it has centre-lock wheels (one big nut)
	lugs: number, -- wheel bolts per wheel (5 usually; 6 on some trucks/SUVs; 4 on small cars); centre-lock cars still give 5
	stop: number, -- real 100-0 km/h braking distance, metres (typical magazine test)
	z60: number, -- real 0-60 mph, seconds
	top: number, -- real top speed, mph (limited where it is)
	hp: number, -- real power, hp
	nm: number, -- real peak torque, Nm
	redline: number, -- rpm / 1000 (EV: the motor's max / 1000)
	cg: number, -- centre of gravity height, metres (estimate: ~0.42 supercars, ~0.5 sedans, ~0.65-0.75 SUVs)
	downforce: number, -- downforce at 250 km/h, kg (0 for cars with none or with lift)
}

local Data: { [string]: Phys } = {
	-- Suzuki Swift (3rd gen, 1.2 Dualjet, 5-speed manual)
	suzaki_swift = { front = 0.62, drive = "FWD", gears = 5, box = "manual", shift = 0.45, tyreF = 185, tyreR = 185, aspectF = 55, aspectR = 55, rimF = 16, rimR = 16, tyre = "touring", brakes = "steel", pistons = 1, caliper = "grey", lugs = 4, stop = 40, z60 = 11.3, top = 112, hp = 90, nm = 120, redline = 6.5, cg = 0.52, downforce = 0 },
	-- Toyota Belta / Yaris sedan (XP90, 1.5, 4-speed auto)
	toyoka_belta = { front = 0.62, drive = "FWD", gears = 4, box = "auto", shift = 0.5, tyreF = 175, tyreR = 175, aspectF = 65, aspectR = 65, rimF = 14, rimR = 14, tyre = "touring", brakes = "steel", pistons = 1, caliper = "grey", lugs = 4, stop = 42, z60 = 10.4, top = 109, hp = 106, nm = 140, redline = 6.4, cg = 0.53, downforce = 0 },
	-- Kia EV6 (CV, 77.4 kWh, single motor RWD)
	kio_ev6 = { front = 0.49, drive = "RWD", gears = 1, box = "ev", shift = 0, tyreF = 235, tyreR = 235, aspectF = 55, aspectR = 55, rimF = 19, rimR = 19, tyre = "touring", brakes = "steel", pistons = 1, caliper = "grey", lugs = 5, stop = 36, z60 = 7.2, top = 114, hp = 225, nm = 350, redline = 15, cg = 0.55, downforce = 0 },
	-- BYD Seal (Dynamic RWD, 61.4 kWh)
	byt_seal = { front = 0.48, drive = "RWD", gears = 1, box = "ev", shift = 0, tyreF = 225, tyreR = 225, aspectF = 50, aspectR = 50, rimF = 18, rimR = 18, tyre = "touring", brakes = "steel", pistons = 1, caliper = "grey", lugs = 5, stop = 36, z60 = 7.2, top = 112, hp = 201, nm = 310, redline = 16, cg = 0.5, downforce = 0 },
	-- Toyota Camry (XV70, 2.5, 8-speed auto)
	toyoka_camri = { front = 0.61, drive = "FWD", gears = 8, box = "auto", shift = 0.3, tyreF = 235, tyreR = 235, aspectF = 45, aspectR = 45, rimF = 18, rimR = 18, tyre = "touring", brakes = "steel", pistons = 1, caliper = "grey", lugs = 5, stop = 38, z60 = 7.6, top = 135, hp = 203, nm = 250, redline = 6.6, cg = 0.52, downforce = 0 },
	-- Toyota Crown RS (S220, 2.0 turbo, 8-speed auto, JDM 180 km/h limit)
	toyoka_crown = { front = 0.55, drive = "RWD", gears = 8, box = "auto", shift = 0.3, tyreF = 225, tyreR = 225, aspectF = 45, aspectR = 45, rimF = 18, rimR = 18, tyre = "touring", brakes = "steel", pistons = 2, caliper = "grey", lugs = 5, stop = 37, z60 = 6.9, top = 112, hp = 241, nm = 350, redline = 6.2, cg = 0.52, downforce = 0 },
	-- Toyota Alphard Executive Lounge (AH30, 3.5 V6, 8-speed auto, JDM 180 km/h limit)
	toyoka_alfard = { front = 0.58, drive = "FWD", gears = 8, box = "auto", shift = 0.35, tyreF = 235, tyreR = 235, aspectF = 50, aspectR = 50, rimF = 18, rimR = 18, tyre = "touring", brakes = "steel", pistons = 2, caliper = "grey", lugs = 5, stop = 42, z60 = 7.8, top = 112, hp = 297, nm = 361, redline = 6.6, cg = 0.75, downforce = 0 },
	-- Toyota Land Cruiser 200 (2016+, 5.7 V8, 8-speed auto)
	toyoka_lc200 = { front = 0.53, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.35, tyreF = 285, tyreR = 285, aspectF = 60, aspectR = 60, rimF = 18, rimR = 18, tyre = "allseason", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 44, z60 = 6.7, top = 130, hp = 381, nm = 544, redline = 5.6, cg = 0.78, downforce = 0 },
	-- Nissan 350Z (Z33 HR, 3.5 V6, 6-speed manual)
	nisun_350z = { front = 0.53, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 225, tyreR = 245, aspectF = 45, aspectR = 45, rimF = 18, rimR = 18, tyre = "sport", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 37, z60 = 5.3, top = 155, hp = 306, nm = 363, redline = 7.5, cg = 0.47, downforce = 0 },
	-- Mazda RX-7 (FD3S, 13B twin-turbo rotary, 5-speed manual, US spec)
	mazdo_rx7 = { front = 0.5, drive = "RWD", gears = 5, box = "manual", shift = 0.45, tyreF = 225, tyreR = 225, aspectF = 50, aspectR = 50, rimF = 16, rimR = 16, tyre = "sport", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 38, z60 = 5, top = 156, hp = 255, nm = 294, redline = 8, cg = 0.45, downforce = 0 },
	-- Mazda RX-8 (SE3P, 13B Renesis rotary, 6-speed manual)
	mazdo_rx8 = { front = 0.5, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 225, tyreR = 225, aspectF = 45, aspectR = 45, rimF = 18, rimR = 18, tyre = "sport", brakes = "steel", pistons = 2, caliper = "grey", lugs = 5, stop = 37, z60 = 6.4, top = 146, hp = 232, nm = 216, redline = 9, cg = 0.46, downforce = 0 },
	-- BMW 530i M Sport (G30, 2.0 turbo, 8-speed auto)
	bnw_530i = { front = 0.51, drive = "RWD", gears = 8, box = "auto", shift = 0.25, tyreF = 245, tyreR = 275, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "steel", pistons = 1, caliper = "grey", lugs = 5, stop = 36, z60 = 5.9, top = 155, hp = 248, nm = 350, redline = 6.5, cg = 0.5, downforce = 0 },
	-- BMW 540i M Sport (G30, 3.0 turbo, 8-speed auto, M Sport brakes)
	bnw_540i = { front = 0.53, drive = "RWD", gears = 8, box = "auto", shift = 0.25, tyreF = 245, tyreR = 275, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "steel", pistons = 4, caliper = "blue", lugs = 5, stop = 35, z60 = 4.7, top = 155, hp = 335, nm = 450, redline = 7, cg = 0.5, downforce = 0 },
	-- Mercedes-Benz E 300 AMG Line (W213, 2.0 turbo, 9G-Tronic)
	bentz_e300 = { front = 0.53, drive = "RWD", gears = 9, box = "auto", shift = 0.3, tyreF = 245, tyreR = 275, aspectF = 45, aspectR = 40, rimF = 18, rimR = 18, tyre = "touring", brakes = "drilled", pistons = 1, caliper = "grey", lugs = 5, stop = 36, z60 = 6.1, top = 155, hp = 241, nm = 370, redline = 6.3, cg = 0.5, downforce = 0 },
	-- Mercedes-Benz E 400 4MATIC (W213, 3.0 V6 biturbo, 9G-Tronic)
	bentz_e400 = { front = 0.54, drive = "AWD", rear = 0.55, gears = 9, box = "auto", shift = 0.3, tyreF = 245, tyreR = 275, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 1, caliper = "grey", lugs = 5, stop = 35, z60 = 4.9, top = 155, hp = 329, nm = 480, redline = 6.3, cg = 0.51, downforce = 0 },
	-- BMW 330i M Sport (G20, 2.0 turbo, 8-speed auto, M Sport brakes)
	bnw_330i_g20 = { front = 0.5, drive = "RWD", gears = 8, box = "auto", shift = 0.2, tyreF = 225, tyreR = 255, aspectF = 45, aspectR = 40, rimF = 18, rimR = 18, tyre = "sport", brakes = "steel", pistons = 4, caliper = "blue", lugs = 5, stop = 34, z60 = 5.3, top = 155, hp = 255, nm = 400, redline = 6.5, cg = 0.48, downforce = 0 },
	-- BMW M3 (E92, 4.0 V8, 6-speed manual)
	bnw_m3_e92 = { front = 0.52, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 245, tyreR = 265, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 1, caliper = "grey", lugs = 5, stop = 34, z60 = 4.6, top = 155, hp = 414, nm = 400, redline = 8.4, cg = 0.47, downforce = 0 },
	-- BMW M3 (F80, 3.0 twin-turbo, 7-speed M-DCT, M Driver's Package)
	bnw_m3_f80 = { front = 0.52, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 255, tyreR = 275, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "blue", lugs = 5, stop = 33, z60 = 3.9, top = 174, hp = 425, nm = 550, redline = 7.6, cg = 0.47, downforce = 0 },
	-- BMW M4 (F82, 3.0 twin-turbo, 7-speed M-DCT, M Driver's Package)
	bnw_m4_f82 = { front = 0.52, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 255, tyreR = 275, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "blue", lugs = 5, stop = 33, z60 = 3.9, top = 174, hp = 425, nm = 550, redline = 7.6, cg = 0.46, downforce = 0 },
	-- BMW M5 (E60, 5.0 V10, 7-speed SMG III, M Driver's Package)
	bnw_m5_e60 = { front = 0.52, drive = "RWD", gears = 7, box = "amt", shift = 0.1, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 2, caliper = "grey", lugs = 5, stop = 35, z60 = 4.4, top = 190, hp = 500, nm = 520, redline = 8.25, cg = 0.5, downforce = 0 },
	-- BMW M6 (E63, 5.0 V10, 7-speed SMG III, M Driver's Package)
	bnw_m6_v10 = { front = 0.52, drive = "RWD", gears = 7, box = "amt", shift = 0.1, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 2, caliper = "grey", lugs = 5, stop = 35, z60 = 4.5, top = 190, hp = 500, nm = 520, redline = 8.25, cg = 0.48, downforce = 0 },
	-- BMW M8 Competition Gran Coupe (F93, 4.4 V8 twin-turbo, 8-speed auto, M xDrive, M Driver's Package)
	bnw_m8gc = { front = 0.54, drive = "AWD", rear = 0.7, gears = 8, box = "auto", shift = 0.2, tyreF = 275, tyreR = 285, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "blue", lugs = 5, stop = 33, z60 = 3, top = 190, hp = 617, nm = 750, redline = 7.2, cg = 0.48, downforce = 0 },
	-- Mercedes-AMG CLA 45 4MATIC+ (C118, 2.0 turbo, 8-speed DCT)
	bentz_cla45 = { front = 0.6, drive = "AWD", rear = 0.3, gears = 8, box = "dct", shift = 0.1, tyreF = 255, tyreR = 255, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "grey", lugs = 5, stop = 34, z60 = 4, top = 155, hp = 382, nm = 480, redline = 7.2, cg = 0.48, downforce = 0 },
	-- Mercedes-AMG CLS 63 S 4MATIC (C218, 5.5 V8 biturbo, 7-speed MCT, Driver's Package)
	bentz_cls63s = { front = 0.55, drive = "AWD", rear = 0.67, gears = 7, box = "auto", shift = 0.15, tyreF = 255, tyreR = 285, aspectF = 35, aspectR = 30, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.6, top = 186, hp = 577, nm = 800, redline = 6.5, cg = 0.5, downforce = 0 },
	-- Toyota Supra Turbo (JZA80, 3.0 2JZ-GTE twin-turbo, 6-speed manual, US spec)
	toyoka_supra_mk4 = { front = 0.53, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 235, tyreR = 255, aspectF = 45, aspectR = 40, rimF = 17, rimR = 17, tyre = "sport", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 34, z60 = 4.6, top = 155, hp = 320, nm = 427, redline = 6.8, cg = 0.46, downforce = 0 },
	-- Nissan Skyline GT-R V-Spec (BNR34, 2.6 RB26DETT twin-turbo, 6-speed manual, UK-quoted top speed)
	nisun_r34 = { front = 0.56, drive = "AWD", rear = 0.85, gears = 6, box = "manual", shift = 0.45, tyreF = 245, tyreR = 245, aspectF = 40, aspectR = 40, rimF = 18, rimR = 18, tyre = "sport", brakes = "steel", pistons = 4, caliper = "gold", lugs = 5, stop = 36, z60 = 4.9, top = 165, hp = 276, nm = 392, redline = 8, cg = 0.48, downforce = 10 },
	-- Dodge Challenger SRT Hellcat (6.2 supercharged V8, 8-speed auto)
	dodger_challenger = { front = 0.57, drive = "RWD", gears = 8, box = "auto", shift = 0.25, tyreF = 275, tyreR = 275, aspectF = 40, aspectR = 40, rimF = 20, rimR = 20, tyre = "sport", brakes = "slotted", pistons = 6, caliper = "red", lugs = 5, stop = 36, z60 = 3.6, top = 199, hp = 707, nm = 881, redline = 6.2, cg = 0.53, downforce = 0 },
	-- Xiaomi SU7 Max (dual motor, 101 kWh)
	xiaomo_su7 = { front = 0.48, drive = "AWD", rear = 0.6, gears = 1, box = "ev", shift = 0, tyreF = 245, tyreR = 265, aspectF = 40, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "steel", pistons = 4, caliper = "red", lugs = 5, stop = 33.3, z60 = 2.7, top = 165, hp = 664, nm = 838, redline = 21, cg = 0.47, downforce = 0 },
	-- BMW X6 xDrive40i M Sport (G06, 3.0 turbo, 8-speed auto)
	bnw_x6 = { front = 0.5, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.25, tyreF = 275, tyreR = 305, aspectF = 45, aspectR = 40, rimF = 20, rimR = 20, tyre = "sport", brakes = "steel", pistons = 4, caliper = "blue", lugs = 5, stop = 36, z60 = 5.2, top = 155, hp = 335, nm = 450, redline = 7, cg = 0.65, downforce = 0 },
	-- BMW X7 M50i (G07, 4.4 V8 twin-turbo, 8-speed auto)
	bnw_x7 = { front = 0.5, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.25, tyreF = 275, tyreR = 315, aspectF = 40, aspectR = 35, rimF = 21, rimR = 21, tyre = "sport", brakes = "steel", pistons = 4, caliper = "blue", lugs = 5, stop = 37, z60 = 4.5, top = 155, hp = 523, nm = 750, redline = 6.5, cg = 0.7, downforce = 0 },
	-- Toyota Land Cruiser 300 (3.4 V6 twin-turbo, 10-speed auto)
	toyoka_lc300 = { front = 0.53, drive = "AWD", rear = 0.6, gears = 10, box = "auto", shift = 0.3, tyreF = 265, tyreR = 265, aspectF = 55, aspectR = 55, rimF = 20, rimR = 20, tyre = "allseason", brakes = "steel", pistons = 4, caliper = "grey", lugs = 6, stop = 42, z60 = 6.6, top = 130, hp = 409, nm = 650, redline = 5.8, cg = 0.75, downforce = 0 },
	-- Lexus LX 700h (J310, 3.4 V6 twin-turbo hybrid, 10-speed auto)
	lexis_lx700 = { front = 0.53, drive = "AWD", rear = 0.6, gears = 10, box = "auto", shift = 0.3, tyreF = 265, tyreR = 265, aspectF = 50, aspectR = 50, rimF = 22, rimR = 22, tyre = "allseason", brakes = "steel", pistons = 4, caliper = "grey", lugs = 6, stop = 42, z60 = 6.3, top = 130, hp = 457, nm = 790, redline = 5.8, cg = 0.78, downforce = 0 },
	-- Mercedes-AMG GLE 53 4MATIC+ Coupe (C167, 3.0 turbo + EQ Boost, 9-speed auto)
	bentz_gle53 = { front = 0.53, drive = "AWD", rear = 0.6, gears = 9, box = "auto", shift = 0.25, tyreF = 275, tyreR = 315, aspectF = 45, aspectR = 40, rimF = 21, rimR = 21, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 36, z60 = 5.2, top = 155, hp = 429, nm = 520, redline = 6.5, cg = 0.65, downforce = 0 },
	-- Mercedes-AMG G 63 (W463A, 4.0 V8 biturbo, 9-speed auto, Driver's Package)
	bentz_g63 = { front = 0.52, drive = "AWD", rear = 0.6, gears = 9, box = "auto", shift = 0.25, tyreF = 295, tyreR = 295, aspectF = 40, aspectR = 40, rimF = 21, rimR = 21, tyre = "allseason", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 39, z60 = 4.4, top = 149, hp = 577, nm = 850, redline = 6.5, cg = 0.8, downforce = 0 },
	-- Yangwang U8 (four motors, range extender)
	byt_u8 = { front = 0.5, drive = "AWD", rear = 0.5, gears = 1, box = "ev", shift = 0, tyreF = 275, tyreR = 275, aspectF = 55, aspectR = 55, rimF = 22, rimR = 22, tyre = "allseason", brakes = "steel", pistons = 6, caliper = "black", lugs = 6, stop = 40, z60 = 3.5, top = 124, hp = 1180, nm = 1280, redline = 20, cg = 0.8, downforce = 0 },
	-- Porsche Panamera Turbo S (971.2, 4.0 V8 twin-turbo, 8-speed PDK, PCCB)
	porsha_panamera = { front = 0.53, drive = "AWD", rear = 0.7, gears = 8, box = "dct", shift = 0.1, tyreF = 275, tyreR = 315, aspectF = 35, aspectR = 30, rimF = 21, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 10, caliper = "yellow", lugs = 5, stop = 33, z60 = 2.9, top = 196, hp = 620, nm = 820, redline = 6.8, cg = 0.5, downforce = 0 },
	-- Chevrolet Camaro ZL1 (6th gen, 6.2 supercharged V8, 10-speed auto)
	chevo_camaro = { front = 0.54, drive = "RWD", gears = 10, box = "auto", shift = 0.2, tyreF = 285, tyreR = 305, aspectF = 30, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "slotted", pistons = 6, caliper = "red", lugs = 5, stop = 33, z60 = 3.5, top = 198, hp = 650, nm = 881, redline = 6.5, cg = 0.5, downforce = 0 },
	-- Chevrolet Corvette (C6, 6.2 LS3 V8, 6-speed manual)
	chevo_c6 = { front = 0.51, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 245, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 18, rimR = 19, tyre = "sport", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 35, z60 = 4.3, top = 190, hp = 430, nm = 575, redline = 6.6, cg = 0.45, downforce = 0 },
	-- Porsche 718 Boxster GTS 4.0 (982, 4.0 flat-6, 6-speed manual)
	porsha_boxster = { front = 0.45, drive = "RWD", gears = 6, box = "manual", shift = 0.45, tyreF = 235, tyreR = 265, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "red", lugs = 5, stop = 33, z60 = 4.3, top = 182, hp = 394, nm = 420, redline = 7.8, cg = 0.43, downforce = 0 },
	-- Chevrolet Corvette Stingray Z51 (C7, 6.2 LT1 V8, 7-speed manual)
	chevo_c7 = { front = 0.5, drive = "RWD", gears = 7, box = "manual", shift = 0.45, tyreF = 245, tyreR = 285, aspectF = 35, aspectR = 30, rimF = 19, rimR = 20, tyre = "sport", brakes = "slotted", pistons = 4, caliper = "red", lugs = 5, stop = 33, z60 = 3.8, top = 180, hp = 460, nm = 630, redline = 6.6, cg = 0.44, downforce = 0 },
	-- Mercedes-AMG S 63 4MATIC (W222, 5.5 V8 biturbo, 7-speed MCT)
	bentz_s63 = { front = 0.53, drive = "AWD", rear = 0.67, gears = 7, box = "auto", shift = 0.15, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 36, z60 = 3.9, top = 155, hp = 577, nm = 900, redline = 6.5, cg = 0.52, downforce = 0 },
	-- Mercedes-AMG GT 63 S 4MATIC+ 4-Door Coupe (X290, 4.0 V8 biturbo, 9-speed MCT)
	bentz_gt63s = { front = 0.56, drive = "AWD", rear = 0.65, gears = 9, box = "auto", shift = 0.15, tyreF = 265, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 21, rimR = 21, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.1, top = 196, hp = 630, nm = 900, redline = 7, cg = 0.5, downforce = 0 },
	-- Nissan GT-R (R35, 2017+, 3.8 V6 twin-turbo, 6-speed DCT)
	nisun_gtr = { front = 0.54, drive = "AWD", rear = 0.75, gears = 6, box = "dct", shift = 0.15, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "grey", lugs = 5, stop = 33, z60 = 2.9, top = 196, hp = 565, nm = 633, redline = 7.1, cg = 0.48, downforce = 20 },
	-- Aston Martin DB9 GT (2016, 6.0 V12, 6-speed Touchtronic II auto)
	astin_db9 = { front = 0.51, drive = "RWD", gears = 6, box = "auto", shift = 0.4, tyreF = 245, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 34, z60 = 4.4, top = 183, hp = 540, nm = 620, redline = 6.8, cg = 0.46, downforce = 0 },
	-- Aston Martin V12 Vantage S (2014, 6.0 V12, 7-speed Sportshift III)
	astin_vantage = { front = 0.51, drive = "RWD", gears = 7, box = "amt", shift = 0.2, tyreF = 255, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 19, rimR = 19, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 33, z60 = 3.7, top = 205, hp = 565, nm = 620, redline = 7, cg = 0.45, downforce = 0 },
	-- Ferrari F430 (4.3 V8, 6-speed F1)
	ferrara_f430 = { front = 0.43, drive = "RWD", gears = 6, box = "amt", shift = 0.15, tyreF = 225, tyreR = 285, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "red", lugs = 5, stop = 34, z60 = 3.6, top = 196, hp = 483, nm = 465, redline = 8.5, cg = 0.44, downforce = 190 },
	-- Mercedes-Benz SL 65 AMG Black Series (R230, 6.0 V12 biturbo, 5-speed auto)
	bentz_sl65bs = { front = 0.52, drive = "RWD", gears = 5, box = "auto", shift = 0.45, tyreF = 265, tyreR = 325, aspectF = 35, aspectR = 30, rimF = 19, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 34, z60 = 3.8, top = 199, hp = 661, nm = 1000, redline = 6, cg = 0.45, downforce = 20 },
	-- Lamborghini Gallardo LP570-4 Superleggera (5.2 V10, 6-speed e-gear)
	lambrini_lp570 = { front = 0.43, drive = "AWD", rear = 0.7, gears = 6, box = "amt", shift = 0.12, tyreF = 235, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 19, rimR = 19, tyre = "sport", brakes = "ceramic", pistons = 8, caliper = "black", lugs = 5, stop = 32, z60 = 3.4, top = 202, hp = 562, nm = 540, redline = 8.5, cg = 0.42, downforce = 40 },
	-- Audi R8 V10 (1st gen, 5.2 V10, 6-speed manual)
	audy_r8 = { front = 0.44, drive = "AWD", rear = 0.85, gears = 6, box = "manual", shift = 0.45, tyreF = 235, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 8, caliper = "red", lugs = 5, stop = 34, z60 = 3.9, top = 196, hp = 525, nm = 530, redline = 8.7, cg = 0.43, downforce = 0 },
	-- McLaren MP4-12C Spider (3.8 V8 twin-turbo, 7-speed SSG)
	mclaran_12c = { front = 0.42, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 235, tyreR = 305, aspectF = 35, aspectR = 30, rimF = 19, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 4, caliper = "silver", lugs = 5, stop = 31, z60 = 3, top = 204, hp = 616, nm = 600, redline = 8.5, cg = 0.42, downforce = 70 },
	-- Ferrari 599 GTB Fiorano (6.0 V12, 6-speed F1)
	ferrara_599 = { front = 0.47, drive = "RWD", gears = 6, box = "amt", shift = 0.1, tyreF = 245, tyreR = 305, aspectF = 40, aspectR = 35, rimF = 19, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "red", lugs = 5, stop = 33, z60 = 3.5, top = 205, hp = 611, nm = 608, redline = 8.4, cg = 0.44, downforce = 200 },
	-- Ferrari 458 Italia (4.5 V8, 7-speed DCT)
	ferrara_458 = { front = 0.42, drive = "RWD", gears = 7, box = "dct", shift = 0.08, tyreF = 235, tyreR = 295, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "red", lugs = 5, stop = 32, z60 = 3, top = 202, hp = 562, nm = 540, redline = 9, cg = 0.42, downforce = 220 },
	-- Mercedes-Benz SLS AMG (C197, 6.2 V8, 7-speed DCT)
	bentz_sls = { front = 0.47, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 265, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 19, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.7, top = 197, hp = 563, nm = 650, redline = 7.2, cg = 0.45, downforce = 30 },
	-- Porsche 911 GT3 (991.2, 4.0 flat-6, 7-speed PDK)
	porsha_gt3 = { front = 0.39, drive = "RWD", gears = 7, box = "dct", shift = 0.08, tyreF = 245, tyreR = 305, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "cup", brakes = "drilled", pistons = 6, caliper = "red", centerLock = true, lugs = 5, stop = 31, z60 = 3.2, top = 197, hp = 500, nm = 460, redline = 9, cg = 0.42, downforce = 95 },
	-- Bentley Continental GT W12 (3rd gen, 6.0 W12 twin-turbo, 8-speed DCT)
	bentlee_contgt = { front = 0.55, drive = "AWD", rear = 0.8, gears = 8, box = "dct", shift = 0.15, tyreF = 275, tyreR = 315, aspectF = 40, aspectR = 35, rimF = 21, rimR = 21, tyre = "sport", brakes = "drilled", pistons = 10, caliper = "grey", lugs = 5, stop = 35, z60 = 3.6, top = 207, hp = 626, nm = 900, redline = 6.5, cg = 0.5, downforce = 0 },
	-- Bentley Bentayga W12 (1st gen, 6.0 W12 twin-turbo, 8-speed auto)
	bentlee_bentayga = { front = 0.57, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.3, tyreF = 285, tyreR = 285, aspectF = 45, aspectR = 45, rimF = 21, rimR = 21, tyre = "touring", brakes = "drilled", pistons = 10, caliper = "grey", lugs = 5, stop = 38, z60 = 3.9, top = 187, hp = 600, nm = 900, redline = 6.5, cg = 0.68, downforce = 0 },
	-- Lamborghini Urus (2018, 4.0 V8 twin-turbo, 8-speed auto)
	lambrini_urus = { front = 0.57, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.2, tyreF = 285, tyreR = 325, aspectF = 40, aspectR = 35, rimF = 22, rimR = 22, tyre = "sport", brakes = "ceramic", pistons = 10, caliper = "black", lugs = 5, stop = 34, z60 = 3.5, top = 190, hp = 641, nm = 850, redline = 6.8, cg = 0.65, downforce = 0 },
	-- Brabus 800 (W463A G 63, 4.0 V8 biturbo, 9-speed auto)
	brabos_g63 = { front = 0.52, drive = "AWD", rear = 0.6, gears = 9, box = "auto", shift = 0.25, tyreF = 305, tyreR = 305, aspectF = 35, aspectR = 35, rimF = 23, rimR = 23, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 39, z60 = 3.9, top = 149, hp = 789, nm = 1000, redline = 6.5, cg = 0.8, downforce = 0 },
	-- Rolls-Royce Wraith (6.6 V12 twin-turbo, 8-speed auto)
	rolls_wraith = { front = 0.52, drive = "RWD", gears = 8, box = "auto", shift = 0.35, tyreF = 255, tyreR = 285, aspectF = 45, aspectR = 40, rimF = 20, rimR = 20, tyre = "touring", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 37, z60 = 4.4, top = 155, hp = 624, nm = 800, redline = 6, cg = 0.53, downforce = 0 },
	-- Rolls-Royce Phantom VIII Extended Wheelbase (6.75 V12 twin-turbo, 8-speed auto; the model is a Phantom, not a Cullinan)
	rolls_cullinan = { front = 0.5, drive = "RWD", gears = 8, box = "auto", shift = 0.35, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 22, rimR = 22, tyre = "touring", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 39, z60 = 5.3, top = 155, hp = 563, nm = 900, redline = 5.8, cg = 0.56, downforce = 0 },
	-- Lamborghini Aventador LP700-4 (6.5 V12, 7-speed ISR)
	lambrini_lp700 = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "amt", shift = 0.06, tyreF = 255, tyreR = 335, aspectF = 35, aspectR = 30, rimF = 19, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 32, z60 = 2.9, top = 217, hp = 690, nm = 690, redline = 8.5, cg = 0.42, downforce = 50 },
	-- Lexus LFA (4.8 V10, 6-speed ASG)
	lexis_lfa = { front = 0.48, drive = "RWD", gears = 6, box = "amt", shift = 0.2, tyreF = 265, tyreR = 305, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 34, z60 = 3.6, top = 202, hp = 553, nm = 480, redline = 9, cg = 0.44, downforce = 40 },
	-- Lexus LFA Nurburgring Package (4.8 V10, 6-speed ASG)
	lexis_lfa_circuit = { front = 0.48, drive = "RWD", gears = 6, box = "amt", shift = 0.15, tyreF = 265, tyreR = 305, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "cup", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 33, z60 = 3.5, top = 202, hp = 563, nm = 480, redline = 9, cg = 0.43, downforce = 100 },
	-- Lamborghini Aventador LP750-4 SV (6.5 V12, 7-speed ISR)
	lambrini_lp750 = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "amt", shift = 0.05, tyreF = 255, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 31, z60 = 2.8, top = 217, hp = 740, nm = 690, redline = 8.5, cg = 0.41, downforce = 140 },
	-- Lamborghini Gallardo LP560-4 Spyder (5.2 V10, 6-speed e-gear)
	lambrini_lp560 = { front = 0.43, drive = "AWD", rear = 0.7, gears = 6, box = "amt", shift = 0.15, tyreF = 235, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 8, caliper = "black", lugs = 5, stop = 34, z60 = 3.9, top = 201, hp = 552, nm = 540, redline = 8.5, cg = 0.44, downforce = 0 },
	-- Lamborghini Huracan EVO (5.2 V10, 7-speed LDF DCT)
	lambrini_huracan = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "dct", shift = 0.1, tyreF = 245, tyreR = 305, aspectF = 30, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 32, z60 = 2.9, top = 202, hp = 631, nm = 600, redline = 8.5, cg = 0.42, downforce = 80 },
	-- Lamborghini Huracan Performante Spyder (5.2 V10, 7-speed LDF DCT, ALA aero)
	lambrini_performante = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "dct", shift = 0.1, tyreF = 245, tyreR = 305, aspectF = 30, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 31, z60 = 3, top = 202, hp = 631, nm = 600, redline = 8.5, cg = 0.42, downforce = 150 },
	-- Lamborghini Huracan STO (5.2 V10, RWD, 7-speed LDF DCT)
	lambrini_sto = { front = 0.41, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 245, tyreR = 305, aspectF = 30, aspectR = 30, rimF = 20, rimR = 20, tyre = "cup", brakes = "ceramic", pistons = 6, caliper = "black", centerLock = true, lugs = 5, stop = 30, z60 = 2.8, top = 193, hp = 631, nm = 565, redline = 8.5, cg = 0.41, downforce = 335 },
	-- Lamborghini Huracan Sterrato (5.2 V10, 7-speed LDF DCT, all-terrain tyres)
	lambrini_sterrato = { front = 0.42, drive = "AWD", rear = 0.7, gears = 7, box = "dct", shift = 0.1, tyreF = 235, tyreR = 285, aspectF = 40, aspectR = 40, rimF = 19, rimR = 19, tyre = "offroad", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 36, z60 = 3.2, top = 162, hp = 602, nm = 560, redline = 8.5, cg = 0.47, downforce = 0 },
	-- Lamborghini Revuelto (6.5 V12 + 3 motors plug-in hybrid, 8-speed DCT)
	lambrini_revuelto = { front = 0.44, drive = "AWD", rear = 0.65, gears = 8, box = "dct", shift = 0.08, tyreF = 265, tyreR = 345, aspectF = 35, aspectR = 30, rimF = 20, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 10, caliper = "black", lugs = 5, stop = 30, z60 = 2.5, top = 217, hp = 1001, nm = 725, redline = 9.5, cg = 0.41, downforce = 150 },
	-- Lamborghini Murcielago LP670-4 SV (6.5 V12, 6-speed e-gear)
	lambrini_lp670 = { front = 0.42, drive = "AWD", rear = 0.72, gears = 6, box = "amt", shift = 0.12, tyreF = 245, tyreR = 335, aspectF = 35, aspectR = 30, rimF = 18, rimR = 18, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 32, z60 = 3.1, top = 212, hp = 661, nm = 660, redline = 8, cg = 0.43, downforce = 80 },
	-- Lamborghini Urus Performante (4.0 V8 twin-turbo, 8-speed auto)
	lambrini_urusp = { front = 0.56, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.2, tyreF = 285, tyreR = 325, aspectF = 40, aspectR = 35, rimF = 22, rimR = 22, tyre = "sport", brakes = "ceramic", pistons = 10, caliper = "black", lugs = 5, stop = 33, z60 = 3.1, top = 190, hp = 657, nm = 850, redline = 6.8, cg = 0.63, downforce = 10 },
	-- Ferrari 458 Spider (4.5 V8, 7-speed DCT)
	ferrara_458spider = { front = 0.42, drive = "RWD", gears = 7, box = "dct", shift = 0.08, tyreF = 235, tyreR = 295, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "red", lugs = 5, stop = 32, z60 = 3.2, top = 199, hp = 562, nm = 540, redline = 9, cg = 0.42, downforce = 210 },
	-- Ferrari 458 Speciale (4.5 V8, 7-speed DCT)
	ferrara_458speciale = { front = 0.42, drive = "RWD", gears = 7, box = "dct", shift = 0.06, tyreF = 245, tyreR = 305, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "cup", brakes = "ceramic", pistons = 6, caliper = "yellow", lugs = 5, stop = 30, z60 = 2.9, top = 202, hp = 597, nm = 540, redline = 9, cg = 0.41, downforce = 260 },
	-- Lamborghini Aventador SVJ (6.5 V12, 7-speed ISR, ALA 2.0)
	lambrini_svj = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "amt", shift = 0.05, tyreF = 255, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 30, z60 = 2.8, top = 217, hp = 759, nm = 720, redline = 8.7, cg = 0.41, downforce = 200 },
	-- Lamborghini Aventador SVJ 63 Roadster (6.5 V12, 7-speed ISR, ALA 2.0)
	lambrini_svj63 = { front = 0.43, drive = "AWD", rear = 0.7, gears = 7, box = "amt", shift = 0.05, tyreF = 255, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "black", lugs = 5, stop = 30, z60 = 2.9, top = 217, hp = 759, nm = 720, redline = 8.7, cg = 0.41, downforce = 200 },
	-- Lamborghini Murcielago LP640 Roadster (6.5 V12, 6-speed e-gear)
	lambrini_lp640 = { front = 0.42, drive = "AWD", rear = 0.72, gears = 6, box = "amt", shift = 0.15, tyreF = 245, tyreR = 335, aspectF = 35, aspectR = 30, rimF = 18, rimR = 18, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "black", lugs = 5, stop = 33, z60 = 3.4, top = 205, hp = 631, nm = 660, redline = 8, cg = 0.44, downforce = 30 },
	-- BMW 750Li xDrive (G12, 4.4 V8 twin-turbo, 8-speed auto)
	bnw_750li = { front = 0.52, drive = "AWD", rear = 0.6, gears = 8, box = "auto", shift = 0.25, tyreF = 245, tyreR = 275, aspectF = 40, aspectR = 35, rimF = 20, rimR = 20, tyre = "touring", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 36, z60 = 4.4, top = 155, hp = 445, nm = 650, redline = 6.5, cg = 0.53, downforce = 0 },
	-- Mercedes-Maybach GLS 600 4MATIC (X167, 4.0 V8 biturbo + EQ Boost, 9-speed auto)
	bentz_gls = { front = 0.52, drive = "AWD", rear = 0.55, gears = 9, box = "auto", shift = 0.3, tyreF = 285, tyreR = 325, aspectF = 45, aspectR = 40, rimF = 22, rimR = 22, tyre = "touring", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 38, z60 = 4.8, top = 155, hp = 550, nm = 730, redline = 6.5, cg = 0.75, downforce = 0 },
	-- Mercedes-Maybach S 680 4MATIC (Z223, 6.0 V12 biturbo, 9-speed auto)
	bentz_s680 = { front = 0.52, drive = "AWD", rear = 0.55, gears = 9, box = "auto", shift = 0.3, tyreF = 255, tyreR = 285, aspectF = 40, aspectR = 35, rimF = 21, rimR = 21, tyre = "touring", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 37, z60 = 4.4, top = 155, hp = 621, nm = 900, redline = 6, cg = 0.54, downforce = 0 },
	-- Lamborghini Countach LP5000 Quattrovalvole (5.2 V12, 5-speed manual)
	lambrini_countach = { front = 0.42, drive = "RWD", gears = 5, box = "manual", shift = 0.5, tyreF = 225, tyreR = 345, aspectF = 50, aspectR = 35, rimF = 15, rimR = 15, tyre = "sport", brakes = "steel", pistons = 4, caliper = "silver", lugs = 5, stop = 40, z60 = 4.9, top = 183, hp = 449, nm = 500, redline = 7.5, cg = 0.47, downforce = 0 },
	-- Toyota Chaser Tourer V (JZX100, 2.5 1JZ-GTE turbo, 5-speed manual, JDM 180 km/h limit)
	toyoka_chaser = { front = 0.54, drive = "RWD", gears = 5, box = "manual", shift = 0.45, tyreF = 205, tyreR = 205, aspectF = 55, aspectR = 55, rimF = 16, rimR = 16, tyre = "sport", brakes = "steel", pistons = 2, caliper = "grey", lugs = 5, stop = 39, z60 = 5.8, top = 112, hp = 276, nm = 378, redline = 7, cg = 0.5, downforce = 0 },
	-- Mercedes-Benz 190 E 2.5-16 Evolution II (W201, 5-speed manual)
	bentz_190e = { front = 0.53, drive = "RWD", gears = 5, box = "manual", shift = 0.45, tyreF = 245, tyreR = 245, aspectF = 40, aspectR = 40, rimF = 17, rimR = 17, tyre = "sport", brakes = "steel", pistons = 4, caliper = "grey", lugs = 5, stop = 39, z60 = 7.1, top = 155, hp = 232, nm = 245, redline = 7.6, cg = 0.48, downforce = 30 },
	-- Mercedes-Benz S 65 AMG (W221, 6.0 V12 biturbo, 5-speed auto)
	bentz_s65_w221 = { front = 0.54, drive = "RWD", gears = 5, box = "auto", shift = 0.5, tyreF = 255, tyreR = 275, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "silver", lugs = 5, stop = 37, z60 = 4.2, top = 155, hp = 604, nm = 1000, redline = 6, cg = 0.53, downforce = 0 },
	-- Maserati Levante GTS (3.8 V8 twin-turbo, 8-speed auto, Q4)
	maseroti_levante = { front = 0.5, drive = "AWD", rear = 0.8, gears = 8, box = "auto", shift = 0.25, tyreF = 265, tyreR = 295, aspectF = 40, aspectR = 35, rimF = 21, rimR = 21, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 36, z60 = 4, top = 181, hp = 542, nm = 730, redline = 6.8, cg = 0.62, downforce = 0 },
	-- Lexus LC 500 (5.0 V8, 10-speed auto)
	lexis_lc500 = { front = 0.52, drive = "RWD", gears = 10, box = "auto", shift = 0.25, tyreF = 245, tyreR = 275, aspectF = 40, aspectR = 35, rimF = 21, rimR = 21, tyre = "sport", brakes = "steel", pistons = 6, caliper = "silver", lugs = 5, stop = 34, z60 = 4.4, top = 168, hp = 471, nm = 540, redline = 7.3, cg = 0.48, downforce = 0 },
	-- Aston Martin DBX (4.0 V8 twin-turbo, 9-speed auto)
	astin_dbx = { front = 0.54, drive = "AWD", rear = 0.7, gears = 9, box = "auto", shift = 0.25, tyreF = 285, tyreR = 325, aspectF = 40, aspectR = 35, rimF = 22, rimR = 22, tyre = "sport", brakes = "steel", pistons = 6, caliper = "black", lugs = 5, stop = 37, z60 = 4.3, top = 181, hp = 542, nm = 700, redline = 6.5, cg = 0.65, downforce = 0 },
	-- Ferrari California (F149, 2009, 4.3 V8, 7-speed DCT)
	ferrara_california = { front = 0.47, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 245, tyreR = 285, aspectF = 40, aspectR = 40, rimF = 19, rimR = 19, tyre = "sport", brakes = "ceramic", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.8, top = 193, hp = 453, nm = 485, redline = 8, cg = 0.45, downforce = 0 },
	-- Bugatti Veyron 16.4 (8.0 W16 quad-turbo, 7-speed DSG, PAX tyres)
	bugotti_veyron = { front = 0.45, drive = "AWD", rear = 0.55, gears = 7, box = "dct", shift = 0.15, tyreF = 265, tyreR = 365, aspectF = 35, aspectR = 25, rimF = 20, rimR = 21, tyre = "sport", brakes = "ceramic", pistons = 8, caliper = "black", lugs = 5, stop = 31, z60 = 2.5, top = 253, hp = 987, nm = 1250, redline = 6.4, cg = 0.43, downforce = 250 },
	-- Bugatti Chiron (8.0 W16 quad-turbo, 7-speed DSG)
	bugotti_chiron = { front = 0.43, drive = "AWD", rear = 0.55, gears = 7, box = "dct", shift = 0.15, tyreF = 285, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "cup", brakes = "ceramic", pistons = 8, caliper = "black", lugs = 5, stop = 31, z60 = 2.4, top = 261, hp = 1479, nm = 1600, redline = 6.7, cg = 0.42, downforce = 300 },
	-- Bugatti Chiron Pur Sport (8.0 W16 quad-turbo, 7-speed DSG, short gearing, fixed wing)
	bugotti_chiron_pursport = { front = 0.43, drive = "AWD", rear = 0.55, gears = 7, box = "dct", shift = 0.15, tyreF = 285, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "cup", brakes = "ceramic", pistons = 8, caliper = "black", lugs = 5, stop = 30, z60 = 2.3, top = 218, hp = 1479, nm = 1600, redline = 6.9, cg = 0.41, downforce = 400 },
	-- Bugatti Chiron Super Sport (8.0 W16 quad-turbo, 7-speed DSG, longtail)
	bugotti_chiron_supersport = { front = 0.43, drive = "AWD", rear = 0.55, gears = 7, box = "dct", shift = 0.15, tyreF = 285, tyreR = 355, aspectF = 30, aspectR = 25, rimF = 20, rimR = 21, tyre = "cup", brakes = "ceramic", pistons = 8, caliper = "black", lugs = 5, stop = 31, z60 = 2.4, top = 273, hp = 1578, nm = 1600, redline = 7.1, cg = 0.42, downforce = 200 },
	-- BMW M5 (F10, 4.4 V8 twin-turbo, 7-speed M-DCT, M Driver's Package)
	bnw_m5_f10 = { front = 0.53, drive = "RWD", gears = 7, box = "dct", shift = 0.1, tyreF = 265, tyreR = 295, aspectF = 40, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "blue", lugs = 5, stop = 34, z60 = 4.2, top = 190, hp = 553, nm = 680, redline = 7.2, cg = 0.5, downforce = 0 },
	-- BMW M5 Competition (F90, 4.4 V8 twin-turbo, 8-speed auto, M xDrive, M Driver's Package)
	bnw_m5_f90 = { front = 0.54, drive = "AWD", rear = 0.7, gears = 8, box = "auto", shift = 0.2, tyreF = 275, tyreR = 285, aspectF = 35, aspectR = 35, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "blue", lugs = 5, stop = 33, z60 = 3.1, top = 190, hp = 617, nm = 750, redline = 7.2, cg = 0.5, downforce = 0 },
	-- Mercedes-AMG E 63 S 4MATIC+ (W213, 4.0 V8 biturbo, 9-speed MCT, Driver's Package)
	bentz_e63s = { front = 0.55, drive = "AWD", rear = 0.65, gears = 9, box = "auto", shift = 0.15, tyreF = 265, tyreR = 295, aspectF = 35, aspectR = 30, rimF = 20, rimR = 20, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.3, top = 186, hp = 603, nm = 850, redline = 7, cg = 0.5, downforce = 0 },
	-- Ford Focus RS (mk3, 2.3 EcoBoost turbo, 6-speed manual)
	dearb_focus_rs = { front = 0.59, drive = "AWD", rear = 0.5, gears = 6, box = "manual", shift = 0.45, tyreF = 235, tyreR = 235, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "steel", pistons = 4, caliper = "blue", lugs = 5, stop = 34, z60 = 4.6, top = 165, hp = 350, nm = 440, redline = 6.8, cg = 0.5, downforce = 0 },
	-- Mercedes-AMG A 45 S 4MATIC+ (W177, 2.0 turbo, 8-speed DCT)
	bentz_a45s = { front = 0.6, drive = "AWD", rear = 0.3, gears = 8, box = "dct", shift = 0.1, tyreF = 245, tyreR = 245, aspectF = 35, aspectR = 35, rimF = 19, rimR = 19, tyre = "sport", brakes = "drilled", pistons = 6, caliper = "red", lugs = 5, stop = 34, z60 = 3.8, top = 168, hp = 416, nm = 500, redline = 7.2, cg = 0.48, downforce = 0 },
}

return Data
