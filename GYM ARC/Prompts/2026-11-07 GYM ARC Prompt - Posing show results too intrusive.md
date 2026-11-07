---
date: 2026-11-07
tags: [gymarc, prompt, bug, ui]
status: done
---
# Posing show results pop up for everyone (owner screenshot, Beach Gym, 7 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Feature: [[GYM ARC - Posing Competition]]. Original rule (prompt 18): "Players who skip it are never interrupted."

Owner: "in beach gym, this annoying posing show thing shows up".

The screenshot shows (player NOT on stage, just training at the Beach Gym):
- a big "THE WINNER / NINA CRUZ" banner across the top-centre;
- a full "RESULTS" panel (1. Nina Cruz ★4.6, 2. Marco Vance ★4.5, 3. XxScoutCantChatxX ★4.3) covering the bottom-centre;
- together they cover most of the screen, and it repeats every 5 minutes. The winner here is an NPC.
- a floating "★★★★" star-card billboard left of the stage, still showing after the show.

```text
GYM ARC – POSING SHOW RESULTS ARE TOO INTRUSIVE (owner: "this annoying posing show thing shows up"). Read GYM ARC\Features\GYM ARC - Posing Competition.md and Prompts\2026-10-20 ... 18 Posing show every 5 minutes.md first. The rule there: players who skip the show are NEVER interrupted. Right now the WINNER banner + RESULTS panel cover the centre of everyone's screen at the Beach Gym every 5 min, even when an NPC won (owner screenshot: "THE WINNER NINA CRUZ" + RESULTS 1-3, the player not on stage).

1) WHO SEES WHAT
- CONTESTANTS (were on stage this show): keep their results, but compact and out of the way:
  - one bottom-centre card (max ~35% screen width on PC, fits 667x375 on phone, above the hotbar/skate button, never over the HUD or the leaderboard): their place + score + reward;
  - the top 3 as one line;
  - auto-close after 5 s, tap/click anywhere to close early;
  - the podium + confetti stay in the world.
- EVERYONE ELSE (not on stage): NO banner, NO results panel, nothing in the centre.
  - If a REAL player won: a small toast in the top-right notification area for 3 s ("<name> won the Local Show!"), max once per show, and only within 150 studs of the stage (or for that player's friends anywhere).
  - If an NPC won: nothing at all for non-contestants.
- The world scoreboard beside the stage keeps showing the last results (that's the right place for them).
- A Settings toggle "Show posing show announcements" (default ON for the small toast).

2) CLEAN-UP
- The floating star-card billboards (the "★★★★" cards) must disappear when the show ends and only exist for contestants on the stage during judging. Find what is still floating left of the stage in the owner's screenshot and remove/hide it after each show (check that no show UI or billboard leaks after a show ends or when a player leaves mid-show).
- Results names: real players use their DisplayName; NPCs stay as they are.

3) TEST
- Player training at the Beach Gym, NOT joining, for 2 shows: nothing covers the screen; NPC win = no toast; a real player's win = one small top-right toast.
- Contestant: a compact result card, auto-closes, tap to close, fits the phone (667x375) without covering the HUD/leaderboard/skate button.
- Run UIAudit (no overlaps) on phone + PC during the results. Screenshots of both views.
Short progress note in the vault.
```
