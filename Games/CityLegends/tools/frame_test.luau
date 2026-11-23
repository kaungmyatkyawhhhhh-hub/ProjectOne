-- Lune test for src/client/Frame.lua (2026-11-20): per-frame logic keeps running with no render frames.
--   lune run tools/frame_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local task = require("@lune/task")

local root = process.args[1] or "."

-- a fake RunService: two signals fired by hand, and a clock we move
local function signal()
	local conns = {}
	return {
		Connect = function(_, fn)
			local c = { fn = fn, Disconnect = function(self)
				local i = table.find(conns, self)
				if i then
					table.remove(conns, i)
				end
			end }
			table.insert(conns, c)
			return c
		end,
		fire = function(dt)
			for _, c in table.clone(conns) do
				c.fn(dt)
			end
		end,
	}
end
local render, heartbeat = signal(), signal()
local now = 100
local env = {
	game = { GetService = function() return { RenderStepped = render, Heartbeat = heartbeat } end },
	os = { clock = function() return now end },
	task = task,
	table = table,
}
local Frame = luau.load(fs.readFile(root .. "/src/client/Frame.lua"), { debugName = "Frame", environment = env })()

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

local calls: { string } = {}
local dts: { number } = {}
local source = ""
local conn = Frame.Connect(function(dt)
	table.insert(calls, source)
	table.insert(dts, dt)
end)
-- one frame of the engine: render (if the window draws), then heartbeat
local function frame(drawn: boolean)
	now += 1 / 60
	if drawn then
		source = "render"
		render.fire(0.016)
	end
	source = "heartbeat"
	heartbeat.fire(0.017)
end

for _ = 1, 60 do
	frame(true)
end
check(#calls == 60 and not table.find(calls, "heartbeat"), "60 drawn frames: 60 calls, all from render")
check(dts[1] == 0.016, "render's own dt")
check(not Frame.noRender(), "noRender false while drawing")

-- the window stops drawing: nothing for the first 0.25 s, then every heartbeat
table.clear(calls)
table.clear(dts)
for _ = 1, 14 do
	frame(false)
end
check(#calls == 0, "no render for 0.23 s: not yet from heartbeat")
for _ = 1, 60 do
	frame(false)
end
check(#calls >= 58 and not table.find(calls, "render"), "no render for longer: once per heartbeat (" .. #calls .. ")")
check(dts[1] == 0.017, "heartbeat's dt")
check(Frame.noRender(), "noRender true")

-- drawing again: render only, straight away, once per frame
table.clear(calls)
for _ = 1, 30 do
	frame(true)
end
check(#calls == 30 and not table.find(calls, "heartbeat"), "render back: 30 calls, none from heartbeat")

-- disconnect: neither source calls it
table.clear(calls)
conn:Disconnect()
conn:Disconnect()
for _ = 1, 5 do
	frame(true)
end
for _ = 1, 40 do
	frame(false)
end
check(#calls == 0, "disconnected: no calls")

-- a listener that disconnects itself from inside a heartbeat call; one that errors doesn't stop the next
local selfCalls, after = 0, 0
local c2
c2 = Frame.Connect(function()
	selfCalls += 1
	c2:Disconnect()
end)
Frame.Connect(function()
	after += 1
end)
frame(false)
frame(false)
check(selfCalls == 1 and after == 2, "self-disconnect inside the heartbeat stand-in; the next listener still runs")

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("frame_test: all passed")
