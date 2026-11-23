--!strict
--[[
	Frame (client; owner, 2026-11-20): a locked / minimised PC gives 0 render frames (RenderStepped fired 0 times in
	3 s while Heartbeat fired 180), so per-frame game logic on RenderStepped stood still and unattended Play tests failed.
	Frame.Connect(fn) is RunService.RenderStepped:Connect(fn) (a real connection per listener: same order, same dt as
	before) that also runs fn from Heartbeat while no render frame has come for Frame.GAP seconds. The first render frame
	stops the Heartbeat calls again (RenderStepped comes before Heartbeat in a frame, so nothing runs twice).
	For game logic only: cameras and pure looks stay on RenderStepped / BindToRenderStep.
	Test: tools/frame_test.luau.
]]

local RunService = game:GetService("RunService")

local Frame = {}

Frame.GAP = 0.25 -- seconds without a render frame before Heartbeat takes over

type Listener = { fn: (number) -> (), on: boolean }
local listeners: { Listener } = {}
local lastRender = os.clock()

RunService.RenderStepped:Connect(function()
	lastRender = os.clock()
end)
RunService.Heartbeat:Connect(function(dt: number)
	if os.clock() - lastRender < Frame.GAP then
		return
	end
	-- (a copy: a listener may disconnect itself; each in its own thread, like a signal: one that errors or
	-- waits doesn't hold the rest. In the order they connected)
	for _, l in table.clone(listeners) do
		if l.on then
			task.spawn(l.fn, dt)
		end
	end
end)

-- true while Heartbeat is standing in for render frames (the window is drawing nothing)
function Frame.noRender(): boolean
	return os.clock() - lastRender >= Frame.GAP
end

-- like RunService.RenderStepped:Connect(fn); the returned connection has Disconnect() only
function Frame.Connect(fn: (number) -> ()): RBXScriptConnection
	local l: Listener = { fn = fn, on = true }
	local conn = RunService.RenderStepped:Connect(fn)
	table.insert(listeners, l)
	return {
		Disconnect = function()
			if l.on then
				l.on = false
				conn:Disconnect()
				local i = table.find(listeners, l)
				if i then
					table.remove(listeners, i)
				end
			end
		end,
	} :: any
end

return Frame
