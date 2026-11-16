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
}
KD.VARIANT = {
	KW0 = "YgnRenderPainted", KW1 = "YgnRenderPainted", KW2 = "YgnRenderPainted", KW3 = "YgnRenderPainted",
	KW4 = "YgnRenderPainted", KW5 = "YgnRenderPainted", KW6 = "YgnRenderPainted", KW7 = "YgnRenderPainted",
	KWB = "YgnRenderPainted", KWG = "YgnRenderStained", KWD2 = "YgnRenderStained", KWC = "YgnRenderStained",
	KGR = "YgnSteelPainted", KAR = "YgnCanvas", KCO = "YgnConcreteBare", KRG = "YgnCorrugatedZinc",
	KRF = "YgnCorrugatedRust", KRB = "YgnCorrugatedBlue", KRT = "YgnClayRoofTile",
}

local looks = {} -- code -> { material, variant name }
function KD.look(q: BasePart, code: string, color: Color3?)
	local l = looks[code]
	if not l then
		local v = KD.VARIANT[code]
		local mv = v and MaterialService:FindFirstChild(v)
		if mv and mv:IsA("MaterialVariant") then
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
			table.insert(T[pid], { kind = kind, part = q, c = q:GetAttribute("C"), size = q:GetAttribute("S") })
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
	local out = { tile = 256, pids = {}, codes = {} }
	out.tile = tonumber(string.match(text, "TILE=([%d%.]+)")) or 256
	for w in string.gmatch(string.match(text, "PIDS=([^\n]*)") or "", "%S+") do
		table.insert(out.pids, w)
	end
	for w in string.gmatch(string.match(text, "CODES=([^\n]*)") or "", "%S+") do
		table.insert(out.codes, w)
	end
	return out
end

local LEN = { [string.byte("P")] = 21, [string.byte("Q")] = 27, [string.byte("B")] = 25 }

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
		if t == 66 then -- "B"
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
					q.CFrame = cf * CFrame.new(tp.c.X * sx, tp.c.Y * sy, tp.c.Z * sz)
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
