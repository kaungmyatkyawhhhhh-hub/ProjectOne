--[[
	Unstack (Studio, Edit mode; 2026-11-03, owner: "buildings flash black and white depending on where
	you look from"): two faces on the same plane flicker (the renderer picks one or the other by
	angle). In a building, parts that overlap in volume and share a face plane on the same side (a
	dark Foot band over a pale Pier, a stone Sill sunk in a Band, two plaster parts whose textures are
	offset) are found, and the one that should be in front is pushed out 0.05 studs along that face.
	Which wins: FRONT ranks (a trim in front of the wall, the wall in front of the glass), then the
	smaller part. Each moved part keeps its total push in the attribute "Unstacked" (body space) so
	it can be undone.

	Unstack.building(model, body) -> parts moved
	Unstack.scan(model, body) -> pairs still on one plane (0 when done)
	Unstack.all(folder) -> parts moved, pairs left (every model with a Body)
	Unstack.undo(folder)
]]

local Unstack = {}

local PUSH = 0.05
local FRONT: { [string]: number } = {
	Sill = 9, Hood = 9, Course = 8, Door = 8, Sign = 8, Foot = 7, Parapet = 7, PlantRoom = 7, Cornice = 7,
	AC = 6, Planter = 6, UmbrellaPole = 6, Pier = 5, Band = 3, Glass = 2, Roof = 1,
}

type Box = { p: BasePart, lo: Vector3, hi: Vector3, vol: number }

local function boxes(model: Instance, body: BasePart): { Box }
	local out = {}
	for _, p in model:GetDescendants() do
		if p:IsA("Part") and p ~= body and p.Transparency < 0.5 and p.Shape == Enum.PartType.Block then
			local rel = body.CFrame:ToObjectSpace(p.CFrame)
			local rx, ry, rz = rel.RightVector, rel.UpVector, rel.LookVector
			local function axisAligned(v: Vector3): boolean
				return math.abs(v.X) > 0.999 or math.abs(v.Y) > 0.999 or math.abs(v.Z) > 0.999
			end
			if axisAligned(rx) and axisAligned(ry) then
				local s = p.Size
				local e = Vector3.new(
					math.abs(rx.X) * s.X + math.abs(ry.X) * s.Y + math.abs(rz.X) * s.Z,
					math.abs(rx.Y) * s.X + math.abs(ry.Y) * s.Y + math.abs(rz.Y) * s.Z,
					math.abs(rx.Z) * s.X + math.abs(ry.Z) * s.Y + math.abs(rz.Z) * s.Z
				) / 2
				table.insert(out, { p = p, lo = rel.Position - e, hi = rel.Position + e, vol = s.X * s.Y * s.Z })
			end
		end
	end
	return out
end

local AXES = { "X", "Y", "Z" }
local OTHER = { X = { "Y", "Z" }, Y = { "X", "Z" }, Z = { "X", "Y" } }
local UNIT = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }

-- calls fn(front, back, normal) for each pair sharing an OUTER face plane on the same side: a facade
-- face (X / Z, at or outside the core's face) or a top at or above the core's top; only those show,
-- and pushing only outward can't swing back and forth
local function pairsOnOnePlane(list: { Box }, half: Vector3, fn: (Box, Box, Vector3) -> ())
	for i = 1, #list do
		local a = list[i]
		for j = i + 1, #list do
			local b = list[j]
			local lo = Vector3.new(math.max(a.lo.X, b.lo.X), math.max(a.lo.Y, b.lo.Y), math.max(a.lo.Z, b.lo.Z))
			local hi = Vector3.new(math.min(a.hi.X, b.hi.X), math.min(a.hi.Y, b.hi.Y), math.min(a.hi.Z, b.hi.Z))
			local d = hi - lo
			if d.X > 0.01 and d.Y > 0.01 and d.Z > 0.01 then
				for _, ax in AXES do
					local o = OTHER[ax]
					if (d :: any)[o[1]] > 0.05 and (d :: any)[o[2]] > 0.05 then
						local sides: { number } = if ax == "Y" then { 1 } else { 1, -1 }
						for _, side in sides do
							local fa = if side == 1 then (a.hi :: any)[ax] else (a.lo :: any)[ax]
							local fb = if side == 1 then (b.hi :: any)[ax] else (b.lo :: any)[ax]
							local outer = fa * side >= (half :: any)[ax] - 0.01
							if outer and math.abs(fa - fb) < 0.03 then
								local ra, rb = FRONT[a.p.Name] or 4, FRONT[b.p.Name] or 4
								local aFront = if ra ~= rb then ra > rb else a.vol <= b.vol
								if aFront then
									fn(a, b, UNIT[ax] * side)
								else
									fn(b, a, UNIT[ax] * side)
								end
							end
						end
					end
				end
			end
		end
	end
end

function Unstack.scan(model: Instance, body: BasePart): number
	local n = 0
	pairsOnOnePlane(boxes(model, body), body.Size / 2, function()
		n += 1
	end)
	return n
end

function Unstack.building(model: Instance, body: BasePart): number
	local push: { [BasePart]: Vector3 } = {}
	pairsOnOnePlane(boxes(model, body), body.Size / 2, function(front: Box, _back: Box, normal: Vector3)
		local cur = push[front.p] or Vector3.zero
		-- the largest push along each axis (several pairs can ask for the same one)
		push[front.p] = Vector3.new(
			if normal.X ~= 0 then normal.X * PUSH else cur.X,
			if normal.Y ~= 0 then normal.Y * PUSH else cur.Y,
			if normal.Z ~= 0 then normal.Z * PUSH else cur.Z
		)
	end)
	local n = 0
	for p, v in push do
		p.CFrame = p.CFrame + body.CFrame:VectorToWorldSpace(v)
		local was = p:GetAttribute("Unstacked")
		p:SetAttribute("Unstacked", (if typeof(was) == "Vector3" then was else Vector3.zero) + v)
		n += 1
	end
	return n
end

function Unstack.all(folder: Instance): (number, number)
	local moved, left = 0, 0
	for i, model in folder:GetDescendants() do
		if model:IsA("Model") then
			local body = model:FindFirstChild("Body")
			if body and body:IsA("BasePart") then
				-- until nothing is left (a push can line a part up with the next one out)
				for _ = 1, 6 do
					local m = Unstack.building(model, body)
					moved += m
					if m == 0 then
						break
					end
				end
				left += Unstack.scan(model, body)
			end
		end
		if i % 400 == 0 then
			task.wait()
		end
	end
	return moved, left
end

function Unstack.undo(folder: Instance)
	for _, model in folder:GetDescendants() do
		if model:IsA("Model") then
			local body = model:FindFirstChild("Body")
			if body and body:IsA("BasePart") then
				for _, p in model:GetDescendants() do
					local v = p:GetAttribute("Unstacked")
					if p:IsA("BasePart") and typeof(v) == "Vector3" then
						p.CFrame = p.CFrame - body.CFrame:VectorToWorldSpace(v)
						p:SetAttribute("Unstacked", nil)
					end
				end
			end
		end
	end
end

return Unstack
