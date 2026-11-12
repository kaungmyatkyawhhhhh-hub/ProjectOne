# Stomp Evolution - Modern HUD v1 + toy VFX (13 Nov 2026, ~01:30-02:15, autopilot)

Owner (00:28): "the UI's need to be better, its so bad rn... also the star vfx dont match with the game".
Reference used (already in the vault, owner-approved for MEGA BITE): the Tap Simulator REBORN recording = "THE modern UI reference" ([[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]], [[2026-11-11 Research - Tap Simulator REBORN art style + 3D reveal]]).
"Stone-age" (owner words) = flat plates, plain strokes, static panels. The purple stud plates were exactly that.

## UIKit modern kit (`K.Big`, `K.Card`, `K.Sticker`, `K.Track`, `K.Square`)
- K.Big: huge LuckiestGuy text, white -> ice (or cream -> gold) vertical gradient, thick navy outline.
- K.Card: body on a darker solid copy offset down-left (chunky 3D slab), navy outline, round corners.
- K.Sticker: tilted yellow sticker with navy outline ("NEXT UP!", "HEIGHT").
- K.Track: dark navy bar with a white inner rim, lime gradient fill with a top shine.
- K.Square: labelled square button (icon inside, outlined word under it).

## HUD now
- Top centre: HEIGHT sticker + height icon + huge outlined number; the NEXT-form bar under it.
- Top left: big coin + big gold number (no plate); the NEXT UP quest card (white card on a blue slab, blue text, lime bar, gold reward pill).
- Left: TALENTS as a violet labelled square (badge kept, sheen/breath from SE_UIFx).
- Right edge: COMING NEXT column (next form, AWAKEN, CROWN) behind padlocks; tap = the lock wiggles + a toast saying how to unlock.
- Bottom: "CLICK TO STOMP!" as breathing outlined cream/gold text.
- Toasts: coloured pills on a darker slab with outlined text (colour = meaning).
- Check: no overlaps between HUD pieces at 1138x841, smallest text 17 px.

## VFX that "didn't match"
- The 4-point white glints were the shark game's sprite (a sparkly anime look). Replaced everywhere:
  - stomp / Ground Pound / evolve / pad buy / golden break = 3D TOY CONFETTI CUBES that tumble and bounce (Tap REBORN hatch style) in game colours, plus our own stud-kit star / coin icons;
  - golden props now float our coin icons; the crown sprinkles our star icon;
  - auras use soft glowing motes (Star form keeps our star icon).
- `FX.cubes(pos, n, colours, size, speed, life)` in StompFX.

## Not done yet (next)
- World signs (pad plates "STOMP POWER LV 0", lock badges "BE 6.00 m") are still on the old stud plates: move them to the white-card look.
- Phone check of the new HUD (S = 0.8 class), the talent square vs the thumbstick.
Saved: version 63.
