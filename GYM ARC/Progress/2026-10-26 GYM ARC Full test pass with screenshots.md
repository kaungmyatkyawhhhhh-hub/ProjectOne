---
date: 2026-10-26
tags: [gymarc, progress, test]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-26 GYM ARC Full test pass with screenshots

Owner: "now test everything and document it with screenshots, i want to check". Studio play tests (PC window), as a **new player** (Studio FreshPlayer: temporary data, nothing saved) and on the **owner's own save**. Game commit 90d7b1e.

**How some things were tested** (they can't happen naturally in a solo Studio test):
- The Starter Pack popup timer was set to 30 s instead of 5 min for the test (put back to 5 min after).
- The Starter Pack purchase was a **test receipt** through the real purchase code (no Robux).
- The VIP deal needed a pass id: the real VIP pass id was used for the test only (put back to none; the owner still has to create the 30%-off pass).
- Growth Spurt 4 and "a friend joined from your invite" were **simulated** events (the real ones need hours of play / a second player).
- The Roblox purchase prompt for AUTO TRAIN can't be shown: the owner's account already owns the pass.

## Result: 6 problems found and fixed during the test
1. **BEST EQUIP overlapped the window's X** on smaller screens -> moved to the bottom of the trainer card (16 -> 24).
2. **PLAY on the main menu did nothing** (a leftover line in the new camera code errored) -> fixed, PLAY works (23).
3. **Statue camera shot blocked by a pillar** -> the camera picks the open side (19 -> 21).
4. **Statue shot blocked by a player / NPC** standing next to it -> it also avoids people (20 -> 21).
5. **The new top came out almost black** (its two colours multiplied) -> fixed; the matte top shows its real colour (25 -> 26). Then made white matte (owner) (31).
6. **A Studio-only loading hold switch from the test was left on** (kept the loading screen up) -> cleared.

No errors in the Output in the final runs (only the old known noise: one Roblox asset id, the TopbarPlus version note, "No ShakeMachine").

## New player, first minutes
| | Shot | What it shows |
|---|---|---|
| 1 | ![[GYM ARC/Screenshots/test_2026-10-26/01_loading_screen.jpg]] | Loading screen: barbell bar with all 4 plates on, LET'S LIFT! |
| 2 | ![[GYM ARC/Screenshots/test_2026-10-26/02_main_menu.jpg]] | Main menu (first version of the drama: logo glow, embers, hype line "No days off.") |
| 3 | ![[GYM ARC/Screenshots/test_2026-10-26/03_new_player_boost_and_goal_card.jpg]] | Coach Dex: NEW PLAYER BOOST 2x for 15 min; GROWTH SPURT 1 card visible from the start |
| 4 | ![[GYM ARC/Screenshots/test_2026-10-26/04_goal_shown_early.jpg]] | Coach Dex explains the goal (grow every muscle, get taller) |
| 5 | ![[GYM ARC/Screenshots/test_2026-10-26/05_first_rep_reward.jpg]] | First rep: "FIRST REP! YOU GOT STRONGER +100 coins" |
| 6 | ![[GYM ARC/Screenshots/test_2026-10-26/06_after_tutorial_750_coins_fast_progress.jpg]] | After the tutorial: +750 coins, Growth Spurt 1 already 50% (2x boost) |
| 7 | ![[GYM ARC/Screenshots/test_2026-10-26/07_daily_window_before_claim.jpg]] | Daily streak window (before claiming) |
| 8 | ![[GYM ARC/Screenshots/test_2026-10-26/08_daily_claimed_streak_tomorrow.jpg]] | Claimed: "STREAK: 1 DAY · TOMORROW: +110 COINS" |
| 9 | ![[GYM ARC/Screenshots/test_2026-10-26/09_deal_tag_and_invite_button.jpg]] | Red DEAL tag on SHOP, INVITE +50% under the left menu (first version, green) |
| 10 | ![[GYM ARC/Screenshots/test_2026-10-26/10_go_train_button.jpg]] | GO TRAIN BACK button after the tutorial |

## Starter Pack and VIP deal
| | Shot | What it shows |
|---|---|---|
| 11 | ![[GYM ARC/Screenshots/test_2026-10-26/11_starter_pack_popup.jpg]] | The popup by itself on the timer: 250 R$ crossed out, 79 R$, -68%, LIMITED, ENDS IN 23:56:02 |
| 12 | ![[GYM ARC/Screenshots/test_2026-10-26/12_starter_pack_flies_into_shop.jpg]] | At Growth Spurt 4 (simulated) it flies into the SHOP: "STARTER PACK · Still in the SHOP" |
| 13 | ![[GYM ARC/Screenshots/test_2026-10-26/13_starter_pack_bought_test_receipt.jpg]] | Bought (test receipt): "STARTER PACK! +5,000 coins, 3 shakes, a DNA..."; coins 2,891 -> 7,891; shakes and the 2x EXP item in the hotbar |
| 14 | ![[GYM ARC/Screenshots/test_2026-10-26/14_vip_deal_after_starter_pack.jpg]] | Then the VIP · 30% OFF offer: perks listed, 299 crossed out, 209, -30% |

## Friends
| | Shot | What it shows |
|---|---|---|
| 15 | ![[GYM ARC/Screenshots/test_2026-10-26/15_invite_boost_toast_simulated.jpg]] | "MAYA JOINED FROM YOUR INVITE! +50% EXP for 30 min" (simulated) |
| 23 | ![[GYM ARC/Screenshots/test_2026-10-26/23_invite_button_gold_premium.jpg]] | INVITE +50% now the gold premium style (owner) |

## Trainers and alters (owner's save)
| | Shot | What it shows |
|---|---|---|
| 16 | ![[GYM ARC/Screenshots/test_2026-10-26/16_trainers_sorted_by_stats_best_equip_overlap_bug.jpg]] | Sorted by stats (Atlas +143% first); BEST EQUIP overlapping the X (bug) |
| 24 | ![[GYM ARC/Screenshots/test_2026-10-26/24_trainers_best_equip_fixed.jpg]] | Fixed: BEST EQUIP on the card's bottom line. Tested: unequip Atlas (3/4), tap BEST EQUIP -> Atlas + the 3 strongest back (4/4) |
| 17 | ![[GYM ARC/Screenshots/test_2026-10-26/17_alter_pill_next_card_background.jpg]] | ALTER 7 pill over the head with the NEXT card's background |

Note: the owner's NEXT: GRANITE went from 53% to 18% because the alter goals were raised (alter 8: 380 -> 653 levels). Players near an alter see the same drop.

## Main menu camera (owner: "more dramatic, change the camera angles")
| | Shot | What it shows |
|---|---|---|
| 18 | ![[GYM ARC/Screenshots/test_2026-10-26/18_menu_camera_shot_a.jpg]] | Wide FOV, leaning camera on the Pump Shop (each shot pushes in fast, FOV 80 -> 62, hard cuts through black) |
| 22 | ![[GYM ARC/Screenshots/test_2026-10-26/22_menu_camera_shot_town.jpg]] | Town shot |
| 19 | ![[GYM ARC/Screenshots/test_2026-10-26/19_menu_statue_orbit_blocked_by_pillar_before_fix.jpg]] | New low-angle statue orbit, blocked by a pillar (bug) |
| 20 | ![[GYM ARC/Screenshots/test_2026-10-26/20_menu_statue_orbit_npc_in_front_before_fix.jpg]] | Blocked by a character standing there (bug) |
| 21 | ![[GYM ARC/Screenshots/test_2026-10-26/21_menu_statue_orbit_fixed.jpg]] | Fixed: clean low-angle hero shot of the champion statue |

## Buttons, AUTO TRAIN, the top
| | Shot | What it shows |
|---|---|---|
| 27 | ![[GYM ARC/Screenshots/test_2026-10-26/27_green_buttons_now_gold_keep.jpg]] | Green buttons are gold now (KEEP on the genetics screen) |
| 29 | ![[GYM ARC/Screenshots/test_2026-10-26/29_auto_on_now_gold.jpg]] | AUTO ON (owner owns the pass) now gold |
| 28 | ![[GYM ARC/Screenshots/test_2026-10-26/28_auto_train_button_for_non_owners.jpg]] | AUTO TRAIN button under the weight card, no AUTO chip on REP |
| 30 | ![[GYM ARC/Screenshots/test_2026-10-26/30_auto_train_off_for_non_owner.jpg]] | As a non-owner: AUTO TRAIN shown (off); a tap calls Roblox's pass purchase prompt (not shown to an account that owns it) |
| 25 | ![[GYM ARC/Screenshots/test_2026-10-26/25_grey_top_too_dark_before_fix.jpg]] | Grey top came out almost black (bug) |
| 26 | ![[GYM ARC/Screenshots/test_2026-10-26/26_grey_matte_top_fixed.jpg]] | Fixed: matte grey (then changed to white, owner) |
| 31 | ![[GYM ARC/Screenshots/test_2026-10-26/31_new_player_white_matte_top.jpg]] | New player in the white matte tank (middle) |

## Still to check on a phone / live
- AUTO TRAIN purchase prompt with an account that doesn't own the pass.
- A real friend joining through an invite (invite boost), and the daily reward notification once `notify_key` is set.
- The 5-minute Starter Pack popup timing and the real fly-into-SHOP at Growth Spurt 4.

## After the test (owner, same day)
- 7'0" isn't max any more: alter tiers add 4 inches; MAX only at the very top. Then Growth Spurts became **4 inches** (4'0" -> 6'0", top 8'0" with all alter tiers). See [[GYM ARC - Growth Spurts]].
| | Shot | What it shows |
|---|---|---|
| 32 | ![[GYM ARC/Screenshots/test_2026-10-26/32_height_7ft4_no_max.jpg]] | 7'4" without MAX (before the 4-inch change) |
| 33 | ![[GYM ARC/Screenshots/test_2026-10-26/33_new_heights_6ft4_white_top.jpg]] | New heights: 6'4" (6'0" + Tier 1), smaller body, white matte top |
