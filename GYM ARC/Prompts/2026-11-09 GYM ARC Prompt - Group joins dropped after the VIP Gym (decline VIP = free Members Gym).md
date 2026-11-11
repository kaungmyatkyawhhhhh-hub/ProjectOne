---
date: 2026-11-09
tags: [gymarc, prompt, claude-code, group, members-gym, vip]
---
# GYM ARC: group joins dropped from ~1,000/day to ~150/day after the VIP Gym (owner, 9 Nov)

Owner: "when there was only members gym, the members went up by 1k members a day, ever since the vip gym came, the vip gym has gotten more attractive and members went up only 150 a day".
Notes: [[GYM ARC - Members Gym and Free Coins]], [[2026-11-01 GYM ARC Starter Pack 29, VIP arrow, 60 FPS pass]] (the VIP Gym moved next to the Starter Gym entrance on 31 Oct, ~20 studs from spawn).

## Why it likely happened
- Before 31 Oct the Members Gym was THE exclusive area players saw first, and joining the group is free, so lots joined.
- Now the VIP Gym is the closer, flashier exclusive door. New players are drawn to it, get a Robux prompt, close it, and never find out there's a FREE exclusive gym too.
- **Check first:** compare group joins ÷ new players per day, before and after 31 Oct. If new players dropped just as much (ads, launch spike ending), it's traffic, not the VIP Gym.

## Why it matters to the owner
- Myanmar Builders Club group members are the owner's own channel for every future MBC game (announcements, launch traffic). VIP Robux are split with the shareholder.
- The fix below turns VIP "no thanks" into group joins, so it adds group members without taking any VIP sales away.

```text
GYM ARC – GET GROUP JOINS BACK (VIP "no" -> free Members Gym). GYM ARC is in maintenance mode: this is a small tweak only, no new systems. Do NOT publish (the owner publishes). Do NOT playtest (the owner tests).

1. VIP DECLINE -> MEMBERS OFFER: when a non-member closes the VIP pass prompt WITHOUT buying (MarketplaceService.PromptGamePassPurchaseFinished, wasPurchased = false), show a small panel once per session (max), not a full-screen popup:
   "NOT VIP? THE MEMBERS GYM IS FREE  ·  +10% GAINS  ·  Top weights"
   [JOIN GROUP] (GroupService:PromptJoinAsync for Myanmar Builders Club 33151111; on success the existing MembersService check opens the doors + group gift) and [No thanks]. Auto-closes after 8 s. Never shown to group members or VIP owners.
2. SIGNPOST AT THE VIP DOOR: a sign/arrow on the VIP Gym's entrance side for non-members: "FREE: MEMBERS GYM ->" pointing at the nearest Members Gym door (the entrance-hall one, mirror of the VIP doorway). Hidden for group members.
3. FIRST SESSION: right after the tutorial ends, the tutorial's last step points at the Members Gym door once ("Join the group for a FREE gym with +10% gains"), with the GO TO arrow. Only for non-members, only once per player (save flag onboarding.membersHint).
0. A/B TEST (owner, 9 Nov: VIP sales went UP after the VIP Gym, and now 80% of revenue is the owner's, so VIP sales must not drop): split new players 50/50 by UserId (even = A: no changes, odd = B: steps 1-3). Save the group in data.abMembersOffer. Log VIP pass purchases per group. The VIP decline panel (step 1) only shows from the player's SECOND decline (not the first), so someone still thinking about VIP isn't steered away.
4. ANALYTICS: custom events MembersOffer_Shown, MembersOffer_Joined, MembersHint_Shown, GroupJoin_Source (door / vipDecline / tutorial), so we can see which one works.

Keep everything existing (VIP prices, the VIP Gym, the Members Gym) unchanged. REPORT (short): files changed, where each new thing appears, and the analytics event names.
```
