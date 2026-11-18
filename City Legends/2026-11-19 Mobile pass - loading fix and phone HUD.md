# 2026-11-19 Mobile pass: loading fix and phone HUD

Owner, 19 Nov: "we need to improve mobile support too, rn the driving buttons are so messy and cant see anything while driving and also the mobile interface is bad and also the loading screen sometimes doesnt load in and i get stuck with no GUI after pressing skip / waiting a while." Later: "some important buttons in mobile driving are missing too", plus the Driving Empire reference shots (`Owner ref - mobile driving HUD (...)`).

## 1. Stuck with no GUI (fixed)

**Cause.** The main menu only opens at the very end of `Main.client` (`showMenu()`), about 500 lines after the loading screen goes. In between, the script waited with **no timeout** on remotes (`FastTravel`, `ClaimStarter`, `DealerOpen`, `DealerCall`, `SaveSettings`, `DespawnCar`) and ran 5 module inits with no guard. On the server, every system's `init` ran unguarded in a row, so one that errors (e.g. Jobs, Store) stopped `Main.server` before it made `SpawnCar`'s handler, `ClaimStarter`, `FastTravel` and `MenuFocus`. The client then waited forever: SKIP (or the 45 s cap) removed the loading screen and nothing came after it.

**Repro (Studio, test save).** `error()` at the top of `Jobs.init`, then Play. Before: no menu after 55 s, the Output said `Infinite yield possible on Remotes:WaitForChild("FastTravel")`. Shot: `2026-11-19 Mobile - loading SKIP path - before.jpg`.

**Fix.**
- `server/Main.server.lua`: every system starts in `guard(name, fn)`, which reports `server start: X failed` and goes on.
- `client/Main.client.lua`:
  - `remote(name, class)` waits 10 s at most, warns, and returns a stand-in.
  - Hotel, Customs, CarUpgrades, Workshop and Market start through `startStep`.
  - `Driving.attach` runs in a `pcall` (if it fails: toast, and the menu comes back).
  - A **watchdog**: when nothing is loading or on its way, and there is no HUD, menu, garage or modal for 6 s (photo mode excepted), it removes the black fade and shows the HUD (in a car or on foot) or the main menu.
- **Tested:**
  - with the repro error: the menu came, and Jobs was reported.
  - SKIP early: the menu came 0.3 s later.
  - full load: menu, then drive.
  - HUD hidden by hand while driving: the watchdog brought it back in 5.5 s.

## 2. Phone driving HUD (Driving Empire approach, our kit)

The middle of the screen stays clear. Everything is on its own `TouchDrive` ScreenGui (`ScreenInsets = CoreUISafeInsets`, DisplayOrder 9). It is drawn for a 375-high phone and scaled up to 1.5x on tablets. Roblox's thumbstick and jump are off in a car (`GuiService.TouchControlsEnabled`).

- **Bottom left:** ◀ ▶ steering, with a round N2O button over ▶ (shown when the car has nitro).
- **Bottom right:**
  - GAS as a tall pedal, BRAKE as a wide pedal (ridges, our colours)
  - a small speed box over BRAKE: speed, unit, gear, rev bar, fuel line
  - a round DRIFT (handbrake) button over GAS
  - round ▼ ▲ paddles in sequential
- **Bottom middle:** the GET OUT / GET IN pill (it fades while moving), with CAM, LIGHTS, RADIO and ••• under it.
- **Top:**
  - menu icons in a slim 40 px column at the far left (5 icons; DESPAWN moved to the ••• menu)
  - cash small at the top right, the minimap under it (smaller)
  - the level and job bars hide while moving and come back when you stop
- **Gone on phones:** the big dial (HudSpeedo is hidden on touch). Speed lines are cut to 40%.

**Every PC driving key, and where it is on a phone:**

| Key | Phone |
|---|---|
| W / S | GAS / BRAKE pedals |
| A / D | ◀ ▶ |
| Space | DRIFT (round) |
| Ctrl / B nitro | N2O (round) |
| F start / get out | auto start on phones; GET OUT pill; ENGINE in ••• |
| V first person | 1ST PERSON in ••• |
| Shift+V / camera | CAM |
| Look around | drag on the screen (CameraLook, as before) |
| R radio | RADIO |
| L lights (hold = flash) | LIGHTS (shows the mode) |
| Z / X / C indicators | ◀ SIGNAL / HAZARD / SIGNAL ▶ in ••• |
| M gearbox | GEARBOX in ••• |
| Q / E shifts | ▼ ▲ paddles (sequential) |
| P park brake | PARK BRAKE in ••• |
| T traction control | TRACTION in ••• |
| Cruise key, + / − | CRUISE, CRUISE + / − in ••• |
| Shift+F doors | DOORS in ••• (on cars with doors) |
| Shift+P / O photo mode | PHOTO in ••• |
| Backspace reset | RESET CAR in ••• |
| Delete despawn | PUT AWAY in ••• |
| U duel | the duel pill (Activities, already tappable) |
| G garage | CARS icon |
| Horn | none (the game has no horn) |

The code is `UI.buildTouchControls`. Keys go through `UI.onCarKey` -> `Driving`'s `driveKey` (the same path as the keyboard).

## 3. Menus on phones
- **Main menu:** phones use a 1000x540 design canvas (PC: 1180x640), so everything is drawn about 20% bigger. The Campaign columns and the World Map pane follow `W` / `H`.
- **Job Center and Goals:** 380 high on phones (the lists scroll), so they are drawn about 20% bigger. Both sit above the touch layer.

## Shots (phone 812x375 via `tools/mobile/phone_preview.luau` + workspace attribute `PreviewPhone`)
- Driving HUD: `2026-11-19 Mobile - driving HUD - before.jpg` / `- after.jpg` / `driving HUD stopped - after.jpg`. Side by side with the Driving Empire ref: `2026-11-19 Mobile - driving HUD - before, after, Driving Empire ref.jpg`.
- Main menu: `2026-11-19 Mobile - main menu - before.jpg` / `- after.jpg`. Store: `- store - after.jpg`. World Map before: `- world map - before.jpg`.
- Loading: `- loading SKIP path - before.jpg` (stuck, empty screen). After: measured, not shot (the menu came 0.3 s after SKIP).

## Left / not checked
- No Job Center shot: no hook to open it from the console. It now fits by code.
- The garage, dealer and settings screens were not checked at phone size.
- The phone camera (height, FOV) was not changed.
- Not checked on a real phone or in the device emulator: a click on Studio was stopped. The preview wrapper is close, but screens that size themselves from `ViewportSize` (Goals, Job Center, HudSpeedo) look wrong in it.
- Store `CityLegends_v1` is back. Saved, not published.
