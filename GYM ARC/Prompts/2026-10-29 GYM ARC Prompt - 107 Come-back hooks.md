---
date: 2026-10-29
tags: [gymarc, prompt, retention, liveops, social]
status: todo (28 Nov; first Power Hours Sat 28 Nov 12:00 and 19:00 UTC)
---
# 107 Come-back hooks: Power Hour, rested gains, friends, notifications

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC The whole game plan (research loop)]] · Why: Roblox ranks on days 2-7 and 8-28 and on co-play days; notifications can't reach under-13s, so the hooks must be in the game.

```text
GYM ARC: give players reasons to come back tomorrow and next Saturday. Follow CLAUDE.md and the Playbook rules. Only the GYM ARC Studio. Read first: Live Update Events, Seasons and Events, Economy and Daily Rewards, Playtime Gifts, Crews, Settings. Never undo my manual Studio changes. Every number in Config + an Experience Config override.

1) POWER HOUR (weekly, automatic): every Saturday 12:00-13:00 UTC AND 19:00-20:00 UTC on every server (UTC clock, same second everywhere, no republish; 12:00 is evening in Asia, 19:00 in Europe/Americas). x2 gains for everyone, OUTSIDE the gains cap like PUMPED (tell the server's gains-per-minute check from 108 about it), a golden "Power Rack" machine appears in the plaza for that hour, a small "POWER HOUR NOW" pill only while it runs (NO countdown card: no time pressure on kids). Attending 4 different Power Hours earns the title "Power Hour Regular"; each Power Hour gives an earned cosmetic from a rotating list that comes back again later (never sold, never "last chance"). Use the existing LiveEvents/Season systems, don't build a new one. Configs: PowerHour_Enabled, PowerHour_Day, PowerHour_StartsUTC (list, "12:00,19:00"), PowerHour_Minutes, PowerHour_Gains. It replaces the removed rush hour.
2) RESTED GAINS: if a player was away 8 h or more, the Welcome back card (with offline coins) adds "WELL RESTED: x2 EXP for 15 min". It sits outside the gains cap like PUMPED (never wasted, never sold), shows as a boost tile using TODAY's boost system (prompt 97 converts it later), pauses on leave.
3) STREAK MILESTONES: a short celebration on login day 3 and day 7 (the grace day stays).
4) FRIENDS: invite prompt with launch data so the friend spawns next to the inviter; players in the same Roblox Party join the same server when possible (Player.PartyId / SocialService); the existing "train together +10%" shows a visible chip "WITH FRIEND +10%".
5) NOTIFICATIONS (Experience Notifications, only opted-in 13+, max 1 per day): "Your muscles are rested: x2 gains waiting" (8 h after leaving) and "<friend> just passed your height!". Ask for opt-in in the one-per-minute queue after the first Growth Spurt (prompt 106), never before, never as a requirement. FIRST check that our servers can send them (Open Cloud user notifications from HttpService with a Secret API key); the "rested" one needs a queue that any running server sends when due. If sending from our servers isn't possible, skip item 5 and tell me. Add the two message templates and tell me what to set up in Creator Hub.
6) WELLBEING: after 2 h in one session, one calm optional line "Great training! Water break?" once per session; Settings toggle "Break reminders".
7) ANALYTICS (no ids in event names): PowerHour_Joined (value = players on server), Rested_Used, Invite_Sent, Invite_Joined, Notify_OptIn_Shown / Accepted.
7b) SWITCHES: PowerHour_Enabled, Rested_Enabled, Notify_Enabled, BreakReminder_Enabled.
TEST: force Power Hour with a Studio attribute, rested after a fake 9 h absence, invite flow (as far as Studio allows), streak day 3/7 animation. Phone screenshots. Progress note + feature notes (new "GYM ARC - Power Hour").
```
After this update the owner adds a recurring **Experience Event** "POWER HOUR every Saturday" in Creator Hub.
