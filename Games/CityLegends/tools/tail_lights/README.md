# Tail lights

How `src/client/TailLights.lua` was made (owner, 2026-10-17: "add rear tail light for all cars"). The scripts run with Blender's Python module on the converted `.blend` files; their paths point at the scratch folders used when they were written.

1. `scan.py <car.blend> <id> <out.json>`: lists the parts at the back of the car that are red (sampled from their textures) or named as tail / brake lights.
2. `picks.py`: for cars whose lamps are only painted on, the lamp spots picked on a rear render (800x560, same views as `brand_marks/views.py`). `build.py` turns them into 3D spots.
3. `to_lua.py <tools dir> <TailLights.lua>`: filters the scan (`EXCL` drops chrome, housings and indicators), matches each part to the game model by name and size, and writes the module.

At runtime CarSkin also finds lamps on cars built in Roblox: parts named as tail / brake lights, A-Chassis "Brake" glow meshes, and small plain red parts in the last sixth of the car. Each lamp gets a red glowing copy; Driving brightens it when braking and hides it with the lights off.
