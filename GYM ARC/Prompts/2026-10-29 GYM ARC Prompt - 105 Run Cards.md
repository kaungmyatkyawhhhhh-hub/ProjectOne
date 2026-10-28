---
date: 2026-10-29
tags: [gymarc, prompt, retention, alters, hall-of-fame]
status: todo (21 Nov, with 96; needs 108's dataVersion; Legacy cards shown by 101)
---
# 105 Run Cards (pick 1 of 3 at every alter)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC The whole game plan (research loop)]] · Idea: owner, 29 Oct ("like the Deepwoken card system for each life before the Hall of Fame")

```text
GYM ARC: add RUN CARDS. Follow CLAUDE.md and the Playbook rules. Only the GYM ARC Studio. Read first: Body Alters, Hall of Fame, Gains and EXP, Personal Trainers, and prompt 96 (same update: the card pick IS "the reward every alter"). Never undo my manual Studio changes. 2D UI only (phones), locked UI kit.

1) WHEN: every time a player completes an alter (1-15), after the transformation, show 3 cards: tap one. Not during Growth Spurts (new players never see this). Players already past alters get their missed picks once (a "3 card picks waiting" button), never lose anything.
2) CARDS (Config/RunCards, about 20 at launch): muscle-group gains ("Chest +12%"), all-gains, trainer boost, coins per rep, stamina, feat upgrades (only when feats exist, prompt 93). Rarity Common 60 / Rare 28 / Epic 10 / Legendary 2 (odds shown on an "Odds" button). Epic and Legendary cards of a type only appear once the player holds 2 cards of that type (builds, like Deepwoken's requirements). Duplicates stack.
3) REROLL: one free reroll per pick. Never sold for Robux, never coins.
4) POWER RULES: card bonuses go in the BODY part of the GAINS number and pass through the soft line (prompt 91 item 9: no hard cap). Cards are ignored in posing shows, the Strongman Showdown and arm wrestling (competitions stay fair).
5) MY BUILD: a small 2D panel (from Stats) listing your cards and their total per type. No 3D.
6) HALL OF FAME = NEW LIFE: entering the Hall of Fame clears Run Cards. For each star the player keeps 1 LEGACY card (chosen at the ceremony from their current cards). Max 3 Legacy cards ACTIVE at once (the rest stored, swap any time outside competitions). Legacy cards replace the planned "Star Perks" (prompt 101 must use this, one system). Legacy cards also go in the BODY part.
7) SAVE: data.runCards = { picks = {...}, legacy = {...}, pending = n } with a dataVersion bump (system from prompt 108) and a migration (old saves: empty + pending picks for alters already done). The Hall of Fame cheat check (prompt 95) must NOT flag gains from these catch-up picks.
7b) SWITCH: Config/Experience Config RunCards_Enabled (false = no new picks, existing cards keep working).
8) SOUND/VFX: card flip with a rarity chord (one family with the roll sounds), Epic+ gets a short glow, ReducedMotion = fade only.
9) ANALYTICS (no ids in event names, Roblox allows 100 names): RunCard_Picked (custom fields: card id, rarity, alter), RunCard_Reroll, LegacyCard_Kept (custom field: card id).
TEST: alter 1 → 3 cards, reroll, pick; alter 15 save with cards → Hall of Fame keeps 1 legacy per star; shows ignore cards; soft line applied. Phone screenshots. Progress note + new feature note "GYM ARC - Run Cards".
```
