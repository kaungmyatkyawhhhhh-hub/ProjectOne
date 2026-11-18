--!strict
--[[ Low-end mode (2026-11-19, owner: the game must run on cheap Android phones; ~93% of players on
phones in Myanmar, 3-4 GB RAM, old Mali / Adreno). Settings > Graphics "Performance": AUTO / LOW-END /
NORMAL, saved as Settings.Performance ("Auto" | "Low" | "Normal").

What it turns down (measured 19 Nov, vault note "2026-11-19 Performance - low-end mode"):
  * WorldFx.qualityScale() capped at 0.5: fewer traffic cars / pedestrians / parked cars and people,
    shorter light LOD, no light shadows, fewer particles, marks and weather drops
  * the Graphics "Low" look (no shadows, glow, sun rays, fog; low reflections) and no Bloom / depth of field
  * Render distance Low (x0.5 on the kit stream's radii and the light LodRange)
  * terrain decoration off; the shells' roof Textures hidden

Auto: phones (touch, no keyboard) start low-end, because the load is the moment a 3 GB phone runs out
of memory; after 25 s in the world a phone that holds ~55 fps under 1,000 MB goes back to normal
(traffic counts stay until the next join). Any device that runs under 28 fps for 25 s goes low-end.
Studio: player attribute TestLowEnd = true forces it on (false forces it off); workspace attribute
TestLowEnd (set in Edit) does the same from the start.
Not game look on PC: a PC on Auto stays normal unless it is that slow. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LowEnd = {}
LowEnd.on = false
LowEnd.mode = "Auto" -- "Auto" | "Low" | "Normal"
LowEnd.SCALE = 0.5 -- the WorldFx.qualityScale() cap while on

local player = Players.LocalPlayer
local listeners: { (boolean) -> () } = {}

local function isPhone(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- the roof Textures on the 1:1 building shells (24k of them in the place): hidden while on
local roofConn: RBXScriptConnection? = nil
local function setRoofs(hide: boolean)
	if roofConn then
		roofConn:Disconnect()
		roofConn = nil
	end
	local root = workspace:FindFirstChild("Yangon1to1")
	local shell = root and root:FindFirstChild("Buildings") and root.Buildings:FindFirstChild("Shell")
	if not shell then
		return
	end
	local v = if hide then 1 else 0
	task.spawn(function()
		for i, d in shell:GetDescendants() do
			if d:IsA("Texture") then
				d.LocalTransparencyModifier = v
			end
			if i % 5000 == 0 then
				task.wait()
			end
		end
	end)
	if hide then
		roofConn = shell.DescendantAdded:Connect(function(d)
			if d:IsA("Texture") then
				d.LocalTransparencyModifier = 1
			end
		end)
	end
end

local function set(on: boolean)
	if LowEnd.on == on then
		return
	end
	LowEnd.on = on
	if player then
		player:SetAttribute("LowEnd", on)
	end
	for _, f in listeners do
		task.spawn(f, on)
	end
end

-- MainMenu re-applies its settings when this changes (Graphics look, render distance)
function LowEnd.changed(f: (boolean) -> ())
	table.insert(listeners, f)
end

-- the extra cuts on top of the Graphics "Low" look (WorldFx.setQuality calls this after LookFx's
-- preset; switching off needs nothing here: the preset it runs first puts the effects back)
function LowEnd.applyWorld()
	for _, e in game:GetService("Lighting"):GetChildren() do
		if LowEnd.on and (e:IsA("BloomEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect")) then
			e.Enabled = false
		elseif e:IsA("BlurEffect") then
			-- (Driving's motion blur only sets Size, so it is switched here and back)
			if LowEnd.on and e.Enabled then
				e.Enabled = false
				e:SetAttribute("LowEndOff", true)
			elseif not LowEnd.on and e:GetAttribute("LowEndOff") then
				e.Enabled = true
				e:SetAttribute("LowEndOff", nil)
			end
		end
	end
	if LowEnd.on then
		pcall(function()
			workspace.Terrain.Decoration = false
		end)
	end
	setRoofs(LowEnd.on)
end

local function autoWatch()
	-- (once per join: 25 s of frames after the map is in)
	task.wait(10)
	local frames, t0 = 0, os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		frames += 1
	end)
	task.wait(25)
	conn:Disconnect()
	if LowEnd.mode ~= "Auto" or (player and player:GetAttribute("TestLowEnd") ~= nil) or workspace:GetAttribute("TestLowEnd") ~= nil then
		return
	end
	local fps = frames / (os.clock() - t0)
	local mem = Stats:GetTotalMemoryUsageMb()
	if LowEnd.on and fps >= 55 and mem < 1000 then
		set(false)
	elseif not LowEnd.on and fps < 28 then
		set(true)
	end
	print(string.format("[LowEnd] auto: %.0f fps, %.0f MB -> %s", fps, mem, if LowEnd.on then "low-end" else "normal"))
end

local function decide()
	local test = player and player:GetAttribute("TestLowEnd")
	if test == nil and RunService:IsStudio() then
		test = workspace:GetAttribute("TestLowEnd") -- (Studio: set in Edit before Play, so counts follow it)
	end
	if type(test) == "boolean" then
		set(test)
	elseif LowEnd.mode == "Low" then
		set(true)
	elseif LowEnd.mode == "Normal" then
		set(false)
	else
		set(isPhone())
	end
end

-- at start, from the saved settings (before Traffic / Pedestrians start, so their counts follow it)
function LowEnd.init(settings: { [string]: any })
	local m = settings.Performance
	LowEnd.mode = if m == "Low" or m == "Normal" then m else "Auto"
	decide()
	if player then
		player:GetAttributeChangedSignal("TestLowEnd"):Connect(decide)
	end
	task.spawn(autoWatch)
end

-- Settings row
function LowEnd.setMode(m: string)
	LowEnd.mode = if m == "Low" or m == "Normal" then m else "Auto"
	decide()
end

return LowEnd
