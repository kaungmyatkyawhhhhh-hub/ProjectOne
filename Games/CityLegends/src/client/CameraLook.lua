--!strict
--[[
	CameraLook: look around the car in the outside cameras (owner, 2026-11-13: "make it so that u can look
	around in third person camera view").

	  * PC: hold the right mouse button and move the mouse (the pointer stays put while you look).
	  * Phone: drag a finger on any free part of the screen (not on a button).
	  * Gamepad: the right stick.

	The camera swings round the car (yaw any way round, pitch from just above the road to high over the
	roof) and keeps the car in the middle. Let go and drive, and it eases back behind the car after
	ReturnDelay; parked, it stays where you left it until you drive off. Not in the cockpit (it has its
	own right-button look) or while another screen has the camera.

	Driving calls CameraLook.init(enabled) once, CameraLook.update(dt, mph) every frame and reads
	CameraLook.yaw / CameraLook.pitch / CameraLook.amount(); CameraLook.reset() snaps back.
]]

local UserInputService = game:GetService("UserInputService")

local CameraLook = {}

CameraLook.Settings = {
	MouseSens = 0.0045, -- radians per pixel of mouse movement
	TouchSens = 0.007, -- radians per pixel of finger movement
	PadSpeed = 3.2, -- radians per second at full right stick
	PadDead = 0.18,
	PitchMin = -0.12, -- (radians) a little below the normal view...
	PitchMax = 1.05, -- ...up to about 60 degrees over it
	ReturnDelay = 0.8, -- seconds after you let go (and drive) before it swings back...
	ReturnRate = 3.2, -- ...how fast it swings back (per second)
	ReturnMph = 6, -- parked (slower than this) it stays where you left it
}

CameraLook.yaw = 0 -- radians round the car (+ = to the left of the car, seen from above)
CameraLook.pitch = 0 -- radians higher than the normal view

local enabledFn: () -> boolean = function()
	return false
end
local mouseHeld = false
local mouseLocked = false
local lookTouch: InputObject? = nil
local lastTouchPos: Vector3? = nil
local idle = 0 -- seconds since the last look input

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function turn(dx: number, dy: number)
	CameraLook.yaw = wrap(CameraLook.yaw - dx)
	CameraLook.pitch = math.clamp(CameraLook.pitch + dy, CameraLook.Settings.PitchMin, CameraLook.Settings.PitchMax)
	idle = 0
end

local function releaseMouse()
	mouseHeld = false
	if mouseLocked then
		mouseLocked = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CameraLook.reset()
	CameraLook.yaw = 0
	CameraLook.pitch = 0
	idle = 0
	releaseMouse()
	lookTouch = nil
	lastTouchPos = nil
end

-- 0 = the normal view, 1 = swung well round (Driving turns the camera from looking ahead of the car to
-- looking at the car as this grows)
function CameraLook.amount(): number
	return math.clamp(math.max(math.abs(CameraLook.yaw), CameraLook.pitch * 1.5) / 0.5, 0, 1)
end

function CameraLook.active(): boolean
	return CameraLook.yaw ~= 0 or CameraLook.pitch ~= 0
end

function CameraLook.update(dt: number, mph: number)
	if not enabledFn() then
		if CameraLook.active() or mouseHeld or lookTouch then
			CameraLook.reset()
		end
		return
	end
	local S = CameraLook.Settings
	-- the right stick
	local stick = false
	if UserInputService.GamepadEnabled then
		for _, input in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
			if input.KeyCode == Enum.KeyCode.Thumbstick2 then
				local p = input.Position
				if p.Magnitude > S.PadDead then
					turn(p.X * S.PadSpeed * dt, -p.Y * S.PadSpeed * 0.6 * dt)
					stick = true
				end
			end
		end
	end
	if mouseHeld or lookTouch or stick then
		idle = 0
		return
	end
	idle += dt
	if mph > S.ReturnMph and idle > S.ReturnDelay and CameraLook.active() then
		local k = math.exp(-dt * S.ReturnRate)
		CameraLook.yaw *= k
		CameraLook.pitch *= k
		if math.abs(CameraLook.yaw) < 0.002 and math.abs(CameraLook.pitch) < 0.002 then
			CameraLook.yaw, CameraLook.pitch = 0, 0
		end
	end
end

function CameraLook.init(enabled: () -> boolean)
	enabledFn = enabled
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not enabledFn() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			mouseHeld = true
			idle = 0
			if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
				mouseLocked = true
			end
		elseif input.UserInputType == Enum.UserInputType.Touch and lookTouch == nil then
			-- (a touch on a button is "processed": steering, GAS and the rest never turn the camera)
			lookTouch = input
			lastTouchPos = input.Position
			idle = 0
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not enabledFn() then
			return
		end
		local S = CameraLook.Settings
		if input.UserInputType == Enum.UserInputType.MouseMovement and mouseHeld then
			turn(input.Delta.X * S.MouseSens, input.Delta.Y * S.MouseSens)
		elseif input == lookTouch and lastTouchPos then
			local d = input.Position - lastTouchPos
			lastTouchPos = input.Position
			turn(d.X * S.TouchSens, d.Y * S.TouchSens)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			releaseMouse()
			idle = 0
		elseif input == lookTouch then
			lookTouch = nil
			lastTouchPos = nil
			idle = 0
		end
	end)
end

return CameraLook
