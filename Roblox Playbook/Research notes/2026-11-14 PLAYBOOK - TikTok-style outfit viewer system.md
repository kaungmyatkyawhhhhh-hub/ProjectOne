# PLAYBOOK: TikTok-style outfit viewer (press E → turntable studio → buy)

- **Date:** 2026-11-14
- **Related:** [[2026-11-14 PLAYBOOK - Roblox classic outfits (shirt + pants) with ChatGPT]], [[2026-11-14 Watch study - Cheap Roblox outfit TikToks (shirt design reference)]]
- **Built in:** a blank Studio place ("Place1", not saved by Claude). Source files are kept in the outfit work folder under `showcase/`.

![[2026-11-14 Outfit viewer - viewer_pc1080.jpg]]
![[2026-11-14 Outfit viewer - viewer_phone_A06.jpg]]

## How it works
- **Lobby:** `Workspace.OutfitShowcase.Pedestals.<Id>` holds a dark pedestal with a neon ring, a name tag, and a ProximityPrompt "View outfit" (E). The prompt has the attribute `OutfitId`, and a `Stand` attachment marks where the character's root goes.
- **Server** (`ServerScriptService.OutfitShowcaseServer`):
  - builds each display character with `CreateHumanoidModelFromDescription` (R6), with accessory types looked up from `GetProductInfo`, and plays an idle animation;
  - keeps a clean copy in `ReplicatedStorage.OutfitShowcase.Models`;
  - answers `GetOutfitInfo` (price, for sale, `PlayerOwnsAsset`);
  - prompts purchases only for asset ids that belong to an outfit, with a rate limit;
  - Buy all uses `PromptBulkPurchase`, falling back to a single prompt;
  - after a purchase, fires `PurchaseUpdated` so the list refreshes.
- **Client** (`StarterPlayerScripts.OutfitViewer`):
  - builds a private studio far from the map, only visible to that player: navy walls, a see-through dark floor with an upside-down clone under it as the reflection, and key/fill/rim lights;
  - adds a halo spotlight that always lights the wall behind the character;
  - the character spins on a turntable;
  - drag, the right stick, or a one-finger touch orbits the camera; scroll, pinch or LT/RT zooms;
  - zooming in glides the camera up to the face, and the spin slows on a close-up.
- **Layout:** the outfit gets about 80% of the screen. The "In this fit" column (about 20%) has one tappable card per item. A card buys the item, or shows a toast saying it's owned or not on sale yet. Buy all sits below the cards: a glow ring pulse, a 3D base, a gradient face and a sheen sweep, all off with Reduced Motion.
- **Config** (`ReplicatedStorage.OutfitShowcase.Config`):
  - `ShirtTemplate`/`PantsTemplate` are image ids, for display only;
  - `ShirtAssetId`/`PantsAssetId` are catalog ids, for buying (nil = "Soon");
  - `Accessories` is a list of catalog ids;
  - also holds the stage tint, turntable speed, zoom limits and face height.

## Gotchas found while testing (all fixed)
1. **Newer places have no `PlayerModule`.** A `WaitForChild("PlayerModule")` hangs forever, leaving a black screen. Freeze the character with WalkSpeed/Jump = 0 instead.
2. **On phones something resets `CameraType` to Custom,** and Roblox's camera overrides yours. Use `BindToRenderStep(Camera+1)` and re-assert Scriptable every frame.
3. **A `UIGradient` on a TextButton tints its text too** (white text turned green on green). A child "shine" also draws on top of the parent's text. Fix: put the gradient on a separate Face frame and the label on a layer above it.
4. **BuilderSans has no ✕ or ✓ glyphs** (they render as a box). Draw icons from rotated rounded bars.
5. **Blue tint on white clothes:** the map's Atmosphere haze plus the sky's environment light (strongest at phone graphics quality). While viewing, set `Atmosphere.Density = 0` and `EnvironmentDiffuseScale`/`EnvironmentSpecularScale = 0`, then restore them on close.
6. **Floor `Reflectance` reflects the blue sky.** Use 0 and rely on the clone reflection.
7. **Testing:** `execute_luau` can't connect MarketplaceService events (capability). Verify purchases by listening to the RemoteEvent on the Server datamodel. Open the viewer through the Studio-only `ViewerTest` BindableEvent.

## UI verify (roblox-ui-pro, 2026-11-14)
| Device | Viewport | Audit | Screenshot |
|---|---|---|---|
| Galaxy A06 | 705x338 | 0 / 0 | outfit 80%, 2.5 cards + scroll, toast works |
| iPhone 17 Pro | 750x381 | 0 / 0 | halo backdrop visible, 3 cards |
| iPad 10th gen | 1179x819 | 0 / 0 | all 4 cards, Buy all glow |
| HD 1080 | 1919x1079 | 0 / 0 | TikTok studio look, reflection |
| Xbox One | 1919x1079 | 0 / 0 | gamepad focus on Buy all, controller hint |

Not checked: portrait orientation, a real device, the actual purchase confirmation (only the prompt request was verified).

## To do before it can sell clothes
- Publish each shirt and pants as classic clothing (official fee shown on upload; docs say 80 Robux each). Then put their catalog ids in `ShirtAssetId`/`PantsAssetId`.
- Copy the place's `OutfitShowcase` folders and scripts into the real game.
- UI sounds (tap, buy), using the `roblox-game-sounds` skill.
