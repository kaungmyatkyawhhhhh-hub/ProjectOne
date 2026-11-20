-- What the client watchdog does when it looks at the screen (pure, so Lune can test it: tools/startup_guard_test.luau).
-- (owner, 2026-11-21: "i am stuck in black screen after skipping loading") the player must never look at a bare view:
-- during startup (no menu yet) the loading screen comes back, after it the HUD or the main menu.
local G = {}

-- seconds of nothing on screen before each action
G.After = { loading = 1, hud = 6, menu = 6 }

-- s.startup: Main.client has not reached the main menu yet; s.loading: the loading screen is up; s.busy: a car is on
-- its way / being put on; s.gui: the HUD, the menu or a full screen is up (or photo mode); s.inGame: in a car or on foot
function G.watch(s: { startup: boolean, loading: boolean, busy: boolean, gui: boolean, inGame: boolean }): string
	if s.loading or s.busy or s.gui then
		return "ok"
	end
	if s.startup then
		return "loading" -- (never the menu or the HUD before the city is there: no car without ground under it)
	end
	return if s.inGame then "hud" else "menu"
end

return G
