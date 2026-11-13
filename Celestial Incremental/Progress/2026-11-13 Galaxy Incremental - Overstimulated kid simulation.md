---
date: 2026-11-13
tags: [galaxy, kid-sim, overstimulated, ui, popups, phone]
---
# Galaxy Incremental: overstimulated-kid simulation (13 Nov)

Owner: "do the simulator on my galaxy incremental", then "fix the forge window and supernova card too".
Method: [[Brain/Methods/Overstimulated kid simulation]] (skill overstimulated-kid-sim). Research: [[2026-11-13 Research - Overstimulated kids (UI overload, stacked popups)]].
**Studio: built, tested in Play at phone size (750 x 381), saved (versions 292 + 293). NOT published.**
Checklist rows updated: #147, #164, #222, #392.

## How the kid works (model, estimates)
- Timeline: the impatient-kid sim's LIVE economy (`kidsim.py`, config G) for the first 10 min (44 live timelines), plus a mid-game 10 min (minutes 20-30: Supernovas every 80-140 s, buy bursts with NEW tiers, level ups, comets, tutorial steps 16-19, then step 20 = IGNITION 1).
- Each trigger becomes the UI it really shows (table below, read from the client scripts and fired in Play).
- Kids aged 6-12: attention slots 2 (6 y) / 3 (7-9 y) / 3.5 (10-12 y); reading 1.5 words/s at 7 and 3 at 10 (x 0.8-1.2 spread); a KEY message is read only while it is visible, not covered and the screen isn't overloaded.
- 2,000 kids x 2 windows per version (500 extra 7-year-olds, 200 extra 6-year-olds).
- It is a model with estimated weights and reading speeds. The real check is watching a kid play (or a screen recording).

## Emitters (live, before the fixes)
| emitter | trigger | region / size | how long, waits for | weight | KEY |
|---|---|---|---|---|---|
| toast (GalaxyHUD, shared.GalaxyToast, ~25 callers) | level up, welcome gift, comet tips, badges, quests, social, heists | top centre under the counter, 340 x 36 | 2.3 s; a new one REPLACED the old at once; drawn on the hidden HUD during cutscenes | 0.5 | some |
| server banner | someone's FIRST Supernova, Celestial / Secret / Void roll, Black Hole | top, 540 x 56 (overlaps the toast row on phones) | 3 s, replaces itself | 1 + sting | no |
| NEW tier moment | a new body / named tier | centre (cutscene mini) | 1.2 s; dropped during a cutscene; the old 1.5 s card ON TOP when a mini already ran | 1.5 + sting | yes |
| LUMI tutorial card | each tutorial step (20) | bottom centre, wide card | until the next step | 0.5 | yes |
| floats (+N, +ESSENCE) | buys, comets, steps | at the counter | 1.2 s | 0.25 | no |
| SUPERNOVA card | the kid taps the pill | centre modal | kid-paced | 2 | yes |
| Supernova cutscene | GO | full screen, HUD hidden | 10 s (first) / ~4.5 s | 2 + flash | yes |
| TUTORIAL COMPLETE card | last step (= Ignition) | centre | 2.8 s | 1.5 | yes |
| IGNITION cutscene | Ignition 1 | full screen, HUD hidden | 8 s | 2 + flash | yes |
| PICK YOUR PATH card | after the Ignition cutscene | centre modal, a choice | kid-paced | 2 | yes |
| LUMI's gift (Forge window + reveal) | tutorial done (the same moment as Ignition) | centre modal | 0.6 s after its toast | 2 | yes |
| like panel | after a Supernova | centre modal | already waits 20 s + calm | 2 | no |
| sounds | milestone, boom, windup, cometAppear, rescue, buyBody | - | - | 0.5 each | - |

## The worst moment, fired in Play (Ignition 1 with the Supernova card left open)
Before (live):
- 0.0 s: NEW IRON ASTEROID mini + LEVEL UP toast + 6 "milestone" stings inside 1 s
- 0.9 s: BADGE toast replaces LEVEL UP
- 0.4-1.4 s: TUTORIAL COMPLETE shown, then hidden by the cutscene (never seen again)
- 1.1 s: LUMI's gift Forge window opens UNDER the Ignition cutscene
- 4.1 s: "Play with friends" toast drawn on the hidden HUD (lost)
- 9.4 s: PICK YOUR PATH opens under the Supernova card (screenshot)

After (built):
- 0.4 s: the cutscene closes the Supernova card, Ignition 8 s (only 2 big sounds: windup, boom)
- 8.8 s: TUTORIAL COMPLETE (4.5 s)
- 15.3 s: PICK YOUR PATH, alone
- after the path card: LUMI's gift toast, then the Forge window
- then the waiting NEW tier and LEVEL UP, one at a time

![[screens/2026-11-13 overstim BEFORE ignition - supernova card over path card.jpg]]
![[screens/2026-11-13 overstim AFTER ignition - path card alone.jpg]]

