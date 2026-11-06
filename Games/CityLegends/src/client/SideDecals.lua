--[[
	Names on the new imports (owner, 2026-11-06). Pictures: tools/side_decals.py.

	lettering: our own version of the real cars' lettering, low on the doors, both sides. ZV = Zanna Vortice,
	ZVX = Zanna Vortice Xtrema, VTZ = Veloce Tracciato Zanna. A see-through flat part just off the door: it doesn't
	take Customs paint. Measured on each model's door (the mesh's faces, in Studio's edit mode): metres in the car's
	own frame, from the middle of its four wheel centres. at = the middle of the lettering on the right-hand door
	(+X; the left one is its mirror); slope = how far the door moves in, per metre towards the back; w, h = its size;
	wb = the wheelbase measured on; centre = the body's middle, when it isn't the car's.

	patches: "remove texts like SVJ and replace them with the fake model name in the same area". A real name that is
	part of a model's shape, not of a picture, can't be painted out: it gets a flat cover, and our name on it. Studs,
	in the car's frame (from Chassis), measured by raycasts in Play.
	at = where the front face sits; face = which way it looks; up = which way the top of the picture points;
	both = the same on the left (mirrored); disc = round. match = takes its colour from the part with that SrcName and
	a name Customs paints (src); image + tint = a see-through part with that picture.
]]
export type Lettering = { image: string, wb: number, at: Vector3, slope: number, w: number, h: number, centre: number? }
export type Patch = {
	at: Vector3,
	face: Vector3,
	up: Vector3?,
	w: number,
	h: number,
	both: boolean?,
	centre: number?, -- the body's middle, when it isn't the car's
	disc: boolean?,
	thick: number?,
	match: string?,
	src: string?,
	color: Color3?,
	image: string?,
	tint: Color3?,
}

local NAME = "rbxassetid://117371703794254" -- VELOCITÉ NOIR
local VTZ = "rbxassetid://122604460495176"
local ZVX = "rbxassetid://140375154364794"
local PLATE_VTZ = "rbxassetid://123629395076518" -- black, pointed ends: for lettering cut into a door
local PLATE_ZV = "rbxassetid://113429051811722"
local ENF = "rbxassetid://85459568757808"

local BLACK = Color3.fromRGB(14, 14, 16)
local DARK = Color3.fromRGB(24, 26, 30)
local ENGINE = Color3.fromRGB(20, 20, 23)

local SideDecals = {}

SideDecals.lettering = {
	lambrini_lp750 = { image = "rbxassetid://100891812021410", wb = 2.7, at = Vector3.new(0.9421, 0.09, -0.4), slope = -0.0612, w = 1.04, h = 0.196 },
	lambrini_svj = { image = "rbxassetid://85541267223079", wb = 2.7, at = Vector3.new(0.9421, 0.09, -0.4), slope = -0.0612, w = 1.04, h = 0.196 },
	-- (behind the door's big 63: it stays, it's our name too)
	lambrini_svj63 = { image = "rbxassetid://85180534105411", wb = 2.7, at = Vector3.new(0.893, 0.09, 0.05), slope = -0.075, w = 0.6, h = 0.113, centre = 0.018 },
} :: { [string]: Lettering }

