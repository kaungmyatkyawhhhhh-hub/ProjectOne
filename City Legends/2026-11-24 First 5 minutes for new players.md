---
tags: [city-legends, onboarding, first-session, mobile]
created: 2026-11-24
status: in Studio (saved), not published
---
# City Legends: the first 5 minutes for new players (24 Nov 2026)

Owner approved "the first 5 minutes for new players". Goal: within 5 minutes a new player has a car, has driven somewhere real, has done one job and earned money, and knows the next goal. Short, skippable, phone-sized, only for new players (saved), never stacked on other pop-ups. Methods used: [[Brain/Methods/Impatient kid simulation]] (skill `impatient-kid-sim`), Playbook rules §4 (first session) and §5 (UI kit, phone HUD, Burmese).

## The flow, step by step
| Step | What the player sees | What ends it |
|---|---|---|
| 1. Pick a car | The menu's own "Pick your first car" (3 free cars, unchanged). No hint pill. | Car claimed and out on Kabar Aye Pagoda Road (engine already on for phones). |
| 2. Drive to the job | The **Delivery job is taken for them**. One-line hint pill: "Drive to the green beam: your first delivery job", with an arrow in the pill that turns toward the Myanmar Plaza dispatch (~300 studs from the spawn). The beam and minimap blip are the job's own (JobsClient). Within 90 studs: "Stop next to the DELIVERY sign to load the parcel". | Stopped at the dispatch for 1.2 s: the delivery starts. |
| 3. Deliver | "Deliver the parcel to Hledan Market Stall: follow the arrow" (the first parcel always goes to the **nearest drop**, 947 studs, a real place). Beam on the drop. Within 90 studs: "Stop at the beam to deliver". | A paid delivery (DELIVERED +$ popup, level-up). A late one goes back to step 2's hint. |
| 4. Next goal | 2.5 s after the pay popups: "Next goal: save $X for the <cheapest dealer car you don't own>" with the DEALER icon; tap opens the DEALER. Stays 12 s. | Tapped, closed or 12 s. Guide done (saved). |

- **Skip:** the red X on the pill ends the guide for good (saved).
- **Never stacked:** the pill sits in the start-up prompt's slot (bottom middle, above the GET OUT pill, under the toasts and popups) and hides while a menu, the dealer, the garage, a modal or the start-up prompt is up, and on foot. No shop card (Starter Pack) and no Double Pay link while the guide runs (Playbook: no shop offers in the tutorial).
- **Only new players:** a save that loads with no car claimed starts it; every older save is marked done. Saved as `profile.Activities.guide`.
- **After the guide:** the player stays on the Delivery job: JobsClient keeps pointing to the nearest dispatch, so the loop goes on by itself.
- **New-player grace (all players below level 5):** every delivery gets 40 s more time; the extra 40 s is not paid as time bonus (pay unchanged).
- **Measuring:** onboarding funnel (AnalyticsService, server, published game only): 1 Joined, 2 Got a car, 3 Delivery started, 4 Delivered, 5 Next goal seen; custom event `GuideSkipped` (value = the step). Read it in Creator Hub > Analytics > Funnels after a week: fix the biggest drop first.

## Kid sim (impatient kids, live numbers)
Code: `Games/CityLegends/tools/kidsim_first5.py` (results `tools/kidsim_first5_results.txt`). 2,500 kids per version, phone start, live economy (start $5,000, delivery $0.34 a stud + $5 a second left, 12 drops 947-2,430 studs from the MP dispatch, dispatch rings invisible since 21 Nov, jobs only in the JOBS tab, level-ups 32 x n^1.3 XP, first-mile goal ~4,600 studs).

**What was wrong in the live start (version A, median kid):** loading ~9 s, car pick ~8 s, car out at ~16 s ... then nothing tells a phone player what to do (the goals tracker is hidden while driving on phones, the dispatch ring is invisible, jobs live in a menu tab). The kid drives around with cut-ups as the only reward and quits at ~42 s. Live: 38% still playing at 60 s, 3% at 5 min.

| Version (each adds one change) | stay 60 s | 120 s | 180 s | 300 s |
|---|---|---|---|---|
| A live | 38 | 6 | 4 | 3 |
| B guide: Delivery taken for you + hint + arrow + beam | 92 | 73 | 63 | 38 |
| C + first parcel to the nearest drop | 93 | 87 | 73 | 36 |
| D + 40 s more on the first run | 93 | 87 | 72 | 37 |
| E + "stop here" hint when close | 92 | 86 | 72 | 35 |
| F + NEXT GOAL line after the pay | 93 | 89 | 78 | 44 |
| **G + 40 s more on every run below level 5 (shipped)** | **93** | **89** | **86** | **66** |
(median patience 11 s; at 7 s: A 0% -> G 38% at 5 min; at 16 s: A 10% -> G 87%.)

- Kept: B, C, E (free: it is the same pill), F, G. D is inside G (new players are level 1), so it is one rule.
- What the sim found after F: kids quit on a "Too late: no pay" on their 2nd-3rd run (a far drop, wrong turns). G fixed it without paying more.
- Honest: it is a model, not players. The real check is the funnel after publishing.

## Code
- New: `src/server/Guide.lua` (step, save, funnel, remote `GuideCall` get / step / skip, player attribute `Guide`; Studio hook server attribute `TestGuide`), `src/client/Guide.lua` (the pill, arrow, next goal; UI kit: panel, accent outline, pulsing accent badge, red round X, the kit's dealer icon).
- Changed: `Activities.lua` (guide: nearest drop; below level 5: +40 s not paid as bonus), `Offers.lua` + `OffersClient.lua` (nothing while `Guide` is set), `Main.server.lua` / `Main.client.lua` (one start line each), `Strings.lua` (5 lines, English + Burmese, `guide.*`).
- No new Config entries (Config is at the size limit).

## Tests
_(filled in below after the Play test)_
