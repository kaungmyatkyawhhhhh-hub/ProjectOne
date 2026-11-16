"""make_place_run.py <sule|botataung> <asset id> -> build/landmarks/<x>/place_run.luau: one execute_luau body that loads
the asset, places it with PagodaPlace.luau under Workspace.Yangon1to1.Landmarks.<Name>, sets the TEMP plates and
reports in a workspace attribute (runs in task.spawn: MCP calls must stay under ~5 s)."""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
key, aid = sys.argv[1], sys.argv[2]
name = {"sule": "Sule", "botataung": "Botataung"}[key]
data = json.load(open(os.path.join(ROOT, "build", "landmarks", key, "place.json")))
data.pop("tris", None)
lib = open(os.path.join(HERE, "PagodaPlace.luau"), encoding="utf-8").read().replace("--!nocheck", "")
js = json.dumps(data, separators=(",", ":"))
code = """local P = (function()
%s
end)()
local HS = game:GetService("HttpService")
local data = HS:JSONDecode([==[%s]==])
local NAME, AID = "%s", %s
workspace:SetAttribute("PagodaPlace_" .. NAME, "running")
task.spawn(function()
	local ok, err = pcall(function()
		local ss = game:GetService("ServerStorage")
		local hold = Instance.new("Folder")
		hold.Name = "PagodaHolding_" .. NAME
		hold.Parent = ss
		local m = game:GetService("InsertService"):LoadAsset(AID)
		m.Parent = hold
		local L = workspace.Yangon1to1.Landmarks
		local a, b, c = P.place(m, L, NAME, data)
		local f = P.fidelity(L[NAME])
		P.plate(L, data.plate)
		if data.river then
			P.plate(L, data.river, Enum.Material.SmoothPlastic, Color3.fromRGB(112, 100, 76))
		end
		hold:Destroy()
		workspace:SetAttribute("PagodaPlace_" .. NAME, string.format("ok world %%d inst %%d coll %%d fid %%d", a, b, c, f))
	end)
	if not ok then
		workspace:SetAttribute("PagodaPlace_" .. NAME, "ERR " .. tostring(err))
	end
end)
return "started " .. NAME
""" % (lib, js, name, aid)
out = os.path.join(ROOT, "build", "landmarks", key, "place_run.luau")
open(out, "w", encoding="utf-8").write(code)
print(out, len(code))
