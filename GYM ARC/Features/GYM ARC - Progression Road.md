---
date: 2026-11-02
tags: [gymarc, feature, retention]
status: built (Studio), not published
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Progression Road

Prompt: [[2026-10-29 GYM ARC Prompt - 91 Future You and Progression Road]]. Progress: [[2026-11-02 GYM ARC Future You and Progression Road + live playtest fixes]]. Related: [[GYM ARC - Growth Spurts]], [[GYM ARC - Body Alters]], [[GYM ARC - Unlock Guides]], [[GYM ARC - Hall of Fame]].

## Why
New players from ads leave before the first Growth Spurt. They need to see the reason to grind in minute one: how tall they'll get and what opens next.

## What the player sees
- **NEXT YOU card** under the GROWTH SPURT card (right column): your avatar small and grey (now) next to a bigger dark silhouette with a gold rim (next), "NEXT YOU · 4'4"", the first thing that opens ("Beach Gym"), "TAP FOR YOUR ROAD". In alter mode: "NEXT YOU · MARBLE", the rim in the alter's colour. All alters done: "YOU MADE IT".
- **YOUR ROAD** (tap the card): a sideways road of stops: START 4'0" -> Growth Spurts 1-6 (to 6'0") -> Alters 1-15 (to 7'0") -> HALL OF FAME -> Alters 16-20 / 21-25 / 26-30 COMING SOON. Each stop: your silhouette at that height, the height and gains bonus, icons of what opens. YOU ARE HERE, NEXT (gold glow + %), ticks on done stops, dark locked stops with "REACH GROWTH SPURT 5". Tap a stop: the strip lists everything it opens (grey = not yet, "(beat Benny)" when a bully still blocks it), a progress bar and WHAT TO TRAIN for the next stop.

## The unlock table (Config/Progression)
Built from the other configs; edit those, not this. Today:
| Stop | Opens |
|---|---|
| Start 4'0" | Starter Gym, arm wrestling |
| Spurt 1 4'4" | Beach Gym (beat Benny), Poses, Crew, Trainer Agency, Genetics, Inventory, Local Show |
| Spurt 2 4'8" | Gear, Regional Show |
| Spurt 3 5'0" | Pro Gym (beat Coral), Auras |
| Spurt 4 5'4" | 2nd trainer slot, National Show |
| Spurt 5 5'8" | Powerlifting Gym (beat Dante), Pro Card Qualifier, Powerlifting Agency |
| Spurt 6 6'0" | Body Alters, Universe Championship |
| Alter 1 | PUMPED skin, Human division |
| Alter 2 | Strongman Yard (beat Hank) |
| Alter 5 | Peak Human aura |
| Alter 6 | Stone division |
| Alter 8 | Golden Era Gym (beat Magnus), Golden Era Agency |
| Alter 10 | Stone Skin aura |
| Alter 11 | Metal division |
| Alter 12 | Beat Vince |
| Alter 15 7'0" | Forged aura, Hall of Fame |
| Hall of Fame | Hall of Fame Agency (star 3) |
| Alters 16-30 | COMING SOON (Gem, Elements, Legend) |
Every alter also opens its skin. New features get a slot by adding them to their own config (or a few lines in `Config/Progression`'s build()).

## Where it lives
`Config/Progression` (Stops, Reached, Current, ItemOpen, NextLine, HeightText), `Shared/UI/FutureYou` (the card + the avatar silhouette piece), `StarterPlayerScripts/RoadClient` (the window), `ProgressClient` (attaches the card), `UIBus.OpenRoad`, `GrowthSpurts.UnlockText` (reads the table), `ActionService` RoadEvent (analytics `FutureYou_Tapped`, `Road_Opened`).

## Rules
- Cheap on phones: the silhouettes are the avatar thumbnail (fetched once) as flat images, no live 3D; redrawn only when the save changes.
- UI kit only (Kit.Modal, Theme.Button chrome, PremiumKit backgrounds and slim buttons, ReadyGlow). No emojis.
- No menu tile yet (the left menu is already crowded): the card is the way in.
