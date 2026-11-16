-- Chaukhtatgyi placer (bahan_buddhas3d.py), asset 129397555354535
local NAME, ASSET = "Chaukhtatgyi", 129397555354535
local LOOK = {
  BLK = {"SmoothPlastic", 28, 28, 34, "", 0.1},
  CEL = {"SmoothPlastic", 236, 236, 230, "", 0},
  CUS = {"SmoothPlastic", 150, 40, 40, "", 0.05},
  FLR = {"SmoothPlastic", 150, 160, 150, "", 0.15},
  GLD = {"Metal", 226, 222, 245, "YgnGoldLeaf", 0},
  LID = {"SmoothPlastic", 172, 206, 230, "", 0.05},
  LIP = {"SmoothPlastic", 186, 44, 52, "", 0.05},
  LMP = {"Neon", 255, 232, 160, "", 0},
  MOS = {"Foil", 150, 160, 140, "", 0.2},
  NCM = {"SmoothPlastic", 122, 46, 40, "", 0},
  NMI = {"SmoothPlastic", 164, 206, 184, "", 0},
  PLT = {"SmoothPlastic", 196, 196, 190, "", 0.05},
  RFG = {"SmoothPlastic", 72, 104, 76, "", 0},
  ROB = {"Metal", 226, 222, 245, "YgnGoldLeaf", 0},
  RUG = {"SmoothPlastic", 96, 96, 100, "", 0},
  SKN = {"SmoothPlastic", 255, 255, 250, "", 0.05},
  SKY = {"SmoothPlastic", 228, 236, 240, "", 0.1},
  SOL = {"SmoothPlastic", 214, 128, 112, "", 0.03},
  STM = {"SmoothPlastic", 112, 50, 44, "", 0.05},
  TEA = {"SmoothPlastic", 44, 92, 102, "", 0},
  WRD = {"Metal", 120, 46, 44, "YgnCorrugatedZinc", 0}
}
local COLL = {
  {37635.06, 70.58, 32763.72, 282.0, 1.2, 138.0, -0.5637},
  {37486.62, 76.58, 32751.51, 1.5, 10.8, 1.5, -0.5637},
  {37499.44, 76.58, 32731.22, 1.8, 10.8, 1.8, -0.5637},
  {37560.36, 76.58, 32634.86, 1.5, 10.8, 1.5, -0.5637},
  {37547.53, 76.58, 32655.15, 1.8, 10.8, 1.8, -0.5637},
  {37506.9, 76.58, 32764.33, 1.5, 10.8, 1.5, -0.5637},
  {37519.73, 76.58, 32744.05, 1.8, 10.8, 1.8, -0.5637},
  {37580.64, 76.58, 32647.69, 1.5, 10.8, 1.5, -0.5637},
  {37567.82, 76.58, 32667.97, 1.8, 10.8, 1.8, -0.5637},
  {37527.19, 76.58, 32777.16, 1.5, 10.8, 1.5, -0.5637},
  {37540.01, 76.58, 32756.87, 1.8, 10.8, 1.8, -0.5637},
  {37600.93, 76.58, 32660.51, 1.5, 10.8, 1.5, -0.5637},
  {37588.1, 76.58, 32680.8, 1.8, 10.8, 1.8, -0.5637},
  {37547.47, 76.58, 32789.98, 1.5, 10.8, 1.5, -0.5637},
  {37560.3, 76.58, 32769.7, 1.8, 10.8, 1.8, -0.5637},
  {37621.21, 76.58, 32673.34, 1.5, 10.8, 1.5, -0.5637},
  {37608.39, 76.58, 32693.62, 1.8, 10.8, 1.8, -0.5637},
  {37567.76, 76.58, 32802.81, 1.5, 10.8, 1.5, -0.5637},
  {37580.58, 76.58, 32782.52, 1.8, 10.8, 1.8, -0.5637},
  {37641.5, 76.58, 32686.16, 1.5, 10.8, 1.5, -0.5637},
  {37628.68, 76.58, 32706.45, 1.8, 10.8, 1.8, -0.5637},
  {37588.05, 76.58, 32815.63, 1.5, 10.8, 1.5, -0.5637},
  {37600.87, 76.58, 32795.34, 1.8, 10.8, 1.8, -0.5637},
  {37661.79, 76.58, 32698.98, 1.5, 10.8, 1.5, -0.5637},
  {37648.96, 76.58, 32719.27, 1.8, 10.8, 1.8, -0.5637},
  {37608.33, 76.58, 32828.46, 1.5, 10.8, 1.5, -0.5637},
  {37621.16, 76.58, 32808.17, 1.8, 10.8, 1.8, -0.5637},
  {37682.07, 76.58, 32711.81, 1.5, 10.8, 1.5, -0.5637},
  {37669.25, 76.58, 32732.1, 1.8, 10.8, 1.8, -0.5637},
  {37628.62, 76.58, 32841.28, 1.5, 10.8, 1.5, -0.5637},
  {37641.44, 76.58, 32820.99, 1.8, 10.8, 1.8, -0.5637},
  {37702.36, 76.58, 32724.63, 1.5, 10.8, 1.5, -0.5637},
  {37689.54, 76.58, 32744.92, 1.8, 10.8, 1.8, -0.5637},
  {37648.91, 76.58, 32854.1, 1.5, 10.8, 1.5, -0.5637},
  {37661.73, 76.58, 32833.82, 1.8, 10.8, 1.8, -0.5637},
  {37722.65, 76.58, 32737.46, 1.5, 10.8, 1.5, -0.5637},
  {37709.82, 76.58, 32757.74, 1.8, 10.8, 1.8, -0.5637},
  {37669.19, 76.58, 32866.93, 1.5, 10.8, 1.5, -0.5637},
  {37682.02, 76.58, 32846.64, 1.8, 10.8, 1.8, -0.5637},
  {37742.93, 76.58, 32750.28, 1.5, 10.8, 1.5, -0.5637},
  {37730.11, 76.58, 32770.57, 1.8, 10.8, 1.8, -0.5637},
  {37689.48, 76.58, 32879.75, 1.5, 10.8, 1.5, -0.5637},
  {37702.3, 76.58, 32859.47, 1.8, 10.8, 1.8, -0.5637},
  {37763.22, 76.58, 32763.11, 1.5, 10.8, 1.5, -0.5637},
  {37750.39, 76.58, 32783.39, 1.8, 10.8, 1.8, -0.5637},
  {37709.76, 76.58, 32892.58, 1.5, 10.8, 1.5, -0.5637},
  {37722.59, 76.58, 32872.29, 1.8, 10.8, 1.8, -0.5637},
  {37783.5, 76.58, 32775.93, 1.5, 10.8, 1.5, -0.5637},
  {37770.68, 76.58, 32796.22, 1.8, 10.8, 1.8, -0.5637},
  {37598.19, 76.58, 32822.04, 281.4, 10.8, 0.6, -0.5637},
  {37640.3, 74.48, 32765.26, 210.9, 6.6, 47.4, -0.5637},
  {37653.77, 73.58, 32742.54, 204.0, 4.8, 0.9, -0.5637},
  {37549.83, 73.58, 32705.41, 0.9, 4.8, 46.5, -0.5637},
  {37639.67, 95.78, 32764.86, 198.0, 36.0, 36.0, -0.5637},
  {37710.19, 101.78, 32810.5, 21.0, 48.0, 21.0, -0.5637}
}
local PIVOT = Vector3.new(37635.06, 69.98, 32763.72)
local PLATE = Vector2.new(300.0, 156.0)
local PLATE_YAW = -0.5637
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
