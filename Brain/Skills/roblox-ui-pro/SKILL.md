---
name: roblox-ui-pro
description: "Use for ANY Roblox UI work: building, fixing, restyling or reviewing a HUD, shop, inventory, index, settings, popup, reward screen or menu. Covers correct ScreenGui setup (respawn, safe areas, phone/tablet/console layout, touch and gamepad), concrete design numbers, a house-style UI kit, cheap-looking/AI-slop checks, and a Studio MCP loop that audits and screenshots the UI on real device sizes until it passes. Use it even when the user only says 'make the UI better', 'the shop looks bad', 'add a button', or 'it breaks on mobile'."
---

# Roblox UI Pro

Build Roblox UI that works on every device and looks hand-made, then prove it in Studio. Three jobs, in order: **correct** (it works on phone, tablet, PC and console), **readable** (a kid gets it in one glance), **crafted** (it looks like this game, not like any AI game). Never decorate a broken layout.

Reference files (read when the step needs them, not all up front):

| File | Read when |
|---|---|
| `references/roblox-ui-api.md` | Writing or fixing any UI code: containers, insets, layouts, flex, text, strokes, shadows, styling, input and focus. API facts checked live in Studio. |
| `references/design-tokens.md` | Choosing sizes, spacing, type, colours, radii, strokes, motion, or a style preset. |
| `references/components.md` | You need a button, counter, panel, tab bar, grid, modal, toast queue or reward reveal. Luau recipes. |
| `references/slop-check.md` | Before saying any UI is done, or when the user says it looks cheap, AI-made or boring. |
| `references/verify-in-studio.md` | Every time you finish a change and Studio MCP is connected. The audit + screenshot loop. |
| `scripts/ui_audit.luau` | Run it through `execute_luau` (the verify file says how). Finds clipping, tiny buttons, tiny text, low contrast, buttons under the thumbstick/jump button, invisible-but-clickable panels, respawn duplicates, too many fonts/radii/text sizes. Read-only. |
| `assets/UIKitStarter.luau` | The game has no UI kit yet. A tested kid-simulator-style kit (button, counter, tile, grid, tabs, modal, toast queue) to copy into ReplicatedStorage and recolour. |

## 1. Read the game's UI language first

Most UI that looks "AI" is UI that ignores the game it lives in. Before designing anything:

