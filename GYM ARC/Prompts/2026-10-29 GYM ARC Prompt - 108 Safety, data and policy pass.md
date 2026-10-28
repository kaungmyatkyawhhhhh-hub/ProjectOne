---
date: 2026-10-29
tags: [gymarc, prompt, safety, data, policy]
status: todo (7 Nov, not slippable: before the ad test, and 105 needs its dataVersion)
---
# 108 Safety, data and policy pass

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC The whole game plan (research loop)]] · Research: [[Playbook notes - Whole-game research (Oct 2026)]] (sections 1 and 8)

```text
GYM ARC: a quiet safety pass, mostly invisible to players. Follow CLAUDE.md and the Playbook rules. Only the GYM ARC Studio. Read first: Player Data and Saving, Monetization, Personal Trainers, Aura, Genetics, Admin console, Codes. Never undo my manual Studio changes. Do NOT replace the save system (no ProfileStore switch): improve the one we have.

1) PAID RANDOM ITEMS: coins can be bought with Robux, so trainer rolls, aura spins and DNA rerolls count as paid random items. (a) Every one of them has a button labelled "Odds" (not just an i icon) listing every outcome with numbers that add up to 100%. (b) PolicyService:GetPolicyInfoForPlayerAsync(...).ArePaidRandomItemsRestricted = true → that player never sees or can buy the Robux coin packs, the DNA Robux products, the Starter Pack (it contains a DNA token) or offers for them (server checks too; their coins are earn-only). (c) REMOVE the Robux "Luck" supplement product from sale (owner rule: no paid luck; owned ones still work). Fail-safe: if the policy call fails, treat as restricted. Report how many places in the code this touched.
2) SAVE VERSION: add data.dataVersion and a step-by-step migration list (version N → N+1) that runs once on load; items are stored by id, never by display name; old ids map to new ones, never deleted. FORWARD-SAFE: a server running older code must never save over a save with a HIGHER dataVersion (load read-only + kick with a calm "Updating, rejoin" message), and unknown fields are always kept, never dropped. Write the rules in the Player Data note, plus: after a version bump use "Migrate to latest update", and never roll the place back past a bump (use the feature's Config switch instead).
3) RIGHT TO ERASURE: admin console command erase <userId> (removes their save, board entries, statue, crew membership; logs it). Tell me how to point Roblox's Right to Erasure webhook at a place I read (Discord/Guilded/email) so I can run the command when a request comes.
4) REMOTES AUDIT: list every RemoteEvent/RemoteFunction; each checks argument types and ranges (math.isfinite for numbers) and has a server rate limit; reps: the client never sends amounts, the server enforces a minimum time between reps; gains per minute are capped using the player's REAL current multipliers (boosts, Power Hour, rested, trainers), so legit players are never cut, and anything above is logged for the Admin console, not punished automatically. ProximityPrompts/ClickDetectors check distance and cooldown on the server. Report anything that was missing and what you fixed.
5) BACKUP ROUTINE: write in the Home note the weekly backup steps (Save to File or Version History > Open Local Copy → .rbxl to cloud; scripts in git).
5b) ANALYTICS NAMES: list every custom event that puts an id in its name (Code_Redeemed_<CODE>, Offer_Shown_<offer>, Guide_<...>, Locked_Tap_<tile>...) and how many names we use of Roblox's limit; tell me before changing any (dashboards depend on them).
6) CHECK ONLY (report, don't change): is the game on TextChatService (needed by May 2027)? Any links/socials anywhere in game text? Any Sound that isn't ours/licensed?
TEST: a fake restricted player (Studio attribute) sees no coin packs/DNA products; Odds buttons on all three; migration on an old save; erase on a test user. Progress note.
```
