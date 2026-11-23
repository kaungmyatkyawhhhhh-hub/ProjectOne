---
tags: [city-legends, onboarding, first-session, mobile]
created: 2026-11-24
status: in Studio (saved, version 1898), not published
---
# City Legends: the first 5 minutes for new players (24 Nov 2026)

Owner approved "the first 5 minutes for new players". Goal: within 5 minutes a new player has a car, has driven somewhere real, has done one job and earned money, and knows the next goal. Short, skippable, phone-sized, only for new players (saved), never stacked on other pop-ups. Methods used: [[Brain/Methods/Impatient kid simulation]] (skill `impatient-kid-sim`), Playbook rules §4 (first session) and §5 (UI kit, phone HUD, Burmese).

## The flow, step by step
| Step | What the player sees | What ends it |
|---|---|---|
| 1. Pick a car | The menu's own "Pick your first car" (3 free cars, unchanged). No hint pill. | Car claimed and out on Kabar Aye Pagoda Road (engine already on for phones). |
| 2. Drive to the job | The **Delivery job is taken for them**. One-line hint pill at the top middle (under the level / job bars): "Drive to the green beam: your first delivery job", with an arrow in the pill that turns toward the Myanmar Plaza dispatch (~300 studs from the spawn). The beam and minimap blip are the job's own (JobsClient). Within 90 studs the pill drops to the bottom slot so the dispatch's DELIVERY JOBS sign stays in view: "Stop next to the DELIVERY sign to load the parcel". | Stopped at the dispatch for 1.2 s: the delivery starts. |
| 3. Deliver | "Deliver to Hledan Market Stall: follow the arrow" (the first parcel always goes to the **nearest drop**, 947 studs, a real place). Beam on the drop. Within 90 studs: "Stop at the beam to deliver" (bottom slot). | A paid delivery (DELIVERED +$ popup, level-ups). A late one goes back to step 2's hint. |
| 4. Next goal | 2.5 s after the pay popups: "Next goal: <the next Legends Path goal> · +$X" (new save: "Drive your first mile · +$600") with the GOALS flag icon; tap opens GOALS. Stays 12 s. | Tapped, closed or 12 s. Guide done (saved). |

- **Skip:** the red X on the pill ends the guide for good (saved).
- **Never stacked:** one pill only; it hides while a popup or toast is on screen (`UI.messageShowing`), while a menu, the dealer, the garage, a modal or the start-up prompt is up, and on foot. No shop card (Starter Pack) and no Double Pay link while the guide runs (Playbook: no shop offers in the tutorial).
- **Only new players:** a save that loads with no car claimed starts it; every older save is marked done. Saved as `profile.Activities.guide`.
- **After the guide:** the player stays on the Delivery job: JobsClient keeps pointing to the nearest dispatch, so the loop goes on by itself.
- **New-player grace (all players below level 5):** every delivery gets 40 s more time; the extra 40 s is not paid as time bonus (pay unchanged).
- **Measuring:** onboarding funnel (AnalyticsService, server, published game only): 1 Joined, 2 Got a car, 3 Delivery started, 4 Delivered, 5 Next goal seen; custom event `GuideSkipped` (value = the step). Read it in Creator Hub > Analytics > Funnels after a week: fix the biggest drop first.

## Kid sim (impatient kids, live numbers)
Code: `Games/CityLegends/tools/kidsim_first5.py` (results `tools/kidsim_first5_results.txt`). 2,500 kids per version, phone start, live economy (start $5,000, delivery $0.34 a stud + $5 a second left, 12 drops 947-2,430 studs from the MP dispatch, dispatch rings invisible since 21 Nov, jobs only in the JOBS tab, level-ups 32 x n^1.3 XP, first-mile goal ~4,600 studs).

