---
date: 2026-11-05
tags: [gymarc, ui, fonts, prompt]
---
# GYM ARC - Prompt: fonts through the UI kit (whole game)

Owner (5 Nov): Physique panel mixes 3 fonts (italic sports titles, bubbly cartoon labels on GENES, italic labels on MUSCLES, thin dim grey small text); "do through the ui kit".

```text
GYM ARC – FONTS THROUGH THE UI KIT (whole game). Read vault GYM ARC\Features\GYM ARC - UI System.md first. Don't publish.

1. THEME (one place): add to the UI kit Theme
   - Font.Display = the bold italic sports font used for "PHYSIQUE" and the tabs (all caps).
   - Font.Text = Builder Sans Bold.
   - Font.Number = Builder Sans Bold with tabular (fixed-width) digits (FontFace + monospaced-digit setting if available; otherwise right-align numbers in fixed-width labels).
   - Sizes (phone first, scale up on PC): Title, Tab, Label, Body (≥14 px on phone), Small (≥13 px), BigNumber.
   - Colours: Text.Primary white, Text.Secondary ≥ #D0D0D0 (no dim grey), Positive green, Negative red; grade colours from the grade ladder (D grey, C green, B blue, A purple, S gold).
   - Stroke: Kit helper for a thin dark UIStroke (~1.5 px) on display text over images.
2. KIT HELPERS: Kit.title / Kit.label / Kit.body / Kit.number (and buttons/tabs) read ONLY from Theme. No window sets Font/TextSize/TextColor3 directly any more.
3. MIGRATE THE WHOLE GAME: find every TextLabel/TextButton/TextBox created in code or saved in StarterGui/ReplicatedStorage that sets its own font/size/colour; switch them to the Kit helpers. Remove the bubbly cartoon font everywhere (list where it was used). Titles, tabs, names, labels = Display; descriptions = Text; values, %, multipliers, prices, timers = Number.
   - Exceptions to keep and list: the GYM ARC logo images, run-card card faces (Merriweather serif is intentional), anything in images.
4. Do it in batches (HUD, Physique, Shop/Pump Shop/Coach Dex, Inventory/Looks, Trainers, Run Cards UI, Genetics, Hall of Fame, Plate Forge, popups/toasts, nameplates/billboards). After each batch, screenshot it.
5. Check nothing overflows or truncates on phone (longest strings: muscle names, prices, other languages if localized); use TextScaled only as a fallback with max size.
6. Progress note: the Theme values, the list of windows migrated, before/after screenshots (PC + phone) of Physique (both tabs), HUD, Pump Shop, Run Cards.
```
