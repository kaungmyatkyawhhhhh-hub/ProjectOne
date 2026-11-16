"""Writes the Studio placer (Luau, for the MCP execute_luau) for a bahan_buddhas3d landmark.

    python bahan_place_luau.py <key> <asset id>  -> build/landmarks/<key>/<key>_place.luau
Run the printed file's text in Studio (Edit). It LoadAssets the .glb model into ServerStorage._Hold_<Name> in a task.spawn,
places every MeshPart by its name (KIND_tag_cx_cy_cz_sx_sy_sz in hundredths of a stud, glb.py: the mesh lands straight,
CFrame.new(centre)), gives each group its look, builds the invisible collision and the *_TEMP ground plate, deletes the
holding folder and sets attribute Status on Workspace.Yangon1to1.Landmarks.<Name> ("done n parts" / "error ...").
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

key, asset = sys.argv[1], sys.argv[2]
P = json.load(open(os.path.join(ROOT, "build", "landmarks", key, key + "_place.json")))
look = ",\n".join('  %s = {"%s", %d, %d, %d, "%s", %s}' % (k, v[0], *v[1], v[2], v[3]) for k, v in sorted(P["look"].items()))
coll = ",\n".join("  {%s}" % ", ".join(str(x) for x in r) for r in P["collide"])
px, py, pz = P["pivot"]
lua = """-- %(name)s placer (bahan_buddhas3d.py), asset %(asset)s
local NAME, ASSET = "%(name)s", %(asset)s
local LOOK = {
%(look)s
}
local COLL = {
%(coll)s
}
local PIVOT = Vector3.new(%(px)s, %(py)s, %(pz)s)
local PLATE = Vector2.new(%(plx)s, %(plz)s)
local PLATE_YAW = %(pyaw)s
local SS = game:GetService("ServerStorage")
local root = workspace:FindFirstChild("Yangon1to1")
local lm = root:FindFirstChild("Landmarks") or Instance.new("Folder", root)
lm.Name = "Landmarks"
local old = lm:FindFirstChild(NAME)
if old then old:Destroy() end
local model = Instance.new("Model")
model.Name = NAME
model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
model:SetAttribute("Status", "loading")
model:SetAttribute("Asset", ASSET)
model:SetAttribute("Source", "tools/yangon/landmarks3d/bahan_buddhas3d.py")
model.Parent = lm
task.spawn(function()
  local ok, err = pcall(function()
    local hold = SS:FindFirstChild("_Hold_" .. NAME)
    if hold then hold:Destroy() end
    hold = Instance.new("Folder")
    hold.Name = "_Hold_" .. NAME
    hold.Parent = SS
    local a = game:GetService("InsertService"):LoadAsset(ASSET)
    a.Parent = hold
    local vis = Instance.new("Folder"); vis.Name = "Visual"; vis.Parent = model
    local col = Instance.new("Folder"); col.Name = "Collision"; col.Parent = model
    local MS = game:GetService("MaterialService")
    local n = 0
    local parts = {}
    for _, d in hold:GetDescendants() do
      if d:IsA("MeshPart") then
        local nm = d.Name
        if not string.find(nm, "_") or #string.split(nm, "_") < 8 then nm = string.gsub(d.Parent.Name, "_Node$", "") end
        local t = string.split(nm, "_")
        local function num(s) if string.sub(s, 1, 1) == "n" then return -tonumber(string.sub(s, 2)) / 100 end return tonumber(s) / 100 end
        local k = #t
        local c = Vector3.new(num(t[k - 5]), num(t[k - 4]), num(t[k - 3]))
        local s = Vector3.new(num(t[k - 2]), num(t[k - 1]), num(t[k]))
        local kind = t[1]
        local q = d:Clone()
        for _, ch in q:GetChildren() do ch:Destroy() end
        q.Name = kind
        q.Size = Vector3.new(math.max(s.X, 0.01), math.max(s.Y, 0.01), math.max(s.Z, 0.01))
        q.CFrame = CFrame.new(c)
        q.Anchored = true
        q.CanCollide = false
        q.CanQuery = false
        q.CanTouch = false
        q.DoubleSided = false
        q.TextureID = ""
        local L = LOOK[kind]
        if L then
          q.Material = Enum.Material[L[1]]
          q.Color = Color3.fromRGB(L[2], L[3], L[4])
          if L[5] ~= "" and MS:FindFirstChild(L[5], true) then q.MaterialVariant = L[5] end
          q.Reflectance = L[6]
        end
        q.CastShadow = not (kind == "SKY" or kind == "LMP")
        q.Parent = vis
        table.insert(parts, q)
        n += 1
      end
    end
    for i, q in parts do
      pcall(function() q.CollisionFidelity = Enum.CollisionFidelity.Box end)
      if i %% 10 == 0 then task.wait() end
    end
    for _, r in COLL do
      local p = Instance.new("Part")
      p.Name = "C"
      p.Anchored = true
      p.Size = Vector3.new(r[4], r[5], r[6])
      p.CFrame = CFrame.new(r[1], r[2], r[3]) * CFrame.Angles(0, r[7], 0)
      p.Transparency = 1
      p.CanCollide = true
      p.CanQuery = true
      p.CanTouch = false
      p.CastShadow = false
      p.Parent = col
    end
    local plateName = NAME .. "Plate_TEMP"
    local op = lm:FindFirstChild(plateName)
    if op then op:Destroy() end
    local pl = Instance.new("Part")
    pl.Name = plateName
    pl.Anchored = true
    pl.Material = Enum.Material.Concrete
    pl.Color = Color3.fromRGB(150, 148, 140)
    pl.Size = Vector3.new(PLATE.X, 6, PLATE.Y)
    pl.CFrame = CFrame.new(PIVOT - Vector3.new(0, 3, 0)) * CFrame.Angles(0, PLATE_YAW, 0)
    pl:SetAttribute("Temp", "flat plate at the GLO-30 ground height until the 1:1 terrain is there")
    pl.Parent = lm
    model.WorldPivot = CFrame.new(PIVOT)
    hold:Destroy()
    model:SetAttribute("Status", "done " .. n .. " meshes, " .. #COLL .. " collision")
  end)
  if not ok then model:SetAttribute("Status", "error " .. tostring(err)) end
end)
return "started"
""" % dict(name=P["name"], asset=asset, look=look, coll=coll, px=px, py=py, pz=pz, plx=P["plate"][0], plz=P["plate"][1],
           pyaw=P["plate_yaw"])
out = os.path.join(ROOT, "build", "landmarks", key, key + "_place.luau")
open(out, "w", encoding="utf-8").write(lua)
print(out, len(lua))
