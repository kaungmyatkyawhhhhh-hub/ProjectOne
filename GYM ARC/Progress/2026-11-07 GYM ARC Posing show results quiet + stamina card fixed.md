---
date: 2026-11-07
tags: [gymarc, progress, bug, ui]
status: done (Studio, not published)
---
# Posing show results quiet + Out-of-stamina card fixed (7 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-11-07 GYM ARC Prompt - Posing show results too intrusive]]. Feature: [[GYM ARC - Posing Competition]], [[GYM ARC - Stamina and Treadmills]].

## 1. Posing show results (owner: "this annoying posing show thing shows up")
**Cause:** the live show is THE RUNWAY (`RunwayClient`). Its show UI (WINNER banner + RESULTS panel) showed for everyone within 75 studs of the runway, which covers the Beach Gym.
- **Not on stage:** no banner, no results panel, no vote panel, no judges' panel, nothing in the middle.
  - A REAL player wins: a small card in the right column for 3 s, "<name> won the Runway!" (old show: "won the Local Show!"). Only within 150 studs of the stage or for that player's friends, max once per show.
  - An NPC wins: nothing.
- **Contestants:** ONE compact card at the bottom centre, above the stamina bar / hotbar: the place, stars + coins (+ trophy), the top 3 in one line. It closes after 5 s, and any click / tap closes it sooner. It replaces the big panel and the separate reward popup. Width 33% of a PC screen, 34% on a 667x375 phone. The podium, confetti and the big screen by the stage stay as before.
- **New kit piece:** `ReplicatedStorage.Shared.UI.ShowResultCard` (Kit.Card + Kit.Text + GoldText; the toast is a RightColumn Tracker card, "PosingToast", priority 150 for its 3 s). Used by RunwayClient and PosingCompClient.
- **Settings:** new row "Posing Announcements" (On by default). Off = no toast. Saved as `settings.showAnnounce`.
- **The floating "★★★★" card:** it was a judge's score card (server BillboardGui, AlwaysOnTop, seen from 120 studs). Its 4.5 s timer could still be running when the results showed, and an older timer could hide a newer card. Now: a token on each timer, every card hidden before the results and at the end of the show (`hideJudgeCards`). On top of that, only the models see the cards at all (RunwayClient hides them for everyone else).
- Leaving mid-show (RunwayOut): the show UI and the cards go at once.
- Names: real players already showed their DisplayName (checked); NPCs unchanged.
- Old divisions show (`PosingCompClient`, not used while the runway exists): the judges' panel shows only to contestants now, with the same compact card and the same toast rule.

## 2. Out-of-stamina card never showed (owner, 7 Nov)
**Cause:** the card waits for the server's `StaminaRecovering`. The server only set it when a rep arrived that it couldn't pay for. But the client never sends a rep it can't pay for (MachineClient `canAffordRep`), so recovering never started: no card, no "RECOVERING" bar.
**Fix (MachineService `lift`):** when a rep leaves too little stamina for the next rep, recovering starts right then. Endless Stamina / TITAN / MONSTER are not affected (the bar stays full).
**Tested in real play** (Flat Bench, auto reps): stamina ran out → "RECOVERING 6s" + the "Out of stamina!" card (REFILL R$ 5 / ENDLESS 15M / SEE BOOST).

## Tests (Studio, one player)
- Watching from the Beach Gym, NPC wins: nothing on the screen.
- Watching, a real player wins: one right-column toast, 3 s, nothing in the middle.
- Model, placed 2nd: compact card, auto-closed after 5.2 s; a click closed it early.
- UIAudit (overlap check, GYM ARC screens) during the results with card + toast: PC 871x584 0 overlaps, phone 667x375 0 overlaps.
- No console errors.
- **Not tested:** a real 2-player runway (one model + one watcher). The results were played through the Studio-only hook `Workspace.TestRunwayResults = "npc" / "player" / "model"`. Real phone not tested.

## Screenshots
![[GYM ARC/Screenshots/2026-11-07_posing_results/01_pc_npc_win_watcher_nothing.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/02_pc_player_win_toast.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/03_pc_contestant_card_and_toast.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/04_phone_contestant_card.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/05_phone_player_win_toast.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/06_pc_stamina_out_card_real.jpg]]
![[GYM ARC/Screenshots/2026-11-07_posing_results/07_phone_stamina_out_card.jpg]]

## Owner to do
- File > Save to Roblox, then publish when ready (not published).
