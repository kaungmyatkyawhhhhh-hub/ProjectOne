# Components

Two cases:

1. **The game has a kit** (MEGA BITE: `ReplicatedStorage.MegaBite.UIKit` with `Plate`, `Text`, `Icon`, `HealImage`, the COUNTER/BUTTON/TILE families, and `UIFx` with `Sheen`, `Glints`, `BurstAt`). Use its builders. Add a missing piece *to the kit* in the kit's own style, then use it. The patterns below show what a good piece must do; port the behaviour, not the code style.
2. **No kit**: copy `assets/UIKitStarter.luau` into `ReplicatedStorage` (e.g. `ReplicatedStorage.UI.Kit`), recolour its TOKENS block from the game's art, then build screens from it.

`UIKitStarter` was tested in Studio (14 Nov 2026): it loads, builds a shop that fits a 705×338 phone, and passes `ui_audit.luau` after one fix (button height now includes the chunky base).

## UIKitStarter API

```lua
local Kit = require(game.ReplicatedStorage.UI.Kit)
local sg = Kit.screen("ShopUI", 15, player.PlayerGui)          -- ResetOnSpawn=false, Sibling z, safe insets

local coins = Kit.counter(sg, { name = "Coins", value = 0, color = Kit.Colors.Currency, icon = COIN_ICON,
	position = UDim2.fromOffset(28, 12) })
coins.Set(1250)                                                  -- ticks up + pops; instant under reduced motion

local shop = Kit.modal(sg, { name = "Shop", title = "SHOP", onClose = function() end })
local openBtn = Kit.button(sg, { name = "ShopButton", role = "Currency", icon = SHOP_ICON,
	size = UDim2.fromOffset(56, 60), anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 12, 0.45, 0),
	onActivated = shop.Open })

local tabs = Kit.tabs(shop.Content, { "Abilities", "Skins", "Boosts" }, function(name) --[[ refill grid ]] end)
local grid = Kit.grid(shop.Content, { position = UDim2.fromOffset(0, 56), size = UDim2.new(1, 0, 1, -56 - 60),
	minCell = 92, maxCell = 120, aspect = 1.15 })
Kit.tile(grid, { id = "Dart", name = "Dart", icon = DART_ICON, rarity = "Rare", price = 2250, state = "buy",
	onActivated = function() --[[ select ]] end })

local buy = Kit.button(footer, { name = "Buy", text = "BUY 2.25K", role = "Primary", size = UDim2.fromOffset(170, 54),
	onActivated = function() BuyRemote:FireServer("Dart") end })
buy.SetEnabled(false, "NEED 2.25K")                              -- disabled + says why

local toasts = Kit.toasts(sg)
toasts.push("+500 coins!", { color = Kit.Colors.Currency, priority = 5 })
```

Depth and polish (added 14 Nov 2026 from the Develuper UI videos):

```lua
Kit.label(parent, "SHOP", 28, { depth = 4 })   -- depth text: a darker copy 4 px under the text
Kit.depthText(existingLabel, 3)                 -- add depth to a label you already made
Kit.edgeHighlight(frame, 12)                    -- thin light line just inside a rounded frame
Kit.modal(sg, { title = "INDEX", transition = "slide" })  -- fade-slide open instead of the pop
Kit.Scale.Hover, Kit.Scale.Press = 1.1, 0.92    -- juicier hover/press for the whole kit
Kit.TextDepth = 0; Kit.EdgeHighlight = 1        -- turn both effects off for a clean style
```

Buttons, panel titles, counters and toasts get depth text automatically (`Kit.depthFor(size)`), and plates and buttons get the edge highlight. The darker copy is tagged `UIDecor`, so the audit skips it.

Pieces: `screen`, `label`, `depthText`, `edgeHighlight`, `plate`, `button` (roles Primary/Secondary/Currency/Danger/Locked; `SetEnabled`, `SetRole`, `SetText`, `Destroy`), `counter`, `grid`, `tile` (states buy/owned/equipped/locked), `tabs`, `modal` (backdrop, open/close tweens that cancel each other, gamepad focus trap, B closes, focus restore), `toasts` (one at a time, priority, dedupe), `bin` (cleanup), `abbrev` (1.2K / 3.4M), `tween`, `reducedMotion`, `usesGamepadFocus`.

## What every component must do (when porting into an existing kit)

**Button**
- Hit area ≥ 44×44 *after* any decorative base/shadow is subtracted.
- `Activated` for the action; `AutoButtonColor = false`; own pressed state (push down 3 px + scale 0.92–0.95) and release (Back Out or Elastic).
- Depth on the plate *and* on the label (and icon), plus the inner edge highlight.
- Art buttons (`ImageButton` with pipeline art): `HoverImage` and `PressedImage` swap to a brighter or pressed version with no code. Only script the swap when the state needs more than an image change.
- Disabled = `Interactable = false` + muted colour + a reason in the label.
- One role per meaning, used everywhere (green always means buy/confirm, red always close/danger).

