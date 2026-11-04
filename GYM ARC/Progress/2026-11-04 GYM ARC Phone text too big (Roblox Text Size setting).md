---
date: 2026-11-04
tags: [gymarc, progress, ui, bug]
---
# GYM ARC - Phone text too big (Roblox Text Size setting)

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - UI System]]

## The bug (owner's phone screenshot, 4 Nov)
On the owner's phone the right-side cards broke: "TODAY'S...", "GROWTH...", "76% · NEEDS BACK, SHOUL" ran past both edges of the card, "TAP FOR YOUR" sat over "2nd trainer", and the top bar pills were huge. In Studio at the same phone size everything fit.

## Cause
Roblox's own **Text Size** setting (Roblox Settings > Accessibility; `GuiService.PreferredTextSize` Large / Larger / Largest) makes every text in every game bigger by itself. Our cards are drawn at fixed sizes, so the bigger words ran out of them. Studio can't switch this setting on, so tests never showed it.

## Fix (in Studio, not published)
- New `StarterPlayerScripts/TextSizeGuard`: only when that setting is above normal, every text in PlayerGui (TopbarPlus too) gets a `UITextSizeConstraint` at its own size. Roblox's documented way to keep text at its designed size. Text with TextScaled or its own constraint is left alone.
- `Kit.Fit` measures text at the designed size on those phones, so it doesn't shrink words for no reason.
- The GROWTH SPURT card's second line now cuts with "..." inside the card instead of running out.
- Studio check: Workspace attribute `TestTextCap = true` runs the guard in Studio. Test: 3,088 texts held, none moved, no errors.

## Owner to do
- Publish, then open the game on the same phone and check the right cards and the top bar.
- Note: players who set Roblox's Text Size to Large won't get bigger text in GYM ARC (it stays the designed size).
