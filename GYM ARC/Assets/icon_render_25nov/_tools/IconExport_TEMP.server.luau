-- TEMP (25 Nov, icon render): exports ServerStorage.ThumbnailScene models as OBJ text to the Blender receiver on
-- 127.0.0.1:34999. HOW: put this as a Script in ServerScriptService, set attribute Models = "NAME1,NAME2", press Play
-- (the Studio Assistant blocks localhost HTTP from execute_luau, a Play-mode server Script is not blocked), Stop, DELETE it.
-- The receiver runs inside Blender (see the progress note). Studio only (does nothing in a live server).
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local HS = game:GetService("HttpService")
local AS = game:GetService("AssetService")
local names = string.split(script:GetAttribute("Models") or "ICON_curl", ",")
for _, NAME in ipairs(names) do
	local ok, err = pcall(function()
		local m = game.ServerStorage.ThumbnailScene:FindFirstChild(NAME)
		if not m then warn("[IconExport] missing", NAME) return end
		local url = "http://127.0.0.1:34999/" .. NAME .. ".obj"
		local buf = { "# GYM ARC icon export (25 Nov), " .. NAME .. ", studs, Roblox Y-up" }
		local function mark(p, shape)
			local c = { p.CFrame:GetComponents() }
			local s = {}
			for i = 1, 12 do s[i] = string.format("%.4f", c[i]) end
			table.insert(buf, string.format("# MARK %s %s %.4f %.4f %.4f %s | %s", p.Name, shape, p.Size.X, p.Size.Y, p.Size.Z, p.Color:ToHex(), table.concat(s, " ")))
		end
		local parts = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				if d.Name:find("JointFill") then mark(d, "Ball")
				elseif d:IsA("MeshPart") and d.Name:find("Stage") then table.insert(parts, d)
				elseif d:IsA("MeshPart") then mark(d, "MeshPart")
				else mark(d, "Part") end
			end
		end
		HS:PostAsync(url, table.concat(buf, "\n") .. "\n")
		local vbase = 0
		for _, p in ipairs(parts) do
			local ok2, em = pcall(function() return AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId)) end)
			if not ok2 then warn("[IconExport] FAIL", p.Name, em) continue end
			local ids = em:GetVertices()
			local idx, pos = {}, {}
			local mn = Vector3.new(math.huge, math.huge, math.huge)
			local mx = -mn
			for i, v in ipairs(ids) do local q = em:GetPosition(v) pos[i] = q idx[v] = i mn = mn:Min(q) mx = mx:Max(q) end
			local ctr, sc = (mn + mx) / 2, p.Size / (mx - mn)
			local lines = { "o " .. p.Name .. "__" .. tostring(p:GetAttribute("BodyStageKind") or "") .. "__" .. p.Color:ToHex() }
			for _, q in ipairs(pos) do local w = p.CFrame * ((q - ctr) * sc) lines[#lines + 1] = string.format("v %.4f %.4f %.4f", w.X, w.Y, w.Z) end
			for _, f in ipairs(em:GetFaces()) do
				local fv = em:GetFaceVertices(f)
				lines[#lines + 1] = string.format("f %d %d %d", vbase + idx[fv[1]], vbase + idx[fv[2]], vbase + idx[fv[3]])
			end
			vbase += #pos
			local body = table.concat(lines, "\n") .. "\n"
			for s = 1, #body, 900000 do HS:PostAsync(url .. "?append=1", body:sub(s, s + 899999)) end
			print("[IconExport]", NAME, p.Name, #pos)
			em:Destroy()
			task.wait()
		end
	end)
	print("[IconExport] DONE", NAME, ok, err)
end
