-- Lune test (2026-11-21) for src/shared/StartupGuard.lua: the watchdog never leaves a bare view, and never lets
-- the player in before startup is over.
--   lune run tools/startup_guard_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local root = process.args[1] or "."
local G = luau.load(fs.readFile(root .. "/src/shared/StartupGuard.lua"), { debugName = "StartupGuard" })()

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end
local function w(startup, loading, busy, gui, inGame)
	return G.watch({ startup = startup, loading = loading, busy = busy, gui = gui, inGame = inGame })
end

check(w(true, true, false, false, false) == "ok", "startup, loading screen up: fine")
check(w(true, false, false, false, false) == "loading", "startup, bare view (skipped / hidden): loading screen back")
check(w(true, false, false, false, true) == "loading", "startup, even in a car: no HUD before the city is there")
check(w(true, false, true, false, false) == "ok", "startup, a car being put on: wait")
check(w(false, false, false, false, false) == "menu", "after startup, nothing up, no car: main menu")
check(w(false, false, false, false, true) == "hud", "after startup, nothing up, in a car / on foot: HUD")
check(w(false, false, false, true, false) == "ok", "a screen is up: fine")
check(w(false, false, true, false, true) == "ok", "a car on its way: fine")
check(G.After.loading <= 1 and G.After.hud == 6 and G.After.menu == 6, "bare view in startup: 1 s; after it the 19 Nov 6 s")

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("startup_guard_test: all passed")