**What was wrong in the live start (version A, median kid):** loading ~9 s, car pick ~8 s, car out ~7 s later ... then nothing tells a phone player what to do (the goals tracker is hidden while driving on phones, the dispatch ring is invisible, jobs live in a menu tab). The kid drives around with cut-ups as the only reward and quits at ~42 s. Live: 38% still playing at 60 s, 3% at 5 min.

| Version (each adds one change) | stay 60 s | 120 s | 180 s | 300 s |
|---|---|---|---|---|
| A live | 32 | 5 | 4 | 3 |
| B guide: Delivery taken for you + hint + arrow + beam | 91 | 71 | 64 | 39 |
| C + first parcel to the nearest drop | 91 | 86 | 74 | 36 |
| D + 40 s more on the first run | 91 | 86 | 73 | 36 |
| E + "stop here" hint when close | 94 | 89 | 76 | 39 |
| F + NEXT GOAL line after the pay | 94 | 91 | 82 | 45 |
| **G + 40 s more on every run below level 5 (shipped)** | **94** | **91** | **88** | **70** |
(median patience 11 s, car-out time as measured in Play: 6.7 s. At 7 s patience: A 0% -> G 37% at 5 min; at 16 s: A 8% -> G 87%.)

- Kept: B, C, E (free: it is the same pill), F, G. D is inside G (new players are level 1), so it is one rule.
- What the sim found after F: kids quit on a "Too late: no pay" on their 2nd-3rd run (a far drop, wrong turns). G fixed it without paying more.
- Honest: it is a model, not players. The real check is the funnel after publishing.

