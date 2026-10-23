---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 41 Title screen layout (desktop + phone)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Polish the title screen. Current look: C:\Users\kaung\Downloads\gym_arc_ui_current\title_now.png. Keep the button styles from prompt 37/40 (chunky PLAY red, SHOP gold, SETTINGS/NEWS dark). Follow CLAUDE.md Speed rules. Never undo the owner's manual Studio changes.

1) BOTH VARIANTS
- Hide ALL gameplay HUD, tooltips and popups (e.g. the "PUMP SHOP in town is open" tooltip top-right) until PLAY is pressed.
- Left column sits on a dark-to-transparent gradient (black ~80% at the left edge fading to 0% at ~45% of the screen width). No opaque halo or box behind PLAY.
- PLAY: clean dark outline + soft red glow only.

2) DESKTOP / TABLET (default)
- Left column vertically CENTRED on the screen.
- Order top to bottom: logo (~30% bigger than now), tagline "Everyone starts tiny.", PLAY (~20% bigger than now), SHOP, SETTINGS, NEWS, then the player card (avatar, name, level/height, coins) at the bottom of the SAME column (not in the middle of the screen).
- Even 12 px gaps between all buttons and the card.
- Camera: framed so the gym doorway and the character fill the right two-thirds of the screen; the ceiling lamp is out of frame.

3) PHONE VARIANT (use when UserInputService.TouchEnabled AND the viewport height is under 500 px)
- Left column 38% of the screen width, 16 px safe margin (respect the safe area / notch).
- Logo 120 px tall. Tagline hidden.
- PLAY 56 px tall, SHOP 44 px tall.
- SETTINGS and NEWS become two 44 px square icon buttons side by side on one row (gear and bell icons, NEWS keeps its red dot / "!" chip).
- Player card 40 px tall: avatar + name + coins only (no level/height).
- Same dark gradient behind the column.
- Camera pulled back so the doorway sits in the right 60% of the screen.
- Re-check the layout when the screen size changes (rotation / resize).

TEST: screenshots at 1920x1080, 1280x720, 844x390 and 667x375 (phone variant on the last two). Short progress note in the vault.
```

## Done (22 Oct, batch run)
- The live gym behind the menu (the menu art is off: it was also a shirtless body picture), gradient over the left 45%, all other screens hidden until PLAY (and back after).
- One column (logo, tagline, PLAY, SHOP, SETTINGS, NEWS, player card), centred, 12 px gaps; PLAY bigger with a soft red glow only.
- Phone variant (touch + height under 500; Studio: TestPhoneSize): 38% width, logo 120, no tagline, PLAY 56, SHOP 44, SETTINGS / NEWS as 44 px icon squares (NEWS keeps its "!"), a 40 px card.
- Camera: the doorway and the character on the right, lamp out of frame, stops inside walls; your own trainers are hidden while the menu is up.
- Not matched: Studio can't show 1280x720 separately (its window stays the same size); the loading screen still uses the old menu art (not in this prompt).

![[GYM ARC/Screenshots/title41/desktop.jpg]]
![[GYM ARC/Screenshots/title41/phone_844.jpg]]
![[GYM ARC/Screenshots/title41/phone_667.jpg]]
![[GYM ARC/Screenshots/title41/after_play.jpg]]
