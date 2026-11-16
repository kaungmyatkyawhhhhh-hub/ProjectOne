--[[
	YangonKitData (2026-11-16, light pass of the 1:1 Yangon buildings): reads the packed kit detail made by
	tools/yangon/city/buildings_1to1.py + kit_pack.py and builds it from the shared kit templates.

	The place keeps only each building's shell (Workspace.Yangon1to1.Buildings.Shell: its collision boxes drawn in the
	wall colour, plus the pitched roofs). The facade panels, piers, party walls, flat roof slabs, roof props, drainpipes,
	AC units, compound walls and gates are data: ReplicatedStorage.YgnKit.Data_<district> holds a StringValue Meta and one
	StringValue a 256-stud tile ("i_j"). client/YangonKitStream builds the tiles near the camera with this module; the
	Edit tool (tools/yangon/YangonKitPlace.luau `preview`) uses it too.

	Record format (fixed width, 64-symbol digits; see kit_pack.py):
	  P pid(2) x(4) y(3) z(4) yaw(3) sx(3) code(1)            a kit piece
	  Q ... as P ... sy(3) sz(3)                              a kit piece scaled in Y / Z too
	  B x(4) y(3) z(4) yaw(3) sx(3) sy(3) sz(3) code(1)       a plain Part (code WCOL: compound-wall collision)
	Street detail (2026-11-16, tools/yangon/city/street_1to1.py; Data_<district>S, Meta LOAD / ATTACH / ATLAS / CELL):
	  L x1(4) y1(3) z1(4) yaw1(3) x2(4) y2(3) z2(4) yaw2(3) n(1) seed(1)   n black cables between two power poles (Beams
	                                                                        between the Meta ATTACH points of each pole)
	  K x1(4) y1(3) z1(4) x2(4) y2(3) z2(4) sag(2)                         one cable (a service drop to a house)
	  T x(4) y(3) z(4) yaw(3) w(2) h(2) atlas(1) cell(2)                   a name plate: an atlas cell on a SurfaceGui
	                                                                        (faces local -Z; an invisible carrier part)

	local KD = require(ReplicatedStorage.Shared.YangonKitData)
	local T = KD.index(templatesFolder)          -- pid -> pieces
	local meta = KD.meta(dataFolder)             -- { tile, pids, codes }
	local job = KD.job(str, i, j, meta, T, parentFolder)
	while not job:step(200) do task.wait() end   -- builds up to 200 parts a step
]]

local MaterialService = game:GetService("MaterialService")

local KD = {}

local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end
local TWO_PI = 2 * math.pi

local function num(s: string, a: number, n: number): number
	local v = 0
	for k = a, a + n - 1 do
		v = v * 64 + VAL[string.byte(s, k)]
	end
	return v
end
KD.num = num

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- landmark_glb3d.GROUPS (midday calibrated) for the wall codes the generator uses (same as YangonKitPlace)
KD.WALL = {
	KW0 = rgb(252, 255, 250), KW1 = rgb(255, 215, 153), KW2 = rgb(178, 242, 255), KW3 = rgb(199, 168, 130),
	KW4 = rgb(226, 248, 255), KW5 = rgb(255, 197, 187), KW6 = rgb(255, 252, 243), KW7 = rgb(208, 255, 165),
	KWG = rgb(162, 160, 150), KWB = rgb(173, 209, 250), KWC = rgb(144, 145, 136), KWD2 = rgb(181, 172, 162),
	-- (2026-11-16, real places: places_1to1.py) fuel stations, car parks, courts, playgrounds
	PCN = rgb(196, 194, 188), PAS = rgb(84, 84, 86), PLN = rgb(236, 236, 230), PLY = rgb(232, 196, 64),
	PCW = rgb(240, 240, 236), PCS = rgb(214, 216, 212), PFG = rgb(46, 140, 82), PFR = rgb(196, 40, 40),
	PFB = rgb(30, 84, 160), PFY = rgb(240, 196, 40), PPD = rgb(40, 42, 46), PGL = rgb(60, 72, 80),
	PST = rgb(150, 154, 160), PRB = rgb(150, 70, 50), PCG = rgb(78, 128, 92), PLT = rgb(255, 250, 236),
	PSD = rgb(214, 196, 160), PCR = rgb(160, 175, 148),
}
-- plain-material codes (no MaterialVariant): Neon canopy lights, glass, plastic
KD.MAT = { PLT = Enum.Material.Neon, PGL = Enum.Material.Glass, PFG = Enum.Material.SmoothPlastic,
	PFR = Enum.Material.SmoothPlastic, PFB = Enum.Material.SmoothPlastic, PFY = Enum.Material.SmoothPlastic,
	PPD = Enum.Material.SmoothPlastic, PLY = Enum.Material.SmoothPlastic, PCW = Enum.Material.SmoothPlastic, PCR = Enum.Material.SmoothPlastic }
