---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M1)
---
# SPEED ARC - UI Kit and HUD

> **Prompt 12 (28 Oct): the UI becomes ART.** Sporty palette (no pink / purple / pastels; the Pink button style is gone, Red = close, Grey = locked). 43 PNG sprites made by `Games/SpeedArc/tools/make_ui_kit.py` into `Games/SpeedArc/ui_kit/` (+ `kit.json` with SliceCenter and SliceScale): 6 button styles x normal/pressed (green buy/go/equip, blue normal, yellow claim, red close, grey locked, navy tab off), panel, 7 colour-glow tiles, 3 pills, progress bar, 2 badges, 15 icons. Mockups in `Screenshots/ui_kit/`. **Owner OK (28 Oct): applied everywhere and LOCKED.** 52 sprites now (added: orange block, round BOOST/JUMP buttons, white badge for tinting, gold + blue pills, the reveal orb + burst). Images upload only after the new group exists (prompt 13); until then Studio uses local copies.
> - **How to use it (code):** `UIKit.button{ Style, Text, Icon }` (Green buy/go/equip, Blue normal, Gold claim, Red close, Grey locked, Dark tabs/small), `UIKit.window`, `UIKit.panel`, `UIKit.tile{ Color }` (nearest of blue / lime / orange / gold / red / cyan / grey; `SliceScale` for big or short cards), `UIKit.setTileColor`, `UIKit.pill{ Kind }`, `UIKit.bar{ Kind }` -> track, fill, `UIKit.icon(name, size, parent)`, `UIKit.sprite(name, props)`.
> - **HUD:** coins pill with a big coin + green "+", a settings gear, rank badge (tinted white badge), the SPEED panel with the bolt and the kit bar, NEXT RACE pill with the flag, DAILY / QUESTS / TOP icon buttons with captions + red dots, LOCKER / COACHES / STORE with icons, CODES / INVITE icon buttons, the wall strip as small colour tiles (white ring = next wall, gold = your best), round BOOST / JUMP buttons in races, the gold boost badge.
> - **Tiles by state:** Locker gold = wearing, blue = owned, lime = can buy, grey = locked; Daily gold = today, lime = got it, blue = coming; Quests blue -> gold (claim) -> lime (done); Store each item its own colour + kit icon; coaches by stage / rarity.
> - **Coach roll reveal (GYM ARC-style):** the orb pops in and shakes, flickering through rarities up to the real one, a white flash and a burst of rays in the coach's colour, then the card (tile in the rarity colour, the 3D coach, rarity pill, name, boost, line) with turning rays and NICE!.
> - Rarity colours are sporty now: Common grey, Uncommon lime, Rare blue, Epic red, Legendary yellow, Mythic orange, Secret white.

> **28 Oct:** dark navy panels like GYM ARC (Palette SpeedBlack #11152E / Carbon #20274F / Graphite #353F78), the title on the panel edge with a coloured underline, Green and Pink button styles. HUD (prompt 11): "N SPEED" (no MPH), the wall strip under the SPEED panel while on the course, the toast lane under it, the AFK machine panel (no combo meter), the race card top right.

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

The look is decided in M1 (Lessons section 10). Every new screen reuses this kit.

## The kit (`Shared/UIKit`)
- **Palette:** Speed Black / Carbon panels with a Graphite border and a thin electric-blue strip on the left; electric blue for actions; GOLD only for coins, rewards, winners and premium; white text; Danger Red only for the last 3 seconds of a timer.
- **Fonts:** Montserrat Heavy *Italic* (titles, numbers, buttons: the "speed" font) + Builder Sans (body text). Smallest text 13.
- **Buttons:** chunky, glossy top, darker bottom edge; pressing pushes the face down and shrinks it a little, with a click sound. Styles: Blue, Gold, Dark.
- **Icons:** drawn from shapes (no emoji, no clip art): coin with speed bars, medals in gold / silver / bronze with the place number, speed chevrons.
- **Scaling:** screens are laid out for an 844 x 390 phone and scaled by one UIScale (0.7 to 1.6x).

## The HUD
- Top left: coins pill.
- Top centre: big MPH number (bounces on each tap), a bar to the next station, and the goal line ("Reach 1,400 MPH to unlock the Treadmill"; after that the next rank or "GO PRO is ready!"). Rank badge under the coins (M3).
- Top right: race timer pill (NEXT RACE 2:31 / JOIN NOW 0:08 / RACE ON) and the pulsing gold JOIN RACE button.
- One toast lane under the MPH (one message at a time; gold for unlocks, red for "can't").
- Training: card bottom right (station, +MPH per tap, combo meter, x1.3), STOP button, "TAP ANYWHERE TO RUN!" hint until your 4th tap.
- Race: position bar at the top, BOOST button with 3 pips, 3-2-1-GO / FINAL STRETCH / FINISH! in the centre, results card with medal, coins counting up, NEW PB! stamp and the standings.

## Phone check (Samsung Galaxy A06, 800 x 360)
Everything fits with no overlap: hub, training, race start, race, finish. See the progress note's screenshots.

## Where it lives
`Shared/UIKit`, `Client/Controllers/HudController`, `RaceController` (race screens).

## Related
[[SPEED ARC - Races]], [[SPEED ARC - Training]]
