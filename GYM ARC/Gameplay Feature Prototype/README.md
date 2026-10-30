# Gym Lift Progression (Roblox prototype)
**Option 2: progression feature**, inspired by the lifting loop of *Gym League* / *Muscle Legends* (10k+ CCU).

## What I built
A **lift → earn → upgrade → grow** loop for multiple players:
- **Train** at an Overhead Press station. Each rep is a **timing bar**: tap/click/Space while the line is in the green. Perfect reps give 2x, and perfects in a row build a **combo** (up to +100%).
- Reps earn **Strength** (permanent: rank and body size) and **Cash** (spent on **heavier weights**, 5 → 160 kg, each doubling gains per rep, with the effect shown before buying). Heavier weights speed up the bar: more reward needs better timing.
- **Others see it:** the barbell moves on every rep (sound and sparkles on perfects), plates grow with your weight, **your body grows** with Strength, and an overhead tag shows rank, Strength, weight and combo. Station signs show who's lifting, rank-ups are announced to the server, and leaderstats are on.

## Key decisions
- **Server-authoritative:** the server re-computes the needle at the player's tap time (shared formula plus the synced server clock), so perfects can't be faked. It also enforces cooldowns and purchases.
- **Two currencies:** spending Cash never shrinks your body or rank.
- **Skill plus grind:** the timing and combo turn a tap loop into a real input decision.
- **Readable structure:** `GymConfig` (all tuning), `GymUtil` (shared math), `GymWorld`, `PlayerData` (DataStore with a safe fallback), `GymServer`, `GymClient`.

## With more time
Real lift animations and sounds, more exercises per muscle, a two-player spotter mechanic, global leaderboards, and analytics to tune the weight curve.

*Run:* open the .rbxlx in Studio, Save As .rbxl, then Test → 2 Players (R15).