KD.VARIANT = {
	KW0 = "YgnRenderPainted", KW1 = "YgnRenderPainted", KW2 = "YgnRenderPainted", KW3 = "YgnRenderPainted",
	KW4 = "YgnRenderPainted", KW5 = "YgnRenderPainted", KW6 = "YgnRenderPainted", KW7 = "YgnRenderPainted",
	KWB = "YgnRenderPainted", KWG = "YgnRenderStained", KWD2 = "YgnRenderStained", KWC = "YgnRenderStained",
	KGR = "YgnSteelPainted", KAR = "YgnCanvas", KCO = "YgnConcreteBare", KRG = "YgnCorrugatedZinc",
	KRF = "YgnCorrugatedRust", KRB = "YgnCorrugatedBlue", KRT = "YgnClayRoofTile",
	PCN = "YgnConcreteStained", PAS = "YgnAsphaltWorn", PLN = "YgnConcreteBare", PCS = "YgnSteelPainted",
	PST = "YgnSteelPainted", PRB = "YgnBrickRed", PCG = "YgnConcreteBare", PSD = "YgnDirtPacked",
}

local looks = {} -- code -> { material, variant name }
function KD.look(q: BasePart, code: string, color: Color3?)
	local l = looks[code]
	if not l then
		local v = KD.VARIANT[code]
		local mv = v and MaterialService:FindFirstChild(v)
		if KD.MAT[code] then
			l = { KD.MAT[code], "" }
		elseif mv and mv:IsA("MaterialVariant") then
			l = { mv.BaseMaterial, v }
		else
			l = { Enum.Material.SmoothPlastic, "" }
		end
		looks[code] = l
	end
	q.Material = l[1]
	q.MaterialVariant = l[2]
	q.Color = color or Color3.new(1, 1, 1)
end

-- templates are named KIND_<pid> with attributes C (middle) and S (size) in the piece's own frame
function KD.index(store: Instance)
	local T = {}
	for _, q in store:GetChildren() do
		local kind, pid = string.match(q.Name, "^(%u+)_(%w+)$")
		if kind and q:IsA("BasePart") then
			T[pid] = T[pid] or {}
			-- (2026-11-16, greenery) optional attribute R: the piece's own rotation in the record frame (CFrame; the
			-- reused old-map tree meshes sit turned in their models)
			table.insert(T[pid], { kind = kind, part = q, c = q:GetAttribute("C"), size = q:GetAttribute("S"), r = q:GetAttribute("R") })
		end
	end
	return T
end