## Code
- New: `src/server/Guide.lua` (step, save, funnel, remote `GuideCall` step / skip, player attribute `Guide`, delivered = Activities' "jobs" note; Studio hook server attribute `TestGuide`), `src/client/Guide.lua` (the pill, arrow, next goal; UI kit: panel, accent outline, pulsing accent badge like the start-up prompt, red round X, the kit's GOALS flag icon).
- Test trick for a brand-new save on the test store (Edit can't reach DataStores): in Play on the Server, `SetAsync("p_<UserId>", { Claimed = false, Session = { id = "first5-reset", at = os.time() } })`, stop (the leave save sees another session and skips), Play again. Add `Settings = { Lang = "my" }` for a Burmese run.
- Changed: server `Activities.lua` (guide: nearest drop; below level 5: +40 s not paid as bonus), `Offers.lua` + `OffersClient.lua` (nothing while `Guide` is set), `Main.server.lua` / `Main.client.lua` (one start line each), `Strings.lua` (5 lines, English + Burmese, `guide.*`), `UI.lua` (`UI.messageShowing`), client `Activities.lua` (phones: the delivery / race card moved top left: under the minimap it lay on GAS / BRAKE), `JobsClient.lua` (no "DELIVERY · stop here" label of its own at the dispatch: it lay over the dispatch's sign).
- No new Config entries (Config is at the size limit).

## Tests (Studio Play, 24 Nov, phone size 812 x 375, test save `CityLegends_test` reset to a brand-new save, unlock-all off)
- Full flow 3 times (English twice, Burmese once): claim -> `Guide` 2 + Delivery job on -> dispatch -> run to Hledan Market Stall (nearest drop) -> paid -> next goal -> done. Funnel steps 1-5 fired. No Starter Pack card and no Double Pay link during the guide. No script errors from these scripts.
- A run that ended unpaid (teleport test: the server saw the car short of the drop) put the pill back to "Drive to the green beam" (fallback works).
- Skip: `GuideCall skip` -> `Guide` cleared (99); a bad step (NaN) is refused.
- Back on `CityLegends_v1` (Server in Play): the owner's old save gets no guide (`Guide` nil), `GuideCall` exists, no errors. StudioUnlockAll back on, PreviewPhone off. Saved as **version 1895**, not published.

**What the Play test found and fixed (3 rounds):**
1. In the bottom slot the pill hid the road and the dispatch sign and sat right under the "You've arrived" toast: moved to the top middle; it drops to the bottom slot only while you are stopping (within 90 studs).
2. Long drop names were cut off: one line that shrinks to fit (shorter English "Deliver to %s ...").
3. "Next goal: save $110,000 for the Apex AE86" (the cheapest dealer car is hours away): now the next Legends Path goal (minutes away, pays).
4. The delivery card lay on the GAS / BRAKE pedals on phones: moved top left (an older bug, met in the first minute).
5. Re-setting the waypoint after the minimap cleared it on arrival spammed "You've arrived" and kept the pill hidden: set once per target.
6. Two labels on top of each other at the dispatch: JobsClient's own label off for delivery.
7. Measured: the car came out **6.7 s** after CLAIM (a second "Loading the streets" wait). Fixed afterwards: 1.0 s (section below).

**Shots** (the existing HUD, top bars, job bar, delivery card and phone controls are in the same frame: same panels, outline and fonts):
![[2026-11-24 First 5 minutes - 1 pick your first car (Play).jpg]]
![[2026-11-24 First 5 minutes - 2 drive to the job, English (Play).jpg]]
![[2026-11-24 First 5 minutes - 3 deliver, English (Play).jpg]]
![[2026-11-24 First 5 minutes - 4 next goal, English (Play).jpg]]
![[2026-11-24 First 5 minutes - 1 pick your first car, Burmese (Play).jpg]]
![[2026-11-24 First 5 minutes - 2b stop at the dispatch, Burmese (Play).jpg]]
![[2026-11-24 First 5 minutes - 3 deliver, Burmese (Play).jpg]]
![[2026-11-24 First 5 minutes - 3b stop at the drop, Burmese (Play).jpg]]
![[2026-11-24 First 5 minutes - 4 next goal, Burmese (Play).jpg]]

## The second loading after CLAIM: 6.7 s -> 1.0 s (24 Nov, saved v1898)
- **Cause:** not the car (it arrives in 0.1 s) and not streaming (its streets went quiet in 1.5 s). `Main.client`'s `isJump` counted the first car out as a "jump" because the menu camera orbits 420+ studs UP over Myanmar Plaza, so `waitForMap` held the loading screen for the fixed terrain wait after a jump: `TERRAIN_SETTLE_PHONE` 6.5 s on phones (a guess in the code, never measured), 4 s on PC.
- **Fix:** the start screen's own map wait has already streamed everything within 800 studs (`NEAR_R`) of the orbit's centre, and the orbit looks down on it: a car that comes out within 800 studs (flat) of the orbit's centre, straight from the start screen, is no jump (`menuAt`, cleared by `stopOrbit`). Fast travel and real jumps keep the old waits.
- **Measured (Studio Play):** new save on `CityLegends_test`, phone layout: "car -> driving" **6.70 s before, 0.99 s after** (map wait 0.85 s). Owner's save on `CityLegends_v1`, PC, PLAY: 1.15 s (was about 4 s). The screenshot 1-2 s after CLAIM shows the roads and terrain fully drawn (no coarse terrain over the road). No script errors.
- Kid sim re-run with 0.8-1.5 s: G stays 93% at 60 s / 68% at 5 min (70% with the 6.7 s wait: within the model's noise; it counts a loading screen as mild boredom). The real gain is 5.7 s less loading screen inside Roblox's 60 s bounce window, which the model can't price.
![[2026-11-24 First 5 minutes - car out 1 s after CLAIM, streets loaded (Play).jpg]]
![[2026-11-24 First 5 minutes - 2 drive to the job, Burmese (Play).jpg]]
(the shorter Burmese step 2 line, one line)

## Not done / not tested
- A real phone and a real drive by hand (the test teleported the car between the spots); the X tapped by finger (the skip remote was tested).
- The funnel only counts in the published game: check Creator Hub > Analytics > Funnels a week after publishing.
- The terrain check after the faster spawn was by eye in Studio on a PC; a cheap phone meshes terrain slower: look once on a real phone right after CLAIM.
