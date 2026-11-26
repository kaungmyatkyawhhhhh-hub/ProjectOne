---
name: roblox-ui-pro
description: "Use for ANY Roblox UI work: building, fixing, restyling or reviewing a HUD, shop, inventory, index, settings, popup, reward screen or menu. Ships the owner-approved house style (Develuper 'UI 10x', copied 1:1 from measured video frames) as a code generator: SVG pieces rendered to PNG, uploaded, 9-sliced in Luau. Also covers correct ScreenGui setup (respawn, safe areas, phone/tablet/console, touch and gamepad), AI-slop checks, and a Studio MCP loop that screenshots the UI on phone and PC sizes until it passes. Use it even when the user only says 'make the UI better', 'the shop looks bad', 'add a button', or 'it breaks on mobile'."
---

# Roblox UI Pro

Build Roblox UI that works on every device, looks like the owner's approved style, and is proven in Studio. Do three jobs in this order:

1. **Correct:** it works on phone, tablet, PC and console.
2. **Readable:** a kid gets it in one glance.
3. **On-style:** it uses the house kit and is never improvised.

Never decorate a broken layout.

**HUD lesson (18 Nov 2026, EVOLVE).** The owner put our Neon HUD next to a ChatGPT mock of the same HUD and called the mock "SIGNIFICANTLY WAY BETTER". What the mock had and ours lacked:
- light blue bevelled rims on deep navy, with navy outlines instead of pure black;
- a character portrait in a gold hex;
- the title on a painted brush band, with the key number in gold;
- slot rows with an icon each, and the number in cyan;
- one colour per menu button (green, blue, purple);
- the currency icon breaking out of its plate.

The fix is `assets/develuper-kit/hud.html`, the mock look as a generator. It has 9-slice insets per piece and a parametric face generator for the species portraits. **When the owner shows a mock they like, match the mock**, not the kit, and start a HUD from `hud.html`. Ask for or make a ChatGPT mock of the screen early; it is a cheap target.

**Popup lesson (26 Nov 2026, GYM ARC muscle picker).** A ChatGPT-art popup (gold bolted frame, sparkles, glossy pills, cartoon hero icons) got "this is very bad. study modern GUI's", then "the pictures that chatgpt made look very AI generated and not modern GUI looking". What passed is the TDS lobby look (vault: `Research - Modern lobby HUD ... (TDS)`):
- no frame: the world blurs (BlurEffect ~14, 0.12 s in) and the HUD steps aside; the choices float;
- a white header with a thin rule line after it, a small grey helper line under it (e.g. "Auto-picks in 4s");
- solid-colour cards (one colour per choice, top-lit gradient, 8 px corners, a 1.5 px light edge), the name inside the card on a dark bottom fade, the card itself is the button (hover lights the edge, the pick snaps a gold outline), cards slide in 50 ms apart;
- the art fills the card and may break out of the top. **No ViewportFrames anywhere** (owner: "laggy and theres no good lighting"); art is a plain image, and the owner makes the pictures himself unless he asks.
- Never put a heavy ornamental frame around a modern popup.

**The look is settled.** The house style is Develuper's "UI 10x", copied 1:1. The owner approved it on 18 Nov 2026 ("these are so great") after rejecting four other looks. Use it for every game unless the owner asks for something else. Build new pieces with the kit's generator. Never hand-tune by eye, and never draw plates out of Frames and UIStroke.

## Files

| File | Read when |
|---|---|
| `references/develuper-style.md` | **Any visual work.** The recipe, measured numbers, layout sizes, the pipeline from SVG to Studio, fitting, gotchas, and the rejected styles. |
| `assets/develuper-kit/` | Making or changing art. It contains:<br>- `hud.html`: the owner-preferred HUD look (bevel plate, gold hex portraits, slot rows, coloured square buttons); `export.py` renders it too;<br>- `kitgen.html`: frame pieces;<br>- `icons.html`: item and HUD icons;<br>- `export.py`: PNG export, ≤1024 px, transparent;<br>- `artlua.py`: the Luau ART table with trim rect and 9-slice;<br>- `exact.html`/`card.html` + `fit*.py`/`rows.py`: fitting against his frames;<br>- `EvolutionUI_example.luau`: a full HUD, shop, list, grid and toast wired to the kit. |
| `references/roblox-ui-api.md` | Writing or fixing UI code: containers, insets, layouts, text, input, focus. |
| `references/components.md` | Behaviour recipes: tab bar, modal, toast queue, reward reveal. Take the behaviour only; the look comes from the kit. |
| `references/design-tokens.md` | Spacing, type scale and motion timings. Its colour and plate presets are **superseded** by the house style. |
| `references/slop-check.md` | Before saying any UI is done, or when the owner says it looks cheap or AI-made. |
| `references/verify-in-studio.md` + `scripts/ui_audit.luau` | Every finished change, when Studio MCP is connected. The audit is read-only. |
| `assets/UIKitStarter.luau`, `assets/UIFx.luau` | Structure only: screens, toast queue, effects. **Never use their Frame-drawn plates as the look.** |