SideDecals.patches = {
	-- BUGATTI across the wing
	bugotti_chiron_pursport = {
		{ at = Vector3.new(0, 1.475, 6.14), face = Vector3.yAxis, up = Vector3.new(0, 0, -1), w = 2.72, h = 0.74, thick = 0.14, color = DARK },
		{ at = Vector3.new(0, 1.5, 6.14), face = Vector3.yAxis, up = Vector3.new(0, 0, -1), w = 2.4, h = 0.6, image = NAME, tint = Color3.fromRGB(32, 140, 240) },
	},
	-- STO on the doors (a plate over its outline and letters) and across the back
	lambrini_sto = {
		{ at = Vector3.new(2.82, -0.16, -1.39), face = Vector3.new(1, 0.13, 0.036), up = Vector3.new(0, 1, -0.1126), w = 2.3, h = 0.38, both = true, image = PLATE_VTZ },
		{ at = Vector3.new(0, 0.12, 6.21), face = Vector3.zAxis, w = 0.96, h = 0.16, thick = 0.08, color = Color3.fromRGB(96, 100, 108) },
		{ at = Vector3.new(0, 0.12, 6.23), face = Vector3.zAxis, w = 0.56, h = 0.14, image = VTZ, tint = BLACK },
	},
	-- the SV behind the door
	lambrini_lp750 = {
		{ at = Vector3.new(3.0, -0.9, 1.66), face = Vector3.new(1, -0.25, -0.048), w = 1.62, h = 0.46, both = true, image = PLATE_ZV },
	},
	-- the small SV by the front wheel (the big one on the rear wing can't be covered flat: tools/road_mesh's route, see the notes)
	lambrini_lp670 = {
		{ at = Vector3.new(2.79, -0.79, -2.22), face = Vector3.new(1, 0.02, -0.032), w = 1.42, h = 0.3, both = true, image = PLATE_ZV },
	},
	-- SV in the red panels on the engine lid
	lambrini_svj63 = {
		{ at = Vector3.new(1.546, 1.27, 3.98), face = Vector3.new(-0.012, 1, 0.165), up = Vector3.new(-1, 0, 0), w = 1.05, h = 0.33, both = true, centre = 0.054, thick = 0.04, match = "Body_Stripe_Red", src = "Body_Stripe_Patch" },
		{ at = Vector3.new(1.546, 1.285, 3.98), face = Vector3.new(-0.012, 1, 0.165), up = Vector3.new(-1, 0, 0), w = 0.96, h = 0.24, both = true, centre = 0.054, image = ZVX, tint = BLACK },
	},
	-- the maker's script on the engine covers (it's part of the model's shape)
	lambrini_lp570 = {
		{ at = Vector3.new(-0.47, 0.76, 2.58), face = Vector3.yAxis, up = Vector3.new(1, 0, 0), w = 0.86, h = 0.18, thick = 0.03, color = ENGINE },
		{ at = Vector3.new(-0.47, 0.78, 2.58), face = Vector3.yAxis, up = Vector3.new(1, 0, 0), w = 0.8, h = 0.16, image = ENF },
		{ at = Vector3.new(0.24, 0.76, 2.58), face = Vector3.yAxis, up = Vector3.new(-1, 0, 0), w = 0.86, h = 0.18, thick = 0.03, color = ENGINE },
		{ at = Vector3.new(0.24, 0.78, 2.58), face = Vector3.yAxis, up = Vector3.new(-1, 0, 0), w = 0.8, h = 0.16, image = ENF },
	},
	lambrini_revuelto = {
		{ at = Vector3.new(-0.245, 0.98, 2.76), face = Vector3.yAxis, up = Vector3.new(1, 0, 0), w = 0.88, h = 0.17, thick = 0.03, color = ENGINE },
		{ at = Vector3.new(-0.245, 1.0, 2.76), face = Vector3.yAxis, up = Vector3.new(1, 0, 0), w = 0.8, h = 0.15, image = ENF },
		{ at = Vector3.new(0.245, 0.98, 2.76), face = Vector3.yAxis, up = Vector3.new(-1, 0, 0), w = 0.88, h = 0.17, thick = 0.03, color = ENGINE },
		{ at = Vector3.new(0.245, 1.0, 2.76), face = Vector3.yAxis, up = Vector3.new(-1, 0, 0), w = 0.8, h = 0.15, image = ENF },
	},
	-- the plates on the engine covers
	bugotti_veyron = {
		{ at = Vector3.new(0.72, 0.9, 3.3), face = Vector3.yAxis, w = 0.3, h = 0.24, both = true, thick = 0.04, color = DARK },
	},
	-- the fuel caps
	bugotti_veyron_sport = {
		{ at = Vector3.new(-2.27, 1.135, 1.85), face = Vector3.new(-0.68, 0.73, 0.09), w = 0.62, h = 0.62, disc = true, thick = 0.04, color = DARK },
		{ at = Vector3.new(2.3, 1.105, 1.82), face = Vector3.new(0.71, 0.7, 0.08), w = 0.62, h = 0.62, disc = true, thick = 0.04, color = DARK },
	},
	bugotti_veyron_top = {
		{ at = Vector3.new(-2.265, 1.165, 1.85), face = Vector3.new(-0.7, 0.71, 0.05), w = 0.62, h = 0.62, disc = true, thick = 0.04, color = DARK },
		{ at = Vector3.new(2.305, 1.125, 1.82), face = Vector3.new(0.71, 0.71, 0.05), w = 0.62, h = 0.62, disc = true, thick = 0.04, color = DARK },
	},
} :: { [string]: { Patch } }

return SideDecals
