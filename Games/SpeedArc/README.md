# SPEED ARC - code

The code for the SPEED ARC Roblox place (placeId 134701616695802). Files here are the source of truth; Studio gets a copy.
Rules for Claude are in `SPEED ARC/CLAUDE.md` in the vault.

## Folders
- `src/ReplicatedStorage/Shared/Config/` - every number (Palette, GameConfig, Stations, Race, Sounds, Lighting)
- `src/ReplicatedStorage/Shared/UIKit.lua` - the UI kit (panels, chunky buttons, coin/medal icons, fonts)
- `src/ReplicatedStorage/Shared/Util/` - Format, Formulas, Net (remotes), TrackPath (oval track maths)
- `src/ServerScriptService/Server/` - `Main.server.lua` + `Services/` (PlayerData, DataTemplate, TrainingService, RaceService)
- `src/StarterPlayer/StarterPlayerScripts/Client/` - `Main.client.lua` + `Controllers/` (Sound, Lighting, Hud, Camera, Training, Race, WorldLife)
- `tools/build_hub.luau` - builds `workspace.Hub` (the Hometown Track) in Studio
- `blender/hub_kit.py` - makes the hub's .fbx props into `Downloads\speed_arc_models\hub\`

File names: `Name.server.lua` = Script, `Name.client.lua` = LocalScript, `Name.lua` = ModuleScript.

## Sending the code to Studio
1. Double-click `tools/serve.bat` (leave the window open).
2. In the SPEED ARC Studio, open View > Command Bar, paste the contents of `tools/sync.luau`, press Enter.
   It turns HTTP on just for the copy, writes every script, and turns HTTP back off.
3. Close the serve window.

(Claude does the same through the Studio MCP.)

## UI art kit (prompt 12)
- `python tools/make_ui_kit.py` draws every UI sprite (`ui_kit/*.png`), packs them into 3 sheets (`ui_kit/sheets/ui_buttons.png`, `ui_tiles.png`, `ui_icons.png`), writes `Config/UIArtSprites.lua` and copies the sheets into Studio's `content/textures/SpeedArcKit/` so Studio shows them before they're uploaded. Run it after any kit change, then sync. (A Studio update makes a new version folder: run it again.)
- Before publishing: upload the 3 sheets to the GROUP and put the ids in `Config/UIArt.lua` (`Ids`). With empty ids a live server shows no kit images.

## Studio test switches (Workspace attributes, Studio only)
- `FreshPlayer` = true: play as a brand-new player on temporary data (never saved)
- `TestSpeed` / `TestCoins` (numbers): start with that much
- `TestRaceNow` = true: start the next race's JOIN window now
- `TestRaceInterval` (seconds): race every N seconds instead of 180

Remove them after testing.
