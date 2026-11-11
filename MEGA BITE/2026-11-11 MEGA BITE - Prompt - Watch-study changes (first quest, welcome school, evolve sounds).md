---
date: 2026-11-11
tags: [megabite, prompt, claude-code, sound, quests, onboarding]
status: prompt READY, not sent, nothing changed in Studio (read-only check)
---
# MEGA BITE: what the Titan clips + Venom sound study changes (check + Claude Code prompt)

Owner (11 Nov, 03:55): "with that research, do we have to change some stuff in Mega Bite too". Back to [[00 MEGA BITE Home]].
Research: [[Roblox Playbook/Research notes/2026-11-11 Watch study - Titan Simulator clips + Venom sound measured (YouTube in the browser)]].
Checked read-only in the Mega Bite place (GameConfig, MB_Sounds, MB_HUD, MB_FishClient) and by measuring our own sound files in `MEGA BITE\Audio`.

## Short answer
Most of it is already in the build. Six small changes, no new models, no redesign.

## Already right (no change)
| Finding | MEGA BITE now |
|---|---|
| Every action pays, no waiting | no bite cooldown, a whole school in one pass, a "+N" for every fish |
| Your body is the score | the body grows, size tags, the crown (built 11 Nov) |
| All sizes in one place | one bank vent, 60 studs from the spawn: every big shark swims past the new players, and cannot hurt them there |
| Rebirth among the giants | Fossilize: back to a Minnow in the same server, EXP x2 |
| No pay to win | x2 EXP is the strongest pass; nothing bought works in the Trench |
| The goal on screen | NEXT shows on every bite and stays up for the last 20%. It fades when nothing changes, which is the owner's free-ocean HUD choice. Keep. |
| Sound weight and density | a modelled 20 s of reef eating (ambience + tail swish + chomp + gulp + pops, at the game's volumes): 37% of the energy at 60-250 Hz and 3.0 sound starts a second, against Venom's 45% and 4.0. Close enough. Measure a real recording at the phone test. |

## Change (6)
1. **First quest is a walk, not a bite.** Quest 1 is "Swim to the BANK VENT" (reward 3) and reef food is not carried, so there is nothing to bank yet. In both reference games the first goal is the core action. New order: "Eat 5 fish to GROW" first; the vent visit moves to just before "Swim out to the OPEN SEA", where banking starts to matter.
2. **No guaranteed first bite.** Schools spawn at random (about 38 groups in the reef, roughly 80 studs apart: about 3 to 6 s of swimming for a Minnow, sometimes more). Put one small school about 25 studs in front of every NEW player.
3. **The evolve sting is used for five things:** evolve, catching the golden fish, a store purchase, taking the crown, Fossilize. In Venom the big burst is rare (5 in 500 s) and that is why it lands. Keep it for evolve and Fossilize only. A purchase should play `BuySuccess`, which exists and is never used there.
4. **Only the first evolve has a second hit** (the "NEW ABILITY" toast, 2.8 s later, Piranha only). Venom's boss kill is a double hit about 1 s apart. Every evolve unlocks an ability, so every evolve gets the second hit.
5. **Size = pitch is in the sound plan but not wired.** `MB_Sounds.Play` only adds random jitter, so a Megalodon's bite sounds like a Minnow's. The plan (Reef Shark sound set): Hammerhead 0.92, Great White 0.85, Megalodon 0.78.
6. **Predator name "Big Jaws"** (a Great White). "Jaws" is the famous shark film. Same lesson as "Rampage" in Stomp Evolution: rename it. Proposal: **Big Chomper** (not yet checked against other games).

## Our sound files, measured (same bands as the Venom table)
| Sound | Length | 60-250 Hz | 250-2,000 Hz | above 2,000 Hz |
|---|---|---|---|---|
| Eat pop 1 / 2 / 3 | 0.26 / 0.25 / 0.34 s | 3 / 3 / 1% | 66 / 61 / 97% | 31 / 35 / 1% |
| Bite chomp 1 / 2 | 0.32 / 0.52 s | 52 / 43% | 31 / 39% | 16 / 16% |
| Gulp | 0.57 s | 49% | 44% | 2% |
| Swim swish | 0.25 s | 2% | 59% | 39% |
| Evolve sting | 2.08 s | 11% | 60% | 22% |
| Size up | 0.80 s | 0% | 60% | 40% |
| Bank ding | 1.42 s | 0% | 83% | 17% |
| Hammer Ram | 0.91 s | 46% (+42% under 60 Hz) | 10% | 2% |
| Safe Reef ambience | 20 s loop | 62% | 22% | 0% |
The chomp and gulp carry the weight; the pops are light on purpose (cute). Fine as a set.

## Still open (not changed by this prompt)
- Our own sim (exptune T4, 9 Nov) keeps 89% of kids at 5 min but 21% at 15 min, and it only knew 3 evolutions. The home note already says to re-run both kid sims on the live numbers. Do that before launch, now with 7 evolutions, the Trench and Fossilize.
- Music: there is only a quiet ambience loop. Venom shows a steady low bed under everything, which looks like music but I could not confirm it. Decide at the phone test.

## Claude Code prompt (paste as one message)
```
MEGA BITE (place "Mega Bite", P&L Studios XP). Read first, in the vault C:\ObsidianOne\Claude+Obsidian: Brain\00 BRAIN.md, MEGA BITE\00 MEGA BITE Home.md, and MEGA BITE\2026-11-11 MEGA BITE - Prompt - Watch-study changes (first quest, welcome school, evolve sounds).md. Six small changes. Every number goes in GameConfig. Do NOT playtest and do NOT publish: the owner tests.

1. QUESTS (GameConfig C.Quests, MB_QuestServer). New first quest: {id = "eat5", kind = "eat", goal = 5, reward = 3, text = "Eat 5 fish to GROW"}. Remove "vent" from first place and put it right before "open" (text: "Find the BANK VENT", reward 6). Keep "eat10" after "eat5". Check how quest progress is saved. It must survive the reorder: resolve the saved quest by its id, not its position, so a player on a quest that moved keeps that quest, and a save with an unknown id falls back to the first unfinished quest.

2. WELCOME SCHOOL (MB_FishServer). When a player's shark spawns with Evo 1 and EXP 0, move the nearest reef group that a Minnow can eat (Shrimp, Sardine, Damsel or Puffer) to a point C.Fish.WelcomeAhead = 25 studs in front of the spawn, at the spawn height, and hold it there for C.Fish.WelcomeHold = 8 s or until it is eaten. Reuse the logic of the Studio test hook that moves a school next to a shark. Never do it for a player who already has EXP.

3. EVOLVE STING ONLY FOR EVOLVE + FOSSILIZE. Replace Sounds.Play("Evolve") in: MB_FishClient golden fish caught -> "BankDing"; MB_StoreUI purchase -> "BuySuccess"; MB_SharkTags taking the crown -> "BankDing" (a crown sting of its own comes later). Leave it in the evolve handler and the Fossilize handler.

4. SECOND HIT ON EVERY EVOLVE (MB_HUD, the Evo changed handler). Today only e == 2 gets Sounds.Play("SizeUp") + the "NEW ABILITY" toast after 2.8 s. Do it for every evolution that has an ability, at C.EvolveAbilityDelay = 1.0 s after the celebration starts, without breaking the celebration queue (a crown bounty that evolves you must still show both).

5. SIZE = PITCH (MB_Sounds). Add C.SoundPitch = {1, 1, 1, 1, 0.92, 0.85, 0.78} by evolution. S.Play(name, parent, evo) multiplies PlaybackSpeed by C.SoundPitch[evo] for these families only: Bite, Gulp, EatPop, DartWhoosh, Swish, HurtBonk. The local player's sounds use the local Evo; a predator's or another shark's sounds use that shark's evolution. UI, bank, evolve and ability sounds are never pitched.

6. RENAME (GameConfig C.Predators.Types.GreatWhite.name): "Big Jaws" -> "Big Chomper". Check every pop and toast that prints the name.

Check without Play: every changed script compiles; list each file and line changed. Then write a short build note in the vault (MEGA BITE folder) and add one line to the home note.
```