## Versions (each adds one change to the one before)
| version | overload s / 10 min (first 10 / mid) | KEY missed (all / 7 y / 6 y) | sound pile-ups / kid | top collision left |
|---|---|---|---|---|
| v0 LIVE | 0.8 / 6.1 | 67% / 78% / 83% | 5.9 | LEVEL UP x BADGE (toast replaced) |
| v1 toast queue (no replace, read time) | 1.0 / 6.7 | 56% / 59% / 83% | 5.9 | banner x LEVEL UP (top band) |
| v2 hold news during cutscenes | 1.0 / 6.9 | 55% / 58% / 83% | 5.9 | banner x LEVEL UP |
| v3 one centre queue (cards in order, cutscene closes cards, NEW merges) | 1.4 / 1.7 | 21% / 23% / 80% | 5.3 | banner x LEVEL UP |
| v4 one big sound per second | 1.4 / 1.5 | 21% / 23% / 80% | 0 | banner x LEVEL UP |
| v5 merge same kind, demote minor news | 1.1 / 1.3 | 21% / 23% / 79% | 0 | banner x LEVEL UP (102, was 883) |
| v6 banner its own band | 1.1 / 1.3 | 21% / 23% / 79% | 0 | banner x banner |
| v7 KEY news waits while a card is up | 1.0 / 0.6 | 18% / 19% / 77% | 0 | - |
| v8 shorter KEY texts | 0.8 / 0.6 | 18% / 18% / 78% | 0 | - |
| **v9 ONE queue for every KEY message (toast, NEW card, LUMI step)** = what is built | **0.3 / 0.2** | **7% / 1.0% / 75%** | **0** | - |
| v10 "tap the comet" only on the LUMI card | 0.2 / 0.2 | 7% / 1.0% / 74% | 0 | - (not built: the toast + arrow was kept, shortened) |

- Goal check: 7-year-olds 1.0% missed (goal 0%: the rest is a NEW card or LEVEL UP landing in a busy burst), overload well under 5 s, 0 flash failures, 0 sound pile-ups.
- **6-year-olds still miss ~75% of the text in every version**: most can't read that fast. They need icons, colour and sound, not words.
- Cost: news now waits its turn: p95 7-10 s, max ~38 s (the Ignition chain: the gift waits for the path card). Rewards themselves still land at once (the counter, the sounds), only the words wait.
- Impatient-kid sim re-run on the live economy: unchanged (100% stay 60 s, 99.3% 3 min, 94.9% 5 min); no dead time added (it never waited on UI).
- Not fixed: "comets blocked" (~3 per kid per 20 min: a comet flies while a card or cutscene is up). Small; comets keep coming every 15-20 s.

## What changed in Studio
**The news queue (GalaxyHUD)**
- `toast()` no longer replaces: ONE queue for toasts, NEW-tier moments and banners.
- Each message stays up words / 1.2 + 0.5 s (2.3-6 s).
- It waits while a full cutscene or a kid-paced card (Supernova card, path card, TUTORIAL COMPLETE) is up. A toast cut by a cutscene comes back after it.
- The same kind merges (LEVEL UP 18 -> 19); minor news (badges, tips, quests, invites) is dropped after waiting 4 s. Time behind a cutscene doesn't count.
- A tutorial step gives the LUMI card 4 s before the next message.
- NEW-tier moments: 2.6 s (was 1.2), queued, never dropped; more NEW tiers meanwhile = "+2 MORE NEW".
- Other players' banners: none during your tutorial (the chat line stays), otherwise queued as minor news.

**Order of the big moments**
- GalaxyCutscene: a full cutscene sets `shared.GalaxyHudHidden` and closes the Supernova card first.
- Ignition: cutscene → TUTORIAL COMPLETE (4.5 s, was 2.8; "STAR FORGE OPEN: PRESS F") → PICK YOUR PATH → LUMI's gift (GalaxyForge waits for calm, max 90 s, then the toast, then the window).
- Pressing F (or any side window) closes the path card first.

**Sounds and texts**
- UIKit `Kit.sound`: one big sting (milestone / rescue / boom) per second; the others play at 20%. The buy chime is not capped.
- Shorter texts: "LUMI'S GIFT: +30 STARDUST!", "TAP THE COMET!", "LUMI CAUGHT IT! TAP THE NEXT ONE!", "GIFT: x2 STARDUST n MIN!".

**Phone windows (owner: "fix the forge window and supernova card too")**
- Cause: `WM.safeArea` counted Roblox's top bar twice on a real phone screen (TopbarInset is in screen px, a ScreenGui's AbsolutePosition is below the GUI inset): 116 px instead of 58. Every phone window sat 29 px low with 58 px less room.
- Fix in WindowManager.safeArea. Forge now 88-366 px on a 381 px screen (was 142-369 and cut); Upgrades 91-363.
- Forge reveal: on a phone the window scrolls, so the reveal showed only its top; it now scrolls to the middle (card, name, rarity, effect, "Tap to close" all on screen).
- SUPERNOVA! pill: hid on phones only if `Kit.phone()` was true at script start (it wasn't yet): now checked every frame, so it steps aside while a window is open.
- Supernova card: the first-run line is now "Shards stay FOREVER: next run is faster!" (one line); with the right safe area the KEEP / RESET lists no longer wrap badly.

![[screens/2026-11-13 overstim forge gift window runs off phone + supernova pill.jpg]]
![[screens/2026-11-13 forge window AFTER fix (phone).jpg]]
![[screens/2026-11-13 forge reveal AFTER fix (phone).jpg]]
![[screens/2026-11-13 overstim supernova card text cut off.jpg]]
![[screens/2026-11-13 supernova card AFTER fix (phone).jpg]]

## Open / for the owner
- **The HUD has the same top-bar double count:** on phones the LVL / GALAXY chips sit ~58 px lower than meant (empty space under Roblox's buttons). Nothing overlaps; not changed.
- Not checked: Store / Daily / Guide windows on a phone (same fit rule, should be fixed too: the emulator's hotkeys stopped answering), a real phone, a 2-player server.
- Publish when happy (File > Publish).

## Files
- Sim: `Celestial Incremental/Calc/overstim.py` (run `py overstim.py 2000` from the Calc folder; it imports kidsim + variants), results `Calc/overstim_results.txt`.
