# Verify in Studio (audit + screenshots)

The loop that proves a UI works before you say it does. Uses the Roblox Studio MCP tools: `list_roblox_studios`, `get_studio_state`, `start_stop_play`, `execute_luau`, `screen_capture`, `get_console_output`. The device-switching API comes from Studio's built-in `rbx-device-simulator-lua` skill (load it with the Studio `skill` tool if you need more than what's here).

## Things learned the hard way (tested 14 Nov 2026)

- **`execute_luau` with `datamodel_type = "Client"` works during Play** and sees the live `PlayerGui`, `AbsoluteSize`, `GuiService.SelectedObject`. Use it. (Some docs say it can't; it can.)
- **Device Simulator setters fail from the Server datamodel during Play, but work from the `Client` datamodel.** You can sweep the whole matrix in one Play session: `StudioDeviceSimulatorService:SetDeviceAsync(id)` from `Client`, wait ~1 s, audit, next device; `StopSimulationAsync()` gives the plain PC window.
- **Opening windows from a test:** `execute_luau` runs in its own Lua context, so `require` gives it a fresh copy of the game's modules, and firing *that* copy's BindableEvents reaches nobody. Mouse clicks through `user_mouse_input` often don't land either. Fix it once per game with a **Studio-only test hook** in the client event bus: `if RunService:IsStudio() and RunService:IsClient() then` parent each BindableEvent under the module by name. Then the test fires `ClientBus.StoreOpen:Fire()` exactly like the real button. MEGA BITE has this in `ReplicatedStorage.MegaBite.ClientBus`. Keep helpers in `_G` (e.g. `_G.UIAudit`, `_G.OpenWin`) for the rest of the Play session.
- **Windows shrink on phones even when the HUD is fixed:** a centred window is scaled until it fits the usable height (~280 px on a small phone), so a tall window drops to ×0.6. Check every window on a phone, not just the HUD.
- **The simulator can silently fall back to the default viewport** (after mode switches or captures). Right before every capture/audit, check `StudioDeviceSimulatorService:GetDeviceAsync()` and `workspace.CurrentCamera.ViewportSize`; re-set the device if needed.
- **`screen_capture` shows StarterGui (Edit) and PlayerGui (Play) UI, not CoreGui.**
- **In Edit with the simulator on, `Players.LocalPlayer` exists but has no PlayerGui.** The audit handles it.
- **Studio's mode can change under you**: the owner may be playtesting. Call `get_studio_state` before each step. If Studio flips between Edit and Play by itself, ask the owner before continuing.
- Most games build their UI at runtime, so Edit mode shows nothing. Test in Play.

## The loop

1. **Find Studio.** `list_roblox_studios`; pick the right place by name. If several are open, confirm with the owner.
2. **Pick a device (Edit mode).**
   ```lua
   local svc = game:GetService("StudioDeviceSimulatorService")
   for _, id in svc:GetDeviceListAsync() do
       if svc:GetDeviceInfoAsync(id).Name == "Samsung Galaxy A06" then svc:SetDeviceAsync(id) end
   end
   task.wait(0.4)
   return svc:GetDeviceAsync() .. " " .. tostring(workspace.CurrentCamera.ViewportSize)
   ```
3. **Start Play** (`start_stop_play` true), wait ~5 s for the game to build its UI.
4. **Open the screen** from the `Client` datamodel: call the screen's own open function or fire what the button fires (e.g. require the UI controller module and call `Open()`, or set the ScreenGui `Enabled` the way the game does). Prefer the real code path over poking properties.
5. **Audit**: send the full text of `scripts/ui_audit.luau` to `execute_luau` (`Client`). Set `CONFIG.only = { "TheScreenGui" }` to focus. If the game has its own touch controls (no Roblox jump button; MEGA BITE: `{ "Dart", "Sprint" }`), list them in `CONFIG.reserve` so the audit checks buttons against those instead of estimating Roblox's. A slim button with a bigger invisible child button (a "Hit" tap area) counts as the child's size. Read the report:
   - ERROR: fix now (off-screen, tiny targets < 36 px, tiny text < 12 px, invisible-but-clickable, duplicate ScreenGuis).
   - WARN: fix, or write one line on why it's fine (e.g. "UNDER_THUMBSTICK: Settings button is PC-only layout").
   - The first lines list fonts, radii and text sizes in use: compare with the kit.
6. **Screenshot** (`screen_capture`) and look at it as a kid on that device: what's first, can I tap it, can I read it, does anything overlap Roblox's controls?
7. **Console**: `get_console_output` for errors from the UI scripts.
8. **Fix → repeat 4–7** until 0 errors and only explained warnings.
9. **Next device**: stop Play, switch device, start Play, repeat.
10. **Clean up**: stop Play, `StopSimulationAsync()`, say "Studio reset to default viewport."

## Device matrix

| Device (simulator name) | Viewport | Why |
|---|---|---|
| Samsung Galaxy A06 | 705×338 | Smallest common phone: clipping, tiny targets, height budget |
| iPhone 17 Pro (or newest iPhone) | ~750×362 | Notch/Dynamic Island side insets |
| iPad 10th Generation | 1180×820 | Too-empty layouts, stretched panels |
| HD 1080 or Average Windows | 1920×1080 / 1366×768 | PC: hover states, panels not huge |
| Xbox One | 1920×1080 | Gamepad focus path, TV readability, edge overscan |

Portrait: only if `StarterGui.ScreenOrientation` allows it (`Sensor`/`Portrait`), via `SetOrientationAsync(Enum.ScreenOrientation.Portrait)`.

Minimum before saying "works on mobile": Galaxy A06 + one PC size. Full matrix for new screens and big redesigns.

## Gamepad check (console row)

With Play running on the Xbox preset, from `Client`:
- After opening, `GuiService.SelectedObject` should be the safest useful button (the audit's first lines print it).
- Walk the graph: set `SelectedObject`, read each `NextSelection*` (or simulate with `user_keyboard_input` if available) and confirm every button is reachable and the modal traps focus.
- B / Back closes the modal and restores the previous selection.

## Previewing a component without touching the place

When Play isn't available (the owner is using Studio), you can build a preview in `game.CoreGui` from the `Edit` datamodel and audit it with `CONFIG.root = game.CoreGui`. It is never saved with the place. Screenshots don't show CoreGui, though; for a picture, either use Play + PlayerGui, or parent the preview to StarterGui only for the capture and **destroy it right after** (tell the owner you did).

## Report format

```
UI verify: <screen> — <date>
| Device | Viewport | Audit | Screenshot |
|---|---|---|---|
| Galaxy A06 | 705x338 | 0 errors, 1 warn (explained) | fits, BUY reachable, tabs readable |
| HD 1080 | 1920x1080 | 0 / 0 | panel capped at 860x560 |
Not checked: portrait (game is landscape-only), real device.
Studio reset to default viewport.
```
