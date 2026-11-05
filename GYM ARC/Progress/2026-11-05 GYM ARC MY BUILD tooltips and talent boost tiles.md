---
date: 2026-11-05
tags: [gymarc, progress, runcards, talents, ui]
---
# GYM ARC - MY BUILD tooltips + talent tiles in the boost row (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Run Cards v2: [[2026-11-05 GYM ARC Run Cards v2 talents built]] · UI: [[GYM ARC - UI System]]

In Studio only. **Not published.**

Owner (5 Nov): "MY BUILD: show a card's description on hover" (PC hover 0.2 s; phone: first tap = info, second tap = the card's action, tap elsewhere closes; name + rarity, CLASSIC, full rule with real numbers, Legendary "Requires" with a green tick, live talent state, legacy "kept from Hall of Fame #n" + ACTIVE / INACTIVE; beside the card, flipped to stay on screen, never over it, max ~260 px, one at a time; same tooltip on the TALENT bar buttons, hover / long-press). Then: "put talent boost icons at the place where boost icons are too and make it hoverable descriptions like the boost icons".

## New kit pieces
- `Shared/UI/Tooltip`: the kit's tooltip for any card / button.
  - The kit card piece, a thin outline in the rarity colour, Kit text helpers only (Theme fonts / sizes / colours), its own screen gui above every window.
  - Hover 0.2 s on PC. Phone: first tap shows, a second tap on the same card does its action, a tap anywhere else closes. `longPress` (TALENT bar): a tap acts, a 0.45 s press shows the tip. `hoverOnly` (the PR hold button: its press is the lift).
  - Placement: right of the card, else left, else below / above; clamped inside the screen; never over the card. 260 px wide.
  - Live: the words refresh every 0.5 s (timers, streaks); it closes when its card goes away.
  - Studio switch: Workspace `TestTouch` = mouse clicks act like phone taps.
- `Shared/UI/RunCardTip`: what a card's tooltip says (MY BUILD and the TALENT bar share it).
- `Config/RunCards.FullRule(id)`: each talent's full rule, built from its own numbers (a re-tune changes the text).

## MY BUILD
- Talent rows, stat rows (every card of that type: rarity, value, "this run" or "Legacy · kept from Hall of Fame #2", TOTAL, CLASSIC note), legacy tiles (active + collection).
- Talent live states: Mind-Muscle "12 PERFECT in a row", Golden Hour "Golden Hour in 3:49" / "3x COINS now", Titan's Grip "3 PR lifts this run", MAX OUT / BREATHE / Frenzy ready or "again in 1:12", Specialist focus, Rest-Pause charge, Lopsided active group, Iron Bond partner.
- Titan's Grip counts PR lifts per run: `data.talents.prs` + player attribute `TalentPRs` (TalentService), cleared by a new life (RunCardService.NewLife).
- Legacy tiles: "Tap again / Click to switch it on/off"; "3 are on (the most): switch one off first"; "You hold this card this run" when blocked.
- The rows are buttons now (a tap used to fall through and close the window).

## Bug fixed (every Kit window)
- A tap on any blank spot or text INSIDE a Kit.Modal window fell through to the backdrop and CLOSED the window (Active alone doesn't stop it; same cause as the Physique map taps). The panel is a silent button now: only the X and taps outside close a window.

## Talent effects in the boost row (bottom left)
- The TALENT column's effect chips are gone; the effects are boost-row tiles with the talent's own art and the boosts' hover / tap info card (name, gold effect pill, line):
  - Golden Hour: dim tile "5m" while waiting ("NEXT: 3x COINS FOR 30 S", "Starts in 4:35 · every 5 min"), its timer while on.
  - Frenzy (Adrenaline) timer, Spotted timer, Rest-Pause "x9" (reps charged) / "3x" (resting), Perfect streak "x12", Iron Bond "ON", Sprint "ON", Unbreakable "25%".
- The TALENT column keeps its buttons (MAX OUT, BREATHE, PR, SPRINT) and the TALENT POWER mini bar; the buttons have the tooltip.

## Tested (Studio, temporary save with talents, a Legendary, CLASSIC cards, legacy cards at stars 1-4)
- PC hover on talent / stat rows and legacy tiles; Legendary requirement met (green tick) and not met (grey lock); CLASSIC rows; legacy flipped left at the panel edge; bottom-edge clamp.
- Phone (TestPhoneSize 844 x 390 + TestTouch): row tap shows the tip and the window stays; legacy tile: first tap = info only (still ACTIVE), second tap switched Golden Hour off; a tap elsewhere closes the tip only.
- TALENT bar: SPRINT hover tip (flipped at the screen edge); long press showed the IRON LUNGS tip and didn't start sprinting.
- Boost row: talent tiles + hover card. No errors.
- Not tested: a real phone; MAX OUT / BREATHE on a machine (same code path as SPRINT).
- Found (was already there): on the phone layout, off a machine, the SPRINT button sat UNDER the right column's STARTER PACK card (its tap area took the press and opened the pack). **Fixed (owner: "yes move sprint on phone")**: on a phone, off a machine, the TALENT bar sits in the thumb's corner, just left of Roblox's jump button (and of SKATE when it shows), level with the jump button (`TalentClient.phoneSpot`; Studio's phone view: Roblox's small-screen jump spot). PC spot unchanged. Checked: nothing over SPRINT, a tap starts sprinting, no popup.
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/08_phone_sprint_moved_clear_of_starter_pack.jpg]]

![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/01_pc_hover_heavy_day_rare.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/02_pc_legendary_requires_met_3_prs_this_run_bottom_edge.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/03_pc_legacy_legendary_requires_not_met_star4_inactive.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/04_pc_classic_legs_rare_legacy_row.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/05_phone_tap_row_mind_muscle.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/06_pc_talent_tiles_in_boost_row_golden_hover.jpg]]
![[GYM ARC/Screenshots/2026-11-05_mybuild_tooltips/07_pc_talent_bar_sprint_hover_screen_edge.jpg]]

## Where
`Shared/UI/Tooltip` (new), `Shared/UI/RunCardTip` (new), `Config/RunCards` (FullRule), `Shared/UI/Kit` (Modal panel = button), `RunCardsClient` (MY BUILD), `TalentClient` (button tips, chips hidden), `ActiveBoostsClient` (talent tiles), `TalentService` + `RunCardService` (PRs this run).