- **Find the existing kit.** Search for a UI kit / theme / style module (names like `UIKit`, `Theme`, `Style`, `UIFx`, `Tokens`, a `StyleSheet`), plus the game's notes (vault art style guide, "UI direction" notes). If a kit exists, **extend it**: reuse its colour tokens, font, outline thickness, plate/button/tile builders and effects. Never start a parallel style.
- **See the real thing.** Screenshot the live UI (Play mode; most games build UI at runtime, so Edit mode shows nothing). Note the font, palette, outline, corner radius, icon family, animation feel.
- **Record what must keep working**: instance names other scripts look up (`WaitForChild`, `FindFirstChild`, PlayerGui paths), RemoteEvents, attributes, tags. Search the scripts before renaming or moving anything.
- If there is no kit, start one first (copy `assets/UIKitStarter.luau`, recolour its tokens from the game's art), then build screens from it.

## 2. Plan the screen before code

Write a short plan (in chat or the game's notes):

- **Job of the screen** in one sentence, and its **one focal point** (the thing the eye hits first: the BUY button, the reward, the currency).
- **Regions**: header / content / action row / HUD edge groups. What moves or collapses on a phone in landscape (the kids' main device), and in portrait if `StarterGui.ScreenOrientation` allows it.
- **States**: default, empty, loading, error, locked, owned/equipped, plus button states (pressed, selected, disabled). An empty inventory must say what to do, not show a blank box.
- **Input**: what touch, mouse and gamepad each do; what is selected first on gamepad; how to close (button + B/Back + Escape).
- **Popups**: what else can appear at the same time (rewards, notifications, offers). Two things must never shout at once; use the toast queue.

Skip the written plan only for a one-line tweak.

## 3. Build it correctly

These are the rules that stop the classic Roblox UI bugs. Details and exact APIs: `references/roblox-ui-api.md`.

- **One `ScreenGui` per screen**, named for its role. Set `ResetOnSpawn = false` for HUDs and menus (default is `true`: UI vanishes or duplicates on respawn). Set `ZIndexBehavior = Sibling` explicitly (`Instance.new` defaults to `Global`). Use `DisplayOrder` bands: world/FX < HUD < menus < modals < toasts < full-screen reveals.
- **Safe areas**: interactive UI keeps `ScreenInsets = CoreUISafeInsets` (the default). Only decoration bleeds to the edges (`DeviceSafeInsets`/`None` + `IgnoreGuiInset`). Never put a button where the notch, topbar, thumbstick or jump button is.
- **Layout with layouts**: `UIListLayout`/`UIGridLayout` + `UIPadding` for anything repeated; flex (`HorizontalFlex`, `UIFlexItem`) to share space. Scale for placement and regions, offset for component sizes and gaps, and bound both with `UISizeConstraint`/`UIAspectRatioConstraint`. Pure scale makes tiny buttons on phones; pure offset overflows them.
- **Design the narrow layout explicitly** (a ~700 px wide, ~340 px tall phone) instead of shrinking the PC layout. Switch on the root's `AbsoluteSize`, not device names.
- **Text**: one font family (two at most). Set sizes from the type scale; if you use `TextScaled`, always add a `UITextSizeConstraint`. Text over the 3D world needs an outline (`UIStroke`, `ApplyStrokeMode = Contextual`) or a backing plate.
- **Buttons**: wire `Activated` (works for mouse, touch and gamepad), not `MouseButton1Click`. Set `AutoButtonColor = false` when you draw your own states. Disabled = `Interactable = false` + a visibly muted look + a reason ("Need 500 coins").
- **Gamepad**: on open, select the safest useful button only when `UserInputService.PreferredInput` is `Gamepad`/`MicroGamepad`; trap focus in modals (`SelectionGroup` + `SelectionBehavior* = Stop`); restore focus on close.
- **Lifecycle**: each screen owns its connections and tweens and cleans them up on close. Cancel a running tween before starting the opposite one, or a fast open/close leaves an invisible panel that still eats clicks.
- **Server-authoritative**: the UI asks, the server decides (purchases, rewards, equips). Never trust a price or ownership check done only in the LocalScript.

## 4. Make it look crafted

Numbers and presets: `references/design-tokens.md`. Ready-made pieces: `references/components.md`.

- **Pick the preset that fits the game** (kid simulator / cartoon, clean, competitive, horror, futuristic) or the game's own kit, and stay inside it. Kid simulator games are *supposed* to have thick ink outlines, chunky plates and juicy taps. "Slop" is not a style; it is inconsistency, defaults and noise.
- **Identity and depth**: every element has the game's look *and* reads as 3D. That means a darker base under plates and buttons, a gradient that's brightest at the top, a thin light edge just inside, and depth under display text. Flat looks unfinished.
- **Hierarchy before effects**: size, weight, colour and position decide what matters. One primary button per screen; secondary and quiet buttons look different. In shops, the best deal goes first and biggest, and prices are green buttons with a currency icon.
- **Every value from a token**: spacing scale, type scale, 2–3 radii, 1–2 stroke weights, palette roles. If you type a one-off number, it is probably wrong.
- **Real art beats Frames**: icons, plates and banners from the game's art pipeline (the `roblox-chatgpt-art-pipeline` skill), not emoji, not default grey Frames, not stock Roblox icons.
- **Motion with a job**: a pop on press, a slide/scale on open, a tick-up on currency, a burst on rewards. 0.08–0.30 s, interruptible, never per-frame loops, honour `GuiService.ReducedMotionEnabled`.
- **Sound with a job**: every tap and purchase has a short UI sound (the `roblox-game-sounds` skill makes them).

## 5. Verify in Studio (the loop)

When the Roblox Studio MCP is connected, do this before you call anything done. Full steps: `references/verify-in-studio.md`.

1. Set a device in the Device Simulator (Edit mode), start Play, open the screen from the `Client` datamodel.
2. Run `scripts/ui_audit.luau` in the `Client` datamodel. Fix every ERROR. Fix WARNs unless you can say why they are fine.
3. `screen_capture` and look at it like a kid on that phone: what do I see first, can I tap it, can I read it?
4. Repeat on the device matrix: small phone, big phone, tablet, PC, console. Add portrait only if the game allows it.
5. Stop Play, stop the simulation, and say "Studio reset to default viewport."

No Studio connection: say so, and give the user the matrix to check by hand. Do not claim it works on phones without seeing it.

Do not save the place, publish, or spend Robux without the owner's OK. Play sessions are fine; they don't change the place.

## 6. Judge the look

- Run `references/slop-check.md` against the screenshots. Fix the top tells.
- For anything players will judge by eye (a new shop, index, HUD), also run the `quality-nerd-kid-sim` skill (cheap tells vs wow moments) and, when several popups/effects can stack, the `overstimulated-kid-sim` skill. For first-minute flows (first shop, first reward), the `impatient-kid-sim` skill.

## 7. Report

Keep it short:

- What changed (screens, files/scripts, kit additions).
- The verify table: device | viewport | audit errors/warnings | what the screenshot showed.
- What is not done or not verified (portrait not tested, console not tested, art still placeholder).
- Fixes that need art or sound, as a list the art/sound skills can pick up.

## Fixing an existing UI (upgrade order)

When asked to "fix", "clean up" or "make better" an existing screen, go in this order and stop when it's good: inspect behaviour → list what must keep working → fix structural bugs (respawn, insets, ZIndex, dead tweens) → fix responsiveness → fix hierarchy → apply polish from the kit → add motion and sound → re-test input → re-run the verify loop. Do not replace a working interface with a different one just to show work.
