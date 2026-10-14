---
date: 2026-10-14
tags: [gymarc, prompt, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: remake the 4 trainers (14 Oct)

```text
TRAINERS LOOK BAD. Remake the 4 trainer NPCs (EXP, Stamina, Coins, Pump) so they look like real, cool gym coaches. Save to Obsidian first.

1. BODY
   - Build each one from a HumanoidDescription (Players:CreateHumanoidModelFromDescription), R15, not hand-made parts.
   - Use our muscle system at a mid stage (fit, clearly stronger than a new player but smaller than a maxed player) so they match the game's style. The Pump trainer can be the biggest.
   - Normal height, slightly smaller than the player so they don't block the view when following.

2. LOOK (use free catalog items; search with search_asset, check they're free/public and have no real brands or logos)
   - Popular hair and an expressive face (confident/smirk/serious faces like the ones top games use). No default blank face.
   - Coach outfit in each trainer's tile color:
     - EXP: red tracksuit jacket + black joggers + whistle
     - Stamina: green athletic tank + shorts + headband + water bottle
     - Coins: gold/black polo + cap + clipboard
     - Pump: purple stringer tank + lifting belt + wrist wraps (biggest muscles)
   - Each one gets 1-2 accessories that fit (whistle, cap, sweatband, stopwatch, towel on shoulder). No headphones floating off the head. Check every accessory is attached properly and doesn't clip.
   - Skin tones and hairstyles different from each other.

3. ANIMATIONS (this matters most)
   - Idle: a coach idle (arms crossed, bouncing on feet, clipboard check), not a stiff T-pose stand.
   - While following: walk/run animation matching speed, stays slightly behind and to the side of the player, never inside them, never blocks the camera.
   - While the player lifts: the trainer faces the player and plays a cheer/clap/"come on!" animation every few reps, with a small speech bubble sometimes ("One more!", "Push!", "Good form!"), max one bubble per 10s.
   - Use Roblox's free animation packs or simple custom animations. No exploit/free-model scripts.

4. UI MATCH
   - Re-render the trainer portraits (trainer_exp/stamina/coins/pump) from the NEW models: head and shoulders, same camera for all 4, dark background, so the Coaches panel shows the actual trainers. Upload and replace the old IDs.

5. PERFORMANCE
   - Follow the NPC culling/LOD rules from before. Other players' trainers far away = simplified, no animations.

Screenshot each trainer: front, following the player, and cheering while the player lifts. Put them in screenshots/trainers/ next to the old ones. Commit, update PROGRESS.md and Obsidian.
```

Follow-up message:

```text
some of the trainers clothes look torn and their skin is showing in some parts of the clothes
especially in the front view of the lats
```