**Panel / modal**
- Backdrop that swallows taps (and optionally closes on tap-outside).
- Open: scale 0.85→1 Back Out + fade, ~0.22 s (small popups, rewards), or a fade slide (rises ~40 px into place, Quint Out 0.35 s) for big panels like a shop or index.
- Big panels: follow the shop layout in `design-tokens.md` (a top bar with a title tab and red Close, the hero item first and biggest, green price buttons with currency icons). Close: ~0.14 s Quad In. Cancel the running tween before starting the other; hide only when the close tween `Completed` with `PlaybackState.Completed`.
- Gamepad: trap focus (`SelectionGroup` + `Stop`), select the safest useful button one frame after open, B closes, restore the previous selection.
- Close button ≥ 44 px, inside the panel's top-right corner.
- Size: scale of the screen (≈ 94% × 90%) capped with `UISizeConstraint.MaxSize` (≈ 860×560) so PC doesn't get a billboard.

**Counter**
- Big outlined number, small icon poking out of the plate, abbreviations from one function.
- Tick-up 0.4–1.2 s scaled by the size of the jump; a small pop on gain; no animation on loss (just set it).

**Grid**
- `ScrollingFrame` + `AutomaticCanvasSize = Y` + `UIPadding` (extra bottom padding) + `UIGridLayout`.
- Columns from the grid's own width: `cols = floor((w + gap) / (minCell + gap))`, `cell = min(maxCell, floor((w - gap*(cols-1)) / cols))`; recompute on `AbsoluteSize` change.
- Pool tiles when switching tabs instead of destroying hundreds of instances.

**Tile**
- Same size for every state; states differ by label + colour + icon, not by layout jumping.
- Rarity is an edge colour *and* a word or gem somewhere (colour-blind kids).
- Owned / Equipped / Locked must be readable at a glance in a 92 px tile.

**Toasts and popups**
- One message centre-top at a time; queue with priority; drop duplicates; cap the queue.
- Big moments (level up, rare reward) are their own full-screen reveal, never a toast, and never while another reveal is up.

## Patterns not in the starter kit

**Screen lifecycle (every screen module)**

```lua
local Screen = {}
local bin = Kit.bin()
function Screen.open()
	bin:add(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshHints))
	bin:add(dataChanged:Connect(render))
	render()
	modal.Open()
end
function Screen.close()
	modal.Close()
	bin:clean()          -- every connection/tween this screen made is gone
end
```

**Narrow vs wide composition (switch on the root's real width)**

```lua
local function compose()
	local narrow = root.AbsoluteSize.X < 700
	sidebar.Visible = not narrow                 -- narrow: categories become a tab strip on top
	tabsStrip.Visible = narrow
	details.Visible = not narrow                 -- narrow: details open as their own state
	grid.Size = if narrow then UDim2.new(1, 0, 1, -52) else UDim2.new(0.6, 0, 1, 0)
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(compose)
task.defer(compose)
```

**Reward reveal (skippable, staged)**
1. Dim the world (backdrop to 0.4) 0.15 s.
2. Item pops in at centre: scale 0 → 1.15 → 1 (0.35 s Back Out) with the rarity colour ring behind it.
3. Name + rarity word fade up 0.2 s later; burst of glints (MEGA BITE `UIFx.BurstAt`) once.
4. Big CLAIM / EQUIP button appears last; tap anywhere skips to this state.
5. Reduced motion: show step 4 immediately.

**One controller wires every button**
Like Develuper's `UIController` LocalScript: loop over the ScreenGui's `GetDescendants()`, give every `GuiButton` hover, press and release, and read a string attribute (e.g. `Opens = "Shop"`) to know which panel a button opens. New buttons then need no code, only the attribute.

**Text: baked into the art or made in Studio?**
- The owner's rule: **no text in ChatGPT art** (ChatGPT garbles letters, and baked text can't change). So all words are Studio text, and display text gets its depth from `Kit.depthText` instead of from the art.
- In Studio, use the kit font with an outline for numbers, prices, names, anything that changes or is tapped, and anything big.
- Logos and one-off title banners can be art, made with the art pipeline's own text step (added in code or an editor, not by ChatGPT).

**Art for UI**
Export or cut every piece as big as possible but **under 1024 px** on its longest side (Roblox downscales larger images and they come out soft). Keep a few pixels of padding so outlines and glows aren't clipped, and set `SliceCenter` for anything that stretches.

**Input hints**
Show only the hints for the current `PreferredInput` (a "B" glyph on gamepad, nothing extra on touch, "E" on keyboard). Update on `PreferredInput` change; never hide the only explanation of an action during a switch.

**Purchases**
UI → `RemoteFunction`/`RemoteEvent` → server checks price, currency, ownership → server replies → UI shows result (toast + counter tick + tile state). Lock the BUY button while waiting (busy state) so double taps don't double-buy. Robux purchases go through `MarketplaceService:PromptProductPurchase`/`PromptGamePassPurchase`; never fake a Robux prompt.