## 1. Read the game first

- **Find the existing UI script and kit.** Look for an `ART` table, a `UI/Kit` module, or a script like `EvolutionUI`. Extend what is there. If the game already uses the house kit, add pieces to the same `ids.json`/ART table.
- **See the real thing.** Start Play and screenshot the screen. Most games build their UI at runtime, so Edit mode shows nothing.
- **Record what must keep working:**
  - instance names other scripts look up (`WaitForChild`, PlayerGui paths);
  - RemoteEvents;
  - attributes;
  - tags.

  Search the scripts before renaming anything.

## 2. Plan the screen

Write a short plan; skip it only for a one-line tweak. It covers:

- **Job and focal point:** the screen's job in one sentence, and the one thing the eye hits first.
- **Regions:** what moves on a phone in landscape. That is the kids' main device.
- **States:**
  - default, empty (tell the kid what to do), locked (show the reason, e.g. "Unlocks at Ape");
  - owned or equipped;
  - pressed or disabled.
- **Input:** touch, mouse and gamepad; what is selected first; how to close.
- **What else can pop up at the same time.** Two things never shout at once; use the toast queue.
- **Choice screens are for kids (owner, 27 Nov 2026, GYM ARC muscle picker):** "dont make it overcomplicated or overstimulating with many texts and making them hard to choose". Each option gets one big icon, one big word and at most one short line. No stat bars, percentages or lists on the cards. Show one clear default. Modern references (TDS, RIVALS) give the style, not the amount of detail.

## 3. Build it correctly

Details: `references/roblox-ui-api.md`.

- **ScreenGuis:**
  - One `ScreenGui` per role, with `ResetOnSpawn = false` and `ZIndexBehavior = Sibling`.
  - `DisplayOrder` bands, lowest to highest: HUD (10), toasts (15), menus (20), modals and reveals above.
- **Safe areas:** interactive UI keeps `ScreenInsets = CoreUISafeInsets`. Nothing goes under the notch, the topbar, the thumbstick or the jump button.
- **Don't cover the game (owner + friends, 18 Nov 2026, EVOLVE).** A 1.7x HUD in the top centre plus a toast over the character got "i cannot see at all, so annoying". Their tests: "every user's experience" wants the middle clear. So:
  - Persistent plates (status, currency, menu) go in the **top-left corner cluster**, never centred.
  - Toasts go under that cluster. Frequent celebrations (every life) go in the **lower third**, off the character.
  - **Cap the scale at 1.2**, so PC gets more game, not a bigger UI. Shrink corner plates to about 0.8 on PC, and keep them at 1 on phones so text stays at 13 px or more.
- **One design size, scaled:**
  - Put everything in a 720×360-point root.
  - The root gets a `UIScale` of `k = clamp(min(W/760, H/400), .72, 1.2)` (it was `clamp(min(W/720, H/360), .75, 1.8)`; at 1.8x the HUD buried the game on PC) and a size of `(W/k, H/k)`.
  - Lay out in points.
  - Design the narrow case explicitly, switching on `AbsoluteSize`.
- **Text:** Fredoka One only.
  - Info at least 13 pt, names and prices 15–18 pt, window titles 28 pt.
  - Every label is white with a black `UIStroke` (`Contextual`, size/9) and a black depth copy (size/12 down).
- **Buttons:**
  - Use `Activated`, with `AutoButtonColor = false`.
  - Add a squish on press (scale 0.93, 0.06 s).
  - Disabled: grey tint, muted text, and the reason in the label.
