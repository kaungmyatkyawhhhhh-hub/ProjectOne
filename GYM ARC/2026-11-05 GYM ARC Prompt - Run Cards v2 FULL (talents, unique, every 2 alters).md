---
date: 2026-11-05
tags: [gymarc, runcards, prompt, final]
---
# GYM ARC - Prompt: RUN CARDS v2 FULL (replaces the earlier talent prompts)

Decisions: [[2026-11-05 GYM ARC Prompt - Run Cards rare and legendary talents (Deepwoken style)]].

```text
GYM ARC – RUN CARDS v2 (FULL, replaces every earlier talent message). Read vault: GYM ARC\Features\GYM ARC - Run Cards.md and GYM ARC\2026-11-05 GYM ARC Prompt - Run Cards rare and legendary talents (Deepwoken style.md (sections "v2" and "Also decided"). Don't publish. Send me the balance table first, then build.

1. RARITIES (Deepwoken logic: rares give new STUFF to do, not % boosts):
   - COMMON = today's stat cards, Common values unchanged: Chest, Shoulders, Back, Arms, Legs, Core, All muscles, Trainer power, Coins, Stamina.
   - RARE = a new action, button, world interaction or visible triggered event.
   - LEGENDARY = changes a mechanic, has a PREREQUISITE shown on the card ("Requires: <card>").
   - Remove Epic and the Rare/Legendary % stat cards from new offers.
2. RARE TALENTS:
   - Second Wind: at 0 stamina a BREATHE button appears; tap 3 times in rhythm to refill 60% (90 s cooldown).
   - Mind-Muscle: a timing ring on the rep button; a rep in the sweet spot counts x2 with a "PERFECT" pop.
   - Heavy Day: MAX OUT button every 2 min: one huge slow rep worth 25 reps, floor-slam VFX + sound.
   - Negative Reps: hold the rep button for a slow rep worth 3 reps (tap vs hold).
   - Spotter's Call: walk up to any lifting player → SPOT prompt: they get +10% EXP for 30 s, you get coins. Holder max +30%, a spotted player max +10% from all spotters.
   - Lucky Plate: reps sometimes drop a gem shard on the floor; walk over it for coins.
   - Iron Lungs: double-tap to SPRINT anywhere; sprinting refills stamina like a treadmill.
   - Rest-Pause: sit on any bench: stamina refills 3x faster and the next 15 reps +40% (chalk-cloud VFX).
   - Specialist: pick a focus muscle at the Progress Mirror: +20% EXP and it visibly grows faster; change once per alter.
3. LEGENDARY TALENTS:
   - Adrenaline (needs 2 Rares): a Body Alter or Growth Spurt starts a 30 s frenzy: reps 2x faster, red screen edge, heartbeat (max once per 3 min).
   - Titan's Grip (needs Heavy Day): every new heaviest weight = a PR ATTEMPT: hold to lift, floor cracks, server message.
   - Golden Hour (needs Lucky Plate): every 5 min, 30 s of 3x coins with a gold screen edge + sound.
   - Unbreakable (needs Second Wind): stamina never fully empties; at 0 you keep repping at 50% EXP.
   - Lopsided Legend (needs Specialist): the focus muscle can grow past max size visually; that group +60% if its EXP is 2x every other group's.
   - Iron Bond (needs Spotter's Call): link with a friend; within 20 studs, 25% of each other's rep EXP is shared to both.
4. WHEN CARDS COME: a pick only on ODD Body Alters (1, 3, 5, 7 …).
   - Even alters show "Next card at Alter <n>" on the alter screen.
   - Already-earned and waiting picks (catch-up + per-star legacy picks) stay; the rule applies to alters reached from now on.
5. UNIQUE CARDS (like Deepwoken): every card can be held only ONCE per run, Commons included.
   - A held card (this run's cards + ACTIVE legacy cards) is never offered; that slot rolls another card.
   - If a rarity is empty, roll another rarity; if the whole pool is used up, give coins instead of a pick.
   - Duplicates of the same talent never happen.
6. ODDS: Common 65 / Rare 28 / Legendary 7. A Legendary only rolls if its prerequisite is met (this run's cards + active legacy count). One free reroll per pick (unchanged). Update the ODDS screen.
7. LEGACY:
   - The Hall of Fame keep is unchanged: 1 card per entry, kept forever.
   - Legacy cards form a collection; in MY BUILD the player activates up to 3 before a run. Only active ones count as held; inactive ones can be drawn normally.
   - At the Hall of Fame keep, cards already in the collection are greyed out ("Already in your collection"). If every card from that run is already collected, give 1 DNA Token instead.
8. OLD CARDS: everything players already hold (Rare/Epic/Legendary % cards, stacked duplicates) keeps working exactly as now, labelled CLASSIC in MY BUILD. Never remove or weaken anything a player owns.
9. UI:
   - Talent buttons sit in one small TALENT bar above the rep button (only talents you hold, phone-sized, cooldown rings).
   - Active effects show a small HUD icon (timer/glow: frenzy, Golden Hour, Rest-Pause charge, Mind-Muscle perfect streak).
   - Nothing blocks normal training.
   - Card faces: Rare and Legendary get their own frames; the rule is written on the card in one short line; Legendary gets a shimmer border and its own flip chord.
10. ART: 15 talent icons are ready in vault GYM ARC\Assets\icons_runcard_talents\ (512x512, file name = talent id: rare_second_wind … legendary_iron_bond). Upload to the game's owner like the v5 icons, put the ids in Config/RunCards.Art.Types, use them on the card faces and in MY BUILD.
11. RULES:
   - Talents never count in shows, the Strongman Showdown or arm wrestling.
   - Nothing grief-able (SPOT and Iron Bond only help).
   - Server-validated (timing ring, MAX OUT and hold-reps checked on the server; no exploits by spamming remotes).
12. BALANCE (send first): EXP/hour + coins per hour for a ★3 player at Alter 3 and a late-run player, with the new card count (odd alters) and unique cards: 3 Commons vs the strongest Rare+Legendary builds, and the legacy worst case (3 active Legendaries at the start of a new run). Every case under ~1.6x the Commons build; tune LEGENDARY numbers only, never Commons.
13. TEST: TestRunCards in Studio: each talent's trigger and cooldown, prerequisites, unique-card rolls, odd-alter picks, legacy loadout + Hall of Fame greyed keep + DNA Token fallback, CLASSIC cards still work. PC + phone. Progress note + screenshots.
```
