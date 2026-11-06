--[[
	Names on the new imports (owner, 2026-11-06). Pictures: tools/side_decals.py.

	lettering: our own version of the real cars' lettering, low on the doors, both sides. ZV = Zanna Vortice,
	ZVX = Zanna Vortice Xtrema, VTZ = Veloce Tracciato Zanna. A see-through flat part just off the door: it doesn't
	take Customs paint. Measured on each model's door (the mesh's faces, in Studio's edit mode): metres in the car's
	own frame, from the middle of its four wheel centres. at = the middle of the lettering on the right-hand door
	(+X; the left one is its mirror); slope = how far the door moves in, per metre towards the back; w, h = its size;
	wb = the wheelbase measured on; centre = the body's middle, when it isn't the car's.

	patches: flat covers, for the last real names in a model's shape. The owner wants no covers (2026-11-06): the old
	letters are taken out of the mesh and ours laid in their place (tools/retext.py, tools/riviera/RetextApply.luau), so
	this list should stay empty or close to it. Studs, in the car's frame (from Chassis), measured by raycasts in Play.
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

local SideDecals = {}

SideDecals.lettering = {
	lambrini_lp750 = { image = "rbxassetid://100891812021410", wb = 2.7, at = Vector3.new(0.9421, 0.09, -0.4), slope = -0.0612, w = 1.04, h = 0.196 },
	lambrini_svj = { image = "rbxassetid://85541267223079", wb = 2.7, at = Vector3.new(0.9421, 0.09, -0.4), slope = -0.0612, w = 1.04, h = 0.196 },
	-- (behind the door's big 63: it stays, it's our name too)
	lambrini_svj63 = { image = "rbxassetid://85180534105411", wb = 2.7, at = Vector3.new(0.893, 0.09, 0.05), slope = -0.075, w = 0.6, h = 0.113, centre = 0.018 },
} :: { [string]: Lettering }

SideDecals.patches = {
} :: { [string]: { Patch } }

return SideDecals
