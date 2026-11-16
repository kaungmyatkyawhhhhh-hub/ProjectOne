-- Ngahtatgyi placer (bahan_buddhas3d.py), asset 133663873545500
local NAME, ASSET = "Ngahtatgyi", 133663873545500
local LOOK = {
  CLT = {"SmoothPlastic", 240, 240, 236, "", 0},
  FBK = {"SmoothPlastic", 22, 22, 26, "", 0.04},
  FGB = {"SmoothPlastic", 222, 172, 64, "", 0.18},
  FGO = {"SmoothPlastic", 204, 164, 86, "", 0.12},
  FLP = {"SmoothPlastic", 192, 46, 56, "", 0.1},
  FPK = {"SmoothPlastic", 232, 142, 142, "", 0.05},
  FRD = {"SmoothPlastic", 150, 46, 40, "", 0.2},
  FSK = {"SmoothPlastic", 240, 238, 232, "", 0.15},
  GBL = {"SmoothPlastic", 204, 218, 212, "", 0.1},
  GLD = {"Metal", 226, 222, 245, "YgnGoldLeaf", 0},
  MIR = {"Foil", 204, 208, 214, "", 0.3},
  PLN = {"SmoothPlastic", 196, 190, 180, "", 0},
  RBS = {"SmoothPlastic", 176, 32, 32, "", 0.05},
  RUS = {"Metal", 132, 66, 50, "YgnCorrugatedZinc", 0},
  SKY = {"SmoothPlastic", 228, 236, 240, "", 0.1},
  STW = {"SmoothPlastic", 226, 229, 232, "", 0.05},
  TEK = {"Wood", 96, 52, 40, "", 0},
  TKL = {"Wood", 128, 72, 52, "", 0},
  UND = {"SmoothPlastic", 74, 54, 48, "", 0},
  WDR = {"SmoothPlastic", 112, 40, 36, "", 0}
}
local COLL = {
  {37211.85, 74.56, 33831.02, 215.4, 2.4, 172.8, 0.0},
  {37126.5, 88.66, 33917.04, 44.7, 25.8, 0.75, 0.0},
  {37244.7, 88.66, 33917.04, 149.7, 25.8, 0.75, 0.0},
  {37104.53, 88.66, 33880.22, 0.75, 25.8, 74.4, 0.0},
  {37104.53, 88.66, 33781.82, 0.75, 25.8, 74.4, 0.0},
  {37126.5, 88.66, 33744.99, 44.7, 25.8, 0.75, 0.0},
  {37193.85, 88.66, 33744.99, 48.0, 25.8, 0.75, 0.0},
  {37276.2, 88.66, 33744.99, 86.7, 25.8, 0.75, 0.0},
  {37319.17, 88.66, 33831.02, 0.75, 25.8, 172.8, 0.0},
  {37159.35, 74.16, 33744.02, 24.0, 1.59, 1.2, 0.0},
  {37159.35, 73.75, 33742.82, 24.0, 0.78, 1.2, 0.0},
  {37159.35, 74.16, 33918.02, 24.0, 1.59, 1.2, 0.0},
  {37159.35, 73.75, 33919.22, 24.0, 0.78, 1.2, 0.0},
  {37103.55, 74.16, 33831.02, 1.2, 1.59, 27.0, 0.0},
  {37102.35, 73.75, 33831.02, 1.2, 0.78, 27.0, 0.0},
  {37225.35, 74.16, 33744.02, 18.0, 1.59, 1.2, 0.0},
  {37225.35, 73.75, 33742.82, 18.0, 0.78, 1.2, 0.0},
  {37134.53, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37134.53, 94.21, 33868.37, 3.3, 36.9, 3.3, 0.0},
  {37134.53, 94.21, 33849.69, 3.3, 36.9, 3.3, 0.0},
  {37134.53, 94.21, 33812.34, 3.3, 36.9, 3.3, 0.0},
  {37134.53, 94.21, 33793.67, 3.3, 36.9, 3.3, 0.0},
  {37134.53, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37153.86, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37153.86, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37173.19, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37173.19, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37192.52, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37192.52, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37211.85, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37211.85, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37231.18, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37231.18, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37250.51, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37250.51, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37269.84, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37269.84, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33887.04, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33868.37, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33849.69, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33812.34, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33793.67, 3.3, 36.9, 3.3, 0.0},
  {37289.17, 94.21, 33774.99, 3.3, 36.9, 3.3, 0.0},
  {37245.6, 79.96, 33831.02, 31.5, 8.4, 54.0, 0.0},
  {37244.85, 105.16, 33831.02, 24.0, 42.0, 39.0, 0.0},
  {37258.35, 104.26, 33831.02, 1.8, 57.0, 63.0, 0.0},
  {37227.15, 77.56, 33831.02, 4.2, 3.6, 54.0, 0.0}
}
local PIVOT = Vector3.new(37211.85, 73.36, 33831.02)
local PLATE = Vector2.new(228.0, 192.0)
local PLATE_YAW = 0.0
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
      if i % 10 == 0 then task.wait() end
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
