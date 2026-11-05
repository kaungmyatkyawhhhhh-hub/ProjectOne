---
date: 2026-11-05
tags: [gymarc, ui, physique, progress]
---
# GYM ARC - Physique panel polish (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · UI: [[GYM ARC - UI System]]

In Studio only. **Not published.** Same panel size (566 x 290) and tabs. The fonts pass ([[2026-11-05 GYM ARC Fonts through the UI kit]]) changes the type on top of this.

## One grade ladder (everywhere)
- `Theme.GradeColors` (+ `Theme.GradeColor(grade)`): **D grey #9AA0A8, C green #3FCB6A, B blue #3F8CFF, A purple #A45BFF, S gold #F6C75A** (S glows).
- Read by: `Kit.GradeBadge` faces (were bronze / silver / grey metal), `Kit.GradeColors`, `Theme.RankColors` (the Genetics screen's rank tags and plates), `Theme.Grades`, the Physique bars and the body map.

## GENES tab
- Each group card: grade badge, NAME, the multiplier big ("x1.32": green > 1.00, red < 1.00, white at 1.00), "grows 32% faster" / "grows 17% slower" / "normal speed" under it.
- Frame / Body: real numbers, same % merged ("+15% Back, Legs, Traps · abs show 25% later"; Lean "No EXP bonus · abs show 20% earlier"; Standard "No EXP bonus").
- "BEST: BACK x1.65 · WORST: LEGS x0.99" line; "3 DNA TOKENS" gold pill next to OPEN GENETICS.
- COIN BOOST left the header: it's a HUD boost tile now (bottom-left row, coin icon, "x4.5" under it, tap: "ALL COIN BOOSTS x4.5 (MAX)"; only while above x1).

## MUSCLES tab
- Body map: every muscle in its group's grade colour, brighter with progress (no red on grey). Tap a muscle: its row lights up gold and the group's muscles pulse white; tap a row: its muscles pulse.
- The eye button: "LABELS" under it + a hover tip "Show your stats around you in the world".
- NEXT GOAL card (replaces "MAX GROWTH SPURT REACHED"): "NEXT: GROWTH SPURT n" before 6'0", then "NEXT: ALTER n" ("(SOON)" when not out yet); bar = the six groups' average share of the goal's EXP (the real `GrowthSpurts.Progress` / `Alters.Progress` numbers, trainer boost included); "Needs 100%: Legs 23%, Core 35% +4 more". A ready Growth Spurt: TAP TO GROW takes its place.
- Bars 24 units tall (>= 18 px on a phone), in the grade colour with the kit's metal shine; one line on top: "% = SIZE TOWARD YOUR FULL LOOK" (the real definition, `Muscles.LookG`). Sorted highest first (kept).
- The total % + physique word now sit on one line above the card (the figure is a bit smaller).

## Tested (Studio, temporary saves; PC + phone layout)
- Low save (GS2, grades C/D/B, ~6-55%) and high save (6'0", Alter 3, S/A/B/C, 54-100%), Narrow/Stocky, Wide/Lean, V-Taper/Stocky.
- Map tap -> row highlight (fixed: the shapes were Frames, the tap fell through to the window's close backdrop; now buttons). Row tap -> pulse.
- Not done: a real phone; a Studio window at real phone resolution (the phone layout flag only).
![[GYM ARC/Screenshots/2026-11-05_physique_polish/03_pc_high_muscles.jpg]]
![[GYM ARC/Screenshots/2026-11-05_physique_polish/09_phone_high_genes.jpg]]
![[GYM ARC/Screenshots/2026-11-05_physique_polish/01_pc_low_muscles.jpg]]
![[GYM ARC/Screenshots/2026-11-05_physique_polish/02_pc_low_genes.jpg]]
(All 9 in `GYM ARC/Screenshots/2026-11-05_physique_polish/`.)

## Where
`Shared/UI/Theme` (GradeColors), `Shared/UI/Kit` (badge faces), `Shared/UI/BodyFigure` (named, tappable shapes; returns them), `StatsClient` (both tabs, NEXT GOAL, taps, TestOpenPanel "Genes"), `ActiveBoostsClient` (CoinBoost tile).
