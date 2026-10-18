---
date: 2026-10-04
tags: [gymarc, feature]
status: done
---
# GYM ARC - Crews

Back to [[00 GYM ARC Home|GYM ARC Home]].

Small groups of friends with a name and a short tag above their heads.

## How it works
- **Size:** up to 8 members.
- **Name and tag:** name 3-20 letters, tag 2-4 letters and numbers, filtered by Roblox's text filter.
- **Actions:** create (free), invite, join, leave.
- **Tag:** shown above members' heads.
- **Top crews:** a crew leaderboard, updated every 2 minutes. Saved across servers (fresh store since the 9 Oct release reset).
- Opened from the Crew tile.

## Where it lives
- `Config/Social` (Crew table)
- `Server/CrewService` (creates the `Crew` remote), `CrewClient`

## Known issues
- Not yet tested with two real players.

## Related
[[GYM ARC - Leaderboards and Statue]], [[GYM ARC - UI System]]

## Avatar headshots (14 Oct)
Player pictures here are the real Roblox avatar headshot in a plain dark circle (the same look everywhere, see [[GYM ARC - Loading Screen and Menu]]).

## Top crews member view (built 15 Oct, saved to git 19 Oct)
- Tapping a crew in TOP CREWS opens that crew's members, read-only, in the same view as MY CREW: name, tag, rank, score, members (headshot with an online dot, name, role, level, height, score; leader first, then by score). A back arrow returns to the list where it was scrolled. Your own crew opens MY CREW instead.
- Button: JOIN (open crews), REQUEST TO JOIN, REQUESTED, FULL or IN A CREW (greyed). The leader picks "join requests" (default) or "open to all" in MY CREW; leader and officers accept or decline requests there. A player accepted while in another server is told through the `CrewInboxV1` DataStore when they join.
- Studio test: Workspace attribute `TestCrews` = true shows test crews (never saved).
- This was in Studio and in `src/` since 15 Oct but never committed; it went into git with the 19 Oct commit. Not yet tested with two real players.

## Unique names and tags, empty crews deleted (19 Oct)
- Crew names and tags are unique, whatever the capitals: "That tag is already taken." / "That crew name is already taken." (`CrewNamesV1`). See [[GYM ARC - Bug - Two crews with the same tag]].
- When the last member leaves, the crew is deleted and leaves TOP CREWS; its name and tag are free again.
- A crew leader can get a one-time message when they join (used once: ARAQ313's tag changed to SRT1).

## Top crews member view tested (19 Oct)
Tested on the phone layout and the PC layout with the Studio test crews: the full crew with long names (fits, scrolls, greyed FULL at the bottom), the one-member open crew (JOIN), a deleted crew ("This crew no longer exists", its name kept in the header: fixed 19 Oct), headshots, online dots, roles, back returns to the same scroll position. Not testable in Studio: tapping your own crew (needs a saved crew); the code opens MY CREW. Note: the back arrow scrolls away with a long member list (scroll up to reach it).
![[GYM ARC/Screenshots/crews_top_view/phone_full_crew.jpg]]
![[GYM ARC/Screenshots/crews_top_view/phone_full_crew_bottom.jpg]]
![[GYM ARC/Screenshots/crews_top_view/phone_solo_crew.jpg]]
![[GYM ARC/Screenshots/crews_top_view/pc_gone_crew.jpg]]
