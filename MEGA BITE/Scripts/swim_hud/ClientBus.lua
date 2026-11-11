-- shared client state between MB_Swim (controller) and MB_HUD. Modules are cached per client, so both see one table.
local B = {}
B.Dart = Instance.new("BindableEvent")      -- HUD -> controller
B.Ability = Instance.new("BindableEvent")
B.ToastEvent = Instance.new("BindableEvent") -- anyone -> HUD (text, colourToken)
B.State = {heading = 0, camYaw = 0, dartReadyAt = 0, dartCooldown = 2.2, pos = Vector3.zero, speed = 0, isTouch = false}
function B.Toast(text, colour) B.ToastEvent:Fire(text, colour) end
return B
