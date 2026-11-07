--[[
	Measures each car model's windscreen in Studio (Edit mode, execute_luau): its middle, its tilt and its size, read from the
	glass mesh with EditableMesh, all in wheelbases from the middle of the four wheels. The result goes into
	src/client/Windscreens.lua: { along (forward), up, normal forward, normal up, width, height }. See the session's script:
	glass faces whose normal looks forward and up, not sideways, between the wheels' middle and the nose.
]]