function KD.meta(folder: Instance)
	local m = folder:FindFirstChild("Meta")
	if not m then
		return nil
	end
	local text = (m :: StringValue).Value
	local out = { tile = 256, pids = {}, codes = {}, attach = {}, atlas = {} }
	out.tile = tonumber(string.match(text, "TILE=([%d%.]+)")) or 256
	out.load = tonumber(string.match(text, "LOAD=([%d%.]+)") or "")
	for a, b, c in string.gmatch(string.match(text, "ATTACH=([^\n]*)") or "", "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		table.insert(out.attach, Vector3.new(tonumber(a) :: number, tonumber(b) :: number, tonumber(c) :: number))
	end
	for w in string.gmatch(string.match(text, "ATLAS=([^\n]*)") or "", "%S+") do
		table.insert(out.atlas, if string.match(w, "^%d+$") then "rbxassetid://" .. w else w)
	end
	local cw, ch, cols = string.match(text, "CELL=(%d+) (%d+) (%d+)")
	out.cell = { tonumber(cw) or 256, tonumber(ch) or 88, tonumber(cols) or 4 }
	for w in string.gmatch(string.match(text, "PIDS=([^\n]*)") or "", "%S+") do
		table.insert(out.pids, w)
	end
	for w in string.gmatch(string.match(text, "CODES=([^\n]*)") or "", "%S+") do
		table.insert(out.codes, w)
	end
	return out
end

local LEN = {
	[string.byte("P")] = 21, [string.byte("Q")] = 27, [string.byte("B")] = 25,
	[string.byte("L")] = 31, [string.byte("K")] = 25, [string.byte("T")] = 22,
}
local WIRE_COLOR = ColorSequence.new(Color3.fromRGB(22, 22, 24))
local WIRE_T = NumberSequence.new(0)

-- a sagging black cable (old YangonDetails' Beam look): attachments on the tile's invisible anchor part
local function wire(anchor: BasePart, a: Vector3, b: Vector3, sag: number, width: number)
	local att0 = Instance.new("Attachment")
	att0.Parent = anchor -- (parent first: WorldCFrame on an unparented attachment is taken as local)
	att0.WorldCFrame = CFrame.fromMatrix(a, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
	local att1 = Instance.new("Attachment")
	att1.Parent = anchor -- (parent first: WorldCFrame on an unparented attachment is taken as local)
	att1.WorldCFrame = CFrame.fromMatrix(b, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = width
	beam.Width1 = width
	beam.Color = WIRE_COLOR
	beam.Transparency = WIRE_T
	beam.LightInfluence = 1
	beam.FaceCamera = true
	beam.Segments = 10
	beam.CurveSize0 = sag
	beam.CurveSize1 = -sag
	beam.Texture = ""
	beam.Parent = anchor
end
KD.wire = wire

local function visual(q: BasePart)
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.CastShadow = true
end

-- a resumable build of one tile's string into `parent`
local Job = {}
Job.__index = Job

function KD.job(s: string, i: number, j: number, meta, T, parent: Instance)
	return setmetatable({ s = s, pos = 1, x0 = i * meta.tile, z0 = j * meta.tile, meta = meta, T = T, parent = parent,
		parts = 0, missing = 0, batch = {} }, Job)
end

-- builds up to `budget` parts; true when the tile is done
function Job:step(budget: number): boolean
	local s, x0, z0, meta, T = self.s, self.x0, self.z0, self.meta, self.T
	local n = #s
	local made = 0
	local batch = self.batch
	while self.pos <= n and made < budget do
		local p = self.pos
		local t = string.byte(s, p)
		local L = LEN[t]
		if not L then
			self.pos = n + 1
			break
		end
		if t == 76 or t == 75 then -- "L" / "K": cables
			if not self.anchor then
				local a = Instance.new("Part")
				a.Name = "Wires"
				a.Anchored = true
				a.CanCollide = false
				a.CanQuery = false
				a.CanTouch = false
				a.Transparency = 1
				a.Size = Vector3.new(1, 1, 1)
				a.CFrame = CFrame.new(x0, 0, z0)
				a.Parent = self.parent
				self.anchor = a
			end
			local x1 = num(s, p + 1, 4) / 500 - 16384 + x0
			local y1 = num(s, p + 5, 3) / 200 - 200
			local z1 = num(s, p + 8, 4) / 500 - 16384 + z0
			if t == 76 then
				local a1 = num(s, p + 12, 3) / 262144 * TWO_PI
				local x2 = num(s, p + 15, 4) / 500 - 16384 + x0
				local y2 = num(s, p + 19, 3) / 200 - 200
				local z2 = num(s, p + 22, 4) / 500 - 16384 + z0
				local a2 = num(s, p + 26, 3) / 262144 * TWO_PI
				local n = VAL[string.byte(s, p + 29)]
				local seed = VAL[string.byte(s, p + 30)]
				local cf1 = CFrame.new(x1, y1, z1) * CFrame.Angles(0, a1, 0)
				local cf2 = CFrame.new(x2, y2, z2) * CFrame.Angles(0, a2, 0)
				local dist = (Vector3.new(x2, y2, z2) - Vector3.new(x1, y1, z1)).Magnitude
				local att = meta.attach
				local m = math.min(n, #att)
				for k = 1, m do
					local o = att[k]
					local sag = dist * (0.022 + 0.004 * ((seed + k * 7) % 5)) + 0.15 * ((seed + k) % 3)
					wire(self.anchor, (cf1 * CFrame.new(o)).Position, (cf2 * CFrame.new(o)).Position, sag, if k <= 4 then 0.09 else 0.12)
				end
				made += m
			else
				local x2 = num(s, p + 12, 4) / 500 - 16384 + x0
				local y2 = num(s, p + 16, 3) / 200 - 200
				local z2 = num(s, p + 19, 4) / 500 - 16384 + z0
				local sag = num(s, p + 23, 2) / 100
				wire(self.anchor, Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), sag, 0.08)
				made += 1
			end
		elseif t == 84 then -- "T": a name plate
			local x = num(s, p + 1, 4) / 500 - 16384 + x0
			local y = num(s, p + 5, 3) / 200 - 200
			local z = num(s, p + 8, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 12, 3) / 262144 * TWO_PI
			local w, h = num(s, p + 15, 2) / 50, num(s, p + 17, 2) / 50
			local a = VAL[string.byte(s, p + 19)] + 1
			local cell = num(s, p + 20, 2)
			local img = meta.atlas[a]
			if img and img ~= "-" then
				local q = Instance.new("Part")
				q.Name = "Plate"
				q.Size = Vector3.new(w, h, 0.05)
				q.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
				q.Transparency = 1
				visual(q)
				q.CastShadow = false
				local cw, ch, cols = meta.cell[1], meta.cell[2], meta.cell[3]
				local g = Instance.new("SurfaceGui")
				g.Face = Enum.NormalId.Front
				g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
				g.CanvasSize = Vector2.new(cw, ch)
				g.LightInfluence = 1
				g.MaxDistance = 260
				local im = Instance.new("ImageLabel")
				im.BackgroundTransparency = 1
				im.Size = UDim2.fromScale(1, 1)
				im.Image = img
				im.ImageRectOffset = Vector2.new((cell % cols) * cw, math.floor(cell / cols) * ch)
				im.ImageRectSize = Vector2.new(cw, ch)
				im.Parent = g
				g.Parent = q
				table.insert(batch, q)
				made += 1
			end
		elseif t == 66 then -- "B"
			local x = num(s, p + 1, 4) / 500 - 16384 + x0
			local y = num(s, p + 5, 3) / 200 - 200
			local z = num(s, p + 8, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 12, 3) / 262144 * TWO_PI
			local sx, sy, sz = num(s, p + 15, 3) / 200, num(s, p + 18, 3) / 200, num(s, p + 21, 3) / 200
			local code = meta.codes[VAL[string.byte(s, p + 24)] + 1]
			local q = Instance.new("Part")
			q.Size = Vector3.new(sx, sy, sz)
			q.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
			q.Name = code
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			if code == "WCOL" then
				-- compound-wall collision (client-side: the local character and car are simulated here)
				q.Anchored = true
				q.Transparency = 1
				q.CanCollide = true
				q.CanQuery = true
				q.CanTouch = false
				q.CastShadow = false
			else
				visual(q)
				KD.look(q, code, KD.WALL[code])
			end
			table.insert(batch, q)
			made += 1
		else
			local pid = meta.pids[num(s, p + 1, 2) + 1]
			local x = num(s, p + 3, 4) / 500 - 16384 + x0
			local y = num(s, p + 7, 3) / 200 - 200
			local z = num(s, p + 10, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 14, 3) / 262144 * TWO_PI
			local sx = num(s, p + 17, 3) / 50000 + 0.1
			local code = meta.codes[VAL[string.byte(s, p + 20)] + 1]
			local sy, sz = 1, 1
			if t == 81 then -- "Q"
				sy = num(s, p + 21, 3) / 5000 + 0.05
				sz = num(s, p + 24, 3) / 5000 + 0.05
			end
			local pieces = T[pid]
			if not pieces then
				self.missing += 1
			else
				local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
				for _, tp in pieces do
					local q = tp.part:Clone()
					q.Size = Vector3.new(tp.size.X * sx, tp.size.Y * sy, tp.size.Z * sz)
					q.CFrame = cf * CFrame.new(tp.c.X * sx, tp.c.Y * sy, tp.c.Z * sz) * (tp.r or CFrame.identity)
					if tp.kind == "KWX" then
						q.Name = code
						KD.look(q, code, KD.WALL[code])
					end
					table.insert(batch, q)
					made += 1
				end
			end
		end
		self.pos = p + L
	end
	for _, q in batch do
		q.Parent = self.parent
	end
	self.parts += #batch
	table.clear(batch)
	return self.pos > n
end

return KD
