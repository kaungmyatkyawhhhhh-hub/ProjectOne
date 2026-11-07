-- ServerStorage.ClaudeTools.LampApply (Studio, Edit): puts the lamp shells (tools/lamps, Open Cloud packs in
-- ServerStorage.LampHolding) into each car in ReplicatedStorage.CarModels as LampFx_<role><L/R> parts.
--   require(LampApply:Clone()).run(holding)   add or replace
--   require(LampApply:Clone()).undo()         take every LampFx part out again
local M = {}

M.IDS = {
	"lexis_lfa", "lexis_lfa_circuit", "lambrini_lp700", "lambrini_lp750", "lambrini_revuelto", "lambrini_svj", "lambrini_svj63",
	"bugotti_veyron", "bugotti_veyron_sport", "bugotti_veyron_top", "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport",
}

local function num(s: string): number
	if s:sub(1, 1) == "n" then
		return -tonumber(s:sub(2)) / 1000
	end
	return tonumber(s) / 1000
end

function M.run(holding: Instance): string
	local n, skipped = 0, 0
	local cars = game.ReplicatedStorage.CarModels
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local i, role, cx, cy, cz, sx, sy, sz = string.match(d.Name, "^LF(%d+)_(%a+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
			local id = i and M.IDS[tonumber(i)]
			local model = id and cars:FindFirstChild(id)
			if model then
				local name = "LampFx_" .. role
				local old = model:FindFirstChild(name)
				if old then
					old:Destroy()
				end
				local q = d:Clone()
				q.Name = name
				q.Size = Vector3.new(math.max(num(sx), 0.002), math.max(num(sy), 0.002), math.max(num(sz), 0.002))
				-- (the importer turns everything round: a half turn puts the mesh back)
				q.CFrame = model:GetPivot() * CFrame.new(num(cx), num(cy), num(cz)) * CFrame.Angles(0, math.pi, 0)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.CastShadow = false
				q.Massless = true
				q.Material = Enum.Material.Neon
				q.Color = Color3.new(1, 1, 1)
				q.Transparency = 0.9
				q.Parent = model
				n += 1
				if n % 40 == 0 then
					task.wait()
				end
			else
				skipped += 1
			end
		end
	end
	return n .. " shells placed, " .. skipped .. " skipped"
end

function M.undo(): number
	local n = 0
	for _, id in M.IDS do
		for _, d in game.ReplicatedStorage.CarModels[id]:GetChildren() do
			if d.Name:sub(1, 7) == "LampFx_" then
				d:Destroy()
				n += 1
			end
		end
	end
	return n
end

return M