- **Gamepad:**
  - Select the first button on open only when `PreferredInput` is a gamepad.
  - Trap focus in modals.
  - Restore focus on close.
- **Lifecycle:**
  - Cancel the opposite tween before starting one.
  - One window open at a time, with a dim backdrop that closes it.
  - Close windows on `GuiService.MenuOpened`.
- **The server decides** purchases, rewards and equips. Paid random items show exact odds and pass a PolicyService check. No fake timers and no "was" prices.

## 4. Make it look like the house style

Everything is in `references/develuper-style.md`. The short version:

- **Pieces are PNGs from the generator, 9-sliced.** Code only places images, text and motion.
  - New piece: add it to `PIECES` in `kitgen.html` with an existing recipe (`pill`, `button`, `card`) and colour set.
  - New icon: add it to `ICONS` in `icons.html`, drawn in the navy-outline, cel-shaded style.
  - Then run export → upload → `artlua.py` → paste into the ART table.
- **In Luau:**
  - always set `ImageRectOffset/Size` from `rect`;
  - set `SliceCenter` relative to the rect;
  - use `SliceScale = 0.5`, because the art is 2 px per point.
- **Screen anatomy:**
  - white panel;
  - green "Title!" bar with an icon, overlapping the top-left;
  - red **"Close"** text button at the top right;
  - tier-coloured cards (hero yellow first and wider, then magenta, purple, cyan, green);
  - every price on a green pill with the currency glyph;
  - lists made of cyan rows, with a green action button and yellow for the current pick.
- **Shops are cards with big art**, not text rows. Each card has, top to bottom: the name, the art (about 35% of the card), one benefit line, and the price pill. Owned items are dimmed with "Owned". The next card peeks in at the edge, and tabs split DNA from Robux.
- **Motion with a job:**
  - press squish;
  - window pop (0.9 → 1, Back, 0.18 s);
  - toast slide.

  Keep each one 0.06–0.3 s, honour `ReducedMotionEnabled`, and never loop every frame.
- **Sound with a job:** use the `roblox-game-sounds` skill.
- **Off-limits:** spiky sunburst rays, radial glows behind items, emoji icons, default grey Frames, and stock Roblox icons.
- **When the owner dislikes a result:** measure it against his frame and fix the numbers (see "Fitting" in the reference). Then write the lesson into the reference file and the vault copy.

## 5. Verify in Studio (the loop)

When Studio MCP is connected, do this before calling anything done. Full steps: `references/verify-in-studio.md`.

1. Start Play. Open each screen from the `Client` datamodel (set `Visible` on the window and its backdrop), then `screen_capture` it.
2. Check the PC size, then a phone. Use the Device Simulator, or emulate the phone: set each `Root.UIScale` to `k` and `Root.Size` to `(W/k, H/k)` for 844×390 and 667×375.
   - Look for clipping at the top: the title bar and Close overhang the panel by 22 pt.
   - Look for an empty band under the cards.
   - Check that text is readable.
3. Run `scripts/ui_audit.luau` in `Client`. Fix every ERROR. Fix every WARN unless you can explain it.
4. Stop Play.

New uploads can show blank for a few minutes while moderation runs; re-screenshot before you debug the ids. With no Studio connection, say so. Never claim it works on phones without seeing it.

Do not save or publish the place without the owner's OK. Play sessions are fine.

## 6. Judge the look

- Check the screenshots against `references/slop-check.md`.
- Put the result next to his frame and check that it reads as the same style.
- For screens players judge by eye, also run `quality-nerd-kid-sim`.
- Where popups stack, run `overstimulated-kid-sim`.
- For first-minute flows, run `impatient-kid-sim`.

## 7. Report

Keep it short:

- What changed: screens, scripts, new pieces and their asset ids.
- Verify table: size | what the screenshot showed | fixes.
- What is not verified: console, portrait, tablet.

## Fixing an existing UI (upgrade order)

Work in this order and stop when the UI is good:

1. Inspect how it behaves now.
2. List what must keep working.
3. Fix structural bugs: respawn, insets, ZIndex, dead tweens.
4. Fix responsiveness.
5. Fix hierarchy.
6. Swap its art to the house kit.
7. Add motion and sound.
8. Re-run the verify loop.

Keep the old script as a disabled backup in ServerStorage until the owner signs off.
