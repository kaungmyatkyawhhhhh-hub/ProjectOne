---
tags: [brain, knowledge, liveops, analytics]
updated: 2026-11-09
---
# K08 LiveOps, updates and analytics
Back to [[00 BRAIN]] · Sources: [[Playbook notes - Updates and live ops]], [[Playbook notes - Admin panels and live tools]], [[Playbook notes - Analytics in practice]], [[Playbook notes - Analytics and experiments]], [[Playbook notes - Costly mistakes of big games]]

## The weekly rhythm
- Every **Saturday 15:00 UTC (21:30 MMT)**: ship early, content hidden behind a Config, switch on at the time; "Restart only outdated servers" with a countdown; a code + a group announcement + a clip.
- Bigger drop every 2-4 weeks; a monthly party; events 7-14 days; a major update per school break.
- Max ~2 prompts per weekly update; one no-release week a month (one owner tests everything).

## The 12 rules from big games' mistakes
1. Update every week (SPTS, Muscle Transform died from silence).
2. New content builds on old progress; never reset wallets or add a currency that wipes the old one (Fisch).
3. Never make an old goal further away or weaken what players own (PS99).
4. The core stays the core (Grow a Garden's pets took over).
5. Add depth slowly. 6. Resets feel like acceleration. 7. No paid power in competitions.
8. Server authority from day 1. 9. Original content only (takedowns).
10. Events: new rewards, tested, clear. 11. Tell players what changed. 12. Watch numbers daily after an update; undo with a Config.

## Live switches
- Creator Hub **Configs** change values in minutes (GYM ARC HallOfFame_EXPScale). Put event multipliers, gift timings and test prices there.
- EventController: config-driven timed events read from the UTC clock, a real countdown banner.
- Automatic rules: a stuck helper (nothing affordable 60 s → small boost), a comeback bonus (3+ days away), quiet-server boosts.
- Shared goals sized to the real player count (the Great Star started at 25/75/150/300/500 for ~25 DAU).

## Analytics routine (weekly, night shift on Mondays)
- D1/D7, 5-minute retention, onboarding funnel (LogOnboardingFunnelStepEvent), session time, payer %, errors, crashes, per-item conversion, A/B halves via custom events with a field.
- GYM ARC 9 Nov: a UI layout loop caused 110K errors/day after the fonts change: always check the Error Report after a publish.
